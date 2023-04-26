# Vapourepo
Welcome to Vapourepo! This repository contains my AUR submissions, as well as sources for Vapour OS, an Arch based Linux Distro I'm working on. You can find pre-built packages for both of these in the packages directory, which you can add to Pacman.

# About Vapour OS
Vapour OS is my own personal Arch Linux based distro. The vapour-os package provides a complete base, with all the necessary packages and utilities for common tasks (CLI only). You can connect to the internet, install extra software from AUR, edit configs with nano and perform administrative tasks with sudo.
Features:
 - Performance/latency, power-saving and security optimisations from the Arch Wiki
 - Easy to use TUI installer and system settings app
 - Fixes for HP devices

Install one or more Vapour OS metapackages to enable additional features.

# What hardware is officially supported?
CPU: Any x86_64 CPU
GPU: Intel Gen 2 and 3
     Intel Gen 5 and above
     Any AMD GPU supported by amdgpu open-source drivers
     Any Nvidia GPU supported by nvidia proprietary drivers
RAM: At least 256MiB RAM (4GiB recommended)
Storage: At least 8GiB (16GiB recommended)

# Why did I create Vapour OS?
 - As a fun and incredibly time-consuming project
 - Because I wanted to speed up the install process
 - Because I was tired of having to manage multiple machines seperately

# Current status of completion
Vapour OS is fully functional and seems to be stable so far. However, it is far from complete. Here's what I have planned next:
 - A better installer
 - A live ISO
 - Simplified localisation settings
 - Power saver - like Android's battery saver. Disables compositing (or disables certain compositor effects). Sets framerate to 60FPS. Lowers screen brightness. Enable additional hardware power-saving features (via sysctl/udev). Forces light theme (dark theme on OLED displays). Better default settings for KDE/XFCE/GNOME etc.
 - A GUI to manage Vapour OS/Linux settings
 - Auto-updater
 - Global redshift
 - Auto dark theme
 - Auto brightness
 - Virtual machine support
 - Switch to Nvidia open-source kernel modules

# Disclaimer
Vapour OS violates the KISS principle and probably a few Unix and GNU principles. But remember this is MY distro, intended for use by me and my family. I may address these issues in the future if more people start using it.
