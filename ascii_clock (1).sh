#!/bin/bash

# Digital ASCII Clock Script - macOS Compatible
# Usage: ./clock.sh

# Function to clear screen and move cursor to top
clear_screen() {
    printf "\033[2J\033[H"
    # Ensure compatibility with macOS Terminal
    tput cup 0 0 2>/dev/null || true
}

# ASCII digit patterns (5 rows high) - macOS compatible characters
get_digit() {
    case $1 in
        0)
            echo " ### "
            echo "#   #"
            echo "#   #"
            echo "#   #"
            echo " ### "
            ;;
        1)
            echo "  #  "
            echo " ##  "
            echo "  #  "
            echo "  #  "
            echo " ### "
            ;;
        2)
            echo " ### "
            echo "    #"
            echo " ### "
            echo "#    "
            echo "#####"
            ;;
        3)
            echo " ### "
            echo "    #"
            echo " ### "
            echo "    #"
            echo " ### "
            ;;
        4)
            echo "#   #"
            echo "#   #"
            echo "#####"
            echo "    #"
            echo "    #"
            ;;
        5)
            echo "#####"
            echo "#    "
            echo "#####"
            echo "    #"
            echo "#####"
            ;;
        6)
            echo " ### "
            echo "#    "
            echo "#### "
            echo "#   #"
            echo " ### "
            ;;
        7)
            echo "#####"
            echo "    #"
            echo "   # "
            echo "  #  "
            echo " #   "
            ;;
        8)
            echo " ### "
            echo "#   #"
            echo " ### "
            echo "#   #"
            echo " ### "
            ;;
        9)
            echo " ### "
            echo "#   #"
            echo " ####"
            echo "    #"
            echo " ### "
            ;;
        :)
            echo "     "
            echo "  #  "
            echo "     "
            echo "  #  "
            echo "     "
            ;;
    esac
}

# Function to display a row of the time
display_row() {
    local row=$1
    local time_str=$2
    local output=""
    
    for (( i=0; i<${#time_str}; i++ )); do
        char="${time_str:$i:1}"
        digit_rows=($(get_digit "$char"))
        output+="${digit_rows[$row]} "
    done
    
    echo "$output"
}

# Function to display the complete time
display_time() {
    # Use macOS compatible date command
    local current_time
    if command -v gdate >/dev/null 2>&1; then
        # Use GNU date if available (from brew install coreutils)
        current_time=$(gdate "+%H:%M:%S")
    else
        # Use macOS BSD date
        current_time=$(date "+%H:%M:%S")
    fi
    
    clear_screen
    echo
    echo "    Digital Clock (macOS)"
    echo "    ===================="
    echo
    
    # Display all 5 rows of the time
    for row in {0..4}; do
        display_row $row "$current_time"
    done
    
    echo
    echo "    Press Ctrl+C to exit"
}

# Trap Ctrl+C to clean up and restore terminal
trap 'clear_screen; echo "Clock stopped."; stty echo 2>/dev/null || true; exit 0' INT TERM

# Hide cursor for cleaner display
printf "\033[?25l" 2>/dev/null || true

# Main loop with better macOS terminal handling
while true; do
    display_time
    # Use built-in sleep which is more reliable on macOS
    sleep 1
done