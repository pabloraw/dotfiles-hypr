#!/usr/bin/env bash
# hx :: volume {up|down|mute|mic} — wpctl + notificación con barra
set -euo pipefail

sink="@DEFAULT_AUDIO_SINK@"
src="@DEFAULT_AUDIO_SOURCE@"
step="5%"

# [#######---] a partir de un porcentaje
bar() {
    local p=$1 n i s=""
    n=$(( (p > 100 ? 100 : p) / 10 ))
    for ((i = 0; i < 10; i++)); do
        if ((i < n)); then s+="#"; else s+="-"; fi
    done
    printf '[%s]' "$s"
}

# lee "Volume: 0.45 [MUTED]" -> porcentaje y estado
read_vol() {
    local raw
    raw=$(wpctl get-volume "$1")
    vol=$(awk '{printf "%d", $2 * 100 + 0.5}' <<<"$raw")
    muted=false
    [[ "$raw" == *MUTED* ]] && muted=true
    return 0
}

notify_vol() {
    read_vol "$sink"
    local icon glyph
    if $muted || ((vol == 0)); then
        icon=audio-volume-muted; glyph="󰝟"
    elif ((vol < 34)); then
        icon=audio-volume-low; glyph="󰕿"
    elif ((vol < 67)); then
        icon=audio-volume-medium; glyph="󰖀"
    else
        icon=audio-volume-high; glyph="󰕾"
    fi
    local body
    if $muted; then body="$(bar 0) mute"; else body="$(bar "$vol") ${vol}%"; fi
    notify-send -a hx -i "$icon" \
        -h "int:value:$($muted && echo 0 || echo "$vol")" \
        -h string:x-canonical-private-synchronous:volume \
        "hx::vol $glyph" "$body"
}

notify_mic() {
    read_vol "$src"
    if $muted; then
        notify-send -a hx -i microphone-sensitivity-muted \
            -h string:x-canonical-private-synchronous:mic "hx::mic 󰍭" "[----------] mute"
    else
        notify-send -a hx -i microphone-sensitivity-high \
            -h string:x-canonical-private-synchronous:mic "hx::mic 󰍬" "$(bar "$vol") ${vol}%"
    fi
}

case "${1:-}" in
    up)   wpctl set-mute "$sink" 0; wpctl set-volume -l 1.0 "$sink" "$step+"; notify_vol ;;
    down) wpctl set-volume "$sink" "$step-"; notify_vol ;;
    mute) wpctl set-mute "$sink" toggle; notify_vol ;;
    mic)  wpctl set-mute "$src" toggle; notify_mic ;;
    *)    echo "uso: $(basename "$0") {up|down|mute|mic}" >&2; exit 2 ;;
esac
