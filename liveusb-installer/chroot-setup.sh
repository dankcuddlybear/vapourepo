#!/bin/bash
[ $(whoami) != "root" ] && echo "[ERROR] You must run this script with root priviliges." && exit 1
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. /etc/vapour-os/install.conf

[ -f $SCRIPT_DIR/progress ] && PROGRESS=$(cat $SCRIPT_DIR/progress); [ -z $PROGRESS ] && PROGRESS=0
SetProgress() {
	PROGRESS=$1
	echo $PROGRESS > $SCRIPT_DIR/PROGRESS
}

if [ $PROGRESS == 0 ]; then
	## Configure Sudo (don't ask for password for automated install)
	echo "root ALL=(ALL:ALL) ALL" > /etc/sudoers
	echo "%wheel ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers
	echo "@includedir /etc/sudoers.d" >> /etc/sudoers
	chmod 440 /etc/sudoers
	echo "$OWNER ALL=(ALL:ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$OWNER"
	chmod 440 "/etc/sudoers.d/$OWNER"
	
	## Configure pacman
	echo "[options]" > /etc/pacman.conf
	echo "HoldPkg = amd-ucode intel-ucode hdapsd vapour-os" >> /etc/pacman.conf
	echo "Architecture = auto" >> /etc/pacman.conf
	echo "#IgnorePkg = " >> /etc/pacman.conf
	echo "#IgnoreGroup = " >> /etc/pacman.conf
	echo "#NoUpgrade = " >> /etc/pacman.conf
	echo "Color" >> /etc/pacman.conf
	echo "CheckSpace" >> /etc/pacman.conf
	echo "ParallelDownloads = $(nproc)" >> /etc/pacman.conf
	echo "SigLevel = Required DatabaseOptional" >> /etc/pacman.conf
	echo "LocalFileSigLevel = Optional" >> /etc/pacman.conf
	echo "" >> /etc/pacman.conf
	echo "[core]" >> /etc/pacman.conf
	echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
	echo "" >> /etc/pacman.conf
	echo "[extra]" >> /etc/pacman.conf
	echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
	echo "" >> /etc/pacman.conf
	echo "[community]" >> /etc/pacman.conf
	echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
	echo "" >> /etc/pacman.conf
	echo "[multilib]" >> /etc/pacman.conf
	echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
	echo "" >> /etc/pacman.conf
	echo "[chaotic-aur]" >> /etc/pacman.conf
	echo "Include = /etc/pacman.d/chaotic-mirrorlist" >> /etc/pacman.conf
	echo "" >> /etc/pacman.conf
	echo "[vapourepo]" >> /etc/pacman.conf
	echo "SigLevel = Optional DatabaseOptional" >> /etc/pacman.conf
	echo "Server = https://raw.githubusercontent.com/dankcuddlybear/\$repo/main/__PKG" >> /etc/pacman.conf
	SetProgress 1; sync
fi

if [ $PROGRESS == 1 ]; then
	## Add Chaotic keys and mirrors
	pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com || exit 1
	pacman-key --lsign-key FBA220DFC880C036
	pacman --noconfirm --asdeps -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' || exit 1
	SetProgress 2; sync
fi

if [ $PROGRESS == 2 ]; then
## Install Vapour OS
	if [ -z $GRAPHICAL ]; then GRAPHICAL=0; elif [ $GRAPHICAL != 1 ] && [ $GRAPHICAL != 2 ]; then GRAPHICAL=0; fi
	if [ $GRAPHICAL == 2 ]; then pacman --needed --noconfirm -Syu lib32-vapour-os-gui || exit 1
	elif [ $GRAPHICAL == 1 ]; then pacman --needed --noconfirm -Syu vapour-os-gui || exit 1
	elif [ $GRAPHICAL == 0 ]; then pacman --needed --noconfirm -Syu vapour-os || exit 1
	pacman --asdeps -D base sudo
	SetProgress 3; sync
fi

if [ $PROGRESS == 3 ]; then
	## Install graphics drivers
	if [ $GRAPHICAL != 0 ]; then
		. /opt/vapour-os/vapour-os-gui/gpuinfo
		if [ $GPU0 == "amd" ] || [ $GPU1 == "amd" ]; then
			pacman --needed --noconfirm -Syu vapour-os-amdgpu || exit 1
			pacman --asdeps -D vapour-os-gui
		fi
		if [ $GPU0 == "intel" ] || [ $GPU1 == "intel" ]; then
			pacman --needed --noconfirm -Syu vapour-os-i915 || exit 1
			pacman --asdeps -D vapour-os-gui
		fi
		if [ $GPU0 == "nvidia" ] || [ $GPU1 == "nvidia" ]; then
			pacman --needed --noconfirm -Syu vapour-os-amdgpu || exit 1
			pacman --asdeps -D vapour-os-gui
		fi
	fi
	SetProgress 4; sync
fi

if [ $PROGRESS == 4 ]; then
	## Configure users
	[ -z "$OWNER" ] && OWNER="user"; useradd -m $OWNER
	CONTINUE=0; while [ $CONTINUE == 0 ]; do
		echo "Enter password for user $OWNER"
		passwd $OWNER && CONTINUE=1
	done
	gpasswd -a $OWNER ftp
	gpasswd -a $OWNER games
	gpasswd -a $OWNER http
	gpasswd -a $OWNER realtime
	gpasswd -a $OWNER wheel
	SetProgress 5; sync
fi

if [ $PROGRESS == 5 ]; then
	## Install extra software
	if [ ! -z $EXTRA_SOFTWARE ]; then
		CONTINUE=0; while [ $CONTINUE == 0 ]; do
			sudo -u $OWNER yay --needed -Syu $EXTRA_SOFTWARE && CONTINUE=1
			if [ $CONTINUE == 0 ]; then
				read -p "[ERROR] Failed to install some extra software. Would you like to try again? (Y/n) " ANSWER
				[ -z $ANSWER ] && ANSWER="y"
				ANSWER=$(echo "$ANSWER" | awk '{print tolower($0)}')
				[ $ANSWER == "n" ] && CONTINUE=1
			fi
		done
	fi
	SetProgress 6; sync
fi

if [ $PROGRESS == 6 ]; then
	# Reconfigure sudo
	echo "Defaults insults" > /etc/sudoers
	echo "root ALL=(ALL:ALL) ALL" >> /etc/sudoers
	echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
	echo "@includedir /etc/sudoers.d" >> /etc/sudoers
	echo >> /etc/sudoers
	chmod 440 /etc/sudoers
	echo "$OWNER ALL=(ALL:ALL) ALL" > "/etc/sudoers.d/$OWNER"
	echo >> "/etc/sudoers.d/$OWNER"
	chmod 440 "/etc/sudoers.d/$OWNER"
	SetProgress 100; sync
fi
