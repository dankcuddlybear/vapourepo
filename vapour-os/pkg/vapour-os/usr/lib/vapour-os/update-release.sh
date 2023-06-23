#!/bin/bash
DISTRO_ID="vapour-os"; DISTRO_NAME="Vapour OS"
[ -f "/$DISTRO_ID-live" ] && INSTALL_MODE="iso" || INSTALL_MODE="system"

if [ $INSTALL_MODE == "iso" ]; then # ArchISO build mode
	cp /etc/os-release /usr/lib/
	cp /usr/share/$DISTRO_ID/custom-configs/lsb-release-live /etc/lsb-release
elif [ $INSTALL_MODE == "system" ]; then ## System install mode
	cp /usr/share/$DISTRO_ID/custom-configs/os-release /usr/lib/
	[ -f /etc/lsb-release ] && cp /usr/share/$DISTRO_ID/custom-configs/lsb-release /etc/
fi

