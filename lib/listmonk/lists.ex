defmodule Listmonk.Lists do
  @moduledoc """
  Functions for managing Listmonk mailing lists.
  """

  alias Listmonk.{Server, Error}
  alias Listmonk.Models.MailingList

  @type server :: pid() | atom()

  @doc """
  Retrieves all mailing lists.
  """
  @spec get(server()) :: {:ok, list(MailingList.t())} | {:error, Error.t()}
  def get(server) do
    path = "/api/lists?page=1&per_page=1000000"

    case Server.request(server, :get, path) do
      {:ok, %{"data" => %{"results" => results}}} ->
        lists = Enum.map(results, &MailingList.from_api/1)
        {:ok, lists}

      error ->
        error
    end
  end

  @doc """
  Retrieves a mailing list by ID.
  """
  @spec get_by_id(server(), integer()) :: {:ok, MailingList.t() | nil} | {:error, Error.t()}
  def get_by_id(server, id) do
    path = "/api/lists/#{id}"

    case Server.request(server, :get, path) do
      {:ok, %{"data" => data}} when is_map(data) ->
        list_data =
          case data do
            %{"results" => results} when is_list(results) ->
              Enum.find(results, &(&1["id"] == id))

            _ ->
              data
          end

        if list_data do
          {:ok, MailingList.from_api(list_data)}
        else
          {:ok, nil}
        end

      error ->
        error
    end
  end

  @doc """
  Creates a new mailing list.

  ## Attributes

  - `:name` (required) - Name of the list
  - `:type` - List type (:public or :private), default: :public
  - `:optin` - Opt-in type (:single or :double), default: :single
  - `:tags` - List of tags
  - `:description` - Description of the list
  """
  @spec create(server(), map()) :: {:ok, MailingList.t()} | {:error, Error.t()}
  def create(server, attrs) do
    with {:ok, payload} <- build_create_payload(attrs) do
      case Server.request(server, :post, "/api/lists", json: payload) do
        {:ok, %{"data" => data}} -> {:ok, MailingList.from_api(data)}
        error -> error
      end
    end
  end

  @doc """
  Deletes a mailing list by ID.
  """
  @spec delete(server(), integer()) :: {:ok, boolean()} | {:error, Error.t()}
  def delete(server, id) do
    case get_by_id(server, id) do
      {:ok, nil} ->
        {:ok, false}

      {:ok, _list} ->
        case Server.request(server, :delete, "/api/lists/#{id}") do
          {:ok, %{"data" => result}} -> {:ok, result == true}
          error -> error
        end

      error ->
        error
    end
  end

  # Private functions

  defp build_create_payload(attrs) do
    name = Map.get(attrs, :name) |> validate_required(:name) |> String.trim()
    list_type = Map.get(attrs, :type, :public)
    optin = Map.get(attrs, :optin, :single)

    unless list_type in [:public, :private] do
      raise ArgumentError, "type must be :public or :private"
    end

    unless optin in [:single, :double] do
      raise ArgumentError, "optin must be :single or :double"
    end

    payload = %{
      "name" => name,
      "type" => to_string(list_type),
      "optin" => to_string(optin)
    }

    payload =
      case Map.get(attrs, :tags) do
        nil -> payload
        tags -> Map.put(payload, "tags", tags)
      end

    payload =
      case Map.get(attrs, :description) do
        nil -> payload
        description -> Map.put(payload, "description", description)
      end

    {:ok, payload}
  rescue
    e in ArgumentError -> {:error, Error.new(e.message)}
  end

  defp validate_required(nil, field), do: raise(ArgumentError, "#{field} is required")
  defp validate_required("", field), do: raise(ArgumentError, "#{field} is required")
  defp validate_required(value, _field), do: value
end
