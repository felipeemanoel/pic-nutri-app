"""Ícones de instalação derivados da imagem aprovada em app_icon_source.png."""
import base64
from pathlib import Path
from PIL import Image, ImageChops

SOURCE = Path(__file__).resolve().parents[2] / 'assets/brand/app_icon_source.png'


def icon(size, radius=0):
    # As plataformas aplicam suas próprias máscaras ao ícone quadrado.
    with Image.open(SOURCE) as source:
        return source.convert('RGB').resize((size, size), Image.Resampling.LANCZOS)


def launcher_symbol(size):
    with Image.open(SOURCE) as source:
        source = source.convert('RGB')
        # O fundo verde tem um canal próximo de zero; o símbolo é branco.
        red, green, blue = source.split()
        alpha = ImageChops.darker(ImageChops.darker(red, green), blue)
        alpha = alpha.point(lambda value: max(0, min(255, (value - 32) * 255 // 223)))
        mark = Image.new('RGBA', source.size, 'white')
        mark.putalpha(alpha)
        # Área segura dos ícones adaptativos: 72 dp dentro de 108 dp.
        inner = round(size * 2 / 3)
        mark = mark.resize((inner, inner), Image.Resampling.LANCZOS)
        result = Image.new('RGBA', (size, size))
        result.alpha_composite(mark, ((size - inner) // 2, (size - inner) // 2))
        return result


def icon_svg():
    data = base64.b64encode(SOURCE.read_bytes()).decode('ascii')
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" '
            'viewBox="0 0 1024 1024"><image width="1024" height="1024" '
            f'href="data:image/png;base64,{data}"/></svg>')


def generate():
    import json
    root = SOURCE.parents[2]
    android = root / 'android/app/src/main/res'
    for folder, legacy, foreground in [('mdpi', 48, 108), ('hdpi', 72, 162),
                                      ('xhdpi', 96, 216), ('xxhdpi', 144, 324),
                                      ('xxxhdpi', 192, 432)]:
        target = android / f'mipmap-{folder}'
        icon(legacy).save(target / 'ic_launcher.png')
        for name in ['ic_launcher_foreground.png', 'ic_launcher_monochrome.png']:
            launcher_symbol(foreground).save(target / name)
    ios = root / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    for entry in json.loads((ios / 'Contents.json').read_text())['images']:
        size = round(float(entry['size'].split('x')[0]) * int(entry['scale'][:-1]))
        icon(size).save(ios / entry['filename'])
    for path in ['assets/brand/picnutri_icon_512.png', 'store/play/picnutri-icon-512.png']:
        icon(512).save(root / path)
    (root / 'assets/brand/picnutri_icon.svg').write_text(icon_svg())


if __name__ == '__main__':
    generate()
