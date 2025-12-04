# Listmonk Elixir Client

[![CI](https://github.com/mifkata/listmonk-elixir-client/actions/workflows/ci.yml/badge.svg)](https://github.com/mifkata/listmonk-elixir-client/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/listmonk_client.svg)](https://hex.pm/packages/listmonk_client)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Elixir client for the [Listmonk](https://listmonk.app) open-source, self-hosted email platform.

Built with [Req](https://github.com/wojtekmach/req) HTTP client and designed for easy integration into Elixir applications.

> **Note:** This library is based on the [Python Listmonk client](https://github.com/mikeckennedy/listmonk) by Michael Kennedy, adapted to idiomatic Elixir patterns and conventions.

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
    {:listmonk_client, "~> 0.2.0"}
  ]
end
```

## Quick Start

### Configuration

For local development, copy the example environment file:

```bash
cp .env.example .env
# Edit .env with your Listmonk instance details
```

Or set environment variables directly:

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
{:ok, healthy} = Listmonk.healthy?()

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

**Quick testing with IEx console:**

```bash
make console
# Your .env will be loaded automatically
# Then try:
Listmonk.healthy?()
Listmonk.get_lists()
```

For detailed examples, see [USAGE.md](USAGE.md).

## Documentation

- [Full Usage Guide](USAGE.md)
- [API Documentation](https://hexdocs.pm/listmonk_client) (coming soon)
- [Listmonk API Docs](https://listmonk.app/docs/apis/apis/)

## Development

Using Make:

```bash
# See all available commands
make help

# Install dependencies
make install

# Run all checks (format, lint, test, dialyzer, compile)
make all

# Individual commands
make format        # Format code
make lint          # Run Credo linter
make test          # Run tests
make dialyzer      # Run Dialyzer static analysis
make compile       # Compile project
make console       # Start IEx console (loads .env if exists)
make docs          # Generate documentation
make clean         # Clean build artifacts
```


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! To ensure your contribution aligns with the project's direction, please follow these steps:

1. **Open an issue first** - Before submitting a Pull Request, please [open an issue](https://github.com/mifkata/listmonk-elixir-client/issues/new) to discuss your proposed changes
2. **Submit a PR** - Once approved, feel free to [submit a Pull Request](https://github.com/mifkata/listmonk-elixir-client/pulls)

**Quick links:**
- [Report a bug or request a feature](https://github.com/mifkata/listmonk-elixir-client/issues/new)
- [View open issues](https://github.com/mifkata/listmonk-elixir-client/issues)
- [Submit a Pull Request](https://github.com/mifkata/listmonk-elixir-client/pulls)

## Acknowledgments

This library is based on the [Python Listmonk client](https://github.com/mikeckennedy/listmonk) by [Michael Kennedy](https://github.com/mikeckennedy). The Python implementation served as a reference for API coverage and functionality, adapted here to follow Elixir patterns and conventions.

## Author

Andriyan Ivanov <andriyan.ivanov@gmail.com> / [@mifkata](https://github.com/mifkata)

## Links

- [GitHub Repository](https://github.com/mifkata/listmonk-elixir-client)
- [Listmonk Official Site](https://listmonk.app)
- [Listmonk GitHub](https://github.com/knadh/listmonk)
