defmodule Listmonk.Models.Template do
  @moduledoc """
  Struct representing a Listmonk template.
  """

  @type template_type :: :campaign | :tx

  @type t :: %__MODULE__{
          id: integer() | nil,
          name: String.t() | nil,
          subject: String.t() | nil,
          body: String.t() | nil,
          type: template_type() | nil,
          is_default: boolean() | nil,
          created_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  defstruct [
    :id,
    :name,
    :subject,
    :body,
    :type,
    :is_default,
    :created_at,
    :updated_at
  ]

  @doc """
  Creates a new template struct from API response data.
  """
  @spec from_api(map()) :: t()
  def from_api(data) when is_map(data) do
    %__MODULE__{
      id: data["id"],
      name: data["name"],
      subject: data["subject"],
      body: data["body"],
      type: parse_type(data["type"]),
      is_default: data["is_default"],
      created_at: parse_datetime(data["created_at"]),
      updated_at: parse_datetime(data["updated_at"])
    }
  end

  @doc """
  Converts a template struct to API request format.
  """
  @spec to_api(t()) :: map()
  def to_api(%__MODULE__{} = template) do
    %{
      "name" => template.name,
      "subject" => template.subject,
      "body" => template.body,
      "type" => type_to_string(template.type),
      "is_default" => template.is_default || false
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp parse_type("campaign"), do: :campaign
  defp parse_type("tx"), do: :tx
  defp parse_type(_), do: :campaign

  defp type_to_string(:campaign), do: "campaign"
  defp type_to_string(:tx), do: "tx"
  defp type_to_string(nil), do: "campaign"

  defp parse_datetime(nil), do: nil

  defp parse_datetime(datetime_string) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _offset} -> datetime
      {:error, _} -> nil
    end
  end

  defp parse_datetime(_), do: nil
end
