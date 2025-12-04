defmodule Listmonk do
  @moduledoc """
  Elixir client for the Listmonk email platform API.

  This module provides a process-based interface to interact with Listmonk's API,
  including subscriber management, campaigns, templates, lists, and transactional emails.

  ## Getting Started

  Start a client process and use it for API calls:

      # Start with an alias (named process)
      {:ok, _pid} = Listmonk.new(config, :my_listmonk)
      {:ok, lists} = Listmonk.get_lists(:my_listmonk)

      # Or start without a name and use the pid
      {:ok, pid} = Listmonk.new(config)
      {:ok, lists} = Listmonk.get_lists(pid)

  ## Configuration

  Create a config struct or use a keyword list:

      # Using a struct
      config = %Listmonk.Config{
        url: "https://listmonk.example.com",
        username: "admin",
        password: "your_password_or_api_key"
      }

      # Using keyword list
      config = [
        url: "https://listmonk.example.com",
        username: "admin",
        password: "your_password_or_api_key"
      ]

  Environment variables are also supported as fallbacks:

      LISTMONK_URL=https://listmonk.example.com
      LISTMONK_USERNAME=your_username
      LISTMONK_PASSWORD=your_password_or_api_key

  ## Usage

  See `USAGE.md` for detailed examples.
  """

  alias Listmonk.{Config, Error, Server}

  alias Listmonk.Models.{
    Subscriber,
    MailingList,
    Campaign,
    Template
  }

  @type server :: pid() | atom()

  # Process Management

  @doc """
  Starts a new Listmonk client process.

  Returns `{:ok, pid}` on success. If a name is provided, the process is registered
  under that name and can be referenced by the atom.

  ## Examples

      # Start with config struct
      config = %Listmonk.Config{url: "https://...", username: "admin", password: "secret"}
      {:ok, pid} = Listmonk.new(config)

      # Start with keyword config
      {:ok, pid} = Listmonk.new(url: "https://...", username: "admin", password: "secret")

      # Start with a name (alias)
      {:ok, pid} = Listmonk.new(config, :my_listmonk)
      # Now use :my_listmonk instead of pid
      {:ok, lists} = Listmonk.get_lists(:my_listmonk)
  """
  @spec new(Config.t() | keyword()) :: {:ok, pid()} | {:error, Error.t()}
  def new(config) do
    Server.start_link(config: config)
  end

  @spec new(Config.t() | keyword(), atom()) :: {:ok, pid()} | {:error, Error.t()}
  def new(config, name) when is_atom(name) do
    Server.start_link(config: config, name: name)
  end

  @doc """
  Gets the current configuration from a client process.

  ## Examples

      config = Listmonk.get_config(:my_listmonk)
      config = Listmonk.get_config(pid)
  """
  @spec get_config(server()) :: Config.t()
  defdelegate get_config(server), to: Server

  @doc """
  Updates the configuration of a client process.

  ## Examples

      new_config = %Listmonk.Config{url: "https://new.example.com", ...}
      :ok = Listmonk.set_config(:my_listmonk, new_config)
  """
  @spec set_config(server(), Config.t()) :: :ok | {:error, Error.t()}
  defdelegate set_config(server, config), to: Server

  @doc """
  Stops a client process.

  ## Examples

      :ok = Listmonk.stop(:my_listmonk)
  """
  @spec stop(server()) :: :ok
  defdelegate stop(server), to: Server

  # Health Check

  @doc """
  Checks the health of the Listmonk instance.

  ## Examples

      {:ok, true} = Listmonk.healthy?(:my_listmonk)
  """
  @spec healthy?(server()) :: {:ok, boolean()} | {:error, Error.t()}
  def healthy?(server) do
    case Server.request(server, :get, "/api/health") do
      {:ok, %{"data" => result}} -> {:ok, result == true}
      {:ok, _} -> {:ok, false}
      error -> error
    end
  end

  @doc """
  Checks the health of the Listmonk instance. Raises on error.
  """
  @spec healthy!(server()) :: boolean()
  def healthy!(server) do
    case healthy?(server) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  # Subscriber functions

  @doc """
  Retrieves subscribers with optional filters.

  ## Options

  - `:query` - SQL query string for filtering
  - `:list_id` - Filter by list ID
  - `:page` - Page number (default: 1)
  - `:per_page` - Results per page (default: 100)

  ## Examples

      {:ok, subscribers} = Listmonk.get_subscribers(:my_listmonk)
      {:ok, subscribers} = Listmonk.get_subscribers(:my_listmonk, query: "subscribers.email LIKE '%@example.com'")
  """
  @spec get_subscribers(server(), keyword()) :: {:ok, list(Subscriber.t())} | {:error, Error.t()}
  def get_subscribers(server, opts \\ []) do
    Listmonk.Subscribers.get(server, opts)
  end

  @doc "Retrieves subscribers. Raises on error."
  @spec get_subscribers!(server(), keyword()) :: list(Subscriber.t())
  def get_subscribers!(server, opts \\ []) do
    case get_subscribers(server, opts) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc "Retrieves a subscriber by email address."
  @spec get_subscriber_by_email(server(), String.t()) ::
          {:ok, Subscriber.t() | nil} | {:error, Error.t()}
  def get_subscriber_by_email(server, email) do
    Listmonk.Subscribers.get_by_email(server, email)
  end

  @doc "Retrieves a subscriber by email. Raises on error."
  @spec get_subscriber_by_email!(server(), String.t()) :: Subscriber.t() | nil
  def get_subscriber_by_email!(server, email) do
    case get_subscriber_by_email(server, email) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc "Retrieves a subscriber by ID."
  @spec get_subscriber_by_id(server(), integer()) ::
          {:ok, Subscriber.t() | nil} | {:error, Error.t()}
  def get_subscriber_by_id(server, id) do
    Listmonk.Subscribers.get_by_id(server, id)
  end

  @doc "Retrieves a subscriber by ID. Raises on error."
  @spec get_subscriber_by_id!(server(), integer()) :: Subscriber.t() | nil
  def get_subscriber_by_id!(server, id) do
    case get_subscriber_by_id(server, id) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc "Retrieves a subscriber by UUID."
  @spec get_subscriber_by_uuid(server(), String.t()) ::
          {:ok, Subscriber.t() | nil} | {:error, Error.t()}
  def get_subscriber_by_uuid(server, uuid) do
    Listmonk.Subscribers.get_by_uuid(server, uuid)
  end

  @doc "Retrieves a subscriber by UUID. Raises on error."
  @spec get_subscriber_by_uuid!(server(), String.t()) :: Subscriber.t() | nil
  def get_subscriber_by_uuid!(server, uuid) do
    case get_subscriber_by_uuid(server, uuid) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc """
  Creates a new subscriber.

  ## Attributes

  - `:email` (required) - Email address
  - `:name` (required) - Full name
  - `:lists` (required) - List of list IDs to subscribe to
  - `:status` - Status (:enabled, :disabled, :blocklisted)
  - `:preconfirm` - Skip confirmation for double opt-in lists
  - `:attribs` - Map of custom attributes
  """
  @spec create_subscriber(server(), map()) :: {:ok, Subscriber.t()} | {:error, Error.t()}
  def create_subscriber(server, attrs) do
    Listmonk.Subscribers.create(server, attrs)
  end

  @doc "Creates a new subscriber. Raises on error."
  @spec create_subscriber!(server(), map()) :: Subscriber.t()
  def create_subscriber!(server, attrs) do
    case create_subscriber(server, attrs) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc "Updates a subscriber."
  @spec update_subscriber(server(), Subscriber.t(), map()) ::
          {:ok, Subscriber.t()} | {:error, Error.t()}
  def update_subscriber(server, subscriber, attrs) do
    Listmonk.Subscribers.update(server, subscriber, attrs)
  end

  @doc "Updates a subscriber. Raises on error."
  @spec update_subscriber!(server(), Subscriber.t(), map()) :: Subscriber.t()
  def update_subscriber!(server, subscriber, attrs) do
    case update_subscriber(server, subscriber, attrs) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc "Deletes a subscriber by email or ID."
  @spec delete_subscriber(server(), String.t() | integer()) ::
          {:ok, boolean()} | {:error, Error.t()}
  def delete_subscriber(server, identifier) do
    Listmonk.Subscribers.delete(server, identifier)
  end

  @doc "Deletes a subscriber. Raises on error."
  @spec delete_subscriber!(server(), String.t() | integer()) :: boolean()
  def delete_subscriber!(server, identifier) do
    case delete_subscriber(server, identifier) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc "Enables a subscriber."
  @spec enable_subscriber(server(), Subscriber.t()) ::
          {:ok, Subscriber.t()} | {:error, Error.t()}
  def enable_subscriber(server, subscriber) do
    Listmonk.Subscribers.enable(server, subscriber)
  end

  @doc "Enables a subscriber. Raises on error."
  @spec enable_subscriber!(server(), Subscriber.t()) :: Subscriber.t()
  def enable_subscriber!(server, subscriber) do
    case enable_subscriber(server, subscriber) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc "Disables a subscriber."
  @spec disable_subscriber(server(), Subscriber.t()) ::
          {:ok, Subscriber.t()} | {:error, Error.t()}
  def disable_subscriber(server, subscriber) do
    Listmonk.Subscribers.disable(server, subscriber)
  end

  @doc "Disables a subscriber. Raises on error."
  @spec disable_subscriber!(server(), Subscriber.t()) :: Subscriber.t()
  def disable_subscriber!(server, subscriber) do
    case disable_subscriber(server, subscriber) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc "Blocks (blocklists) a subscriber."
  @spec block_subscriber(server(), Subscriber.t()) ::
          {:ok, Subscriber.t()} | {:error, Error.t()}
  def block_subscriber(server, subscriber) do
    Listmonk.Subscribers.block(server, subscriber)
  end

  @doc "Blocks a subscriber. Raises on error."
  @spec block_subscriber!(server(), Subscriber.t()) :: Subscriber.t()
  def block_subscriber!(server, subscriber) do
    case block_subscriber(server, subscriber) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc "Confirms opt-in for a subscriber to a list."
  @spec confirm_optin(server(), String.t(), String.t()) ::
          {:ok, boolean()} | {:error, Error.t()}
  def confirm_optin(server, subscriber_uuid, list_uuid) do
    Listmonk.Subscribers.confirm_optin(server, subscriber_uuid, list_uuid)
  end

  @doc "Confirms opt-in. Raises on error."
  @spec confirm_optin!(server(), String.t(), String.t()) :: boolean()
  def confirm_optin!(server, subscriber_uuid, list_uuid) do
    case confirm_optin(server, subscriber_uuid, list_uuid) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  # List functions

  @doc "Retrieves all mailing lists."
  @spec get_lists(server()) :: {:ok, list(MailingList.t())} | {:error, Error.t()}
  def get_lists(server) do
    Listmonk.Lists.get(server)
  end

  @doc "Retrieves all mailing lists. Raises on error."
  @spec get_lists!(server()) :: list(MailingList.t())
  def get_lists!(server) do
    case get_lists(server) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc "Retrieves a mailing list by ID."
  @spec get_list_by_id(server(), integer()) ::
          {:ok, MailingList.t() | nil} | {:error, Error.t()}
  def get_list_by_id(server, id) do
    Listmonk.Lists.get_by_id(server, id)
  end

  @doc "Retrieves a mailing list by ID. Raises on error."
  @spec get_list_by_id!(server(), integer()) :: MailingList.t() | nil
  def get_list_by_id!(server, id) do
    case get_list_by_id(server, id) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc """
  Creates a new mailing list.

  ## Attributes

  - `:name` (required) - Name of the list
  - `:type` - List type (:public or :private)
  - `:optin` - Opt-in type (:single or :double)
  - `:tags` - List of tags
  - `:description` - Description of the list
  """
  @spec create_list(server(), map()) :: {:ok, MailingList.t()} | {:error, Error.t()}
  def create_list(server, attrs) do
    Listmonk.Lists.create(server, attrs)
  end

  @doc "Creates a new mailing list. Raises on error."
  @spec create_list!(server(), map()) :: MailingList.t()
  def create_list!(server, attrs) do
    case create_list(server, attrs) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc "Deletes a mailing list by ID."
  @spec delete_list(server(), integer()) :: {:ok, boolean()} | {:error, Error.t()}
  def delete_list(server, id) do
    Listmonk.Lists.delete(server, id)
  end

  @doc "Deletes a mailing list. Raises on error."
  @spec delete_list!(server(), integer()) :: boolean()
  def delete_list!(server, id) do
    case delete_list(server, id) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  # Campaign functions

  @doc "Retrieves all campaigns."
  @spec get_campaigns(server()) :: {:ok, list(Campaign.t())} | {:error, Error.t()}
  def get_campaigns(server) do
    Listmonk.Campaigns.get(server)
  end

  @doc "Retrieves all campaigns. Raises on error."
  @spec get_campaigns!(server()) :: list(Campaign.t())
  def get_campaigns!(server) do
    case get_campaigns(server) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc "Retrieves a campaign by ID."
  @spec get_campaign_by_id(server(), integer()) ::
          {:ok, Campaign.t() | nil} | {:error, Error.t()}
  def get_campaign_by_id(server, id) do
    Listmonk.Campaigns.get_by_id(server, id)
  end

  @doc "Retrieves a campaign by ID. Raises on error."
  @spec get_campaign_by_id!(server(), integer()) :: Campaign.t() | nil
  def get_campaign_by_id!(server, id) do
    case get_campaign_by_id(server, id) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc "Retrieves a campaign preview by ID."
  @spec preview_campaign(server(), integer()) :: {:ok, String.t()} | {:error, Error.t()}
  def preview_campaign(server, id) do
    Listmonk.Campaigns.preview(server, id)
  end

  @doc "Retrieves a campaign preview. Raises on error."
  @spec preview_campaign!(server(), integer()) :: String.t()
  def preview_campaign!(server, id) do
    case preview_campaign(server, id) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc """
  Creates a new campaign.

  ## Attributes

  - `:name` (required) - Campaign name
  - `:subject` (required) - Email subject
  - `:lists` - List IDs to send to
  - `:from_email` - From email address
  - `:type` - Campaign type (:regular or :optin)
  - `:content_type` - Content type (:richtext, :html, :markdown, :plain)
  - `:body` - Email body content
  """
  @spec create_campaign(server(), map()) :: {:ok, Campaign.t()} | {:error, Error.t()}
  def create_campaign(server, attrs) do
    Listmonk.Campaigns.create(server, attrs)
  end

  @doc "Creates a new campaign. Raises on error."
  @spec create_campaign!(server(), map()) :: Campaign.t()
  def create_campaign!(server, attrs) do
    case create_campaign(server, attrs) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc "Updates a campaign."
  @spec update_campaign(server(), Campaign.t(), map()) ::
          {:ok, Campaign.t()} | {:error, Error.t()}
  def update_campaign(server, campaign, attrs) do
    Listmonk.Campaigns.update(server, campaign, attrs)
  end

  @doc "Updates a campaign. Raises on error."
  @spec update_campaign!(server(), Campaign.t(), map()) :: Campaign.t()
  def update_campaign!(server, campaign, attrs) do
    case update_campaign(server, campaign, attrs) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc "Deletes a campaign by ID."
  @spec delete_campaign(server(), integer()) :: {:ok, boolean()} | {:error, Error.t()}
  def delete_campaign(server, id) do
    Listmonk.Campaigns.delete(server, id)
  end

  @doc "Deletes a campaign. Raises on error."
  @spec delete_campaign!(server(), integer()) :: boolean()
  def delete_campaign!(server, id) do
    case delete_campaign(server, id) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  # Template functions

  @doc "Retrieves all templates."
  @spec get_templates(server()) :: {:ok, list(Template.t())} | {:error, Error.t()}
  def get_templates(server) do
    Listmonk.Templates.get(server)
  end

  @doc "Retrieves all templates. Raises on error."
  @spec get_templates!(server()) :: list(Template.t())
  def get_templates!(server) do
    case get_templates(server) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc "Retrieves a template by ID."
  @spec get_template_by_id(server(), integer()) ::
          {:ok, Template.t() | nil} | {:error, Error.t()}
  def get_template_by_id(server, id) do
    Listmonk.Templates.get_by_id(server, id)
  end

  @doc "Retrieves a template by ID. Raises on error."
  @spec get_template_by_id!(server(), integer()) :: Template.t() | nil
  def get_template_by_id!(server, id) do
    case get_template_by_id(server, id) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc "Retrieves a template preview by ID."
  @spec preview_template(server(), integer()) :: {:ok, String.t()} | {:error, Error.t()}
  def preview_template(server, id) do
    Listmonk.Templates.preview(server, id)
  end

  @doc "Retrieves a template preview. Raises on error."
  @spec preview_template!(server(), integer()) :: String.t()
  def preview_template!(server, id) do
    case preview_template(server, id) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc """
  Creates a new template.

  ## Attributes

  - `:name` (required) - Template name
  - `:body` (required) - Template body HTML
  - `:type` - Template type (:campaign or :tx)
  - `:subject` - Default subject (for tx templates)
  - `:is_default` - Set as default template
  """
  @spec create_template(server(), map()) :: {:ok, Template.t()} | {:error, Error.t()}
  def create_template(server, attrs) do
    Listmonk.Templates.create(server, attrs)
  end

  @doc "Creates a new template. Raises on error."
  @spec create_template!(server(), map()) :: Template.t()
  def create_template!(server, attrs) do
    case create_template(server, attrs) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc "Updates a template."
  @spec update_template(server(), Template.t(), map()) ::
          {:ok, Template.t()} | {:error, Error.t()}
  def update_template(server, template, attrs) do
    Listmonk.Templates.update(server, template, attrs)
  end

  @doc "Updates a template. Raises on error."
  @spec update_template!(server(), Template.t(), map()) :: Template.t()
  def update_template!(server, template, attrs) do
    case update_template(server, template, attrs) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc "Deletes a template by ID."
  @spec delete_template(server(), integer()) :: {:ok, boolean()} | {:error, Error.t()}
  def delete_template(server, id) do
    Listmonk.Templates.delete(server, id)
  end

  @doc "Deletes a template. Raises on error."
  @spec delete_template!(server(), integer()) :: boolean()
  def delete_template!(server, id) do
    case delete_template(server, id) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc "Sets a template as the default."
  @spec set_default_template(server(), integer()) :: {:ok, boolean()} | {:error, Error.t()}
  def set_default_template(server, id) do
    Listmonk.Templates.set_default(server, id)
  end

  @doc "Sets a template as the default. Raises on error."
  @spec set_default_template!(server(), integer()) :: boolean()
  def set_default_template!(server, id) do
    case set_default_template(server, id) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  # Transactional email functions

  @doc """
  Sends a transactional email.

  ## Attributes

  - `:subscriber_email` (required) - Recipient email address
  - `:template_id` (required) - TX template ID to use
  - `:from_email` - From email address
  - `:data` - Template data map
  - `:attachments` - List of file paths to attach
  """
  @spec send_transactional_email(server(), map()) :: {:ok, boolean()} | {:error, Error.t()}
  def send_transactional_email(server, attrs) do
    Listmonk.Transactional.send_email(server, attrs)
  end

  @doc "Sends a transactional email. Raises on error."
  @spec send_transactional_email!(server(), map()) :: boolean()
  def send_transactional_email!(server, attrs) do
    case send_transactional_email(server, attrs) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end
end
