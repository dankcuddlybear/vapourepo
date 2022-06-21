#!/bin/bash
[ $(whoami) != "root" ] && echo "[ERROR] You must run this script with root priviliges." && exit 1
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/options.conf
loadkeys $KEYMAP
setfont latarcyrheb-sun32
timedatectl set-ntp true

# HARDWARE CHECKER - gathers hardware info to automatically install recommended packages
echo "Checking hardware..."
# CPU checker
lscpu | grep "x86_64" &> /dev/null && CPU_ARCH="x86_64"
#for CPU in "x86_64" "i486" "i686" "pentium4" "aarch64" "armv7h"; do
#	lscpu | grep "$CPU" &> /dev/null && CPU_ARCH="$CPU"
#done
if [ -z $CPU_ARCH ]; then
    echo "[ERROR] Unsupported CPU architecture! (Supported: x86_64)"
    #echo "[ERROR] Unsupported CPU architecture! (Supported: x86_64 i486 i686 pentium4 aarch64 armv7h)"
    echo "For example, Vapour OS will work on the following devices:"
    echo " - Any computer with a 64-bit Intel or AMD processor (x86_64)"
    echo " - Xbox One, PS4, Steam Deck (x86_64)"
    #echo " - Any computer with a 32/64-bit Intel or AMD processor (x86/x86_64)"
    #echo " - Raspberry Pi/compute module 2/3/4 series and Raspberry Pi 400 (armv7h/aarch64)"
    echo "Vapour OS will NOT work on these devices:"
    echo " - Any computer with a 16/32-bit Intel or AMD processor (x86)"
    echo " - Raspberry Pi/compute module (armv6/armv7h/aarch64)"
    #echo " - Raspberry Pi/compute model 1 series (armv6)"
    echo " - Apple M1/M2 Silicon Macs (aarch64)"
    echo " - Apple Power/G-series Macs (PPC)"
    echo " - Nintendo Switch (aarch64)"
    exit 1
fi
lscpu | grep "GenuineIntel" &> /dev/null && CPU="intel"
lscpu | grep "AuthenticAMD" &> /dev/null && CPU="amd"
if [ $CPU == "intel" ]; then
    echo "Found Intel CPU"
elif [ $CPU == "amd" ]; then
    echo "Found AMD CPU"
else
    echo "[WARNING] Could not determine CPU manufacturer. Skipping microcode installation."
    WARNINGS_ISSUED=1
fi
lscpu | grep "sse4_2" &> /dev/null && SSE4_2=1
if [ $SSE4_2 == 1 ]; then
    echo "CPU supports SSE4.2"
else
    echo "[WARNING] Your CPU does not support SSE4.2"
    WARNINGS_ISSUED=1
fi
# RAM checker
RAM=$(($(getconf _PHYS_PAGES) * $(getconf PAGE_SIZE)))
if [ $RAM -lt 268435456 ]; then
    echo "Found $(expr $RAM / 1048576)MiB RAM"
    echo "[ERROR] At least 256MiB of RAM is required for minimal installation (with no GUI)"
    exit 1
elif [ $RAM -lt 1073741824 ]; then
    echo "Found $(expr $RAM / 1048576)MiB RAM"
    echo "[WARNING] Less than 1GiB RAM detected. This may not be enough for a graphical desktop environment. Consider using swap or installing more RAM if possible."
    WARNINGS_ISSUED=1
else
    echo "Found $(expr $RAM / 1073741824)GiB RAM"
fi
# UEFI checker
[ -d "/sys/firmware/efi/efivars" ] && UEFI=1
if [ -z $UEFI ]; then
    echo "[ERROR] UEFI not detected. Please check that your motherboard supports UEFI, and that you have booted in UEFI mode, not BIOS or UEFI-CSM (compatibility mode)."
    exit 1
fi

# Detect chassis type
CHASSIS=$(dmidecode --string chassis-type)
if [ $CHASSIS == "Portable" ] || [ $CHASSIS == "Laptop" ] || [ $CHASSIS == "Notebook" ] || [ $CHASSIS == "Hand Held" ] || [ $CHASSIS == "Sub Notebook" ]; then
    PORTABLE=1
    BATTERY=1
    echo "Computer is portable (chassis type: $CHASSIS)"
    # Detect if computer has an accelerometer
    ACCELEROMETER=$(cat /sys/class/input/js0/device/name | grep -i "accelerometer")
    if [ ! -z "$ACCELEROMETER" ]; then
        ACCELEROMETER=1
        echo "Found accelerometer"
        echo "[WARNING] This may mess with some games (for example, the camera keeps moving left or right in Eduke32), because the accelerometer shows up as a regular controller. Disable controller support for affected games, or force a different input device if possible."
        WARNINGS_ISSUED=1
    fi
else
    echo "Chassis type: $CHASSIS"
fi
[ $WARNINGS_ISSUED == 1 ] && echo && read -p "Press enter to continue" CONTINUE

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
umount -f "$BOOT_DEV"
[ ! -z "$HOME_DEV" ] && umount -f "$HOME_DEV"
[ ! -z "$MEDIA_DEV" ] && umount -f "$MEDIA_DEV"
[ ! -z "$PUBLIC_DEV" ] && umount -f "$PUBLIC_DEV"
umount -f "$ROOT_DEV"
# Format any filesystems marked for formatting
[ $FORMAT_ROOT == 1 ] || [ $FORMAT_BOOT == 1 ] || [ $FORMAT_HOME == 1 ] || \
[ $FORMAT_MEDIA == 1 ] || [ $FORMAT_PUBLIC == 1 ] && echo "Formatting partitions..."
if [ $FORMAT_ROOT == 1 ]; then mkfs.ext4 -L "$LABEL_ROOT" "$ROOT_DEV"; fi
if [ $FORMAT_BOOT == 1 ]; then mkfs.fat -F 32 -n "$LABEL_BOOT" "$BOOT_DEV"; fi
if [ ! -z "$HOME_DEV" ]; then [ $FORMAT_HOME == 1 ] && mkfs.ext4 -L "$LABEL_HOME" "$HOME_DEV"; fi
if [ ! -z "$MEDIA_DEV" ]; then [ $FORMAT_MEDIA == 1 ] && mkfs.ext4 -L "$LABEL_MEDIA" "$MEDIA_DEV"; fi
if [ ! -z "$PUBLIC_DEV" ]; then [ $FORMAT_PUBLIC == 1 ] && mkfs.ext4 -L "$LABEL_PUBLIC" "$PUBLIC_DEV"; fi
# Tune filesystems
echo "Tuning filesystems..."
tune2fs -O fast_commit "$ROOT_DEV"
tune2fs -c 1 "$ROOT_DEV"  # Perform fsck every mount
[ ! -z "$HOME_DEV" ] && tune2fs -O fast_commit "$HOME_DEV"
[ ! -z "$MEDIA_DEV" ] && tune2fs -O fast_commit "$MEDIA_DEV"
[ ! -z "$PUBLIC_DEV" ] && tune2fs -O fast_commit "$PUBLIC_DEV"
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
PKG_PACSTRAP="autoconf automake base bison fakeroot gcc git make patch pkgconf sudo which"
[ $CPU == "amd" ] && PKG_PACSTRAP_EXTRA="amd-ucode"
[ $CPU == "intel" ] && PKG_PACSTRAP_EXTRA="intel-ucode"
[ $ACCELEROMETER == 1 ] && PKG_PACSTRAP_EXTRA="$PKG_PACSTRAP_EXTRA hdapsd"
pacstrap /mnt $PKG_PACSTRAP $PKG_PACSTRAP_EXTRA || exit 1
sync

# Configure Sudo (don't ask for password for automated install)
echo "root ALL=(ALL:ALL) ALL" > /mnt/etc/sudoers
echo "%wheel ALL=(ALL:ALL) NOPASSWD:ALL" >> /mnt/etc/sudoers
echo "@includedir /etc/sudoers.d" >> /mnt/etc/sudoers
chmod 440 /mnt/etc/sudoers
echo "$OWNER ALL=(ALL:ALL) NOPASSWD:ALL" > "/mnt/etc/sudoers.d/$OWNER"
echo >> "/mnt/etc/sudoers.d/$OWNER"
chmod 440 "/mnt/etc/sudoers.d/$OWNER"

# Configure pacman
echo "[options]" > /mnt/etc/pacman.conf
echo "HoldPkg = amd-ucode intel-ucode hdapsd vapour-os" >> /mnt/etc/pacman.conf
echo "Architecture = auto" >> /mnt/etc/pacman.conf
echo "#IgnorePkg = " >> /mnt/etc/pacman.conf
echo "#IgnoreGroup = " >> /mnt/etc/pacman.conf
echo "#NoUpgrade = " >> /mnt/etc/pacman.conf
echo "Color" >> /mnt/etc/pacman.conf
echo "CheckSpace" >> /mnt/etc/pacman.conf
echo "ParallelDownloads = $(nproc)" >> /mnt/etc/pacman.conf
echo "SigLevel = Required DatabaseOptional" >> /mnt/etc/pacman.conf
echo "LocalFileSigLevel = Optional" >> /mnt/etc/pacman.conf
echo "" >> /mnt/etc/pacman.conf
echo "[core]" >> /mnt/etc/pacman.conf
echo "Include = /etc/pacman.d/mirrorlist" >> /mnt/etc/pacman.conf
echo "" >> /mnt/etc/pacman.conf
echo "[extra]" >> /mnt/etc/pacman.conf
echo "Include = /etc/pacman.d/mirrorlist" >> /mnt/etc/pacman.conf
echo "" >> /mnt/etc/pacman.conf
echo "[community]" >> /mnt/etc/pacman.conf
echo "Include = /etc/pacman.d/mirrorlist" >> /mnt/etc/pacman.conf
echo "" >> /mnt/etc/pacman.conf
echo "[multilib]" >> /mnt/etc/pacman.conf
echo "Include = /etc/pacman.d/mirrorlist" >> /mnt/etc/pacman.conf
echo "" >> /mnt/etc/pacman.conf

# Copy installer options
mkdir -p /mnt/etc/vapour-os
cp $SCRIPT_DIR/options.conf /mnt/etc/vapour-os/install.conf
# Copy device info
echo "CPU=\"$CPU\"                      # \"intel\", \"amd\" or leave blank if you have neither" > /mnt/etc/vapour-os/device.conf
echo "SSE4_2=\"$SSE4_2\"                # Set to 1 if your CPU supports SSE4.2" >> /mnt/etc/vapour-os/device.conf
echo "RAM=$RAM" >> /mnt/etc/vapour-os/device.conf
echo "PORTABLE=\"$PORTABLE\"            # Set to 1 if your device is portable" >> /mnt/etc/vapour-os/device.conf
echo "BATTERY=\"$BATTERY\"              # Set to 1 if your device has a battery or UPS" >> /mnt/etc/vapour-os/device.conf
echo "ACCELEROMETER=\"$ACCELEROMETER\"  # Set to 1 if your portable device has an accelerometer" >> /mnt/etc/vapour-os/device.conf

# Finish initial system configuration in chroot
echo "#!/bin/bash" > /mnt/etc/vapour-os/chroot-cfg
echo ". /etc/vapour-os/install.conf" >> /mnt/etc/vapour-os/chroot-cfg
# Add CHaotic-AUR repo
echo "pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com || exit 1" >> /mnt/etc/vapour-os/chroot-cfg
echo "pacman-key --lsign-key FBA220DFC880C036" >> /mnt/etc/vapour-os/chroot-cfg
echo "pacman --noconfirm --asdeps -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' || exit 1" >> /mnt/etc/vapour-os/chroot-cfg
echo "echo \"[chaotic-aur]\" >> /etc/pacman.conf" >> /mnt/etc/vapour-os/chroot-cfg
echo "echo \"Include = /etc/pacman.d/chaotic-mirrorlist\" >> /etc/pacman.conf" >> /mnt/etc/vapour-os/chroot-cfg
echo "echo \"\" >> /etc/pacman.conf" >> /mnt/etc/vapour-os/chroot-cfg
# Add Vapour OS repo
echo "echo \"[vapourepo]\" >> /etc/pacman.conf" >> /mnt/etc/vapour-os/chroot-cfg
echo "echo \"SigLevel = Optional DatabaseOptional\" >> /etc/pacman.conf" >> /mnt/etc/vapour-os/chroot-cfg
echo "echo \"Server = https://raw.githubusercontent.com/dankcuddlybear/\\\$repo/main/__PKG\" >> /etc/pacman.conf" >> /mnt/etc/vapour-os/chroot-cfg
# Install Vapour OS
if [ ! -z $GRAPHICAL ]; then # GRAPHICAL is set
	if [ $GRAPHICAL != 0 ]; then # Graphical system (any)
		# Install 64bit/multilib GUI libs
		if [ $GRAPHICAL == 2 ]; then echo "pacman --needed --noconfirm -Syu lib32-vapour-os-gui || exit 1" >> /mnt/etc/vapour-os/chroot-cfg
		else echo "pacman --needed --noconfirm -Syu vapour-os-gui || exit 1" >> /mnt/etc/vapour-os/chroot-cfg; fi
		# Detect and install GPU drivers
		echo ". /opt/vapour-os/vapour-os/gui/gpuinfo" >> /mnt/etc/vapour-os/chroot-cfg
		echo "if [ \$GPU0 == \"amd\" ] || [ \$GPU1 == \"amd\" ]; then"
		echo "    pacman --needed --noconfirm -Syu vapour-os-amdgpu || exit 1" >> /mnt/etc/vapour-os/chroot-cfg
		echo "    pacman --asdeps -D vapour-os-gui" >> /mnt/etc/vapour-os/chroot-cfg
		echo "fi" >> /mnt/etc/vapour-os/chroot-cfg
		echo "if [ \$GPU0 == \"intel\" ] || [ \$GPU1 == \"intel\" ]; then"
		echo "    pacman --needed --noconfirm -Syu vapour-os-i915 || exit 1" >> /mnt/etc/vapour-os/chroot-cfg
		echo "    pacman --asdeps -D vapour-os-gui" >> /mnt/etc/vapour-os/chroot-cfg
		echo "fi" >> /mnt/etc/vapour-os/chroot-cfg
		echo "if [ \$GPU0 == \"nvidia\" ] || [ \$GPU1 == \"nvidia\" ]; then"
		echo "    pacman --needed --noconfirm -Syu vapour-os-nvidia || exit 1" >> /mnt/etc/vapour-os/chroot-cfg
		echo "    pacman --asdeps -D vapour-os-gui" >> /mnt/etc/vapour-os/chroot-cfg
		echo "fi" >> /mnt/etc/vapour-os/chroot-cfg
	else echo "pacman --needed --noconfirm -Syu vapour-os || exit 1" >> /mnt/etc/vapour-os/chroot-cfg; fi
else echo "pacman --needed --noconfirm -Syu vapour-os || exit 1" >> /mnt/etc/vapour-os/chroot-cfg; fi
echo "pacman --asdeps -D $PKG_PACSTRAP" >> /mnt/etc/vapour-os/chroot-cfg
# Configure owner user
echo "CONTINUE=0" >> /mnt/etc/vapour-os/chroot-cfg
echo "useradd -m \$OWNER" >> /mnt/etc/vapour-os/chroot-cfg
echo "gpasswd -a \$OWNER ftp" >> /mnt/etc/vapour-os/chroot-cfg
echo "gpasswd -a \$OWNER games" >> /mnt/etc/vapour-os/chroot-cfg
echo "gpasswd -a \$OWNER http" >> /mnt/etc/vapour-os/chroot-cfg
echo "gpasswd -a \$OWNER realtime" >> /mnt/etc/vapour-os/chroot-cfg
echo "gpasswd -a \$OWNER wheel" >> /mnt/etc/vapour-os/chroot-cfg
echo "echo" >> /mnt/etc/vapour-os/chroot-cfg
echo "CONTINUE=0" >> /mnt/etc/vapour-os/chroot-cfg
echo "while [ \$CONTINUE == 0 ]; do" >> /mnt/etc/vapour-os/chroot-cfg
echo "    echo \"Enter password for user \$OWNER\"" >> /mnt/etc/vapour-os/chroot-cfg
echo "    passwd \$OWNER && CONTINUE=1" >> /mnt/etc/vapour-os/chroot-cfg
echo "done" >> /mnt/etc/vapour-os/chroot-cfg
# Install optional software
echo "FAIL=1" >> /mnt/etc/vapour-os/chroot-cfg
echo "while [ \$FAIL == 1 ]; do" >> /mnt/etc/vapour-os/chroot-cfg
echo "    sudo -u \$OWNER yay --needed -Syu \$EXTRA_SOFTWARE && FAIL=0 || FAIL=1" >> /mnt/etc/vapour-os/chroot-cfg
echo "    if [ \$FAIL == 1 ]; then" >> /mnt/etc/vapour-os/chroot-cfg
echo "        read -p \"[ERROR] Failed to install some extra software. Would you like to try again? (Y/n) \" ANSWER" >> /mnt/etc/vapour-os/chroot-cfg
echo "        if [ -z \$ANSWER ] || [ \$ANSWER != \"y\" ] && [ \$ANSWER != \"Y\" ]; then FAIL=0; fi" >> /mnt/etc/vapour-os/chroot-cfg
echo "    fi" >> /mnt/etc/vapour-os/chroot-cfg
echo "done" >> /mnt/etc/vapour-os/chroot-cfg
echo "sync" >> /mnt/etc/vapour-os/chroot-cfg
chmod +x /mnt/etc/vapour-os/chroot-cfg

# Begin chroot install
sync
arch-chroot /mnt '/etc/vapour-os/chroot-cfg' || exit 1
rm /mnt/etc/vapour-os/chroot-cfg

# Reconfigure sudo
echo "Defaults insults" > /mnt/etc/sudoers
echo "root ALL=(ALL:ALL) ALL" >> /mnt/etc/sudoers
echo "%wheel ALL=(ALL:ALL) ALL" >> /mnt/etc/sudoers
echo "@includedir /etc/sudoers.d" >> /mnt/etc/sudoers
echo >> /mnt/etc/sudoers
chmod 440 /mnt/etc/sudoers
echo "$OWNER ALL=(ALL:ALL) ALL" > "/mnt/etc/sudoers.d/$OWNER"
echo >> "/mnt/etc/sudoers.d/$OWNER"
chmod 440 "/mnt/etc/sudoers.d/$OWNER"

# The system is now bootable
sync
echo "Installation complete! Please reboot into the new system to finish setting it up."
echo "[WARNING] Your hardware info has been saved to /mnt/etc/vapour-os/device.conf - please make sure all settings are correct."
