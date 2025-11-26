defmodule Listmonk.Models.Subscriber do
  @moduledoc """
  Struct representing a Listmonk subscriber.
  """

  @type status :: :enabled | :disabled | :blocklisted

  @type t :: %__MODULE__{
          id: integer() | nil,
          email: String.t() | nil,
          name: String.t() | nil,
          uuid: String.t() | nil,
          status: status() | nil,
          lists: list(map()) | nil,
          attribs: map() | nil,
          created_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  defstruct [
    :id,
    :email,
    :name,
    :uuid,
    :status,
    :lists,
    :attribs,
    :created_at,
    :updated_at
  ]

  @doc """
  Creates a new subscriber struct from API response data.
  """
  @spec from_api(map()) :: t()
  def from_api(data) when is_map(data) do
    %__MODULE__{
      id: data["id"],
      email: data["email"],
      name: data["name"],
      uuid: data["uuid"],
      status: parse_status(data["status"]),
      lists: data["lists"] || [],
      attribs: data["attribs"] || %{},
      created_at: parse_datetime(data["created_at"]),
      updated_at: parse_datetime(data["updated_at"])
    }
  end

  @doc """
  Converts a subscriber struct to API request format.
  """
  @spec to_api(t(), keyword()) :: map()
  def to_api(%__MODULE__{} = subscriber, opts \\ []) do
    list_ids = Keyword.get(opts, :list_ids, extract_list_ids(subscriber.lists))
    preconfirm = Keyword.get(opts, :preconfirm, true)

    %{
      "email" => subscriber.email,
      "name" => subscriber.name,
      "status" => status_to_string(subscriber.status),
      "lists" => list_ids,
      "attribs" => subscriber.attribs || %{},
      "preconfirm_subscriptions" => preconfirm
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp parse_status("enabled"), do: :enabled
  defp parse_status("disabled"), do: :disabled
  defp parse_status("blocklisted"), do: :blocklisted
  defp parse_status(_), do: nil

  defp status_to_string(:enabled), do: "enabled"
  defp status_to_string(:disabled), do: "disabled"
  defp status_to_string(:blocklisted), do: "blocklisted"
  defp status_to_string(nil), do: "enabled"

  defp parse_datetime(nil), do: nil

  defp parse_datetime(datetime_string) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _offset} -> datetime
      {:error, _} -> nil
    end
  end

  defp parse_datetime(_), do: nil

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
