#!/bin/bash

DIRS=(
    "$HOME"
    "$HOME/Code"
    "$HOME/forge"
    "$HOME/Documents/Revelations"
)

if [[ $# -ge 1 ]]; then
    selected=$1
else
    selected=$(fd . "${DIRS[@]}" --type=dir --max-depth=1 --full-path \
        | sed "s|^$HOME/||" \
        | sk --margin 10%)

    [[ $selected ]] && selected="$HOME/$selected"
fi

[[ ! $selected ]] && exit 0

if [[ $# -ge 2 ]]; then
    selected_name=$2
else
    selected_name=$(basename "$selected" | tr . _)
fi

if ! tmux has-session -t "$selected_name"; then
    tmux new-session -ds "$selected_name" -c "$selected"
    tmux select-window -t "$selected_name:1"
fi

tmux switch-client -t "$selected_name"
