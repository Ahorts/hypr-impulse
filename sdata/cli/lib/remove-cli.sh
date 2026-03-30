#!/usr/bin/env bash

# Command: vynx remove-cli
BIN_PATH="/usr/local/bin/vynx"

echo -e "${RED}• Removing Vynx CLI from the system (requires sudo)...${NC}"

if [ -L "$BIN_PATH" ]; then
    echo -e "${RED}Are you sure you want to remove Vynx CLI? (y/n): ${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Operation cancelled.${NC}"
        exit 0
    fi
    sudo rm "$BIN_PATH"
    echo -e "${GREEN}✓ Vynx CLI has been successfully removed from $BIN_PATH.${NC}"
    echo -e "${BLUE}The repository at $BASE_DIR remains intact.${NC}"
else
    echo -e "${YELLOW}Vynx CLI (/usr/local/bin/vynx) not found.${NC}"
fi