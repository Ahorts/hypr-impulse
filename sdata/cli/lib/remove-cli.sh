#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CLI_NAME="vynx"
BIN_PATH="$HOME/.local/bin/$CLI_NAME"

echo -e "${RED}• Removing Vynx CLI (user mode)...${NC}"

if [ -L "$BIN_PATH" ]; then
    echo -e "${RED}Are you sure you want to remove Vynx CLI? (y/n): ${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Operation cancelled.${NC}"
        exit 0
    fi

    rm "$BIN_PATH"

    echo -e "${GREEN}✓ Vynx CLI removed from $BIN_PATH.${NC}"
    echo -e "${BLUE}The repository at $BASE_DIR remains intact.${NC}"
else
    echo -e "${YELLOW}Vynx CLI not found at $BIN_PATH.${NC}"

    ALT_PATH="$(command -v $CLI_NAME 2>/dev/null)"

    if [ -n "$ALT_PATH" ]; then
        echo -e "${YELLOW}⚠ Found $CLI_NAME at: $ALT_PATH${NC}"
        echo -e "${YELLOW}You may need to remove it manually.${NC}"
    fi
fi