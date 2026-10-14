#!/usr/bin/env bash
# Cambia entre el setup nuevo (hx, fósforo verde) y el antiguo (JaKooLit) sin perder ninguno.
# Uso: ./hx-switch.sh hx | jakoolit
set -euo pipefail

repo="$(cd "$(dirname "$0")" && pwd)"
old=(hypr waybar rofi kitty)
new=(hx-hypr hx-waybar hx-rofi hx-kitty hx-swaync)
swaync_bak="$HOME/.config/swaync.jakoolit"
prev_wall="$HOME/.cache/hx-prev-wallpaper"

# Lanza un proceso colgado de Hyprland (no de esta shell)
launch() { hyprctl dispatch exec "$1" >/dev/null; }

restart_ui() {
	pkill -x waybar || true
	pkill -x swaync || true
	sleep 0.5
	hyprctl reload >/dev/null
	launch waybar
	launch swaync
}

case "${1:-}" in
hx)
	cd "$repo"
	# Recordar el wallpaper actual para restaurarlo al volver
	swww query 2>/dev/null | sed -n '1s/.*image: //p' >"$prev_wall" || true
	stow -t "$HOME" -D "${old[@]}"
	# swaync del setup antiguo no está en stow: se aparta para dejar sitio
	if [[ -d "$HOME/.config/swaync" && ! -L "$HOME/.config/swaync" ]]; then
		mv "$HOME/.config/swaync" "$swaync_bak"
	fi
	stow -t "$HOME" "${new[@]}"
	pkill -x ags || true
	restart_ui
	"$HOME/.config/hypr/scripts/wallpaper.sh" || true
	echo "hx activo"
	;;
jakoolit)
	cd "$repo"
	stow -t "$HOME" -D "${new[@]}"
	if [[ -d "$swaync_bak" && ! -e "$HOME/.config/swaync" ]]; then
		mv "$swaync_bak" "$HOME/.config/swaync"
	fi
	stow -t "$HOME" "${old[@]}"
	restart_ui
	launch ags
	[[ -s "$prev_wall" ]] && swww img "$(cat "$prev_wall")" || true
	echo "jakoolit activo"
	;;
*)
	echo "uso: $0 hx | jakoolit" >&2
	exit 1
	;;
esac
