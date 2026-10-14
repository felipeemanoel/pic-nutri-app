"""Gera ícones e splash do PicNutri a partir da geometria em symbol.py.

Uso (na raiz do app):  pip install cairosvg pillow && python3 tool/brand/generate.py
"""
import io
import json
import os
import sys

import cairosvg
from PIL import Image, ImageChops, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from symbol import reference_svg, rib_svg, shape_svg  # noqa: E402

PRIMARY = (8, 127, 91, 255)
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def render(svg_text, size):
    data = cairosvg.svg2png(bytestring=svg_text.encode(), output_width=size, output_height=size)
    return Image.open(io.BytesIO(data)).convert("RGBA")


def symbol(size, color=(255, 255, 255, 255)):
    """Símbolo com a nervura recortada (transparente)."""
    shape = render(shape_svg(), size).getchannel("A")
    rib = render(rib_svg(), size).getchannel("A")
    alpha = ImageChops.multiply(shape, ImageChops.invert(rib))
    out = Image.new("RGBA", (size, size), color)
    out.putalpha(alpha)
    return out


def icon(size, radius=232):
    base = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    r = int(size * radius / 1024)
    mask = Image.new("L", (size, size), 0 if r else 255)
    if r:
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, size - 1, size - 1], r, fill=255)
    base.paste(Image.new("RGBA", (size, size), PRIMARY), (0, 0), mask)
    base.alpha_composite(symbol(size))
    return base


def save(img, path, rgb=False):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    (img.convert("RGB") if rgb else img).save(path, optimize=True)


open(os.path.join(ROOT, "assets/brand/picnutri_icon.svg"), "w").write(reference_svg())
open(os.path.join(ROOT, "assets/brand/picnutri_symbol.svg"), "w").write(
    reference_svg(bg=False, fg="#087F5B", rib_color="#FFFFFF"))

android = os.path.join(ROOT, "android/app/src/main/res")
for folder, legacy, fg in [("mdpi", 48, 108), ("hdpi", 72, 162), ("xhdpi", 96, 216),
                          ("xxhdpi", 144, 324), ("xxxhdpi", 192, 432)]:
    save(icon(legacy), f"{android}/mipmap-{folder}/ic_launcher.png")
    save(symbol(fg), f"{android}/mipmap-{folder}/ic_launcher_foreground.png")
    save(symbol(fg), f"{android}/mipmap-{folder}/ic_launcher_monochrome.png")
    save(symbol(legacy * 2), f"{android}/drawable-{folder}/splash_symbol.png")

os.makedirs(f"{android}/mipmap-anydpi-v26", exist_ok=True)
open(f"{android}/mipmap-anydpi-v26/ic_launcher.xml", "w").write("""<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>
</adaptive-icon>
""")

ios = os.path.join(ROOT, "ios/Runner/Assets.xcassets/AppIcon.appiconset")
for image in json.load(open(f"{ios}/Contents.json"))["images"]:
    base = float(image["size"].split("x")[0])
    scale = int(image["scale"].rstrip("x"))
    save(icon(int(round(base * scale)), radius=0), f"{ios}/{image['filename']}", rgb=True)

launch = os.path.join(ROOT, "ios/Runner/Assets.xcassets/LaunchImage.imageset")
for name, size in [("LaunchImage.png", 96), ("LaunchImage@2x.png", 192), ("LaunchImage@3x.png", 288)]:
    save(symbol(size), f"{launch}/{name}")

save(icon(512), os.path.join(ROOT, "assets/brand/picnutri_icon_512.png"))
print("ok")
