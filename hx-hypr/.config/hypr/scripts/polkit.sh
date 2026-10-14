#!/usr/bin/env bash
# hx :: polkit — lanza el primer agente polkit disponible
set -uo pipefail

agents=(
    /usr/lib/x86_64-linux-gnu/libexec/polkit-kde-authentication-agent-1
    /usr/libexec/polkit-kde-authentication-agent-1
    /usr/lib/polkit-kde-authentication-agent-1
    /usr/libexec/hyprpolkitagent
    /usr/lib/hyprpolkitagent/hyprpolkitagent
    /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
    /usr/libexec/polkit-gnome-authentication-agent-1
    /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1
    /usr/libexec/polkit-mate-authentication-agent-1
)

for a in "${agents[@]}"; do
    if [[ -x "$a" && ! -d "$a" ]]; then
        exec "$a"
    fi
done

notify-send -a hx -u critical -i dialog-password "hx::polkit 󰌆" "[err] ningún agente polkit instalado"
exit 1
