#!/bin/sh
DISTRO_ID="vapour-os"
SCRIPT_USER="$(whoami)"
if [ ! -f "/home/$SCRIPT_USER/.config/KDE/$DISTRO_ID-kde" ]; then
	cp -r "/usr/share/$DISTRO_ID/custom-configs/$DISTRO_ID-kde/.config" "/home/$SCRIPT_USER/" &> /dev/null
fi; if [ ! -f "/home/$SCRIPT_USER/.local/share/$DISTRO_ID-kde" ]; then
	cp -r "/usr/share/$DISTRO_ID/custom-configs/$DISTRO_ID-kde/.local" "/home/$SCRIPT_USER/" &> /dev/null
fi
