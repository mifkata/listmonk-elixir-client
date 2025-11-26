# Listmonk Elixir Client

Elixir client for the [Listmonk](https://listmonk.app) open-source, self-hosted email platform.

Built with [Req](https://github.com/wojtekmach/req) HTTP client and designed for easy integration into Elixir applications.

## Features

- ➕ **Add and manage subscribers** with custom attributes
- 🔍 **Search subscribers** using SQL queries
- 📋 **Manage mailing lists** (create, read, delete)
- 📧 **Send transactional emails** with template support and attachments
- 📨 **Create and manage campaigns** (bulk emails)
- 🎨 **Manage templates** for consistent email design
- 🏥 **Health checks** for instance connectivity
- 🔐 **Flexible authentication** via environment variables or runtime config
- ✨ **Both safe and bang variants** for all operations (`get/1` and `get!/1`)

## Installation

Add `listmonk_client` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:listmonk_client, "~> 0.1.0"}
  ]
end
```

## Quick Start

### Configuration

Set environment variables:

```bash
export LISTMONK_URL=https://listmonk.example.com
export LISTMONK_USERNAME=admin
export LISTMONK_PASSWORD=your_password_or_api_key
```

Or configure at runtime:

```elixir
config = %Listmonk.Config{
  url: "https://listmonk.example.com",
  username: "admin",
  password: "your_password_or_api_key"
}
```

### Basic Usage

```elixir
# Check health
{:ok, healthy} = Listmonk.is_healthy()

# Get all lists
{:ok, lists} = Listmonk.get_lists()

# Create a subscriber
{:ok, subscriber} = Listmonk.create_subscriber(%{
  email: "user@example.com",
  name: "Jane Doe",
  lists: [1],
  attribs: %{"city" => "Portland"}
})

# Send a transactional email
{:ok, sent} = Listmonk.send_transactional_email(%{
  subscriber_email: "user@example.com",
  template_id: 3,
  data: %{
    full_name: "Jane Doe",
    reset_code: "abc123"
  }
})
```

For detailed examples, see [USAGE.md](USAGE.md).

## Documentation

- [Full Usage Guide](USAGE.md)
- [API Documentation](https://hexdocs.pm/listmonk_client) (coming soon)
- [Listmonk API Docs](https://listmonk.app/docs/apis/apis/)

## Development

```bash
# Get dependencies
mix deps.get

# Compile
mix compile

# Run tests
mix test

# Run linter
mix credo
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Author

Andriyan Ivanov <andriyan.ivanov@gmail.com> / [@mifkata](https://github.com/mifkata)

## Links

- [GitHub Repository](https://github.com/mifkata/listmonk-elixir-client)
- [Listmonk Official Site](https://listmonk.app)
- [Listmonk GitHub](https://github.com/knadh/listmonk)

