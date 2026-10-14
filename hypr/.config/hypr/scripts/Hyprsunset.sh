#!/usr/bin/env bash
set -euo pipefail

# Hyprsunset toggle + Waybar status helper
# Phase 1: manual toggle only (no scheduling)
# Icons:
# - Off: sol / On: luna (Nerd Font)
#
# Customize via env vars:
#   HYPRSUNSET_TEMP   default 4500 (K)

STATE_FILE="$HOME/.cache/.hyprsunset_state"
TARGET_TEMP="${HYPRSUNSET_TEMP:-4500}"

ensure_state() {
  [[ -f "$STATE_FILE" ]] || echo "off" > "$STATE_FILE"
}

# Render icons using pango markup to allow colorization
icon_off() {
  # Nerd Font: sol (weather-sunny)
  printf "󰖙"
}

icon_on() {
  # Nerd Font: luna (weather-night)
  printf "󰖔"
}

cmd_toggle() {
  ensure_state
  state="$(cat "$STATE_FILE" || echo off)"

  # Always stop any running hyprsunset first to avoid CTM manager conflicts
  if pgrep -x hyprsunset >/dev/null 2>&1; then
    pkill -x hyprsunset || true
    # give it a moment to release the CTM manager
    sleep 0.2
  fi

if [[ "$state" == "on" ]]; then
    # Turning OFF: set identity and exit
    if command -v hyprsunset >/dev/null 2>&1; then
      nohup hyprsunset -i >/dev/null 2>&1 &
      # if hyprsunset persists, stop it shortly after applying identity
      sleep 0.3 && pkill -x hyprsunset || true
    fi
    echo off > "$STATE_FILE"
    notify-send -u low "Luz nocturna desactivada" || true
  else
    # Turning ON: start hyprsunset at target temp in background
    if command -v hyprsunset >/dev/null 2>&1; then
      nohup hyprsunset -t "$TARGET_TEMP" >/dev/null 2>&1 &
    fi
    echo on > "$STATE_FILE"
    notify-send -u low "Luz nocturna activada" "${TARGET_TEMP} K" || true
  fi
}

cmd_status() {
  ensure_state
  # Prefer live process detection; fall back to state file
  if pgrep -x hyprsunset >/dev/null 2>&1; then
    onoff="on"
  else
    onoff="$(cat "$STATE_FILE" || echo off)"
  fi

  if [[ "$onoff" == "on" ]]; then
    txt="$(icon_on)"
    cls="on"
    tip="Luz nocturna: ACTIVADA (${TARGET_TEMP} K)\\nClic o Super+N: desactivar"
  else
    txt="$(icon_off)"
    cls="off"
    tip="Luz nocturna: desactivada\\nClic o Super+N: activar (pantalla más cálida)"
  fi
  printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$txt" "$cls" "$tip"
}

cmd_init() {
  ensure_state
  state="$(cat "$STATE_FILE" || echo off)"

  if [[ "$state" == "on" ]]; then
    if command -v hyprsunset >/dev/null 2>&1; then
      nohup hyprsunset -t "$TARGET_TEMP" >/dev/null 2>&1 &
    fi
  fi
}

case "${1:-}" in
  toggle) cmd_toggle ;;
  status) cmd_status ;;
  init) cmd_init ;;
  *) echo "usage: $0 [toggle|status|init]" >&2; exit 2 ;;
 esac
