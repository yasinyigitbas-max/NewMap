"""UV island packing (shared by Blender build and compose). Deterministic."""
import json, math
ATLAS = 2048      # work resolution; ship colour 1024, normal + ORM 512
PAD = 8           # px at 2048 (4 px at 1024, 2 px at 512)

def pack(islands, used, atlas=ATLAS, pad=PAD):
    best = None
    for order in ('area', 'maxside', 'height', 'perim'):
        r = _pack(islands, used, atlas, pad, order)
        if best is None or r[0] > best[0]: best = r
    return best

def _pack(islands, used, atlas, pad, order):
    items = []
    for k in sorted(used):
        I = islands[k]
        items.append((k, I['w']*I['weight'], I['h']*I['weight'], I.get('minpx', (4, 4))))
    def try_scale(s):
        rects = {}
        R = []
        for k, w, h, mp in items:
            pw = max(mp[0], int(math.ceil(w*s))); ph = max(mp[1], int(math.ceil(h*s)))
            rot = False
            if ph > pw: pw, ph, rot = ph, pw, True
            if pw + 2*pad > atlas: return None
            R.append((k, pw, ph, rot))
        keys = dict(area=lambda r: (-(r[1]*r[2]), r[0]), maxside=lambda r: (-max(r[1], r[2]), -(r[1]*r[2]), r[0]),
                    height=lambda r: (-r[2], -r[1], r[0]), perim=lambda r: (-(r[1]+r[2]), r[0]))
        R.sort(key=keys[order])
        free = [(0, 0, atlas, atlas)]
        for k, pw0, ph0, rot0 in R:
            best = None
            for (pw, ph, rot) in ((pw0, ph0, rot0), (ph0, pw0, not rot0)):
                W, H = pw + 2*pad, ph + 2*pad
                for fx, fy, fw, fh in free:
                    if W <= fw and H <= fh:
                        sc = (min(fw-W, fh-H), max(fw-W, fh-H))
                        if best is None or sc < best[0]: best = (sc, fx, fy, W, H, pw, ph, rot)
            if best is None: return None
            _, fx, fy, W, H, pw, ph, rot = best
            rects[k] = dict(x=fx+pad, y=fy+pad, w=pw, h=ph, rot=rot)
            nf = []
            for f in free:
                x0, y0, w0, h0 = f
                if fx >= x0+w0 or fx+W <= x0 or fy >= y0+h0 or fy+H <= y0: nf.append(f); continue
                if fx > x0: nf.append((x0, y0, fx-x0, h0))
                if fx+W < x0+w0: nf.append((fx+W, y0, x0+w0-fx-W, h0))
                if fy > y0: nf.append((x0, y0, w0, fy-y0))
                if fy+H < y0+h0: nf.append((x0, fy+H, w0, y0+h0-fy-H))
            free = [a for a in nf if not any(a != b and b[0] <= a[0] and b[1] <= a[1] and a[0]+a[2] <= b[0]+b[2] and a[1]+a[3] <= b[1]+b[3] for b in nf)]
        return rects
    lo, hi = 50.0, 5000.0
    best = None
    for _ in range(22):
        mid = (lo+hi)/2
        r = try_scale(mid)
        if r: best, lo = (mid, r), mid
        else: hi = mid
    s, rects = best
    for k in rects: rects[k]['s'] = s
    return s, rects

def uv_of(rect, I, a, b, atlas=ATLAS):
    """island-local (a,b) metres -> (u,v) glTF/Blender UV (v up)"""
    fa = a / I['w']; fb = b / I['h']
    if not rect['rot']:
        px = rect['x'] + fa*rect['w']; py = rect['y'] + fb*rect['h']
    else:
        px = rect['x'] + fb*rect['w']; py = rect['y'] + fa*rect['h']
    return px/atlas, 1.0 - py/atlas
