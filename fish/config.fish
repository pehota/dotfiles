set -e EDITOR; set -Ux EDITOR (command -v nvim)

if status is-interactive
  # Key bindings: vim and default emacs
  fish_hybrid_key_bindings

  if test -e ~/.fishrc
    source ~/.fishrc
  end
end
