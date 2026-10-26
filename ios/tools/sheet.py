# sheet.py <out.png> <in1.png> <in2.png> …: a contact sheet, two across, each labelled with its file name, so a set of
# screenshots can be looked at in one image. Needs Pillow (python3 -m pip install pillow).
import sys
from PIL import Image, ImageDraw, ImageFont
out, ins = sys.argv[1], sys.argv[2:]
W = 1376
# labels big enough to read on the sheet: the Mac's own font when there is one, on a plate
try: font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 30)
except OSError: font = ImageFont.load_default()
tiles = []
for p in ins:
    im = Image.open(p).convert("RGB")
    im = im.resize((W, int(W * im.height / im.width)))
    d, name = ImageDraw.Draw(im), p.split("/")[-1].rsplit(".", 1)[0]
    box = d.textbbox((20, 16), name, font=font)
    d.rectangle((box[0] - 8, box[1] - 6, box[2] + 8, box[3] + 6), fill=(255, 255, 255), outline=(200, 0, 0))
    d.text((20, 16), name, fill=(200, 0, 0), font=font)
    tiles.append(im)
h = max(t.height for t in tiles)
rows = (len(tiles) + 1) // 2
sheet = Image.new("RGB", (2 * W + 10, rows * (h + 10)), "white")
for i, t in enumerate(tiles):
    sheet.paste(t, ((i % 2) * (W + 10), (i // 2) * (h + 10)))
sheet.save(out)
