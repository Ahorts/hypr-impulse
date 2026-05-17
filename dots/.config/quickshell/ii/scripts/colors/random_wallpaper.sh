#!/usr/bin/env bash

# Default wallpaper directory
DEFAULT_WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Script directory (where switchwall.sh is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWITCHWALL_SCRIPT="$SCRIPT_DIR/switchwall.sh"

# State file to track current position
STATE_FILE="$SCRIPT_DIR/.wallpaper_position"

# Supported image and video extensions
IMAGE_EXTENSIONS=("jpg" "jpeg" "png" "gif" "bmp" "webp" "tiff" "svg")
VIDEO_EXTENSIONS=("mp4" "mkv" "webm")
SUPPORTED_EXTENSIONS=("${IMAGE_EXTENSIONS[@]}" "${VIDEO_EXTENSIONS[@]}")

usage() {
    echo "Usage: $0 [OPTIONS] [DIRECTORY]"
    echo ""
    echo "Sequentially select and set wallpapers from a directory"
    echo ""
    echo "OPTIONS:"
    echo "  -d, --directory DIR    Directory to search for wallpapers"
    echo "  --mode MODE           Color mode: dark or light"
    echo "  --type TYPE           Color scheme type"
    echo "  --color [HEX]         Use color instead of image (optional hex color)"
    echo "  --recursive           Search subdirectories recursively"
    echo "  --list-only           Only list found images, don't set wallpaper"
    echo "  --reset               Reset position to start from beginning"
    echo "  --show-position       Show current position and exit"
    echo "  --no-video            Skip video files (useful for battery saving)"
    echo "  -h, --help            Show this help message"
}

find_images() {
    local search_dir="$1"
    local recursive="$2"
    local skip_video="$3"
    local find_args=()
    
    if [[ ! -d "$search_dir" ]]; then
        echo "Error: Directory '$search_dir' does not exist" >&2
        return 1
    fi
    
    # Build find command arguments
    if [[ "$recursive" == "1" ]]; then
        find_args+=("$search_dir")
    else
        find_args+=("$search_dir" "-maxdepth" "1")
    fi
    
    find_args+=("-type" "f")
    
    # Determine which extensions to look for
    local active_extensions=("${SUPPORTED_EXTENSIONS[@]}")
    if [[ "$skip_video" == "1" ]]; then
        active_extensions=("${IMAGE_EXTENSIONS[@]}")
    fi
    
    # Add extension filters
    local first=1
    find_args+=("(")
    for ext in "${active_extensions[@]}"; do
        if [[ $first -eq 1 ]]; then
            find_args+=("-iname" "*.${ext}")
            first=0
        else
            find_args+=("-o" "-iname" "*.${ext}")
        fi
    done
    find_args+=(")")
    
    # Execute find command and sort for consistent ordering
    find "${find_args[@]}" 2>/dev/null | sort
}

get_state_key() {
    local wallpaper_dir="$1"
    local recursive="$2"
    local skip_video="$3"
    
    # Include no-video status in key to avoid index mismatches when switching power states
    local key="${wallpaper_dir}:${recursive:-0}:${skip_video:-0}"
    echo "$key"
}

read_position() {
    local state_key="$1"
    if [[ -f "$STATE_FILE" ]]; then
        # Look for the line with our state key
        grep "^${state_key}:" "$STATE_FILE" 2>/dev/null | cut -d':' -f4
    fi
}

write_position() {
    local state_key="$1"
    local position="$2"
    touch "$STATE_FILE"
    grep -v "^${state_key}:" "$STATE_FILE" > "${STATE_FILE}.tmp" 2>/dev/null || true
    echo "${state_key}:${position}" >> "${STATE_FILE}.tmp"
    mv "${STATE_FILE}.tmp" "$STATE_FILE"
}

select_next_image() {
    local state_key="$1"
    shift
    local images=("$@")
    
    if [[ ${#images[@]} -eq 0 ]]; then
        echo "Error: No supported images found" >&2
        return 1
    fi
    
    local current_position=$(read_position "$state_key")
    if [[ -z "$current_position" ]] || ! [[ "$current_position" =~ ^[0-9]+$ ]]; then
        current_position=0
    fi
    
    if [[ $current_position -ge ${#images[@]} ]]; then
        current_position=0
    fi
    
    local selected_image="${images[$current_position]}"
    local next_position=$(( (current_position + 1) % ${#images[@]} ))
    write_position "$state_key" "$next_position"
    
    echo "$selected_image"
}

main() {
    local wallpaper_dir="$DEFAULT_WALLPAPER_DIR"
    local recursive=""
    local list_only=""
    local no_video=""
    local reset_position_flag=""
    local show_position_flag=""
    local color_flag=""
    local switchwall_args=()
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) usage; exit 0 ;;
            -d|--directory) wallpaper_dir="$2"; shift 2 ;;
            --mode) switchwall_args+=(--mode "$2"); shift 2 ;;
            --type) switchwall_args+=(--type "$2"); shift 2 ;;
            --color)
                color_flag="1"; switchwall_args+=(--color)
                [[ "$2" =~ ^#?[A-Fa-f0-9]{6}$ ]] && { switchwall_args+=("$2"); shift 2; } || shift
                ;;
            --recursive) recursive="1"; shift ;;
            --list-only) list_only="1"; shift ;;
            --no-video) no_video="1"; shift ;;
            --reset) reset_position_flag="1"; shift ;;
            --show-position) show_position_flag="1"; shift ;;
            *) wallpaper_dir="$1"; shift ;;
        esac
    done
    
    if [[ ! -f "$SWITCHWALL_SCRIPT" ]]; then
        echo "Error: switchwall.sh not found at $SWITCHWALL_SCRIPT" >&2
        exit 1
    fi
    
    if [[ "$color_flag" == "1" ]]; then
        exec "$SWITCHWALL_SCRIPT" "${switchwall_args[@]}"
    fi
    
    wallpaper_dir="${wallpaper_dir/#\~/$HOME}"
    state_key=$(get_state_key "$wallpaper_dir" "$recursive" "$no_video")
    
    if [[ "$reset_position_flag" == "1" ]]; then
        write_position "$state_key" "0"
        echo "Position reset."
        exit 0
    fi
    
    mapfile -t images < <(find_images "$wallpaper_dir" "$recursive" "$no_video")
    
    if [[ ${#images[@]} -eq 0 ]]; then
        echo "No supported files found in '$wallpaper_dir'" >&2
        exit 1
    fi
    
    if [[ "$show_position_flag" == "1" ]]; then
        local current_pos=$(read_position "$state_key")
        echo "Found ${#images[@]} files. Current index: ${current_pos:-0}"
        exit 0
    fi
    
    if [[ "$list_only" == "1" ]]; then
        printf '%s\n' "${images[@]}"; exit 0
    fi
    
    selected_image=$(select_next_image "$state_key" "${images[@]}")
    echo "Selected: $(basename "$selected_image")"
    exec "$SWITCHWALL_SCRIPT" "$selected_image" "${switchwall_args[@]}"
}

main "$@"