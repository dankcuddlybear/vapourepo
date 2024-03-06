#!/bin/bash
DISTRO_ID="vapour-os"; DISTRO_NAME="Vapour OS"
Error() {
	echo "[ERROR] $1"
	exit 1
}
[ -z "$1" ] && Error "No command (install/upgrade/uninstall)"
if [ -f "/$DISTRO_ID-live" ]; then INSTALL_MODE="iso"; else INSTALL_MODE="system"; fi
Upgrade() {
	pacman-key --populate
	systemctl mask systemd-resolved; systemctl stop systemd-resolved &> /dev/null
	systemctl --now enable irqbalance rtirq rtirq-resume rtkit-daemon fstrim.timer systemd-oomd NetworkManager avahi-daemon.socket fwupd &> /dev/null
}
Install() {
	/usr/share/libalpm/scripts/$DISTRO_ID/mirrors # Update Pacman mirrorlists now
	cp -r /usr/share/$DISTRO_ID/custom-configs/etc / # Copy custom configs
	/usr/lib/$DISTRO_ID/kernel-config
	echo "[ -z \"\$LOADED_BASHRC_D\" ] && (for FILE in \$(ls /etc/bashrc.d); do . \"/etc/bashrc.d/\$FILE\"; done) && LOADED_BASHRC_D=1" >> /etc/bash.bashrc
	#
	## Create custom /etc/issue greeting
	setterm -cursor on > /etc/issue
	#echo -e "$(cat /usr/share/$DISTRO_ID/$DISTRO_ID.ascii)" >> /etc/issue
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
		rm /usr/local/bin/* # Remove binaries needed by install scripts
		# Add installer shortcut
		case "$(cat /$DISTRO_ID-live)" in
			kde)
				mkdir -p /home/live/Desktop; chown live:live /home/live/Desktop
				cp /usr/share/applications/install-vapour-os.desktop /home/live/Desktop/install-vapour-os.desktop
				chmod 755 /home/live/Desktop/install-vapour-os.desktop
				chown live:live /home/live/Desktop/install-vapour-os.desktop;;
			*)
				mkdir -p /etc/xdg/autostart
				cp /usr/share/applications/install-vapour-os.desktop /etc/xdg/autostart/install-vapour-os.desktop
				chmod +x /etc/xdg/autostart/install-vapour-os.desktop;;
		esac
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
	plymouth-set-default-theme vapour-os # Set boot splash
	pacman-key --init # Pacman keys
	locale-gen # Locales
	Upgrade # Finish installation
}

case $1 in
	install) Install;;
	upgrade) Upgrade;;
	help|-h|--help) echo "Usage: $(basename $0) <command> (install/upgrade)"; exit;;
	*) Error "Unrecognised command \"$1\" - valid commands are install or upgrade";;
esac

