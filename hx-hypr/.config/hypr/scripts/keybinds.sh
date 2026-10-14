#!/usr/bin/env bash
# hx :: keybinds — lista los bindd de Hyprland en rofi (icono por tipo de acción)
set -euo pipefail

pkill -x rofi && exit 0

# modmask -> "SUPER SHIFT ..." ; icono según dispatcher / comando
hyprctl binds -j | jq -r '
    def mods:
        [ (if (. / 64 | floor) % 2 == 1 then "SUPER" else empty end),
          (if (. / 4  | floor) % 2 == 1 then "CTRL"  else empty end),
          (if (. / 8  | floor) % 2 == 1 then "ALT"   else empty end),
          (if  . % 2 == 1               then "SHIFT" else empty end) ] | join(" ");
    def icon:
        if   .dispatcher | test("workspace") then "󱂬"
        elif .dispatcher | test("^(movefocus|movewindow|swapwindow|resizeactive|resizewindow)$") then "󰆾"
        elif .dispatcher == "killactive" then "󰅖"
        elif .dispatcher | test("^(fullscreen|togglefloating|pseudo|layoutmsg)$") then "󰊓"
        elif .dispatcher | test("group|cyclenext|bringactivetotop") then "󰓩"
        elif .dispatcher == "exit" then "󰍃"
        elif .arg | test("screenshot") then "󰄀"
        elif .arg | test("volume") then "󰕾"
        elif .arg | test("media") then "󰝚"
        elif .arg | test("hyprlock|powermenu|suspend") then "󰌾"
        else "" end;
    .[] | select(.has_description)
        | "\(icon)  \((.modmask | mods) as $m | if $m == "" then .key else "\($m) + \(.key)" end)\t\(.description)"
' | column -t -s $'\t' |
    rofi -dmenu -i -p "keys" -mesg "hx::keybinds" -no-custom >/dev/null || true
