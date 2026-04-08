#!/usr/bin/env python3
"""
Composite real iOS Simulator captures (taken via tools/take_screenshots.sh)
into App Store marketing slides.

Layout: gradient background → bold tagline + subtitle → real screen image
clipped into a rounded iPhone-style frame, centered and offset toward the
bottom of the canvas.

Output: marketing/screenshots/{en,fr,ar}/slide_{1..5}.png
        1320 × 2868 (iPhone 6.9" required size).
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

import arabic_reshaper
from bidi.algorithm import get_display

# ----- Constants ------------------------------------------------------------

W, H = 1320, 2868
REPO = Path(__file__).resolve().parent.parent
RAW_DIR = REPO / "marketing/raw"
OUT_DIR = REPO / "marketing/screenshots"

FONT_LATIN  = "/System/Library/Fonts/SFNSRounded.ttf"
FONT_ARABIC = "/System/Library/Fonts/SFArabicRounded.ttf"

SS_PRIMARY = (47, 184, 133)
SS_ACCENT  = (23, 112, 130)


# ----- Slide content --------------------------------------------------------

SLIDES = [
    {
        "raw": "1_home.png",
        "bg": (SS_PRIMARY, SS_ACCENT),
        "title": {
            "en": "Track your daily salt",
            "fr": "Suivez votre sel quotidien",
            "ar": "تتبع ملحك اليومي",
        },
        "subtitle": {
            "en": "Stay below the WHO 5 g daily limit.",
            "fr": "Restez sous la limite OMS de 5 g par jour.",
            "ar": "ابق تحت حد 5 غرامات اليومي.",
        },
    },
    {
        "raw": "1bis_scanner.png",
        "bg": ((28, 144, 186), (47, 184, 133)),
        "title": {
            "en": "Scan any product",
            "fr": "Scannez n'importe quel produit",
            "ar": "امسح أي منتج",
        },
        "subtitle": {
            "en": "Instantly read the salt content of any food.",
            "fr": "Lisez instantanément le sel de tout aliment.",
            "ar": "اقرأ فورًا محتوى الملح في أي طعام.",
        },
    },
    {
        "raw": "3_detail.png",
        "bg": ((68, 184, 113), (12, 86, 102)),
        "title": {
            "en": "Full nutrition at a glance",
            "fr": "Toute la nutrition en un coup d'œil",
            "ar": "كل المعلومات الغذائية بنظرة",
        },
        "subtitle": {
            "en": "Nutriscore, allergens, additives & more.",
            "fr": "Nutriscore, allergènes, additifs et plus.",
            "ar": "نوتري سكور والمواد المسببة للحساسية والمزيد.",
        },
    },
    {
        "raw": "4_history.png",
        "bg": ((23, 112, 130), (8, 50, 60)),
        "title": {
            "en": "Keep your scan history",
            "fr": "Gardez votre historique",
            "ar": "احتفظ بسجل عمليات المسح",
        },
        "subtitle": {
            "en": "Search, favorite and revisit any product.",
            "fr": "Recherchez et retrouvez vos produits favoris.",
            "ar": "ابحث وأضف إلى المفضلة وراجع منتجاتك.",
        },
    },
    {
        "raw": "5_settings.png",
        "bg": ((47, 184, 133), (12, 86, 102)),
        "title": {
            "en": "Stay healthy, every day",
            "fr": "Restez en bonne santé chaque jour",
            "ar": "ابق بصحة جيدة كل يوم",
        },
        "subtitle": {
            "en": "Personalize your daily salt goal.",
            "fr": "Personnalisez votre objectif quotidien.",
            "ar": "خصص هدفك اليومي من الملح.",
        },
    },
]


# ----- Helpers --------------------------------------------------------------

def shape(text: str, lang: str) -> str:
    if lang == "ar":
        return get_display(arabic_reshaper.reshape(text))
    return text


def font(size: int, lang: str, weight: str = "Bold") -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(FONT_ARABIC if lang == "ar" else FONT_LATIN, size)
    try:
        f.set_variation_by_name(weight)
    except Exception:
        pass
    return f


def draw_text_center(draw, xy, text, fnt, fill, max_width=None, lang="en"):
    if max_width:
        words = text.split(" ")
        lines, cur = [], ""
        for w in words:
            test = (cur + " " + w).strip()
            bbox = draw.textbbox((0, 0), shape(test, lang), font=fnt)
            if bbox[2] - bbox[0] > max_width and cur:
                lines.append(cur)
                cur = w
            else:
                cur = test
        if cur:
            lines.append(cur)
    else:
        lines = [text]
    line_h = fnt.size * 1.15
    y0 = xy[1] - (line_h * len(lines)) / 2
    for i, line in enumerate(lines):
        shaped_line = shape(line, lang)
        bbox = draw.textbbox((0, 0), shaped_line, font=fnt)
        tw = bbox[2] - bbox[0]
        draw.text((xy[0] - tw / 2 - bbox[0], y0 + i * line_h - bbox[1]),
                  shaped_line, font=fnt, fill=fill)


def diagonal_gradient(c1, c2, w=W, h=H) -> Image.Image:
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


def frame_screenshot(canvas: Image.Image, x: int, y: int, screen_path: Path) -> None:
    """Stamp a phone-shaped bezel containing the real capture at (x, y)."""
    src = Image.open(screen_path).convert("RGBA")
    src_w, src_h = src.size
    aspect = src_h / src_w
    screen_w = PHONE_W - 2 * SCREEN_INSET
    screen_h = int(screen_w * aspect)
    phone_h = screen_h + 2 * SCREEN_INSET

    # Drop shadow under the phone.
    shadow = Image.new("RGBA", (PHONE_W + 80, phone_h + 80), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((40, 50, 40 + PHONE_W, 50 + phone_h),
                         radius=PHONE_RADIUS, fill=(0, 0, 0, 150))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=28))
    canvas.alpha_composite(shadow, (x - 40, y - 40))

    # Bezel.
    bezel = Image.new("RGBA", (PHONE_W, phone_h), (0, 0, 0, 0))
    bd = ImageDraw.Draw(bezel)
    bd.rounded_rectangle((0, 0, PHONE_W, phone_h),
                         radius=PHONE_RADIUS, fill=(18, 22, 26, 255))
    canvas.alpha_composite(bezel, (x, y))

    # Inset & rounded screen.
    screen = src.resize((screen_w, screen_h))
    mask = Image.new("L", (screen_w, screen_h), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle((0, 0, screen_w, screen_h),
                         radius=PHONE_RADIUS - SCREEN_INSET, fill=255)
    canvas.paste(screen, (x + SCREEN_INSET, y + SCREEN_INSET), mask)


# ----- Slide composition ----------------------------------------------------

def render_slide(slide: dict, lang: str) -> Image.Image:
    bg = diagonal_gradient(slide["bg"][0], slide["bg"][1]).convert("RGBA")
    d = ImageDraw.Draw(bg)

    title_size = 110 if lang != "ar" else 96
    sub_size = 50

    draw_text_center(
        d, (W // 2, 360),
        slide["title"][lang],
        font(title_size, lang, "Black"),
        (255, 255, 255),
        max_width=W - 160, lang=lang,
    )
    draw_text_center(
        d, (W // 2, 620),
        slide["subtitle"][lang],
        font(sub_size, lang, "Regular"),
        (255, 255, 255, 220),
        max_width=W - 200, lang=lang,
    )

    # Frame the real capture toward the bottom.
    raw = RAW_DIR / lang / slide["raw"]
    frame_screenshot(bg, x=(W - PHONE_W) // 2, y=820, screen_path=raw)

    return bg.convert("RGB")


def main() -> None:
    for lang in ["en", "fr", "ar"]:
        out = OUT_DIR / lang
        out.mkdir(parents=True, exist_ok=True)
        for i, slide in enumerate(SLIDES, start=1):
            img = render_slide(slide, lang)
            path = out / f"slide_{i}.png"
            img.save(path, format="PNG", optimize=True)
            print(f"wrote {path.relative_to(REPO)}")


if __name__ == "__main__":
    main()
