#!/bin/bash
[ $(whoami) != "root" ] && echo "[ERROR] You must run this script with root priviliges." && exit 1 # Do not run without root priviliges
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )  # Get script directory
. $SCRIPT_DIR/options.conf # Load options
loadkeys $KEYMAP # Load keymap
(($DISPLAY_SCALE > 100)) && setfont latarcyrheb-sun32 # Load extra large font if display is HiDPI
timedatectl set-ntp true # Ensure system clock is accurate

# HARDWARE CHECKER - gathers necessary hardware info and aborts installation if system requirements are not met.
echo "Checking hardware..."
# CPU checker
lscpu | grep "x86_64" &> /dev/null && CPU_ARCH="x86_64"
if [ -z $CPU_ARCH ]; then
    echo "[ERROR] Unsupported CPU architecture! Only x86_64 is supported - this installer will not work on Apple's M1 Silicon Macs, PowerPC Macs or a Raspberry Pi for example."
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
if [ $RAM -lt 134217728 ]; then
    echo "Found $(expr $RAM / 1048576)MiB RAM"
    echo "[ERROR] At least 128MiB of RAM is required for minimal installation (with no GUI)"
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
# GPU checker. If present, the Intel iGPU or AMD GPU will always be the primary GPU.
lspci | grep "VGA compatible controller: Intel Corporation" &> /dev/null && GPU0="intel"
if [ $GPU0 == "intel" ]; then
    lspci | grep "VGA compatible controller: NVIDIA Corporation" &> /dev/null && GPU1="nvidia"
    lspci | grep "VGA compatible controller: Advanced Micro Devices" &> /dev/null && GPU1="amd"
else
    lspci | grep "VGA compatible controller: Advanced Micro Devices" &> /dev/null && GPU0="amd"
    if [ $GPU0 == "amd" ]; then
        lspci | grep "VGA compatible controller: NVIDIA Corporation" &> /dev/null && GPU1="nvidia"
    else
        lspci | grep "VGA compatible controller: NVIDIA Corporation" &> /dev/null && GPU0="nvidia"
    fi
fi
[ -z $GPU0 ] && echo "[WARNING] Could not find a GPU. You may have an unsupported graphics card (this includes virtual graphics adaptors used by virtual machines)." && WARNINGS_ISSUED=1
[ $GPU0 == "intel" ] && echo "Found Intel integrated GPU, which will be the primary GPU"
[ $GPU0 == "amd" ] && echo "Found AMD GPU, which will be the primary GPU"
[ $GPU0 == "nvidia" ] && echo "Found Nvidia GPU, which will be the primary GPU"
[ $GPU1 == "amd" ] && echo "Found AMD GPU, which will be the secondary GPU"
[ $GPU1 == "nvidia" ] && echo "Found Nvidia GPU, which will be the secondary GPU"
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
        echo "[WARNING] This may mess with games that support motion controls (for example, the camera keeps moving left or right in Eduke32), because the accelerometer shows up as a regular motion controller. Disable controller support for affected games, or force a different input device if possible."
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
echo " - Data saver - like Android's data saver. Reduces network usage for background apps, and compresses all network traffic."
echo " - Eye saver - automatically adjusts screen brightness based on ambient light conditions. Enables dark theme at sunset or if there is low ambient light. Makes colours warmer during sunset to help you sleep better. Requires location services and ambient light sensor or webcam."
echo " - Wayland support, although this will probably never happen, not for a thousand years."
echo
read -p "When you are ready, press enter to continue or CTRL+C to abort installation." CONTINUE

# Unmount any mounted filesystems
echo "Unmounting filesystems..."
umount $DEV_BOOT &> /dev/null
[ ! -z $DEV_HOME ] && umount $DEV_HOME &> /dev/null
[ ! -z $DEV_MEDIA ] && umount $DEV_MEDIA &> /dev/null
[ ! -z $DEV_PUBLIC ] && umount $DEV_PUBLIC &> /dev/null
umount $DEV_ROOT &> /dev/null
# Format any filesystems marked for formatting
[ $FORMAT_ROOT == 1 ] || [ $FORMAT_BOOT == 1 ] || [ $FORMAT_HOME == 1 ] || \
[ $FORMAT_MEDIA == 1 ] || [ $FORMAT_PUBLIC == 1 ] && echo "Formatting partitions..."
[ $FORMAT_ROOT == 1 ] && mke2fs -L $LABEL_ROOT $DEV_ROOT
[ $FORMAT_BOOT == 1 ] && mkfs.fat -F 32 -n $LABEL_BOOT $DEV_BOOT
[ ! -z $DEV_HOME ] && [ $FORMAT_HOME == 1 ] && mke2fs -L $LABEL_HOME $DEV_HOME
[ ! -z $DEV_MEDIA ] && [ $FORMAT_MEDIA == 1 ] && mke2fs -L $LABEL_MEDIA $DEV_MEDIA
[ ! -z $DEV_PUBLIC ] && [ $FORMAT_PUBLIC == 1 ] && mke2fs -L $LABEL_PUBLIC $DEV_PUBLIC
# Tune filesystems
echo "Tuning filesystems..."
tune2fs -O fast_commit $DEV_ROOT
tune2fs -c 1 $DEV_ROOT  # Perform fsck every mount
[ ! -z $DEV_HOME ] && tune2fs -O fast_commit $DEV_HOME
[ ! -z $DEV_MEDIA ] && tune2fs -O fast_commit $DEV_MEDIA
[ ! -z $DEV_PUBLIC ] && tune2fs -O fast_commit $DEV_PUBLIC
# Set boot flag on ESP
DEV_BOOT=$(readlink -f $DEV_BOOT)
if [ ${DEV_BOOT:5:2} == "hd" ] || [ ${DEV_BOOT:5:2} == "sd" ] || [ ${DEV_BOOT:5:2} == "vd" ]; then
	ESPDISK=${DEV_BOOT:0:8}
	ESPPART=${DEV_BOOT:8:3}
elif [ ${DEV_BOOT:5:4} == "nvme" ]; then
	ESPDISK=${DEV_BOOT:0:12}
	ESPPART=${DEV_BOOT:13:3}
elif [ ${DEV_BOOT:5:6} == "mmcblk" ]; then
	ESPDISK=${DEV_BOOT:0:12}
	ESPPART=${DEV_BOOT:13:3}
else echo "[ERROR] Error detecting EFI system partition!"; exit 1; fi
parted $ESPDISK set $ESPPART boot on 1> /dev/null
# Mount and clear root filesystem
echo "Mounting filesystems..."
mount $DEV_ROOT /mnt || exit 1
[ $FORMAT_ROOT != 1 ] && echo "Clearing root filesystem" && rm -rf /mnt/bin /mnt/dev /mnt/etc /mnt/lib /mnt/lib64 /mnt/mnt /mnt/opt /mnt/proc /mnt/root /mnt/run /mnt/sbin /mnt/sys /mnt/tmp /mnt/usr /mnt/var
# Create mount points
mkdir /mnt/boot &> /dev/null
mkdir /mnt/public &> /dev/null
[ ! -z $DEV_HOME ] && mkdir /mnt/home
[ ! -z $DEV_MEDIA ] && mkdir /mnt/media
# Mount and clear other filesystems
mount $DEV_BOOT /mnt/boot || exit 1
[ $FORMAT_BOOT != 1 ] && echo "Clearing ESP (will keep Windows/MacOS bootloader)" && rm -rf /mnt/boot/*.img /mnt/boot/vmlinuz-linux-zen /mnt/boot/EFI/systemd /mnt/boot/loader
[ ! -z $DEV_HOME ] && mount $DEV_HOME /mnt/home
[ ! -z $DEV_MEDIA ] && mount $DEV_MEDIA /mnt/media
[ ! -z $DEV_PUBLIC ] && mount $DEV_PUBLIC /mnt/public
sync

# Bootstrap packages. If it fails for some reason, abort installation.
PKG_PACSTRAP="autoconf automake base bison fakeroot gcc git make patch pkgconf sudo which"
[ $CPU == "amd" ] && PKG_PACSTRAP="$PKG_PACSTRAP amd-ucode"
[ $CPU == "intel" ] && PKG_PACSTRAP="$PKG_PACSTRAP intel-ucode"
[ $ACCELEROMETER == 1 ] && PKG_PACSTRAP="$PKG_PACSTRAP hdapsd"
pacstrap /mnt $PKG_PACSTRAP || exit 1
sync

# Generate /etc/fstab for new system
UUID_ROOT=$(blkid -o value -s UUID $DEV_ROOT)
UUID_BOOT=$(blkid -o value -s UUID $DEV_BOOT)
[ ! -z $DEV_HOME ] && UUID_HOME=$(blkid -o value -s UUID $DEV_HOME)
[ ! -z $DEV_MEDIA ] && UUID_MEDIA=$(blkid -o value -s UUID $DEV_MEDIA)
[ ! -z $DEV_PUBLIC ] && UUID_PUBLIC=$(blkid -o value -s UUID $DEV_PUBLIC)
echo "UUID=$UUID_ROOT / ext4 rw,lazytime 0 1" > /mnt/etc/fstab
echo "UUID=$UUID_BOOT /boot vfat rw,noatime,noexec,noauto,x-systemd.automount,dmask=0022,fmask=133,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro 0 2" >> /mnt/etc/fstab
[ ! -z $DEV_HOME ] && echo "UUID=$UUID_ROOT / ext4 rw,noatime,noauto,x-systemd.automount 0 1" >> /mnt/etc/fstab
[ ! -z $DEV_MEDIA ] && echo "UUID=$UUID_ROOT / ext4 rw,noatime,noauto,x-systemd.automount 0 1" >> /mnt/etc/fstab
[ ! -z $DEV_PUBLIC ] && echo "UUID=$UUID_ROOT / ext4 rw,noatime,noauto,x-systemd.automount 0 1" >> /mnt/etc/fstab

# Configure Sudo (don't ask for password for automated install)
echo "root ALL=(ALL:ALL) ALL" > /mnt/etc/sudoers
echo "%wheel ALL=(ALL:ALL) NOPASSWD:ALL" >> /mnt/etc/sudoers
echo "@includedir /etc/sudoers.d" >> /mnt/etc/sudoers
chmod 440 /mnt/etc/sudoers

# Configure pacman
echo "[options]" >> /mnt/etc/pacman.conf
echo "HoldPkg = amd-ucode intel-ucode hdapsd vapour-os" >> /mnt/etc/pacman.conf
echo "Architecture = auto" >> /mnt/etc/pacman.conf
echo "#IgnorePkg = " >> /mnt/etc/pacman.conf
echo "#IgnoreGroup = " >> /mnt/etc/pacman.conf
echo "#NoUpgrade = " >> /mnt/etc/pacman.conf
echo "#NoExtract = " >> /mnt/etc/pacman.conf
echo "Color" >> /mnt/etc/pacman.conf
echo "CheckSpace" >> /mnt/etc/pacman.conf
echo "ParallelDownloads = $(nproc)" >> /mnt/etc/pacman.conf
echo "SigLevel = Required DatabaseOptional" >> /mnt/etc/pacman.conf
echo "LocalFileSigLevel = Optional" >> /mnt/etc/pacman.conf
echo "#RemoteFileSigLevel = Required" >> /mnt/etc/pacman.conf
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
# Copy device info
echo "CPU=\"$CPU\"                      # \"intel\", \"amd\" or leave blank if you have neither" > /mnt/etc/vapour-os/device.conf
echo "SSE4_2=\"$SSE4_2\"                # Set to 1 if your CPU supports SSE4.2" >> /mnt/etc/vapour-os/device.conf
echo "RAM=$RAM"
echo "GPU0=\"$GPU0\"                    # \"intel\", \"amd\", \"nvidia\" or leave blank if you don't have a GPU" >> /mnt/etc/vapour-os/device.conf
echo "GPU1=\"$GPU1\"                    # \"amd\", \"nvidia\" or leave blank if you don't have a second GPU" >> /mnt/etc/vapour-os/device.conf
echo "PORTABLE=\"$PORTABLE\"            # Set to 1 if your device is portable" >> /mnt/etc/vapour-os/device.conf
echo "BATTERY=\"$BATTERY\"              # Set to 1 if your device has a battery or UPS" >> /mnt/etc/vapour-os/device.conf
echo "ACCELEROMETER=\"$ACCELEROMETER\"  # Set to 1 if your portable device has an accelerometer" >> /mnt/etc/vapour-os/device.conf

# Finish initial system configuration in chroot
echo "#!/bin/bash" > /mnt/etc/vapour-os/chroot-cfg
echo ". /etc/vapour-os/install.conf" >> /mnt/etc/vapour-os/chroot-cfg
# Add CHaotic-AUR repo
echo "pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com || exit 1" >> /mnt/etc/vapour-os/chroot-cfg
echo "pacman-key --lsign-key FBA220DFC880C036" >> /mnt/etc/vapour-os/chroot-cfg
echo "pacman --noconfirm --asdeps -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' || exit 1" >> /mnt/etc/vapour-os/chroot-cfg
echo "echo \"[chaotic-aur]\" >> /etc/pacman.conf" >> /mnt/etc/vapour-os/chroot-cfg
echo "echo \"Include = /etc/pacman.d/chaotic-mirrorlist\" >> /etc/pacman.conf" >> /mnt/etc/vapour-os/chroot-cfg
echo "echo \"\" >> /etc/pacman.conf" >> /mnt/etc/vapour-os/chroot-cfg
# Add Vapour OS repo
echo "echo \"[vapourepo]\" >> /etc/pacman.conf" >> /mnt/etc/vapour-os/chroot-cfg
echo "echo \"SigLevel = Optional DatabaseOptional\" >> /etc/pacman.conf" >> /mnt/etc/vapour-os/chroot-cfg
echo "echo \"Server = https://raw.githubusercontent.com/dankcuddlybear/\\\$repo/main/__PKG\" >> /etc/pacman.conf" >> /mnt/etc/vapour-os/chroot-cfg
# Install Vapour OS
echo "pacman -Syu vapour-os || exit 1"
# Configure users
echo "read -p \"Do you want to enable root login? (y/N) \" ANSWER" >> /mnt/etc/vapour-os/chroot-cfg
echo "if [ \$ANSWER == \"y\" ] || [ \$ANSWER == \"Y\" ]; then" >> /mnt/etc/vapour-os/chroot-cfg
echo "    CONTINUE=0" >> /mnt/etc/vapour-os/chroot-cfg
echo "    while [ \$CONTINUE == 0 ]; do" >> /mnt/etc/vapour-os/chroot-cfg
echo "        echo \"Enter root password\"" >> /mnt/etc/vapour-os/chroot-cfg
echo "        passwd root && CONTINUE=1" >> /mnt/etc/vapour-os/chroot-cfg
echo "    done" >> /mnt/etc/vapour-os/chroot-cfg
echo "fi" >> /mnt/etc/vapour-os/chroot-cfg
echo "useradd -m $OWNER" >> /mnt/etc/vapour-os/chroot-cfg
echo "gpasswd -a $OWNER audio" >> /mnt/etc/vapour-os/chroot-cfg
echo "gpasswd -a $OWNER games" >> /mnt/etc/vapour-os/chroot-cfg
echo "gpasswd -a $OWNER input" >> /mnt/etc/vapour-os/chroot-cfg
echo "gpasswd -a $OWNER network" >> /mnt/etc/vapour-os/chroot-cfg
echo "gpasswd -a $OWNER realtime" >> /mnt/etc/vapour-os/chroot-cfg
echo "gpasswd -a $OWNER video" >> /mnt/etc/vapour-os/chroot-cfg
echo "gpasswd -a $OWNER ftp" >> /mnt/etc/vapour-os/chroot-cfg
echo "gpasswd -a $OWNER http" >> /mnt/etc/vapour-os/chroot-cfg
echo "gpasswd -a $OWNER wheel" >> /mnt/etc/vapour-os/chroot-cfg
echo "echo" >> /mnt/etc/vapour-os/chroot-cfg
echo "CONTINUE=0" >> /mnt/etc/vapour-os/chroot-cfg
echo "while [ \$CONTINUE == 0 ]; do" >> /mnt/etc/vapour-os/chroot-cfg
echo "    echo \"Enter password for user $OWNER\"" >> /mnt/etc/vapour-os/chroot-cfg
echo "    passwd $OWNER && CONTINUE=1" >> /mnt/etc/vapour-os/chroot-cfg
echo "done" >> /mnt/etc/vapour-os/chroot-cfg
# Install optional software
echo "FAIL=1" >> /mnt/etc/vapour-os/chroot-cfg
echo "while [ \$FAIL == 1 ]; do" >> /mnt/etc/vapour-os/chroot-cfg
echo "    sudo -u $OWNER yay --needed -Syu $EXTRA_SOFTWARE && FAIL=0 || FAIL=1" >> /mnt/etc/vapour-os/chroot-cfg
echo "    if [ \$FAIL == 1 ]; then" >> /mnt/etc/vapour-os/chroot-cfg
echo "        read -p \"[ERROR] Failed to install some extra software. Would you like to try again?\" ANSWER" >> /mnt/etc/vapour-os/chroot-cfg
echo "        if [ \$ANSWER == \"y\" ] || [ \$ANSWER == \"Y\" ]; then FAIL=0; fi" >> /mnt/etc/vapour-os/chroot-cfg
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
chmod 440 /mnt/etc/sudoers

# The system is now bootable
sync
echo "Installation complete! Please reboot into the new system to finish setting it up."
echo "[WARNING] Your hardware info has been saved to /mnt/etc/vapour-os/device.conf - please make sure all settings are correct."