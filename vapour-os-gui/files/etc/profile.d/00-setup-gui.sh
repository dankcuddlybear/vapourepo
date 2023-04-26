#!/bin/sh
if [ -z $XDG_CURRENT_DESKTOP ] || ([ $XDG_CURRENT_DESKTOP != "KDE" ] && [ $XDG_CURRENT_DESKTOP != "LXQt" ]); then
	export QT_QPA_PLATFORMTHEME=qt5ct
fi
if [ ! -z $XDG_SESSION_TYPE ]; then
	if [ $XDG_SESSION_TYPE == "wayland" ]; then
		export GDK_BACKEND=wayland
		export QT_QPA_PLATFORM="wayland;xcb"
		export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
		export CLUTTER_BACKEND=wayland
		export SDL_VIDEODRIVER=wayland
		export ELM_DISPLAY=wl
		export EGL_PLATFORM=wayland,x11
	fi
fi
