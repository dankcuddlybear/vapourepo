#!/bin/sh
REPO_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
REPO_NAME="vapourepo"
rm $REPO_DIR/$REPO_NAME.db $REPO_DIR/$REPO_NAME.db.tar.gz $REPO_DIR/$REPO_NAME.files $REPO_DIR/$REPO_NAME.files.tar.gz
repo-add $REPO_DIR/vapour-os-repo.db.tar.gz $REPO_DIR/*.pkg.tar.zst
rm $REPO_DIR/$REPO_NAME.db $REPO_DIR/$REPO_NAME.files
mv $REPO_DIR/$REPO_NAME.db.tar.gz $REPO_DIR/$REPO_NAME.db
mv $REPO_DIR/$REPO_NAME.files.tar.gz $REPO_DIR/$REPO_NAME.files