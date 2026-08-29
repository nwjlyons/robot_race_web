#!/usr/bin/env bash
set -euo pipefail

if ! command -v mise >/dev/null 2>&1; then
  echo "mise is required. Install it from https://mise.jdx.dev/getting-started.html" >&2
  exit 1
fi

mise install
mise exec -- elixir -v
