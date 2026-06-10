#!/bin/sh
# Fetch location based on your IP address
CONTENT=$(curl -s http://ip-api.com/json/)

# Extract latitude and longitude
latitude=$(echo $CONTENT | jq .lat)
longitude=$(echo $CONTENT | jq .lon)

# Start the nightlight using those coordinates
wlsunset -l $latitude -L $longitude -t 4000 -T 6500

