defmodule Listmonk.Client do
  @moduledoc """
  HTTP client for interacting with the Listmonk API.

  This module handles all HTTP communication with the Listmonk server,
  including authentication, request building, and response parsing.
  """

  alias Listmonk.{Config, Error}

  @user_agent "Listmonk-Elixir-Client/0.1.0"

  @doc """
  Checks if the Listmonk instance is healthy.

  ## Examples

      iex> Listmonk.Client.healthy?()
      {:ok, true}
  """
  @spec healthy?(Config.t() | nil) :: {:ok, boolean()} | {:error, term()}
  def healthy?(config \\ nil) do
    with {:ok, config} <- resolve_config(config),
         {:ok, response} <- get("/api/health", config) do
      {:ok, get_in(response, ["data"]) == true}
    end
  end

  @doc """
  Checks if the Listmonk instance is healthy. Raises on error.
  """
  @spec healthy!(Config.t() | nil) :: boolean()
  def healthy!(config \\ nil) do
    case healthy?(config) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc """
  Makes a GET request to the Listmonk API.

  ## Examples

      iex> Listmonk.Client.get("/api/lists", config)
      {:ok, %{"data" => %{"results" => [...]}}}
  """
  @spec get(String.t(), Config.t() | nil, keyword()) :: {:ok, map()} | {:error, Error.t()}
  def get(path, config, opts \\ []) do
    request(:get, path, config, opts)
  end

  @doc """
  Makes a GET request to the Listmonk API. Raises on error.
  """
  @spec get!(String.t(), Config.t() | nil, keyword()) :: map()
  def get!(path, config, opts \\ []) do
    case get(path, config, opts) do
      {:ok, response} -> response
      {:error, error} -> raise error
    end
  end

  @doc """
  Makes a POST request to the Listmonk API.

  ## Examples

      iex> Listmonk.Client.post("/api/subscribers", config, json: %{email: "test@example.com"})
      {:ok, %{"data" => %{...}}}
  """
  @spec post(String.t(), Config.t() | nil, keyword()) :: {:ok, map()} | {:error, Error.t()}
  def post(path, config, opts \\ []) do
    request(:post, path, config, opts)
  end

  @doc """
  Makes a POST request to the Listmonk API. Raises on error.
  """
  @spec post!(String.t(), Config.t() | nil, keyword()) :: map()
  def post!(path, config, opts \\ []) do
    case post(path, config, opts) do
      {:ok, response} -> response
      {:error, error} -> raise error
    end
  end

  @doc """
  Makes a PUT request to the Listmonk API.

  ## Examples

      iex> Listmonk.Client.put("/api/subscribers/1", config, json: %{name: "Updated"})
      {:ok, %{"data" => %{...}}}
  """
  @spec put(String.t(), Config.t() | nil, keyword()) :: {:ok, map()} | {:error, Error.t()}
  def put(path, config, opts \\ []) do
    request(:put, path, config, opts)
  end

  @doc """
  Makes a PUT request to the Listmonk API. Raises on error.
  """
  @spec put!(String.t(), Config.t() | nil, keyword()) :: map()
  def put!(path, config, opts \\ []) do
    case put(path, config, opts) do
      {:ok, response} -> response
      {:error, error} -> raise error
    end
  end

  @doc """
  Makes a DELETE request to the Listmonk API.

  ## Examples

      iex> Listmonk.Client.delete("/api/subscribers/1", config)
      {:ok, %{"data" => true}}
  """
  @spec delete(String.t(), Config.t() | nil, keyword()) :: {:ok, map()} | {:error, Error.t()}
  def delete(path, config, opts \\ []) do
    request(:delete, path, config, opts)
  end

  @doc """
  Makes a DELETE request to the Listmonk API. Raises on error.
  """
  @spec delete!(String.t(), Config.t() | nil, keyword()) :: map()
  def delete!(path, config, opts \\ []) do
    case delete(path, config, opts) do
      {:ok, response} -> response
      {:error, error} -> raise error
    end
  end

  # Private functions

  defp request(method, path, config, opts) do
    with {:ok, config} <- resolve_config(config),
         :ok <- Config.validate(config) do
      url = build_url(config.url, path)

      req_opts =
        [
          method: method,
          url: url,
          auth: {:basic, "#{config.username}:#{config.password}"},
          headers: [{"user-agent", @user_agent}],
          receive_timeout: 30_000
        ]
        |> Keyword.merge(opts)

      case Req.request(req_opts) do
        {:ok, %Req.Response{status: status} = response} when status in 200..299 ->
          parse_response(response)

        {:ok, %Req.Response{} = response} ->
          {:error, Error.from_response(response)}

        {:error, exception} ->
          {:error, Error.new("Request failed: #{Exception.message(exception)}")}
      end
    end
  end

  defp resolve_config(nil), do: {:ok, Config.resolve(nil)}
  defp resolve_config(%Config{} = config), do: {:ok, Config.resolve(config)}

  defp resolve_config(_) do
    {:error, Error.new("Invalid configuration provided")}
  end

  defp build_url(base_url, path) do
    base_url = String.trim_trailing(base_url, "/")
    path = if String.starts_with?(path, "/"), do: path, else: "/#{path}"
    base_url <> path
  end

  defp parse_response(%Req.Response{body: body}) when is_map(body) do
    {:ok, body}
  end

  defp parse_response(%Req.Response{body: body}) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} -> {:ok, decoded}
      {:error, _} -> {:ok, %{"data" => body}}
    end
  end

  defp parse_response(%Req.Response{body: body}) do
    {:ok, %{"data" => body}}
  end
end
