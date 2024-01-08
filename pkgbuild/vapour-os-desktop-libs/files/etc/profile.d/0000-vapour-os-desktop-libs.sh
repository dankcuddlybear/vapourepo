#!/bin/sh
if [ -f "usr/bin/qt5ct" ]; then
	if [ -z "$XDG_CURRENT_DESKTOP" ]; then
	export QT_QPA_PLATFORMTHEME=qt5ct; else
		if [ "$XDG_CURRENT_DESKTOP" != "KDE" ] && \
		[ "$XDG_CURRENT_DESKTOP" != "TDE" ] && \
		[ "$XDG_CURRENT_DESKTOP" != "Razor" ] && \
		[ "$XDG_CURRENT_DESKTOP" != "DDE" ] && \
		[ "$XDG_CURRENT_DESKTOP" != "LXQt" ]; then
		export QT_QPA_PLATFORMTHEME=qt5ct; fi
	fi
fi
