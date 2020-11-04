set -e EDITOR; set -Ux EDITOR (command -v nvim)
set -e VISUAL; set -Ux VISUAL (command -v nvim)
# fnm
set PATH /home/dimitara/.fnm $PATH
fnm env | source

if status is-interactive
  # Key bindings: vim and default emacs
  fish_hybrid_key_bindings

  # if test (nvm current) 
    # nvm use default > /dev/null
  # end

  if test -e ~/.fishrc
    source ~/.fishrc
  end
end
