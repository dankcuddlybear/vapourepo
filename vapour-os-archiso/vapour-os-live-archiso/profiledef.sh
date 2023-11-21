#!/usr/bin/env bash
# shellcheck disable=SC2034
iso_name="vapour-os"
iso_label="VOS_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Dankcuddlybear <https://github.com/dankcuddlybear/vapourepo>"
iso_application="Modular Arch based distro"
iso_version="$(date +%Y.%-m.%-d)-$(expr $(date +%-S) + $(expr 60 \* $(date +%-M)) + $(expr 3600 \* $(date +%-H)))"
install_dir="vapour-os"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito'
	'uefi-ia32.grub.esp' 'uefi-ia32.grub.eltorito'
	'uefi-x64.grub.esp' 'uefi-x64.grub.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
file_permissions=(
	["/etc/sudoers.d"]="0:0:750"
	["/usr/local/sbin/cat"]="0:0:755"
	["/usr/share/polkit-1/rules.d"]="0:0:750"
)
