defmodule Listmonk do
  @moduledoc """
  Elixir client for the Listmonk email platform API.

  This module provides a comprehensive interface to interact with Listmonk's API,
  including subscriber management, campaigns, templates, lists, and transactional emails.

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
    Subscribers,
    Lists,
    Campaigns,
    Templates,
    Transactional
  }

  @doc """
  Checks the health of the Listmonk instance.

  ## Examples

      iex> Listmonk.is_healthy()
      {:ok, true}

      iex> Listmonk.is_healthy(config)
      {:ok, true}
  """
  @spec is_healthy(Config.t() | nil) :: {:ok, boolean()} | {:error, term()}
  defdelegate is_healthy(config \\ nil), to: Listmonk.Client

  @doc """
  Checks the health of the Listmonk instance. Raises on error.
  """
  @spec is_healthy!(Config.t() | nil) :: boolean()
  defdelegate is_healthy!(config \\ nil), to: Listmonk.Client

  # Subscriber functions
  @doc "See `Listmonk.Subscribers.get/2`"
  defdelegate get_subscribers(opts \\ [], config \\ nil), to: Subscribers, as: :get

  @doc "See `Listmonk.Subscribers.get!/2`"
  defdelegate get_subscribers!(opts \\ [], config \\ nil), to: Subscribers, as: :get!

  @doc "See `Listmonk.Subscribers.get_by_email/2`"
  defdelegate get_subscriber_by_email(email, config \\ nil), to: Subscribers, as: :get_by_email

  @doc "See `Listmonk.Subscribers.get_by_email!/2`"
  defdelegate get_subscriber_by_email!(email, config \\ nil), to: Subscribers, as: :get_by_email!

  @doc "See `Listmonk.Subscribers.get_by_id/2`"
  defdelegate get_subscriber_by_id(id, config \\ nil), to: Subscribers, as: :get_by_id

  @doc "See `Listmonk.Subscribers.get_by_id!/2`"
  defdelegate get_subscriber_by_id!(id, config \\ nil), to: Subscribers, as: :get_by_id!

  @doc "See `Listmonk.Subscribers.get_by_uuid/2`"
  defdelegate get_subscriber_by_uuid(uuid, config \\ nil), to: Subscribers, as: :get_by_uuid

  @doc "See `Listmonk.Subscribers.get_by_uuid!/2`"
  defdelegate get_subscriber_by_uuid!(uuid, config \\ nil), to: Subscribers, as: :get_by_uuid!

  @doc "See `Listmonk.Subscribers.create/2`"
  defdelegate create_subscriber(attrs, config \\ nil), to: Subscribers, as: :create

  @doc "See `Listmonk.Subscribers.create!/2`"
  defdelegate create_subscriber!(attrs, config \\ nil), to: Subscribers, as: :create!

  @doc "See `Listmonk.Subscribers.update/3`"
  defdelegate update_subscriber(subscriber, attrs, config \\ nil), to: Subscribers, as: :update

  @doc "See `Listmonk.Subscribers.update!/3`"
  defdelegate update_subscriber!(subscriber, attrs, config \\ nil), to: Subscribers, as: :update!

  @doc "See `Listmonk.Subscribers.delete/2`"
  defdelegate delete_subscriber(identifier, config \\ nil), to: Subscribers, as: :delete

  @doc "See `Listmonk.Subscribers.delete!/2`"
  defdelegate delete_subscriber!(identifier, config \\ nil), to: Subscribers, as: :delete!

  @doc "See `Listmonk.Subscribers.enable/2`"
  defdelegate enable_subscriber(subscriber, config \\ nil), to: Subscribers, as: :enable

  @doc "See `Listmonk.Subscribers.enable!/2`"
  defdelegate enable_subscriber!(subscriber, config \\ nil), to: Subscribers, as: :enable!

  @doc "See `Listmonk.Subscribers.disable/2`"
  defdelegate disable_subscriber(subscriber, config \\ nil), to: Subscribers, as: :disable

  @doc "See `Listmonk.Subscribers.disable!/2`"
  defdelegate disable_subscriber!(subscriber, config \\ nil), to: Subscribers, as: :disable!

  @doc "See `Listmonk.Subscribers.block/2`"
  defdelegate block_subscriber(subscriber, config \\ nil), to: Subscribers, as: :block

  @doc "See `Listmonk.Subscribers.block!/2`"
  defdelegate block_subscriber!(subscriber, config \\ nil), to: Subscribers, as: :block!

  @doc "See `Listmonk.Subscribers.confirm_optin/3`"
  defdelegate confirm_optin(subscriber_uuid, list_uuid, config \\ nil), to: Subscribers

  @doc "See `Listmonk.Subscribers.confirm_optin!/3`"
  defdelegate confirm_optin!(subscriber_uuid, list_uuid, config \\ nil), to: Subscribers

  # List functions
  @doc "See `Listmonk.Lists.get/1`"
  defdelegate get_lists(config \\ nil), to: Lists, as: :get

  @doc "See `Listmonk.Lists.get!/1`"
  defdelegate get_lists!(config \\ nil), to: Lists, as: :get!

  @doc "See `Listmonk.Lists.get_by_id/2`"
  defdelegate get_list_by_id(id, config \\ nil), to: Lists, as: :get_by_id

  @doc "See `Listmonk.Lists.get_by_id!/2`"
  defdelegate get_list_by_id!(id, config \\ nil), to: Lists, as: :get_by_id!

  @doc "See `Listmonk.Lists.create/2`"
  defdelegate create_list(attrs, config \\ nil), to: Lists, as: :create

  @doc "See `Listmonk.Lists.create!/2`"
  defdelegate create_list!(attrs, config \\ nil), to: Lists, as: :create!

  @doc "See `Listmonk.Lists.delete/2`"
  defdelegate delete_list(id, config \\ nil), to: Lists, as: :delete

  @doc "See `Listmonk.Lists.delete!/2`"
  defdelegate delete_list!(id, config \\ nil), to: Lists, as: :delete!

  # Campaign functions
  @doc "See `Listmonk.Campaigns.get/1`"
  defdelegate get_campaigns(config \\ nil), to: Campaigns, as: :get

  @doc "See `Listmonk.Campaigns.get!/1`"
  defdelegate get_campaigns!(config \\ nil), to: Campaigns, as: :get!

  @doc "See `Listmonk.Campaigns.get_by_id/2`"
  defdelegate get_campaign_by_id(id, config \\ nil), to: Campaigns, as: :get_by_id

  @doc "See `Listmonk.Campaigns.get_by_id!/2`"
  defdelegate get_campaign_by_id!(id, config \\ nil), to: Campaigns, as: :get_by_id!

  @doc "See `Listmonk.Campaigns.preview/2`"
  defdelegate preview_campaign(id, config \\ nil), to: Campaigns, as: :preview

  @doc "See `Listmonk.Campaigns.preview!/2`"
  defdelegate preview_campaign!(id, config \\ nil), to: Campaigns, as: :preview!

  @doc "See `Listmonk.Campaigns.create/2`"
  defdelegate create_campaign(attrs, config \\ nil), to: Campaigns, as: :create

  @doc "See `Listmonk.Campaigns.create!/2`"
  defdelegate create_campaign!(attrs, config \\ nil), to: Campaigns, as: :create!

  @doc "See `Listmonk.Campaigns.update/3`"
  defdelegate update_campaign(campaign, attrs, config \\ nil), to: Campaigns, as: :update

  @doc "See `Listmonk.Campaigns.update!/3`"
  defdelegate update_campaign!(campaign, attrs, config \\ nil), to: Campaigns, as: :update!

  @doc "See `Listmonk.Campaigns.delete/2`"
  defdelegate delete_campaign(id, config \\ nil), to: Campaigns, as: :delete

  @doc "See `Listmonk.Campaigns.delete!/2`"
  defdelegate delete_campaign!(id, config \\ nil), to: Campaigns, as: :delete!

  # Template functions
  @doc "See `Listmonk.Templates.get/1`"
  defdelegate get_templates(config \\ nil), to: Templates, as: :get

  @doc "See `Listmonk.Templates.get!/1`"
  defdelegate get_templates!(config \\ nil), to: Templates, as: :get!

  @doc "See `Listmonk.Templates.get_by_id/2`"
  defdelegate get_template_by_id(id, config \\ nil), to: Templates, as: :get_by_id

  @doc "See `Listmonk.Templates.get_by_id!/2`"
  defdelegate get_template_by_id!(id, config \\ nil), to: Templates, as: :get_by_id!

  @doc "See `Listmonk.Templates.preview/2`"
  defdelegate preview_template(id, config \\ nil), to: Templates, as: :preview

  @doc "See `Listmonk.Templates.preview!/2`"
  defdelegate preview_template!(id, config \\ nil), to: Templates, as: :preview!

  @doc "See `Listmonk.Templates.create/2`"
  defdelegate create_template(attrs, config \\ nil), to: Templates, as: :create

  @doc "See `Listmonk.Templates.create!/2`"
  defdelegate create_template!(attrs, config \\ nil), to: Templates, as: :create!

  @doc "See `Listmonk.Templates.update/3`"
  defdelegate update_template(template, attrs, config \\ nil), to: Templates, as: :update

  @doc "See `Listmonk.Templates.update!/3`"
  defdelegate update_template!(template, attrs, config \\ nil), to: Templates, as: :update!

  @doc "See `Listmonk.Templates.delete/2`"
  defdelegate delete_template(id, config \\ nil), to: Templates, as: :delete

  @doc "See `Listmonk.Templates.delete!/2`"
  defdelegate delete_template!(id, config \\ nil), to: Templates, as: :delete!

  @doc "See `Listmonk.Templates.set_default/2`"
  defdelegate set_default_template(id, config \\ nil), to: Templates, as: :set_default

  @doc "See `Listmonk.Templates.set_default!/2`"
  defdelegate set_default_template!(id, config \\ nil), to: Templates, as: :set_default!

  # Transactional email functions
  @doc "See `Listmonk.Transactional.send_email/2`"
  defdelegate send_transactional_email(attrs, config \\ nil), to: Transactional, as: :send_email

  @doc "See `Listmonk.Transactional.send_email!/2`"
  defdelegate send_transactional_email!(attrs, config \\ nil), to: Transactional, as: :send_email!
end
