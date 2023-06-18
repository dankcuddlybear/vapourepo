#!/bin/sh
touch /etc/vconsole.conf
unset FONT
. /etc/vconsole.conf
[ -z "$FONT" ] && echo "FONT=ter-116b" >> /etc/vconsole.conf
systemctl --now enable bluetooth ModemManager ipp-usb cups.socket cups-browsed
