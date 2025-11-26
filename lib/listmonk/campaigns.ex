defmodule Listmonk.Campaigns do
  @moduledoc """
  Functions for managing Listmonk campaigns.
  """

  alias Listmonk.{Client, Config, Error}
  alias Listmonk.Models.Campaign

  @doc """
  Retrieves all campaigns.

  ## Examples

      iex> Listmonk.Campaigns.get()
      {:ok, [%Campaign{}, ...]}
  """
  @spec get(Config.t() | nil) :: {:ok, list(Campaign.t())} | {:error, Error.t()}
  def get(config \\ nil) do
    path = "/api/campaigns?page=1&per_page=1000000"

    case Client.get(path, config) do
      {:ok, %{"data" => %{"results" => results}}} ->
        campaigns = Enum.map(results, &Campaign.from_api/1)
        {:ok, campaigns}

      error ->
        error
    end
  end

  @doc """
  Retrieves all campaigns. Raises on error.
  """
  @spec get!(Config.t() | nil) :: list(Campaign.t())
  def get!(config \\ nil) do
    case get(config) do
      {:ok, campaigns} -> campaigns
      {:error, error} -> raise error
    end
  end

  @doc """
  Retrieves a campaign by ID.

  ## Examples

      iex> Listmonk.Campaigns.get_by_id(15)
      {:ok, %Campaign{}}
  """
  @spec get_by_id(integer(), Config.t() | nil) :: {:ok, Campaign.t() | nil} | {:error, Error.t()}
  def get_by_id(id, config \\ nil) do
    path = "/api/campaigns/#{id}"

    case Client.get(path, config) do
      {:ok, %{"data" => data}} when is_map(data) and map_size(data) > 0 ->
        {:ok, Campaign.from_api(data)}

      {:ok, %{"data" => _}} ->
        {:ok, nil}

      error ->
        error
    end
  end

  @doc """
  Retrieves a campaign by ID. Raises on error.
  """
  @spec get_by_id!(integer(), Config.t() | nil) :: Campaign.t() | nil
  def get_by_id!(id, config \\ nil) do
    case get_by_id(id, config) do
      {:ok, campaign} -> campaign
      {:error, error} -> raise error
    end
  end

  @doc """
  Retrieves a campaign preview by ID.

  ## Examples

      iex> Listmonk.Campaigns.preview(15)
      {:ok, "<html>...</html>"}
  """
  @spec preview(integer(), Config.t() | nil) :: {:ok, String.t()} | {:error, Error.t()}
  def preview(id, config \\ nil) do
    path = "/api/campaigns/#{id}/preview"

    case Client.get(path, config) do
      {:ok, %{"data" => preview}} when is_binary(preview) -> {:ok, preview}
      {:ok, response} -> {:ok, to_string(response)}
      error -> error
    end
  end

  @doc """
  Retrieves a campaign preview. Raises on error.
  """
  @spec preview!(integer(), Config.t() | nil) :: String.t()
  def preview!(id, config \\ nil) do
    case preview(id, config) do
      {:ok, preview} -> preview
      {:error, error} -> raise error
    end
  end

  @doc """
  Creates a new campaign.

  ## Attributes

  - `:name` (required) - Campaign name
  - `:subject` (required) - Email subject
  - `:lists` - List IDs to send to (default: [1])
  - `:from_email` - From email address
  - `:type` - Campaign type (:regular or :optin), default: :regular
  - `:content_type` - Content type (:richtext, :html, :markdown, :plain), default: :richtext
  - `:body` - Email body content
  - `:altbody` - Alternative text body
  - `:send_at` - DateTime to schedule send
  - `:messenger` - Messenger type (default: "email")
  - `:template_id` - Template ID to use
  - `:tags` - List of tags
  - `:headers` - Custom email headers map

  ## Examples

      iex> Listmonk.Campaigns.create(%{
      ...>   name: "Monthly Newsletter",
      ...>   subject: "Great news this month!",
      ...>   lists: [1, 2],
      ...>   body: "<p>Hello!</p>"
      ...> })
      {:ok, %Campaign{}}
  """
  @spec create(map(), Config.t() | nil) :: {:ok, Campaign.t()} | {:error, Error.t()}
  def create(attrs, config \\ nil) do
    with {:ok, payload} <- build_create_payload(attrs) do
      case Client.post("/api/campaigns", config, json: payload) do
        {:ok, %{"data" => data}} -> {:ok, Campaign.from_api(data)}
        error -> error
      end
    end
  end

  @doc """
  Creates a new campaign. Raises on error.
  """
  @spec create!(map(), Config.t() | nil) :: Campaign.t()
  def create!(attrs, config \\ nil) do
    case create(attrs, config) do
      {:ok, campaign} -> campaign
      {:error, error} -> raise error
    end
  end

  @doc """
  Updates a campaign.

  ## Attributes

  Same as create/2 attributes.

  ## Examples

      iex> campaign = Listmonk.Campaigns.get_by_id!(15)
      iex> Listmonk.Campaigns.update(campaign, %{name: "Updated Name"})
      {:ok, %Campaign{}}
  """
  @spec update(Campaign.t(), map(), Config.t() | nil) :: {:ok, Campaign.t()} | {:error, Error.t()}
  def update(%Campaign{id: id} = campaign, attrs, config \\ nil) do
    updated_campaign = merge_campaign_attrs(campaign, attrs)
    payload = Campaign.to_api(updated_campaign, list_ids: get_list_ids(updated_campaign, attrs))

    # Handle send_at being in the past
    payload = normalize_send_at(payload)

    case Client.put("/api/campaigns/#{id}", config, json: payload) do
      {:ok, _response} -> get_by_id(id, config)
      error -> error
    end
  end

  @doc """
  Updates a campaign. Raises on error.
  """
  @spec update!(Campaign.t(), map(), Config.t() | nil) :: Campaign.t()
  def update!(campaign, attrs, config \\ nil) do
    case update(campaign, attrs, config) do
      {:ok, updated} -> updated
      {:error, error} -> raise error
    end
  end

  @doc """
  Deletes a campaign by ID.

  ## Examples

      iex> Listmonk.Campaigns.delete(15)
      {:ok, true}
  """
  @spec delete(integer(), Config.t() | nil) :: {:ok, boolean()} | {:error, Error.t()}
  def delete(id, config \\ nil) do
    case get_by_id(id, config) do
      {:ok, nil} ->
        {:ok, false}

      {:ok, _campaign} ->
        case Client.delete("/api/campaigns/#{id}", config) do
          {:ok, %{"data" => result}} -> {:ok, result == true}
          error -> error
        end

      error ->
        error
    end
  end

  @doc """
  Deletes a campaign. Raises on error.
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
    subject = Map.get(attrs, :subject) |> validate_required(:subject)
    lists = Map.get(attrs, :lists, [1])

    payload = %{
      "name" => name,
      "subject" => subject,
      "lists" => lists,
      "type" => campaign_type_to_string(Map.get(attrs, :type)),
      "content_type" => content_type_to_string(Map.get(attrs, :content_type)),
      "tags" => Map.get(attrs, :tags, []),
      "headers" => Map.get(attrs, :headers, %{})
    }

    payload = maybe_add_field(payload, attrs, :from_email, "from_email")
    payload = maybe_add_field(payload, attrs, :body, "body")
    payload = maybe_add_field(payload, attrs, :altbody, "altbody")
    payload = maybe_add_field(payload, attrs, :messenger, "messenger")
    payload = maybe_add_field(payload, attrs, :template_id, "template_id")

    payload =
      case Map.get(attrs, :send_at) do
        nil -> payload
        %DateTime{} = dt -> Map.put(payload, "send_at", DateTime.to_iso8601(dt))
        _ -> payload
      end

    {:ok, payload}
  rescue
    e in ArgumentError -> {:error, Error.new(e.message)}
  end

  defp campaign_type_to_string(:regular), do: "regular"
  defp campaign_type_to_string(:optin), do: "optin"
  defp campaign_type_to_string(nil), do: "regular"
  defp campaign_type_to_string(type) when is_binary(type), do: type

  defp content_type_to_string(:richtext), do: "richtext"
  defp content_type_to_string(:html), do: "html"
  defp content_type_to_string(:markdown), do: "markdown"
  defp content_type_to_string(:plain), do: "plain"
  defp content_type_to_string(nil), do: "richtext"
  defp content_type_to_string(type) when is_binary(type), do: type

  defp validate_required(nil, field), do: raise(ArgumentError, "#{field} is required")
  defp validate_required("", field), do: raise(ArgumentError, "#{field} is required")
  defp validate_required(value, _field), do: value

  defp maybe_add_field(payload, attrs, key, api_key) do
    case Map.get(attrs, key) do
      nil -> payload
      value -> Map.put(payload, api_key, value)
    end
  end

  defp merge_campaign_attrs(campaign, attrs) do
    %{
      campaign
      | name: Map.get(attrs, :name, campaign.name),
        subject: Map.get(attrs, :subject, campaign.subject),
        from_email: Map.get(attrs, :from_email, campaign.from_email),
        body: Map.get(attrs, :body, campaign.body),
        altbody: Map.get(attrs, :altbody, campaign.altbody),
        type: Map.get(attrs, :type, campaign.type),
        content_type: Map.get(attrs, :content_type, campaign.content_type),
        messenger: Map.get(attrs, :messenger, campaign.messenger),
        template_id: Map.get(attrs, :template_id, campaign.template_id),
        tags: Map.get(attrs, :tags, campaign.tags),
        headers: Map.get(attrs, :headers, campaign.headers),
        send_at: Map.get(attrs, :send_at, campaign.send_at)
    }
  end

  defp get_list_ids(campaign, attrs) do
    Map.get(attrs, :lists) || extract_campaign_list_ids(campaign.lists)
  end

  defp extract_campaign_list_ids(nil), do: []
  defp extract_campaign_list_ids([]), do: []

  defp extract_campaign_list_ids(lists) when is_list(lists) do
    Enum.map(lists, fn
      %{"id" => id} -> id
      id when is_integer(id) -> id
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp normalize_send_at(%{"send_at" => send_at} = payload) when is_binary(send_at) do
    case DateTime.from_iso8601(send_at) do
      {:ok, datetime, _offset} ->
        if DateTime.compare(datetime, DateTime.utc_now()) == :lt do
          Map.delete(payload, "send_at")
        else
          payload
        end

      _ ->
        payload
    end
  end

  defp normalize_send_at(payload), do: payload
end
