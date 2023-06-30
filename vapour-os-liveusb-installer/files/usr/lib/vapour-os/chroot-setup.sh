#!/bin/bash
DISTRO_ID="vapour-os"
DISTRO_NAME="Vapour OS"
[ $(whoami) != "root" ] && echo "[ERROR] You must run this script with root priviliges." && exit 1
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ARCH="$(uname -m)"

# Clean up packages
pacman --asdeps -D lib32-pipewire-jack pipewire-alsa pipewire-jack pipewire-pulse xdg-desktop-portal-gnome xdg-desktop-portal-kde xdg-desktop-portal-gtk wireplumber
pacman --noconfirm -Sc

# Add user
CONTINUE=0; while [ $CONTINUE == 0 ]; do
	echo "[ATTENTION] Please enter an owner's username. This user will have administrator priviliges."
	unset USER_NAME; read USER_NAME
	if [ -z "$USER_NAME" ]; then echo "[ERROR] No username provided"
	else
		useradd -m "$USER_NAME" && CONTINUE=1 || CONTINUE=0
	fi
done
passwd -d "$USER_NAME"; gpasswd -a "$USER_NAME" wheel
CONTINUE=0; while [ $CONTINUE == 0 ]; do
	echo "[ATTENTION] Please enter a password for that owner's account."
	passwd "$USER_NAME" && CONTINUE=1 || CONTINUE=0
done

# Set hostname
CONTINUE=0; while [ $CONTINUE == 0 ]; do
	echo "[ATTENTION] Please enter a hostname for this computer"
	unset HOST_NAME; read HOST_NAME
	if [ -z "$HOST_NAME" ]; then echo "[ERROR] No hostname provided"
	else
		echo "$HOST_NAME" > /etc/hostname
		echo "127.0.0.1 localhost" > /etc/hosts
		echo "::1 localhost" >> /etc/hosts
		echo "127.0.1.1 $HOST_NAME" >> /etc/hosts
		CONTINUE=1
	fi
done
sync
