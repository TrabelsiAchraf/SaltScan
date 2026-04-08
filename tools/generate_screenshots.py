#!/usr/bin/env python3
"""
Generate App Store marketing screenshots for SaltScan 0.2.0.

Output: 5 slides × 3 languages (en/fr/ar) = 15 PNGs at 1320×2868
        (iPhone 6.9", required size for new App Store submissions).

Each slide has:
  - A bold tagline at the top
  - A subtitle
  - A stylized iPhone mockup showing a representative app screen below

The mock UIs are deliberately simplified geometric reconstructions of the
real screens — fast to generate, on-brand, and stay valid even if the
actual layout drifts. Run from the repo root:

    python3 tools/generate_screenshots.py
"""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

import arabic_reshaper
from bidi.algorithm import get_display

# ----- Constants ------------------------------------------------------------

W, H = 1320, 2868
REPO = Path(__file__).resolve().parent.parent
OUT_DIR = REPO / "marketing/screenshots"

FONT_LATIN = "/System/Library/Fonts/SFNSRounded.ttf"
FONT_ARABIC = "/System/Library/Fonts/SFArabicRounded.ttf"

# Brand palette
SS_PRIMARY = (47, 184, 133)
SS_ACCENT = (23, 112, 130)
SS_SEVERITY_LOW = (56, 189, 115)
SS_SEVERITY_MED = (245, 163, 51)
SS_SEVERITY_HIGH = (237, 84, 84)
SURFACE = (255, 255, 255)
SURFACE_DIM = (244, 246, 248)
TEXT_PRIMARY = (18, 32, 36)
TEXT_SECONDARY = (110, 124, 130)


# ----- Text helpers ---------------------------------------------------------

def shape(text: str, lang: str) -> str:
    if lang == "ar":
        return get_display(arabic_reshaper.reshape(text))
    return text


def font(size: int, lang: str, weight: str = "Bold") -> ImageFont.FreeTypeFont:
    path = FONT_ARABIC if lang == "ar" else FONT_LATIN
    f = ImageFont.truetype(path, size)
    try:
        f.set_variation_by_name(weight)
    except Exception:
        pass
    return f


def draw_text_center(draw, xy, text, fnt, fill, max_width=None, lang="en"):
    """
    Center-aligned multi-line text with logical-order word wrap.

    For Arabic the BiDi reshaping must happen *after* the wrap, otherwise the
    visual wrap flips the order of words between lines.
    """
    if max_width:
        words = text.split(" ")
        lines = []
        cur = ""
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
    total_h = line_h * len(lines)
    y0 = xy[1] - total_h / 2
    for i, line in enumerate(lines):
        shaped_line = shape(line, lang)
        bbox = draw.textbbox((0, 0), shaped_line, font=fnt)
        tw = bbox[2] - bbox[0]
        draw.text((xy[0] - tw / 2 - bbox[0], y0 + i * line_h - bbox[1]),
                  shaped_line, font=fnt, fill=fill)


# ----- Background -----------------------------------------------------------

def diagonal_gradient(c1, c2, w=W, h=H) -> Image.Image:
    xs = np.arange(w, dtype=np.float32)
    ys = np.arange(h, dtype=np.float32)
    X, Y = np.meshgrid(xs, ys)
    t = (X / w * 0.4 + Y / h * 0.6)
    arr = np.zeros((h, w, 3), dtype=np.uint8)
    for i in range(3):
        arr[..., i] = (c1[i] * (1 - t) + c2[i] * t).astype(np.uint8)
    return Image.fromarray(arr)


# ----- iPhone mockup --------------------------------------------------------

PHONE_W = 920
PHONE_H = 1880
PHONE_RADIUS = 110
SCREEN_INSET = 24


def draw_phone_frame(canvas: Image.Image, x: int, y: int, screen_image: Image.Image) -> None:
    """Stamp an iPhone-shaped frame containing `screen_image` onto `canvas`."""
    # Outer frame mask + fill
    frame_layer = Image.new("RGBA", (PHONE_W + 60, PHONE_H + 60), (0, 0, 0, 0))
    fd = ImageDraw.Draw(frame_layer)
    # Shadow
    shadow = Image.new("RGBA", frame_layer.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((30, 36, 30 + PHONE_W, 36 + PHONE_H), radius=PHONE_RADIUS, fill=(0, 0, 0, 130))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=24))
    canvas.alpha_composite(shadow, (x - 30, y - 30))

    # Bezel
    fd.rounded_rectangle((30, 30, 30 + PHONE_W, 30 + PHONE_H), radius=PHONE_RADIUS, fill=(20, 24, 28, 255))
    canvas.alpha_composite(frame_layer, (x - 30, y - 30))

    # Inset screen
    screen_w = PHONE_W - 2 * SCREEN_INSET
    screen_h = PHONE_H - 2 * SCREEN_INSET
    screen = screen_image.resize((screen_w, screen_h)).convert("RGBA")
    # Round screen corners
    mask = Image.new("L", (screen_w, screen_h), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle((0, 0, screen_w, screen_h), radius=PHONE_RADIUS - SCREEN_INSET, fill=255)
    canvas.paste(screen, (x + SCREEN_INSET, y + SCREEN_INSET), mask)

    # Dynamic island
    island_w = 240
    island_h = 56
    island_x = x + (PHONE_W - island_w) // 2
    island_y = y + 38
    od = ImageDraw.Draw(canvas)
    od.rounded_rectangle((island_x, island_y, island_x + island_w, island_y + island_h),
                         radius=island_h // 2, fill=(8, 12, 14, 255))


# ----- Mock app screens -----------------------------------------------------

def screen_canvas(bg=SURFACE) -> Image.Image:
    return Image.new("RGBA", (PHONE_W - 2 * SCREEN_INSET, PHONE_H - 2 * SCREEN_INSET), bg + (255,))


def mock_home() -> Image.Image:
    img = screen_canvas(SURFACE_DIM)
    d = ImageDraw.Draw(img)
    cx = img.width // 2

    # Header
    d.text((60, 130), "Hello 👋", font=font(64, "en", "Bold"), fill=TEXT_PRIMARY)
    d.text((60, 210), "Today's salt", font=font(38, "en", "Regular"), fill=TEXT_SECONDARY)

    # Daily ring card
    card_top = 320
    card_bot = 760
    d.rounded_rectangle((50, card_top, img.width - 50, card_bot), radius=48, fill=SURFACE)

    ring_cx = 250
    ring_cy = (card_top + card_bot) // 2
    ring_r = 150
    # Track
    d.ellipse((ring_cx - ring_r, ring_cy - ring_r, ring_cx + ring_r, ring_cy + ring_r),
              outline=(56, 189, 115, 60), width=28)
    # Progress arc (62%)
    d.arc((ring_cx - ring_r, ring_cy - ring_r, ring_cx + ring_r, ring_cy + ring_r),
          start=-90, end=-90 + 360 * 0.62, fill=SS_PRIMARY, width=28)
    # Value
    val = "3.1g"
    bb = d.textbbox((0, 0), val, font=font(80, "en", "Black"))
    d.text((ring_cx - (bb[2] - bb[0]) / 2, ring_cy - 50), val, font=font(80, "en", "Black"), fill=SS_PRIMARY)
    bb = d.textbbox((0, 0), "today", font=font(32, "en", "Regular"))
    d.text((ring_cx - (bb[2] - bb[0]) / 2, ring_cy + 40), "today", font=font(32, "en", "Regular"), fill=TEXT_SECONDARY)

    # Right side text
    d.text((460, ring_cy - 80), "Daily salt", font=font(44, "en", "Bold"), fill=TEXT_PRIMARY)
    d.text((460, ring_cy - 20), "Goal: 5.0 g", font=font(34, "en", "Regular"), fill=TEXT_SECONDARY)

    # Latest scans header
    d.text((60, 820), "Latest scans", font=font(46, "en", "Bold"), fill=TEXT_PRIMARY)

    items = [
        ("San Pellegrino", "0.02 g / 100g", SS_SEVERITY_LOW),
        ("Doritos Nacho",  "1.42 g / 100g", SS_SEVERITY_MED),
        ("Soy Sauce",      "5.81 g / 100g", SS_SEVERITY_HIGH),
    ]
    for i, (name, sub, sev) in enumerate(items):
        y0 = 900 + i * 150
        d.rounded_rectangle((50, y0, img.width - 50, y0 + 130), radius=36, fill=SURFACE)
        # Severity dot
        d.ellipse((90, y0 + 50, 130, y0 + 90), fill=sev)
        d.text((170, y0 + 30), name, font=font(38, "en", "Bold"), fill=TEXT_PRIMARY)
        d.text((170, y0 + 75), sub, font=font(28, "en", "Regular"), fill=TEXT_SECONDARY)

    return img


def mock_scanner() -> Image.Image:
    img = screen_canvas((10, 14, 18))
    d = ImageDraw.Draw(img)
    cx = img.width // 2
    cy = img.height // 2

    # Viewfinder rounded rect
    vw, vh = 720, 460
    x0, y0 = cx - vw // 2, cy - vh // 2 - 80
    d.rounded_rectangle((x0, y0, x0 + vw, y0 + vh), radius=64, outline=(255, 255, 255, 220), width=8)

    # Fake barcode lines
    bar_x = x0 + 80
    bar_y = y0 + vh // 2 - 80
    bar_w = vw - 160
    for i, w in enumerate([8, 4, 12, 6, 4, 14, 8, 6, 10, 4, 12, 6, 8, 4, 14, 6, 4, 10, 12, 6]):
        gap = 10
        d.rectangle((bar_x, bar_y, bar_x + w, bar_y + 160), fill=(255, 255, 255, 240))
        bar_x += w + gap

    # Laser line
    d.line((x0 + 30, cy - 80, x0 + vw - 30, cy - 80), fill=SS_PRIMARY + (255,), width=6)

    # Instructions pill
    pill = "Align the barcode within the frame"
    bb = d.textbbox((0, 0), pill, font=font(34, "en", "Semibold"))
    pw = bb[2] - bb[0] + 80
    ph = 80
    px0 = cx - pw // 2
    py0 = cy + 320
    d.rounded_rectangle((px0, py0, px0 + pw, py0 + ph), radius=ph // 2, fill=(0, 0, 0, 180))
    d.text((cx - (bb[2] - bb[0]) / 2, py0 + 18), pill, font=font(34, "en", "Semibold"), fill=(255, 255, 255))

    return img


def mock_detail() -> Image.Image:
    img = screen_canvas(SURFACE_DIM)
    d = ImageDraw.Draw(img)

    # Hero card
    d.rounded_rectangle((50, 130, img.width - 50, 380), radius=48, fill=SURFACE)
    d.rounded_rectangle((90, 170, 290, 340), radius=24, fill=(220, 226, 230))
    d.text((320, 175), "Doritos Nacho", font=font(44, "en", "Bold"), fill=TEXT_PRIMARY)
    d.text((320, 230), "Frito-Lay", font=font(32, "en", "Regular"), fill=TEXT_SECONDARY)
    # Severity pill
    d.rounded_rectangle((320, 280, 480, 330), radius=24, fill=(245, 163, 51, 50))
    d.text((345, 290), "Medium", font=font(30, "en", "Semibold"), fill=SS_SEVERITY_MED)

    # Score card
    d.rounded_rectangle((50, 410, img.width - 50, 600), radius=48, fill=SURFACE)
    # Nutriscore badge
    d.ellipse((110, 450, 230, 570), fill=SS_SEVERITY_MED)
    d.text((148, 470), "C", font=font(80, "en", "Black"), fill=(255, 255, 255))
    d.text((270, 460), "Nutriscore", font=font(34, "en", "Regular"), fill=TEXT_SECONDARY)
    d.text((270, 500), "Average", font=font(48, "en", "Bold"), fill=TEXT_PRIMARY)
    # Salt right
    d.text((600, 460), "Salt / 100g", font=font(28, "en", "Regular"), fill=TEXT_SECONDARY)
    d.text((600, 500), "1.42 g", font=font(56, "en", "Black"), fill=SS_SEVERITY_MED)

    # Nutrients card
    d.rounded_rectangle((50, 630, img.width - 50, 1180), radius=48, fill=SURFACE)
    d.text((90, 660), "Nutrients (per 100g)", font=font(38, "en", "Bold"), fill=TEXT_PRIMARY)
    rows = [
        ("Energy",    "498 kcal"),
        ("Sugars",    "1.4 g"),
        ("Sat. fat",  "3.2 g"),
        ("Proteins",  "6.8 g"),
        ("Sodium",    "0.568 g"),
    ]
    for i, (label, value) in enumerate(rows):
        y = 740 + i * 80
        d.ellipse((100, y + 10, 140, y + 50), fill=SS_PRIMARY)
        d.text((170, y + 10), label, font=font(34, "en", "Regular"), fill=TEXT_SECONDARY)
        bb = d.textbbox((0, 0), value, font=font(38, "en", "Bold"))
        d.text((img.width - 90 - (bb[2] - bb[0]), y + 5), value, font=font(38, "en", "Bold"), fill=TEXT_PRIMARY)

    return img


def mock_history() -> Image.Image:
    img = screen_canvas(SURFACE_DIM)
    d = ImageDraw.Draw(img)
    d.text((60, 130), "History", font=font(64, "en", "Bold"), fill=TEXT_PRIMARY)

    # Search bar
    d.rounded_rectangle((50, 240, img.width - 50, 340), radius=48, fill=SURFACE)
    d.ellipse((90, 270, 140, 320), outline=TEXT_SECONDARY, width=4)
    d.text((170, 268), "Search by name or barcode", font=font(32, "en", "Regular"), fill=TEXT_SECONDARY)

    # Today section header
    d.text((60, 380), "Today", font=font(36, "en", "Semibold"), fill=TEXT_SECONDARY)

    items = [
        ("San Pellegrino", "Sparkling water", SS_SEVERITY_LOW),
        ("Doritos Nacho",  "Frito-Lay",       SS_SEVERITY_MED),
        ("Soy Sauce",      "Kikkoman",        SS_SEVERITY_HIGH),
        ("Whole Milk",     "Lactel",          SS_SEVERITY_LOW),
        ("Camembert",      "Président",       SS_SEVERITY_HIGH),
    ]
    for i, (name, sub, sev) in enumerate(items):
        y0 = 450 + i * 180
        d.rounded_rectangle((50, y0, img.width - 50, y0 + 160), radius=40, fill=SURFACE)
        d.rounded_rectangle((90, y0 + 30, 200, y0 + 130), radius=24, fill=(220, 226, 230))
        d.text((230, y0 + 30), name, font=font(40, "en", "Bold"), fill=TEXT_PRIMARY)
        d.text((230, y0 + 80), sub, font=font(30, "en", "Regular"), fill=TEXT_SECONDARY)
        # Severity pill
        d.ellipse((img.width - 130, y0 + 60, img.width - 90, y0 + 100), fill=sev)

    return img


def mock_settings() -> Image.Image:
    img = screen_canvas(SURFACE_DIM)
    d = ImageDraw.Draw(img)
    d.text((60, 130), "Settings", font=font(64, "en", "Bold"), fill=TEXT_PRIMARY)

    d.text((60, 260), "GENERAL", font=font(28, "en", "Semibold"), fill=TEXT_SECONDARY)
    d.rounded_rectangle((50, 310, img.width - 50, 480), radius=40, fill=SURFACE)
    d.text((90, 340), "Appearance", font=font(36, "en", "Regular"), fill=TEXT_PRIMARY)
    d.text((img.width - 240, 340), "Automatic", font=font(34, "en", "Regular"), fill=TEXT_SECONDARY)
    d.line((90, 410, img.width - 90, 410), fill=(220, 226, 230), width=2)
    d.text((90, 425), "Language", font=font(36, "en", "Regular"), fill=TEXT_PRIMARY)
    d.text((img.width - 240, 425), "English", font=font(34, "en", "Regular"), fill=TEXT_SECONDARY)

    # Daily salt goal card
    d.text((60, 540), "DAILY SALT GOAL", font=font(28, "en", "Semibold"), fill=TEXT_SECONDARY)
    d.rounded_rectangle((50, 590, img.width - 50, 820), radius=40, fill=SURFACE)
    d.text((90, 620), "Goal", font=font(36, "en", "Regular"), fill=TEXT_PRIMARY)
    d.text((img.width - 220, 620), "5.0 g", font=font(40, "en", "Bold"), fill=SS_PRIMARY)

    # Slider
    track_y = 720
    d.rounded_rectangle((90, track_y, img.width - 90, track_y + 18), radius=9, fill=(220, 226, 230))
    fill_w = int((img.width - 180) * 0.5)
    d.rounded_rectangle((90, track_y, 90 + fill_w, track_y + 18), radius=9, fill=SS_PRIMARY)
    d.ellipse((90 + fill_w - 24, track_y - 16, 90 + fill_w + 24, track_y + 32), fill=SURFACE,
              outline=SS_PRIMARY, width=6)

    d.text((90, 770), "WHO recommends ≤ 5 g per day.",
           font=font(28, "en", "Regular"), fill=TEXT_SECONDARY)

    return img


# ----- Slide composition ----------------------------------------------------

# (background_top, background_bottom, mock_fn, en, fr, ar, subtitle_en, subtitle_fr, subtitle_ar)
SLIDES = [
    {
        "bg": (SS_PRIMARY, SS_ACCENT),
        "mock": mock_scanner,
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
        "bg": ((28, 144, 186), (47, 184, 133)),
        "mock": mock_home,
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
        "bg": ((68, 184, 113), (12, 86, 102)),
        "mock": mock_detail,
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
        "bg": ((23, 112, 130), (8, 50, 60)),
        "mock": mock_history,
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
        "bg": ((47, 184, 133), (12, 86, 102)),
        "mock": mock_settings,
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


def render_slide(slide: dict, lang: str) -> Image.Image:
    bg = diagonal_gradient(slide["bg"][0], slide["bg"][1])
    canvas = bg.convert("RGBA")
    d = ImageDraw.Draw(canvas)

    title = slide["title"][lang]
    subtitle = slide["subtitle"][lang]

    title_size = 110 if lang != "ar" else 96
    sub_size = 50

    draw_text_center(d, (W // 2, 360), title, font(title_size, lang, "Black"),
                     (255, 255, 255), max_width=W - 160, lang=lang)
    draw_text_center(d, (W // 2, 620), subtitle, font(sub_size, lang, "Regular"),
                     (255, 255, 255, 220), max_width=W - 200, lang=lang)

    # Mockup centered horizontally, near the bottom
    mock = slide["mock"]()
    phone_x = (W - PHONE_W) // 2
    phone_y = 820
    draw_phone_frame(canvas, phone_x, phone_y, mock)

    return canvas.convert("RGB")


# ----- Entrypoint -----------------------------------------------------------

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
