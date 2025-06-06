# AGENTS.md

## Build & Test Commands
```
mix deps.get                     # Install dependencies
mix compile                      # Compile the project
mix test                         # Run all tests
mix test path/to/test.exs        # Run specific test file
mix test path/to/test.exs:42     # Run test at specific line
mix lint                         # Run formatter and compile
mix format                       # Format code
mix assets.deploy               # Build and minify assets
```

## Code Style Guidelines
- **Formatting**: Use `mix format` with standard formatter settings
- **Types**: Define `@type` specs for structs and custom types; use `@spec` for all public functions
- **Documentation**: Include `@moduledoc` for modules and `@doc` for public functions
- **Modules**: Use PascalCase for modules, snake_case for functions and variables
- **Error Handling**: Use tagged tuples like `{:ok, result}` and `{:error, reason}`
- **Patterns**: Use pattern matching in function clauses, guard clauses for validation
- **Imports**: Use targeted imports with `only:` option; prefer aliases
- **Structure**: Public functions first, private functions last
- **Tests**: Use descriptive `describe` blocks with specific test cases
