#!/bin/sh
DISTRO_ID="vapour-os"; SCRIPT_USER="$(whoami)"
if ([ ! -z "$DESKTOP_SESSION" ] && [ "$DESKTOP_SESSION" == "xfce" ]) || \
([ ! -z "$XDG_DESKTOP_SESSION" ] && [ "$XDG_DESKTOP_SESSION" == "xfce" ]); then
	export QT_QPA_PLATFORMTHEME=qt5ct
	if [ ! -f "/home/$SCRIPT_USER/.config/xfce4/vapour-os-xfce" ]; then
		cp -r "/usr/share/$DISTRO_ID/custom-configs/$DISTRO_ID-xfce/.config" "/home/$SCRIPT_USER/" &> /dev/null
	else
		cp -nr "/usr/share/$DISTRO_ID/custom-configs/$DISTRO_ID-xfce/.config" "/home/$SCRIPT_USER/" &> /dev/null
	fi
fi