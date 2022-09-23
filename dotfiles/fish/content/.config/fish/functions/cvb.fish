function cvb --description 'Clean Vim backup files'
	rm ~/.vim/backup/*.* 2>/dev/null
	rm ~/.local/share/nvim/swap/*.* 2>/dev/null
end
