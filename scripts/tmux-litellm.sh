#!/bin/bash
exec >>/tmp/tmux-litellm.log 2>&1
set -x

echo "=== $(date) ==="
echo "HOME=$HOME"
echo "PATH=$PATH"

SESSION_NAME="litellm"
INTERCEPTOR_DIR="$HOME/Code/IdeaProjects/deliveryhero/llm-interceptor/"

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    tmux kill-session -t "$SESSION_NAME"
    tmux display-popup -T " litellm " -s "fg=yellow" -w 40 -h 3 -E "echo ''; echo '  ✗ litellm proxy stopped'; sleep 2"
    exit 0
fi

tmux new-session -ds "$SESSION_NAME" -n "litellm" -c "$HOME"
tmux send-keys -t "$SESSION_NAME:litellm" "dp-devinfra litellm token && dp-devinfra litellm proxy || echo 'FAILED'" Enter

tmux new-window -a -t "$SESSION_NAME" -n "interceptor" -c "$INTERCEPTOR_DIR"
tmux send-keys -t "$SESSION_NAME:interceptor" "bun start" Enter

(
    for i in {1..30}; do
        output=$(tmux capture-pane -t "$SESSION_NAME" -p)

        if echo "$output" | grep -q "Listening on"; then
            tmux display-popup -T " litellm " -s "fg=green" -w 40 -h 3 -E "echo ''; echo '  ✓ litellm proxy is running'; sleep 3"
            exit 0
        fi

        if echo "$output" | grep -q "^FAILED$"; then
            tmux display-popup -T " litellm " -s "fg=red" -w 40 -h 3 -E "echo ''; echo '  ✗ litellm proxy failed to start'; sleep 3"
            exit 1
        fi

        sleep 1
    done

    tmux display-popup -T " litellm " -s "fg=red" -w 40 -h 3 -E "echo ''; echo '  ✗ litellm proxy failed to start'; sleep 3"
) &
disown
