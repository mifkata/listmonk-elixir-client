defmodule Listmonk.Config do
  @moduledoc """
  Configuration struct for Listmonk API client.

  Configuration can be provided either through environment variables or at runtime.
  Runtime configuration takes precedence over environment variables.

  ## Environment Variables

  - `LISTMONK_URL` - The base URL of your Listmonk instance
  - `LISTMONK_USERNAME` - Username or API user
  - `LISTMONK_PASSWORD` - Password or API key

  ## Runtime Configuration

      config = %Listmonk.Config{
        url: "https://listmonk.example.com",
        username: "admin",
        password: "secret"
      }

  """

  @type t :: %__MODULE__{
          url: String.t() | nil,
          username: String.t() | nil,
          password: String.t() | nil
        }

  defstruct [:url, :username, :password]

  @doc """
  Creates a new configuration struct with the given options.

  ## Examples

      iex> Listmonk.Config.new(url: "https://listmonk.example.com")
      %Listmonk.Config{url: "https://listmonk.example.com", username: nil, password: nil}
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    %__MODULE__{
      url: Keyword.get(opts, :url),
      username: Keyword.get(opts, :username),
      password: Keyword.get(opts, :password)
    }
  end

  @doc """
  Resolves configuration by merging runtime config with environment variables.

  Runtime values take precedence over environment variables.

  ## Examples

      iex> Listmonk.Config.resolve(nil)
      %Listmonk.Config{url: "https://...", username: "...", password: "..."}

      iex> config = %Listmonk.Config{url: "https://custom.com"}
      iex> Listmonk.Config.resolve(config)
      %Listmonk.Config{url: "https://custom.com", username: "...", password: "..."}
  """
  @spec resolve(t() | nil) :: t()
  def resolve(nil) do
    from_env()
  end

  def resolve(%__MODULE__{} = config) do
    env_config = from_env()

    %__MODULE__{
      url: config.url || env_config.url,
      username: config.username || env_config.username,
      password: config.password || env_config.password
    }
  end

  @doc """
  Validates that all required configuration fields are present.

  ## Examples

      iex> config = %Listmonk.Config{url: "https://example.com", username: "user", password: "pass"}
      iex> Listmonk.Config.validate(config)
      :ok

      iex> config = %Listmonk.Config{url: nil}
      iex> Listmonk.Config.validate(config)
      {:error, "Missing required configuration: url"}
  """
  @spec validate(t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{url: nil}), do: {:error, "Missing required configuration: url"}
  def validate(%__MODULE__{username: nil}), do: {:error, "Missing required configuration: username"}
  def validate(%__MODULE__{password: nil}), do: {:error, "Missing required configuration: password"}

  def validate(%__MODULE__{url: url}) do
    if String.starts_with?(url, "http://") or String.starts_with?(url, "https://") do
      :ok
    else
      {:error, "URL must start with http:// or https://"}
    end
  end

  @doc """
  Validates configuration and raises if invalid.

  ## Examples

      iex> config = %Listmonk.Config{url: "https://example.com", username: "user", password: "pass"}
      iex> Listmonk.Config.validate!(config)
      :ok
  """
  @spec validate!(t()) :: :ok
  def validate!(config) do
    case validate(config) do
      :ok -> :ok
      {:error, message} -> raise Listmonk.Error, message: message
    end
  end

  @doc """
  Loads configuration from environment variables.

  ## Examples

      iex> Listmonk.Config.from_env()
      %Listmonk.Config{url: "...", username: "...", password: "..."}
  """
  @spec from_env() :: t()
  def from_env do
    %__MODULE__{
      url: get_env("LISTMONK_URL"),
      username: get_env("LISTMONK_USERNAME"),
      password: get_env("LISTMONK_PASSWORD")
    }
  end

  defp get_env(key) do
    System.get_env(key) |> normalize_value()
  end

  defp normalize_value(nil), do: nil
  defp normalize_value(""), do: nil

  defp normalize_value(value) when is_binary(value) do
    trimmed = String.trim(value)
    if trimmed == "", do: nil, else: trimmed
  end
end
