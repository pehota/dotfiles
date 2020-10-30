#!/bin/bash
# Start a terminal (if there is none), and show (toggle) it as i3 scratchpad
# See <https://www.reddit.com/r/i3wm/comments/8q44zr/script_to_runs_scratchpad_if_not_running/>

TITLE="__${1:-i3-sensible-terminal}__"
WORKSPACE="${2}"
I3_MSG="focus"

if ! pgrep -f "$TITLE"; then
	COMMAND=""

	if command -v "$1" > /dev/null 2>&1; then
		COMMAND="bash -c $1"
	fi

	if [[ -z $COMMAND && $TITLE != "__i3-sensible-terminal__" ]]; then
		exit 0
	fi

	case "$WORKSPACE" in
		scratchpad)
			I3_MSG="scratchpad show sticky enable floating enable; focus"
			;;
		"")
			I3_MSG="focus"
			;;
		*)
			I3_MSG="focus, move container to workspace ${WORKSPACE},workspace ${WORKSPACE}"
	esac

	i3-msg "exec --no-startup-id i3-sensible-terminal --class '$TITLE' $COMMAND"

	sleep 0.5
fi

echo "MSG: $I3_MSG; $WORKSPACE"

i3-msg "[class=\"$TITLE\"] $I3_MSG"
