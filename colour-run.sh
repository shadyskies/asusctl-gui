#!/bin/bash

# This script launches a KDE color picker, then presents mode options via a menu.
# It runs the corresponding 'asusctl aura' command with the selected color (if needed).

# --- Configuration ---
DEFAULT_COLOR="#00ff00" # Optional default color (#RRGGBB)

# --- Dependency Check ---
if ! command -v kdialog &> /dev/null; then
    echo "Error: 'kdialog' command not found." >&2
    echo "Please install it (e.g., 'sudo apt install kdialog' or 'sudo dnf install kdialog')." >&2
    exit 1
fi
if ! command -v asusctl &> /dev/null; then
    echo "Warning: 'asusctl' command not found. Final command execution will fail." >&2
fi

# --- Step 1: Color Selection ---
echo "Launching KDE color selector..." >&2
echo "Step 1: Select the desired color and click OK." >&2
KDIALOG_COLOR_ARGS=("--getcolor" "--title=Step 1: Select Aura Color")
if [[ -n "$DEFAULT_COLOR" && "$DEFAULT_COLOR" =~ ^#[0-9a-fA-F]{6}$ ]]; then
    KDIALOG_COLOR_ARGS+=("--default" "$DEFAULT_COLOR")
elif [ -n "$DEFAULT_COLOR" ]; then
    echo "Warning: Invalid DEFAULT_COLOR format ('$DEFAULT_COLOR'). Ignoring default." >&2
fi

HEX_COLOR_WITH_HASH=$(kdialog "${KDIALOG_COLOR_ARGS[@]}")
KDIALOG_COLOR_EXIT_STATUS=$?

if [ $KDIALOG_COLOR_EXIT_STATUS -ne 0 ]; then
    echo "Color selection cancelled." >&2
    exit 2
fi
if [[ ! "$HEX_COLOR_WITH_HASH" =~ ^#([0-9a-fA-F]{6})$ ]]; then
    echo "Error: Invalid color format received: '$HEX_COLOR_WITH_HASH'" >&2
    exit 3
fi
HEX_CODE_CLEAN="${BASH_REMATCH[1]}" # Extract hex without # using regex group

# --- Step 2: Mode Selection using --menu ---
echo "Color selected: $HEX_COLOR_WITH_HASH" >&2
echo "Launching mode selector..." >&2
echo "Step 2: Choose the desired Aura mode from the menu." >&2

# --menu requires <tag> <item> pairs. kdialog returns the <tag> on selection.
# We use descriptive tags here.
SELECTED_MODE_TAG=$(kdialog --menu "Step 2: Select Aura Mode" \
                           "static"        "Static (Uses selected color)" \
                           "breathe"       "Breathe (Uses selected color)" \
                           "rainbow-cycle" "Rainbow Cycle (Color ignored)" \
                           "rainbow-wave"  "Rainbow Wave (Color ignored)" \
                           "pulse"         "Pulse (Uses selected color)" \
                           --title="Step 2: Select Aura Mode")
KDIALOG_MODE_EXIT_STATUS=$?

# Check if mode selection was cancelled (e.g., Escape or closing window)
# kdialog --menu returns exit code 1 for Cancel/Close, 0 for OK
if [ $KDIALOG_MODE_EXIT_STATUS -ne 0 ]; then
    echo "Mode selection cancelled." >&2
    exit 4
fi

# Check if we got a tag back (should always happen if exit status is 0)
if [ -z "$SELECTED_MODE_TAG" ]; then
    echo "Error: Mode selection failed unexpectedly (no tag returned)." >&2
    exit 5
fi

# --- Step 3: Command Execution ---
COMMAND_TO_RUN=""
echo "Mode tag selected: $SELECTED_MODE_TAG" >&2

# Use the tag returned by kdialog --menu in the case statement
case "$SELECTED_MODE_TAG" in
    "static")
        COMMAND_TO_RUN="asusctl aura static -c $HEX_CODE_CLEAN"
        ;;
    "breathe")
        COMMAND_TO_RUN="asusctl aura breathe -c $HEX_CODE_CLEAN"
        ;;
    "rainbow-cycle")
        COMMAND_TO_RUN="asusctl aura rainbow-cycle"
        ;;
    "rainbow-wave")
        COMMAND_TO_RUN="asusctl aura rainbow-wave"
        ;;
    "pulse")
         COMMAND_TO_RUN="asusctl aura pulse -c $HEX_CODE_CLEAN"
        ;;
    *)
        echo "Error: Unknown mode tag selected '$SELECTED_MODE_TAG'." >&2
        exit 6
        ;;
esac

echo "Running command: $COMMAND_TO_RUN" >&2

# Execute the constructed command
eval "$COMMAND_TO_RUN"
COMMAND_EXIT_STATUS=$?

if [ $COMMAND_EXIT_STATUS -ne 0 ]; then
   echo "Error: '$COMMAND_TO_RUN' failed with exit status $COMMAND_EXIT_STATUS." >&2
   exit $COMMAND_EXIT_STATUS
else
   echo "'$COMMAND_TO_RUN' executed successfully." >&2
fi

exit 0
