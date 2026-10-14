#!/usr/bin/env bash
# hx :: wallpaper — aplica el fondo matrix con swww (transición grow rápida)
set -euo pipefail

img="${1:-$HOME/.config/hypr/wallpapers/hx-matrix.png}"

if [[ ! -f "$img" ]]; then
    notify-send -a hx -u critical -i image-missing "hx::wall 󰸉" "[err] no existe $img"
    exit 1
fi

# espera a que el daemon responda (al arrancar puede tardar)
for _ in {1..20}; do
    swww query >/dev/null 2>&1 && break
    sleep 0.2
done

swww img "$img" \
    --transition-type grow \
    --transition-pos center \
    --transition-duration 0.6 \
    --transition-fps 60
