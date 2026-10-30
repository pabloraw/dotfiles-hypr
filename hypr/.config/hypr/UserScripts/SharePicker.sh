#!/usr/bin/env bash
# Selector de compartir pantalla para xdg-desktop-portal-hyprland (custom_picker_binary).
# Sustituye al hyprland-share-picker (Qt) por un menú rofi con el tema del sistema.
# Protocolo: xdph pasa las ventanas en $XDPH_WINDOW_SHARING_LIST y lee de stdout
# "[SELECTION]<flags>/screen:<salida>" | "/window:<id>" | "/region:<salida>@x,y,w,h".

rofi_theme="$HOME/.config/rofi/config-share-picker.rasi"

declare -a values
menu=""

add() { # texto, icono, valor
    menu+="$1\0icon\x1f$2\n"
    values+=("$3")
}

# Pantallas
while IFS=$'\t' read -r name desc w h; do
    add "Pantalla  $name  ·  ${w}×${h}  ·  $desc" "video-display" "screen:$name"
done < <(hyprctl monitors -j | jq -r '.[] | [.name, .description, .width, .height] | @tsv')

# Región (con slurp)
command -v slurp >/dev/null && add "Región…" "edit-select" "region"

# Ventanas
if [ -n "$XDPH_WINDOW_SHARING_LIST" ]; then
    list="${XDPH_WINDOW_SHARING_LIST//\[HA>\]/$'\n'}"
    while IFS= read -r entry; do
        [ -z "$entry" ] && continue
        id="${entry%%\[HC>\]*}";   rest="${entry#*\[HC>\]}"
        class="${rest%%\[HT>\]*}"; rest="${rest#*\[HT>\]}"
        title="${rest%%\[HE>\]*}"
        add "$class  ·  $title" "${class,,}" "window:$id"
    done <<< "$list"
fi

idx=$(printf "$menu" | rofi -dmenu -i -format i -show-icons -no-custom \
    -p "Compartir" -config "$rofi_theme") || exit 1
[ -z "$idx" ] && exit 1
choice="${values[$idx]}"

if [ "$choice" = "region" ]; then
    region=$(slurp -f "%o@%x,%y,%w,%h") || exit 1
    choice="region:$region"
fi

echo "[SELECTION]/$choice"
