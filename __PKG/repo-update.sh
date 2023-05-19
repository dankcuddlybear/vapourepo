#!/bin/sh
REPO_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
REPO_NAME="vapourepo"

# Delete old files
rm $REPO_DIR/$REPO_NAME.db $REPO_DIR/$REPO_NAME.db.sig $REPO_DIR/$REPO_NAME.db.tar.gz $REPO_DIR/$REPO_NAME.db.tar.gz.sig $REPO_DIR/$REPO_NAME.files $REPO_DIR/$REPO_NAME.files.sig $REPO_DIR/$REPO_NAME.files.tar.gz $REPO_DIR/$REPO_NAME.files.tar.gz.sig

# Create repo and add packages (everything is signed)
repo-add --verify --sign $REPO_DIR/$REPO_NAME.db.tar.gz $REPO_DIR/*.pkg.tar.zst

# Delete/rename files for pacman
rm $REPO_DIR/$REPO_NAME.db $REPO_DIR/$REPO_NAME.db.sig $REPO_DIR/$REPO_NAME.files $REPO_DIR/$REPO_NAME.files.sig
mv $REPO_DIR/$REPO_NAME.db.tar.gz $REPO_DIR/$REPO_NAME.db
mv $REPO_DIR/$REPO_NAME.db.tar.gz.sig $REPO_DIR/$REPO_NAME.db.sig
mv $REPO_DIR/$REPO_NAME.files.tar.gz $REPO_DIR/$REPO_NAME.files
mv $REPO_DIR/$REPO_NAME.files.tar.gz.sig $REPO_DIR/$REPO_NAME.files.sig

read -p "Done. Press ENTER to exit"
