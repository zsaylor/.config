#!/usr/bin/env bash

set -euo pipefail

cache="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-litellm-budget"

if [[ "${1:-}" == "--refresh" ]]; then
  result="$(dp-devinfra litellm usage 2>/dev/null \
    | awk 'NF>=4 && $1 ~ /^\$/ {remaining=$3; util=$4} END {if (remaining!="") print remaining " (" util ")"}')"
  [[ -n "$result" ]] && printf '%s\n' "$result" > "$cache"
fi

[[ -f "$cache" ]] && cat "$cache" || printf '%s\n' "<leader>$"
