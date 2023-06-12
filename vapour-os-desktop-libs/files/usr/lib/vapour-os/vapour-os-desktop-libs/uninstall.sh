#!/bin/sh
touch /etc/vconsole.conf
unset FONT KEYMAP
. /etc/vconsole.conf
# If font is set but isn't installed, unset it
if [ ! -z "$FONT" ] && [ -z "$(ls /usr/share/kbd/consolefonts/$FONT.*)" ]; then
	[ ! -z "$KEYMAP" ] && echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
fi
