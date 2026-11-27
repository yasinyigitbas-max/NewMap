"""Modules for the vans, trucks and buses: bumpers, chassis, mirrors, lamps, box bodies with barn doors, the ambulance
box, tipper, refuse compactor with its hopper, fire body with its ladder, utility service body with boom and bucket,
bus seats, campaign van speakers and sign. Each is an 'extra': fn(p, hi, put, parts)."""
import math
import bpy, bmesh
from mathutils import Vector, Matrix
import wlib as w
import vlib as vl
from vlib import V, box, extrude, sweep, lathe, cyl, rrect, circle, bevel, join


def _open_box(name, lo, hi, key, inner_key, open_faces=('+y',), t=0.03):
    """a box body with walls of thickness t, open on the given faces (+y = the back); outer key, inner key"""
    x0, y0, z0 = lo
    x1, y1, z1 = hi
    ob = box(name, lo, hi, key)
    bm = bmesh.new(); bm.from_mesh(ob.data)
    kill = []
    for f in bm.faces:
        n = f.normal
        tag = ('+' if max(n) > 0.9 else '-') + 'xyz'[[abs(n.x), abs(n.y), abs(n.z)].index(max(abs(n.x), abs(n.y), abs(n.z)))]
        if tag in open_faces:
            kill.append(f)
    bmesh.ops.delete(bm, geom=kill, context='FACES')
    bm.to_mesh(ob.data); bm.free()
    vl.thicken(ob, t, inner_key)
    return ob


def bumpers_box(p, hi, put, parts):
    W, L = p['W'], p['L']
    yF, yR = -L / 2, L / 2
    zf, zr = p.get('bumper_fz', (0.30, 0.55)), p.get('bumper_rz', (0.30, 0.52))
    key = p.get('bumper_key', 'trim_blk')
    if p.get('box_front_bumper', False):
        b = box('bf', (-W * 0.98, yF - 0.06, zf[0]), (W * 0.98, yF + 0.10, zf[1]), key)
        put('bumper_f', b)
    b = box('br', (-W * 0.98, yR - 0.10, zr[0]), (W * 0.98, yR + 0.08, zr[1]), key)
    if hi:
        bevel(b, 0.02, 2)
    put('bumper_r', b)
    if hi:
        put('bumper_r', box('plate', (-0.26, yR + 0.078, zr[0] + 0.03), (0.26, yR + 0.09, zr[0] + 0.15), 'plate'))


def lamps_square(p, hi, put, parts):
    """front and rear lamps of the flat-ended vehicles: rectangles a little proud of the ends"""
    W = p['W']
    yF, yR = -p['L'] / 2, p['L'] / 2
    fz, rz = p.get('head_z', (0.75, 0.95)), p.get('tail_z', (0.55, 0.95))
    yfe = p.get('front_face', yF)
    ob = []
    for s in (1, -1):
        x0, x1 = sorted((s * W * 0.60, s * W * 0.90))
        ob.append(box('hl', (x0, yfe - 0.012, fz[0]), (x1, yfe + 0.05, fz[1]), 'lamp_head'))
        ob.append(box('ind', (x0, yfe - 0.012, fz[0] - 0.12), (x1, yfe + 0.05, fz[0] - 0.04), 'lamp_ind'))
        xr0, xr1 = sorted((s * W * 0.80, s * W * 0.98))
        ob.append(box('tl', (xr0, yR - 0.05, rz[0]), (xr1, yR + 0.012, rz[1]), 'lamp_tail'))
    put('lamps', ob)


def mirrors_truck(p, hi, put, parts):
    W = p['W']
    y0 = p.get('mirror_y', p['y_cowl'] + 0.05)
    z0 = p.get('mirror_z', p['belt'] + 0.05)
    for s, side in ((1, 'l'), (-1, 'r')):
        arm = box('arm', (s * W if s > 0 else -(W + 0.22), y0, z0 + 0.10), ((W + 0.22) if s > 0 else -W, y0 + 0.03, z0 + 0.13), 'trim_blk')
        mir = box('mir', (s * (W + 0.18) if s > 0 else -(W + 0.30), y0 - 0.02, z0 - 0.10), ((W + 0.30) if s > 0 else -(W + 0.18), y0 + 0.06, z0 + 0.32), 'trim_blk')
        if hi:
            bevel(mir, 0.015, 2)
        put('door_f_' + side if 'door_f_' + side in parts else 'body', [arm, mir])


def chassis(p, hi, put, parts):
    """frame rails, fuel tank, battery box, steps under the cab, mudguards over the rear wheels"""
    W, L = p['W'], p['L']
    yF, yR = -L / 2, L / 2
    zr0, zr1 = p.get('rail_z', (0.62, 0.90))
    obs = [box('rail', (s * 0.42 - 0.05, yF + 0.6, zr0), (s * 0.42 + 0.05, yR - 0.10, zr1), 'under') for s in (1, -1)]
    yt = p.get('tank_y', p.get('y_cb', 0) + 0.3)
    obs.append(cyl('tank', V(-W * 0.92, yt, 0.75), V(-W * 0.92, yt + 0.9, 0.75), 0.27, 0.27, 12, 'alu'))
    obs.append(box('batt', (W * 0.60, yt, 0.55), (W * 0.95, yt + 0.6, 0.95), 'trim_blk'))
    if p.get('steps', True):
        for s in (1, -1):
            obs.append(box('step', (s * (W - 0.20) if s > 0 else -(W + 0.02), p['y_cowl'] + 0.15, 0.45), ((W + 0.02) if s > 0 else -(W - 0.20), p['y_cowl'] + 0.75, 0.50), 'alu_tread'))
            obs.append(box('step2', (s * (W - 0.20) if s > 0 else -(W + 0.02), p['y_cowl'] + 0.15, 0.78), ((W + 0.02) if s > 0 else -(W - 0.20), p['y_cowl'] + 0.75, 0.82), 'alu_tread'))
    r = p['r']
    for ya in p.get('axle_ys', ())[1:]:
        for s in (1, -1):
            x0, x1 = sorted((s * (W - 0.02), s * (W - 0.62)))
            obs.append(box('guard', (x0, ya - r * 1.25, r * 2 + 0.10), (x1, ya + r * 1.25, r * 2 + 0.14), 'trim_blk'))
            obs.append(box('flap', (x0, ya + r * 1.20, 0.25), (x1, ya + r * 1.24, r * 2 + 0.10), 'rubber'))
    put('body', obs)


def box_body(p, hi, put, parts):
    """a cargo box with a floor, open at the back, barn doors on outer hinges; an inner lining"""
    W = p['box_w']
    y0, y1 = p['box_y']
    z0, z1 = p['box_z']
    ob = _open_box('cargo', (-W, y0, z0), (W, y1, z1), p.get('box_key', 'paint_wht'), 'int_trim', ('+y',), 0.04)
    if hi:
        # corner posts, rub rails, roof bows
        for s in (1, -1):
            for yy in (y0, y1 - 0.06):
                put('body', box('post', (s * W - 0.03, yy, z0), (s * W + 0.03, yy + 0.06, z1), 'alu'))
            put('body', box('rub', (s * W - 0.02, y0, z0 + 0.15), (s * W + 0.02, y1, z0 + 0.22), 'alu'))
        put('body', box('roofrail', (-W, y0, z1 - 0.06), (W, y0 + 0.05, z1), 'alu'))
    put('body', ob)
    put('body', box('subfloor', (-W, y0, z0 - 0.12), (W, y1, z0), 'under'))
    back_doors(p, hi, put, parts, (-W, W), (z0 + 0.02, z1 - 0.03), y1, p.get('box_key', 'paint_wht'), windows=False)


def back_doors(p, hi, put, parts, xr, zr, yb, key, windows=True):
    x0, x1 = xr
    xm = (x0 + x1) / 2
    for side, a, b in (('l', xm, x1), ('r', x0, xm)):
        d = box('bd', (min(a, b) + 0.004, yb - 0.04, zr[0]), (max(a, b) - 0.004, yb, zr[1]), key)
        vl.set_mats(d, lambda c, nn: key if nn.y > 0.5 else 'int_trim')
        obs = [d]
        if windows:
            hgt = zr[1] - zr[0]
            g = box('bg', (min(a, b) + 0.08, yb - 0.035, zr[0] + hgt * 0.55), (max(a, b) - 0.08, yb + 0.006, zr[1] - 0.10), 'glass')
            obs.append(g)
        if hi:
            ex = a + (b - a) * (0.15 if side == 'l' else 0.85)
            obs.append(box('hdl', (ex - 0.02, yb, (zr[0] + zr[1]) / 2 - 0.12), (ex + 0.02, yb + 0.025, (zr[0] + zr[1]) / 2 + 0.12), 'chrome'))
        put('back_door_' + side, obs)


def van_back(p, hi, put, parts):
    """the panel van's barn doors and cargo lining (the shell is open at the back)"""
    W, H, belt = p['W'], p['H'], p['belt']
    yR = p['L'] / 2
    back_doors(p, hi, put, parts, (-W * 0.92, W * 0.92), (p.get('zc', 0.25) + 0.12, H - 0.08), yR + 0.012, 'paint', windows=p.get('back_windows', False))
    put('body', box('sill', (-W * 0.95, yR - 0.06, p.get('zc', 0.25)), (W * 0.95, yR + 0.01, p.get('zc', 0.25) + 0.14), 'paint'))
    put('body', box('header', (-W * 0.95, yR - 0.06, H - 0.10), (W * 0.95, yR + 0.01, H), 'paint'))


def ambulance_box(p, hi, put, parts):
    box_body_ambulance = dict(p)
    W = p['box_w']
    y0, y1 = p['box_y']
    z0, z1 = p['box_z']
    ob = _open_box('amb', (-W, y0, z0), (W, y1, z1), 'paint_wht', 'int_trim', ('+y',), 0.04)
    put('body', ob)
    put('body', box('subfloor', (-W, y0, z0 - 0.15), (W, y1, z0), 'under'))
    # side door on the right, with a window; small windows on the left
    sd = box('sd', (-W - 0.004, y0 + 0.20, z0 + 0.05), (-W + 0.03, y0 + 1.05, z1 - 0.12), 'paint_wht')
    vl.set_mats(sd, lambda c, nn: 'paint_wht' if nn.x < -0.5 else 'int_trim')
    sg = box('sg', (-W - 0.008, y0 + 0.35, z1 - 0.75), (-W + 0.02, y0 + 0.90, z1 - 0.35), 'glass')
    put('door_b_r', [sd, sg])
    back_doors(p, hi, put, parts, (-W, W), (z0 + 0.03, z1 - 0.08), y1, 'paint_wht', windows=True)
    # beacons and flood lamps
    bc = []
    for s in (1, -1):
        for yy, k in ((y0 + 0.05, 'lamp_red'), (y1 - 0.18, 'lamp_red')):
            bc.append(box('bcn', (s * (W - 0.20) - 0.09, yy, z1), (s * (W - 0.20) + 0.09, yy + 0.13, z1 + 0.10), k))
        bc.append(box('bcn', (s * (W - 0.004) - 0.0, y0 + 1.6, z1 - 0.25), (s * (W + 0.03), y0 + 1.75, z1 - 0.12), 'lamp_red'))
    put('beacons', bc)
    if hi:
        # chequer band (high-visibility) on both sides and the back, the star of life, lettering
        for s, side in ((1, 'l'), (-1, 'r')):
            n = int((y1 - y0) / 0.15)
            for k in range(n):
                key = 'paint_red' if k % 2 == 0 else 'paint_yel'
                x0, x1 = sorted((s * W, s * (W + 0.003)))
                put('body', box('band', (x0, y0 + k * 0.15, z0 + 0.45), (x1, y0 + (k + 1) * 0.15, z0 + 0.60), key))
            put('body', vl_text('AMBULANCE', (s * (W + 0.004), (y0 + y1) / 2 + 0.3, z1 - 0.45), 0.24, side, 'paint_red'))
        put('body', vl_text('AMBULANCE', (0, p['y_cowl'] - 0.02, p['bonnet_f'] - 0.06), 0.10, 'f', 'paint_red'))


def tipper(p, hi, put, parts):
    W = p['box_w']
    y0, y1 = p['box_y']
    z0, z1 = p['box_z']
    ob = _open_box('tip', (-W, y0, z0), (W, y1, z1), 'paint_org', 'steel_bare', ('+z',), 0.05)
    put('tipper', ob)
    put('tipper', box('cab_guard', (-W, y0 - 0.02, z1), (W, y0 + 0.35, z1 + 0.06), 'paint_org'))
    put('body', box('subframe', (-0.55, y0, z0 - 0.14), (0.55, y1, z0 - 0.01), 'under'))
    p['pivot_tipper'] = (0.0, y1, z0 - 0.02)


def garbage(p, hi, put, parts):
    W = p['box_w']
    y0, y1 = p['box_y']
    z0, z1 = p['box_z']
    yh = y1 - p.get('hopper_len', 1.35)
    prof = [(W, z0), (W, z1 - 0.30), (W * 0.80, z1 - 0.05), (W * 0.40, z1), (-W * 0.40, z1), (-W * 0.80, z1 - 0.05), (-W, z1 - 0.30), (-W, z0)]
    body = vl.loft('compactor', [[V(x, y0, z) for x, z in prof], [V(x, yh, z) for x, z in prof]], p.get('box_key', 'paint_grn'))
    if hi:
        for k in range(4):
            yy = y0 + 0.4 + k * (yh - y0 - 0.8) / 3
            put('body', vl.loft('rib', [[V(x * 1.01, yy, z) for x, z in prof], [V(x * 1.01, yy + 0.08, z) for x, z in prof]], p.get('box_key', 'paint_grn')))
    put('body', body)
    put('body', box('subframe', (-0.6, y0, z0 - 0.14), (0.6, y1, z0), 'under'))
    hp = [(W * 1.02, z0 - 0.25), (W * 1.02, z1 - 0.25), (W * 0.82, z1 + 0.05), (-W * 0.82, z1 + 0.05), (-W * 1.02, z1 - 0.25), (-W * 1.02, z0 - 0.25)]
    hop = vl.loft('hopper', [[V(x, yh + 0.01, z) for x, z in hp], [V(x * 0.98, y1 - 0.30, z - 0.10) for x, z in hp],
                             [V(x * 0.94, y1, z - 0.55 if z > z0 else z0 + 0.15) for x, z in hp]], p.get('box_key', 'paint_grn'))
    put('hopper', hop)
    put('hopper', box('mouth', (-W * 0.85, y1 - 0.02, z0 - 0.15), (W * 0.85, y1 + 0.02, z0 + 0.55), 'under'))
    lm = []
    for s in (1, -1):
        lm.append(box('ht', (s * W * 0.95 - 0.06, y1 - 0.30, z1 - 0.10), (s * W * 0.95 + 0.06, y1 - 0.18, z1 + 0.06), 'lamp_ind'))
        lm.append(box('step', (s * (W - 0.45), y1 + 0.05, 0.45), (s * (W - 0.05), y1 + 0.30, 0.50), 'alu_tread'))
    put('hopper', lm)
    p['pivot_hopper'] = (0.0, yh, z1 + 0.05)


def fire_body(p, hi, put, parts):
    W = p['box_w']
    y0, y1 = p['box_y']
    z0, z1 = p['box_z']
    body = box('fb', (-W, y0, z0), (W, y1, z1), 'paint_red')
    put('body', body)
    put('body', box('subfloor', (-W, y0, z0 - 0.12), (W, y1, z0), 'under'))
    if hi:
        n = int((y1 - y0 - 0.2) / 1.05)
        for s in (1, -1):
            for k in range(n):
                ya = y0 + 0.15 + k * 1.05
                x0, x1 = sorted((s * W, s * (W + 0.004)))
                put('body', box('shutter', (x0, ya, z0 + 0.25), (x1, ya + 0.95, z1 - 0.20), 'alu'))
                for j in range(12):
                    zz = z0 + 0.30 + j * (z1 - z0 - 0.55) / 12
                    x0b, x1b = sorted((s * (W + 0.004), s * (W + 0.007)))
                    put('body', box('slat', (x0b, ya + 0.02, zz), (x1b, ya + 0.93, zz + 0.008), 'alu'))
            x0, x1 = sorted((s * W, s * (W + 0.003)))
            put('body', box('stripe', (x0, y0, z0 + 0.05), (x1, y1, z0 + 0.18), 'paint_wht'))
        put('body', vl_text('FIRE DEPT', (0, p['y_cowl'] - 0.012, p['belt'] - 0.35), 0.20, 'f', 'paint_wht'))
    # ladder on top, on a turntable at the back
    lw = 0.55
    lad = []
    lad.append(box('lr', (lw - 0.06, y0 - 0.6, z1 + 0.12), (lw, y1 - 0.1, z1 + 0.24), 'alu'))
    lad.append(box('lr', (-lw, y0 - 0.6, z1 + 0.12), (-lw + 0.06, y1 - 0.1, z1 + 0.24), 'alu'))
    n = int((y1 - y0 + 0.5) / 0.35)
    for k in range(n):
        yy = y0 - 0.55 + k * 0.35
        lad.append(box('rung', (-lw + 0.05, yy, z1 + 0.16), (lw - 0.05, yy + 0.04, z1 + 0.20), 'alu'))
    put('ladder', lad)
    put('body', cyl('turntable', V(0, y1 - 0.45, z1), V(0, y1 - 0.45, z1 + 0.12), 0.55, 0.55, 12, 'alu'))
    p['pivot_ladder'] = (0.0, y1 - 0.45, z1 + 0.12)


def utility_body(p, hi, put, parts):
    W = p['box_w']
    y0, y1 = p['box_y']
    z0, z1 = p['box_z']
    for s in (1, -1):
        x0, x1 = sorted((s * W, s * (W - 0.50)))
        put('body', box('cmp', (x0, y0, z0), (x1, y1, z1), 'paint_wht'))
        if hi:
            n = 3
            for k in range(n):
                ya = y0 + 0.05 + k * (y1 - y0 - 0.1) / n
                xa, xb = sorted((s * W, s * (W + 0.006)))
                put('body', box('cdoor', (xa, ya + 0.03, z0 + 0.12), (xb, ya + (y1 - y0 - 0.1) / n - 0.03, z1 - 0.05), 'paint_wht'))
                put('body', box('lat', (xa, ya + 0.15, z1 - 0.25), (xb + s * 0.01 if s > 0 else xb, ya + 0.25, z1 - 0.20), 'chrome'))
            xa, xb = sorted((s * W, s * (W + 0.004)))
            put('body', box('hiviz', (xa, y0, z0 + 0.02), (xb, y1, z0 + 0.10), 'paint_org'))
    put('body', box('deck', (-(W - 0.50), y0, z0), (W - 0.50, y1, z0 + 0.25), 'alu_tread'))
    # the aerial lift: turret, boom (folded along the truck), bucket
    yt = y1 - 0.45
    put('body', cyl('turret', V(0, yt, z0 + 0.25), V(0, yt, z0 + 0.55), 0.30, 0.30, 12, 'paint_wht'))
    boom = [box('b1', (-0.11, -p['L'] / 2 + 1.35, z0 + 0.95), (0.11, yt + 0.25, z0 + 1.20), 'paint_wht'),
            box('b2', (-0.08, -p['L'] / 2 + 1.30, z0 + 0.98), (0.08, yt + 0.30, z0 + 1.17), 'alu'),
            box('post', (-0.15, yt - 0.20, z0 + 0.55), (0.15, yt + 0.25, z0 + 1.20), 'paint_wht')]
    put('boom', boom)
    put('bucket', box('bkt', (-0.40, -p['L'] / 2 + 0.95, z0 + 0.70), (0.40, -p['L'] / 2 + 1.70, z0 + 1.75), 'paint_yel'))
    put('body', box('rest', (-0.20, y0 - 0.20, p['H'] + 0.02), (0.20, y0, p['H'] + 0.10), 'trim_blk'))
    p['pivot_boom'] = (0.0, yt, z0 + 0.55)
    p['pivot_bucket'] = (0.0, -p['L'] / 2 + 1.30, z0 + 1.10)
    bc = [box('amb', (s * 0.55 - 0.08, p['y_bpil'] - 0.35, p['H']), (s * 0.55 + 0.08, p['y_bpil'] - 0.20, p['H'] + 0.12), 'lamp_ind') for s in (1, -1)]
    put('beacons', bc)


def bus_seats(p, hi, put, parts):
    W, L = p['W'], p['L']
    yF = -L / 2
    zf = p.get('zc', 0.30) + 0.10
    obs = []
    ys = p['seat_rows']
    for y in ys:
        for s in (1, -1):
            if s < 0 and any(a - 0.2 < y - yF < b + 0.4 for a, b in (p['door1'], p['door2'])):
                continue
            x0, x1 = sorted((s * (W - 0.10), s * (W - 0.95)))
            obs.append(box('cush', (x0, y - 0.22, zf + 0.40), (x1, y + 0.20, zf + 0.48), 'int_fabric'))
            obs.append(box('back', (x0, y + 0.20, zf + 0.42), (x1, y + 0.28, zf + 0.95), 'int_fabric'))
            obs.append(box('leg', ((x0 + x1) / 2 - 0.05, y - 0.05, zf), ((x0 + x1) / 2 + 0.05, y + 0.05, zf + 0.40), 'int_plastic'))
    for k in range(int((L - 2) / 1.6)):
        y = yF + 1.6 + k * 1.6
        for s in (1, -1):
            obs.append(box('pole', (s * (W - 1.00) - 0.02, y, zf), (s * (W - 1.00) + 0.02, y + 0.04, p['H'] - 0.10), 'chrome'))
    obs.append(box('floor', (-(W - 0.08), yF + 0.1, zf - 0.02), (W - 0.08, L / 2 - 0.3, zf), 'int_carpet'))
    put('interior', obs)


def roof_speakers(p, hi, put, parts):
    """campaign van: two loudspeaker horns on a roof rack"""
    H, W = p['H'], p['W']
    yc = p['y_bpil'] + 0.4
    sp = [box('rack', (-W * 0.8, yc - 0.6, H + 0.01), (W * 0.8, yc + 0.6, H + 0.05), 'trim_blk')]
    for s in (1, -1):
        sp.append(lathe('horn', [(0.0, 0.06), (0.35, 0.18), (0.36, 0.0)], 16 if hi else 8, 'paint_wht', (s * 0.35, yc - 0.1, H + 0.20), axis=(0, -1, 0)))
        sp.append(box('drv', (s * 0.35 - 0.08, yc - 0.15, H + 0.05), (s * 0.35 + 0.08, yc + 0.15, H + 0.30), 'trim_blk'))
    put('speakers', sp)


def roof_board(p, hi, put, parts):
    """campaign van: a printed board on the roof (both faces)"""
    H, W = p['H'], p['W']
    y0, y1 = p['y_bpil'] - 0.2, p['L'] / 2 - 0.4
    b = [box('posts', (-0.03, y0 + 0.2, H), (0.03, y1 - 0.2, H + 0.12), 'trim_blk'),
         box('board', (-0.025, y0, H + 0.12), (0.025, y1, H + 0.75), 'paint_wht')]
    put('speakers', b)
    if hi:
        for s, side in ((1, 'l'), (-1, 'r')):
            put('speakers', vl_text(p['slogan2'], (s * 0.027, (y0 + y1) / 2, H + 0.44), 0.26, side, p['slogan_key']))


def campaign_livery(p, hi, put, parts):
    if not hi:
        return
    W = p['W']
    for s, side in ((1, 'l'), (-1, 'r')):
        yc = (p['y_bpil'] + p['L'] / 2) / 2
        put('body', vl_text(p['slogan'], (s * (W + 0.003), yc, p['H'] - 0.55), 0.32, side, p['slogan_key']))
        put('body', vl_text(p['slogan_sub'], (s * (W + 0.003), yc, p['H'] - 0.95), 0.16, side, p['slogan_key2']))
        x0, x1 = sorted((s * W, s * (W + 0.002)))
        put('body', box('band', (x0, p['y_bpil'] + 0.15, p.get('zc', 0.25) + 0.30), (x1, p['L'] / 2 - 0.05, p.get('zc', 0.25) + 0.48), p['slogan_key2']))
    put('back_door_l', vl_text(p['slogan_back'], (W * 0.46, p['L'] / 2 + 0.013, p['H'] - 0.70), 0.13, 'b', p['slogan_key']))


def vl_text(*a, **k):
    import vmodels
    return vmodels.text_decal(*a, **k)


def lightbar_cab(p, hi, put, parts):
    W, H = p['W'], p['H']
    yc = p.get('y_roof_f', p['y_cowl']) + 0.25
    put('lightbar', box('lb', (-W * 0.75, yc - 0.13, H + 0.01), (W * 0.75, yc + 0.13, H + 0.05), 'trim_blk'))
    for s, k in ((1, 'lamp_red'), (-1, 'lamp_red' if p.get('all_red', True) else 'lamp_blue')):
        x0, x1 = sorted((s * 0.03, s * W * 0.72))
        put('lightbar', box('lens', (x0, yc - 0.11, H + 0.05), (x1, yc + 0.11, H + 0.14), k))


def utility_body_auto(p, hi, put, parts):
    p['box_y'] = (p['y_cab'] + 0.06, p['L'] / 2 - 0.12)
    utility_body(p, hi, put, parts)


def roof_rails(p, hi, put, parts):
    W, H = p['W'], p['H']
    y0, y1 = p['y_roof_f'] + 0.15, p.get('y_roof_r', p['L'] / 2 - 0.3) - 0.10
    for s in (1, -1):
        x = s * p['W'] * p.get('roof_w', 0.80) * 0.80
        put('body', box('rail', (x - 0.025, y0, H), (x + 0.025, y1, H + 0.05), 'trim_blk'))
        for yy in (y0, y1 - 0.06):
            put('body', box('foot', (x - 0.03, yy, H - 0.01), (x + 0.03, yy + 0.06, H + 0.06), 'trim_blk'))


def front_detail(p, hi, put, parts):
    """(high model) grille, plate and door handles for the flat-fronted vehicles; bus destination sign"""
    if not hi:
        return
    W = p['W']
    yF = p.get('front_face', -p['L'] / 2)
    fz = p.get('head_z', (0.75, 0.95))
    put('body', box('grille', (-W * 0.50, yF - 0.008, fz[0] - 0.05), (W * 0.50, yF + 0.02, fz[1] + 0.12), 'grille'))
    put('bumper_f', box('plate', (-0.26, yF - 0.075, p.get('bumper_fz', (0.3, 0.5))[0] + 0.04), (0.26, yF - 0.06, p.get('bumper_fz', (0.3, 0.5))[0] + 0.16), 'plate'))
    if p.get('family') == 'bus':
        H = p['H']
        put('body', box('dest', (-W * 0.70, yF - 0.008, H - 0.42), (W * 0.70, yF + 0.02, H - 0.12), 'gauge'))
        import vmodels
        put('body', vmodels.text_decal(p.get('route', '12  DOWNTOWN'), (0, yF - 0.012, H - 0.27), 0.16, 'f', 'lamp_ind'))
    for s, side in ((1, 'l'), (-1, 'r')):
        dn = 'door_f_' + side
        if dn in parts:
            x0, x1 = sorted((s * (W - 0.005), s * (W + 0.015)))
            yy = p['y_bpil'] - 0.20
            put(dn, box('handle', (x0, yy - 0.08, p['belt'] - 0.12), (x1, yy + 0.08, p['belt'] - 0.08), 'trim_blk'))
