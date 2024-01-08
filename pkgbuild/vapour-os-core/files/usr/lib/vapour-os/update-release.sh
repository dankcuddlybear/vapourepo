#!/bin/bash
DISTRO_ID="vapour-os"; DISTRO_NAME="Vapour OS"
if [ -f "/$DISTRO_ID-live" ]; then # ArchISO build mode
	cp /etc/os-release /usr/lib/
	cp /usr/share/$DISTRO_ID/custom-configs/lsb-release-live /etc/lsb-release
else # System install mode
	cp /usr/share/$DISTRO_ID/custom-configs/os-release /usr/lib/
	[ -f /etc/lsb-release ] && cp /usr/share/$DISTRO_ID/custom-configs/lsb-release /etc/
fi
exit 0
