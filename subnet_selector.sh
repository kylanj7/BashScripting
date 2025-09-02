#!/bin/bash

SNET24="/hostdeploy24.sh"
SNET23="/hostdeploy23.sh"

while true; do
    echo "Network Config Selector"
    echo "1) Select /24 network"
    echo "2) Select /23 network" 
    echo "3) Exit"
    read -p "Select the number asscociated with your choice and press enter. " choice
    
    case $choice in
        1) [ -x "$SNET24" ] && "$SNET24" || echo "Error: $SCRIPT1 not found/executable" ;; #Tests if the file path SNET24 exists AND is executable. 
        2) [ -x "$SNET23" ] && "$SNET23" || echo "Error: $SCRIPT2 not found/executable" ;; #Tests if the file path SNET23 exists AND is executable. 
        3) exit 0 ;;
        *) echo "Invalid choice" ;;
    esac
    
    [ $choice != 3 ] && read -p "Press Enter to continue..."
done
