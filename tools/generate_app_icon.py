#!/usr/bin/env python3
"""
Generate the SaltScan app icon (1024×1024) in three iOS 18 appearances:
  - any   (light): green→teal gradient + white salt shaker
  - dark         : deep teal gradient + soft white salt shaker
  - tinted       : grayscale luminosity image (black bg, light shaker)

Run from the repo root:
    python3 tools/generate_app_icon.py
"""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

# ----- Constants ------------------------------------------------------------

SIZE = 1024
REPO = Path(__file__).resolve().parent.parent
OUT_DIR = REPO / "SaltScan/Configuration/Assets.xcassets/AppIcon.appiconset"

# Brand palette (matches DesignSystem/Theme.swift)
SS_PRIMARY  = (47, 184, 133)   # #2FB885
SS_ACCENT   = (23, 112, 130)   # #177082
DARK_TOP    = (14, 57, 66)
DARK_BOTTOM = (6, 26, 31)


# ----- Drawing primitives ---------------------------------------------------

def diagonal_gradient(c1: tuple[int, int, int], c2: tuple[int, int, int]) -> Image.Image:
    """Linear gradient from top-left (c1) to bottom-right (c2)."""
    xs = np.arange(SIZE, dtype=np.float32)
    ys = np.arange(SIZE, dtype=np.float32)
    X, Y = np.meshgrid(xs, ys)
    t = (X + Y) / (2 * (SIZE - 1))
    arr = np.zeros((SIZE, SIZE, 3), dtype=np.uint8)
    for i in range(3):
        arr[..., i] = (c1[i] * (1 - t) + c2[i] * t).astype(np.uint8)
    return Image.fromarray(arr)


def shaker_mask() -> tuple[Image.Image, Image.Image]:
    """
    Build the salt shaker as two layers:
      - body  : rounded-rectangle bottle
      - cap   : narrower rounded-rectangle on top with hole cutouts
    Plus a few salt grains floating above the shaker on the body mask
    so the silhouette tells the "salt" story instantly.
    """
    # Bottle layout — fits the central 60% safe area.
    body_w = 380
    body_h = 460
    cx = SIZE / 2
    cy = SIZE / 2 + 60                 # nudge down to leave room for grains

    body_left   = cx - body_w / 2
    body_right  = cx + body_w / 2
    body_top    = cy - body_h / 2
    body_bottom = cy + body_h / 2

    # Cap layout — sits on top of the body, slightly narrower with rounded corners.
    cap_w = 300
    cap_h = 130
    cap_left   = cx - cap_w / 2
    cap_right  = cx + cap_w / 2
    cap_bottom = body_top + 6          # slight overlap into the body
    cap_top    = cap_bottom - cap_h

    body_mask = Image.new("L", (SIZE, SIZE), 0)
    cap_mask  = Image.new("L", (SIZE, SIZE), 0)
    body_draw = ImageDraw.Draw(body_mask)
    cap_draw  = ImageDraw.Draw(cap_mask)

    # --- Bottle body: rounded rectangle.
    body_draw.rounded_rectangle(
        (body_left, body_top, body_right, body_bottom),
        radius=80,
        fill=255,
    )
    # Subtle "label" indent: a thin notch line near the middle — purely
    # decorative, gives the silhouette a recognizable shaker waist.
    notch_y1 = cy - 30
    notch_y2 = cy + 30
    notch_inset = 24
    body_draw.rectangle(
        (body_left + notch_inset, notch_y1, body_right - notch_inset, notch_y2),
        fill=0,
    )

    # --- Cap: rounded rectangle on top.
    cap_draw.rounded_rectangle(
        (cap_left, cap_top, cap_right, cap_bottom),
        radius=46,
        fill=255,
    )
    # Pour holes — 3 small circles arranged on the cap's top half.
    hole_r = 16
    hole_y = cap_top + cap_h * 0.38
    for dx in (-58, 0, 58):
        cap_draw.ellipse(
            (cx + dx - hole_r, hole_y - hole_r, cx + dx + hole_r, hole_y + hole_r),
            fill=0,
        )

    # --- Floating salt grains above the shaker.
    grains = [
        (cx - 150, cap_top - 110, 22),
        (cx - 60,  cap_top - 165, 18),
        (cx + 60,  cap_top - 150, 20),
        (cx + 150, cap_top - 95,  16),
        (cx + 5,   cap_top - 80,  12),
    ]
    for gx, gy, gr in grains:
        body_draw.rounded_rectangle(
            (gx - gr, gy - gr, gx + gr, gy + gr),
            radius=gr * 0.35,
            fill=255,
        )

    body_mask = body_mask.filter(ImageFilter.GaussianBlur(radius=1.4))
    cap_mask  = cap_mask.filter(ImageFilter.GaussianBlur(radius=1.4))
    return body_mask, cap_mask


def union(*masks: Image.Image) -> Image.Image:
    arrays = [np.asarray(m, dtype=np.uint16) for m in masks]
    out = arrays[0].copy()
    for a in arrays[1:]:
        out = np.maximum(out, a)
    return Image.fromarray(out.astype(np.uint8))


def soft_drop_shadow(mask: Image.Image, offset: int = 10, blur: int = 28, opacity: int = 130) -> Image.Image:
    arr = np.asarray(mask, dtype=np.uint16)
    rgba = np.zeros((SIZE, SIZE, 4), dtype=np.uint8)
    rgba[..., 3] = (arr * opacity // 255).astype(np.uint8)
    layer = Image.fromarray(rgba).filter(ImageFilter.GaussianBlur(radius=blur))
    out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    out.paste(layer, (0, offset), layer)
    return out


# ----- Variant composition --------------------------------------------------

def compose(background: Image.Image, mark_color: tuple[int, int, int], mark_alpha: int = 255) -> Image.Image:
    base = background.convert("RGBA")

    body, cap = shaker_mask()
    silhouette = union(body, cap)

    # Drop shadow under the whole silhouette for subtle depth.
    base = Image.alpha_composite(base, soft_drop_shadow(silhouette))

    # Tint silhouette with the requested colour.
    arr = np.asarray(silhouette, dtype=np.uint16)
    rgba = np.zeros((SIZE, SIZE, 4), dtype=np.uint8)
    rgba[..., 0] = mark_color[0]
    rgba[..., 1] = mark_color[1]
    rgba[..., 2] = mark_color[2]
    rgba[..., 3] = (arr * mark_alpha // 255).astype(np.uint8)

    return Image.alpha_composite(base, Image.fromarray(rgba)).convert("RGB")


def make_any() -> Image.Image:
    return compose(diagonal_gradient(SS_PRIMARY, SS_ACCENT), mark_color=(255, 255, 255))


def make_dark() -> Image.Image:
    return compose(diagonal_gradient(DARK_TOP, DARK_BOTTOM), mark_color=(255, 255, 255), mark_alpha=235)


def make_tinted() -> Image.Image:
    bg = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
    return compose(bg, mark_color=(235, 235, 235))


# ----- Entrypoint -----------------------------------------------------------

def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, builder in [
        ("AppIcon_any.png",   make_any),
        ("AppIcon_dark.png",  make_dark),
        ("AppIcon_light.png", make_tinted),     # tinted appearance slot
    ]:
        path = OUT_DIR / name
        builder().save(path, format="PNG", optimize=True)
        print(f"wrote {path.relative_to(REPO)}")


if __name__ == "__main__":
    main()
