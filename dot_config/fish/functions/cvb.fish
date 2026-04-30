function cvb --description 'Clean Vim backup files'
	rm ~/.local/state/nvim/swap/*.* 2>/dev/null
end
