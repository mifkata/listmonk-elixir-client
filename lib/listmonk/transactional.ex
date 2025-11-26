defmodule Listmonk.Transactional do
  @moduledoc """
  Functions for sending transactional emails via Listmonk.
  """

  alias Listmonk.{Client, Config, Error}

  @doc """
  Sends a transactional email.

  ## Attributes

  - `:subscriber_email` (required) - Recipient email address
  - `:template_id` (required) - TX template ID to use
  - `:from_email` - From email address (optional, uses default if not provided)
  - `:data` - Template data map (available as `{{ .Tx.Data.* }}`)
  - `:messenger` - Messenger type (default: "email")
  - `:content_type` - Content type (:html, :markdown, :plain), default: :html
  - `:attachments` - List of file paths to attach
  - `:headers` - List of custom email headers (e.g., `[%{"X-Custom" => "value"}]`)

  ## Examples

      iex> Listmonk.Transactional.send_email(%{
      ...>   subscriber_email: "user@example.com",
      ...>   template_id: 3,
      ...>   from_email: "app@example.com",
      ...>   data: %{
      ...>     full_name: "John Doe",
      ...>     reset_code: "abc123"
      ...>   }
      ...> })
      {:ok, true}

      iex> Listmonk.Transactional.send_email(%{
      ...>   subscriber_email: "user@example.com",
      ...>   template_id: 3,
      ...>   attachments: ["/path/to/file.pdf"]
      ...> })
      {:ok, true}
  """
  @spec send_email(map(), Config.t() | nil) :: {:ok, boolean()} | {:error, Error.t()}
  def send_email(attrs, config \\ nil) do
    with {:ok, email, attachments} <- validate_and_prepare(attrs) do
      send_request(email, attachments, config)
    end
  end

  @doc """
  Sends a transactional email. Raises on error.
  """
  @spec send_email!(map(), Config.t() | nil) :: boolean()
  def send_email!(attrs, config \\ nil) do
    case send_email(attrs, config) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  # Private functions

  defp validate_and_prepare(attrs) do
    subscriber_email =
      Map.get(attrs, :subscriber_email)
      |> validate_required(:subscriber_email)
      |> String.trim()
      |> String.downcase()

    template_id = Map.get(attrs, :template_id) |> validate_required(:template_id)

    email_data = %{
      "subscriber_email" => subscriber_email,
      "template_id" => template_id,
      "data" => Map.get(attrs, :data, %{}),
      "messenger" => Map.get(attrs, :messenger, "email"),
      "content_type" => content_type_to_string(Map.get(attrs, :content_type, :html)),
      "headers" => Map.get(attrs, :headers, [])
    }

    email_data =
      case Map.get(attrs, :from_email) do
        nil -> email_data
        from_email -> Map.put(email_data, "from_email", from_email)
      end

    attachments = validate_attachments(Map.get(attrs, :attachments, []))

    {:ok, email_data, attachments}
  rescue
    e in ArgumentError -> {:error, Error.new(e.message)}
  end

  defp send_request(email_data, [], config) do
    # No attachments - send as JSON
    case Client.post("/api/tx", config, json: email_data) do
      {:ok, %{"data" => result}} -> {:ok, result == true}
      error -> error
    end
  end

  defp send_request(email_data, attachments, config) do
    # With attachments - send as multipart form data
    with {:ok, resolved_config} <- resolve_and_validate_config(config) do
      url = build_url(resolved_config.url, "/api/tx")

      # Prepare multipart form data
      multipart =
        {:multipart,
         [
           {"data", Jason.encode!(email_data), [{"content-type", "application/json"}]}
           | build_file_parts(attachments)
         ]}

      req_opts = [
        method: :post,
        url: url,
        auth: {:basic, "#{resolved_config.username}:#{resolved_config.password}"},
        body: multipart,
        receive_timeout: 30_000
      ]

      case Req.request(req_opts) do
        {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
          result = get_in(body, ["data"]) || body
          {:ok, result == true}

        {:ok, %Req.Response{} = response} ->
          {:error, Error.from_response(response)}

        {:error, exception} ->
          {:error, Error.new("Request failed: #{Exception.message(exception)}")}
      end
    end
  end

  defp validate_required(nil, field), do: raise(ArgumentError, "#{field} is required")
  defp validate_required(value, _field), do: value

  defp content_type_to_string(:html), do: "html"
  defp content_type_to_string(:markdown), do: "markdown"
  defp content_type_to_string(:plain), do: "plain"
  defp content_type_to_string(type) when is_binary(type), do: type

  defp validate_attachments([]), do: []

  defp validate_attachments(attachments) when is_list(attachments) do
    Enum.map(attachments, fn path ->
      unless File.exists?(path) do
        raise ArgumentError, "Attachment file not found: #{path}"
      end

      unless File.regular?(path) do
        raise ArgumentError, "Attachment path is not a file: #{path}"
      end

      path
    end)
  end

  defp build_file_parts(attachments) do
    Enum.map(attachments, fn path ->
      filename = Path.basename(path)
      content = File.read!(path)
      {"file", content, [{"filename", filename}], []}
    end)
  end

  defp resolve_and_validate_config(nil) do
    config = Config.resolve(nil)

    case Config.validate(config) do
      :ok -> {:ok, config}
      {:error, message} -> {:error, Error.new(message)}
    end
  end

  defp resolve_and_validate_config(%Config{} = config) do
    resolved = Config.resolve(config)

    case Config.validate(resolved) do
      :ok -> {:ok, resolved}
      {:error, message} -> {:error, Error.new(message)}
    end
  end

  defp build_url(base_url, path) do
    base_url = String.trim_trailing(base_url, "/")
    path = if String.starts_with?(path, "/"), do: path, else: "/#{path}"
    base_url <> path
  end
end
