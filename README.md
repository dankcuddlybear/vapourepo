# Discontinued
Due to financial and mental health struggles, as well as bloat and old, poorly optimised code, I have decided to cease development of Vapour OS. Maybe I'll bring it back some day, or make something entirely new. I'm already working on another Arch distro, which is much closer to the vanilla Arch experience. This repository will remain up so that anyone can use my code for their projects.



Are you tired of installing and configuring Arch Linux from scratch every time? Do you just want a simple Linux experience while still enjoying the benefits of Arch Linux, like rolling release software and access to the Arch User Repository (AUR)? Then this distro is for you.

Features:
 - Pre-configured for most use cases
 - Performance/latency, power-saving and security optimisations from the Arch Wiki
 - Easy to use TUI installer
 - Fixes for HP devices

Main packages:
 - vapour-os: Core system (for servers and embedded devices). A lightweight, highly optimised Linux base package for many different use cases. Includes networking support via NetworkManager.
 - vapour-os-desktop-libs: Additional software and functionality for everyday computing. No GUI.
 - vapour-os-xfce: Desktop libs + XFCE desktop.
 - vapour-os-gnome: Desktop libs + Gnome Shell.
 - vapour-os-kde: Desktop libs + KDE Plasma desktop.

GPU drivers:
 - vapour-os-amdgpu: For AMD graphics
 - vapour-os-i915: For Intel graphics
 - vapour-os-nvidia: NVIDIA proprietary drivers
 - vapour-os-nvidia-470xx: NVIDIA proprietary drivers (version 470.xx for older cards)

Extras:
 - vapour-os-multimedia-codecs: All-in-one codec package for various multimedia formats. lib32 version also available
 - vapour-os-printer-drivers: Printer/scanner support.
 - vapour-os-gaming: Support for Windows games through Wine, as well as older Linux games. (multilib)

# System requirements
CPU: x86_64 CPU
GPU: Any Intel graphics except GMA 3600 (PowerVR)
     AMD graphics
     NVIDIA GTX 745 or newer (NVIDIA driver)
     NVIDIA GeForce 256 or newer (Nouveau driver)

RAM: 256MiB (no GUI), 512MiB (XFCE), 2GiB (KDE), 4GiB (GNOME)
Storage: 1.5GiB (core), 2.7GiB (desktop libs)
         3GiB (XFCE), 3.8GiB (GNOME), 5GiB (KDE)
         8-16GiB+ (KDE with all additional software)

# Recommended specs
CPU: 1.6GHz quad-core (or dual-core with hyperthreading)
GPU: Intel HD graphics/AMD Radeon Graphics (NVIDIA GPUs are NOT recommended)
RAM: 8GiB
Storage: 32GiB
