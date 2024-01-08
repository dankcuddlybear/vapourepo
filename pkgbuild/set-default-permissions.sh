#!/bin/sh
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SetPermissions() {
	chmod 755 "$1"
	for FILE in $(ls -A); do
		if [ -f "$FILE" ]; then
			chmod 644 "$(pwd)/$FILE"
		elif [ -d "$FILE" ]; then
			cd "$FILE"
			SetPermissions "$(pwd)"
			cd ../
		fi
	done
}
if [ -z "$1" ]; then echo "[ERROR] No path sepcified"; exit 1
else
	echo "Setting recursive permissions for $1"
	if [ -f "$1" ]; then chmod 644 "$1"
	elif [ -d "$1" ]; then cd "$1"; SetPermissions "$1"
	else echo "[ERROR] Path does not exist"; exit 1; fi
	chmod +x "$SCRIPT_DIR/$(basename $0)"
	echo "Finished setting recursive permissions for $1"
fi
