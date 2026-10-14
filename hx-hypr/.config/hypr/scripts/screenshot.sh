#!/usr/bin/env bash
# hx :: screenshot {now|area|window|satty}
# guarda en ~/Imágenes/capturas, copia al portapapeles y notifica con la propia captura como icono
set -euo pipefail

dir="$HOME/Imágenes/capturas"
mkdir -p "$dir"
out="$dir/hx_$(date +%Y-%m-%d_%H-%M-%S).png"
satty="$HOME/.cargo/bin/satty"

notify_ok() {
    wl-copy --type image/png <"$out"
    notify-send -a hx -i "$out" "hx::shot 󰄀" "> $1 :: $(basename "$out")"
}

fail() {
    notify-send -a hx -u low -i camera-photo "hx::shot 󰄀" "[cancelado] $1"
    exit 1
}

mode="${1:-now}"
case "$mode" in
    now)
        grim "$out" || fail "now"
        notify_ok "pantalla"
        ;;
    area)
        geom=$(slurp -d) || fail "area"
        grim -g "$geom" "$out" || fail "area"
        notify_ok "área"
        ;;
    window)
        geom=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
        [[ "$geom" == "null,null nullxnull" ]] && fail "sin ventana activa"
        grim -g "$geom" "$out" || fail "window"
        notify_ok "ventana"
        ;;
    satty)
        tmp=$(mktemp --suffix=.png)
        trap 'rm -f "$tmp"' EXIT
        geom=$(slurp -d) || fail "satty"
        grim -g "$geom" "$tmp" || fail "satty"
        # fix probado: sin --copy-command; se copia desde el shell al salir
        "$satty" -f "$tmp" \
            --output-filename "$out" \
            --save-after-copy \
            --disable-notifications \
            --early-exit || true
        [[ -f "$out" ]] || exit 0
        notify_ok "satty"
        ;;
    *)
        echo "uso: $(basename "$0") {now|area|window|satty}" >&2
        exit 2
        ;;
esac
