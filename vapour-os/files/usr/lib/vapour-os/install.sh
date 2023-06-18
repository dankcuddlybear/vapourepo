#!/bin/bash
DISTRO_ID="vapour-os"; DISTRO_NAME="Vapour OS"
Error() {
	echo "[ERROR] $1"
	exit 1
}
[ -z "$1" ] && Error "No command (install/upgrade/uninstall)"
if [ -f "/$DISTRO_ID-live" ]; then INSTALL_MODE="iso"; else INSTALL_MODE="system"; fi
SecureBootSetup() {
	if ([ -d /sys/firmware/efi ] && [ ! -z "$(bash -c 'cd /sys/firmware/efi/efivars; shopt -s nocaseglob; ls *secureboot*')" ]) || [ $INSTALL_MODE == "iso" ]; then
		sbctl create-keys
		sbctl sign-all -g
		if [ $INSTALL_MODE == "system" ]; then
			sbctl enroll-keys -m && echo "Secure boot support is now enabled." ||
			echo "[WARNING] Failed to enroll secure boot keys"
			echo "          If you don't wish to use secure boot, you can ignore this warning. Otherwise:"
			echo "           - Enter firmware setup utility and find an option to clear all secure boot certificates."
			echo "             This will disable secure boot and put the firmware in setup mode."
			echo "           - Reboot $DISTRO_NAME and run the following command: sbctl enroll-keys -m"
			echo "             This will enroll Microsoft's keys and your own secure boot keys to the UEFI."
			echo "             Most OPROMs are signed Microsoft's keys. Without them, most expansion cards, like graphics cards, will not work with secure boot enabled."
			echo "             It is important to enroll Microsoft's keys as well."
			echo "           - Enter firmware setup utility again and enable secure boot."
		fi
	fi
}
TuneExt4() {
	tune2fs -c 1 -O ea_inode,encrypt,large_dir,verity -o acl,user_xattr $1
}
Upgrade() {
	true
}
Install() {
	/usr/share/libalpm/scripts/$DISTRO_ID/mirrors # Update Pacman mirrorlists now
	cp -r /usr/share/$DISTRO_ID/custom-configs/etc / # Copy custom configs
	echo "[ -z \"\$LOADED_BASHRC_D\" ] && (for FILE in \$(ls /etc/bashrc.d); do . \"/etc/bashrc.d/\$FILE\"; done) && LOADED_BASHRC_D=1" >> /etc/bash.bashrc
	#
	## Create custom /etc/issue greeting
	setterm -cursor on > /etc/issue
	echo -e "$(cat /usr/share/$DISTRO_ID/$DISTRO_ID.ascii)" >> /etc/issue
	echo "\\n \\r \\m" >> /etc/issue
	echo "\\d \\t" >> /etc/issue
	echo "/dev/\\l" >> /etc/issue
	echo "" >> /etc/issue
	echo "Welcome!" >> /etc/issue
	echo "" >> /etc/issue
	#
	if [ $INSTALL_MODE == "iso" ]; then # ArchISO build mode
		passwd -uq root; passwd -dq root # Unlock root account
		useradd -m live; passwd -dq live # Create passwordless user "live"
		groupadd -r autologin # Create autologin group for LightDM
		gpasswd -a live wheel 1> /dev/null; gpasswd -a live autologin 1> /dev/null # Add to groups
		rm -rf /etc/*.pacnew # We don't need these files
		rm /usr/local/sbin/cat # Remove cat needed by GRUB install script
		if [ -f /usr/share/applications/install-vapour-os.desktop ]; then # Create installer desktop shortcut
			sudo -u live mkdir -p /home/live/Desktop
			sudo -u live cp /usr/share/applications/install-vapour-os.desktop /home/live/Desktop/
			sudo -u live chmod +x /home/live/Desktop/install-vapour-os.desktop
		fi
	elif [ $INSTALL_MODE == "system" ]; then ## System install mode
		# mkinitcpio.conf
		VAPOUR_OS_NO_OVERWRITE="$(sh -c '. /etc/mkinitcpio.conf && echo $VAPOUR_OS_NO_OVERWRITE')"
		if [ -z "$VAPOUR_OS_NO_OVERWRITE" ] || [ "$VAPOUR_OS_NO_OVERWRITE" != 1 ]; then
			cp /usr/share/$DISTRO_ID/custom-configs/mkinitcpio.conf /etc/mkinitcpio.conf
		fi
		#
		# Set up disks
		. /usr/lib/$DISTRO_ID/diskinfo
		if [ "$ROOT_FSTYPE" == "ext4" ]; then
			TuneExt4 "$ROOT_DEV"
			debugfs -w -R "set_super_value mount_opts auto_da_alloc,i_version,journal_checksum,lazytime" "$ROOT_DEV"
			fscrypt setup
		elif [ "$ROOT_FSTYPE" == "f2fs" ]; then
			fsck.f2fs -O encrypt "$ROOT_DEV"
			fscrypt setup
		fi
		if [ ! -z "$HOME_DEV" ]; then
			if [ "$HOME_FSTYPE" == "ext4" ]; then
				TuneExt4 "$HOME_DEV"
				debugfs -w -R "set_super_value mount_opts auto_da_alloc,i_version,journal_checksum,lazytime,nodev,nosuid" "$HOME_DEV"
				fscrypt setup /home
			elif [ "$HOME_FSTYPE" == "f2fs" ]; then
				fsck.f2fs -O encrypt "$HOME_DEV"
				fscrypt setup /home
			fi
		fi
		if [ ! -z "$MEDIA_DEV" ]; then
			if [ "$MEDIA_FSTYPE" == "ext4" ]; then
				TuneExt4 "$MEDIA_DEV"
				debugfs -w -R "set_super_value mount_opts auto_da_alloc,i_version,journal_checksum,noatime,nodev,nosuid" "$MEDIA_DEV"
				fscrypt setup /media
			elif [ "$MEDIA_FSTYPE" == "f2fs" ]; then
				fsck.f2fs -O encrypt "$MEDIA_DEV"
				fscrypt setup /media
			fi
		fi
		if [ ! -z "$PUBLIC_DEV" ]; then
			if [ "$PUBLIC_FSTYPE" == "ext4" ]; then
				TuneExt4 "$PUBLIC_DEV"
				debugfs -w -R "set_super_value mount_opts auto_da_alloc,i_version,journal_checksum,noatime,nodev,nosuid" "$PUBLIC_DEV"
				fscrypt setup /public
			elif [ "$PUBLIC_FSTYPE" == "f2fs" ]; then
				fsck.f2fs -O encrypt "$PUBLIC_DEV"
				fscrypt setup /public
			fi
		fi
		passwd -l root # Lock root account (su/sudo still usable)
		cp /usr/share/$DISTRO_ID/custom-configs/locale.gen /etc/locale.gen
	fi
	locale-gen
	pacman-key --init; pacman-key --populate
	systemctl mask systemd-resolved
	systemctl --now enable ananicy-cpp irqbalance rtirq rtirq-resume fstrim.timer rtirq systemd-oomd NetworkManager avahi-daemon.socket
	SecureBootSetup
	Upgrade # Finish installation
}
Uninstall() {
	# Restore default configs
	cp /usr/share/factory/etc/issue /etc/issue
	cp -r /usr/share/$DISTRO_ID/arch-configs/usr/* /usr
	[ -f /etc/lsb-release ] && cp usr/share/$DISTRO_ID/arch-configs/lsb-release /etc/lsb-release
	passwd -u root; passwd -d root # Unlock root account
	
	echo "$DISTRO_NAME has now been uninstalled. Please read the following info:"
	echo "[INFO] The following units may be still enabled: avahi-daemon.socket fstrim.timer NetworkManager systemd-oomd"
	echo "    To disable, run \"sudo systemctl disable <units>\""
	echo "[WARNING] The root account has now been unlocked. This is a huge security risk,"
	echo "    and was done only to prevent administrators from getting locked out."
	echo "    When you are sure everything works properly, re-lock root with \"sudo passwd -l root\""
	echo "    or set a password with \"sudo passwd root\"."
}

case $1 in
	install) Install;;
	upgrade) Upgrade;;
	help|-h|--help) echo "Usage: $(basename $0) <command> (install/upgrade/uninstall)"; exit;;
	uninstall) Uninstall;;
	*) Error "Unrecognised command \"$1\" - valid commands are install, upgrade, uninstall)";;
esac

