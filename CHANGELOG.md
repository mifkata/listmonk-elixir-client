# Changelog

## [0.3.0] - Unreleased

### Added

- **Process-based client architecture** - The client now uses GenServer processes for managing connections
- `Listmonk.new/1` and `Listmonk.new/2` functions to start client processes
- Named process support via aliases (e.g., `Listmonk.new(config, :my_listmonk)`)
- `Listmonk.get_config/1` to retrieve current configuration from a client
- `Listmonk.set_config/2` to update configuration at runtime
- `Listmonk.stop/1` to stop a client process
- `Listmonk.Server` module implementing the GenServer

### Changed

- **Breaking:** All API functions now require a server reference (pid or atom) as the first argument instead of an optional config as the last argument
- Example migration:
  ```elixir
  # Before (0.2.x)
  {:ok, lists} = Listmonk.get_lists()
  {:ok, lists} = Listmonk.get_lists(config)

  # After (0.3.0)
  {:ok, pid} = Listmonk.new(config)
  {:ok, lists} = Listmonk.get_lists(pid)

  # Or with a named process
  {:ok, _pid} = Listmonk.new(config, :my_listmonk)
  {:ok, lists} = Listmonk.get_lists(:my_listmonk)
  ```
- Removed bang (`!`) variants from submodules - use main `Listmonk` module instead
- Configuration is now validated and resolved at process start time

### Removed

- Direct config passing to API functions (use `Listmonk.new/1` instead)
- `Listmonk.Client` module's public API (now internal to Server)

## [0.2.0] - 2025-11-28

### Added

- Type specifications (`@spec`) for all 46 delegated functions in the main `Listmonk` module, improving IDE support and enabling Dialyzer checks
- Dialyzer static analysis support via `dialyxir` dependency
- `make dialyzer` command for running static analysis
- PLT caching in `priv/plts/` for faster subsequent Dialyzer runs

### Fixed

- `Lists.get_by_id/2` now correctly returns `{:ok, nil}` when a list is not found, matching its type specification (previously returned `{:error, ...}`)

### Changed

- `make all` now includes Dialyzer checks in addition to format and lint
- `make clean` now removes Dialyzer PLT cache files

## [0.1.0] - 2025-11-26

### Added

- Initial release
- Subscriber management (create, read, update, delete, enable, disable, block)
- Mailing list management (create, read, delete)
- Campaign management (create, read, update, delete, preview)
- Template management (create, read, update, delete, preview, set default)
- Transactional email sending with template and attachment support
- Health check endpoint
- Flexible configuration via environment variables or runtime config
- Both safe (`get/1`) and bang (`get!/1`) variants for all operations
- Makefile with common development commands
- Credo linter integration
- ExDoc documentation

[0.3.0]: https://github.com/mifkata/listmonk-elixir-client/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/mifkata/listmonk-elixir-client/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/mifkata/listmonk-elixir-client/releases/tag/v0.1.0
