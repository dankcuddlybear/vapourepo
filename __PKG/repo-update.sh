#!/bin/sh
REPO_NAME="vapour-os-repo"
rm $REPO_NAME.db $REPO_NAME.db.tar.gz $REPO_NAME.files $REPO_NAME.files.tar.gz
repo-add vapour-os-repo.db.tar.gz *.pkg.tar.zst
rm $REPO_NAME.db $REPO_NAME.files
mv $REPO_NAME.db.tar.gz $REPO_NAME.db
mv $REPO_NAME.files.tar.gz $REPO_NAME.files