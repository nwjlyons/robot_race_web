# Used by "mix format"
[
  import_deps: [:ecto, :phoenix],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"],
  plugins: [Phoenix.LiveView.HTMLFormatter]
]
