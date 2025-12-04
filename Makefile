.PHONY: help install compile console format format-check lint lint-strict dialyzer test clean docs all

# Default target
help:
	@echo "Available targets:"
	@echo "  make install       - Install dependencies"
	@echo "  make compile       - Compile the project"
	@echo "  make console       - Start IEx with the project loaded"
	@echo "  make format        - Format code"
	@echo "  make format-check  - Check code formatting"
	@echo "  make lint          - Run Credo linter"
	@echo "  make lint-strict   - Run Credo linter (strict mode)"
	@echo "  make dialyzer      - Run Dialyzer static analysis"
	@echo "  make test          - Run tests"
	@echo "  make docs          - Generate documentation"
	@echo "  make clean         - Clean build artifacts"
	@echo "  make all           - Run format, lint, test, and dialyzer checks"

# Install dependencies
install:
	mix deps.get

# Compile the project
compile: install
	mix compile

# Start IEx console with project loaded
console: compile
	@if [ -f .env ]; then \
		echo "Loading environment from .env..."; \
		export $$(cat .env | grep -v '^#' | xargs) && iex -S mix; \
	else \
		echo "Warning: .env file not found. Copy .env.example to .env and configure it."; \
		iex -S mix; \
	fi

# Format code
format:
	mix format

# Check code formatting
format-check:
	mix format --check-formatted

# Run Credo linter
lint:
	mix credo

# Run Credo linter in strict mode
lint-strict:
	mix credo --strict

# Run Dialyzer static analysis
dialyzer:
	mix dialyzer

# Run tests
test:
	mix test

# Generate documentation
docs:
	mix docs

# Clean build artifacts
clean:
	mix clean
	rm -rf _build deps doc priv/plts/*.plt priv/plts/*.plt.hash

# Run all checks (format, lint, test, dialyzer, compile)
all: format lint test dialyzer compile
	@echo "✓ All checks passed!"
