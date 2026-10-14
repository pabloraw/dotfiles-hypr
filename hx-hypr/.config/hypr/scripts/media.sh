#!/usr/bin/env bash
# hx :: media {play|next|prev|stop} — playerctl + notificación con la pista
set -uo pipefail

case "${1:-}" in
    play) playerctl play-pause ;;
    next) playerctl next ;;
    prev) playerctl previous ;;
    stop) playerctl stop ;;
    *)    echo "uso: $(basename "$0") {play|next|prev|stop}" >&2; exit 2 ;;
esac

# deja que el reproductor actualice metadatos
sleep 0.2
status=$(playerctl status 2>/dev/null || echo "Stopped")
track=$(playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null || true)

case "$status" in
    Playing) glyph="󰐊"; icon=media-playback-start ;;
    Paused)  glyph="󰏤"; icon=media-playback-pause ;;
    *)       glyph="󰓛"; icon=media-playback-stop ;;
esac

notify-send -a hx -i "$icon" -h string:x-canonical-private-synchronous:media \
    "hx::media $glyph" "> ${status,,}${track:+ :: $track}"
