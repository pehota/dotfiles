set -e EDITOR; set -Ux EDITOR (command -v nvim)

# Avoid fisher throwing errors when updating: https://github.com/jorgebucaran/fisher/issues/528#issuecomment-467810844
if status is-interactive
  if test (nvm current) 
    nvm use default > /dev/null
  end

  if test -e ~/.fishrc
    source ~/.fishrc
  end
end
