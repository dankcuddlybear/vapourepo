#!/bin/sh
export DXVK_STATE_CACHE_PATH="/home/$USER/.cache/dxvk" VKD3D_SHADER_CACHE_PATH="/home/$USER/.cache/vkd3d"
mkdir -p "$DXVK_STATE_CACHE_PATH" "$VKD3D_SHADER_CACHE_PATH" &> /dev/null
