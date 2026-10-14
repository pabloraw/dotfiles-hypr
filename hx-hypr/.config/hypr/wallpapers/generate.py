#!/usr/bin/env python3
"""Generador procedural del wallpaper HX (fósforo verde).

Uso:  python3 -I generate.py [semilla]
Salida (junto a este script):
  hx-matrix.png  1920x1080  escritorio
  hx-lock.png    1920x1080  variante oscura y difuminada para hyprlock
Determinista: misma semilla -> misma imagen (por defecto 1337).
"""

import math
import random
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

W, H = 1920, 1080
OUT = Path(__file__).resolve().parent

# Paleta HX
BRIGHT = (0x9D, 0xFF, 0xB0)
FG = (0x00, 0xFF, 0x41)
MID = (0x00, 0xA8, 0x2D)
DIM = (0x0F, 0x5C, 0x26)
BG_HL = (0x0A, 0x1F, 0x0F)

# Rejilla de glifos
CELL_W, CELL_H, FONT_PX = 18, 22, 17

KATAKANA = [chr(c) for c in range(0xFF66, 0xFF9E)]  # half-width
DIGITS = list("0123456789")
HEX = list("ABCDEF")
SYMBOLS = list(":.=*+-<>|")


# ---------- fuentes ----------

def fc_match(pattern, fmt="%{file}|%{index}"):
    try:
        out = subprocess.run(["fc-match", "-f", fmt, pattern],
                             capture_output=True, text=True, check=True).stdout
        path, _, idx = out.partition("|")
        return path, int(idx or 0)
    except (OSError, subprocess.CalledProcessError, ValueError):
        return None, 0


def load_fonts():
    mono_path, mono_idx = fc_match("JetBrainsMono Nerd Font Mono")
    bold_path, bold_idx = fc_match("JetBrainsMono Nerd Font Mono:bold")
    mono = ImageFont.truetype(mono_path, FONT_PX, index=mono_idx)
    small = ImageFont.truetype(mono_path, 15, index=mono_idx)
    bold = ImageFont.truetype(bold_path or mono_path, 15, index=bold_idx)

    # Katakana: solo si hay fuente con glifos japoneses
    kana = None
    try:
        files = subprocess.run(["fc-list", ":lang=ja", "file"],
                               capture_output=True, text=True).stdout
    except OSError:
        files = ""
    if files.strip():
        path, idx = fc_match("Noto Sans Mono CJK JP:lang=ja")
        if not path or "CJK" not in path and "Droid" not in path:
            path, idx = files.splitlines()[0].rstrip(": "), 0
        try:
            kana = ImageFont.truetype(path, FONT_PX + 2, index=idx)
        except OSError:
            kana = None
    return mono, small, bold, kana


# ---------- utilidades de color ----------

def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def trail_color(t):
    """t=0 cabeza, t=1 final de la estela."""
    stops = [(0.0, BRIGHT), (0.06, FG), (0.35, MID), (0.65, DIM), (1.0, (0, 0, 0))]
    for (t0, c0), (t1, c1) in zip(stops, stops[1:]):
        if t <= t1:
            return lerp(c0, c1, (t - t0) / (t1 - t0))
    return (0, 0, 0)


def scale(c, k):
    return tuple(max(0, min(255, int(v * k))) for v in c)


def column_weight(x):
    """Más denso en los bordes, casi vacío en el centro."""
    d = abs(x / W - 0.5) * 2  # 0 centro, 1 borde
    return 0.06 + 0.94 * d ** 1.8


# ---------- capas ----------

def pick_glyph(rng, kana):
    r = rng.random()
    if kana and r < 0.58:
        return rng.choice(KATAKANA), True
    if r < 0.82:
        return rng.choice(DIGITS), False
    if r < 0.95:
        return rng.choice(HEX), False
    return rng.choice(SYMBOLS), False


def draw_rain(rng, mono, kana):
    img = Image.new("RGB", (W, H), (0, 0, 0))
    d = ImageDraw.Draw(img)
    cols, rows = W // CELL_W, H // CELL_H + 1
    x_off = (W - cols * CELL_W) // 2

    # Polvo de fondo: glifos sueltos casi invisibles para dar textura
    for _ in range(900):
        cx, cy = rng.randrange(cols), rng.randrange(rows)
        x = x_off + cx * CELL_W
        if rng.random() > column_weight(x) * 0.9 + 0.1:
            continue
        g, is_k = pick_glyph(rng, kana)
        d.text((x, cy * CELL_H), g, font=kana if is_k else mono,
               fill=scale(BG_HL, 0.6 + rng.random() * 0.6))

    # Estelas
    for cx in range(cols):
        x = x_off + cx * CELL_W
        w = column_weight(x + CELL_W / 2)
        if rng.random() > w * 0.85:
            continue
        for _ in range(1 + (rng.random() < w * 0.45)):
            length = rng.randint(6, 30)
            head = rng.randint(-4, rows + 8)
            bright = (0.45 + rng.random() * 0.55) * (0.55 + 0.45 * w)
            lit_head = rng.random() < 0.7  # algunas sin cabeza blanca
            for i in range(length):
                row = head - i
                if row < 0 or row >= rows:
                    continue
                t = i / max(1, length - 1)
                if not lit_head:
                    t = 0.12 + t * 0.88
                col = scale(trail_color(t), bright)
                if max(col) < 6:
                    continue
                g, is_k = pick_glyph(rng, kana)
                d.text((x, row * CELL_H), g, font=kana if is_k else mono, fill=col)
    return img


def center_fade(img, strength):
    """Oscurece una elipse central suave para que el centro quede limpio."""
    mask = Image.new("L", (W // 8, H // 8))
    px = mask.load()
    mw, mh = mask.size
    for y in range(mh):
        for x in range(mw):
            dx = (x / mw - 0.5) / 0.42
            dy = (y / mh - 0.5) / 0.55
            r = math.sqrt(dx * dx + dy * dy)
            k = min(1.0, r) ** 2.2
            px[x, y] = int(255 * (1 - strength * (1 - k)))
    mask = mask.resize((W, H), Image.BICUBIC).filter(ImageFilter.GaussianBlur(20))
    return ImageChops.multiply(img, Image.merge("RGB", (mask,) * 3))


def clear_box(img, box):
    """Apaga la lluvia tras la firma (bordes suaves)."""
    mask = Image.new("L", (W, H), 255)
    ImageDraw.Draw(mask).rectangle(box, fill=18)
    mask = mask.filter(ImageFilter.GaussianBlur(28))
    return ImageChops.multiply(img, Image.merge("RGB", (mask,) * 3))


def vignette(img, strength):
    mask = Image.new("L", (W // 8, H // 8))
    px = mask.load()
    mw, mh = mask.size
    for y in range(mh):
        for x in range(mw):
            dx = (x / mw - 0.5) * 2
            dy = (y / mh - 0.5) * 2
            r = math.sqrt(dx * dx * 0.8 + dy * dy * 0.9)
            k = max(0.0, r - 0.55) / 0.85
            px[x, y] = int(255 * max(0.0, 1 - strength * min(1.0, k) ** 1.6))
    mask = mask.resize((W, H), Image.BICUBIC)
    return ImageChops.multiply(img, Image.merge("RGB", (mask,) * 3))


def scanlines(img, depth):
    """Una línea oscura cada 3 px: CRT muy suave."""
    lines = Image.new("L", (1, H), 255)
    px = lines.load()
    for y in range(0, H, 3):
        px[0, y] = int(255 * (1 - depth))
    lines = lines.resize((W, H))
    return ImageChops.multiply(img, Image.merge("RGB", (lines,) * 3))


def glow(img, radius, amount):
    blur = img.filter(ImageFilter.GaussianBlur(radius))
    blur = Image.eval(blur, lambda v: int(v * amount))
    return ImageChops.add(img, blur)


def draw_signature(img, small, bold):
    """Bloque estilo fastfetch, pequeño y discreto, abajo a la izquierda."""
    d = ImageDraw.Draw(img)
    art = [
        "██╗  ██╗██╗  ██╗",
        "██║  ██║╚██╗██╔╝",
        "███████║ ╚███╔╝ ",
        "██╔══██║ ██╔██╗ ",
        "██║  ██║██╔╝ ██╗",
        "╚═╝  ╚═╝╚═╝  ╚═╝",
    ]
    info = [
        ("pablo", "@hypr"),
        ("─" * 11, ""),
        ("os    ", "ubuntu"),
        ("wm    ", "hyprland"),
        ("term  ", "kitty"),
        ("theme ", "hx // phosphor"),
    ]
    lh = 20  # = alto del glifo █ a 15px: bloques sin huecos
    x0, y0 = 56, H - 56 - lh * 8
    for i, line in enumerate(art):
        d.text((x0, y0 + i * lh), line, font=small, fill=scale(DIM, 1.25))
    xi = x0 + 190
    for i, (k, v) in enumerate(info):
        y = y0 + i * lh
        if i == 0:
            d.text((xi, y), k, font=bold, fill=scale(FG, 0.8))
            d.text((xi + d.textlength(k, font=bold), y), v, font=bold, fill=scale(MID, 0.8))
        else:
            d.text((xi, y), k, font=small, fill=scale(MID, 0.75) if v else scale(DIM, 1.0))
            d.text((xi + d.textlength(k, font=small), y), v, font=small, fill=scale(DIM, 1.35))
    # prompt con cursor de bloque
    py = y0 + lh * 7
    prompt = "pablo@hypr ~ $ "
    d.text((x0, py), prompt, font=small, fill=scale(MID, 0.8))
    cx = x0 + d.textlength(prompt, font=small)
    d.rectangle((cx + 1, py + 3, cx + 9, py + 18), fill=scale(FG, 0.75))
    return img


# ---------- main ----------

def main():
    seed = int(sys.argv[1]) if len(sys.argv) > 1 else 1337
    rng = random.Random(seed)
    mono, small, bold, kana = load_fonts()

    rain = draw_rain(rng, mono, kana)
    rain = center_fade(rain, 0.82)
    sig_clear = clear_box(rain, (0, H - 290, 560, H))

    # Escritorio
    desk = glow(sig_clear, 6, 0.55)
    desk = draw_signature(desk, small, bold)
    desk = glow(desk, 3, 0.25)  # halo suave también para la firma
    desk = scanlines(desk, 0.18)
    desk = vignette(desk, 0.85)
    desk.save(OUT / "hx-matrix.png", optimize=True)

    # Lock: sin firma, más oscuro y difuminado (hyprlock pinta su UI encima)
    lock = rain.filter(ImageFilter.GaussianBlur(1.4))
    lock = glow(lock, 8, 0.8)
    lock = Image.eval(lock, lambda v: int(v * 0.78))
    lock = scanlines(lock, 0.22)
    lock = vignette(lock, 0.9)
    lock.save(OUT / "hx-lock.png", optimize=True)

    print(f"seed={seed} kana={'si' if kana else 'no'} -> {OUT}")


if __name__ == "__main__":
    main()
