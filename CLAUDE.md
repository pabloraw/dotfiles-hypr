# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Descripción

Dotfiles para Hyprland gestionados con GNU Stow. Cada aplicación es un paquete independiente con la estructura `app/.config/app/`.

## Comandos Comunes

```bash
# Instalar todos los paquetes
stow -t ~ hypr waybar rofi kitty swaync wlogout fonts

# Instalar un paquete específico
stow -t ~ hypr

# Desinstalar paquetes
stow -t ~ -D hypr waybar rofi kitty swaync wlogout fonts

# Simular instalación (dry-run)
stow -t ~ -n hypr
```

## Arquitectura

### Sistema de Configuración Modular de Hyprland

El archivo principal `hyprland.conf` orquesta la carga de configuraciones en orden específico:

1. **Configuraciones base** (`configs/`): Keybinds, variables de entorno, reglas de ventanas
2. **Configuraciones de usuario** (`UserConfigs/`): Sobrescriben los defaults

```
hyprland.conf
├── source $configs/Keybinds.conf      # Atajos por defecto
├── source $configs/Startup_Apps.conf  # Apps de inicio (base)
├── source $UserConfigs/Startup_Apps.conf  # Apps de inicio (usuario)
└── ...
```

Para personalizar: modificar archivos en `UserConfigs/`, no en `configs/`.

### Componentes Principales

| Directorio | Descripción |
|------------|-------------|
| `hypr/.config/hypr/` | Compositor Hyprland + hyprlock + hypridle |
| `hypr/.config/hypr/scripts/` | ~55 scripts de utilidad (bash + python) |
| `hypr/.config/hypr/animations/` | 16 perfiles de animaciones predefinidos |
| `waybar/.config/waybar/` | Barra de estado con 60+ temas |
| `rofi/.config/rofi/` | Lanzador con 15+ temas RASI |
| `kitty/.config/kitty/` | Terminal con 200+ temas |

### Sistema Wallust (Colores Dinámicos)

Los esquemas de color se generan dinámicamente desde el wallpaper:
- `hypr/.config/hypr/wallust/` - colores para Hyprland
- `waybar/.config/waybar/wallust/` - colores para Waybar
- `rofi/.config/rofi/wallust/` - colores para Rofi
- `kitty/.config/kitty/wallust/` - colores para Kitty

Scripts relacionados: `WallustSwww.sh`, `ThemeChanger.sh`

### Scripts Frecuentes

```bash
# Ubicación: hypr/.config/hypr/scripts/

DarkLight.sh          # Toggle modo claro/oscuro
ThemeChanger.sh       # Cambiar tema
Volume.sh             # Control de volumen
Brightness.sh         # Control de brillo
KeyHints.sh           # Mostrar atajos de teclado
ClipManager.sh        # Gestor de portapapeles
```

### Iconos propios de Waybar (fuente `Waybar Icons`)

Logos que no existen en Nerd Fonts (Claude, Todoist, Notion, Supabase, Vercel, Crisopa) se compilan a una fuente propia:
- Fuentes SVG en `fonts-src/svg/` (relleno, viewBox 24×24; los de trazo de Lucide se pasan a relleno con Inkscape, ver `fonts-src/build.py`)
- `python3 fonts-src/build.py` genera `fonts/.local/share/fonts/WaybarIcons.otf` (paquete stow `fonts`), luego `fc-cache -f` y reiniciar waybar
- Códigos en el plano privado U+100001+; las reglas están en `ModulesWorkspaces` (`window-rewrite`, solo para Chrome)

## Notas de Desarrollo

- Los scripts usan `$HOME/.config/hypr/` como ruta base
- `initial-boot.sh` se ejecuta solo una vez (marcador en `.initial_startup_done`)
- Al añadir nuevas apps, seguir la estructura `app/.config/app/` para compatibilidad con stow
