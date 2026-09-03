#!/usr/bin/env python3
"""
Composite real iOS Simulator captures (taken via tools/take_screenshots.sh)
into App Store marketing slides.

Layout: gradient background → bold tagline + subtitle → real screen image
clipped into a rounded iPhone-style frame, centered and offset toward the
bottom of the canvas. Slide 6 has no capture: it is a typographic "trust"
slide (free, no account, data stays on the phone, Open Food Facts).

Every slide is rendered per store locale (the wording differs: "sodium" for
US/CA, "salt" for GB/AU) and per App Store display size:
  6.5"  1284 × 2778   (iPhone 14 Plus class)
  6.9"  1320 × 2868   (iPhone 16 Pro Max class, required set)

Output: marketing/screenshots/<locale>/<size>/slide_{1..6}.png
        en-CA reuses en-US, en-AU reuses en-GB, fr-CA reuses fr-FR.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import re

from PIL import Image, ImageDraw, ImageFilter, ImageFont, features

import arabic_reshaper
from bidi.algorithm import get_display

# ----- Constants ------------------------------------------------------------

BASE_W, BASE_H = 1284, 2778  # design coordinates; other sizes scale from here
SIZES = {"6.5": (1284, 2778), "6.9": (1320, 2868)}

REPO = Path(__file__).resolve().parent.parent
RAW_DIR = REPO / "marketing/raw"
OUT_DIR = REPO / "marketing/screenshots"

FONT_LATIN = "/System/Library/Fonts/SFNSRounded.ttf"
FONT_ARABIC = "/System/Library/Fonts/SFArabicRounded.ttf"

SS_PRIMARY = (47, 184, 133)
SS_ACCENT = (23, 112, 130)

# Store locale -> (raw capture folder, text language, fallback locale for copy).
# Captures are per store locale because the region changes the units on screen
# (milligrams of sodium for en-US, grams of salt for en-GB).
LOCALES = {
    "en-US": ("en-US", "en", None),
    "en-GB": ("en-GB", "en", "en-US"),
    "fr-FR": ("fr-FR", "fr", None),
    "ar-SA": ("ar-SA", "ar", None),
}


# ----- Slide content --------------------------------------------------------

SLIDES = [
    {
        "raw": "1_home.png",
        "bg": (SS_PRIMARY, SS_ACCENT),
        "title": {
            "en-US": "Know your sodium, every day",
            "en-GB": "Know your salt, every day",
            "fr-FR": "Votre sel du jour, en un coup d'œil",
            "ar-SA": "ملحك اليومي بنظرة واحدة",
        },
        "subtitle": {
            "en-US": "Milligrams of sodium, per serving, against your daily goal.",
            "en-GB": "Stay under your daily salt limit.",
            "fr-FR": "Suivez votre consommation face à votre objectif.",
            "ar-SA": "تابع استهلاكك اليومي مقابل هدفك.",
        },
    },
    {
        "raw": "2_scanner.png",
        "bg": ((28, 144, 186), SS_PRIMARY),
        "title": {
            "en-US": "Scan a barcode, see the sodium",
            "en-GB": "Scan a barcode, see the salt",
            "fr-FR": "Scannez, le sel s'affiche",
            "ar-SA": "امسح الباركود واعرف الملح",
        },
        "subtitle": {
            "en-US": "Salt and sodium in one second, rated Low, Medium or High.",
            "en-GB": "Traffic-light rating in one second.",
            "fr-FR": "Teneur en sel et sodium en une seconde.",
            "ar-SA": "الملح والصوديوم في ثانية واحدة.",
        },
    },
    {
        "raw": "3_detail.png",
        "bg": ((68, 184, 113), (12, 86, 102)),
        "title": {
            "en-US": "Nutri-Score, allergens & additives",
            "fr-FR": "Nutri-Score, allergènes et additifs",
            "ar-SA": "نوتري سكور ومسببات الحساسية والإضافات",
        },
        "subtitle": {
            "en-US": "Everything about a product on one screen.",
            "fr-FR": "Tout sur un seul écran.",
            "ar-SA": "كل شيء عن المنتج في شاشة واحدة.",
        },
    },
    {
        "raw": "4_compare.png",
        "bg": ((23, 112, 130), (47, 184, 133)),
        "title": {
            "en-US": "Compare, then choose",
            "fr-FR": "Comparez, puis choisissez",
            "ar-SA": "قارن ثم اختر",
        },
        "subtitle": {
            "en-US": "Side by side: sodium, sugar, fat, Nutri-Score.",
            "en-GB": "Side by side: salt, sugar, fat, Nutri-Score.",
            "fr-FR": "Côte à côte : sel, sucres, graisses, Nutri-Score.",
            "ar-SA": "جنبًا إلى جنب: الملح والسكر والدهون ونوتري سكور.",
        },
    },
    {
        "raw": "5_history.png",
        "bg": ((23, 112, 130), (8, 50, 60)),
        "title": {
            "en-US": "Every scan, saved",
            "fr-FR": "Tous vos scans, conservés",
            "ar-SA": "كل عملية مسح محفوظة",
        },
        "subtitle": {
            "en-US": "Search, favorite and revisit any product.",
            "en-GB": "Search, favourite and revisit any product.",
            "fr-FR": "Recherchez, ajoutez en favori, retrouvez.",
            "ar-SA": "ابحث وأضف إلى المفضلة وراجع أي منتج.",
        },
    },
    {
        "raw": None,
        "bg": (SS_PRIMARY, (12, 86, 102)),
        "title": {
            "en-US": "Free. No ads. No account.",
            "fr-FR": "Gratuit. Sans pub. Sans compte.",
            "ar-SA": "مجاني. بدون إعلانات. بدون حساب.",
        },
        "subtitle": {
            "en-US": "Your data stays on your phone.",
            "fr-FR": "Vos données restent chez vous.",
            "ar-SA": "بياناتك تبقى على هاتفك.",
        },
        "bullets": {
            "en-US": [
                "No ads, no tracking",
                "No account, no sign-up",
                "Scans and journal stay on your device",
                "Product data from Open Food Facts",
            ],
            "fr-FR": [
                "Aucune publicité, aucun traçage",
                "Aucun compte, aucune inscription",
                "Scans et journal restent sur l'appareil",
                "Données produits : Open Food Facts",
            ],
            "ar-SA": [
                "بدون إعلانات أو تتبع",
                "بدون حساب أو تسجيل",
                "المسح والسجل يبقيان على جهازك",
                "بيانات المنتجات من Open Food Facts",
            ],
        },
    },
]


def copy_for(slide: dict, field: str, locale: str):
    """Locale copy with fallback (en-GB → en-US)."""
    table = slide.get(field, {})
    if locale in table:
        return table[locale]
    fallback = LOCALES[locale][2]
    if fallback and fallback in table:
        return table[fallback]
    return table.get("en-US")


# ----- Helpers --------------------------------------------------------------

HAS_RAQM = features.check("raqm")


def shape(text: str, lang: str) -> str:
    """Prepare text for PIL. With libraqm, PIL shapes and reorders Arabic itself;
    without it we pre-shape with arabic_reshaper and reorder with python-bidi."""
    if lang == "ar" and not HAS_RAQM:
        return get_display(arabic_reshaper.reshape(text))
    return text


def text_kwargs(lang: str) -> dict:
    """Extra draw.text / textbbox arguments per script."""
    if lang == "ar" and HAS_RAQM:
        return {"direction": "rtl", "language": "ar"}
    return {}


LATIN_RUN = re.compile(r"[A-Za-z][A-Za-z0-9 .'&-]*[A-Za-z0-9.]|[A-Za-z]")


def fit_font(draw, text, lang, size, max_width, weight):
    """Largest font at or below `size` whose rendering of `text` fits `max_width`."""
    while size > 20:
        fnt = font(size, lang, weight)
        bbox = draw.textbbox((0, 0), shape(text, lang), font=fnt, **text_kwargs(lang))
        if bbox[2] - bbox[0] <= max_width:
            return fnt
        size -= 2
    return font(size, lang, weight)


def font(size: int, lang: str, weight: str = "Bold") -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(FONT_ARABIC if lang == "ar" else FONT_LATIN, size)
    try:
        f.set_variation_by_name(weight)
    except Exception:
        pass
    return f


def wrap_lines(draw, text, fnt, max_width, lang):
    words = text.split(" ")
    lines, cur = [], ""
    for w in words:
        test = (cur + " " + w).strip()
        bbox = draw.textbbox((0, 0), shape(test, lang), font=fnt, **text_kwargs(lang))
        if bbox[2] - bbox[0] > max_width and cur:
            lines.append(cur)
            cur = w
        else:
            cur = test
    if cur:
        lines.append(cur)
    return lines


def draw_text_center(draw, xy, text, fnt, fill, max_width=None, lang="en"):
    lines = wrap_lines(draw, text, fnt, max_width, lang) if max_width else [text]
    line_h = fnt.size * 1.15
    y0 = xy[1] - (line_h * len(lines)) / 2
    for i, line in enumerate(lines):
        shaped_line = shape(line, lang)
        bbox = draw.textbbox((0, 0), shaped_line, font=fnt, **text_kwargs(lang))
        tw = bbox[2] - bbox[0]
        draw.text((xy[0] - tw / 2 - bbox[0], y0 + i * line_h - bbox[1]),
                  shaped_line, font=fnt, fill=fill, **text_kwargs(lang))


def diagonal_gradient(c1, c2, w, h) -> Image.Image:
    xs = np.arange(w, dtype=np.float32)
    ys = np.arange(h, dtype=np.float32)
    X, Y = np.meshgrid(xs, ys)
    t = (X / w * 0.4 + Y / h * 0.6)
    arr = np.zeros((h, w, 3), dtype=np.uint8)
    for i in range(3):
        arr[..., i] = (c1[i] * (1 - t) + c2[i] * t).astype(np.uint8)
    return Image.fromarray(arr)


# ----- iPhone frame around real captures ------------------------------------

PHONE_W = 920
PHONE_RADIUS = 96
SCREEN_INSET = 22


def frame_screenshot(canvas: Image.Image, x: int, y: int, screen_path: Path, s: float) -> None:
    """Stamp a phone-shaped bezel containing the real capture at (x, y)."""
    phone_w = int(PHONE_W * s)
    radius = int(PHONE_RADIUS * s)
    inset = int(SCREEN_INSET * s)

    src = Image.open(screen_path).convert("RGBA")
    src_w, src_h = src.size
    aspect = src_h / src_w
    screen_w = phone_w - 2 * inset
    screen_h = int(screen_w * aspect)
    phone_h = screen_h + 2 * inset

    # Drop shadow under the phone.
    pad = int(40 * s)
    shadow = Image.new("RGBA", (phone_w + 2 * pad, phone_h + 2 * pad), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((pad, pad + int(10 * s), pad + phone_w, pad + int(10 * s) + phone_h),
                         radius=radius, fill=(0, 0, 0, 150))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=28 * s))
    canvas.alpha_composite(shadow, (x - pad, y - pad))

    # Bezel.
    bezel = Image.new("RGBA", (phone_w, phone_h), (0, 0, 0, 0))
    bd = ImageDraw.Draw(bezel)
    bd.rounded_rectangle((0, 0, phone_w, phone_h), radius=radius, fill=(18, 22, 26, 255))
    canvas.alpha_composite(bezel, (x, y))

    # Inset & rounded screen.
    screen = src.resize((screen_w, screen_h), Image.LANCZOS)
    mask = Image.new("L", (screen_w, screen_h), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle((0, 0, screen_w, screen_h), radius=radius - inset, fill=255)
    canvas.paste(screen, (x + inset, y + inset), mask)


def draw_trust_card(canvas: Image.Image, bullets: list[str], lang: str, s: float, w: int) -> None:
    """White card with check-marked statements, replacing the phone frame on slide 6."""
    card_w = int(1100 * s)
    row_h = int(190 * s)
    pad_y = int(80 * s)
    card_h = pad_y * 2 + row_h * len(bullets)
    x0 = (w - card_w) // 2
    # Center the card in the area below the subtitle, where the phone frame sits on other slides.
    area_top = int(820 * s)
    area_h = canvas.height - area_top - int(160 * s)
    y0 = area_top + max(0, (area_h - card_h) // 2)

    shadow = Image.new("RGBA", (card_w + int(80 * s), card_h + int(80 * s)), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((int(40 * s), int(50 * s), int(40 * s) + card_w, int(50 * s) + card_h),
                         radius=int(56 * s), fill=(0, 0, 0, 120))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=26 * s))
    canvas.alpha_composite(shadow, (x0 - int(40 * s), y0 - int(40 * s)))

    card = Image.new("RGBA", (card_w, card_h), (0, 0, 0, 0))
    cd = ImageDraw.Draw(card)
    cd.rounded_rectangle((0, 0, card_w, card_h), radius=int(56 * s), fill=(255, 255, 255, 255))

    circle_r = int(38 * s)
    margin = int(72 * s)
    gap = int(36 * s)
    text_max = card_w - 2 * margin - 2 * circle_r - gap
    rtl = lang == "ar"
    for i, text in enumerate(bullets):
        cy = pad_y + row_h * i + row_h // 2
        cx = card_w - margin - circle_r if rtl else margin + circle_r
        cd.ellipse((cx - circle_r, cy - circle_r, cx + circle_r, cy + circle_r), fill=SS_PRIMARY)
        # Check mark: two strokes.
        k = circle_r * 0.55
        cd.line([(cx - k * 0.9, cy), (cx - k * 0.2, cy + k * 0.7), (cx + k, cy - k * 0.6)],
                fill=(255, 255, 255, 255), width=max(3, int(9 * s)), joint="curve")
        start_x = (cx - circle_r - gap) if rtl else (cx + circle_r + gap)
        draw_mixed_line(cd, text, lang, int(58 * s), text_max, start_x, cy, rtl)

    canvas.alpha_composite(card, (x0, y0))


def draw_mixed_line(cd, text, lang, size, max_width, start_x, cy, rtl):
    """Draw one line, splitting Latin runs (brand names) out of Arabic text so each
    script uses a font that has its glyphs. Runs are laid out from `start_x`,
    leftwards when `rtl`."""
    if lang != "ar":
        fnt = fit_font(cd, text, lang, size, max_width, "Semibold")
        bbox = cd.textbbox((0, 0), text, font=fnt)
        cd.text((start_x - bbox[0], cy - (bbox[3] - bbox[1]) / 2 - bbox[1]), text, font=fnt, fill=(20, 33, 28, 255))
        return

    runs = []  # (text, lang) in logical order
    pos = 0
    for m in LATIN_RUN.finditer(text):
        if m.start() > pos:
            runs.append((text[pos:m.start()], "ar"))
        runs.append((m.group(0), "en"))
        pos = m.end()
    if pos < len(text):
        runs.append((text[pos:], "ar"))

    # Shrink until the whole line fits.
    fsize = size
    while True:
        fonts = [font(fsize, l, "Semibold") for _, l in runs]
        widths = []
        for (t, l), f in zip(runs, fonts):
            bbox = cd.textbbox((0, 0), shape(t.strip(), l), font=f, **text_kwargs(l))
            widths.append(bbox[2] - bbox[0])
        space = int(fsize * 0.3)
        total = sum(widths) + space * (len(runs) - 1)
        if total <= max_width or fsize <= 20:
            break
        fsize -= 2

    x = start_x
    for (t, l), f, w in zip(runs, fonts, widths):
        shaped = shape(t.strip(), l)
        bbox = cd.textbbox((0, 0), shaped, font=f, **text_kwargs(l))
        th = bbox[3] - bbox[1]
        if rtl:
            x -= w
            cd.text((x - bbox[0], cy - th / 2 - bbox[1]), shaped, font=f, fill=(20, 33, 28, 255), **text_kwargs(l))
            x -= space
        else:
            cd.text((x - bbox[0], cy - th / 2 - bbox[1]), shaped, font=f, fill=(20, 33, 28, 255), **text_kwargs(l))
            x += w + space


# ----- Slide composition ----------------------------------------------------

def render_slide(slide: dict, locale: str, size_key: str) -> Image.Image:
    w, h = SIZES[size_key]
    s = w / BASE_W
    raw_lang, lang, _ = LOCALES[locale]

    bg = diagonal_gradient(slide["bg"][0], slide["bg"][1], w, h).convert("RGBA")
    d = ImageDraw.Draw(bg)

    title_size = int((110 if lang != "ar" else 96) * s)
    sub_size = int(50 * s)

    draw_text_center(
        d, (w // 2, int(360 * s)),
        copy_for(slide, "title", locale),
        font(title_size, lang, "Black"),
        (255, 255, 255),
        max_width=w - int(160 * s), lang=lang,
    )
    draw_text_center(
        d, (w // 2, int(620 * s)),
        copy_for(slide, "subtitle", locale),
        font(sub_size, lang, "Regular"),
        (255, 255, 255, 220),
        max_width=w - int(200 * s), lang=lang,
    )

    if slide["raw"]:
        raw = RAW_DIR / raw_lang / slide["raw"]
        frame_screenshot(bg, x=(w - int(PHONE_W * s)) // 2, y=int(820 * s), screen_path=raw, s=s)
    else:
        draw_trust_card(bg, copy_for(slide, "bullets", locale), lang, s, w)

    return bg.convert("RGB")


def main() -> None:
    for locale in LOCALES:
        for size_key in SIZES:
            out = OUT_DIR / locale / size_key
            out.mkdir(parents=True, exist_ok=True)
            for i, slide in enumerate(SLIDES, start=1):
                img = render_slide(slide, locale, size_key)
                path = out / f"slide_{i}.png"
                img.save(path, format="PNG", optimize=True)
                print(f"wrote {path.relative_to(REPO)}")


if __name__ == "__main__":
    main()
