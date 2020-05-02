#!/bin/bash
# Start a terminal (if there is none), and show (toggle) it as i3 scratchpad
# See <https://www.reddit.com/r/i3wm/comments/8q44zr/script_to_runs_scratchpad_if_not_running/>

TITLE="_scratchpad"

if ! pgrep -f "$TITLE"; then
	# i3-msg "exec --no-startup-id i3-sensible-terminal --class '$TITLE'"
	i3-msg "exec --no-startup-id st -c '$TITLE' -f 'Source Code Pro:size=12'"
	sleep 0.5
fi

i3-msg "[class=\"$TITLE\"] scratchpad show; sticky enable"
