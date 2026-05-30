#!/usr/bin/env bash
# hyprset.sh - thin wrapper for hyprset.lua
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="${1:-}"

case "$MODE" in
    key)   exec lua "$SCRIPT_DIR/hyprset.lua" set "$2" "$3" ;;
    anim)  exec lua "$SCRIPT_DIR/hyprset.lua" set-animation "$2" "$3" ;;
    reset) exec lua "$SCRIPT_DIR/hyprset.lua" reset "$2" ;;
    merge) exec lua "$SCRIPT_DIR/hyprset.lua" merge "$2" ;;
    set|set-animation|reset)
           exec lua "$SCRIPT_DIR/hyprset.lua" "$@" ;;
    *)
        echo "Usage: vynx hyprset <key|anim|reset|merge> [...]"
        echo "  key   <section:field> <value>   Set a hyprland option"
        echo "  anim  <name> <style>            Set animation style"
        echo "  reset <key>                     Remove an override"
        echo "  merge <file>                    Merge repo defaults"
        exit 1 ;;
esac
