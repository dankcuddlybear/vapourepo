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
rm -rf "$ARCHISO_PROFILE/airootfs/usr/local/sbin"
mkdir -p "$ARCHISO_PROFILE/airootfs/usr/local/sbin"
for BIN in cat pacman-key vercmp; do
	cp /usr/bin/$BIN "$ARCHISO_PROFILE/airootfs/usr/local/sbin/"
done
sudo rm -rf "$TEMP_DIR" "$OUT_DIR" &> /dev/null; sudo mkdir "$TEMP_DIR" "$OUT_DIR"
#sudo pacman-key --refresh-keys
sudo mkarchiso -v -w "$TEMP_DIR" "$ARCHISO_PROFILE" -o "$OUT_DIR"
rm -rf "$ARCHISO_PROFILE/airootfs/usr/local/sbin"
sudo chown -R $SCRIPT_USER:$SCRIPT_USER "$OUT_DIR"
cd "$OUT_DIR"; for FILE in $(ls *.iso); do
	mv "$FILE" ../../../../vapour-os-iso/
done; cd ../
rmdir out
echo "Done."
