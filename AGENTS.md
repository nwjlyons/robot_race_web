# AGENTS.md

## Environment Setup
- Elixir and Erlang versions are pinned in `.tool-versions`.
- Install asdf (https://asdf-vm.com/guide/getting-started.html).
- Add plugins: `asdf plugin add erlang` and `asdf plugin add elixir`.
- Install versions from `.tool-versions`: `asdf install`.
- Ensure `asdf` shims are on your `PATH` in your shell config.

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