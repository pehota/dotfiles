set -e EDITOR; set -Ux EDITOR (command -v nvim)
set -e VISUAL; set -Ux VISUAL $EDITOR
set -e BAT_THEME; set -Ux BAT_THEME gruvbox

if status is-interactive
  # Key bindings: vim and default emacs
  fish_hybrid_key_bindings

  if test -e ~/.fishrc
    source ~/.fishrc
  end
end
