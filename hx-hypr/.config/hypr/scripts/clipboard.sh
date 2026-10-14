#!/usr/bin/env bash
# hx :: clipboard — historial de cliphist en rofi (icono según tipo)
# entrada: copia | Alt+Del (kb-custom-1): borra entrada | Alt+Shift+Del (kb-custom-2): vacía historial
set -uo pipefail

pkill -x rofi && exit 0

while true; do
    # cliphist list -> "ID<TAB>contenido"; se antepone icono: 󰋩 imagen, 󰅍 texto
    sel=$(cliphist list | awk -F'\t' '{
            icon = ($2 ~ /^\[\[ binary data/) ? "󰋩" : "󰅍"
            print $1 "\t" icon "  " $2
        }' |
        rofi -dmenu -i -p "clip" -mesg "hx::clipboard  󰆴 alt+del borrar  󰩺 alt+shift+del vaciar" \
            -display-columns 2 -display-column-separator $'\t' \
            -kb-custom-1 "Alt+Delete" -kb-custom-2 "Alt+Shift+Delete")
    rc=$?
    # cliphist solo necesita "ID<TAB>" para localizar la entrada
    id="${sel%%$'\t'*}"

    case $rc in
        0)  # copiar la entrada elegida
            [[ -n "$id" ]] && printf '%s\t\n' "$id" | cliphist decode | wl-copy
            exit 0 ;;
        10) # borrar y volver a mostrar
            [[ -n "$id" ]] && printf '%s\t\n' "$id" | cliphist delete
            ;;
        11) cliphist wipe
            notify-send -a hx -i edit-clear "hx::clip 󰅍" "> historial vaciado"
            exit 0 ;;
        *)  exit 0 ;;
    esac
done
