defmodule Listmonk.Models.Campaign do
  @moduledoc """
  Struct representing a Listmonk campaign.
  """

  @type campaign_type :: :regular | :optin
  @type content_type :: :richtext | :html | :markdown | :plain
  @type status :: :draft | :scheduled | :running | :paused | :finished | :cancelled

  @type t :: %__MODULE__{
          id: integer() | nil,
          uuid: String.t() | nil,
          name: String.t() | nil,
          subject: String.t() | nil,
          from_email: String.t() | nil,
          body: String.t() | nil,
          altbody: String.t() | nil,
          type: campaign_type() | nil,
          content_type: content_type() | nil,
          status: status() | nil,
          lists: list(map()) | nil,
          tags: list(String.t()) | nil,
          template_id: integer() | nil,
          messenger: String.t() | nil,
          headers: map() | nil,
          send_at: DateTime.t() | nil,
          started_at: DateTime.t() | nil,
          to_send: integer() | nil,
          sent: integer() | nil,
          views: integer() | nil,
          clicks: integer() | nil,
          created_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  defstruct [
    :id,
    :uuid,
    :name,
    :subject,
    :from_email,
    :body,
    :altbody,
    :type,
    :content_type,
    :status,
    :lists,
    :tags,
    :template_id,
    :messenger,
    :headers,
    :send_at,
    :started_at,
    :to_send,
    :sent,
    :views,
    :clicks,
    :created_at,
    :updated_at
  ]

  @doc """
  Creates a new campaign struct from API response data.
  """
  @spec from_api(map()) :: t()
  def from_api(data) when is_map(data) do
    %__MODULE__{
      id: data["id"],
      uuid: data["uuid"],
      name: data["name"],
      subject: data["subject"],
      from_email: data["from_email"],
      body: data["body"],
      altbody: data["altbody"],
      type: parse_campaign_type(data["type"]),
      content_type: parse_content_type(data["content_type"]),
      status: parse_status(data["status"]),
      lists: data["lists"] || [],
      tags: data["tags"] || [],
      template_id: data["template_id"],
      messenger: data["messenger"],
      headers: data["headers"] || %{},
      send_at: parse_datetime(data["send_at"]),
      started_at: parse_datetime(data["started_at"]),
      to_send: data["to_send"],
      sent: data["sent"],
      views: data["views"],
      clicks: data["clicks"],
      created_at: parse_datetime(data["created_at"]),
      updated_at: parse_datetime(data["updated_at"])
    }
  end

  @doc """
  Converts a campaign struct to API request format.
  """
  @spec to_api(t(), keyword()) :: map()
  def to_api(%__MODULE__{} = campaign, opts \\ []) do
    list_ids = Keyword.get(opts, :list_ids, extract_list_ids(campaign.lists))

    %{
      "name" => campaign.name,
      "subject" => campaign.subject,
      "from_email" => campaign.from_email,
      "body" => campaign.body,
      "altbody" => campaign.altbody,
      "type" => campaign_type_to_string(campaign.type),
      "content_type" => content_type_to_string(campaign.content_type),
      "lists" => list_ids,
      "tags" => campaign.tags || [],
      "template_id" => campaign.template_id,
      "messenger" => campaign.messenger,
      "headers" => campaign.headers || %{},
      "send_at" => format_datetime(campaign.send_at)
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp parse_campaign_type("regular"), do: :regular
  defp parse_campaign_type("optin"), do: :optin
  defp parse_campaign_type(_), do: :regular

  defp campaign_type_to_string(:regular), do: "regular"
  defp campaign_type_to_string(:optin), do: "optin"
  defp campaign_type_to_string(nil), do: "regular"

  defp parse_content_type("richtext"), do: :richtext
  defp parse_content_type("html"), do: :html
  defp parse_content_type("markdown"), do: :markdown
  defp parse_content_type("plain"), do: :plain
  defp parse_content_type(_), do: :richtext

  defp content_type_to_string(:richtext), do: "richtext"
  defp content_type_to_string(:html), do: "html"
  defp content_type_to_string(:markdown), do: "markdown"
  defp content_type_to_string(:plain), do: "plain"
  defp content_type_to_string(nil), do: "richtext"

  defp parse_status("draft"), do: :draft
  defp parse_status("scheduled"), do: :scheduled
  defp parse_status("running"), do: :running
  defp parse_status("paused"), do: :paused
  defp parse_status("finished"), do: :finished
  defp parse_status("cancelled"), do: :cancelled
  defp parse_status(_), do: :draft

  defp parse_datetime(nil), do: nil

  defp parse_datetime(datetime_string) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _offset} -> datetime
      {:error, _} -> nil
    end
  end

  defp parse_datetime(_), do: nil

  defp format_datetime(nil), do: nil

  defp format_datetime(%DateTime{} = datetime) do
    DateTime.to_iso8601(datetime)
  end

  defp extract_list_ids(nil), do: []
  defp extract_list_ids([]), do: []

  defp extract_list_ids(lists) when is_list(lists) do
    Enum.map(lists, fn
      %{"id" => id} -> id
      id when is_integer(id) -> id
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)
  end
end
