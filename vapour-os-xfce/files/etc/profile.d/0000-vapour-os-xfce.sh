#!/bin/sh
DISTRO_ID="vapour-os"
SCRIPT_USER="$(whoami)"
if [ ! -f "/home/$SCRIPT_USER/.config/xfce4/vapour-os-xfce" ]; then
	cp -r "/usr/share/$DISTRO_ID/custom-configs/$DISTRO_ID-xfce/.config" "/home/$SCRIPT_USER/" &> /dev/null
else cp -nr "/usr/share/$DISTRO_ID/custom-configs/$DISTRO_ID-xfce/.config" "/home/$SCRIPT_USER/" &> /dev/null; fi
