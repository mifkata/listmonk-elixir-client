defmodule Listmonk.Server do
  @moduledoc """
  GenServer implementation for maintaining Listmonk client state.

  This module manages the client configuration and provides a process-based
  interface for interacting with the Listmonk API.

  ## Usage

      # Start with an alias (named process)
      {:ok, pid} = Listmonk.new(config, :my_listmonk)
      {:ok, lists} = Listmonk.get_lists(:my_listmonk)

      # Start without a name (use pid)
      {:ok, pid} = Listmonk.new(config)
      {:ok, lists} = Listmonk.get_lists(pid)

      # Update configuration at runtime
      :ok = Listmonk.set_config(:my_listmonk, new_config)

      # Get current configuration
      config = Listmonk.get_config(:my_listmonk)
  """

  use GenServer
  alias Listmonk.{Config, Error}

  @type server :: pid() | atom()

  ## Client API

  @doc """
  Starts a new Listmonk client process.

  ## Options

  - `:name` - Optional name to register the process under
  - `:config` - Configuration struct (required)

  ## Examples

      # Start with a PID reference
      {:ok, pid} = Listmonk.Server.start_link(config: config)

      # Start with a named reference
      {:ok, pid} = Listmonk.Server.start_link(config: config, name: :my_client)
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    config = Keyword.fetch!(opts, :config) |> normalize_config()

    case Config.validate(config) do
      :ok ->
        if name do
          GenServer.start_link(__MODULE__, config, name: name)
        else
          GenServer.start_link(__MODULE__, config)
        end

      {:error, message} ->
        {:error, Error.new(message)}
    end
  end

  @doc """
  Gets the current configuration from the server process.

  ## Examples

      iex> config = Listmonk.Server.get_config(pid)
      %Listmonk.Config{...}

      iex> config = Listmonk.Server.get_config(:my_listmonk)
      %Listmonk.Config{...}
  """
  @spec get_config(server()) :: Config.t()
  def get_config(server) do
    GenServer.call(server, :get_config)
  end

  @doc """
  Updates the configuration of the server process.

  ## Examples

      iex> new_config = %Listmonk.Config{url: "https://new.example.com", ...}
      iex> Listmonk.Server.set_config(pid, new_config)
      :ok
  """
  @spec set_config(server(), Config.t()) :: :ok | {:error, Error.t()}
  def set_config(server, new_config) do
    GenServer.call(server, {:set_config, new_config})
  end

  @doc """
  Stops the server process.

  ## Examples

      iex> Listmonk.Server.stop(:my_listmonk)
      :ok
  """
  @spec stop(server()) :: :ok
  def stop(server) do
    GenServer.stop(server)
  end

  @doc """
  Makes an HTTP request through the server process.

  This is used internally by API modules.
  """
  @spec request(server(), atom(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def request(server, method, path, opts \\ []) do
    GenServer.call(server, {:request, method, path, opts}, :infinity)
  end

  ## GenServer Callbacks

  @impl true
  def init(config) do
    {:ok, config}
  end

  @impl true
  def handle_call(:get_config, _from, config) do
    {:reply, config, config}
  end

  @impl true
  def handle_call({:set_config, new_config}, _from, _config) do
    case Config.validate(new_config) do
      :ok ->
        {:reply, :ok, new_config}

      {:error, message} ->
        {:reply, {:error, Error.new(message)}, new_config}
    end
  end

  @impl true
  def handle_call({:request, method, path, opts}, _from, config) do
    result = do_request(method, path, config, opts)
    {:reply, result, config}
  end

  ## Private Functions

  @user_agent "Listmonk-Elixir-Client/0.3.0"

  defp normalize_config(%Config{} = config), do: config
  defp normalize_config(opts) when is_list(opts), do: Config.new(opts)

  defp do_request(method, path, config, opts) do
    url = build_url(config.url, path)

    req_opts =
      [
        method: method,
        url: url,
        auth: {:basic, "#{config.username}:#{config.password}"},
        headers: [{"user-agent", @user_agent}],
        receive_timeout: 30_000,
        retry: false
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
