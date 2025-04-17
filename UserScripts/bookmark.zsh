#!/bin/bash

# URL Launcher - Launch URLs with custom key mappings
# Usage: ./url_launcher.sh

# Colors for better UI
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Config file location
CONFIG_FILE="$HOME/.url_launcher_config"
touch "$CONFIG_FILE" 2>/dev/null || { echo "Error: Cannot create config file"; exit 1; }

# Function to add a new URL mapping
add_mapping() {
    echo -e "${BLUE}Enter URL:${NC}"
    read url
    
    if [[ ! "$url" =~ ^https?:// ]]; then
        url="https://$url"
    fi
    
    echo -e "${BLUE}Enter a name for this URL:${NC}"
    read name
    
    echo -e "${BLUE}Enter a single key to map to this URL:${NC}"
    read -n 1 key
    
    # Convert to lowercase
    key=$(echo "$key" | tr '[:upper:]' '[:lower:]')
    
    # Check if key already exists
    if grep -q "^$key:" "$CONFIG_FILE"; then
        echo -e "\n${YELLOW}Warning: Key '$key' is already mapped.${NC}"
        echo -e "${BLUE}Do you want to overwrite it? (y/n)${NC}"
        read -n 1 overwrite
        echo
        
        if [[ "$overwrite" != "y" ]]; then
            echo -e "${RED}Mapping not added.${NC}"
            return 1
        fi
        
        # Remove existing mapping
        sed -i "/^$key:/d" "$CONFIG_FILE"
    fi
    
    # Add the new mapping
    echo "$key:$name:$url" >> "$CONFIG_FILE"
    echo -e "\n${GREEN}Mapping added: Press '$key' to launch $name ($url)${NC}"
}

# Function to list all mappings
list_mappings() {
    echo -e "${BLUE}Current URL Mappings:${NC}\n"
    
    if [[ ! -s "$CONFIG_FILE" ]]; then
        echo -e "${YELLOW}No mappings found. Add some with option 1.${NC}"
        return
    fi
    
    echo -e "${GREEN}KEY | NAME | URL${NC}"
    echo "-------------------------"
    
    while IFS=: read -r key name url; do
        echo -e "${GREEN}$key${NC}   | ${YELLOW}$name${NC} | $url"
    done < "$CONFIG_FILE"
}

# Function to remove a mapping
remove_mapping() {
    echo -e "${BLUE}Enter the key of the mapping you want to remove:${NC}"
    read -n 1 key
    
    if grep -q "^$key:" "$CONFIG_FILE"; then
        name=$(grep "^$key:" "$CONFIG_FILE" | cut -d':' -f2)
        sed -i "/^$key:/d" "$CONFIG_FILE"
        echo -e "\n${GREEN}Removed mapping for key '$key' ($name)${NC}"
    else
        echo -e "\n${RED}No mapping found for key '$key'${NC}"
    fi
}

# Function to launch a URL by key
launch_url() {
    if [[ ! -s "$CONFIG_FILE" ]]; then
        echo -e "${YELLOW}No mappings found. Add some with option 1.${NC}"
        return
    fi
    
    echo -e "${BLUE}Press the key for the URL you want to launch:${NC}"
    read -n 1 key
    
    # Convert to lowercase
    key=$(echo "$key" | tr '[:upper:]' '[:lower:]')
    
    if grep -q "^$key:" "$CONFIG_FILE"; then
        url=$(grep "^$key:" "$CONFIG_FILE" | cut -d':' -f3)
        name=$(grep "^$key:" "$CONFIG_FILE" | cut -d':' -f2)
        
        echo -e "\n${GREEN}Launching $name...${NC}"
        
        # Detect the operating system and launch the URL accordingly
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            xdg-open "$url" &>/dev/null &
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            open "$url" &>/dev/null &
        elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
            start "$url" &>/dev/null &
        else
            echo -e "${RED}Unsupported operating system.${NC}"
            return 1
        fi
    else
        echo -e "\n${RED}No URL mapped to key '$key'${NC}"
    fi
}

# Quick launch mode - launch URL immediately
quick_launch() {
    if [[ ! -s "$CONFIG_FILE" ]]; then
        echo -e "${YELLOW}No mappings found. Add some first.${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}URL Launcher - Quick Mode${NC}"
    echo -e "${BLUE}Press a key to launch the corresponding URL (or q to quit):${NC}"
    
    while true; do
        read -n 1 key
        
        if [[ "$key" == "q" ]]; then
            echo -e "\n${GREEN}Exiting URL Launcher.${NC}"
            exit 0
        fi
        
        # Convert to lowercase
        key=$(echo "$key" | tr '[:upper:]' '[:lower:]')
        
        if grep -q "^$key:" "$CONFIG_FILE"; then
            url=$(grep "^$key:" "$CONFIG_FILE" | cut -d':' -f3)
            name=$(grep "^$key:" "$CONFIG_FILE" | cut -d':' -f2)
            
            echo -e "\n${GREEN}Launching $name ($url)...${NC}"
            
            # Detect the operating system and launch the URL accordingly
            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                xdg-open "$url" &>/dev/null &
            elif [[ "$OSTYPE" == "darwin"* ]]; then
                open "$url" &>/dev/null &
            elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
                start "$url" &>/dev/null &
            else
                echo -e "${RED}Unsupported operating system.${NC}"
            fi
        else
            echo -e "\n${RED}No URL mapped to key '$key'${NC}"
        fi
        
        echo -e "\n${BLUE}Press another key to launch a URL (or q to quit):${NC}"
    done
}

# Main menu
if [[ "$1" == "--quick" || "$1" == "-q" ]]; then
    quick_launch
else
    while true; do
        echo -e "\n${BLUE}URL Launcher - Main Menu${NC}"
        echo -e "${GREEN}1${NC}. Add new URL mapping"
        echo -e "${GREEN}2${NC}. List URL mappings"
        echo -e "${GREEN}3${NC}. Remove URL mapping"
        echo -e "${GREEN}4${NC}. Launch URL by key"
        echo -e "${GREEN}5${NC}. Enter quick launch mode"
        echo -e "${GREEN}q${NC}. Quit"
        echo -e "${BLUE}Enter your choice:${NC}"
        
        read -n 1 choice
        echo
        
        case "$choice" in
            1) add_mapping ;;
            2) list_mappings ;;
            3) remove_mapping ;;
            4) launch_url ;;
            5) quick_launch ;;
            q) echo -e "${GREEN}Goodbye!${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid choice.${NC}" ;;
        esac
    done
fi

