#!/usr/bin/env bash
# hx :: adb-screenshot — captura la pantalla del móvil (adb) y la copia al portapapeles
set -euo pipefail

adb=$(command -v adb || echo "$HOME/Android/Sdk/platform-tools/adb")

err() {
    notify-send -a hx -u critical -i phone "hx::adb 󰄜" "[err] $1"
    exit 1
}

[[ -x "$adb" ]] || err "adb no encontrado"
"$adb" get-state >/dev/null 2>&1 || err "ningún dispositivo (o hay más de uno)"

# archivo fijo (no se borra al salir) para que el icono de la notificación siga existiendo al mostrarse
out="${XDG_RUNTIME_DIR:-/tmp}/hx-adb-shot.png"

if "$adb" exec-out screencap -p >"$out" && [[ -s "$out" ]]; then
    wl-copy --type image/png <"$out"
    notify-send -a hx -i "$out" "hx::adb 󰄜" "> captura del móvil copiada"
else
    err "falló la captura"
fi
