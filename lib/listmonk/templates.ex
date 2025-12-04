defmodule Listmonk.Templates do
  @moduledoc """
  Functions for managing Listmonk templates.
  """

  alias Listmonk.{Server, Error}
  alias Listmonk.Models.Template

  @type server :: pid() | atom()

  @doc """
  Retrieves all templates.
  """
  @spec get(server()) :: {:ok, list(Template.t())} | {:error, Error.t()}
  def get(server) do
    path = "/api/templates?page=1&per_page=1000000"

    case Server.request(server, :get, path) do
      {:ok, %{"data" => results}} when is_list(results) ->
        templates = Enum.map(results, &Template.from_api/1)
        {:ok, templates}

      error ->
        error
    end
  end

  @doc """
  Retrieves a template by ID.
  """
  @spec get_by_id(server(), integer()) :: {:ok, Template.t() | nil} | {:error, Error.t()}
  def get_by_id(server, id) do
    path = "/api/templates/#{id}"

    case Server.request(server, :get, path) do
      {:ok, %{"data" => data}} when is_map(data) and map_size(data) > 0 ->
        {:ok, Template.from_api(data)}

      {:ok, %{"data" => _}} ->
        {:ok, nil}

      error ->
        error
    end
  end

  @doc """
  Retrieves a template preview by ID.
  """
  @spec preview(server(), integer()) :: {:ok, String.t()} | {:error, Error.t()}
  def preview(server, id) do
    path = "/api/templates/#{id}/preview"

    case Server.request(server, :get, path) do
      {:ok, %{"data" => preview}} when is_binary(preview) -> {:ok, preview}
      {:ok, response} -> {:ok, to_string(response)}
      error -> error
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
  """
  @spec create(server(), map()) :: {:ok, Template.t()} | {:error, Error.t()}
  def create(server, attrs) do
    with {:ok, payload} <- build_create_payload(attrs) do
      case Server.request(server, :post, "/api/templates", json: payload) do
        {:ok, %{"data" => data}} -> {:ok, Template.from_api(data)}
        error -> error
      end
    end
  end

  @doc """
  Updates a template.
  """
  @spec update(server(), Template.t(), map()) :: {:ok, Template.t()} | {:error, Error.t()}
  def update(server, %Template{id: id} = template, attrs) do
    updated_template = merge_template_attrs(template, attrs)
    payload = Template.to_api(updated_template)

    case Server.request(server, :put, "/api/templates/#{id}", json: payload) do
      {:ok, _response} -> get_by_id(server, id)
      error -> error
    end
  end

  @doc """
  Deletes a template by ID.
  """
  @spec delete(server(), integer()) :: {:ok, boolean()} | {:error, Error.t()}
  def delete(server, id) do
    case get_by_id(server, id) do
      {:ok, nil} ->
        {:ok, false}

      {:ok, _template} ->
        case Server.request(server, :delete, "/api/templates/#{id}") do
          {:ok, %{"data" => result}} -> {:ok, result == true}
          error -> error
        end

      error ->
        error
    end
  end

  @doc """
  Sets a template as the default template.
  """
  @spec set_default(server(), integer()) :: {:ok, boolean()} | {:error, Error.t()}
  def set_default(server, id) do
    case get_by_id(server, id) do
      {:ok, nil} ->
        {:ok, false}

      {:ok, _template} ->
        case Server.request(server, :put, "/api/templates/#{id}/default") do
          {:ok, %{"data" => result}} -> {:ok, result == true}
          error -> error
        end

      error ->
        error
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
