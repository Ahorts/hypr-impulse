#!/usr/bin/env bash

# Script directory (where random_wallpaper.sh is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RANDOM_WALLPAPER_SCRIPT="$SCRIPT_DIR/random_wallpaper.sh"

# Wait time in seconds (10 minutes = 600 seconds)
WAIT_TIME=600

# Check if random_wallpaper.sh exists
if [[ ! -f "$RANDOM_WALLPAPER_SCRIPT" ]]; then
  echo "Error: random_wallpaper.sh not found at $RANDOM_WALLPAPER_SCRIPT"
  echo "Make sure this script is in the same directory as random_wallpaper.sh"
  exit 1
fi

echo "Starting wallpaper rotation loop..."
echo "Changing wallpaper every 10 minutes"
echo "Power Management: Videos will be skipped when on battery."
echo "Press Ctrl+C to stop"
echo ""

# Counter for tracking iterations
counter=1

while true; do
  # Determine power status using upower
  # Finds the AC adapter/Line Power device and checks if it's 'online'
  POWER_DEVICE=$(upower -e | grep -E 'line_power|AC')
  
  if [[ -n "$POWER_DEVICE" ]] && upower -i "$POWER_DEVICE" | grep -q "online: *no"; then
    BATTERY_FLAG="--no-video"
    echo "[$(date '+%H:%M:%S')] Battery mode detected. Videos will be filtered out."
  else
    BATTERY_FLAG=""
    echo "[$(date '+%H:%M:%S')] AC power detected. Videos allowed."
  fi

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $counter - Setting new wallpaper..."

  # Execute random_wallpaper.sh with battery flag and any arguments passed to this script
  "$RANDOM_WALLPAPER_SCRIPT" $BATTERY_FLAG "$@"

  if [[ $? -eq 0 ]]; then
    echo "Wallpaper changed successfully"
  else
    echo "Error: Failed to change wallpaper"
  fi

  echo "Waiting 10 minutes until next change..."
  echo ""

  sleep $WAIT_TIME
  ((counter++))
done