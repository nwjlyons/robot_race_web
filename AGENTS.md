# AGENTS.md

## Environment Setup
- Elixir and Erlang versions are pinned in `mise.toml`.
- Install mise (https://mise.jdx.dev/getting-started.html).
- Install the pinned tool versions: `mise install`.
- Activate mise in your shell (https://mise.jdx.dev/getting-started.html#activate-mise).

## Common Commands
```bash
mix deps.get                     # Install dependencies
mix compile                      # Compile the project
mix test                         # Run all tests
mix test path/to/test.exs        # Run a specific test file
mix test path/to/test.exs:42     # Run a test at a specific line
mix lint                         # Run formatter and compile checks
mix format                       # Format code
mix assets.deploy                # Build and minify assets
```
