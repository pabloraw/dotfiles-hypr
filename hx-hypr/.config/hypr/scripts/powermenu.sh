#!/usr/bin/env bash
# hx :: powermenu — rofi dmenu con icono por entrada
set -euo pipefail

lock="󰌾  > lock"
suspend="󰤄  > suspend"
logout="󰍃  > logout"
reboot="󰜉  > reboot"
poweroff="󰐥  > poweroff"

pkill -x rofi && exit 0

choice=$(printf '%s\n' "$lock" "$suspend" "$logout" "$reboot" "$poweroff" |
    rofi -dmenu -i -p "power" -mesg "hx::session" -no-custom || true)

case "$choice" in
    "$lock")     pidof hyprlock || hyprlock ;;
    "$suspend")  systemctl suspend ;;
    "$logout")   hyprctl dispatch exit ;;
    "$reboot")   systemctl reboot ;;
    "$poweroff") systemctl poweroff ;;
    *)           exit 0 ;;
esac
