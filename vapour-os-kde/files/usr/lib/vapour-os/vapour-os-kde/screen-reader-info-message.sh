#!/bin/sh
DISTRO_ID="vapour-os"
SCRIPT_USER="$(whoami)"
espeak "If you need a screen reader, press ALT, Windows, and S, at the same time." &
kdialog --title "How to enable screen reader" --msgbox "If you need a screen reader, press\nALT + META (Windows key) + S\nat the same time to enable once.\nTo enable every session, go to\nSystem Settings > Accessibility > Screen reader\nand check \"Enable screen reader\".\n\nYou will not see this message again."
rm -f "/home/$SCRIPT_USER/.config/autostart/screen-reader-info-message-$DISTRO_ID-kde.desktop"
