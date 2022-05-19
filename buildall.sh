#!/bin/sh
[ $(whoami) == "root" ] && echo "[ERROR] You must run this script as a non-root user with sudo priviliges." && exit 1
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
shopt -s extglob
for dir in $SCRIPT_DIR/!(.git|__PKG|__PROTO)/   
	cd $dir
	echo "Building $dir"
	makepkg -sr || exit 1
	mv */pkg.tar.zst ../__PKG
	rm -rf pkg src
	cd ../
done
__PKG/repo-update.sh