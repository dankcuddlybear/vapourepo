#!/bin/sh
. /opt/vapour-os/diskinfo &> /dev/null # Check if media partition exists

# Set XDG user dirs for all users except guest
# If the /media partition exists, create the user directory inside it (with same permissions as home directory) if it does not exist,
# then set all XDG user dirs (except Desktop) to be inside /media/$USER.
# If there is no /media partition, set all XDG user dirs to be inside /home/$USER instead (the default).
if [ ! -z $MEDIA_DEV ] && [ $USER != "guest" ]; then
	mkdir -p /media/$USER/Downloads \
	/media/$USER/Templates \
	/media/$USER/Public \
	/media/$USER/Documents \
	/media/$USER/Music \
	/media/$USER/Pictures \
	/media/$USER/Videos &> /dev/null
	chmod 700 /media/$USER
	[ "$(/opt/vapour-os/setvar query "/home/$USER/.config/user-dirs.dirs" XDG_DOWNLOAD_DIR)" != "\"/media/$USER/Downloads\"" ] && \
	xdg-user-dirs-update --set DOWNLOAD "/media/$USER/Downloads"
	[ "$(/opt/vapour-os/setvar query "/home/$USER/.config/user-dirs.dirs" XDG_TEMPLATES_DIR)" != "\"/media/$USER/Templates\"" ] && \
	xdg-user-dirs-update --set TEMPLATES "/media/$USER/Templates"
	[ "$(/opt/vapour-os/setvar query "/home/$USER/.config/user-dirs.dirs" XDG_PUBLICSHARE_DIR)" != "\"/media/$USER/Public\"" ] && \
	xdg-user-dirs-update --set PUBLICSHARE "/media/$USER/Public"
	[ "$(/opt/vapour-os/setvar query "/home/$USER/.config/user-dirs.dirs" XDG_DOCUMENTS_DIR)" != "\"/media/$USER/Documents\"" ] && \
	xdg-user-dirs-update --set DOCUMENTS "/media/$USER/Documents"
	[ "$(/opt/vapour-os/setvar query "/home/$USER/.config/user-dirs.dirs" XDG_MUSIC_DIR)" != "\"/media/$USER/Music\"" ] && \
	xdg-user-dirs-update --set MUSIC "/media/$USER/Music"
	[ "$(/opt/vapour-os/setvar query "/home/$USER/.config/user-dirs.dirs" XDG_PICTURES_DIR)" != "\"/media/$USER/Pictures\"" ] && \
	xdg-user-dirs-update --set PICTURES "/media/$USER/Pictures"
	[ "$(/opt/vapour-os/setvar query "/home/$USER/.config/user-dirs.dirs" XDG_VIDEOS_DIR)" != "\"/media/$USER/Videos\"" ] && \
	xdg-user-dirs-update --set VIDEOS "/media/$USER/Videos"
elif [ $USER != "guest" ]; then
	[ "$(/opt/vapour-os/setvar query "/home/$USER/.config/user-dirs.dirs" XDG_DOWNLOAD_DIR)" != "\"\$HOME/Downloads\"" ] && \
	xdg-user-dirs-update --set DOWNLOAD "$HOME/Downloads"
	[ "$(/opt/vapour-os/setvar query "/home/$USER/.config/user-dirs.dirs" XDG_TEMPLATES_DIR)" != "\"\$HOME/Templates\"" ] && \
	xdg-user-dirs-update --set TEMPLATES "$HOME/Templates"
	[ "$(/opt/vapour-os/setvar query "/home/$USER/.config/user-dirs.dirs" XDG_PUBLICSHARE_DIR)" != "\"\$HOME/Public\"" ] && \
	xdg-user-dirs-update --set PUBLICSHARE "$HOME/Public"
	[ "$(/opt/vapour-os/setvar query "/home/$USER/.config/user-dirs.dirs" XDG_DOCUMENTS_DIR)" != "\"\$HOME/Documents\"" ] && \
	xdg-user-dirs-update --set DOCUMENTS "$HOME/Documents"
	[ "$(/opt/vapour-os/setvar query "/home/$USER/.config/user-dirs.dirs" XDG_MUSIC_DIR)" != "\"\$HOME/Music\"" ] && \
	xdg-user-dirs-update --set MUSIC "$HOME/Music"
	[ "$(/opt/vapour-os/setvar query "/home/$USER/.config/user-dirs.dirs" XDG_PICTURES_DIR)" != "\"\$HOME/Pictures\"" ] && \
	xdg-user-dirs-update --set PICTURES "$HOME/Pictures"
	[ "$(/opt/vapour-os/setvar query "/home/$USER/.config/user-dirs.dirs" XDG_VIDEOS_DIR)" != "\"\$HOME/Videos\"" ] && \
	xdg-user-dirs-update --set VIDEOS "$HOME/Videos"
fi

# Copy files from /etc/skel if they don't exist
for FILE in $(ls -A /etc/skel); do cp cp -nr --no-preserve=all /etc/skel/$FILE /home/$USER; done
