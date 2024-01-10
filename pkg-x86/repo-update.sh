#!/bin/sh
REPO_DIR="$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"
REPO_NAME="vapourepo-x86"

# Delete old files
rm -f "$REPO_DIR"/*.db "$REPO_DIR"/*.files "$REPO_DIR"/*.sig "$REPO_DIR"/*.tar.gz

# Sign all packages
for FILE in $(ls "$REPO_DIR"/*.pkg.tar.zst); do
	gpg --use-agent --output "$FILE.sig" --detach-sig "$FILE"
done

# Create repo and add packages (everything is signed)
repo-add --verify --sign "$REPO_DIR/$REPO_NAME.db.tar.gz" "$REPO_DIR"/*.pkg.tar.zst

# Delete/rename files for pacman
rm $REPO_NAME.db $REPO_NAME.files
mv $REPO_NAME.db.tar.gz $REPO_NAME.db
mv $REPO_NAME.files.tar.gz $REPO_NAME.files
mv $REPO_NAME.db.tar.gz.sig $REPO_NAME.db.sig
mv $REPO_NAME.files.tar.gz.sig $REPO_NAME.files.sig

echo "Done."
