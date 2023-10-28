#!/bin/bash
DISTRO_ID="vapour-os"
TEMP_DIR="/tmp/$DISTRO_ID-isobuild-tmp"
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ARCHISO_PROFILE="$SCRIPT_DIR/$DISTRO_ID-live-archiso"
OUT_DIR="$SCRIPT_DIR/out"
SCRIPT_USER="$(whoami)"
Error() {
	echo "[ERROR] $1" && exit 1
}
[ "$SCRIPT_USER" == "root" ] && Error "Do not run this script as root."
cp /usr/bin/cat "$ARCHISO_PROFILE/airootfs/usr/local/sbin/"
cp /usr/bin/vercmp "$ARCHISO_PROFILE/airootfs/usr/local/sbin/"
sudo rm -rf "$TEMP_DIR" "$OUT_DIR" &> /dev/null; sudo mkdir "$TEMP_DIR" "$OUT_DIR"
sudo pacman-key --refresh-keys
sudo mkarchiso -v -w "$TEMP_DIR" "$ARCHISO_PROFILE" -o "$OUT_DIR"
sudo chown -R $SCRIPT_USER:$SCRIPT_USER "$OUT_DIR"
read -p "Done. Press ENTER to exit."
