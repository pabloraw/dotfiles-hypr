#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# wlogout (Power, Screen Lock, Suspend, etc)
# Fila compacta de tarjetas centrada en el monitor activo (estilo en ~/.config/wlogout/style.css)

BUTTONS=5      # botones en ~/.config/wlogout/layout
CARD=0.20      # lado de cada tarjeta, en proporción a la altura del monitor

# Check if wlogout is already running
if pgrep -x "wlogout" > /dev/null; then
    pkill -x "wlogout"
    exit 0
fi

# Tamaño lógico del monitor activo (descontando el escalado)
read -r width height < <(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | "\(.width / .scale | floor) \(.height / .scale | floor)"')

if [[ -z "$width" || -z "$height" ]]; then
    wlogout --protocol layer-shell -b "$BUTTONS" &
    exit 0
fi

card=$(awk "BEGIN {printf \"%.0f\", $height * $CARD}")
vert=$(( (height - card) / 2 ))
horiz=$(( (width - card * BUTTONS) / 2 ))
(( horiz < 0 )) && horiz=0

wlogout --protocol layer-shell -b "$BUTTONS" -T "$vert" -B "$vert" -L "$horiz" -R "$horiz" &
