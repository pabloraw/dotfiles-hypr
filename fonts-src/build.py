#!/usr/bin/env python3
"""Genera la fuente de iconos propios para Waybar (logos que no existen en Nerd Fonts).

Cada SVG de svg/ (viewBox 0 0 24 24, relleno) se convierte en un glifo en el
plano de uso privado U+100000+, que no choca con Nerd Fonts.

Uso:  python3 build.py
Salida: ../fonts/.local/share/fonts/WaybarIcons.otf  (paquete stow `fonts`)

Para añadir un icono: deja el SVG en svg/ y añádelo a ICONS con el siguiente código.
Los iconos de trazo (Lucide) hay que pasarlos antes a relleno con Inkscape:
  inkscape "$PWD/svg/x-stroke.svg" --actions="select-all;object-stroke-to-path;select-all;path-union" \
           --export-plain-svg --export-filename="$PWD/svg/x.svg"
"""
import xml.etree.ElementTree as ET
from pathlib import Path

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.t2CharStringPen import T2CharStringPen
from fontTools.pens.transformPen import TransformPen
from fontTools.svgLib.path import parse_path

HERE = Path(__file__).resolve().parent
OUT = HERE.parent / "fonts/.local/share/fonts/WaybarIcons.otf"

# nombre -> código (el icono se escribe en Waybar como "\U00100001" o pegando el carácter)
ICONS = {
    "claude": 0x100001,
    "todoist": 0x100002,
    "notion": 0x100003,
    "supabase": 0x100004,
    "vercel": 0x100005,
    "crisopa": 0x100006,
}

UPM = 1000
ASCENT, DESCENT = 800, -200
SIZE = 24.0
# Celda cuadrada de 1000 unidades; el dibujo ocupa el 85 % y va centrado,
# para igualar el tamaño visual de los iconos de Nerd Fonts
FILL = 0.85
SCALE = UPM / SIZE * FILL
ADVANCE = UPM
INSET = UPM * (1 - FILL) / 2
TOP = ASCENT - INSET


def glyph_from_svg(path: Path):
    root = ET.parse(path).getroot()
    ds = [el.get("d") for el in root.iter() if el.tag.endswith("path") and el.get("d")]
    pen = T2CharStringPen(ADVANCE, None)
    # SVG: Y hacia abajo, origen arriba. Fuente: Y hacia arriba, base en 0.
    tpen = TransformPen(pen, (SCALE, 0, 0, -SCALE, INSET, TOP))
    for d in ds:
        parse_path(d, tpen)
    return pen.getCharString()


def main():
    names = [".notdef"] + list(ICONS)
    fb = FontBuilder(UPM, isTTF=False)
    fb.setupGlyphOrder(names)
    fb.setupCharacterMap({cp: name for name, cp in ICONS.items()})

    empty = T2CharStringPen(ADVANCE, None)
    charstrings = {".notdef": empty.getCharString()}
    for name in ICONS:
        charstrings[name] = glyph_from_svg(HERE / "svg" / f"{name}.svg")

    fb.setupCFF("WaybarIcons", {"FullName": "Waybar Icons"}, charstrings, {})
    fb.setupHorizontalMetrics({n: (ADVANCE, 0) for n in names})
    fb.setupHorizontalHeader(ascent=ASCENT, descent=DESCENT)
    fb.setupNameTable({"familyName": "Waybar Icons", "styleName": "Regular"})
    fb.setupOS2(sTypoAscender=ASCENT, sTypoDescender=DESCENT, usWinAscent=ASCENT, usWinDescent=-DESCENT)
    fb.setupPost()

    OUT.parent.mkdir(parents=True, exist_ok=True)
    fb.save(OUT)
    print(f"{OUT} ({len(ICONS)} iconos)")


if __name__ == "__main__":
    main()
