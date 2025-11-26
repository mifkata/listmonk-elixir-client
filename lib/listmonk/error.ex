defmodule Listmonk.Error do
  @moduledoc """
  Exception struct for Listmonk API errors.
  """

  defexception [:message, :status_code, :response_body]

  @type t :: %__MODULE__{
          message: String.t(),
          status_code: integer() | nil,
          response_body: term() | nil
        }

  @doc """
  Creates a new error with the given message.
  """
  @spec new(String.t(), keyword()) :: t()
  def new(message, opts \\ []) do
    %__MODULE__{
      message: message,
      status_code: Keyword.get(opts, :status_code),
      response_body: Keyword.get(opts, :response_body)
    }
  end

  @doc """
  Creates an error from an HTTP response.
  """
  @spec from_response(Req.Response.t()) :: t()
  def from_response(%Req.Response{status: status, body: body}) do
    message = parse_error_message(body, status)

    %__MODULE__{
      message: message,
      status_code: status,
      response_body: body
    }
  end

  defp parse_error_message(body, status) when is_map(body) do
    cond do
      Map.has_key?(body, "message") -> body["message"]
      Map.has_key?(body, "error") -> body["error"]
      true -> "HTTP #{status}: #{inspect(body)}"
    end
  end

  defp parse_error_message(body, status) when is_binary(body) do
    "HTTP #{status}: #{body}"
  end

  defp parse_error_message(_body, status) do
    "HTTP #{status}"
  end
end
