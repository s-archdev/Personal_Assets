#!/bin/bash

# Digital ASCII Clock Script
# Usage: ./clock.sh

# Function to clear screen and move cursor to top
clear_screen() {
    printf "\033[2J\033[H"
}

# ASCII digit patterns (5 rows high)
get_digit() {
    case $1 in
        0)
            echo " ███ "
            echo "█   █"
            echo "█   █"
            echo "█   █"
            echo " ███ "
            ;;
        1)
            echo "  █  "
            echo " ██  "
            echo "  █  "
            echo "  █  "
            echo " ███ "
            ;;
        2)
            echo " ███ "
            echo "    █"
            echo " ███ "
            echo "█    "
            echo "█████"
            ;;
        3)
            echo " ███ "
            echo "    █"
            echo " ███ "
            echo "    █"
            echo " ███ "
            ;;
        4)
            echo "█   █"
            echo "█   █"
            echo "█████"
            echo "    █"
            echo "    █"
            ;;
        5)
            echo "█████"
            echo "█    "
            echo "█████"
            echo "    █"
            echo "█████"
            ;;
        6)
            echo " ███ "
            echo "█    "
            echo "████ "
            echo "█   █"
            echo " ███ "
            ;;
        7)
            echo "█████"
            echo "    █"
            echo "   █ "
            echo "  █  "
            echo " █   "
            ;;
        8)
            echo " ███ "
            echo "█   █"
            echo " ███ "
            echo "█   █"
            echo " ███ "
            ;;
        9)
            echo " ███ "
            echo "█   █"
            echo " ████"
            echo "    █"
            echo " ███ "
            ;;
        :)
            echo "     "
            echo "  █  "
            echo "     "
            echo "  █  "
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
    local current_time=$(date "+%H:%M:%S")
    
    clear_screen
    echo
    echo "    Digital Clock"
    echo "    ============="
    echo
    
    # Display all 5 rows of the time
    for row in {0..4}; do
        display_row $row "$current_time"
    done
    
    echo
    echo "    Press Ctrl+C to exit"
}

# Trap Ctrl+C to clean up
trap 'clear_screen; echo "Clock stopped."; exit 0' INT

# Main loop
while true; do
    display_time
    sleep 1
done