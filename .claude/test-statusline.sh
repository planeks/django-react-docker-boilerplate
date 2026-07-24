#!/usr/bin/env bash
# Feed fake session JSON to the project statusline to preview warnings.
# Usage: test-statusline.sh [ctx%] [5h%] [7d%]

ctx=${1:-88}
five=${2:-91}
seven=${3:-25}
now=$(date +%s)
script=/home/oleh/workspace/django-react-docker-boilerplate/.claude/statusline.sh

echo "{\"model\":{\"display_name\":\"Fable 5\"},
\"context_window\":{\"used_percentage\":$ctx,\"context_window_size\":200000,
\"total_input_tokens\":170000,\"total_output_tokens\":6000},
\"workspace\":{\"project_dir\":\"/home/oleh/workspace/django-react-docker-boilerplate\"},
\"rate_limits\":{\"five_hour\":{\"used_percentage\":$five,\"resets_at\":$((now + 8000))},
\"seven_day\":{\"used_percentage\":$seven,\"resets_at\":$((now + 280000))}}}" | bash "$script"
