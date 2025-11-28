# Changelog

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

[Unreleased]: https://github.com/mifkata/listmonk-elixir-client/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/mifkata/listmonk-elixir-client/releases/tag/v0.1.0
