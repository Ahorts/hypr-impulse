#!/usr/bin/env bash
# Generates Material You theme for YouTube Music Desktop via matugen native template

set -euo pipefail

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YTM_DIR="$XDG_CONFIG_HOME/YouTube Music"
COLORS_JSON="$XDG_STATE_HOME/quickshell/user/generated/colors.json"
TEMPLATE="$SCRIPT_DIR/ytmusic.css"
OUTPUT="$YTM_DIR/style.css"

# Only run if YouTube Music Desktop is installed
if [ ! -d "$YTM_DIR" ]; then
    exit 0
fi

# require the colors.json
if [ ! -f "$COLORS_JSON" ]; then
    echo "[generate-ytmusic-theme] Error: colors.json not found at '$COLORS_JSON'." \
         "Run switchwall.sh first." >&2
    exit 1
fi

sed_expr=""
while IFS="=" read -r key value; do
    sed_expr+="s|{{colors.${key}.default.hex}}|${value}|g;"
done < <(jq -r 'to_entries[] | "\(.key)=\(.value)"' "$COLORS_JSON")

sed "$sed_expr" "$TEMPLATE" > "$OUTPUT"

echo "[generate-ytmusic-theme] Done. Theme written to: $OUTPUT"
