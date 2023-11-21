#!/bin/sh
DISTRO_ID="vapour-os"
# Copy custom config files
[ ! -d "~/.config/Mousepad" ] && cp -r "/etc/skel/.config/Mousepad" "~/.config/"
[ ! -d "~/.config/Thunar" ] && cp -r "/etc/skel/.config/Thunar" "~/.config/"
if [ ! -d "~/.config/xfce4" ]; then
	cp -r "/etc/skel/.config/xfce4" "~/.config/"
else
	[ ! -f "~/.config/xfce4/$DISTRO_ID-xfce" ] && cp -r "/etc/skel/.config/xfce4" "~/.config/"
fi
