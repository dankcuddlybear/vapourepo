#!/bin/sh
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SetPermissions() {
	echo "755: $1"
	chmod 755 "$1"
	for FILE in $(ls -A); do
		if [ -f "$FILE" ]; then
			echo "644: $(pwd)/$FILE"
			chmod 644 "$(pwd)/$FILE"
		elif [ -d "$FILE" ]; then
			cd "$FILE"
			SetPermissions "$(pwd)"
			cd ../
		fi
	done
}
if [ -z "$1" ]; then echo "[ERROR] No directory sepcified"; exit 1
else
	echo "Setting permissions for files in directory $1"
	cd "$1"
	SetPermissions "$1"
	chmod +x "$SCRIPT_DIR/$(basename $0)"
	echo "Finished setting permissions for files in directory $1"
fi
