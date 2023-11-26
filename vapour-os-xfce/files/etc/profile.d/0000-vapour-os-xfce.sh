#!/bin/sh
DISTRO_ID="vapour-os"
cp -nr /usr/share/$DISTRO_ID/custom-configs/$DISTRO_ID-xfce/.config /home/$(whoami)/
