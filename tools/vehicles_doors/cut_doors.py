"""cut_doors.py <dump_prefix> <out_dir> <car>: cut an old car's front doors out of its body mesh, for real.

Reads the body mesh dumped by mesh_dump.gd (Godot frame: metres, Y up, front +Z, left +X). For each side, every
triangle of that side's outer skin is clipped exactly against the door's outline (a convex polygon drawn in the side
view, z forward / y up, from the panel gaps in the car's own AO map): the part inside becomes the door, the rest stays
on the body. Every new vertex takes its position, normal, tangent and both UV sets from the edge it was cut on, so the
paint, the gap lines and the car maps carry on across the cut. Then:
  - the door gets a thickness (an inner card 5 cm in, wound the other way) and an edge strip all round;
  - the body gets a jamb all round the opening (6 cm deep), so an open door shows a frame, not a paper edge;
  - the door is moved into its hinge's frame (hinge = its front edge, vertical axis): the game turns it about its origin.
New faces (card, strip, jamb) take one dark trim texel of the car's own trim sheet (a B-pillar texel) and its UV2.
Writes <car>_body, <car>_door_l, <car>_door_r (mesh_dump format) and <car>_doors.json (hinges, outlines, cabin box)."""
import sys, os, json
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import meshio
ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))

# ------------------------------------------------------------------ per car: the door outline and the cabin box
CARS = {
    'sakura': dict(
        # left front door, side view (z, y), convex, front edge first; the right door is its mirror
        door=[(0.71, 0.35), (0.71, 0.99), (0.66, 1.02), (0.18, 1.29), (-0.294, 1.34), (-0.224, 0.97), (-0.224, 0.35)],
        skin_x=0.50,        # a triangle belongs to a side's skin when its centre is further out than this
        hinge_z=0.71,
        card=0.05, jamb=0.06,
        dark=(-0.33, 1.15),  # (z, y) of a black B-pillar texel: the new faces take its UVs
        cabin=dict(lo=(-0.74, 0.34, -1.10), hi=(0.74, 1.20, 0.25)),   # the parallax cabin box (Godot frame)
        # the cabin seen through an open door: this side profile (z, y), from under the dash, along the windscreen, to the
        # back of the rear seat, extruded across the cabin's width (it fills the opening right to the hinge)
        hull=[(0.70, 0.34), (0.70, 0.96), (0.20, 1.22), (-1.10, 1.22), (-1.10, 0.34)], hull_x=0.74,
    ),
}

P = 0; NRM = 3; TAN = 6; UV = 10; UV2 = 12


def side_dot(a, b, c):
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def clip_half(poly, a, b, keep_left):
    """Sutherland-Hodgman against the line a->b in the (z, y) plane; poly = list of full vertex rows"""
    out = []
    n = len(poly)
    if n == 0:
        return out
    def ins(v):
        s = side_dot(a, b, (v[2], v[1]))
        return s >= 0 if keep_left else s <= 0
    for i in range(n):
        cur, nxt = poly[i], poly[(i + 1) % n]
        ci, ni = ins(cur), ins(nxt)
        if ci:
            out.append(cur)
        if ci != ni:
            sc = side_dot(a, b, (cur[2], cur[1]))
            sn = side_dot(a, b, (nxt[2], nxt[1]))
            t = sc / (sc - sn) if sc != sn else 0.0
            v = cur + (nxt - cur) * t
            for o, k in ((NRM, 3), (TAN, 3)):
                l = np.linalg.norm(v[o:o + k])
                if l > 1e-9:
                    v[o:o + k] /= l
            out.append(v)
    return out


def fan(poly):
    return [(poly[0], poly[i], poly[i + 1]) for i in range(1, len(poly) - 1)]


def main(dump, out_dir, car):
    if car in CARS:
        C = CARS[car]
    else:   # the Zhabotinsky cars: one entry each in doors_zh.json (outline, hinge, cabin box), their own colour map
        C = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'doors_zh.json')))[car]
        C.setdefault('skin_x', 0.5); C.setdefault('card', 0.05); C.setdefault('jamb', 0.06); C.setdefault('dark', (0.0, 0.6))
    j, V, I = meshio.read(dump)
    tris = V[I].reshape(-1, 3, V.shape[1])
    outline = C['door']
    # winding of the outline (as listed) in the (z, y) plane: inside = left of every edge if counter-clockwise
    area = sum(outline[i][0] * outline[(i + 1) % len(outline)][1] - outline[(i + 1) % len(outline)][0] * outline[i][1] for i in range(len(outline)))
    ccw = area > 0
    # the dark texel for new faces: the triangle nearest the given (z, y) on the left skin
    cz, cy = C['dark']
    cen = tris[:, :, :3].mean(1)
    # black plastic: a trim-sheet texel that is neither paint (alpha > 0.75) nor glass (0.3 .. 0.75) nor a lamp, and dark
    from PIL import Image
    tex = C.get('albedo') or os.path.join(ROOT, 'vehicles/models/cartex/trim_albedo.png')
    trim = np.asarray(Image.open(tex).convert('RGBA')).astype(np.float32) / 255
    th, tw = trim.shape[:2]
    uvc = tris[:, :, UV:UV + 2].mean(1)
    px = trim[np.clip((uvc[:, 1] % 1) * th, 0, th - 1).astype(int), np.clip((uvc[:, 0] % 1) * tw, 0, tw - 1).astype(int)]
    lum = px[:, :3].mean(1)
    ok = (px[:, 3] < 0.05) & (lum < 0.10)
    sel = np.where(ok)[0]
    if len(sel) == 0:
        raise SystemExit('no black trim texel found')
    k = sel[np.argmin((cen[sel, 2] - cz) ** 2 + (cen[sel, 1] - cy) ** 2)]
    print('dark texel: triangle', k, 'rgba', px[k].round(3), 'at', cen[k].round(2))
    dark_uv, dark_uv2 = tris[k, :, UV:UV + 2].mean(0), tris[k, :, UV2:UV2 + 2].mean(0)
    body, doors = [], {'l': [], 'r': []}
    for t in tris:
        c = t[:, :3].mean(0)
        sd = 'l' if c[0] > C['skin_x'] else ('r' if c[0] < -C['skin_x'] else None)
        if sd is None:
            body.append(t); continue
        # the outline of this side (the right door: the same outline, the skin mirrored in x only)
        inside = [v for v in t]
        rest = []
        for i in range(len(outline)):
            a, b = outline[i], outline[(i + 1) % len(outline)]
            outp = clip_half(inside, a, b, keep_left=not ccw)
            if len(outp) >= 3:
                rest.append(outp)
            inside = clip_half(inside, a, b, keep_left=ccw)
            if len(inside) < 3:
                inside = []
                break
        if inside:
            for tri in fan(inside):
                doors[sd].append(np.array(tri))
            for r in rest:
                for tri in fan(r):
                    body.append(np.array(tri))
        else:
            body.append(t)
    meta = {'metas': j['metas'], 'format': j['format']}
    info = {'car': car, 'doors': {}, 'cabin': C.get('cabin')}

    def new_vert(p, n):
        v = np.zeros(V.shape[1], np.float32)
        v[0:3] = p; v[3:6] = n
        tdir = np.cross(n, (0, 1, 0)); tl = np.linalg.norm(tdir)
        v[6:9] = tdir / tl if tl > 1e-6 else (1, 0, 0); v[9] = 1.0
        v[UV:UV + 2] = dark_uv; v[UV2:UV2 + 2] = dark_uv2
        return v

    def boundary(trs):
        """outer boundary edges of a triangle soup (positions rounded to 0.1 mm): (p, q) in the soup's winding"""
        cnt = {}
        key = lambda p: tuple(np.round(p, 4))
        for t in trs:
            for i in range(3):
                a, b = key(t[i][:3]), key(t[(i + 1) % 3][:3])
                e = (a, b) if a < b else (b, a)
                cnt.setdefault(e, []).append((t[i][:3], t[(i + 1) % 3][:3]))
        return [v[0] for v in cnt.values() if len(v) == 1]

    def on_outline(p, q, tol=0.006):
        """is the edge p-q on the door outline (side view)? (inner boundaries, round the glass or the mirror, are not)"""
        m = ((p[2] + q[2]) / 2, (p[1] + q[1]) / 2)
        best = 1e9
        for i in range(len(outline)):
            a, b = np.array(outline[i]), np.array(outline[(i + 1) % len(outline)])
            ab = b - a; t = np.clip(np.dot(np.array(m) - a, ab) / np.dot(ab, ab), 0, 1)
            best = min(best, np.linalg.norm(a + ab * t - np.array(m)))
        return best < tol

    for sd, s in (('l', 1.0), ('r', -1.0)):
        skin = doors[sd]
        if not skin:
            raise SystemExit('no door triangles on side ' + sd)
        inn = np.array([-s, 0.0, 0.0])
        # inner card: the skin pushed in, wound the other way, facing in
        card = [np.array([new_vert(v[:3] + inn * C['card'], -s * np.array([1.0, 0, 0])) for v in (t[0], t[2], t[1])]) for t in skin]
        strip = []
        rim = [(p, q) for p, q in boundary(skin) if on_outline(p, q)]
        for p, q in rim:
            p2, q2 = p + inn * C['card'], q + inn * C['card']
            e = q - p
            n = np.cross(e, inn); nl = np.linalg.norm(n); n = n / nl if nl > 1e-9 else inn
            strip.append(np.array([new_vert(x, n) for x in (p, q, q2)]))
            strip.append(np.array([new_vert(x, n) for x in (p, q2, p2)]))
        allf = skin + card + strip
        # the jamb on the body: round the opening, pushed in, facing into the opening
        for p, q in rim:
            p2, q2 = p + inn * C['jamb'], q + inn * C['jamb']
            e = q - p
            n = -np.cross(e, inn); nl = np.linalg.norm(n); n = n / nl if nl > 1e-9 else -inn
            body.append(np.array([new_vert(x, n) for x in (q, p, p2)]))
            body.append(np.array([new_vert(x, n) for x in (q, p2, q2)]))
        # hinge frame: front edge (largest z), the skin's outer x there, mid height of the outline
        pts = np.array([t[:, :3] for t in skin]).reshape(-1, 3)
        zmax = pts[:, 2].max()
        front = pts[pts[:, 2] > zmax - 0.03]
        hinge = np.array([front[:, 0].max() if s > 0 else front[:, 0].min(), (pts[:, 1].min() + pts[:, 1].max()) / 2, zmax])
        D = np.array(allf).reshape(-1, V.shape[1]).copy()
        D[:, 0:3] -= hinge
        meshio.write(os.path.join(out_dir, '%s_door_%s' % (car, sd)), D, np.arange(len(D)), meta)
        info['doors'][sd] = {'hinge': hinge.round(4).tolist(), 'axis': [0, 1, 0], 'opens': 'out', 'max_angle_deg': 68,
                             'tris': len(allf), 'skin_tris': len(skin), 'rim_edges': len(rim)}
        print('door', sd, 'skin', len(skin), 'rim edges', len(rim), 'all', len(allf), 'hinge', hinge.round(3))
    # the cabin hull: the profile extruded across x, faces outward (cabin_box.gdshader draws its inside: cull_front)
    hp = C.get('hull'); hx = C.get('hull_x', 0.7)
    if not hp:                       # (a car with a modelled cabin needs no hull)
        hp = None
    hull = []
    n = len(hp) if hp else 0
    area_h = sum(hp[i][0] * hp[(i + 1) % n][1] - hp[(i + 1) % n][0] * hp[i][1] for i in range(n)) if n else 0
    for i in range(n):
        (z0, y0), (z1, y1) = hp[i], hp[(i + 1) % n]
        e = np.array([0.0, y1 - y0, z1 - z0]); nn = np.cross(e, [1.0, 0, 0]) * (-1 if area_h > 0 else 1)
        nn = nn / np.linalg.norm(nn)
        a, b, c2, d = (hx, y0, z0), (hx, y1, z1), (-hx, y1, z1), (-hx, y0, z0)
        for tri in ((a, b, c2), (a, c2, d)):
            v = [new_vert(np.array(p), nn) for p in tri]
            if np.dot(np.cross(v[1][:3] - v[0][:3], v[2][:3] - v[0][:3]), nn) < 0:
                v = [v[0], v[2], v[1]]
            hull.append(np.array(v))
    for sx in ((1.0, -1.0) if n else ()):
        cap = [(sx * hx, y, z) for z, y in hp]
        for k in range(1, n - 1):
            v = [new_vert(np.array(p), np.array([sx, 0, 0])) for p in (cap[0], cap[k], cap[k + 1])]
            if np.dot(np.cross(v[1][:3] - v[0][:3], v[2][:3] - v[0][:3]), [sx, 0, 0]) < 0:
                v = [v[0], v[2], v[1]]
            hull.append(np.array(v))
    if hull:
        H = np.array(hull).reshape(-1, V.shape[1])
        meshio.write(os.path.join(out_dir, '%s_cabin' % car), H, np.arange(len(H)), {'metas': {}, 'format': j['format']})
    B = np.array(body).reshape(-1, V.shape[1])
    meshio.write(os.path.join(out_dir, '%s_body' % car), B, np.arange(len(B)), meta)
    info['body_tris'] = len(body)
    info['outline_left'] = outline
    json.dump(info, open(os.path.join(out_dir, '%s_doors.json' % car), 'w'), indent=1)
    print('body tris', len(body), '(was', len(I) // 3, ')')


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2], sys.argv[3])
