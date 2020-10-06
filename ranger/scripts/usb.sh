#!/usr/bin/env bash

# Utility to mount/unmount drives

# get device UUIDs with `lsblk -lno UUID,NAME,SIZE`
DRIVES=(
'DEBC8E9CBC8E6EB9'
)

# check if drive is already mounted
# returns boolean
mounted() {
    MOUNT=$(lsblk -lno UUID,MOUNTPOINT | grep "$1" | awk '{print $2}')
    [[ $MOUNT ]] && return 0 || return 1
}

# get device /dev/ name using UUID
# returns boolean
dev_name() {
    NAME=$(lsblk -lno UUID,NAME | grep "$1" | awk '{print $2}')
    [[ $NAME ]] && return 0 || return 1
}

# check if the action is valid and can be done without error
# ie. trying to mount a drive that is already mounted or unmounting a drive that isnt mouned
# returns boolean
valid() {
    if ([[ $1 == 'mount' ]] && mounted $UUID) || ([[ $1 == 'unmount' ]] && ! mounted $UUID); then
        return 1
    fi
    return 0
}

# loop over device UUIDs, perform $1 action on each device
# requires udisks
drive_loop() {
    (! hash udisksctl) && return
    local action=$1
    for UUID in "${DRIVES[@]}"; do
        dev_name $UUID && valid $action && udisksctl $action -b /dev/$NAME || continue
    done
}

# USAGE: script [-r]
# without -r option drives will be mounted
case $1 in
    -r) drive_loop unmount ;;
    *)  drive_loop mount
esac

exit 0
