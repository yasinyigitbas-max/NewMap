"""Lays out the panels of tests/people/gait_film.gd (p<panel>_<frame>.png) as a 3 x 2 grid with their titles, one
animated GIF at the film's own 25 fps, plus a still sheet of the first frame.
    python -I tools/people/gait_film.py OUT/gait_film review/people_20nov/gait_side_by_side.gif
"""
import glob
import os
import sys

from PIL import Image, ImageDraw, ImageFont

TITLES = [
    "Quaternius walk: game now, x1.74",
    "Quaternius walk: own speed",
    "Rocketbox walk: own speed",
    "Quaternius sprint: game now, x1.48",
    "Quaternius jog: own speed",
    "Rocketbox run: own speed",
]
COLS, BAR, SCALE = 3, 30, 0.75


def main(src, dst):
    frames = sorted({int(os.path.basename(f)[3:6]) for f in glob.glob(os.path.join(src, "p0_*.png"))})
    first = Image.open(os.path.join(src, "p0_000.png"))
    w, h = int(first.width * SCALE), int(first.height * SCALE)
    rows = (len(TITLES) + COLS - 1) // COLS
    try:
        font = ImageFont.truetype("arial.ttf", 15)
    except OSError:
        font = ImageFont.load_default()
    out = []
    for k in frames:
        sheet = Image.new("RGB", (w * COLS, (h + BAR) * rows), (24, 24, 26))
        d = ImageDraw.Draw(sheet)
        for i, title in enumerate(TITLES):
            x, y = (i % COLS) * w, (i // COLS) * (h + BAR)
            p = Image.open(os.path.join(src, "p%d_%03d.png" % (i, k))).convert("RGB").resize((w, h), Image.LANCZOS)
            sheet.paste(p, (x, y + BAR))
            d.text((x + 8, y + 7), title, fill=(235, 235, 235), font=font)
        out.append(sheet.quantize(colors=128, method=Image.MEDIANCUT, dither=Image.NONE))
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    out[0].save(dst, save_all=True, append_images=out[1:], duration=40, loop=0, optimize=True)
    out[0].convert("RGB").save(os.path.splitext(dst)[0] + "_still.png")
    print("GIF %d frames %dx%d -> %s (%.1f MB)" % (len(out), out[0].width, out[0].height, dst, os.path.getsize(dst) / 1e6))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
