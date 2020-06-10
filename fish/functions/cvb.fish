# Defined in /tmp/fish.xWu3YO/cvb.fish @ line 2
function cvb --description 'Clean Vim backup files'
	rm ~/.vim/backup/*.* 2>/dev/null
end
