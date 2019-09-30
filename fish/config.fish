set -e EDITOR; set -Ux EDITOR (command -v nvim)

if test (nvm current) = 'none'
  nvm use default > /dev/null
end

if test -e ~/.fishrc
  source ~/.fishrc
end
