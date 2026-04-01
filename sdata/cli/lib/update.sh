#!/usr/bin/env bash

# Command: vynx update
echo -e "${BLUE}Updating Vynx...${NC}"

export VERBOSE="${VERBOSE:-false}"

DO_PULL=true
BACKUP=true
FORCE_INSTALL=false
FULL_INSTALL=false
NO_CONFIRM=false

for arg in "$@"; do
    case $arg in
        --no-pull)       DO_PULL=false ;;
        --no-backup)     BACKUP=false ;;
        --force-install) FORCE_INSTALL=true ;;
        --full-install)  FULL_INSTALL=true ;;
        --no-confirm)    NO_CONFIRM=true ;;
        *)
            echo -e "${RED}Unknown flag: $arg${NC}"
            echo "Usage: vynx update [--no-pull] [--no-backup] [--force-install] [--full-install] [--no-confirm]"
            exit 1
            ;;
    esac
done

SETUP_FLAGS=""
[[ "$VERBOSE" == "true" ]]      && SETUP_FLAGS="$SETUP_FLAGS -v"
[[ "$DO_PULL" == "false" ]]     && SETUP_FLAGS="$SETUP_FLAGS --no-pull"
[[ "$BACKUP" == "false" ]]      && SETUP_FLAGS="$SETUP_FLAGS --no-backup"
[[ "$FORCE_INSTALL" == "true" ]] && SETUP_FLAGS="$SETUP_FLAGS --force-install"
[[ "$FULL_INSTALL" == "true" ]]  && SETUP_FLAGS="$SETUP_FLAGS --full-install"
[[ "$NO_CONFIRM" == "true" ]]   && SETUP_FLAGS="$SETUP_FLAGS --no-confirm"

if [ -d "$BASE_DIR" ]; then
    cd "$BASE_DIR"
    if [[ "$VERBOSE" == "true" ]]; then
        git pull
    else
        git pull > /dev/null 2>&1
    fi
    
    echo -e "${GREEN}Vynx repo updated successfully!${NC}"
    
    bash setup-ii-vynx.sh $SETUP_FLAGS
else
    echo -e "${RED}Error: Cannot find install path.${NC}"
    exit 1
fi