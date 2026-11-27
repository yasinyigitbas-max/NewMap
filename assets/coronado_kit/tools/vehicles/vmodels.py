"""The fleet: one builder per body family, each vehicle a table of measurements. build(hi) returns
{'parts': {name: [objects]}, 'markers': {name: (x,y,z)}, 'pivots': {name: (x,y,z)}}; hi=False is the game model,
hi=True the bake source. All generic designs: no maker's shapes, badges or names."""
import math
import bpy
from mathutils import Vector, Matrix
import wlib as w
import vlib as vl
import vmodules as vm
from vlib import V, box, extrude, sweep, lathe, loft, cyl, rrect, circle, bevel, cut, join, smooth


def _arch_zb(dy, r, zr, base):
    """underside height over a wheel: an arch of radius 1.12 r round the hub at height zr"""
    R = r * 1.14
    if abs(dy) >= R:
        return base
    return max(base, zr + math.sqrt(R * R - dy * dy) * 0.93)


def stations_car(p):
    """keyframe stations of a car body (front to rear) from its measurements; arches inserted afterwards"""
    L, W, H = p['L'], p['W'], p['H']
    yF, yR = -L / 2, L / 2
    zc = p.get('zc', 0.20)                    # underside
    belt = p['belt']
    wt = W * p.get('roof_w', 0.80)
    bf, bc = p['bonnet_f'], p.get('cowl', belt)
    y_c, y_rf, y_b, y_rr, y_deck = p['y_cowl'], p['y_roof_f'], p['y_bpil'], p['y_roof_r'], p['y_deck']
    deck = p.get('deck', belt + 0.04)
    style = p['style']
    S = []

    def st(y, zb, zbl, zt, wd, wtt, zone, **kw):
        d = dict(y=y, zb=zb, zbl=zbl, zt=zt, w=wd, wt=wtt, zone=zone)
        d.update(kw)
        S.append(d)
    st(yF, zc + 0.14, bf - 0.12, bf - 0.12, W * 0.78, W * 0.60, 'bumper_f', sill=0.05)
    st(yF + 0.025, zc + 0.10, bf - 0.07, bf - 0.07, W * 0.88, W * 0.70, 'front')
    st(yF + 0.07, zc + 0.07, bf - 0.025, bf - 0.025, W * 0.95, W * 0.79, 'front')
    st(yF + 0.16, zc, bf, bf, W * 0.985, W * 0.86, 'bonnet')
    st((yF + 0.16 + y_c) / 2, zc, (bf + bc) / 2 + 0.01, (bf + bc) / 2 + 0.01, W, W * 0.88, 'bonnet')
    st(y_c, zc, bc, bc, W, W * 0.88, 'screen')
    st(y_rf, zc, belt, H, W, wt, 'door_f')
    nd = p.get('doors', 4)
    if nd == 4:
        st(y_b, zc, belt, H, W, wt, 'bpillar')
        st(y_b + 0.09, zc, belt, H, W, wt, p.get('rear_zone', 'door_r'))
        y_rd = p['y_rdoor']
        st(y_rd, zc, belt, H - 0.005, W, wt, p.get('quarter_zone', 'quarter'))
    else:
        st(y_b, zc, belt, H, W, wt, 'quarter')
    if style == 'van':                       # flat back, open (barn doors are their own parts); bumper is a box
        st(yR - 0.04, zc, belt, H, W, wt, 'back')
        st(yR, zc, belt, H, W, wt, 'back')
        for a, b in zip(S, S[1:]):
            assert b['y'] > a['y'] + 1e-4, 'stations out of order at y=%.3f -> %.3f' % (a['y'], b['y'])
        return S
    if style == 'cab':                       # a van cab only: closed back wall (a body module sits behind)
        st(p['y_cb'], zc, belt, H, W, wt, 'cabrear')
        st(p['y_cb'] + 0.02, zc + 0.02, belt, H - 0.01, W - 0.01, wt - 0.01, 'cabrear')
        for a, b in zip(S, S[1:]):
            assert b['y'] > a['y'] + 1e-4, 'stations out of order at y=%.3f -> %.3f' % (a['y'], b['y'])
        return S
    if style == 'pickup':
        yc, bt = p['y_cab'], p['bed_top']
        if p.get('no_bed'):                  # (a body module sits on the frame: the cab ends in a wall)
            st(y_rr, zc, belt + 0.01, H - 0.02, W, wt * 0.98, 'cabback')
            st(yc, zc, belt, H - 0.04, W, wt * 0.97, 'cabrear')
            st(yc + 0.02, zc + 0.02, belt, H - 0.05, W - 0.01, wt - 0.01, 'cabrear')
            return S
        st(y_rr, zc, belt + 0.01, H - 0.02, W, wt * 0.98, 'cabback')
        st(yc, zc, bt, bt, W, W * 0.97, 'bedgap')
        st(yc + 0.06, zc, bt, bt, W, W * 0.97, 'bed')
        st(yR - 0.06, zc, bt, bt, W, W * 0.97, 'ptail')
    elif style in ('sedan', 'coupe'):
        st(y_rr, zc, belt + 0.01, H - 0.02, W, wt * 0.98, 'rscreen')
        st(y_deck, zc, deck, deck, W * 0.99, wt * 0.95, 'boot')
        st(yR - 0.16, zc, deck - 0.01, deck - 0.01, W * 0.985, W * 0.86, 'boot')
        st(yR - 0.08, zc + 0.04, deck - 0.04, deck - 0.04, W * 0.95, W * 0.80, 'rear')
    else:     # hatch / wagon / suv: roof to a tailgate
        st(y_rr, zc, belt + 0.01, H - 0.01, W, wt * 0.98, 'tailgate')
        st(yR - 0.08, zc + 0.02, belt - 0.02, p.get('tail_top', H - 0.10), W * 0.97, wt * 0.92, 'rear')
    st(yR - 0.035, zc + 0.08, S[-1]['zbl'] - 0.06, S[-1]['zbl'] - 0.06, W * 0.91, W * 0.72, 'bumper_r', sill=0.05)
    st(yR, zc + 0.16, S[-1]['zbl'] - 0.02, S[-1]['zbl'] - 0.02, W * 0.82, W * 0.62, 'bumper_r', sill=0.04)
    # the last station's zone is unused (it ends the loft)
    for a, b in zip(S, S[1:]):
        assert b['y'] > a['y'] + 1e-4, 'stations out of order at y=%.3f -> %.3f (%s -> %s)' % (a['y'], b['y'], a['zone'], b['zone'])
    return S


def stations_cabover(p):
    """a flat-fronted truck cab high over the front wheels; ends in a closed back wall"""
    L, W, H = p['L'], p['W'], p['H']
    yF = -L / 2
    zf, belt = p['cab_floor'], p['belt']
    wt = W * 0.94
    S = []

    def st(y, zb, zbl, zt, wd, wtt, zone, **kw):
        d = dict(y=y, zb=zb, zbl=zbl, zt=zt, w=wd, wt=wtt, zone=zone, sill=0.06, tb=0.01, sh=0.03, rail=0.10)
        d.update(kw)
        S.append(d)
    st(yF, zf + 0.02, belt - 0.02, belt - 0.02, W * 0.95, W * 0.90, 'tfront')
    st(yF + 0.12, zf, belt, H, W, wt, 'door_f')
    yc = yF + 0.12 + p.get('fdoor', 1.15)
    st(yc, zf, belt, H, W, wt, 'cabrear')
    st(yc + 0.30, zf, belt, H, W, wt, 'cabrear')
    st(yc + 0.32, zf + 0.02, belt, H - 0.01, W - 0.01, wt - 0.01, 'cabrear')
    p['y_cb'] = yc + 0.32
    p['y_cowl'] = yF + 0.12
    p['y_roof_f'] = yF + 0.12
    p['y_bpil'] = yc
    return S


def stations_bus(p):
    """a city bus: flat nose with the screen above it, a window band, two folding doors on the right"""
    L, W, H = p['L'], p['W'], p['H']
    yF, yR = -L / 2, L / 2
    zc, belt = p.get('zc', 0.30), p['belt']
    wt = W * 0.97
    S = []

    def st(y, zb, zbl, zt, wd, wtt, zone, **kw):
        d = dict(y=y, zb=zb, zbl=zbl, zt=zt, w=wd, wt=wtt, zone=zone, sill=0.08, tb=0.01, sh=0.04, rail=p.get('rail', 0.55))
        d.update(kw)
        S.append(d)
    st(yF, zc + 0.10, 0.95, 0.95, W * 0.94, W * 0.90, 'bfront')
    st(yF + 0.10, zc, belt, H, W, wt, 'window')
    for name, (a, b) in (('busdoor1', p['door1']), ('busdoor2', p['door2'])):
        st(yF + a, zc, belt, H, W, wt, name)
        st(yF + b, zc, belt, H, W, wt, 'window')
    st(yR - 0.50, zc, belt, H, W, wt, 'back')
    st(yR - 0.06, zc, belt, H - 0.04, W * 0.99, wt * 0.98, 'back')
    st(yR, zc + 0.10, belt, H - 0.10, W * 0.96, wt * 0.94, 'back')
    S.sort(key=lambda s: s['y'])
    p['y_cowl'] = yF + 0.10
    p['y_roof_f'] = yF + 0.10
    p['y_bpil'] = yF + 1.2
    return S


def add_arches(S, axles, r, zr):
    """insert stations over each axle so the underside follows the wheel arch"""
    out = list(S)
    for ya in axles:
        for f in (-1.14, -0.95, -0.7, -0.35, 0.0, 0.35, 0.7, 0.95, 1.14):
            y = ya + f * r
            for i in range(len(out) - 1):
                a, b = out[i], out[i + 1]
                if a['y'] < y < b['y']:
                    t = (y - a['y']) / (b['y'] - a['y'])
                    s = vl.interp_station(a, b, t)
                    s['y'] = y
                    s['zone'] = a['zone']
                    out.insert(i + 1, s)
                    break
    for s in out:
        for ya in axles:
            s['zb'] = _arch_zb(s['y'] - ya, r, zr, s['zb'])
    return out


def classify_car(p):
    nd = p.get('doors', 4)
    windows = p.get('windows', True)
    slide_side = p.get('slide_side', 'r')

    def glass_or(side, other='body'):
        return ('glass_side_' + side) if windows else other

    def f(zone, seg, side):
        if zone in ('cap_f',):
            return p.get('cap_f', 'bumper_f')
        if zone in ('cap_r',):
            return p.get('cap_r', 'bumper_r')
        if zone == 'bumper_f':
            return 'bumper_f'
        if zone == 'bumper_r':
            return 'bumper_r'
        if seg == 0:
            return 'body'
        if zone == 'bonnet':
            return 'bonnet' if seg >= 4 else 'body'
        if zone in ('screen', 'door_f'):
            if seg in (2, 3):
                return 'door_f_' + side
            if seg in (4, 5):
                return 'glass_door_f_' + side
            if seg == 7 and zone == 'screen':
                return 'glass_front'
            return 'body'
        if zone == 'tfront':                 # cab-over front: corner posts and the tall screen
            return 'glass_front' if seg == 7 else 'body'
        if zone == 'door_r':
            if seg in (2, 3):
                return 'door_r_' + side
            if seg in (4, 5):
                return 'glass_door_r_' + side
            return 'body'
        if zone == 'slide':
            if side == slide_side or slide_side == 'both':
                if seg in (2, 3):
                    return 'door_s_' + side
                if seg in (4, 5):
                    return 'glass_door_s_' + side if windows else 'door_s_' + side
                return 'body'
            return glass_or(side) if seg in (4, 5) else 'body'
        if zone in ('side', 'window'):
            return glass_or(side) if seg in (4, 5) else 'body'
        if zone.startswith('busdoor'):
            if side == 'r':
                if seg in (2, 3):
                    return zone + '_r'
                if seg in (4, 5):
                    return 'glass_' + zone + '_r'
                return 'body'
            return glass_or(side) if seg in (4, 5) else 'body'
        if zone == 'bfront':                 # bus front: the screen is the upper half of the nose
            return 'glass_front' if seg >= 5 else 'body'
        if zone == 'quarter':
            return ('glass_side_' + side) if (seg == 5 and p.get('quarter_glass')) else 'body'
        if zone == 'rscreen':
            return 'glass_rear' if seg == 7 else 'body'
        if zone == 'boot':
            return 'boot' if seg >= 4 else 'body'
        if zone == 'tailgate':
            if seg == 7:
                return 'glass_rear'
            return 'tailgate' if seg == 6 else 'body'
        if zone == 'cabback':
            return 'glass_rear' if seg == 7 and p.get('cab_window', True) else 'body'
        if zone in ('bed', 'bedgap'):
            return None if seg >= 6 else 'body'
        if zone == 'ptail':
            return None if seg >= 6 else ('tailgate' if seg >= 2 else 'body')
        if zone == 'rear':
            if p.get('style') in ('hatch', 'wagon', 'suv', 'minivan') and seg >= 3:
                return 'tailgate'
            return 'body'
        return 'body'
    return f


CABIN = ('screen', 'tfront', 'door_f', 'bpillar', 'door_r', 'quarter', 'rscreen', 'tailgate', 'cabback', 'slide', 'side', 'window', 'back',
         'cabrear', 'bfront', 'busdoor1', 'busdoor2')
GLASSY = ('door_f', 'door_r', 'screen', 'slide', 'side', 'window', 'busdoor1', 'busdoor2', 'tfront')


def lining_classify(zone, seg, side):
    """the cabin's inner lining: cabin zones only, open where the glass is"""
    if zone not in CABIN:
        return None
    if zone in GLASSY and seg in (4, 5):
        return None
    if zone in ('screen', 'rscreen', 'tailgate', 'cabback', 'tfront') and seg == 7:
        return None
    if zone == 'bfront' and seg >= 5:
        return None
    return 'lining'


def auto(p):
    """fill the cabin positions from the main measurements (explicit keys win)"""
    p = dict(p)
    L, H, belt, r = p['L'], p['H'], p['belt'], p['r']
    yF, yR = -L / 2, L / 2
    yfa = yF + p['fo']
    yra = yfa + p['wb']
    p.setdefault('y_cowl', yfa + 1.14 * r + p.get('cowl_gap', 0.10))
    p.setdefault('y_roof_f', p['y_cowl'] + p.get('screen_run', (H - belt) * 1.3))
    nd = p.get('doors', 4)
    p.setdefault('y_bpil', p['y_cowl'] + p.get('fdoor', 1.25 if nd == 4 else 1.35))
    if nd == 4:
        p.setdefault('y_rdoor', p['y_bpil'] + 0.09 + p.get('rdoor', 0.85))
    last = p.get('y_rdoor', p['y_bpil'])
    st = p['style']
    if st in ('sedan', 'coupe'):
        p.setdefault('y_roof_r', last + (0.12 if nd == 4 else 0.40))
        p.setdefault('y_deck', p['y_roof_r'] + p.get('rscreen_run', 0.50))
    elif st == 'pickup':
        p.setdefault('y_roof_r', last + 0.10)
        p.setdefault('y_cab', p['y_roof_r'] + 0.06)
        p.setdefault('y_deck', p['y_cab'])
    else:
        p.setdefault('y_roof_r', yR - p.get('tail_run', 0.30))
        p.setdefault('y_deck', p['y_roof_r'])
    p.setdefault('hip_back', 0.22)
    return p


def car(p, hi):
    """a car of one of the families sedan / coupe / hatch / wagon / suv / pickup"""
    fam = p.get('family', 'car')
    if fam == 'car':
        p = auto(p)
    else:
        p = dict(p)
    r, tw = p['r'], p.get('tyre_w', 0.21)
    yfa = -p['L'] / 2 + p['fo']
    yra = yfa + p['wb']
    axle_ys = p.get('axle_ys', (yfa, yra))
    zr = r
    Sraw = {'car': stations_car, 'cabover': stations_cabover, 'bus': stations_bus}[fam](p)
    S = add_arches(Sraw, axle_ys, r, zr) if p.get('arches', True) else Sraw
    sh = vl.shell(S, classify_car(p))
    parts = {}

    def put(name, obs):
        parts.setdefault(name, []).extend(obs if isinstance(obs, list) else [obs])
    livery = p.get('livery')
    for n, ob in sh.items():
        if n.startswith('glass'):
            vl.set_mats(ob, lambda c, nn: 'glass')
            vl.thicken(ob, 0.006, 'glass')
            continue
        def mk(c, nn, n=n):
            if nn.z < -0.7:
                return 'under'
            if livery:
                k = livery(n, c, nn)
                if k:
                    return k
            if n.startswith('bumper') and p.get('bumper_key'):
                return p['bumper_key']
            return 'paint'
        vl.set_mats(ob, mk)
        if n.startswith('door') or n in ('bonnet', 'boot', 'tailgate'):
            vl.thicken(ob, 0.05 if n.startswith('door') else 0.03, 'int_trim' if n.startswith('door') else 'under')
    # B-pillar and window surrounds in black trim (the 'bpillar' strip's upper half) - by material on the body
    body = sh['body']
    # glass goes with its door; fixed glass stays its own part
    for dn in sh:
        if dn.startswith(('door', 'busdoor')):
            put(dn, [sh[dn]] + ([sh['glass_' + dn]] if 'glass_' + dn in sh else []))
    for n in ('bonnet', 'boot', 'tailgate', 'bumper_f', 'bumper_r', 'glass_front', 'glass_rear'):
        if n in sh:
            put(n, sh[n])
    for n in sh:                                         # fixed side glass: one part
        if n.startswith('glass_side') or n.startswith('glass_q'):
            put('glass_side', sh[n])
    if 'tailgate' in parts and 'glass_rear' in parts and p.get('style') != 'pickup':      # the rear screen lifts with the tailgate
        parts['tailgate'] += parts.pop('glass_rear')
    # --- lamps, grille, plates, mirrors, handles
    W, L = p['W'], p['L']
    yF, yR = -L / 2, L / 2
    bf = p.get('bonnet_f', p.get('head_z', (0.8, 1.0))[1] + 0.12)
    lamps = []
    for s in ((1, -1) if fam == 'car' else ()):
        hl = box('hl', (s * W * 0.48 if s > 0 else -W * 0.84, yF + 0.012, bf - 0.13), (W * 0.84 if s > 0 else -W * 0.48, yF + 0.15, bf - 0.045), 'lamp_head')
        lamps.append(hl)
        deck = S[-3]['zbl']
        tl = box('tl', (s * W * 0.52 if s > 0 else -W * 0.88, yR - 0.15, deck - 0.16), (W * 0.88 if s > 0 else -W * 0.52, yR - 0.03, deck - 0.06), 'lamp_tail')
        lamps.append(tl)
        ind = box('ind', (s * W * 0.62 if s > 0 else -W * 0.80, yF + 0.005, p.get('zc', 0.2) + 0.28), (W * 0.80 if s > 0 else -W * 0.62, yF + 0.10, p.get('zc', 0.2) + 0.33), 'lamp_ind')
        lamps.append(ind)
    if lamps:
        put('lamps', lamps)
    # mirrors on the front doors
    for s, side in (((1, 'l'), (-1, 'r')) if fam == 'car' else ()):
        y0 = p['y_cowl'] + 0.10
        mz = p['belt'] + 0.02
        mir = box('mirror', (s * (W - 0.02) if s > 0 else -(W + 0.20), y0, mz), ((W + 0.20) if s > 0 else -(W - 0.02), y0 + 0.12, mz + 0.13), 'paint')
        if hi:
            bevel(mir, 0.02, 2)
            glass_m = box('mglass', (s * (W + 0.03) if s > 0 else -(W + 0.19), y0 + 0.118, mz + 0.015), ((W + 0.19) if s > 0 else -(W + 0.03), y0 + 0.124, mz + 0.115), 'chrome')
            put('door_f_' + side, glass_m)
        put('door_f_' + side, mir)
    # --- wheels
    track = W - p.get('wheel_in', 0.10) - tw / 2
    duals = p.get('duals', ())
    tags = ['f', 'r', 'r2', 'r3']
    for ai, yy in enumerate(axle_ys):
        for s, side in ((1, 'l'), (-1, 'r')):
            dual = ai in duals
            ww = tw * (2.1 if dual else 1.0)
            obs = vl.wheel('w', r, ww, hi, p.get('rim', 'rim'), p.get('spokes', 5), side=s)
            tr = track - (ww - tw) / 2
            for o in obs:
                o.data.transform(Matrix.Translation(V(s * tr, yy, zr)))
            put('wheel_%s%s' % (tags[ai], side), obs)
    # --- interior: lining, floor, seats, dash, console, steering wheel
    Sin = []
    for s in S:
        d = dict(s)
        d['w'] -= 0.05; d['wt'] -= 0.05; d['zt'] -= 0.05; d['zbl'] -= 0.0; d['zb'] = max(s['zb'], p.get('zc', 0.2) + 0.12)
        Sin.append(d)
    cab = [s for s in Sin if s['zone'] in CABIN]
    if cab:
        i0 = Sin.index(cab[0]); i1 = Sin.index(cab[-1]) + 1
        ln = vl.shell(Sin[i0:i1 + 1], lining_classify)
        for n, ob in ln.items():
            ob.data.flip_normals()
            vl.set_mats(ob, lambda c, nn: 'int_carpet' if nn.z > 0.7 and c.z < p['belt'] - 0.2 else 'int_trim')
            put('interior', ob)
        # engine bay and boot well: the same stations shrunk, floors and walls only (their lids are the bonnet / boot)
        def bay_cls(zone, seg, side):
            if zone in ('bonnet',) and seg <= 3:
                return 'bay'
            if zone in ('boot',) and seg <= 3 and p.get('style') in ('sedan', 'coupe'):
                return 'well'
            return None
        bays = vl.shell(Sin, bay_cls)
        for n, ob in bays.items():
            ob.data.flip_normals()
            vl.set_mats(ob, lambda c, nn, n=n: 'under' if n == 'bay' else 'int_carpet')
            put('interior', ob)
        ys = [s['y'] for s in S if s['zone'] == 'bonnet']
        if ys:
            ye0, ye1 = min(ys) + 0.15, max(ys) - 0.05
            eng = box('engine', (-W * 0.55, ye0, p.get('zc', 0.2) + 0.15), (W * 0.55, ye1, bf - 0.10), 'steel_bare')
            put('interior', eng)
            if hi:
                bevel(eng, 0.03, 2)
                cov = box('ecover', (-W * 0.35, ye0 + 0.05, bf - 0.11), (W * 0.35, ye1 - 0.05, bf - 0.05), 'int_plastic')
                bevel(cov, 0.02, 2)
                put('interior', cov)
    hip_z = p.get('hip_z', p.get('zc', 0.2) + p.get('hip', 0.36))
    y_hp = p.get('y_hp', p['y_bpil'] - p.get('hip_back', 0.22))
    xs = W * 0.42
    markers = {}
    seats = []
    room = p['H'] - 0.10 - hip_z                     # (headroom: the seat back and headrest stay under the roof)
    bh_f = max(0.40, min(0.58, room - 0.20))
    for s, side in ((1, 'l'), (-1, 'r')):
        if side not in p.get('front_seats', ('l', 'r')):
            continue
        seats += vl.seat('seat', (s * xs * 0.95, y_hp, hip_z), 0.50, hi, back_h=bh_f)
        markers['seat_f' + side] = (s * xs * 0.95, y_hp, hip_z)
    if fam == 'car' and (p.get('doors', 4) == 4 or p.get('rear_seat', True)):
        yb = y_hp + p.get('rear_leg', 0.85)
        bh_r = max(0.30, min(0.55, p.get('rear_room', room - 0.25)))
        seats += vl.seat('bench', (0, yb, hip_z + 0.03), W * 1.55, hi, bench=True, back_h=bh_r)
        markers['seat_rl'] = (xs * 0.9, yb, hip_z + 0.03)
        markers['seat_rr'] = (-xs * 0.9, yb, hip_z + 0.03)
    put('interior', seats)
    if p.get('style') == 'pickup' and not p.get('no_bed'):
        bt = p['bed_top']
        fl = p.get('zc', 0.2) + 0.42
        tub = box('tub', (-(W - 0.05), p['y_cab'] + 0.04, fl), (W - 0.05, L / 2 - 0.075, bt - 0.005), 'alu_tread' if p.get('tread_bed') else 'under')
        bm_ = tub.data
        import bmesh as _b
        b_ = _b.new(); b_.from_mesh(bm_)
        _b.ops.delete(b_, geom=[f for f in b_.faces if f.normal.z > 0.9], context='FACES')
        _b.ops.reverse_faces(b_, faces=b_.faces)
        b_.to_mesh(bm_); b_.free()
        put('body', tub)
    yd = p['y_cowl']
    db = p.get('dash_z', p['belt'])
    dash = extrude('dash', [(yd - 0.05, db - 0.02), (yd + 0.30, db + 0.02), (yd + 0.42, db - 0.10),
                            (yd + 0.40, db - 0.30), (yd + 0.15, db - 0.40), (yd - 0.05, db - 0.40)], -(W - 0.06), W - 0.06, 'int_plastic')
    cons = box('console', (-0.10, yd + 0.38, hip_z - 0.24), (0.10, y_hp + 0.10, hip_z + 0.05), 'int_plastic')
    if hi:
        bevel(dash, 0.02, 2, 30)
        bevel(cons, 0.015, 2, 30)
        cl = box('cluster', (xs * 0.95 - 0.16, yd + 0.33, db - 0.08), (xs * 0.95 + 0.16, yd + 0.425, db - 0.02), 'gauge')
        put('interior', cl)
    put('interior', [dash, cons])
    sw_c = V(xs * 0.95, y_hp - p.get('wheel_reach', 0.45), hip_z + p.get('wheel_up', 0.36))
    sw = vl.steering_wheel('steering_wheel', sw_c, math.radians(p.get('wheel_tilt', -25)), p.get('wheel_r', 0.19), hi)
    put('steering_wheel', sw)
    put('body', body)
    if hi and fam == 'car':
        # grille and plates (baked into the bumpers), door handles, panel detail
        g = box('grille', (-W * 0.42, yF - 0.004, p.get('zc', 0.2) + 0.30), (W * 0.42, yF + 0.06, bf - 0.16), 'grille')
        put('bumper_f', g)
        for yy, n in ((yF - 0.002, 'bumper_f'), (yR + 0.002, 'bumper_r')):
            pz = p.get('zc', 0.2) + 0.30
            pl = box('plate', (-0.26, yy - 0.01, pz - 0.06), (0.26, yy + 0.01, pz + 0.06), 'plate')
            put(n, pl)
        for s, side in ((1, 'l'), (-1, 'r')):
            for d, yy in (('f', p['y_bpil'] - 0.18), ('r', p.get('y_rdoor', 0) - 0.16)):
                if 'door_%s_%s' % (d, side) in parts:
                    hd = box('handle', (s * (W - 0.01) if s > 0 else -(W + 0.012), yy - 0.08, p['belt'] - 0.10), ((W + 0.012) if s > 0 else -(W - 0.01), yy + 0.08, p['belt'] - 0.065), 'chrome' if p.get('chrome_handles') else 'trim_blk')
                    put('door_%s_%s' % (d, side), hd)
    for fn in p.get('extras', ()):
        fn(p, hi, put, parts)
    # pivots (hinges) and markers
    piv = {}
    for n, obs in parts.items():
        lo = Vector([min(min((o.matrix_world @ v.co)[i] for v in o.data.vertices) for o in obs if o.data.vertices) for i in range(3)])
        hi_ = Vector([max(max((o.matrix_world @ v.co)[i] for v in o.data.vertices) for o in obs if o.data.vertices) for i in range(3)])
        if n.startswith('door') or n.startswith('busdoor'):
            s = 1 if n.endswith('_l') else -1
            piv[n] = (hi_.x if s > 0 else lo.x, lo.y + 0.02, (lo.z + hi_.z) / 2)      # front edge, vertical axis (sliding / folding: the same edge)
        elif n.startswith('back_door'):
            s = 1 if n.endswith('_l') else -1
            piv[n] = (hi_.x if s > 0 else lo.x, hi_.y - 0.02, (lo.z + hi_.z) / 2)    # outer edge, vertical axis
        elif n in ('hopper', 'ladder', 'tipper', 'boom', 'bucket', 'tail_lift'):
            piv[n] = tuple(p.get('pivot_' + n, ((lo.x + hi_.x) / 2, hi_.y, lo.z)))
        elif n == 'bonnet':
            piv[n] = (0.0, hi_.y, hi_.z)                                           # at the cowl
        elif n == 'tailgate' and p.get('style') == 'pickup':
            piv[n] = (0.0, (lo.y + hi_.y) / 2, lo.z)                               # drops down on its bottom edge
        elif n in ('boot', 'tailgate'):
            piv[n] = (0.0, lo.y, hi_.z)                                            # at its front edge (roof / rear screen)
        elif n.startswith('wheel'):
            piv[n] = ((lo.x + hi_.x) / 2, (lo.y + hi_.y) / 2, zr)
        elif n == 'steering_wheel':
            piv[n] = tuple(sw_c)
        elif n in ('lightbar', 'roof_sign', 'beacons', 'speakers'):
            piv[n] = ((lo.x + hi_.x) / 2, (lo.y + hi_.y) / 2, lo.z)
        elif n.startswith('bumper'):
            piv[n] = ((lo.x + hi_.x) / 2, (lo.y + hi_.y) / 2, (lo.z + hi_.z) / 2)
        else:
            piv[n] = (0.0, 0.0, 0.0)
    for s, side in ((1, 'l'), (-1, 'r')):
        markers['entry_' + side] = (s * (W + 0.45), p['y_bpil'] - 0.35, 0.0)
        markers['head_' + side] = (s * W * 0.72, yF + 0.02, bf - 0.10)
        markers['tail_' + side] = (s * W * 0.75, yR - 0.01, S[-3]['zbl'] - 0.11)
    markers['exhaust'] = tuple(p.get('exhaust', (-W * 0.55, yR - 0.02, p.get('zc', 0.2) + 0.08)))
    for k, v in p.get('markers', {}).items():
        markers[k] = v
    return {'parts': parts, 'pivots': piv, 'markers': markers, 'axles': (yfa, yra), 'r': r}


# ====================================================================== extras and liveries
def text_decal(txt, centre, height, facing, key, depth=0.003):
    """raised lettering (high model only: it is baked into the texture). facing: 'l' / 'r' (side), 'f' / 'b' (ends), 'u' (up)"""
    cu = bpy.data.curves.new('t', 'FONT')
    cu.body = txt
    cu.align_x = 'CENTER'
    cu.align_y = 'CENTER'
    cu.size = height
    cu.extrude = depth
    ob = bpy.data.objects.new('t', cu)
    w.coll().objects.link(ob)
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
    bpy.data.objects.remove(ob)
    o = bpy.data.objects.new('txt', me)
    w.coll().objects.link(o)
    R = {'l': Matrix.Rotation(math.radians(90), 4, 'Z') @ Matrix.Rotation(math.radians(90), 4, 'X'),
         'r': Matrix.Rotation(math.radians(-90), 4, 'Z') @ Matrix.Rotation(math.radians(90), 4, 'X'),
         'f': Matrix.Rotation(math.radians(90), 4, 'X'),
         'b': Matrix.Rotation(math.radians(180), 4, 'Z') @ Matrix.Rotation(math.radians(90), 4, 'X'),
         'u': Matrix.Identity(4)}[facing]
    me.transform(Matrix.Translation(Vector(centre)) @ R)
    me.materials.append(w.MAT(key))
    return o


def lightbar(p, hi, put, parts):
    W, H = p['W'], p['H']
    yc = (p['y_roof_f'] + p['y_bpil']) / 2 + 0.05
    put('lightbar', box('lb', (-W * 0.62, yc - 0.14, H + 0.02), (W * 0.62, yc + 0.14, H + 0.06), 'trim_blk'))
    for s, k in ((1, 'lamp_red'), (-1, 'lamp_blue')):
        put('lightbar', box('lens', (0.02 if s > 0 else -W * 0.60, yc - 0.12, H + 0.06), (W * 0.60 if s > 0 else -0.02, yc + 0.12, H + 0.15), k))
    put('lightbar', box('lbf', (-W * 0.5, yc - 0.12, H), (W * 0.5, yc + 0.12, H + 0.025), 'trim_blk'))


def push_bar(p, hi, put, parts):
    W, L = p['W'], p['L']
    yF = -L / 2
    z0 = p.get('zc', 0.2) + 0.25
    for s in (1, -1):
        put('bumper_f', box('pbv', (s * 0.30 - 0.03, yF - 0.10, z0), (s * 0.30 + 0.03, yF - 0.04, p['bonnet_f'] - 0.02), 'trim_blk'))
    put('bumper_f', box('pbh', (-0.40, yF - 0.11, z0 + 0.12), (0.40, yF - 0.05, z0 + 0.20), 'trim_blk'))


def police_text(p, hi, put, parts):
    if not hi:
        return
    W = p['W']
    for s, side in ((1, 'l'), (-1, 'r')):
        yy = (p['y_bpil'] + p['y_rdoor']) / 2 + 0.05
        put('door_r_' + side, text_decal('POLICE', (s * (W + 0.002), yy, p['belt'] - 0.25), 0.16, side, 'paint_blk'))
        put('door_f_' + side, text_decal('911', (s * (W + 0.002), p['y_bpil'] - 0.45, p['belt'] - 0.24), 0.10, side, 'paint_blk'))


def roof_sign(p, hi, put, parts):
    W, H = p['W'], p['H']
    yc = (p['y_roof_f'] + p['y_bpil']) / 2 + 0.10
    put('roof_sign', box('rs', (-0.30, yc - 0.10, H + 0.02), (0.30, yc + 0.10, H + 0.20), 'plate'))
    if hi:
        for d, yy in (('f', yc - 0.101), ('b', yc + 0.101)):
            put('roof_sign', text_decal('TAXI', (0, yy, H + 0.11), 0.11, d, 'paint_blk'))


def taxi_checks(p, hi, put, parts):
    if not hi:
        return
    W = p['W']
    for s, side in ((1, 'l'), (-1, 'r')):
        for d, yy in (('f', p['y_bpil'] - 0.5), ('r', p['y_rdoor'] - 0.45)):
            for k in range(8):
                for j in range(2):
                    if (k + j) % 2 == 0:
                        y0 = yy - 0.32 + k * 0.08
                        z0 = p['belt'] - 0.16 + j * 0.05
                        put('door_%s_%s' % (d, side), box('chk', (s * W if s > 0 else -(W + 0.003), y0, z0), ((W + 0.003) if s > 0 else -W, y0 + 0.08, z0 + 0.05), 'paint_blk'))


def lv_police(n, c, nn):
    if n.startswith('door') or (n == 'body' and c.z > 1.2) or n in ('bonnet',) and False:
        return 'paint_wht'
    return 'paint_blk'


def lv_solid(key):
    return lambda n, c, nn: key


# ====================================================================== the fleet
SALOON = dict(style='sedan', L=4.75, W=0.91, H=1.45, belt=0.94, bonnet_f=0.76, wb=2.80, fo=0.95, r=0.33, fdoor=1.25, rdoor=0.85, deck=1.00)
FLEET = {
    'compact': dict(build=car, cls='compact', note='small three-door hatchback',
                    p=dict(style='hatch', doors=2, L=3.80, W=0.84, H=1.46, belt=0.90, bonnet_f=0.74, wb=2.42, fo=0.72, r=0.30, fdoor=1.30,
                           tail_run=0.22, rear_leg=0.70)),
    'hatch': dict(build=car, cls='compact', note='five-door family hatchback',
                  p=dict(style='hatch', L=4.25, W=0.875, H=1.48, belt=0.92, bonnet_f=0.74, wb=2.62, fo=0.85, r=0.31, fdoor=1.08, rdoor=0.80,
                         tail_run=0.28)),
    'saloon': dict(build=car, cls='saloon', note='mid-size four-door saloon', p=dict(SALOON)),
    'saloon_exec': dict(build=car, cls='saloon', note='long executive saloon, chrome handles',
                        p=dict(style='sedan', L=5.05, W=0.935, H=1.47, belt=0.96, bonnet_f=0.80, wb=3.00, fo=1.00, r=0.34, fdoor=1.30, rdoor=0.95,
                               deck=1.03, chrome_handles=True, spokes=10)),
    'wagon': dict(build=car, cls='saloon', note='estate car (station wagon)',
                  p=dict(style='wagon', L=4.85, W=0.91, H=1.50, belt=0.94, bonnet_f=0.76, wb=2.82, fo=0.95, r=0.33, fdoor=1.25, rdoor=0.85,
                         tail_run=0.20, quarter_glass=True)),
    'coupe': dict(build=car, cls='sports', note='two-door coupe',
                  p=dict(style='coupe', doors=2, L=4.55, W=0.91, H=1.36, belt=0.90, bonnet_f=0.72, wb=2.65, fo=0.95, r=0.33, fdoor=1.35,
                         screen_run=0.80, rscreen_run=0.70, roof_w=0.76, rear_leg=0.70, deck=0.95)),
    'sports': dict(build=car, cls='sports', note='low two-seat sports car',
                   p=dict(style='coupe', doors=2, L=4.35, W=0.96, H=1.18, belt=0.82, bonnet_f=0.64, wb=2.55, fo=0.95, r=0.33, zc=0.14, fdoor=1.30,
                          screen_run=0.85, rscreen_run=0.80, roof_w=0.72, hip=0.24, rear_seat=False, deck=0.86, spokes=10)),
    'muscle': dict(build=car, cls='sports', note='long-bonnet two-door muscle car',
                   p=dict(style='coupe', doors=2, L=4.85, W=0.94, H=1.33, belt=0.92, bonnet_f=0.84, wb=2.80, fo=1.05, r=0.34, fdoor=1.40,
                          rscreen_run=0.65, roof_w=0.78, deck=0.98, rim='rim_steel', chrome_handles=True)),
    'suv': dict(build=car, cls='suv', note='mid-size SUV',
                p=dict(style='suv', L=4.70, W=0.94, H=1.72, belt=1.10, bonnet_f=0.95, wb=2.80, fo=0.90, r=0.37, zc=0.28, fdoor=1.15, rdoor=0.90,
                       tail_run=0.22, quarter_glass=True, hip=0.40)),
    'suv_large': dict(build=car, cls='suv', note='large boxy SUV',
                      p=dict(style='suv', L=5.10, W=0.99, H=1.88, belt=1.18, bonnet_f=1.05, wb=3.00, fo=0.95, r=0.39, zc=0.30, fdoor=1.20, rdoor=0.95,
                             roof_w=0.88, tail_run=0.15, quarter_glass=True, hip=0.42, rim='rim_steel')),
    'crossover': dict(build=car, cls='suv', note='compact crossover',
                      p=dict(style='suv', L=4.45, W=0.91, H=1.60, belt=1.02, bonnet_f=0.86, wb=2.65, fo=0.88, r=0.35, zc=0.24, fdoor=1.10, rdoor=0.85,
                             tail_run=0.35, hip=0.38)),
    'pickup': dict(build=car, cls='pickup', note='full-size crew-cab pickup',
                   p=dict(style='pickup', L=5.35, W=0.98, H=1.82, belt=1.15, bonnet_f=1.05, wb=3.35, fo=0.95, r=0.38, zc=0.30, fdoor=1.10, rdoor=0.72,
                          bed_top=1.10, hip=0.42, rim='rim_steel')),
    'taxi': dict(build=car, cls='service', note='yellow taxi on the saloon, roof sign, checker band',
                 p=dict(SALOON, livery=lv_solid('paint_yel'), extras=(roof_sign, taxi_checks))),
    'police': dict(build=car, cls='emergency', note='police cruiser: black and white, light bar, push bar',
                   p=dict(SALOON, L=4.95, wb=2.90, fo=1.00, livery=lv_police, extras=(lightbar, push_bar, police_text), rim='rim_steel')),
    # ---- vans
    'minivan': dict(build=car, cls='van', note='seven-seat minivan, sliding doors both sides',
                    p=dict(style='minivan', L=5.10, W=0.99, H=1.76, belt=1.05, bonnet_f=0.98, wb=3.03, fo=0.95, r=0.36, zc=0.22, fdoor=1.05,
                           rdoor=0.95, rear_zone='slide', quarter_zone='side', slide_side='both', tail_run=0.20, screen_run=1.00, hip=0.40)),
    'van_panel': dict(build=car, cls='van', note='panel van, sliding side door, barn doors, no rear windows',
                      p=dict(style='van', L=5.25, W=1.00, H=2.05, belt=1.08, bonnet_f=1.02, wb=3.30, fo=0.95, r=0.36, zc=0.25, fdoor=1.05,
                             rdoor=1.10, screen_run=0.75, rear_zone='slide', quarter_zone='side', windows=False, cap_r=None, hip=0.42,
                             rear_seat=False, rim='rim_steel', extras=(vm.van_back, vm.bumpers_box))),
    'van_delivery': dict(build=car, cls='van', note='high-roof delivery van',
                         p=dict(style='van', L=5.95, W=1.02, H=2.62, belt=1.10, bonnet_f=1.05, wb=3.65, fo=0.95, r=0.37, zc=0.26, fdoor=1.05,
                                rdoor=1.15, screen_run=0.80, rear_zone='slide', quarter_zone='side', windows=False, cap_r=None, hip=0.44,
                                rear_seat=False, rim='rim_steel', extras=(vm.van_back, vm.bumpers_box))),
    'campaign_a': dict(build=car, cls='van', note='political campaign van: blue and white, loudspeakers on the roof (fictional candidate)',
                       p=dict(style='van', L=5.25, W=1.00, H=2.05, belt=1.08, bonnet_f=1.02, wb=3.30, fo=0.95, r=0.36, zc=0.25, fdoor=1.05,
                              rdoor=1.10, screen_run=0.75, rear_zone='slide', quarter_zone='side', windows=False, cap_r=None, hip=0.42,
                              rear_seat=False, livery=lambda n, c, nn: 'paint_blu' if c.z < 0.75 else 'paint_wht',
                              slogan='VOTE HALVERSON', slogan_sub='FOR MAYOR - A CITY THAT WORKS', slogan_back='HALVERSON',
                              slogan_key='paint_blu', slogan_key2='paint_red',
                              extras=(vm.van_back, vm.bumpers_box, vm.roof_speakers, vm.campaign_livery))),
    'campaign_b': dict(build=car, cls='van', note='political campaign van: red and white, roof billboard (fictional candidate)',
                       p=dict(style='van', L=5.25, W=1.00, H=2.05, belt=1.08, bonnet_f=1.02, wb=3.30, fo=0.95, r=0.36, zc=0.25, fdoor=1.05,
                              rdoor=1.10, screen_run=0.75, rear_zone='slide', quarter_zone='side', windows=False, cap_r=None, hip=0.42,
                              rear_seat=False, livery=lambda n, c, nn: 'paint_red' if c.z < 0.75 else 'paint_wht',
                              slogan='RE-ELECT OKAFOR', slogan_sub='COUNCIL DISTRICT 4', slogan_back='OKAFOR', slogan2='OKAFOR 4 COUNCIL',
                              slogan_key='paint_red', slogan_key2='paint_blu',
                              extras=(vm.van_back, vm.bumpers_box, vm.roof_board, vm.campaign_livery))),
    'ambulance': dict(build=car, cls='emergency', note='ambulance: van cab and a box body, beacons, high-visibility band',
                      p=dict(style='cab', L=6.60, W=1.02, H=2.10, belt=1.10, bonnet_f=1.04, wb=3.75, fo=0.95, r=0.37, zc=0.26, fdoor=1.05,
                             doors=2, screen_run=0.80, y_cb=-0.55, cap_r='body', hip=0.44, rear_seat=False, rim='rim_steel', duals=(1,),
                             livery=lambda n, c, nn: 'paint_wht', box_w=1.12, box_y=(-0.50, 3.25), box_z=(0.78, 2.85),
                             tail_z=(0.80, 1.20), extras=(vm.ambulance_box, vm.bumpers_box, vm.lightbar_cab))),
    # ---- trucks (cab over the front axle)
    'lorry_box': dict(build=car, cls='truck', note='box lorry, 7.5 t class, barn doors',
                      p=dict(family='cabover', L=7.60, W=1.17, H=2.85, belt=1.95, cab_floor=1.10, fo=1.20, wb=4.20, r=0.48, tyre_w=0.26,
                             duals=(1,), fdoor=1.05, cap_f='body', cap_r='body', arches=False, hip_z=1.62, rear_seat=False, wheel_r=0.22,
                             wheel_tilt=-55, wheel_reach=0.40, wheel_up=0.30, dash_z=1.98, livery=lambda n, c, nn: 'paint',
                             box_w=1.25, box_y=(-1.95, 3.70), box_z=(1.18, 3.55), box_front_bumper=True, bumper_fz=(0.45, 0.85),
                             bumper_rz=(0.70, 0.90), head_z=(0.88, 1.02), tail_z=(0.92, 1.05), front_face=-3.80, rim='rim_steel',
                             extras=(vm.chassis, vm.box_body, vm.bumpers_box, vm.lamps_square, vm.mirrors_truck))),
    'tipper': dict(build=car, cls='truck', note='tipper truck, orange dump body',
                   p=dict(family='cabover', L=6.90, W=1.17, H=2.85, belt=1.95, cab_floor=1.10, fo=1.20, wb=3.90, r=0.48, tyre_w=0.26,
                          duals=(1,), fdoor=1.05, cap_f='body', cap_r='body', arches=False, hip_z=1.62, rear_seat=False, wheel_r=0.22,
                          wheel_tilt=-55, wheel_reach=0.40, wheel_up=0.30, dash_z=1.98, livery=lambda n, c, nn: 'paint_wht',
                          box_w=1.18, box_y=(-1.55, 3.35), box_z=(1.22, 2.10), box_front_bumper=True, bumper_fz=(0.45, 0.85),
                          bumper_rz=(0.70, 0.90), head_z=(0.88, 1.02), tail_z=(0.92, 1.05), front_face=-3.45, rim='rim_steel',
                          extras=(vm.chassis, vm.tipper, vm.bumpers_box, vm.lamps_square, vm.mirrors_truck))),
    'garbage_truck': dict(build=car, cls='truck', note='refuse truck: compactor body and a rear loading hopper',
                          p=dict(family='cabover', L=8.60, W=1.20, H=2.75, belt=1.90, cab_floor=1.05, fo=1.30, wb=4.60, r=0.50, tyre_w=0.27,
                                 duals=(1,), fdoor=1.05, cap_f='body', cap_r='body', arches=False, hip_z=1.55, rear_seat=False, wheel_r=0.22,
                                 wheel_tilt=-55, wheel_reach=0.40, wheel_up=0.30, dash_z=1.93, livery=lambda n, c, nn: 'paint_wht',
                                 box_w=1.24, box_y=(-2.20, 4.30), box_z=(1.20, 3.45), box_key='paint_grn', hopper_len=1.45,
                                 box_front_bumper=True, bumper_fz=(0.45, 0.85), bumper_rz=(0.40, 0.55), head_z=(0.86, 1.00),
                                 tail_z=(1.10, 1.30), front_face=-4.30, rim='rim_steel',
                                 extras=(vm.chassis, vm.garbage, vm.bumpers_box, vm.lamps_square, vm.mirrors_truck))),
    'fire_truck': dict(build=car, cls='emergency', note='fire engine: crew cab, locker body, ladder, light bar',
                       p=dict(family='cabover', L=9.30, W=1.24, H=3.00, belt=2.00, cab_floor=1.10, fo=1.40, wb=4.90, r=0.52, tyre_w=0.30,
                              duals=(1,), fdoor=1.30, cap_f='body', cap_r='body', arches=False, hip_z=1.65, rear_seat=False, wheel_r=0.24,
                              wheel_tilt=-55, wheel_reach=0.40, wheel_up=0.30, dash_z=2.03, livery=lambda n, c, nn: 'paint_red' if c.z < 2.55 else 'paint_wht',
                              box_w=1.25, box_y=(-1.85, 4.55), box_z=(1.10, 2.95), box_front_bumper=True, bumper_fz=(0.40, 0.85),
                              bumper_rz=(0.55, 0.80), head_z=(0.90, 1.05), tail_z=(0.95, 1.10), front_face=-4.65, rim='rim',
                              extras=(vm.chassis, vm.fire_body, vm.bumpers_box, vm.lamps_square, vm.mirrors_truck, vm.lightbar_cab))),
    'utility_truck': dict(build=car, cls='truck', note='utility truck: service body with lockers, aerial lift boom and bucket',
                          p=dict(style='pickup', doors=2, no_bed=True, L=6.40, W=1.00, H=1.98, belt=1.20, bonnet_f=1.12, wb=4.10, fo=1.00,
                                 r=0.40, zc=0.32, fdoor=1.15, bed_top=1.15, hip=0.42, rear_seat=False, rim='rim_steel', duals=(1,), tyre_w=0.22,
                                 cap_r='body', livery=lambda n, c, nn: 'paint_wht', box_w=1.15, box_z=(0.95, 1.85),
                                 extras=(vm.utility_body_auto, vm.bumpers_box))),
    # ---- buses
    'bus_city': dict(build=car, cls='bus', note='12 m low-floor city bus, two folding doors',
                     p=dict(family='bus', L=12.0, W=1.27, H=3.05, belt=1.25, zc=0.30, fo=2.60, wb=5.90, r=0.50, tyre_w=0.28, duals=(1,),
                            door1=(0.25, 1.40), door2=(5.20, 6.40), cap_f='body', cap_r='body', arches=True, hip_z=1.10, y_hp=-5.0,
                            front_seats=('l',), rear_seat=False, wheel_r=0.24, wheel_tilt=-70, wheel_reach=0.45, wheel_up=0.25, dash_z=1.20,
                            livery=lambda n, c, nn: 'paint_wht' if c.z > 1.0 else 'paint', box_front_bumper=True, bumper_fz=(0.30, 0.55),
                            bumper_rz=(0.30, 0.55), head_z=(0.55, 0.75), tail_z=(0.60, 1.10), front_face=-6.0, rim='rim',
                            seat_rows=[-6.0 + 2.0 + 0.85 * k for k in range(12)],
                            extras=(vm.bus_seats, vm.bumpers_box, vm.lamps_square, vm.mirrors_truck))),
    'bus_mini': dict(build=car, cls='bus', note='8 m midibus, two folding doors',
                     p=dict(family='bus', L=8.0, W=1.18, H=2.85, belt=1.20, zc=0.28, fo=1.90, wb=4.20, r=0.42, tyre_w=0.24, duals=(1,),
                            door1=(0.25, 1.25), door2=(3.70, 4.70), cap_f='body', cap_r='body', arches=True, hip_z=1.05, y_hp=-3.0,
                            front_seats=('l',), rear_seat=False, wheel_r=0.22, wheel_tilt=-65, wheel_reach=0.42, wheel_up=0.25, dash_z=1.15,
                            livery=lambda n, c, nn: 'paint_wht' if c.z > 0.95 else 'paint', box_front_bumper=True, bumper_fz=(0.28, 0.50),
                            bumper_rz=(0.28, 0.50), head_z=(0.52, 0.70), tail_z=(0.55, 1.00), front_face=-4.0, rim='rim',
                            seat_rows=[-4.0 + 1.8 + 0.85 * k for k in range(7)],
                            extras=(vm.bus_seats, vm.bumpers_box, vm.lamps_square, vm.mirrors_truck))),
}
