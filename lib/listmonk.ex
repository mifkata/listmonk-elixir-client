defmodule Listmonk do
  @moduledoc """
  Elixir client for the Listmonk email platform API.

  This module provides a comprehensive interface to interact with Listmonk's API,
  including subscriber management, campaigns, templates, lists, and transactional emails.

  Based on the Python Listmonk client by Michael Kennedy (https://github.com/mikeckennedy/listmonk),
  adapted to idiomatic Elixir patterns and conventions.

  ## Configuration

  You can configure the client either via environment variables or at runtime:

  ### Environment Variables

      LISTMONK_URL=https://listmonk.example.com
      LISTMONK_USERNAME=your_username
      LISTMONK_PASSWORD=your_password_or_api_key

  ### Runtime Configuration

      config = %Listmonk.Config{
        url: "https://listmonk.example.com",
        username: "your_username",
        password: "your_password_or_api_key"
      }

  Runtime configuration takes precedence over environment variables.

  ## Usage

  See `USAGE.md` for detailed examples.
  """

  alias Listmonk.{
    Config,
    Error,
    Subscribers,
    Lists,
    Campaigns,
    Templates,
    Transactional
  }

  alias Listmonk.Models.{
    Subscriber,
    MailingList,
    Campaign,
    Template
  }

  @doc """
  Checks the health of the Listmonk instance.

  Returns `{:ok, true}` if the instance is healthy, or an error tuple otherwise.
  """
  @spec healthy?(Config.t() | nil) :: {:ok, boolean()} | {:error, term()}
  defdelegate healthy?(config \\ nil), to: Listmonk.Client

  @doc """
  Checks the health of the Listmonk instance. Raises on error.
  """
  @spec healthy!(Config.t() | nil) :: boolean()
  defdelegate healthy!(config \\ nil), to: Listmonk.Client

  # Subscriber functions
  @doc "See `Listmonk.Subscribers.get/2`"
  @spec get_subscribers(keyword(), Config.t() | nil) ::
          {:ok, list(Subscriber.t())} | {:error, Error.t()}
  defdelegate get_subscribers(opts \\ [], config \\ nil), to: Subscribers, as: :get

  @doc "See `Listmonk.Subscribers.get!/2`"
  @spec get_subscribers!(keyword(), Config.t() | nil) :: list(Subscriber.t())
  defdelegate get_subscribers!(opts \\ [], config \\ nil), to: Subscribers, as: :get!

  @doc "See `Listmonk.Subscribers.get_by_email/2`"
  @spec get_subscriber_by_email(String.t(), Config.t() | nil) ::
          {:ok, Subscriber.t() | nil} | {:error, Error.t()}
  defdelegate get_subscriber_by_email(email, config \\ nil), to: Subscribers, as: :get_by_email

  @doc "See `Listmonk.Subscribers.get_by_email!/2`"
  @spec get_subscriber_by_email!(String.t(), Config.t() | nil) :: Subscriber.t() | nil
  defdelegate get_subscriber_by_email!(email, config \\ nil), to: Subscribers, as: :get_by_email!

  @doc "See `Listmonk.Subscribers.get_by_id/2`"
  @spec get_subscriber_by_id(integer(), Config.t() | nil) ::
          {:ok, Subscriber.t() | nil} | {:error, Error.t()}
  defdelegate get_subscriber_by_id(id, config \\ nil), to: Subscribers, as: :get_by_id

  @doc "See `Listmonk.Subscribers.get_by_id!/2`"
  @spec get_subscriber_by_id!(integer(), Config.t() | nil) :: Subscriber.t() | nil
  defdelegate get_subscriber_by_id!(id, config \\ nil), to: Subscribers, as: :get_by_id!

  @doc "See `Listmonk.Subscribers.get_by_uuid/2`"
  @spec get_subscriber_by_uuid(String.t(), Config.t() | nil) ::
          {:ok, Subscriber.t() | nil} | {:error, Error.t()}
  defdelegate get_subscriber_by_uuid(uuid, config \\ nil), to: Subscribers, as: :get_by_uuid

  @doc "See `Listmonk.Subscribers.get_by_uuid!/2`"
  @spec get_subscriber_by_uuid!(String.t(), Config.t() | nil) :: Subscriber.t() | nil
  defdelegate get_subscriber_by_uuid!(uuid, config \\ nil), to: Subscribers, as: :get_by_uuid!

  @doc "See `Listmonk.Subscribers.create/2`"
  @spec create_subscriber(map(), Config.t() | nil) :: {:ok, Subscriber.t()} | {:error, Error.t()}
  defdelegate create_subscriber(attrs, config \\ nil), to: Subscribers, as: :create

  @doc "See `Listmonk.Subscribers.create!/2`"
  @spec create_subscriber!(map(), Config.t() | nil) :: Subscriber.t()
  defdelegate create_subscriber!(attrs, config \\ nil), to: Subscribers, as: :create!

  @doc "See `Listmonk.Subscribers.update/3`"
  @spec update_subscriber(Subscriber.t(), map(), Config.t() | nil) ::
          {:ok, Subscriber.t()} | {:error, Error.t()}
  defdelegate update_subscriber(subscriber, attrs, config \\ nil), to: Subscribers, as: :update

  @doc "See `Listmonk.Subscribers.update!/3`"
  @spec update_subscriber!(Subscriber.t(), map(), Config.t() | nil) :: Subscriber.t()
  defdelegate update_subscriber!(subscriber, attrs, config \\ nil), to: Subscribers, as: :update!

  @doc "See `Listmonk.Subscribers.delete/2`"
  @spec delete_subscriber(String.t() | integer(), Config.t() | nil) ::
          {:ok, boolean()} | {:error, Error.t()}
  defdelegate delete_subscriber(identifier, config \\ nil), to: Subscribers, as: :delete

  @doc "See `Listmonk.Subscribers.delete!/2`"
  @spec delete_subscriber!(String.t() | integer(), Config.t() | nil) :: boolean()
  defdelegate delete_subscriber!(identifier, config \\ nil), to: Subscribers, as: :delete!

  @doc "See `Listmonk.Subscribers.enable/2`"
  @spec enable_subscriber(Subscriber.t(), Config.t() | nil) ::
          {:ok, Subscriber.t()} | {:error, Error.t()}
  defdelegate enable_subscriber(subscriber, config \\ nil), to: Subscribers, as: :enable

  @doc "See `Listmonk.Subscribers.enable!/2`"
  @spec enable_subscriber!(Subscriber.t(), Config.t() | nil) :: Subscriber.t()
  defdelegate enable_subscriber!(subscriber, config \\ nil), to: Subscribers, as: :enable!

  @doc "See `Listmonk.Subscribers.disable/2`"
  @spec disable_subscriber(Subscriber.t(), Config.t() | nil) ::
          {:ok, Subscriber.t()} | {:error, Error.t()}
  defdelegate disable_subscriber(subscriber, config \\ nil), to: Subscribers, as: :disable

  @doc "See `Listmonk.Subscribers.disable!/2`"
  @spec disable_subscriber!(Subscriber.t(), Config.t() | nil) :: Subscriber.t()
  defdelegate disable_subscriber!(subscriber, config \\ nil), to: Subscribers, as: :disable!

  @doc "See `Listmonk.Subscribers.block/2`"
  @spec block_subscriber(Subscriber.t(), Config.t() | nil) ::
          {:ok, Subscriber.t()} | {:error, Error.t()}
  defdelegate block_subscriber(subscriber, config \\ nil), to: Subscribers, as: :block

  @doc "See `Listmonk.Subscribers.block!/2`"
  @spec block_subscriber!(Subscriber.t(), Config.t() | nil) :: Subscriber.t()
  defdelegate block_subscriber!(subscriber, config \\ nil), to: Subscribers, as: :block!

  @doc "See `Listmonk.Subscribers.confirm_optin/3`"
  @spec confirm_optin(String.t(), String.t(), Config.t() | nil) ::
          {:ok, boolean()} | {:error, Error.t()}
  defdelegate confirm_optin(subscriber_uuid, list_uuid, config \\ nil), to: Subscribers

  @doc "See `Listmonk.Subscribers.confirm_optin!/3`"
  @spec confirm_optin!(String.t(), String.t(), Config.t() | nil) :: boolean()
  defdelegate confirm_optin!(subscriber_uuid, list_uuid, config \\ nil), to: Subscribers

  # List functions
  @doc "See `Listmonk.Lists.get/1`"
  @spec get_lists(Config.t() | nil) :: {:ok, list(MailingList.t())} | {:error, Error.t()}
  defdelegate get_lists(config \\ nil), to: Lists, as: :get

  @doc "See `Listmonk.Lists.get!/1`"
  @spec get_lists!(Config.t() | nil) :: list(MailingList.t())
  defdelegate get_lists!(config \\ nil), to: Lists, as: :get!

  @doc "See `Listmonk.Lists.get_by_id/2`"
  @spec get_list_by_id(integer(), Config.t() | nil) ::
          {:ok, MailingList.t() | nil} | {:error, Error.t()}
  defdelegate get_list_by_id(id, config \\ nil), to: Lists, as: :get_by_id

  @doc "See `Listmonk.Lists.get_by_id!/2`"
  @spec get_list_by_id!(integer(), Config.t() | nil) :: MailingList.t() | nil
  defdelegate get_list_by_id!(id, config \\ nil), to: Lists, as: :get_by_id!

  @doc "See `Listmonk.Lists.create/2`"
  @spec create_list(map(), Config.t() | nil) :: {:ok, MailingList.t()} | {:error, Error.t()}
  defdelegate create_list(attrs, config \\ nil), to: Lists, as: :create

  @doc "See `Listmonk.Lists.create!/2`"
  @spec create_list!(map(), Config.t() | nil) :: MailingList.t()
  defdelegate create_list!(attrs, config \\ nil), to: Lists, as: :create!

  @doc "See `Listmonk.Lists.delete/2`"
  @spec delete_list(integer(), Config.t() | nil) :: {:ok, boolean()} | {:error, Error.t()}
  defdelegate delete_list(id, config \\ nil), to: Lists, as: :delete

  @doc "See `Listmonk.Lists.delete!/2`"
  @spec delete_list!(integer(), Config.t() | nil) :: boolean()
  defdelegate delete_list!(id, config \\ nil), to: Lists, as: :delete!

  # Campaign functions
  @doc "See `Listmonk.Campaigns.get/1`"
  @spec get_campaigns(Config.t() | nil) :: {:ok, list(Campaign.t())} | {:error, Error.t()}
  defdelegate get_campaigns(config \\ nil), to: Campaigns, as: :get

  @doc "See `Listmonk.Campaigns.get!/1`"
  @spec get_campaigns!(Config.t() | nil) :: list(Campaign.t())
  defdelegate get_campaigns!(config \\ nil), to: Campaigns, as: :get!

  @doc "See `Listmonk.Campaigns.get_by_id/2`"
  @spec get_campaign_by_id(integer(), Config.t() | nil) ::
          {:ok, Campaign.t() | nil} | {:error, Error.t()}
  defdelegate get_campaign_by_id(id, config \\ nil), to: Campaigns, as: :get_by_id

  @doc "See `Listmonk.Campaigns.get_by_id!/2`"
  @spec get_campaign_by_id!(integer(), Config.t() | nil) :: Campaign.t() | nil
  defdelegate get_campaign_by_id!(id, config \\ nil), to: Campaigns, as: :get_by_id!

  @doc "See `Listmonk.Campaigns.preview/2`"
  @spec preview_campaign(integer(), Config.t() | nil) :: {:ok, String.t()} | {:error, Error.t()}
  defdelegate preview_campaign(id, config \\ nil), to: Campaigns, as: :preview

  @doc "See `Listmonk.Campaigns.preview!/2`"
  @spec preview_campaign!(integer(), Config.t() | nil) :: String.t()
  defdelegate preview_campaign!(id, config \\ nil), to: Campaigns, as: :preview!

  @doc "See `Listmonk.Campaigns.create/2`"
  @spec create_campaign(map(), Config.t() | nil) :: {:ok, Campaign.t()} | {:error, Error.t()}
  defdelegate create_campaign(attrs, config \\ nil), to: Campaigns, as: :create

  @doc "See `Listmonk.Campaigns.create!/2`"
  @spec create_campaign!(map(), Config.t() | nil) :: Campaign.t()
  defdelegate create_campaign!(attrs, config \\ nil), to: Campaigns, as: :create!

  @doc "See `Listmonk.Campaigns.update/3`"
  @spec update_campaign(Campaign.t(), map(), Config.t() | nil) ::
          {:ok, Campaign.t()} | {:error, Error.t()}
  defdelegate update_campaign(campaign, attrs, config \\ nil), to: Campaigns, as: :update

  @doc "See `Listmonk.Campaigns.update!/3`"
  @spec update_campaign!(Campaign.t(), map(), Config.t() | nil) :: Campaign.t()
  defdelegate update_campaign!(campaign, attrs, config \\ nil), to: Campaigns, as: :update!

  @doc "See `Listmonk.Campaigns.delete/2`"
  @spec delete_campaign(integer(), Config.t() | nil) :: {:ok, boolean()} | {:error, Error.t()}
  defdelegate delete_campaign(id, config \\ nil), to: Campaigns, as: :delete

  @doc "See `Listmonk.Campaigns.delete!/2`"
  @spec delete_campaign!(integer(), Config.t() | nil) :: boolean()
  defdelegate delete_campaign!(id, config \\ nil), to: Campaigns, as: :delete!

  # Template functions
  @doc "See `Listmonk.Templates.get/1`"
  @spec get_templates(Config.t() | nil) :: {:ok, list(Template.t())} | {:error, Error.t()}
  defdelegate get_templates(config \\ nil), to: Templates, as: :get

  @doc "See `Listmonk.Templates.get!/1`"
  @spec get_templates!(Config.t() | nil) :: list(Template.t())
  defdelegate get_templates!(config \\ nil), to: Templates, as: :get!

  @doc "See `Listmonk.Templates.get_by_id/2`"
  @spec get_template_by_id(integer(), Config.t() | nil) ::
          {:ok, Template.t() | nil} | {:error, Error.t()}
  defdelegate get_template_by_id(id, config \\ nil), to: Templates, as: :get_by_id

  @doc "See `Listmonk.Templates.get_by_id!/2`"
  @spec get_template_by_id!(integer(), Config.t() | nil) :: Template.t() | nil
  defdelegate get_template_by_id!(id, config \\ nil), to: Templates, as: :get_by_id!

  @doc "See `Listmonk.Templates.preview/2`"
  @spec preview_template(integer(), Config.t() | nil) :: {:ok, String.t()} | {:error, Error.t()}
  defdelegate preview_template(id, config \\ nil), to: Templates, as: :preview

  @doc "See `Listmonk.Templates.preview!/2`"
  @spec preview_template!(integer(), Config.t() | nil) :: String.t()
  defdelegate preview_template!(id, config \\ nil), to: Templates, as: :preview!

  @doc "See `Listmonk.Templates.create/2`"
  @spec create_template(map(), Config.t() | nil) :: {:ok, Template.t()} | {:error, Error.t()}
  defdelegate create_template(attrs, config \\ nil), to: Templates, as: :create

  @doc "See `Listmonk.Templates.create!/2`"
  @spec create_template!(map(), Config.t() | nil) :: Template.t()
  defdelegate create_template!(attrs, config \\ nil), to: Templates, as: :create!

  @doc "See `Listmonk.Templates.update/3`"
  @spec update_template(Template.t(), map(), Config.t() | nil) ::
          {:ok, Template.t()} | {:error, Error.t()}
  defdelegate update_template(template, attrs, config \\ nil), to: Templates, as: :update

  @doc "See `Listmonk.Templates.update!/3`"
  @spec update_template!(Template.t(), map(), Config.t() | nil) :: Template.t()
  defdelegate update_template!(template, attrs, config \\ nil), to: Templates, as: :update!

  @doc "See `Listmonk.Templates.delete/2`"
  @spec delete_template(integer(), Config.t() | nil) :: {:ok, boolean()} | {:error, Error.t()}
  defdelegate delete_template(id, config \\ nil), to: Templates, as: :delete

  @doc "See `Listmonk.Templates.delete!/2`"
  @spec delete_template!(integer(), Config.t() | nil) :: boolean()
  defdelegate delete_template!(id, config \\ nil), to: Templates, as: :delete!

  @doc "See `Listmonk.Templates.set_default/2`"
  @spec set_default_template(integer(), Config.t() | nil) ::
          {:ok, boolean()} | {:error, Error.t()}
  defdelegate set_default_template(id, config \\ nil), to: Templates, as: :set_default

  @doc "See `Listmonk.Templates.set_default!/2`"
  @spec set_default_template!(integer(), Config.t() | nil) :: boolean()
  defdelegate set_default_template!(id, config \\ nil), to: Templates, as: :set_default!

  # Transactional email functions
  @doc "See `Listmonk.Transactional.send_email/2`"
  @spec send_transactional_email(map(), Config.t() | nil) ::
          {:ok, boolean()} | {:error, Error.t()}
  defdelegate send_transactional_email(attrs, config \\ nil), to: Transactional, as: :send_email

  @doc "See `Listmonk.Transactional.send_email!/2`"
  @spec send_transactional_email!(map(), Config.t() | nil) :: boolean()
  defdelegate send_transactional_email!(attrs, config \\ nil), to: Transactional, as: :send_email!
end
