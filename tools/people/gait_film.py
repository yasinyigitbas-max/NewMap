"""Lays out the panels of tests/people/gait_film.gd (p<panel>_<frame>.png) as a 3 x 2 grid with their titles, one
animated GIF at the film's own 25 fps, plus a still sheet of the first frame.
    python -I tools/people/gait_film.py OUT/gait_film review/people_20nov/gait_side_by_side.gif
    python -I tools/people/gait_film.py --mood OUT/mood_film review/people_20nov/mood_casual_angry.gif
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
MOOD_TITLES = ["Casual (Rocketbox mocap)", "Angry (Quaternius)"]
COLS, BAR, SCALE = 3, 30, 0.75


def main(src, dst, titles=TITLES, cols=COLS, scale=SCALE, step=1, colors=128):
    frames = sorted({int(os.path.basename(f)[3:6]) for f in glob.glob(os.path.join(src, "p0_*.png"))})
    first = Image.open(os.path.join(src, "p0_000.png"))
    w, h = int(first.width * scale), int(first.height * scale)
    rows = (len(titles) + cols - 1) // cols
    try:
        font = ImageFont.truetype("arial.ttf", 15)
    except OSError:
        font = ImageFont.load_default()
    out = []
    for k in frames[::step]:
        sheet = Image.new("RGB", (w * cols, (h + BAR) * rows), (24, 24, 26))
        d = ImageDraw.Draw(sheet)
        for i, title in enumerate(titles):
            x, y = (i % cols) * w, (i // cols) * (h + BAR)
            p = Image.open(os.path.join(src, "p%d_%03d.png" % (i, k))).convert("RGB").resize((w, h), Image.LANCZOS)
            sheet.paste(p, (x, y + BAR))
            d.text((x + 8, y + 7), title, fill=(235, 235, 235), font=font)
        out.append(sheet.quantize(colors=colors, method=Image.MEDIANCUT, dither=Image.NONE))
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    out[0].save(dst, save_all=True, append_images=out[1:], duration=40 * step, loop=0, optimize=True)
    out[0].convert("RGB").save(os.path.splitext(dst)[0] + "_still.png")
    print("GIF %d frames %dx%d -> %s (%.1f MB)" % (len(out), out[0].width, out[0].height, dst, os.path.getsize(dst) / 1e6))


if __name__ == "__main__":
    if "--mood" in sys.argv:   # (tests/people/mood_film.gd: two panels, casual and angry)
        a = [x for x in sys.argv[1:] if x != "--mood"]
        main(a[0], a[1], MOOD_TITLES, 2, 0.7, 2, 64)   # (12.5 fps, small: it is 19 s long)
    else:
        main(sys.argv[1], sys.argv[2])
