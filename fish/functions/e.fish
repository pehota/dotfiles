# Defined in /tmp/fish.sRfrbZ/e.fish @ line 2
function e
 fzf --preview "bat --color=always --style=numbers {}" | xargs -ro nvim
end
