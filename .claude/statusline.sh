#!/bin/bash
# Claude Code status line: model, git branch, context usage, caveman mode.
# Receives session JSON on stdin, prints one line. Needs jq.

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "?"')
context_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0 | floor')
used_tokens=$(echo "$input" | jq -r '((.context_window.total_input_tokens // 0) + (.context_window.total_output_tokens // 0))')
max_tokens=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // "."')

branch=$(git -C "$project_dir" branch --show-current 2>/dev/null)

humanize() {
    awk -v n="$1" 'BEGIN {
        if (n >= 1000000) printf "%.1fM", n / 1000000
        else if (n >= 1000) printf "%dk", n / 1000
        else printf "%d", n
    }'
}

cyan='\033[1;36m'
blue='\033[34m'
dim='\033[2m'
orange='\033[38;5;208m'
reset='\033[0m'

# Context number: green under 60%, yellow under 85%, red above.
if [ "$context_pct" -ge 85 ]; then
    pct_color='\033[31m'
elif [ "$context_pct" -ge 60 ]; then
    pct_color='\033[33m'
else
    pct_color='\033[32m'
fi

# Caveman plugin keeps its level in this flag file; absent or "off" means inactive.
caveman_flag="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.caveman-active"
caveman=""
if [ -f "$caveman_flag" ]; then
    level=$(cat "$caveman_flag")
    if [ -n "$level" ] && [ "$level" != "off" ]; then
        caveman=$(printf ' %b|%b %bcaveman:%s%b' "$dim" "$reset" "$orange" "$level" "$reset")
    fi
fi

printf '%b[%s]%b %b%s%b %b|%b ctx %b%s%%%b %b(%s/%s)%b%s\n' \
    "$cyan" "$model" "$reset" \
    "$blue" "${branch:-no branch}" "$reset" \
    "$dim" "$reset" \
    "$pct_color" "$context_pct" "$reset" \
    "$dim" "$(humanize "$used_tokens")" "$(humanize "$max_tokens")" "$reset" \
    "$caveman"
