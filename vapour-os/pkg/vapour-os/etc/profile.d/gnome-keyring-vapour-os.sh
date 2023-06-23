#!/bin/sh
if [ -n "$DESKTOP_SESSION" ] && [ -z /usr/bin/gnome-keyring-daemon ]; then
    eval $(gnome-keyring-daemon --start)
    export SSH_AUTH_SOCK
fi
