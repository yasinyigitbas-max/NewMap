import os as _os
def _w(p):      # (hard links into other trees: delete, then write)
    if _os.path.exists(p): _os.remove(p)
    return open(p, 'w')

"""Slot layouts for every built-in bay x kind (22 Nov 2026 rollout). Per bay (bays.json) and each kind it furnishes,
2-3 templates that differ in logic (A: counter / front at the back wall; B: counter along a side wall or desks at the
back; C: a third arrangement where the room is big enough), each a full slot table in the bay frame (model frame):
[name, slot_type, variant, x, z, yaw_deg (kit front +Z goes there), lift (wall things: centre height), on (host slot for
till / top)]. Footprints are the largest prop of the slot type in the kind's set, so any variant / decor set fits.
Checked here: inside the floor, no two footprints overlap, the door's entry zone and a 0.9 m path to the back stay
clear, wall things stand at a wall facing into the room, seats face what they serve, the prop tri cap (25k).
Writes interiors/builtin/layouts.json; prints a summary. Mirror (x -> 2c - x, yaw -> -yaw) is applied at fill time
and checked by validate_bays.gd."""
import json, glob, math, os, sys, collections
REPO = '/workspace/NewMap'; R = REPO + '/map_dc/coronado/city_kit/interiors/'
B = json.load(open(R + 'builtin/bays.json'))['models']
S = json.load(open(R + 'builtin/furniture_sets.json'))['sets']
import sys, os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); import contracts; con = contracts.load(R)
man = {}
for m in glob.glob(REPO + '/assets/coronado_kit/props/manifest_*.json'):
    for k, v in json.load(open(m)).items(): man[k] = v
for k, d in [('vending_snack', (0.9, 0.8, 1.8)), ('vending_soda', (0.9, 0.8, 1.8)), ('ice_chest', (1.2, 0.7, 1.0))]:
    man.setdefault(k, dict(mount='ground', footprint_w=d[0], footprint_d=d[1], height=d[2], tiers={'near': 900}))
WALLT = {'decor', 'board'}
CAP = 25000
def dims(kind, t):
    ws = [(float(man[p].get('footprint_w', 1)), float(man[p].get('footprint_d', 1)), float(man[p].get('height', 1))) for p in S[kind].get(t, []) if p in man]
    if not ws: return (0.5, 0.5, 1.0)
    return (max(w for w, d, h in ws), max(d for w, d, h in ws), max(h for w, d, h in ws))
def tris(kind, t, v):
    l = S[kind].get(t, []); p = l[v % len(l)] if l else None
    return int(man.get(p, {}).get('tiers', {}).get('near', 600)) if p else 0
class Room:
    def __init__(s, kind, X0, X1, ZB, ZF, da, dw, side_wins):
        s.k = kind; s.X0, s.X1, s.ZB, s.ZF, s.da, s.dw = X0, X1, ZB, ZF, da, dw
        s.W = X1 - X0; s.D = ZF - ZB; s.slots = []; s.rects = []; s.n = collections.Counter(); s.side_wins = side_wins
        s.clear = [(da - dw / 2 - 0.45, ZF - 1.9, da + dw / 2 + 0.45, ZF + 1)]      # entry zone
        s.tri = 0
    def has(s, t): return bool(S[s.k].get(t))
    def fp(s, t, yaw):
        w, d, h = dims(s.k, t)
        return (d, w) if abs(math.sin(math.radians(yaw))) > 0.7 else (w, d)
    def free(s, r, gap=0.08, clear=True):
        x0, z0, x1, z1 = r
        if x0 < s.X0 + 0.04 or x1 > s.X1 - 0.04 or z0 < s.ZB + 0.04 or z1 > s.ZF - 0.04: return False
        for q in s.rects + (s.clear if clear else []):
            if x0 < q[2] + gap and x1 > q[0] - gap and z0 < q[3] + gap and z1 > q[1] - gap: return False
        return True
    def put(s, t, x, z, yaw, lift=0.0, on='', var=None, clear=True, front_gap=0.0):
        if not s.has(t): return None
        if t in ('till', 'top'):
            if not on: return None
            v = s.n[t] if var is None else var
            if s.tri + tris(s.k, t, v) > CAP - 2500 and t == 'top': return None
            nm = '%s_%d' % (t, s.n[t] + 1); s.n[t] += 1
            s.slots.append([nm, t, v % len(S[s.k][t]), round(x, 3), round(z, 3), yaw, lift, on]); s.tri += tris(s.k, t, v); return nm
        if t in WALLT:
            w = dims(s.k, t)[0]; r = (x - w / 2, z - 0.05, x + w / 2, z + 0.05) if abs(math.sin(math.radians(yaw))) < 0.7 else (x - 0.05, z - w / 2, x + 0.05, z + w / 2)
            for q in [q for q in s.slots if q[1] in WALLT]:
                if abs(q[3] - x) < w and abs(q[4] - z) < w: return None
        else:
            w, d = s.fp(t, yaw)
            # usable side: front_gap of free floor in front of the prop (its +Z after yaw)
            fx, fz = math.sin(math.radians(yaw)), math.cos(math.radians(yaw))
            r = (x - w / 2, z - d / 2, x + w / 2, z + d / 2)
            if not s.free(r, clear=clear): return None
            if front_gap > 0:
                dd = (d if abs(fz) > 0.7 else w) / 2
                rr = (x + fx * (dd + front_gap / 2) - (w / 2 if abs(fz) > 0.7 else front_gap / 2), z + fz * (dd + front_gap / 2) - (front_gap / 2 if abs(fz) > 0.7 else w / 2),
                      x + fx * (dd + front_gap / 2) + (w / 2 if abs(fz) > 0.7 else front_gap / 2), z + fz * (dd + front_gap / 2) + (front_gap / 2 if abs(fz) > 0.7 else w / 2))
                if not s.free(rr, gap=0.0, clear=False): return None
            s.rects.append(r)
        v = s.n[t] if var is None else var
        t_tri = tris(s.k, t, v)
        if s.tri + t_tri > CAP - 2500 and t != 'staff' and not ((t in S[s.k].get('required', []) or t in ('counter', 'desk', 'front')) and s.n[t] < 2): 
            if t not in WALLT: s.rects.pop()
            return None
        nm = '%s_%d' % (t, s.n[t] + 1); s.n[t] += 1
        s.slots.append([nm, t, v % len(S[s.k][t]), round(x, 3), round(z, 3), yaw, lift, on]); s.tri += t_tri
        return nm
    # ---- helpers
    def wall_run(s, t, side, a0, a1, step=None, yaw=None, inset=0.0, tall_ok=True):
        """items of type t against a wall: side L (x = X0), R (x = X1), B (z = ZB); a0..a1 along the wall"""
        w, d, h = dims(s.k, t)
        if side == 'L': yaw = 90
        elif side == 'R': yaw = -90
        else: yaw = 0
        step = step or (w + 0.12)
        a = a0 + w / 2; out = []
        while a + w / 2 <= a1 + 1e-6:
            if side in 'LR' and h > 1.0 and not tall_ok: break
            if side in 'LR' and h > 0.9 and any(abs(a - wz) < ww / 2 + w / 2 for wz, ww, y0 in s.side_wins.get(side, []) if y0 < h): a += 0.25; continue
            x = s.X0 + d / 2 + 0.06 + inset if side == 'L' else s.X1 - d / 2 - 0.06 - inset if side == 'R' else a
            z = a if side in 'LR' else s.ZB + d / 2 + 0.06 + inset
            nm = s.put(t, x, z, yaw, front_gap=0.7)
            if nm: out.append(nm); a += step
            else: a += 0.3
        return out
    def decor_run(s, side, a0, a1, lift=1.6, every=2.2, t='decor'):
        if not s.has(t): return
        a = a0 + 0.6
        while a < a1 - 0.6:
            if side == 'L': nm = s._wall_decor(t, s.X0 + 0.04, a, 90, lift)
            elif side == 'R': nm = s._wall_decor(t, s.X1 - 0.04, a, -90, lift)
            else: nm = s._wall_decor(t, a, s.ZB + 0.04, 0, lift)
            a += every
    def _wall_decor(s, t, x, z, yaw, lift):
        # not above a tall prop at that wall, not over a side window
        w, d, h = dims(s.k, t)
        for q in s.slots:
            if q[1] in WALLT: continue
            qh = dims(s.k, q[1])[2]
            if qh > lift - h / 2 - 0.05 and abs(q[3] - x) < 0.9 and abs(q[4] - z) < 0.9: return None
        side = 'L' if yaw == 90 else 'R' if yaw == -90 else 'B'
        if side in 'LR' and any(abs(z - wz) < ww / 2 + w / 2 + 0.1 for wz, ww, y0 in s.side_wins.get(side, [])): return None
        return s.put(t, x, z, yaw, lift)
    def table_group(s, x, z, seats=4):
        tw, td, _ = dims(s.k, 'table')
        if not s.free((x - tw / 2 - 0.55, z - td / 2 - 0.55, x + tw / 2 + 0.55, z + td / 2 + 0.55)): return False
        tn = s.put('table', x, z, 0)
        if not tn: return False
        if 'folding_table_chairs' in S[s.k].get('table', []) or not s.has('seat'): return True
        for (dx, dz, yaw) in [(0, -(td / 2 + 0.32), 0), (0, td / 2 + 0.32, 180), (-(tw / 2 + 0.32), 0, 90), (tw / 2 + 0.32, 0, -90)][:seats]:
            s.put('seat', x + dx, z + dz, yaw, clear=True)
        return True
def counter_back(r, x=None, along_side=False):
    """the counter across the back zone (A) facing the front; back items on the wall behind; till on it"""
    cw, cd, _ = dims(r.k, 'counter')
    x = r.X0 + r.W / 2 if x is None else x
    z = r.ZB + 1.25 + cd / 2
    if r.D < 5.0: z = r.ZB + 0.9 + cd / 2
    c = r.put('counter', x, z, 0)
    if not c: return None
    r.put('till', x + cw * 0.25, z, 0, on=c)
    bw = dims(r.k, 'back')[0]
    n = 0; a = x - cw / 2
    for off in [0, -1, 1, -2, 2]:
        bx = x + off * (bw + 0.15)
        if r.put('back', bx, r.ZB + dims(r.k, 'back')[1] / 2 + 0.06, 0, lift=1.55 if man.get(S[r.k].get('back', ['x'])[0], {}).get('mount') == 'wall' else 0.0): n += 1
        if n >= 3: break
    return c
def counter_side(r, side='L'):
    """the counter along a side wall near the front (B): staff between it and the wall, customers on the room side"""
    cw, cd, _ = dims(r.k, 'counter')
    zc = r.ZF - 2.2 - cw / 2
    if zc - cw / 2 < r.ZB + 0.3: zc = r.ZB + 0.3 + cw / 2
    yaw = 90 if side == 'L' else -90
    x = r.X0 + 1.1 + cd / 2 if side == 'L' else r.X1 - 1.1 - cd / 2
    c = r.put('counter', x, zc, yaw)
    if not c: return None
    r.put('till', x, zc + cw * 0.25, yaw, on=c)
    bw = dims(r.k, 'back')
    for off in [0, -1, 1]:
        bz = zc + off * (bw[0] + 0.15)
        bx = r.X0 + bw[1] / 2 + 0.06 if side == 'L' else r.X1 - bw[1] / 2 - 0.06
        r.put('back', bx, bz, yaw, lift=1.55 if man.get(S[r.k].get('back', ['x'])[0], {}).get('mount') == 'wall' else 0.0)
    return c
def islands(r, z0, z1, cols=None, yaw=0, spine=True):
    w, d = r.fp('island', yaw)
    ax = 1.0      # aisle
    xs = []; x = r.X0 + 1.0 + w / 2
    while x + w / 2 <= r.X1 - 1.0: xs.append(x); x += w + ax
    z = z0 + d / 2
    while z + d / 2 <= z1:
        for x in xs:
            if spine and abs(x - r.da) < w / 2 + 0.45: continue
            r.put('island', x, z, yaw)
        z += d + 1.1
def big_items(r, z0, z1):
    w, d = r.fp('big', 0)
    x = r.X0 + 1.0 + w / 2
    while x + w / 2 < r.X1 - 1.0:
        r.put('big', x, (z0 + z1) / 2, 0); x += w + 1.2
def finish(r, front_z=None):
    """decor on the side / back walls, a plant in a front corner, a bin by the door, waiting by the front"""
    r.decor_run('L', r.ZB, r.ZF - 0.5); r.decor_run('R', r.ZB, r.ZF - 0.5); r.decor_run('B', r.X0, r.X1)
    for (x, z) in [(r.X0 + 0.4, r.ZF - 0.45), (r.X1 - 0.4, r.ZF - 0.45), (r.X0 + 0.4, r.ZB + 0.4), (r.X1 - 0.4, r.ZB + 0.4)]:
        if r.n['plant'] >= (2 if r.W * r.D > 120 else 1): break
        r.put('plant', x, z, 90 if x < r.da else -90)
    for (x, z) in [(r.da - r.dw / 2 - 0.75, r.ZF - 0.3), (r.da + r.dw / 2 + 0.75, r.ZF - 0.3)]:
        if r.put('bin', x, z, 180): break
    if r.has('waiting'):
        ww, wd, _ = dims(r.k, 'waiting')
        for side in ('L', 'R'):
            if r.n['waiting'] >= 2: break
            x = r.X0 + wd / 2 + 0.05 if side == 'L' else r.X1 - wd / 2 - 0.05
            r.put('waiting', x, r.ZF - 1.0 - ww / 2, 90 if side == 'L' else -90)
    if r.has('top'):
        for q in list(r.slots):
            if q[1] in ('counter', 'table', 'back', 'front') and r.n['top'] < 3 and q[1] != 'back':
                w, d, h = dims(r.k, q[1])
                r.put('top', q[3] - (w * 0.3 if abs(math.sin(math.radians(q[5]))) < 0.7 else 0), q[4] - (w * 0.3 if abs(math.sin(math.radians(q[5]))) > 0.7 else 0), q[5], on=q[0])
    if r.has('queue'):
        cs = [q for q in r.slots if q[1] in ('counter', 'till')]
        if cs:
            c = cs[0]
            for i in range(2): r.put('queue', c[3] - 0.9 + 1.8 * i, c[4] + 1.2, 0)
def desks(r, side, z0, z1, n_max=6):
    """desks against a side wall: user chair between desk and wall facing it, visitor on the room side facing it"""
    dw_, dd, _ = dims(r.k, 'desk')
    yaw = -90 if side == 'L' else 90       # desk front (screen) toward its user at the wall
    z = z0 + dw_ / 2; n = 0
    while z + dw_ / 2 <= z1 and n < n_max:
        xd = r.X0 + 0.95 + dd / 2 if side == 'L' else r.X1 - 0.95 - dd / 2
        if r.free((xd - dd / 2 - 0.9, z - dw_ / 2, xd + dd / 2 + 0.9, z + dw_ / 2)) and r.put('desk', xd, z, yaw):
            xs = r.X0 + 0.5 if side == 'L' else r.X1 - 0.5
            r.put('staff', xs, z, -yaw)
            r.put('visitor', xd + (dd / 2 + 0.45) * (1 if side == 'L' else -1), z, yaw)
            n += 1; z += dw_ + 0.9
        else: z += 0.4
    return n
def desks_back(r, x0, x1):
    dw_, dd, _ = dims(r.k, 'desk'); x = x0 + dw_ / 2; n = 0
    while x + dw_ / 2 <= x1:
        zd = r.ZB + 0.95 + dd / 2
        if r.free((x - dw_ / 2, zd - dd / 2 - 0.9, x + dw_ / 2, zd + dd / 2 + 0.9)) and r.put('desk', x, zd, 180):
            r.put('staff', x, r.ZB + 0.5, 0); r.put('visitor', x, zd + dd / 2 + 0.45, 180); n += 1; x += dw_ + 0.8
        else: x += 0.4
    return n
def rows(r, z0, z1, aisles=1):
    """seat rows facing the back wall (front): blocks either side of the aisle(s), 0.85 m from the side walls"""
    w, d, _ = dims(r.k, 'row'); pitch = d + 0.45 if d < 0.8 else d + 0.5
    if aisles == 1: blocks = [(r.X0 + 0.9, r.da - 0.6), (r.da + 0.6, r.X1 - 0.9)]
    else:
        t = (r.X1 - r.X0 - 1.8 - 2.4) / 3
        a = r.X0 + 0.9; blocks = [(a, a + t), (a + t + 1.2, a + 2 * t + 1.2), (a + 2 * t + 2.4, r.X1 - 0.9)]
    z = z0 + d / 2
    while z + d / 2 <= z1:
        for (b0, b1) in blocks:
            x = b0 + w / 2
            while x + w / 2 <= b1 + 1e-6:
                r.put('row', x, z, 180); x += w + 0.04
        z += pitch
def front(r):
    fw, fd, _ = dims(r.k, 'front')
    f = r.put('front', r.da if r.X0 + fw / 2 + 0.3 < r.da < r.X1 - fw / 2 - 0.3 else r.X0 + r.W / 2, r.ZB + 1.0 + fd / 2, 0)
    if f and r.has('board'): r.put('board', r.X0 + r.W / 2, r.ZB + 0.04, 0, lift=1.5)
    return f
def stations(r, side, z0, z1):
    sw, sd, _ = dims(r.k, 'station'); mw = dims(r.k, 'shelf')[0] if r.has('shelf') else 1.0
    yaw_w = 90 if side == 'L' else -90
    z = z0 + max(sw, mw) / 2; n = 0
    while z + max(sw, mw) / 2 <= z1:
        xm = r.X0 + 0.22 if side == 'L' else r.X1 - 0.22
        xs = r.X0 + 0.5 + sd / 2 + 0.25 if side == 'L' else r.X1 - 0.5 - sd / 2 - 0.25
        if r.free((r.X0 + 0.05 if side == 'L' else xs - sd / 2, z - max(sw, mw) / 2, xs + sd / 2 if side == 'L' else r.X1 - 0.05, z + max(sw, mw) / 2)):
            if r.has('shelf'): r.put('shelf', xm, z, yaw_w)
            r.put('station', xs, z, -yaw_w); n += 1
        z += max(sw, mw) + 0.35
    return n
# ------------------------------------------------------------------ templates per archetype
def T_retail(r, t):
    if t == 'A':
        counter_back(r)
        r.wall_run('shelf', 'L', r.ZB + 0.3, r.ZF - 1.0); r.wall_run('shelf', 'R', r.ZB + 0.3, r.ZF - 1.0)
        if r.has('big') and r.W * r.D > 90: big_items(r, r.ZB + 2.8, r.ZF - 2.2)
        islands(r, r.ZB + 3.0, r.ZF - 2.2)
    elif t == 'B':
        side = 'R' if r.da < r.X0 + r.W / 2 else 'L'
        counter_side(r, side)
        r.wall_run('shelf', 'B', r.X0 + 0.3, r.X1 - 0.3); r.wall_run('shelf', 'L' if side == 'R' else 'R', r.ZB + 0.9, r.ZF - 1.0)
        if r.has('big') and r.W * r.D > 90: big_items(r, r.ZB + 1.5, r.ZF - 2.4)
        islands(r, r.ZB + 1.6, r.ZF - 2.4, yaw=90 if r.W > 7 else 0)
    else:
        counter_back(r, x=r.X0 + min(2.2, r.W / 3))
        r.wall_run('shelf', 'R', r.ZB + 0.3, r.ZF - 1.0); r.wall_run('shelf', 'B', r.X0 + r.W / 2, r.X1 - 0.3)
        islands(r, r.ZB + 2.6, r.ZF - 2.2, yaw=90, spine=True)
    finish(r)
def T_aisles(r, t):
    if t == 'A':
        side = 'R' if r.da < r.X0 + r.W / 2 else 'L'
        counter_side(r, side)
        r.wall_run('shelf', 'B', r.X0 + 0.3, r.X1 - 0.3); r.wall_run('shelf', 'L' if side == 'R' else 'R', r.ZB + 0.9, r.ZF - 1.0)
        islands(r, r.ZB + 1.6, r.ZF - 2.6, yaw=90)
    else:
        counter_back(r)
        r.wall_run('shelf', 'L', r.ZB + 0.3, r.ZF - 1.0); r.wall_run('shelf', 'R', r.ZB + 0.3, r.ZF - 1.0)
        islands(r, r.ZB + 3.0, r.ZF - 2.4, yaw=0)
    finish(r)
def T_seating(r, t):
    tw, td, _ = dims(r.k, 'table')
    if t == 'A':
        counter_back(r)
        r.wall_run('shelf', 'R', r.ZB + 0.3, r.ZB + 3.0)
        if r.has('booth'):
            bw, bd, _ = dims(r.k, 'booth'); z = r.ZB + 3.2
            while z + 2 * bd + td < r.ZF - 1.2:
                x = r.X0 + bw / 2 + 0.03
                if r.free((r.X0, z, r.X0 + bw + 0.1, z + 2 * bd + td + 0.1)):
                    r.put('booth', x, z + bd / 2, 0); r.put('table', x, z + bd + td / 2 + 0.02, 0); r.put('booth', x, z + 1.5 * bd + td + 0.04, 180)
                z += 2 * bd + td + 0.5
        z = r.ZB + 3.6
        while z < r.ZF - 1.4:
            x = r.X0 + (2.4 if r.has('booth') else 1.2) + tw / 2
            while x < r.X1 - 1.0: r.table_group(x, z, 4 if r.W > 6 else 2); x += tw + 1.7
            z += td + 1.8
    elif t == 'B':
        side = 'L' if r.da > r.X0 + r.W / 2 else 'R'
        counter_side(r, side)
        cs = [q for q in r.slots if q[1] == 'counter']
        if cs and r.has('seat'):
            c = cs[0]; cw = dims(r.k, 'counter')[0]; cd = dims(r.k, 'counter')[1]
            sx = c[3] + (cd / 2 + 0.35) * (1 if side == 'L' else -1)
            for i in range(3): r.put('seat', sx, c[4] - cw / 3 + i * cw / 3, -90 if side == 'L' else 90)
        z = r.ZB + 1.2
        while z < r.ZF - 1.4:
            x = (r.X1 - 1.0 - tw / 2) if side == 'L' else (r.X0 + 1.0 + tw / 2)
            r.table_group(x, z, 2 if r.W < 7 else 4); z += td + 1.6
        r.wall_run('shelf', 'B', r.X0 + 0.3, r.X1 - 0.3)
    else:
        counter_back(r, x=r.X1 - min(2.2, r.W / 3))
        z = r.ZB + 3.4
        while z < r.ZF - 1.4:
            for x in (r.X0 + 1.0 + tw / 2, r.X0 + r.W / 2 - 0.3):
                r.table_group(x, z, 2)
            z += td + 1.5
    finish(r)
def T_office(r, t):
    if t == 'A':
        if r.has('counter'): counter_back(r)
        n = desks(r, 'L', r.ZB + 0.6, r.ZF - 2.2)
        if r.has('desk') and not n or r.W > 7: desks(r, 'R', r.ZB + 0.6, r.ZF - 2.2)
        r.wall_run('shelf', 'B', r.X0 + 0.3, r.X1 - 0.3)
    else:
        n = desks_back(r, r.X0 + 0.6, r.X1 - 0.6)
        if r.has('counter'): counter_side(r, 'R' if r.da < r.X0 + r.W / 2 else 'L')
        if not n: desks(r, 'L', r.ZB + 0.6, r.ZF - 2.2)
        r.wall_run('shelf', 'L', r.ZB + 2.6, r.ZF - 2.0); r.wall_run('shelf', 'R', r.ZB + 2.6, r.ZF - 2.0)
    finish(r)
def T_rows(r, t):
    front(r)
    if r.has('desk'): desks_back(r, r.X0 + 0.6, r.X0 + 0.6 + 2.6) if t == 'A' else desks_back(r, r.X1 - 3.2, r.X1 - 0.6)
    if r.has('counter') and r.W * r.D > 60: r.put('counter', r.X1 - 1.6, r.ZB + 1.6, -90)
    rows(r, r.ZB + 3.0, r.ZF - 2.0, aisles=1 if (t == 'A' or r.W < 9) else 2)
    r.wall_run('shelf', 'L', r.ZB + 0.3, r.ZB + 2.4)
    finish(r)
def T_stations(r, t):
    if t == 'A':
        side = 'R' if r.da < r.X0 + r.W / 2 else 'L'
        counter_side(r, side)
        stations(r, 'L' if side == 'R' else 'R', r.ZB + 0.6, r.ZF - 1.6)
        r.wall_run('back', 'B', r.X0 + 0.3, r.X1 - 0.3)
    else:
        counter_back(r)
        stations(r, 'L', r.ZB + 2.6, r.ZF - 1.8); stations(r, 'R', r.ZB + 2.6, r.ZF - 1.8)
    finish(r)
def T_machines(r, t):
    if t == 'A': counter_back(r)
    else: counter_side(r, 'R' if r.da < r.X0 + r.W / 2 else 'L')
    r.wall_run('shelf', 'L', r.ZB + 0.3, r.ZF - 1.2); r.wall_run('shelf', 'R', r.ZB + 0.3, r.ZF - 1.2)
    islands(r, r.ZB + 3.0, r.ZF - 2.4, yaw=90)
    finish(r)
ARCH = dict(retail=T_retail, aisles=T_aisles, seating=T_seating, office=T_office, rows=T_rows, stations=T_stations, machines=T_machines)
def side_windows(c, X0, X1, ZB, ZF):
    out = {'L': [], 'R': []}
    for o in c['openings']:
        if int(o['floor']) != 0: continue
        if o['facade'] == 'left' and X0 <= c['floors'][0]['box_min'][0] + 0.35: out['L'].append((float(o['along']), float(o['w']), float(o['y0'])))
        if o['facade'] == 'right' and X1 >= c['floors'][0]['box_max'][0] - 0.35: out['R'].append((float(o['along']), float(o['w']), float(o['y0'])))
    return out
def fill_space(r):
    """big rooms: the empty middle gets a grid of what the kind has (floor stock, else tables, else waiting rows)"""
    if r.W * r.D < 100: return
    if r.has('island'): islands(r, r.ZB + 2.0, r.ZF - 2.2, yaw=0)
    if r.has('table'):
        tw, td, _ = dims(r.k, 'table'); z = r.ZB + 2.4
        while z < r.ZF - 2.0:
            x = r.X0 + 1.6 + tw / 2
            while x < r.X1 - 1.6: r.table_group(x, z, 4); x += tw + 1.8
            z += td + 1.9
    elif r.has('waiting'):
        ww, wd, _ = dims(r.k, 'waiting'); z = r.ZB + 3.0
        while z < r.ZF - 2.6:
            x = r.X0 + 2.0 + ww / 2
            while x < r.X1 - 2.0:
                if abs(x - r.da) > ww / 2 + 0.6: r.put('waiting', x, z, 0); r.put('waiting', x, z - wd - 0.05, 180)
                x += ww + 1.2
            z += 2 * wd + 1.4
def fill_required(r):
    have = lambda t: any(q[1] == t for q in r.slots)
    if r.has('counter') and not have('counter'):
        counter_back(r) or counter_side(r, 'L') or counter_side(r, 'R')
    if r.has('front') and not have('front'): front(r)
    if r.has('row') and not have('row'): rows(r, r.ZB + 2.6, r.ZF - 2.0)
    if r.has('desk') and not have('desk'):
        desks(r, 'L', r.ZB + 0.5, r.ZF - 2.0, 2) or desks(r, 'R', r.ZB + 0.5, r.ZF - 2.0, 2) or desks_back(r, r.X0 + 0.5, r.X1 - 0.5)
    if r.has('station') and not have('station'):
        stations(r, 'L', r.ZB + 0.5, r.ZF - 1.6) or stations(r, 'R', r.ZB + 0.5, r.ZF - 1.6)
    if r.has('table') and not have('table'):
        tw, td, _ = dims(r.k, 'table'); z = r.ZB + 2.0
        while z < r.ZF - 2.0 and not have('table'):
            x = r.X0 + 1.0 + tw / 2
            while x < r.X1 - 1.0 and not have('table'):
                r.table_group(x, z, 4); x += 0.5
            z += 0.5
        for side in ('L', 'R'):      # against a side wall, seats at its two ends
            z = r.ZB + 1.5
            while z < r.ZF - 2.0 and not have('table'):
                x = r.X0 + td / 2 + 0.05 if side == 'L' else r.X1 - td / 2 - 0.05
                if r.free((x - td / 2, z - tw / 2 - 0.55, x + td / 2, z + tw / 2 + 0.55)) and r.put('table', x, z, 90):
                    if r.has('seat') and 'folding_table_chairs' not in S[r.k]['table']:
                        r.put('seat', x, z - tw / 2 - 0.3, 0); r.put('seat', x, z + tw / 2 + 0.3, 180)
                z += 0.5
def required_ok(r):
    have = {q[1] for q in r.slots}
    return [t for t in S[r.k].get('required', []) if t not in have]
OUT = {}; report = []; fails = []
for m, M in sorted(B.items()):
    c = con[m]
    for b in M['bays']:
        X0, X1 = b['s0'] + 0.0, b['s1'] - 0.0; ZB, ZF = M['box_min'][2], M['box_max'][2]
        sw = side_windows(c, X0, X1, ZB, ZF)
        for k in b['kinds']:
            if k not in S: fails.append('%s bay %d: no set %s' % (m, b['i'], k)); continue
            arch = S[k]['archetype']; temps = {}
            for t in ('A', 'B', 'C'):
                if t == 'C' and (X1 - X0) * (ZF - ZB) < 90: continue
                r = Room(k, X0, X1, ZB, ZF, b['door_along'], b['door_w'], sw)
                ARCH[arch](r, t)
                fill_required(r)
                fill_space(r)
                for tt in ('top', 'decor', 'island', 'shelf', 'waiting', 'big', 'plant'):      # trim to the cap (Yasin: budgets are maximums)
                    while r.tri > CAP and any(q[1] == tt for q in r.slots):
                        q = [q for q in r.slots if q[1] == tt][-1]
                        if any(p[7] == q[0] for p in r.slots): break
                        r.slots.remove(q); r.tri -= tris(k, tt, q[2])
                miss = required_ok(r)
                if miss: report.append('%s bay %d %s %s: template %s dropped (no %s)' % (m, b['i'], k, arch, t, miss)); continue
                sig = sorted((q[1], q[3], q[4], q[5]) for q in r.slots)
                if any(sorted((q[1], q[3], q[4], q[5]) for q in x['slots']) == sig for x in temps.values()): continue
                cx = (X0 + X1) / 2; mok = True      # mirror (x -> 2c - x): only if the door's entry zone and spine stay clear
                for q in r.slots:
                    if q[1] in WALLT or q[1] in ('till', 'top'): continue
                    w, d = r.fp(q[1], q[5]); mx = 2 * cx - q[3]
                    for c0 in r.clear:
                        if mx - w / 2 < c0[2] and mx + w / 2 > c0[0] and q[4] - d / 2 < c0[3] and q[4] + d / 2 > c0[1]: mok = False
                temps[t] = dict(slots=r.slots, tris=r.tri, mirror_ok=mok)
            if not temps: fails.append('%s bay %d %s (%s, %.1f x %.1f m): no template fits' % (m, b['i'], k, arch, X1 - X0, ZF - ZB))
            OUT.setdefault(m, {}).setdefault(str(b['i']), {})[k] = temps
json.dump(dict(rect_note='bay frame = model frame; X0..X1 = bay s0..s1, ZB..ZF = floor box z', layouts=OUT), _w(R + 'builtin/layouts.json'), indent=0)
nt = sum(len(t) for mm in OUT.values() for bb in mm.values() for t in bb.values())
ns = sum(len(x['slots']) for mm in OUT.values() for bb in mm.values() for t in bb.values() for x in t.values())
print('bay-kinds', sum(len(bb) for mm in OUT.values() for bb in mm.values()), 'templates', nt, 'slots', ns)
print('one template only', sum(1 for mm in OUT.values() for bb in mm.values() for t in bb.values() if len(t) == 1))
print('\n'.join(fails[:40])); print(len(fails), 'fails'); print('\n'.join(report[:15])); print(len(report), 'dropped')
