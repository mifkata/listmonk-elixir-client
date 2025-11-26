defmodule Listmonk.Templates do
  @moduledoc """
  Functions for managing Listmonk templates.
  """

  alias Listmonk.{Client, Config, Error}
  alias Listmonk.Models.Template

  @doc """
  Retrieves all templates.

  ## Examples

      iex> Listmonk.Templates.get()
      {:ok, [%Template{}, ...]}
  """
  @spec get(Config.t() | nil) :: {:ok, list(Template.t())} | {:error, Error.t()}
  def get(config \\ nil) do
    path = "/api/templates?page=1&per_page=1000000"

    case Client.get(path, config) do
      {:ok, %{"data" => results}} when is_list(results) ->
        templates = Enum.map(results, &Template.from_api/1)
        {:ok, templates}

      error ->
        error
    end
  end

  @doc """
  Retrieves all templates. Raises on error.
  """
  @spec get!(Config.t() | nil) :: list(Template.t())
  def get!(config \\ nil) do
    case get(config) do
      {:ok, templates} -> templates
      {:error, error} -> raise error
    end
  end

  @doc """
  Retrieves a template by ID.

  ## Examples

      iex> Listmonk.Templates.get_by_id(2)
      {:ok, %Template{}}
  """
  @spec get_by_id(integer(), Config.t() | nil) :: {:ok, Template.t() | nil} | {:error, Error.t()}
  def get_by_id(id, config \\ nil) do
    path = "/api/templates/#{id}"

    case Client.get(path, config) do
      {:ok, %{"data" => data}} when is_map(data) and map_size(data) > 0 ->
        {:ok, Template.from_api(data)}

      {:ok, %{"data" => _}} ->
        {:ok, nil}

      error ->
        error
    end
  end

  @doc """
  Retrieves a template by ID. Raises on error.
  """
  @spec get_by_id!(integer(), Config.t() | nil) :: Template.t() | nil
  def get_by_id!(id, config \\ nil) do
    case get_by_id(id, config) do
      {:ok, template} -> template
      {:error, error} -> raise error
    end
  end

  @doc """
  Retrieves a template preview by ID.

  ## Examples

      iex> Listmonk.Templates.preview(3)
      {:ok, "<html>...</html>"}
  """
  @spec preview(integer(), Config.t() | nil) :: {:ok, String.t()} | {:error, Error.t()}
  def preview(id, config \\ nil) do
    path = "/api/templates/#{id}/preview"

    case Client.get(path, config) do
      {:ok, %{"data" => preview}} when is_binary(preview) -> {:ok, preview}
      {:ok, response} -> {:ok, to_string(response)}
      error -> error
    end
  end

  @doc """
  Retrieves a template preview. Raises on error.
  """
  @spec preview!(integer(), Config.t() | nil) :: String.t()
  def preview!(id, config \\ nil) do
    case preview(id, config) do
      {:ok, preview} -> preview
      {:error, error} -> raise error
    end
  end

  @doc """
  Creates a new template.

  ## Attributes

  - `:name` (required) - Template name
  - `:body` (required) - Template body HTML (must include `{{ template "content" . }}`)
  - `:type` - Template type (:campaign or :tx), default: :campaign
  - `:subject` - Default subject (for tx templates)
  - `:is_default` - Set as default template, default: false

  ## Examples

      iex> Listmonk.Templates.create(%{
      ...>   name: "My Template",
      ...>   body: "<html><body>{{ template \\"content\\" . }}</body></html>",
      ...>   type: :campaign
      ...> })
      {:ok, %Template{}}
  """
  @spec create(map(), Config.t() | nil) :: {:ok, Template.t()} | {:error, Error.t()}
  def create(attrs, config \\ nil) do
    with {:ok, payload} <- build_create_payload(attrs) do
      case Client.post("/api/templates", config, json: payload) do
        {:ok, %{"data" => data}} -> {:ok, Template.from_api(data)}
        error -> error
      end
    end
  end

  @doc """
  Creates a new template. Raises on error.
  """
  @spec create!(map(), Config.t() | nil) :: Template.t()
  def create!(attrs, config \\ nil) do
    case create(attrs, config) do
      {:ok, template} -> template
      {:error, error} -> raise error
    end
  end

  @doc """
  Updates a template.

  ## Attributes

  Same as create/2 attributes.

  ## Examples

      iex> template = Listmonk.Templates.get_by_id!(2)
      iex> Listmonk.Templates.update(template, %{name: "Updated Template"})
      {:ok, %Template{}}
  """
  @spec update(Template.t(), map(), Config.t() | nil) :: {:ok, Template.t()} | {:error, Error.t()}
  def update(%Template{id: id} = template, attrs, config \\ nil) do
    updated_template = merge_template_attrs(template, attrs)
    payload = Template.to_api(updated_template)

    case Client.put("/api/templates/#{id}", config, json: payload) do
      {:ok, _response} -> get_by_id(id, config)
      error -> error
    end
  end

  @doc """
  Updates a template. Raises on error.
  """
  @spec update!(Template.t(), map(), Config.t() | nil) :: Template.t()
  def update!(template, attrs, config \\ nil) do
    case update(template, attrs, config) do
      {:ok, updated} -> updated
      {:error, error} -> raise error
    end
  end

  @doc """
  Deletes a template by ID.

  ## Examples

      iex> Listmonk.Templates.delete(3)
      {:ok, true}
  """
  @spec delete(integer(), Config.t() | nil) :: {:ok, boolean()} | {:error, Error.t()}
  def delete(id, config \\ nil) do
    case get_by_id(id, config) do
      {:ok, nil} ->
        {:ok, false}

      {:ok, _template} ->
        case Client.delete("/api/templates/#{id}", config) do
          {:ok, %{"data" => result}} -> {:ok, result == true}
          error -> error
        end

      error ->
        error
    end
  end

  @doc """
  Deletes a template. Raises on error.
  """
  @spec delete!(integer(), Config.t() | nil) :: boolean()
  def delete!(id, config \\ nil) do
    case delete(id, config) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc """
  Sets a template as the default template.

  ## Examples

      iex> Listmonk.Templates.set_default(2)
      {:ok, true}
  """
  @spec set_default(integer(), Config.t() | nil) :: {:ok, boolean()} | {:error, Error.t()}
  def set_default(id, config \\ nil) do
    case get_by_id(id, config) do
      {:ok, nil} ->
        {:ok, false}

      {:ok, _template} ->
        case Client.put("/api/templates/#{id}/default", config) do
          {:ok, %{"data" => result}} -> {:ok, result == true}
          error -> error
        end

      error ->
        error
    end
  end

  @doc """
  Sets a template as default. Raises on error.
  """
  @spec set_default!(integer(), Config.t() | nil) :: boolean()
  def set_default!(id, config \\ nil) do
    case set_default(id, config) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  # Private functions

  defp build_create_payload(attrs) do
    name = Map.get(attrs, :name) |> validate_required(:name) |> String.trim()
    body = Map.get(attrs, :body) |> validate_required(:body)

    unless String.contains?(body, ~s({{ template "content" . }})) do
      raise ArgumentError,
            ~s(The placeholder {{ template "content" . }} should appear in the template body)
    end

    payload = %{
      "name" => name,
      "body" => body,
      "type" => template_type_to_string(Map.get(attrs, :type)),
      "is_default" => Map.get(attrs, :is_default, false)
    }

    payload =
      case Map.get(attrs, :subject) do
        nil -> payload
        subject -> Map.put(payload, "subject", subject)
      end

    {:ok, payload}
  rescue
    e in ArgumentError -> {:error, Error.new(e.message)}
  end

  defp template_type_to_string(:campaign), do: "campaign"
  defp template_type_to_string(:tx), do: "tx"
  defp template_type_to_string(nil), do: "campaign"
  defp template_type_to_string(type) when is_binary(type), do: type

  defp validate_required(nil, field), do: raise(ArgumentError, "#{field} is required")
  defp validate_required("", field), do: raise(ArgumentError, "#{field} is required")
  defp validate_required(value, _field), do: value

  defp merge_template_attrs(template, attrs) do
    %{
      template
      | name: Map.get(attrs, :name, template.name),
        subject: Map.get(attrs, :subject, template.subject),
        body: Map.get(attrs, :body, template.body),
        type: Map.get(attrs, :type, template.type)
    }
  end
end
