#!/bin/bash

INTERVAL=10
TOTAL_DURATION=30
SOURCE_TYPE="monitor"  # monitor | input

while getopts "i:t:s:" opt; do
  case $opt in
    i) INTERVAL=$OPTARG ;;
    t) TOTAL_DURATION=$OPTARG ;;
    s) SOURCE_TYPE=$OPTARG ;;
    *) exit 1 ;;
  esac
done

if ! command -v songrec >/dev/null 2>&1 || ! command -v parec >/dev/null 2>&1 || ! command -v ffmpeg >/dev/null 2>&1; then
    exit 1
fi

if [ "$SOURCE_TYPE" = "monitor" ]; then
    AUDIO_DEVICE=$(pactl get-default-sink).monitor
elif [ "$SOURCE_TYPE" = "input" ]; then
    AUDIO_DEVICE=$(pactl get-default-source)
else
    echo "Invalid source type"
    exit 1
fi

if [ -z "$AUDIO_DEVICE" ] || ! pactl list short sources | grep -q "$AUDIO_DEVICE"; then
    exit 1
fi

TMPDIR=$(mktemp -d /tmp/songrec_chunks_XXXXXX)
trap 'rm -rf "$TMPDIR"' EXIT

ELAPSED=0
while [ "$ELAPSED" -lt "$TOTAL_DURATION" ]; do
    RAW="$TMPDIR/chunk.raw"
    WAV="$TMPDIR/chunk.wav"
    rm -f "$RAW" "$WAV"

    # INTERVAL saniyelik PCM kaydı al
    timeout "$((INTERVAL + 2))" parec \
        --device="$AUDIO_DEVICE" \
        --rate=44100 --channels=2 --format=s16le \
        --raw "$RAW" 2>/dev/null

    ffmpeg -loglevel quiet -f s16le -ar 44100 -ac 2 -i "$RAW" -y "$WAV" 2>/dev/null

    RESULT=$(songrec recognize --json "$WAV" 2>/dev/null)

    if echo "$RESULT" | grep -q '"matches": \[{' ; then
        echo "$RESULT"
        exit 0
    fi

    ELAPSED=$((ELAPSED + INTERVAL))
done

exit 0