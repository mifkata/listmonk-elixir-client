defmodule Listmonk.Subscribers do
  @moduledoc """
  Functions for managing Listmonk subscribers.
  """

  alias Listmonk.{Server, Error}
  alias Listmonk.Models.Subscriber

  @type server :: pid() | atom()

  @doc """
  Retrieves a list of subscribers based on optional filters.

  ## Options

  - `:query` - SQL query string for filtering (e.g., "subscribers.attribs->>'city' = 'Portland'")
  - `:list_id` - Filter by list ID
  - `:page` - Page number (default: 1)
  - `:per_page` - Results per page (default: 100)
  """
  @spec get(server(), keyword()) :: {:ok, list(Subscriber.t())} | {:error, Error.t()}
  def get(server, opts \\ []) do
    query_params = build_query_params(opts)
    path = "/api/subscribers?#{URI.encode_query(query_params)}"

    case fetch_all_pages(server, path, opts) do
      {:ok, results} -> {:ok, Enum.map(results, &Subscriber.from_api/1)}
      error -> error
    end
  end

  @doc """
  Retrieves a subscriber by email address.
  """
  @spec get_by_email(server(), String.t()) :: {:ok, Subscriber.t() | nil} | {:error, Error.t()}
  def get_by_email(server, email) do
    encoded_email = email |> String.replace("+", "%2b")
    query = "subscribers.email='#{encoded_email}'"

    case get(server, query: query, per_page: 1) do
      {:ok, [subscriber | _]} -> {:ok, subscriber}
      {:ok, []} -> {:ok, nil}
      error -> error
    end
  end

  @doc """
  Retrieves a subscriber by ID.
  """
  @spec get_by_id(server(), integer()) :: {:ok, Subscriber.t() | nil} | {:error, Error.t()}
  def get_by_id(server, id) do
    query = "subscribers.id=#{id}"

    case get(server, query: query, per_page: 1) do
      {:ok, [subscriber | _]} -> {:ok, subscriber}
      {:ok, []} -> {:ok, nil}
      error -> error
    end
  end

  @doc """
  Retrieves a subscriber by UUID.
  """
  @spec get_by_uuid(server(), String.t()) :: {:ok, Subscriber.t() | nil} | {:error, Error.t()}
  def get_by_uuid(server, uuid) do
    query = "subscribers.uuid='#{uuid}'"

    case get(server, query: query, per_page: 1) do
      {:ok, [subscriber | _]} -> {:ok, subscriber}
      {:ok, []} -> {:ok, nil}
      error -> error
    end
  end

  @doc """
  Creates a new subscriber.

  ## Attributes

  - `:email` (required) - Email address
  - `:name` (required) - Full name
  - `:lists` (required) - List of list IDs to subscribe to
  - `:status` - Status (:enabled, :disabled, :blocklisted), default: :enabled
  - `:preconfirm` - Skip confirmation for double opt-in lists, default: true
  - `:attribs` - Map of custom attributes
  """
  @spec create(server(), map()) :: {:ok, Subscriber.t()} | {:error, Error.t()}
  def create(server, attrs) do
    with {:ok, payload} <- build_create_payload(attrs) do
      case Server.request(server, :post, "/api/subscribers", json: payload) do
        {:ok, %{"data" => data}} -> {:ok, Subscriber.from_api(data)}
        error -> error
      end
    end
  end

  @doc """
  Updates a subscriber.

  ## Attributes

  - `:name` - Update name
  - `:email` - Update email
  - `:status` - Update status
  - `:attribs` - Update custom attributes
  - `:add_lists` - List IDs to add
  - `:remove_lists` - List IDs to remove
  """
  @spec update(server(), Subscriber.t(), map()) :: {:ok, Subscriber.t()} | {:error, Error.t()}
  def update(server, %Subscriber{id: id} = subscriber, attrs) do
    updated_subscriber = merge_subscriber_attrs(subscriber, attrs)

    payload =
      Subscriber.to_api(updated_subscriber, list_ids: calculate_list_ids(subscriber, attrs))

    case Server.request(server, :put, "/api/subscribers/#{id}", json: payload) do
      {:ok, _response} -> get_by_id(server, id)
      error -> error
    end
  end

  @doc """
  Deletes a subscriber by email or ID.
  """
  @spec delete(server(), String.t() | integer()) :: {:ok, boolean()} | {:error, Error.t()}
  def delete(server, email) when is_binary(email) do
    case get_by_email(server, email) do
      {:ok, nil} -> {:ok, false}
      {:ok, %Subscriber{id: id}} -> delete(server, id)
      error -> error
    end
  end

  def delete(server, id) when is_integer(id) do
    case Server.request(server, :delete, "/api/subscribers/#{id}") do
      {:ok, %{"data" => result}} -> {:ok, result == true}
      error -> error
    end
  end

  @doc """
  Enables a subscriber.
  """
  @spec enable(server(), Subscriber.t()) :: {:ok, Subscriber.t()} | {:error, Error.t()}
  def enable(server, subscriber) do
    update(server, subscriber, %{status: :enabled})
  end

  @doc """
  Disables a subscriber.
  """
  @spec disable(server(), Subscriber.t()) :: {:ok, Subscriber.t()} | {:error, Error.t()}
  def disable(server, subscriber) do
    update(server, subscriber, %{status: :disabled})
  end

  @doc """
  Blocks (unsubscribes) a subscriber.
  """
  @spec block(server(), Subscriber.t()) :: {:ok, Subscriber.t()} | {:error, Error.t()}
  def block(server, subscriber) do
    update(server, subscriber, %{status: :blocklisted})
  end

  @doc """
  Confirms opt-in for a subscriber to a list.
  """
  @spec confirm_optin(server(), String.t(), String.t()) :: {:ok, boolean()} | {:error, Error.t()}
  def confirm_optin(server, subscriber_uuid, list_uuid) do
    payload = %{"l" => list_uuid, "confirm" => "true"}
    path = "/subscription/optin/#{subscriber_uuid}"

    case Server.request(server, :post, path, form: payload) do
      {:ok, response} ->
        body = response["data"] || response
        success = check_optin_success(body)
        {:ok, success}

      error ->
        error
    end
  end

  # Private functions

  defp build_query_params(opts) do
    %{
      page: Keyword.get(opts, :page, 1),
      per_page: Keyword.get(opts, :per_page, 100),
      order_by: "updated_at",
      order: "DESC"
    }
    |> maybe_add_query(opts)
    |> maybe_add_list_id(opts)
  end

  defp maybe_add_query(params, opts) do
    case Keyword.get(opts, :query) do
      nil -> params
      query -> Map.put(params, :query, query)
    end
  end

  defp maybe_add_list_id(params, opts) do
    case Keyword.get(opts, :list_id) do
      nil -> params
      list_id -> Map.put(params, :list_id, list_id)
    end
  end

  defp fetch_all_pages(server, initial_path, opts) do
    per_page = Keyword.get(opts, :per_page, 100)
    fetch_pages(server, initial_path, per_page, 1, [])
  end

  defp fetch_pages(server, path_template, per_page, page, acc) do
    path = String.replace(path_template, ~r/page=\d+/, "page=#{page}")

    case Server.request(server, :get, path) do
      {:ok, %{"data" => %{"results" => results, "total" => total}}} ->
        new_acc = acc ++ results
        retrieved = page * per_page

        if retrieved < total do
          fetch_pages(server, path_template, per_page, page + 1, new_acc)
        else
          {:ok, new_acc}
        end

      error ->
        error
    end
  end

  defp build_create_payload(attrs) do
    email = Map.get(attrs, :email) |> validate_required(:email)
    name = Map.get(attrs, :name) |> validate_required(:name)
    lists = Map.get(attrs, :lists) |> validate_required(:lists)

    payload = %{
      "email" => String.trim(email),
      "name" => String.trim(name),
      "status" => status_to_string(Map.get(attrs, :status, :enabled)),
      "lists" => lists,
      "preconfirm_subscriptions" => Map.get(attrs, :preconfirm, true),
      "attribs" => Map.get(attrs, :attribs, %{})
    }

    {:ok, payload}
  rescue
    e in ArgumentError -> {:error, Error.new(e.message)}
  end

  defp validate_required(nil, field), do: raise(ArgumentError, "#{field} is required")
  defp validate_required(value, _field), do: value

  defp status_to_string(:enabled), do: "enabled"
  defp status_to_string(:disabled), do: "disabled"
  defp status_to_string(:blocklisted), do: "blocklisted"
  defp status_to_string(status) when is_binary(status), do: status

  defp merge_subscriber_attrs(subscriber, attrs) do
    %{
      subscriber
      | name: Map.get(attrs, :name, subscriber.name),
        email: Map.get(attrs, :email, subscriber.email),
        status: Map.get(attrs, :status, subscriber.status),
        attribs: Map.get(attrs, :attribs, subscriber.attribs)
    }
  end

  defp calculate_list_ids(subscriber, attrs) do
    current_ids = Subscriber.to_api(subscriber, []) |> Map.get("lists", [])
    add_lists = Map.get(attrs, :add_lists, []) |> MapSet.new()
    remove_lists = Map.get(attrs, :remove_lists, []) |> MapSet.new()

    current_ids
    |> MapSet.new()
    |> MapSet.union(add_lists)
    |> MapSet.difference(remove_lists)
    |> MapSet.to_list()
  end

  defp check_optin_success(body) when is_binary(body) do
    success_phrases = [
      "Subscribed successfully",
      "Confirmed",
      "no subscriptions to confirm",
      "No subscriptions"
    ]

    Enum.any?(success_phrases, &String.contains?(body, &1))
  end

  defp check_optin_success(_), do: false
end
