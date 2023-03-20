function cvb --description 'Clean Vim backup files'
	rm ~/.local/share/nvim/swap/*.* 2>/dev/null
	rm ~/.local/state/nvim/swap/*.* 2>/dev/null
end
