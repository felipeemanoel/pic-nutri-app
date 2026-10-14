"""Geometria do símbolo PicNutri (grade de 1024).

A haste e o bojo formam um "P"; o bojo tem forma de folha com a ponta
subindo para a direita, e a nervura vazada é uma linha de evolução.
O mesmo desenho é usado pelo widget PicNutriLogo (lib/core/design/brand_logo.dart).
"""
STEM = "M 318 300 L 428 300 L 428 712 A 55 55 0 0 1 318 712 Z"
LEAF = "M 318 300 C 318 270 340 252 372 250 L 706 214 C 740 420 650 590 428 592 L 318 592 Z"
RIB = "M 470 524 C 560 500 640 420 676 268"
RIB_WIDTH = 30
OFFSET_Y = 20

_HEAD = '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">'


def shape_svg(fill="#FFFFFF"):
    return (f'{_HEAD}<g transform="translate(0 {OFFSET_Y})"><path d="{STEM}" fill="{fill}"/>'
            f'<path d="{LEAF}" fill="{fill}"/></g></svg>')


def rib_svg():
    return (f'{_HEAD}<path d="{RIB}" fill="none" stroke="#000" stroke-width="{RIB_WIDTH}" '
            f'stroke-linecap="round" transform="translate(0 {OFFSET_Y})"/></svg>')


def reference_svg(bg=True, fg="#FFFFFF", bgc="#087F5B", rib_color=None):
    """SVG de referência (a nervura é desenhada na cor do fundo)."""
    rib_color = rib_color or bgc
    bgel = f'<rect width="1024" height="1024" rx="232" fill="{bgc}"/>' if bg else ""
    return (f'{_HEAD}{bgel}<g transform="translate(0 {OFFSET_Y})"><path d="{STEM}" fill="{fg}"/>'
            f'<path d="{LEAF}" fill="{fg}"/><path d="{RIB}" fill="none" stroke="{rib_color}" '
            f'stroke-width="{RIB_WIDTH}" stroke-linecap="round"/></g></svg>')
