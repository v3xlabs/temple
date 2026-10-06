"""Builds outline fonts from TempleOS's 8x8 `sys_font_std` bitmap.

Each set pixel becomes a square, so the glyphs stay sharp at every integer
multiple of 8 px. usage: templeos-font.py FontStd.HC OUTDIR
"""

import re
import sys

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen

PIXEL = 128
CELL = 8
# Row 7 holds the descenders of g, j, p, q and y.
BASELINE_ROW = 7

source, outdir = sys.argv[1], sys.argv[2]
with open(source, encoding="latin-1") as file:
    table = [int(value, 16) for value in re.findall(r"0x([0-9A-Fa-f]{16})", file.read())]
assert len(table) == 256, len(table)


# TempleOS stores row 0 in the low byte and the leftmost pixel in bit 0.
def runs(bitmap):
    for row in range(CELL):
        bits = (bitmap >> (row * 8)) & 0xFF
        column = 0
        while column < CELL:
            if bits >> column & 1:
                start = column
                while column < CELL and bits >> column & 1:
                    column += 1
                yield row, start, column
            else:
                column += 1


def glyph(bitmap):
    pen = TTGlyphPen(None)
    for row, start, end in runs(bitmap):
        top = (BASELINE_ROW - row) * PIXEL
        bottom = top - PIXEL
        pen.moveTo((start * PIXEL, top))
        pen.lineTo((end * PIXEL, top))
        pen.lineTo((end * PIXEL, bottom))
        pen.lineTo((start * PIXEL, bottom))
        pen.closePath()
    return pen.glyph()


# Printable ASCII, then the CP437 upper half that TempleOS keeps from the PC
# character set. 0x7F and 0xFF are solid blocks in TempleOS, not DEL and NBSP.
codes = list(range(0x20, 0x7F)) + list(range(0x80, 0xFF))
charmap = {}
glyphs = {".notdef": glyph(0)}
for code in codes:
    name = f"uni{code:02X}"
    char = bytes([code]).decode("cp437")
    charmap[ord(char)] = name
    glyphs[name] = glyph(table[code])


def build(family, em_pixels, filename):
    builder = FontBuilder(em_pixels * PIXEL, isTTF=True)
    order = list(glyphs)
    builder.setupGlyphOrder(order)
    builder.setupCharacterMap(charmap)
    builder.setupGlyf(glyphs)
    builder.setupHorizontalMetrics({name: (CELL * PIXEL, 0) for name in order})
    ascent = BASELINE_ROW * PIXEL
    descent = (CELL - BASELINE_ROW) * PIXEL
    builder.setupHorizontalHeader(ascent=ascent, descent=-descent, lineGap=0)
    builder.setupNameTable(
        {
            "familyName": family,
            "styleName": "Regular",
            "uniqueFontIdentifier": family.replace(" ", ""),
            "fullName": family,
            "psName": family.replace(" ", "") + "-Regular",
            "copyright": "TempleOS by Terry A. Davis, public domain",
        }
    )
    builder.setupOS2(
        sTypoAscender=ascent,
        sTypoDescender=-descent,
        sTypoLineGap=0,
        usWinAscent=ascent,
        usWinDescent=descent,
        xAvgCharWidth=CELL * PIXEL,
        fsSelection=0x40 | 0x80,
    )
    builder.font["OS/2"].panose.bFamilyType = 2
    builder.font["OS/2"].panose.bProportion = 9
    builder.setupPost(isFixedPitch=1)
    builder.save(f"{outdir}/{filename}")


# The shell sizes text in pixels and kitty in points (4/3 px at 96 dpi), so
# one family has an em of 6 pixels and the other of 8: both draw the 8x8 cell
# at 16 px from a size of 12.
build("TempleOS", 6, "TempleOS.ttf")
build("TempleOS Term", 8, "TempleOSTerm.ttf")
