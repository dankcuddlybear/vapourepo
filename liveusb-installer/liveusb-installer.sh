#!/bin/bash
[ $(whoami) != "root" ] && echo "[ERROR] You must run this script with root priviliges." && exit 1
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/install.conf
loadkeys $KEYMAP
setfont latarcyrheb-sun32
timedatectl set-ntp true

# HARDWARE CHECKER - gathers hardware info to automatically install recommended packages
echo "Checking hardware..."
# CPU checker
lscpu | grep "GenuineIntel" &> /dev/null && CPU="intel" && echo "Found Intel CPU"
lscpu | grep "AuthenticAMD" &> /dev/null && CPU="amd" && echo "Found AMD CPU"

# Detect chassis type
CHASSIS=$(dmidecode --string chassis-type)
if [ $CHASSIS == "Portable" ] || [ $CHASSIS == "Laptop" ] || [ $CHASSIS == "Notebook" ] || [ $CHASSIS == "Hand Held" ] || [ $CHASSIS == "Sub Notebook" ]; then
    PORTABLE=1
    BATTERY=1
    echo "Computer is portable ($CHASSIS)"
    # Detect if computer has an accelerometer
    ACCELEROMETER=$(cat /sys/class/input/js0/device/name | grep -i "accelerometer")
    if [ ! -z "$ACCELEROMETER" ]; then
        ACCELEROMETER=1
        echo "Found accelerometer"
        echo "[WARNING] This may mess with some games (for example, the camera keeps moving left or right in Eduke32), because the accelerometer shows up as a regular controller. Disable controller support for affected games, or force a different input device if possible."
        WARNINGS_ISSUED=1
    fi
fi
[ ! -z $WARNINGS_ISSUED ] && echo && read -p "Press enter to continue" CONTINUE

# Show splash screen
echo "____   ____                                   ________    _________"
echo "\\   \\ /   /____  ______   ____  __ _________  \\_____  \\  /   _____/"
echo " \\   Y   /\\__  \\ \\____ \\ /  _ \\|  |  \\_  __ \\  /   |   \\ \\_____  \\"
echo "  \\     /  / __ \\|  |_> >  <_> )  |  /|  | \\/ /    |    \\/        \\"
echo "   \\___/  (____  /   __/ \\____/|____/ |__|    \\_______  /_______  /"
echo "               \\/|__|                                 \\/        \\/"
echo "     .__                 __         .__  .__"
echo "     |__| ____   _______/  |______  |  | |  |   ___________"
echo "     |  |/    \\ /  ___/\\   __\\__  \\ |  | |  | _/ __ \\_  __ \\"
echo "     |  |   |  \\\\___ \\  |  |  / __ \\|  |_|  |_\\  ___/|  | \\/"
echo "     |__|___|  /____  > |__| (____  /____/____/\\___  >__|"
echo "             \\/     \\/            \\/               \\/"
echo
echo "Welcome to the Vapour OS installer!"
echo
echo "FEATURES:"
echo " - The linux-zen kernel is optimised for low latency, and features like fsync help improve performance in games."
echo " - Pipewire audio server for low-latency audio as a replacement for Pulseaudio, ALSA and JACK. Still relatively new, expect bugs (1 known, see \"gui\" in optional software."
echo " - Ext4 partitions feature hardware accelerated metadata checksum support and fast commit. noatime for all partitions except root partition which uses lazytime."
echo " - Auto CPU frequency - slow down or speed up CPU depending on what programs are running."
echo "COMING SOON (hopefully):"
echo " - Power saver - like Android's battery saver but better. Disables compositing, sets refresh rate to 60FPS, lowers the screen brightness and forces light theme (forces dark theme on OLED displays)."
echo " - Vapour OS manager: Manage the system and software or repair the system. Toggle settings which will take effect immediately (most of them)."
echo " - Eye saver - automatically adjusts screen brightness based on ambient light conditions. Enables dark theme at sunset or if there is low ambient light. Makes colours warmer during sunset to help you sleep better. Requires location services and ambient light sensor or webcam."
echo " - Wayland support, although this will probably never happen, not for a thousand years."
echo
read -p "When you are ready, press enter to continue or CTRL+C to abort installation." CONTINUE

# Unmount any mounted filesystems
echo "Unmounting filesystems..."
umount -f "$BOOT_DEV" &> /dev/null
[ ! -z "$HOME_DEV" ] && umount -f "$HOME_DEV" &> /dev/null
[ ! -z "$MEDIA_DEV" ] && umount -f "$MEDIA_DEV" &> /dev/null
[ ! -z "$PUBLIC_DEV" ] && umount -f "$PUBLIC_DEV" &> /dev/null
umount -f "$ROOT_DEV" &> /dev/null
# Format any filesystems marked for formatting
if [ ! -z $FORMAT_ROOT ] && [ $FORMAT_ROOT == 1 ]; then
	echo "Formatting root partition..."
	mkfs.ext4 -L "$LABEL_ROOT" "$ROOT_DEV"
fi
if [ ! -z $FORMAT_BOOT ] && [ $FORMAT_BOOT == 1 ]; then
	echo "Formatting boot partition..."
	mkfs.fat -F 32 -n "$LABEL_BOOT" "$BOOT_DEV"
fi
if [ ! -z $FORMAT_HOME ] && [ $FORMAT_HOME == 1 ]; then
	echo "Formatting home partition..."
	mkfs.ext4 -L "$LABEL_HOME" "$HOME_DEV"
fi
if [ ! -z $FORMAT_MEDIA ] && [ $FORMAT_MEDIA == 1 ]; then
	echo "Formatting media partition..."
	mkfs.ext4 -L "$LABEL_MEDIA" "$MEDIA_DEV"
fi
if [ ! -z $FORMAT_PUBLIC ] && [ $FORMAT_PUBLIC == 1 ]; then
	echo "Formatting public partition..."
	mkfs.ext4 -L "$LABEL_PUBLIC" "$PUBLIC_DEV"
fi

# Set boot flag on ESP
BOOT_DEV=$(readlink -f "$BOOT_DEV")
if [ ${BOOT_DEV:5:2} == "hd" ] || [ ${BOOT_DEV:5:2} == "sd" ] || [ ${BOOT_DEV:5:2} == "vd" ]; then
	ESPDISK=${BOOT_DEV:0:8}
	ESPPART=${BOOT_DEV:8:3}
elif [ ${BOOT_DEV:5:4} == "nvme" ]; then
	ESPDISK=${BOOT_DEV:0:12}
	ESPPART=${BOOT_DEV:13:3}
elif [ ${BOOT_DEV:5:6} == "mmcblk" ]; then
	ESPDISK=${BOOT_DEV:0:12}
	ESPPART=${BOOT_DEV:13:3}
else echo "[ERROR] Error detecting EFI system partition!"; exit 1; fi
parted $ESPDISK set $ESPPART boot on 1> /dev/null

# Tune filesystems
echo "Tuning root partition..." && tune2fs -O fast_commit -c 1 "$ROOT_DEV"
[ ! -z "$HOME_DEV" ] && echo "Tuning home partition..." && tune2fs -O fast_commit -c 1 "$HOME_DEV"
[ ! -z "$MEDIA_DEV" ] && echo "Tuning media partition..." && tune2fs -O fast_commit -c 1 "$MEDIA_DEV"
[ ! -z "$PUBLIC_DEV" ] && echo "Tuning public" && tune2fs -O fast_commit -c 1 "$PUBLIC_DEV"

# Mount and clear root filesystem
echo "Mounting filesystems..."
mount "$ROOT_DEV" /mnt
[ $FORMAT_ROOT != 1 ] && echo "Clearing root filesystem" && rm -rf /mnt/bin /mnt/dev /mnt/etc /mnt/lib /mnt/lib64 /mnt/mnt /mnt/opt /mnt/proc /mnt/root /mnt/run /mnt/sbin /mnt/sys /mnt/tmp /mnt/usr /mnt/var
# Create mount points
mkdir /mnt/boot &> /dev/null
mkdir /mnt/public &> /dev/null
chmod 777 /mnt/public
chmod +t /mnt/public
[ ! -z "$HOME_DEV" ] && mkdir /mnt/home &> /dev/null
if [ ! -z "$MEDIA_DEV" ]; then
	mkdir /mnt/media &> /dev/null
	chmod 777 /mnt/media
	chmod +t /mnt/media
fi
# Mount and clear other filesystems
mount "$BOOT_DEV" /mnt/boot
[ $FORMAT_BOOT != 1 ] && echo "Clearing ESP (will keep Windows/MacOS bootloader)" && rm -rf /mnt/boot/*.img /mnt/boot/vmlinuz-linux-zen /mnt/boot/EFI/systemd /mnt/boot/loader
[ ! -z "$HOME_DEV" ] && mount "$HOME_DEV" /mnt/home
[ ! -z "$MEDIA_DEV" ] && mount "$MEDIA_DEV" /mnt/media
[ ! -z "$PUBLIC_DEV" ] && mount "$PUBLIC_DEV" /mnt/public
sync

# Bootstrap packages. If it fails for some reason, abort installation.
[ $CPU == "amd" ] && PKG_PACSTRAP_EXTRA="amd-ucode"
[ $CPU == "intel" ] && PKG_PACSTRAP_EXTRA="intel-ucode"
[ $ACCELEROMETER == 1 ] && PKG_PACSTRAP_EXTRA="$PKG_PACSTRAP_EXTRA hdapsd"
pacstrap /mnt base sudo $PKG_PACSTRAP_EXTRA || exit 1
sync

# Copy installer options and chroot-setup.sh
mkdir -p /mnt/etc/vapour-os
cp $SCRIPT_DIR/install.conf /mnt/etc/vapour-os/install.conf
cp $SCRIPT_DIR/chroot-setup.sh /mnt/etc/vapour-os/chroot-setup.sh

# Begin chroot install
sync
arch-chroot /mnt '/etc/vapour-os/chroot-cfg' || exit 1

# The system is now bootable
sync
echo "Installation complete! Please reboot into the new system to finish setting it up."
