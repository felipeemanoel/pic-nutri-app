"""Regenera ícones e splash com os PNGs oficiais (requer Pillow).

Uso: python3 tool/brand/generate.py
A geometria antiga de symbol.py foi aposentada.
"""
import base64
from pathlib import Path

from PIL import Image

from launcher import generate

ROOT = Path(__file__).resolve().parents[2]


def splash(size):
    with Image.open(ROOT / 'assets/brand/picnutri_logo_square_white.png') as image:
        image = image.convert('RGBA')
        white = Image.new('RGBA', image.size, 'white')
        white.putalpha(image.getchannel('A'))
        white.thumbnail((size, size), Image.Resampling.LANCZOS)
        result = Image.new('RGBA', (size, size))
        result.alpha_composite(white, ((size-white.width)//2, (size-white.height)//2))
        return result


def main():
    generate()
    android = ROOT / 'android/app/src/main/res'
    for folder, size in [('mdpi', 96), ('hdpi', 144), ('xhdpi', 192),
                         ('xxhdpi', 288), ('xxxhdpi', 384)]:
        splash(size).save(android / f'drawable-{folder}/splash_symbol.png')
    ios = ROOT / 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
    for name, size in [('LaunchImage.png', 96), ('LaunchImage@2x.png', 192),
                       ('LaunchImage@3x.png', 288)]:
        splash(size).save(ios / name)
    source = ROOT / 'assets/brand/picnutri_monogram.png'
    encoded = base64.b64encode(source.read_bytes()).decode('ascii')
    with Image.open(source) as image:
        w, h = image.size
    (ROOT / 'assets/brand/picnutri_symbol.svg').write_text(
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}">'
        f'<image width="{w}" height="{h}" href="data:image/png;base64,{encoded}"/></svg>')


if __name__ == '__main__':
    main()
