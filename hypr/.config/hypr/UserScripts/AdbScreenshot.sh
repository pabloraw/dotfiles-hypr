#!/usr/bin/env bash
# Captura la pantalla del móvil conectado por adb y la copia al portapapeles (PNG)

adb=$(command -v adb || echo "$HOME/Android/Sdk/platform-tools/adb")

if [[ ! -x "$adb" ]]; then
    notify-send -u critical "ADB screenshot" "adb no encontrado"
    exit 1
fi

if ! "$adb" get-state >/dev/null 2>&1; then
    notify-send -u critical "ADB screenshot" "Ningún dispositivo conectado (o hay más de uno)"
    exit 1
fi

tmp=$(mktemp --suffix=.png)
trap 'rm -f "$tmp"' EXIT

if "$adb" exec-out screencap -p >"$tmp" && [[ -s "$tmp" ]]; then
    wl-copy --type image/png <"$tmp"
    "$HOME/.config/hypr/scripts/Sounds.sh" --screenshot 2>/dev/null
    notify-send -i "$tmp" "ADB screenshot" "Copiada al portapapeles"
else
    notify-send -u critical "ADB screenshot" "Falló la captura"
    exit 1
fi
