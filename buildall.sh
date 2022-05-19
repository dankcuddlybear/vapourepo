#!/bin/sh
for dir in */ ; do
    cd $dir
    echo "Building $dir"
    makepkg || exit 1
    cd ../
done