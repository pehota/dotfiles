#!/bin/bash
# Start a terminal (if there is none), and show (toggle) it as i3 scratchpad
# See <https://www.reddit.com/r/i3wm/comments/8q44zr/script_to_runs_scratchpad_if_not_running/>

TERMINAL_APP="i3-sensible-terminal"
APP="${1:-$TERMINAL_APP}"
TITLE="__${APP}__"
WORKSPACE="${2:-scratchpad}"
I3_MSG="focus"

# if ! pgrep -f "$APP"; then
if test ! $(pidof -s "$APP"); then
	COMMAND=""

	if "$APP" == "$TERMINAL_APP"; then
		COMMAND=""
	elif (command -v "$APP" > /dev/null 2>&1); then
		COMMAND="bash -c $APP"
	else
		exit 0
	fi

	echo "exec --no-startup-id $TERMINAL_APP --class '$TITLE' $COMMAND"

	case "$WORKSPACE" in
		scratchpad)
			I3_MSG="scratchpad show sticky enable floating enable, focus"
			;;
		"")
			I3_MSG="focus"
			;;
		*)
			I3_MSG="focus;move container to workspace ${WORKSPACE};workspace ${WORKSPACE}"
	esac

	i3-msg "exec --no-startup-id $TERMINAL_APP --class '$TITLE' $COMMAND"

	sleep 0.5
fi

echo "MSG: $I3_MSG; $WORKSPACE; $APP"

i3-msg "[class=\"$TITLE\"] $I3_MSG"
