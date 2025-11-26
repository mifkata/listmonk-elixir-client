defmodule Listmonk.Models.MailingList do
  @moduledoc """
  Struct representing a Listmonk mailing list.
  """

  @type list_type :: :public | :private
  @type optin :: :single | :double

  @type t :: %__MODULE__{
          id: integer() | nil,
          uuid: String.t() | nil,
          name: String.t() | nil,
          type: list_type() | nil,
          optin: optin() | nil,
          tags: list(String.t()) | nil,
          description: String.t() | nil,
          subscriber_count: integer() | nil,
          created_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  defstruct [
    :id,
    :uuid,
    :name,
    :type,
    :optin,
    :tags,
    :description,
    :subscriber_count,
    :created_at,
    :updated_at
  ]

  @doc """
  Creates a new mailing list struct from API response data.
  """
  @spec from_api(map()) :: t()
  def from_api(data) when is_map(data) do
    %__MODULE__{
      id: data["id"],
      uuid: data["uuid"],
      name: data["name"],
      type: parse_type(data["type"]),
      optin: parse_optin(data["optin"]),
      tags: data["tags"] || [],
      description: data["description"],
      subscriber_count: data["subscriber_count"],
      created_at: parse_datetime(data["created_at"]),
      updated_at: parse_datetime(data["updated_at"])
    }
  end

  @doc """
  Converts a mailing list struct to API request format.
  """
  @spec to_api(t()) :: map()
  def to_api(%__MODULE__{} = list) do
    %{
      "name" => list.name,
      "type" => type_to_string(list.type),
      "optin" => optin_to_string(list.optin),
      "tags" => list.tags || [],
      "description" => list.description
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp parse_type("public"), do: :public
  defp parse_type("private"), do: :private
  defp parse_type(_), do: :public

  defp type_to_string(:public), do: "public"
  defp type_to_string(:private), do: "private"
  defp type_to_string(nil), do: "public"

  defp parse_optin("single"), do: :single
  defp parse_optin("double"), do: :double
  defp parse_optin(_), do: :single

  defp optin_to_string(:single), do: "single"
  defp optin_to_string(:double), do: "double"
  defp optin_to_string(nil), do: "single"

  defp parse_datetime(nil), do: nil

  defp parse_datetime(datetime_string) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _offset} -> datetime
      {:error, _} -> nil
    end
  end

  defp parse_datetime(_), do: nil
end
