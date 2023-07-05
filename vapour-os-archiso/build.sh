#!/bin/bash
DISTRO_ID="vapour-os"
TEMP_DIR="/tmp/$DISTRO_ID-isobuild-tmp"
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ARCHISO_PROFILE="$SCRIPT_DIR/$DISTRO_ID-live-archiso"
SCRIPT_USER="$(whoami)"
Error() {
	echo "[ERROR] $1" && exit 1
}
[ "$SCRIPT_USER" == "root" ] && Error "Do not run this script as root."
cp /usr/bin/cat "$ARCHISO_PROFILE/airootfs/usr/local/sbin/"
cp /usr/bin/vercmp "$ARCHISO_PROFILE/airootfs/usr/local/sbin/"
sudo rm -rf "$TEMP_DIR" "$SCRIPT_DIR/out" &> /dev/null; sudo mkdir "$TEMP_DIR"
sudo mkarchiso -v -w "$TEMP_DIR" "$ARCHISO_PROFILE" &&
sudo chown -R 1000:1000 "$SCRIPT_DIR/out"
read -p "Done. Press ENTER to exit."
