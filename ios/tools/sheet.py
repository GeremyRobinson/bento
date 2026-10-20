# sheet.py <out.png> <in1.png> <in2.png> …: a contact sheet, two across, each labelled with its file name, so a set of
# screenshots can be looked at in one image. Needs Pillow (python3 -m pip install pillow).
import sys
from PIL import Image, ImageDraw
out, ins = sys.argv[1], sys.argv[2:]
W = 1376
tiles = []
for p in ins:
    im = Image.open(p).convert("RGB")
    im = im.resize((W, int(W * im.height / im.width)))
    ImageDraw.Draw(im).text((20, 20), p.split("/")[-1], fill=(200, 0, 0))
    tiles.append(im)
h = max(t.height for t in tiles)
rows = (len(tiles) + 1) // 2
sheet = Image.new("RGB", (2 * W + 10, rows * (h + 10)), "white")
for i, t in enumerate(tiles):
    sheet.paste(t, ((i % 2) * (W + 10), (i // 2) * (h + 10)))
sheet.save(out)
