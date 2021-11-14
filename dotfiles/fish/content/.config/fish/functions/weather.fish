# Defined in /tmp/fish.UFJjwh/weather.fish @ line 2
function weather --description 'Show weather in different locations'
	curl -4 "http://wttr.in/$argv"
end
