#!/bin/sh
. /opt/vapour-os/diskinfo

# Set XDG user dirs to /media/$USER/XDG_DIR if media partition exists, otherwise reset to defaults. Desktop ALWAYS stays in /home/$USER
if [ ! -z $MEDIA_DEV ]; then
	mkdir /media/$USER &> /dev/null
	chmod 700 /media/user
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
else
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
