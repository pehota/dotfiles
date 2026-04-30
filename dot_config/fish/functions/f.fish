# Defined in /tmp/fish.LVt4vg/f.fish @ line 2
function f
	fzf --preview "test -f {} && bat --color=always --style=numbers {}" | xargs -ro $argv
end
