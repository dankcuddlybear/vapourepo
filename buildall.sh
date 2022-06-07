#!/bin/sh
[ $(whoami) == "root" ] && echo "[ERROR] You must run this script as a non-root user with sudo priviliges." && exit 1
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
shopt -s extglob
for dir in $SCRIPT_DIR/!(.git|liveusb-installer|__PKG|__PROTO)/; do
	cd $dir
	echo "Building $dir"
	makepkg -cdf
	mv *.pkg.tar.zst ../__PKG
	[ $dir == "hackbgrt-bin" ] || [ $dir == "vapour-os-bootscreen" ] && rm *.zip
	[ $dir == "intel-opencl-runtime" ] && rm *.tgz
	cd ../
done
$SCRIPT_DIR/__PKG/repo-update.sh