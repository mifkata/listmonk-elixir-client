defmodule Listmonk.Subscribers do
  @moduledoc """
  Functions for managing Listmonk subscribers.
  """

  alias Listmonk.{Client, Config, Error}
  alias Listmonk.Models.Subscriber

  @doc """
  Retrieves a list of subscribers based on optional filters.

  ## Options

  - `:query` - SQL query string for filtering (e.g., "subscribers.attribs->>'city' = 'Portland'")
  - `:list_id` - Filter by list ID
  - `:page` - Page number (default: 1)
  - `:per_page` - Results per page (default: 100)

  ## Examples

      iex> Listmonk.Subscribers.get()
      {:ok, [%Subscriber{}, ...]}

      iex> Listmonk.Subscribers.get(query: "subscribers.email LIKE '%@example.com'")
      {:ok, [%Subscriber{}, ...]}
  """
  @spec get(keyword(), Config.t() | nil) :: {:ok, list(Subscriber.t())} | {:error, Error.t()}
  def get(opts \\ [], config \\ nil) do
    query_params = build_query_params(opts)
    path = "/api/subscribers?#{URI.encode_query(query_params)}"

    case fetch_all_pages(path, config, opts) do
      {:ok, results} -> {:ok, Enum.map(results, &Subscriber.from_api/1)}
      error -> error
    end
  end

  @doc """
  Retrieves subscribers. Raises on error.
  """
  @spec get!(keyword(), Config.t() | nil) :: list(Subscriber.t())
  def get!(opts \\ [], config \\ nil) do
    case get(opts, config) do
      {:ok, subscribers} -> subscribers
      {:error, error} -> raise error
    end
  end

  @doc """
  Retrieves a subscriber by email address.

  ## Examples

      iex> Listmonk.Subscribers.get_by_email("user@example.com")
      {:ok, %Subscriber{}}

      iex> Listmonk.Subscribers.get_by_email("nonexistent@example.com")
      {:ok, nil}
  """
  @spec get_by_email(String.t(), Config.t() | nil) ::
          {:ok, Subscriber.t() | nil} | {:error, Error.t()}
  def get_by_email(email, config \\ nil) do
    encoded_email = email |> String.replace("+", "%2b")
    query = "subscribers.email='#{encoded_email}'"

    case get([query: query, per_page: 1], config) do
      {:ok, [subscriber | _]} -> {:ok, subscriber}
      {:ok, []} -> {:ok, nil}
      error -> error
    end
  end

  @doc """
  Retrieves a subscriber by email. Raises on error.
  """
  @spec get_by_email!(String.t(), Config.t() | nil) :: Subscriber.t() | nil
  def get_by_email!(email, config \\ nil) do
    case get_by_email(email, config) do
      {:ok, subscriber} -> subscriber
      {:error, error} -> raise error
    end
  end

  @doc """
  Retrieves a subscriber by ID.

  ## Examples

      iex> Listmonk.Subscribers.get_by_id(123)
      {:ok, %Subscriber{}}
  """
  @spec get_by_id(integer(), Config.t() | nil) ::
          {:ok, Subscriber.t() | nil} | {:error, Error.t()}
  def get_by_id(id, config \\ nil) do
    query = "subscribers.id=#{id}"

    case get([query: query, per_page: 1], config) do
      {:ok, [subscriber | _]} -> {:ok, subscriber}
      {:ok, []} -> {:ok, nil}
      error -> error
    end
  end

  @doc """
  Retrieves a subscriber by ID. Raises on error.
  """
  @spec get_by_id!(integer(), Config.t() | nil) :: Subscriber.t() | nil
  def get_by_id!(id, config \\ nil) do
    case get_by_id(id, config) do
      {:ok, subscriber} -> subscriber
      {:error, error} -> raise error
    end
  end

  @doc """
  Retrieves a subscriber by UUID.

  ## Examples

      iex> Listmonk.Subscribers.get_by_uuid("c37786af-e6ab-4260-9b49-740adpcm6ed")
      {:ok, %Subscriber{}}
  """
  @spec get_by_uuid(String.t(), Config.t() | nil) ::
          {:ok, Subscriber.t() | nil} | {:error, Error.t()}
  def get_by_uuid(uuid, config \\ nil) do
    query = "subscribers.uuid='#{uuid}'"

    case get([query: query, per_page: 1], config) do
      {:ok, [subscriber | _]} -> {:ok, subscriber}
      {:ok, []} -> {:ok, nil}
      error -> error
    end
  end

  @doc """
  Retrieves a subscriber by UUID. Raises on error.
  """
  @spec get_by_uuid!(String.t(), Config.t() | nil) :: Subscriber.t() | nil
  def get_by_uuid!(uuid, config \\ nil) do
    case get_by_uuid(uuid, config) do
      {:ok, subscriber} -> subscriber
      {:error, error} -> raise error
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

  ## Examples

      iex> Listmonk.Subscribers.create(%{
      ...>   email: "user@example.com",
      ...>   name: "John Doe",
      ...>   lists: [1, 2],
      ...>   attribs: %{"city" => "Portland"}
      ...> })
      {:ok, %Subscriber{}}
  """
  @spec create(map(), Config.t() | nil) :: {:ok, Subscriber.t()} | {:error, Error.t()}
  def create(attrs, config \\ nil) do
    with {:ok, payload} <- build_create_payload(attrs) do
      case Client.post("/api/subscribers", config, json: payload) do
        {:ok, %{"data" => data}} -> {:ok, Subscriber.from_api(data)}
        error -> error
      end
    end
  end

  @doc """
  Creates a new subscriber. Raises on error.
  """
  @spec create!(map(), Config.t() | nil) :: Subscriber.t()
  def create!(attrs, config \\ nil) do
    case create(attrs, config) do
      {:ok, subscriber} -> subscriber
      {:error, error} -> raise error
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

  ## Examples

      iex> subscriber = Listmonk.Subscribers.get_by_id!(123)
      iex> Listmonk.Subscribers.update(subscriber, %{name: "Jane Doe", add_lists: [3]})
      {:ok, %Subscriber{}}
  """
  @spec update(Subscriber.t(), map(), Config.t() | nil) ::
          {:ok, Subscriber.t()} | {:error, Error.t()}
  def update(%Subscriber{id: id} = subscriber, attrs, config \\ nil) do
    updated_subscriber = merge_subscriber_attrs(subscriber, attrs)

    payload =
      Subscriber.to_api(updated_subscriber, list_ids: calculate_list_ids(subscriber, attrs))

    case Client.put("/api/subscribers/#{id}", config, json: payload) do
      {:ok, _response} -> get_by_id(id, config)
      error -> error
    end
  end

  @doc """
  Updates a subscriber. Raises on error.
  """
  @spec update!(Subscriber.t(), map(), Config.t() | nil) :: Subscriber.t()
  def update!(subscriber, attrs, config \\ nil) do
    case update(subscriber, attrs, config) do
      {:ok, updated} -> updated
      {:error, error} -> raise error
    end
  end

  @doc """
  Deletes a subscriber by email or ID.

  ## Examples

      iex> Listmonk.Subscribers.delete("user@example.com")
      {:ok, true}

      iex> Listmonk.Subscribers.delete(123)
      {:ok, true}
  """
  @spec delete(String.t() | integer(), Config.t() | nil) :: {:ok, boolean()} | {:error, Error.t()}
  def delete(identifier, config \\ nil)

  def delete(email, config) when is_binary(email) do
    case get_by_email(email, config) do
      {:ok, nil} -> {:ok, false}
      {:ok, %Subscriber{id: id}} -> delete(id, config)
      error -> error
    end
  end

  def delete(id, config) when is_integer(id) do
    case Client.delete("/api/subscribers/#{id}", config) do
      {:ok, %{"data" => result}} -> {:ok, result == true}
      error -> error
    end
  end

  @doc """
  Deletes a subscriber. Raises on error.
  """
  @spec delete!(String.t() | integer(), Config.t() | nil) :: boolean()
  def delete!(identifier, config \\ nil) do
    case delete(identifier, config) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc """
  Enables a subscriber.

  ## Examples

      iex> subscriber = Listmonk.Subscribers.get_by_id!(123)
      iex> Listmonk.Subscribers.enable(subscriber)
      {:ok, %Subscriber{status: :enabled}}
  """
  @spec enable(Subscriber.t(), Config.t() | nil) :: {:ok, Subscriber.t()} | {:error, Error.t()}
  def enable(subscriber, config \\ nil) do
    update(subscriber, %{status: :enabled}, config)
  end

  @doc """
  Enables a subscriber. Raises on error.
  """
  @spec enable!(Subscriber.t(), Config.t() | nil) :: Subscriber.t()
  def enable!(subscriber, config \\ nil) do
    case enable(subscriber, config) do
      {:ok, updated} -> updated
      {:error, error} -> raise error
    end
  end

  @doc """
  Disables a subscriber.

  ## Examples

      iex> subscriber = Listmonk.Subscribers.get_by_id!(123)
      iex> Listmonk.Subscribers.disable(subscriber)
      {:ok, %Subscriber{status: :disabled}}
  """
  @spec disable(Subscriber.t(), Config.t() | nil) :: {:ok, Subscriber.t()} | {:error, Error.t()}
  def disable(subscriber, config \\ nil) do
    update(subscriber, %{status: :disabled}, config)
  end

  @doc """
  Disables a subscriber. Raises on error.
  """
  @spec disable!(Subscriber.t(), Config.t() | nil) :: Subscriber.t()
  def disable!(subscriber, config \\ nil) do
    case disable(subscriber, config) do
      {:ok, updated} -> updated
      {:error, error} -> raise error
    end
  end

  @doc """
  Blocks (unsubscribes) a subscriber.

  ## Examples

      iex> subscriber = Listmonk.Subscribers.get_by_id!(123)
      iex> Listmonk.Subscribers.block(subscriber)
      {:ok, %Subscriber{status: :blocklisted}}
  """
  @spec block(Subscriber.t(), Config.t() | nil) :: {:ok, Subscriber.t()} | {:error, Error.t()}
  def block(subscriber, config \\ nil) do
    update(subscriber, %{status: :blocklisted}, config)
  end

  @doc """
  Blocks a subscriber. Raises on error.
  """
  @spec block!(Subscriber.t(), Config.t() | nil) :: Subscriber.t()
  def block!(subscriber, config \\ nil) do
    case block(subscriber, config) do
      {:ok, updated} -> updated
      {:error, error} -> raise error
    end
  end

  @doc """
  Confirms opt-in for a subscriber to a list.

  ## Examples

      iex> Listmonk.Subscribers.confirm_optin(subscriber_uuid, list_uuid)
      {:ok, true}
  """
  @spec confirm_optin(String.t(), String.t(), Config.t() | nil) ::
          {:ok, boolean()} | {:error, Error.t()}
  def confirm_optin(subscriber_uuid, list_uuid, config \\ nil) do
    payload = %{"l" => list_uuid, "confirm" => "true"}
    path = "/subscription/optin/#{subscriber_uuid}"

    case Client.post(path, config, form: payload) do
      {:ok, response} ->
        body = response["data"] || response
        success = check_optin_success(body)
        {:ok, success}

      error ->
        error
    end
  end

  @doc """
  Confirms opt-in. Raises on error.
  """
  @spec confirm_optin!(String.t(), String.t(), Config.t() | nil) :: boolean()
  def confirm_optin!(subscriber_uuid, list_uuid, config \\ nil) do
    case confirm_optin(subscriber_uuid, list_uuid, config) do
      {:ok, result} -> result
      {:error, error} -> raise error
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

  defp fetch_all_pages(initial_path, config, opts) do
    per_page = Keyword.get(opts, :per_page, 100)
    fetch_pages(initial_path, config, per_page, 1, [])
  end

  defp fetch_pages(path_template, config, per_page, page, acc) do
    path = String.replace(path_template, ~r/page=\d+/, "page=#{page}")

    case Client.get(path, config) do
      {:ok, %{"data" => %{"results" => results, "total" => total}}} ->
        new_acc = acc ++ results
        retrieved = page * per_page

        if retrieved < total do
          fetch_pages(path_template, config, per_page, page + 1, new_acc)
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
