#!/usr/bin/env python3
"""LOD match review: EVERY building, one labelled row each, 8 rows a sheet (about 2048 px wide), plain background.
Row: near @60 m | mid BEFORE @60 m | mid AFTER @60 m || near @220 m | far BEFORE @220 m | far AFTER @220 m
at the phone's real pixel size at the switch (6.4 px/m at 60 m, 1.75 px/m at 220 m), blown up with square pixels (one
zoom per row, the 220 m ones 3.7x more) so they show what the phone gets. Same view for every tier. Before = git HEAD's tier files (glass:
the old mid had no ORM in game, so none here either); after = the files in the tree (glass from the page's alpha).
usage: sheets_all.py OUTDIR [--old=/tmp/lod_old] [--ck_old=/tmp/ck_dump] [--ck_new=/tmp/ck_dump_after] [--jobs=6]"""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np, glbr, lod_audit
from PIL import Image, ImageDraw, ImageFont
from multiprocessing import Pool
KIT = '/workspace/NewMap/assets/coronado_kit'
args = dict(a[2:].split('=', 1) for a in sys.argv[2:] if a.startswith('--') and '=' in a)
OUT = sys.argv[1]; OLD = args.get('old', '/tmp/lod_old'); CKO = args.get('ck_old', '/tmp/ck_dump'); CKN = args.get('ck_new', '/tmp/ck_dump_after')
CW, CH, LW = 300, 230, 150      # cell, label column
BG = (0.86, 0.86, 0.84)
REP = {}
for rf in ('lod_match.json', 'lod_match_b.json'):
    p = KIT + '/reports/' + rf
    if os.path.exists(p):
        for b in json.load(open(p))['buildings']: REP[b['name'].split('/')[-1]] = b

def fit(a, scale):
    """composed image -> CW x CH cell (scaled by `scale` with square pixels, centred, cropped if too big)"""
    im = glbr.to_img(a)
    if scale != 1: im = im.resize((max(1, round(im.width * scale)), max(1, round(im.height * scale))), Image.NEAREST)
    if im.width > CW or im.height > CH:
        k = min(CW / im.width, CH / im.height); im = im.resize((max(1, int(im.width * k)), max(1, int(im.height * k))), Image.LANCZOS)
    cell = Image.new('RGB', (CW, CH), tuple(int(c * 255) for c in BG)); cell.paste(im, ((CW - im.width) // 2, CH - im.height - 4))
    return cell

def row(item):
    n, t = item
    nm = n.split('/')[-1]
    try:
        near = glbr.load_any(t['near'])
        if n.startswith('ck/'):
            om, of = glbr.load_any(CKO + '/' + nm + '_mid.json'), glbr.load_any(CKO + '/' + nm + '_far.json')
            nmid, nfar = glbr.load_any(CKN + '/' + nm + '_mid.json'), glbr.load_any(CKN + '/' + nm + '_far.json')
        else:
            rel = lambda p: OLD + p[len('/workspace/NewMap'):]
            om, of = glbr.load_any(rel(t['mid'])), glbr.load_any(rel(t['far']))
            nmid, nfar = glbr.load_any(t['mid']), glbr.load_any(t['far'])
        for m in (nmid, nfar, om, of):
            if m.get('albedo') and os.path.basename(m['albedo']).startswith('bld_lod_color'): m['glass_alpha'] = True; m['orm'] = None
        az, el = 35, 16
        R, U, F = glbr.view_basis(az, el); P = near['P']
        b = ((P @ R).min() - 1, (P @ R).max() + 1, (P @ U).min() - 1, (P @ U).max() + 1)
        def r(m, ppm):
            rgb, a, _ = glbr.render(m, az, el, 12.8, b); return glbr.down(glbr.compose(rgb, a, BG), 12.8 / ppm)
        k = 6.4 / 1.75
        a60 = [r(near, 6.4), r(om, 6.4), r(nmid, 6.4)]; a220 = [r(near, 1.75), r(of, 1.75), r(nfar, 1.75)]
        # one zoom per row (square pixels, the same for all six) so a small house fills its cell like a tower
        z = max(1.0, min((CW - 8) / a60[0].shape[1], (CH - 8) / a60[0].shape[0]))
        z = float(int(z)) if z >= 2 else z
        cells = [fit(a, z) for a in a60] + [fit(a, k * z) for a in a220]
        err = None
    except Exception as e:
        cells = [Image.new('RGB', (CW, CH), (255, 200, 200))] * 6; err = str(e)[:60]
    W = LW + 6 * CW + 3 * 8 + 16
    im = Image.new('RGB', (W, CH + 8), (255, 255, 255)); dr = ImageDraw.Draw(im)
    f1 = ImageFont.load_default(size=17); f2 = ImageFont.load_default(size=13)
    grp = n.split('/')[0] if not n.startswith('examples') else 'modular/' + n.split('/')[0]
    dr.text((6, 8), nm, fill=(0, 0, 0), font=f1); dr.text((6, 30), grp, fill=(90, 90, 90), font=f2)
    rp = REP.get(nm)
    y = 54
    if rp:
        tb = rp['tris_before']
        for line in ('near %d' % tb['near'], 'mid %d -> %d' % (tb['mid'], rp['tris_mid']), 'far %d -> %d' % (tb['far'], rp['tris_far']),
                     'far budget %d' % rp['far_budget'], '%.2f px/m' % rp['dens']):
            dr.text((6, y), line, fill=(40, 40, 40), font=f2); y += 17
    if err: dr.text((6, y + 4), 'ERROR ' + err, fill=(200, 0, 0), font=f2)
    x = LW
    for i, c in enumerate(cells):
        im.paste(c, (x, 4)); x += CW + (16 if i == 2 else 8)
    return im

def header():
    W = LW + 6 * CW + 3 * 8 + 16
    im = Image.new('RGB', (W, 30), (40, 40, 40)); dr = ImageDraw.Draw(im); f = ImageFont.load_default(size=15)
    x = LW
    for i, s in enumerate(['near @ 60 m', 'mid BEFORE @ 60 m', 'mid AFTER @ 60 m', 'near @ 220 m', 'far BEFORE @ 220 m', 'far AFTER @ 220 m']):
        dr.text((x + 6, 7), s, fill=(255, 255, 255), font=f); x += CW + (16 if i == 2 else 8)
    return im

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    items = lod_audit.find(KIT)
    with Pool(int(args.get('jobs', 6))) as pool: rows = pool.map(row, items, chunksize=1)
    paths = []
    for k in range(0, len(rows), 8):
        part = [header()] + rows[k:k + 8]
        sh = Image.new('RGB', (part[0].width, sum(p.height for p in part)), (255, 255, 255)); y = 0
        for p in part: sh.paste(p, (0, y)); y += p.height
        path = os.path.join(OUT, 'sheet_%02d.png' % (k // 8 + 1)); sh.save(path); paths.append(path)
    json.dump({'sheets': paths, 'rows': [n for n, _ in items]}, open(os.path.join(OUT, 'index.json'), 'w'), indent=1)
    print(len(items), 'buildings,', len(paths), 'sheets')
