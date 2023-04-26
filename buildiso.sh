#!/bin/sh
[ $(whoami) != "root" ] && echo "[ERROR] You must run this script as a root user" && exit 1
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DISTRO_ID="vapour-os"
DISTRO_NAME="Vapour OS"
TEMP_DIR="$SCRIPT_DIR/$DISTRO_ID-installer-tmp"; mkdir -p "$TEMP_DIR"
export NEW_ROOT="/mnt"
export VAPOUR_OS_INSTALL_MODE="buildiso"

MODE="image"
#MODE="usb"
#clear
#lsblk
#read -p "Please type the device you want to install (/dev/sdX, /dev/nvme0nX...) THIS WILL DESTROY ALL DATA ON THAT DEVICE." USB_DEV

# Create virtual disks
[ ! -z "$(mount | grep "/mnt/boot")" ] && umount -f "/mnt/boot"
[ ! -z "$(mount | grep "/mnt")" ] && umount -f "/mnt"
if [ $MODE == "image" ]; then
	rm -rf "$TEMP_DIR/$DISTRO_ID-liveusb.img"
	fallocate -l 9730M "$TEMP_DIR/$DISTRO_ID-liveusb.img"; sync
	parted "$TEMP_DIR/$DISTRO_ID-liveusb.img" mklabel msdos; sync
	parted "$TEMP_DIR/$DISTRO_ID-liveusb.img" mkpart primary 1MiB 513MiB; sync
	parted "$TEMP_DIR/$DISTRO_ID-liveusb.img" set 1 boot on; sync
	parted "$TEMP_DIR/$DISTRO_ID-liveusb.img" mkpart primary 513MiB 9729MiB; sync
	LOOP_DEV="$(losetup --partscan --show --find "$TEMP_DIR/$DISTRO_ID-liveusb.img")"
	mkfs.fat -F 32 -n "VOSBOOT" "${LOOP_DEV}p1"; sync
	mkfs.ext4 -FL "$DISTRO_ID-live" -O ea_inode,encrypt,fast_commit,large_dir,uninit_bg,verity "${LOOP_DEV}p2"; sync
	mount "${LOOP_DEV}p2" /mnt
	mkdir /mnt/boot
	mount "${LOOP_DEV}p1" /mnt/boot
elif [ $MODE == "usb" ]; then
	parted "$USB_DEV" mklabel msdos; sync
	parted "$USB_DEV" mkpart primary 1MiB 513MiB; sync
	parted "$USB_DEV" set 1 boot on; sync
	parted "$USB_DEV" mkpart primary 513MiB 9729MiB; sync
	lsblk
	read -p "Please type boot partition (/dev/sdXY, /dev/nvme0nXpY...)" USB_BOOT
	read -p "Please type root partition (/dev/sdXY, /dev/nvme0nXpY...)" USB_ROOT
	mkfs.fat -F 32 -n "VOSBOOT" "$USB_BOOT"; sync
	mkfs.ext4 -FL "$DISTRO_ID-live" "$USB_ROOT"; sync
	mount "$USB_ROOT" /mnt
	mkdir /mnt/boot
	mount "$USB_BOOT" /mnt
fi
sync; "$SCRIPT_DIR/$DISTRO_ID-liveusb-installer/files/usr/lib/$DISTRO_ID/$DISTRO_ID-installer"
sync; umount /mnt/boot; umount /mnt
if [ $MODE == "image" ]; then limine-deploy $LOOP_DEV; sync; losetup -d $LOOP_DEV
elif [ $MODE == "usb" ]; then limine-deploy $USB_DEV; sync; fi

#mksquashfs "$NEW_ROOT" "$NEW_ROOT.squashfs" -comp xz -b 4M -Xbcj x86 -Xdict-size 1M -not-reproducible -noappend -mem 4G
