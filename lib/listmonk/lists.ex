defmodule Listmonk.Lists do
  @moduledoc """
  Functions for managing Listmonk mailing lists.
  """

  alias Listmonk.{Client, Config, Error}
  alias Listmonk.Models.MailingList

  @doc """
  Retrieves all mailing lists.

  ## Examples

      iex> Listmonk.Lists.get()
      {:ok, [%MailingList{}, ...]}
  """
  @spec get(Config.t() | nil) :: {:ok, list(MailingList.t())} | {:error, Error.t()}
  def get(config \\ nil) do
    path = "/api/lists?page=1&per_page=1000000"

    case Client.get(path, config) do
      {:ok, %{"data" => %{"results" => results}}} ->
        lists = Enum.map(results, &MailingList.from_api/1)
        {:ok, lists}

      error ->
        error
    end
  end

  @doc """
  Retrieves all mailing lists. Raises on error.
  """
  @spec get!(Config.t() | nil) :: list(MailingList.t())
  def get!(config \\ nil) do
    case get(config) do
      {:ok, lists} -> lists
      {:error, error} -> raise error
    end
  end

  @doc """
  Retrieves a mailing list by ID.

  ## Examples

      iex> Listmonk.Lists.get_by_id(7)
      {:ok, %MailingList{}}
  """
  @spec get_by_id(integer(), Config.t() | nil) ::
          {:ok, MailingList.t() | nil} | {:error, Error.t()}
  def get_by_id(id, config \\ nil) do
    path = "/api/lists/#{id}"

    case Client.get(path, config) do
      {:ok, %{"data" => data}} when is_map(data) ->
        # Handle the API bug where sometimes it returns results array
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
  Retrieves a mailing list by ID. Raises on error.
  """
  @spec get_by_id!(integer(), Config.t() | nil) :: MailingList.t() | nil
  def get_by_id!(id, config \\ nil) do
    case get_by_id(id, config) do
      {:ok, list} -> list
      {:error, error} -> raise error
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

  ## Examples

      iex> Listmonk.Lists.create(%{name: "Newsletter"})
      {:ok, %MailingList{}}

      iex> Listmonk.Lists.create(%{
      ...>   name: "VIP List",
      ...>   type: :private,
      ...>   optin: :double,
      ...>   tags: ["vip", "premium"]
      ...> })
      {:ok, %MailingList{}}
  """
  @spec create(map(), Config.t() | nil) :: {:ok, MailingList.t()} | {:error, Error.t()}
  def create(attrs, config \\ nil) do
    with {:ok, payload} <- build_create_payload(attrs) do
      case Client.post("/api/lists", config, json: payload) do
        {:ok, %{"data" => data}} -> {:ok, MailingList.from_api(data)}
        error -> error
      end
    end
  end

  @doc """
  Creates a new mailing list. Raises on error.
  """
  @spec create!(map(), Config.t() | nil) :: MailingList.t()
  def create!(attrs, config \\ nil) do
    case create(attrs, config) do
      {:ok, list} -> list
      {:error, error} -> raise error
    end
  end

  @doc """
  Deletes a mailing list by ID.

  ## Examples

      iex> Listmonk.Lists.delete(7)
      {:ok, true}
  """
  @spec delete(integer(), Config.t() | nil) :: {:ok, boolean()} | {:error, Error.t()}
  def delete(id, config \\ nil) do
    case get_by_id(id, config) do
      {:ok, nil} ->
        {:ok, false}

      {:ok, _list} ->
        case Client.delete("/api/lists/#{id}", config) do
          {:ok, %{"data" => result}} -> {:ok, result == true}
          error -> error
        end

      error ->
        error
    end
  end

  @doc """
  Deletes a mailing list. Raises on error.
  """
  @spec delete!(integer(), Config.t() | nil) :: boolean()
  def delete!(id, config \\ nil) do
    case delete(id, config) do
      {:ok, result} -> result
      {:error, error} -> raise error
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
