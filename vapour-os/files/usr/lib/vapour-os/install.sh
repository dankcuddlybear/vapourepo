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
			sbctl enroll-keys -m && echo "Secure boot support is now enabled." || echo "[WARNING] Failed to enroll secure boot keys"
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
	## /etc/fstab
	[ -z "$(cat /etc/fstab | grep "/proc")" ] && echo "proc /proc proc nosuid,nodev,noexec,hidepid=2,gid=proc 0 0" >> /mnt/etc/fstab
	#
	if [ $INSTALL_MODE == "iso" ]; then # ArchISO build mode
		passwd -uq root; passwd -dq root # Unlock root account
		useradd -m live; passwd -dq live # Create passwordless user "live"
		groupadd -r autologin # Create autologin group for LightDM
		gpasswd -a live wheel 1> /dev/null; gpasswd -a live autologin 1> /dev/null # Add to groups
		rm -rf /etc/*.pacnew # We don't need these files
		rm /usr/local/sbin/cat /usr/local/sbin/vercmp # Remove binaries needed by GRUB install script
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
		# FScrypt (need to update code to read UUIDS from /etc/fstab)
		fscrypt setup --all-users --quiet
		#[ ! -z "$HOME_DEV" ] && fscrypt setup /home
		passwd -l root # Lock root account (su/sudo still usable)
		cp /usr/share/$DISTRO_ID/custom-configs/locale.gen /etc/locale.gen
	fi

	# Pacman keys
	pacman-key --init
	pacman-key --add /usr/share/pacman/keyrings/cachyos.gpg; pacman-key --lsign-key F3B607488DB35A47
	pacman-key --add /usr/share/pacman/keyrings/vapourepo.gpg; pacman-key --lsign-key 7E33F46247D1BA09
	pacman-key --populate
	pacman-key --updatedb

	locale-gen
	systemctl mask systemd-resolved
	systemctl --now enable ananicy-cpp irqbalance rtirq rtirq-resume rtkit-daemon fstrim.timer systemd-oomd NetworkManager avahi-daemon.socket
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

