#!/bin/bash
# Start a terminal (if there is none), and show (toggle) it as i3 scratchpad
# See <https://www.reddit.com/r/i3wm/comments/8q44zr/script_to_runs_scratchpad_if_not_running/>

TITLE="__${1:-i3-sensible-terminal}__"

if ! pgrep -f "$TITLE"; then
	COMMAND=""

	if command -v "$1" > /dev/null 2>&1; then
		COMMAND="bash -c $1"
	fi

	if [[ -z $COMMAND && $TITLE != "__i3-sensible-terminal__" ]]; then
		exit 0
	fi

	i3-msg "exec --no-startup-id i3-sensible-terminal --class '$TITLE' $COMMAND"

	sleep 0.5
fi

i3-msg "[class=\"$TITLE\"] scratchpad show sticky enable floating enable"
