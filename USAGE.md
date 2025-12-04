# Usage

Comprehensive guide to using the Listmonk Elixir client library.

## Table of Contents

- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Health Checks](#health-checks)
- [Subscribers](#subscribers)
- [Mailing Lists](#mailing-lists)
- [Campaigns](#campaigns)
- [Templates](#templates)
- [Transactional Emails](#transactional-emails)
- [Error Handling](#error-handling)

## Getting Started

The Listmonk client uses a process-based architecture. You start a client process and then use it for all API calls:

```elixir
# Create a client with a named alias
config = %Listmonk.Config{
  url: "https://listmonk.example.com",
  username: "admin",
  password: "your_password_or_api_key"
}

{:ok, _pid} = Listmonk.new(config, :my_listmonk)

# Now use the alias for all operations
{:ok, lists} = Listmonk.get_lists(:my_listmonk)
{:ok, subscribers} = Listmonk.get_subscribers(:my_listmonk)
```

Or use without a name (pid-based):

```elixir
{:ok, pid} = Listmonk.new(config)
{:ok, lists} = Listmonk.get_lists(pid)
```

## Configuration

### Using a Config Struct

```elixir
config = %Listmonk.Config{
  url: "https://listmonk.example.com",
  username: "admin",
  password: "your_password_or_api_key"
}

{:ok, _pid} = Listmonk.new(config, :listmonk)
```

### Using a Keyword List

```elixir
config = [
  url: "https://listmonk.example.com",
  username: "admin",
  password: "your_password_or_api_key"
]

{:ok, _pid} = Listmonk.new(config, :listmonk)
```

### Environment Variables

For local development, copy the example file:

```bash
cp .env.example .env
# Edit .env with your Listmonk instance details
```

Or export variables directly:

```bash
export LISTMONK_URL=https://listmonk.example.com
export LISTMONK_USERNAME=admin
export LISTMONK_PASSWORD=your_password_or_api_key
```

Then resolve config from environment:

```elixir
config = Listmonk.Config.from_env()
{:ok, _pid} = Listmonk.new(config, :listmonk)
```

### Managing Client Configuration

```elixir
# Get current config
config = Listmonk.get_config(:listmonk)

# Update config at runtime
new_config = %Listmonk.Config{
  url: "https://new-instance.example.com",
  username: "admin",
  password: "new_password"
}
:ok = Listmonk.set_config(:listmonk, new_config)

# Stop client when done
:ok = Listmonk.stop(:listmonk)
```

## Health Checks

Check if your Listmonk instance is healthy and accessible:

```elixir
# Safe variant
{:ok, true} = Listmonk.healthy?(:listmonk)

# Bang variant (raises on error)
true = Listmonk.healthy!(:listmonk)
```

## Subscribers

### Get Subscribers

```elixir
# Get all subscribers
{:ok, subscribers} = Listmonk.get_subscribers(:listmonk)

# Get subscribers from a specific list
{:ok, subscribers} = Listmonk.get_subscribers(:listmonk, list_id: 1)

# Query subscribers with SQL
{:ok, subscribers} = Listmonk.get_subscribers(:listmonk,
  query: "subscribers.attribs->>'city' = 'Portland'"
)

# Pagination
{:ok, subscribers} = Listmonk.get_subscribers(:listmonk,
  page: 1,
  per_page: 50
)
```

### Get Subscriber by Identifier

```elixir
# By email
{:ok, subscriber} = Listmonk.get_subscriber_by_email(:listmonk, "user@example.com")

# By ID
{:ok, subscriber} = Listmonk.get_subscriber_by_id(:listmonk, 123)

# By UUID
{:ok, subscriber} = Listmonk.get_subscriber_by_uuid(:listmonk, "c37786af-e6ab-4260...")
```

### Create Subscriber

```elixir
{:ok, subscriber} = Listmonk.create_subscriber(:listmonk, %{
  email: "user@example.com",
  name: "Jane Doe",
  lists: [1, 2],  # List IDs to subscribe to
  status: :enabled,  # :enabled, :disabled, or :blocklisted
  preconfirm: true,  # Skip double opt-in confirmation
  attribs: %{
    "city" => "Portland",
    "plan" => "premium",
    "score" => 95
  }
})
```

### Update Subscriber

```elixir
subscriber = Listmonk.get_subscriber_by_email!(:listmonk, "user@example.com")

{:ok, updated} = Listmonk.update_subscriber(:listmonk, subscriber, %{
  name: "Jane Smith",
  attribs: %{"plan" => "enterprise"},
  add_lists: [3, 4],
  remove_lists: [1]
})
```

### Subscriber Status Management

```elixir
subscriber = Listmonk.get_subscriber_by_id!(:listmonk, 123)

# Enable subscriber
{:ok, enabled} = Listmonk.enable_subscriber(:listmonk, subscriber)

# Disable subscriber
{:ok, disabled} = Listmonk.disable_subscriber(:listmonk, subscriber)

# Block (unsubscribe) subscriber
{:ok, blocked} = Listmonk.block_subscriber(:listmonk, subscriber)
```

### Delete Subscriber

```elixir
# By email
{:ok, true} = Listmonk.delete_subscriber(:listmonk, "user@example.com")

# By ID
{:ok, true} = Listmonk.delete_subscriber(:listmonk, 123)
```

### Confirm Opt-in

For managing double opt-in confirmations:

```elixir
{:ok, confirmed} = Listmonk.confirm_optin(:listmonk,
  subscriber_uuid,
  list_uuid
)
```

## Mailing Lists

### Get Lists

```elixir
# Get all lists
{:ok, lists} = Listmonk.get_lists(:listmonk)

# Get specific list by ID
{:ok, list} = Listmonk.get_list_by_id(:listmonk, 7)
```

### Create List

```elixir
{:ok, list} = Listmonk.create_list(:listmonk, %{
  name: "Newsletter",
  type: :public,  # :public or :private
  optin: :single,  # :single or :double
  tags: ["newsletter", "monthly"],
  description: "Monthly newsletter for all users"
})
```

### Delete List

```elixir
{:ok, true} = Listmonk.delete_list(:listmonk, 7)
```

## Campaigns

### Get Campaigns

```elixir
# Get all campaigns
{:ok, campaigns} = Listmonk.get_campaigns(:listmonk)

# Get specific campaign
{:ok, campaign} = Listmonk.get_campaign_by_id(:listmonk, 15)

# Preview campaign
{:ok, html} = Listmonk.preview_campaign(:listmonk, 15)
```

### Create Campaign

```elixir
{:ok, campaign} = Listmonk.create_campaign(:listmonk, %{
  name: "Monthly Newsletter - January",
  subject: "Great updates this month!",
  lists: [1, 2],
  from_email: "newsletter@example.com",
  type: :regular,  # :regular or :optin
  content_type: :html,  # :richtext, :html, :markdown, :plain
  body: "<h1>Hello!</h1><p>Check out our updates...</p>",
  altbody: "Hello! Check out our updates...",
  template_id: 1,
  tags: ["newsletter", "2025"],
  send_at: ~U[2025-01-15 10:00:00Z]  # Optional scheduled send time
})
```

### Update Campaign

```elixir
campaign = Listmonk.get_campaign_by_id!(:listmonk, 15)

{:ok, updated} = Listmonk.update_campaign(:listmonk, campaign, %{
  name: "Updated Campaign Name",
  subject: "Even better subject!",
  body: "<h1>Updated content</h1>"
})
```

### Delete Campaign

```elixir
{:ok, true} = Listmonk.delete_campaign(:listmonk, 15)
```

## Templates

### Get Templates

```elixir
# Get all templates
{:ok, templates} = Listmonk.get_templates(:listmonk)

# Get specific template
{:ok, template} = Listmonk.get_template_by_id(:listmonk, 2)

# Preview template
{:ok, html} = Listmonk.preview_template(:listmonk, 2)
```

### Create Template

```elixir
# Campaign template
{:ok, template} = Listmonk.create_template(:listmonk, %{
  name: "My Campaign Template",
  type: :campaign,
  body: """
  <!DOCTYPE html>
  <html>
    <head><title>{{ .Campaign.Name }}</title></head>
    <body>
      <h1>{{ .Campaign.Subject }}</h1>
      {{ template "content" . }}
      <footer>Unsubscribe: {{ .UnsubscribeURL }}</footer>
    </body>
  </html>
  """
})

# Transactional template
{:ok, tx_template} = Listmonk.create_template(:listmonk, %{
  name: "Password Reset",
  type: :tx,
  subject: "Reset your password",
  body: """
  <!DOCTYPE html>
  <html>
    <body>
      <h1>Hi {{ .Subscriber.Name }}!</h1>
      {{ template "content" . }}
      <p>Reset code: {{ .Tx.Data.reset_code }}</p>
    </body>
  </html>
  """
})
```

### Update Template

```elixir
template = Listmonk.get_template_by_id!(:listmonk, 2)

{:ok, updated} = Listmonk.update_template(:listmonk, template, %{
  name: "Updated Template Name",
  body: "<html>...</html>"
})
```

### Set Default Template

```elixir
{:ok, true} = Listmonk.set_default_template(:listmonk, 2)
```

### Delete Template

```elixir
{:ok, true} = Listmonk.delete_template(:listmonk, 3)
```

## Transactional Emails

Send individual transactional emails using TX templates:

### Basic Transactional Email

```elixir
{:ok, sent} = Listmonk.send_transactional_email(:listmonk, %{
  subscriber_email: "user@example.com",
  template_id: 3,
  from_email: "app@example.com",  # Optional
  data: %{
    full_name: "Jane Doe",
    reset_code: "abc123",
    expiry_time: "24 hours"
  }
})
```

### With Custom Headers

```elixir
{:ok, sent} = Listmonk.send_transactional_email(:listmonk, %{
  subscriber_email: "user@example.com",
  template_id: 3,
  headers: [
    %{"X-Custom-Header" => "value"},
    %{"Reply-To" => "support@example.com"}
  ],
  data: %{...}
})
```

### With File Attachments

```elixir
{:ok, sent} = Listmonk.send_transactional_email(:listmonk, %{
  subscriber_email: "user@example.com",
  template_id: 3,
  attachments: [
    "/path/to/invoice.pdf",
    "/path/to/receipt.pdf"
  ],
  data: %{
    invoice_number: "INV-2025-001"
  }
})
```

### Different Content Types

```elixir
# HTML (default)
{:ok, sent} = Listmonk.send_transactional_email(:listmonk, %{
  subscriber_email: "user@example.com",
  template_id: 3,
  content_type: :html,
  data: %{...}
})

# Markdown
{:ok, sent} = Listmonk.send_transactional_email(:listmonk, %{
  subscriber_email: "user@example.com",
  template_id: 3,
  content_type: :markdown,
  data: %{...}
})

# Plain text
{:ok, sent} = Listmonk.send_transactional_email(:listmonk, %{
  subscriber_email: "user@example.com",
  template_id: 3,
  content_type: :plain,
  data: %{...}
})
```

## Error Handling

All functions return `{:ok, result}` or `{:error, %Listmonk.Error{}}` tuples:

```elixir
case Listmonk.get_subscriber_by_email(:listmonk, "user@example.com") do
  {:ok, subscriber} ->
    IO.puts("Found subscriber: #{subscriber.name}")

  {:ok, nil} ->
    IO.puts("Subscriber not found")

  {:error, %Listmonk.Error{message: message}} ->
    IO.puts("Error: #{message}")
end
```

### Using Bang Variants

Bang variants raise exceptions on error:

```elixir
try do
  subscriber = Listmonk.get_subscriber_by_email!(:listmonk, "user@example.com")
  IO.puts("Found: #{subscriber.name}")
rescue
  e in Listmonk.Error ->
    IO.puts("Error: #{e.message}")
    IO.puts("Status: #{e.status_code}")
end
```

### Error Attributes

```elixir
%Listmonk.Error{
  message: "HTTP 404: Not found",
  status_code: 404,
  response_body: %{"error" => "subscriber not found"}
}
```

## Advanced Usage

### Multiple Listmonk Instances

You can connect to multiple Listmonk instances simultaneously:

```elixir
# Production instance
{:ok, _} = Listmonk.new(prod_config, :prod_listmonk)

# Staging instance
{:ok, _} = Listmonk.new(staging_config, :staging_listmonk)

# Use different instances
{:ok, prod_lists} = Listmonk.get_lists(:prod_listmonk)
{:ok, staging_lists} = Listmonk.get_lists(:staging_listmonk)
```

### Working with Subscriber Attributes

```elixir
# Create with custom attributes
{:ok, subscriber} = Listmonk.create_subscriber(:listmonk, %{
  email: "user@example.com",
  name: "Jane Doe",
  lists: [1],
  attribs: %{
    "signup_date" => "2025-01-01",
    "plan" => "premium",
    "credits" => 100
  }
})

# Query by attributes
{:ok, premium_users} = Listmonk.get_subscribers(:listmonk,
  query: "subscribers.attribs->>'plan' = 'premium'"
)

# Update attributes
subscriber = Listmonk.get_subscriber_by_email!(:listmonk, "user@example.com")

{:ok, updated} = Listmonk.update_subscriber(:listmonk, subscriber, %{
  attribs: Map.merge(subscriber.attribs, %{
    "credits" => 150,
    "last_purchase" => "2025-01-15"
  })
})
```

### Batch Operations

```elixir
# Process multiple subscribers
emails = ["user1@example.com", "user2@example.com", "user3@example.com"]

results = Enum.map(emails, fn email ->
  Listmonk.create_subscriber(:listmonk, %{
    email: email,
    name: email,
    lists: [1]
  })
end)

successes = Enum.filter(results, &match?({:ok, _}, &1))
failures = Enum.filter(results, &match?({:error, _}, &1))

IO.puts("Created: #{length(successes)}, Failed: #{length(failures)}")
```

### Using with Supervision Trees

```elixir
# In your application.ex
def start(_type, _args) do
  children = [
    # ... other children
    {Listmonk.Server, config: listmonk_config(), name: :listmonk}
  ]

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
end

defp listmonk_config do
  %Listmonk.Config{
    url: System.get_env("LISTMONK_URL"),
    username: System.get_env("LISTMONK_USERNAME"),
    password: System.get_env("LISTMONK_PASSWORD")
  }
end
```

## Best Practices

1. **Use Named Clients**: Use atoms like `:listmonk` for easier reference throughout your app
2. **Handle Errors**: Always handle both success and error cases
3. **Validate Email Addresses**: Validate emails before creating subscribers
4. **Use Supervision**: Add the client to your supervision tree for automatic restarts
5. **Rate Limiting**: Implement rate limiting for bulk operations
6. **Monitor Health**: Regularly check instance health with `Listmonk.healthy?/1`
7. **Preconfirm Carefully**: Only use `preconfirm: true` when you've verified opt-in yourself

## More Information

- [Listmonk API Documentation](https://listmonk.app/docs/apis/apis/)
- [Listmonk Querying Guide](https://listmonk.app/docs/querying-and-segmentation/)
- [GitHub Repository](https://github.com/mifkata/listmonk-elixir-client)
