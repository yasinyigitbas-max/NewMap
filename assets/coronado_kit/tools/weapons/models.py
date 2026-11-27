"""The weapons, one builder per model: build(hi) returns the parts. hi=False is the game model (within budget);
hi=True is the bake source (bevels, cuts, small parts, surface relief). Author space: Z up, muzzle -Y, origin at grip_r.
Most guns are drawn in 'gun coordinates' first: Yp forward from the rear of the gun, Z up from its lowest point,
then moved so the right-hand grip point sits at the origin (P / P3 below).
All models are generic: no maker's shapes copied part for part, no names or logos."""
import math
import wlib as w
from wlib import box, extrude, sweep, lathe, loft, cyl, rrect, circle, bevel, cut, union, split_mat, join, mirror_x, smooth, flat


def mk(Gy, Gz):
    P = lambda Yp, Z: (-(Yp - Gy), Z - Gz)
    P3 = lambda x, Yp, Z: (x, -(Yp - Gy), Z - Gz)
    return P, P3


def catmull(prof, n=4):
    """smooth a (t, r) profile for the high model"""
    out = []
    for i in range(len(prof) - 1):
        p0 = prof[max(i - 1, 0)]; p1 = prof[i]; p2 = prof[i + 1]; p3 = prof[min(i + 2, len(prof) - 1)]
        for k in range(n):
            s = k / n
            out.append(tuple(0.5 * ((2 * p1[j]) + (-p0[j] + p2[j]) * s + (2 * p0[j] - 5 * p1[j] + 4 * p2[j] - p3[j]) * s * s
                                    + (-p0[j] + 3 * p1[j] - 3 * p2[j] + p3[j]) * s ** 3) for j in range(2)))
    out.append(prof[-1])
    return out


def cutters(objs, name='cutter'):
    objs = [o for o in objs if o]
    return join(objs, name) if len(objs) > 1 else objs[0]


# ====================================================================== baseball bat
def bat(hi):
    T0 = 0.15                     # grip_r sits 15 cm from the knob end
    p0 = (0, T0, 0)
    prof = [(0, 0), (0.0004, 0.0205), (0.006, 0.0245), (0.013, 0.0222), (0.022, 0.0136), (0.10, 0.0126), (0.30, 0.0136),
            (0.45, 0.0200), (0.58, 0.0290), (0.66, 0.0326), (0.80, 0.0335), (0.826, 0.0312), (0.836, 0.0205), (0.838, 0)]
    if not hi:
        return [lathe('bat', prof, 10, 'ash', p0)]
    hp = catmull(prof[1:-1], 4)
    hp = [(0, 0)] + hp + [(0.838, 0)]
    body = lathe('bat_h', hp, 40, 'ash', p0)
    # grip tape over the handle, and the stained barrel (two-tone bat)
    tp = [(t, r + 0.0010) for t, r in hp if 0.024 <= t <= 0.30]
    tape = lathe('tape', [(0.022, 0.0138)] + tp + [(0.302, 0.0137)], 40, 'tape', p0, close_ends=False)
    bp = [(t, r + 0.00035) for t, r in hp if t >= 0.50]
    barrel = lathe('stain', bp + [(0.8382, 0)], 40, 'ash_dark', p0, close_ends=False)
    # knob: stained too
    kp = [(0, 0)] + [(t, r + 0.0003) for t, r in hp if t <= 0.022]
    knob = lathe('knob', kp, 40, 'ash_dark', p0, close_ends=False)
    return [body, tape, barrel, knob]


# ====================================================================== polymer pistol (striker fired, generic)
def pistol_polymer(hi):
    P, P3 = mk(0.026, 0.052)
    parts = []
    # --- slide: chamfered top edges, sloped nose
    hw, z0, c = 0.0127, 0.098, 0.0032

    def sec(Yp, z1):
        return [P3(hw, Yp, z0), P3(hw, Yp, z1 - c), P3(hw - c, Yp, z1), P3(-hw + c, Yp, z1), P3(-hw, Yp, z1 - c), P3(-hw, Yp, z0)]
    slide = loft('slide', [sec(0.0, 0.1255), sec(0.004, 0.128), sec(0.176, 0.128), sec(0.186, 0.1185)], 'parkerized')
    if hi:
        bevel(slide, 0.0007, 2)
        cs = []
        for k in range(5):                                  # rear cocking serrations, both sides (wide: they must read
            y0 = 0.008 + k * 0.0060                         # at the page's ~0.5 px/mm normal map)
            for s in (1, -1):
                cs.append(box('sr', (s * 0.0117 if s > 0 else -0.03, -(y0 + 0.0028 - 0.026), 0.1005 - 0.052),
                              (0.03 if s > 0 else -0.0117, -(y0 - 0.026), 0.1245 - 0.052), None))
        cs.append(box('port', P3(0.0035, 0.149, 0.115), P3(0.03, 0.100, 0.14), None))       # ejection port
        cs.append(cyl('bore', P3(0, 0.195, 0.1105), P3(0, 0.181, 0.1105), 0.0072, 0.0072, 24, None))
        cut(slide, cutters(cs))
        hood = box('hood', P3(-0.0030, 0.149, 0.104), P3(0.0118, 0.1005, 0.1262), 'blued')
        bevel(hood, 0.0005, 1)
        barrel = cyl('barrel', P3(0, 0.1845, 0.1105), P3(0, 0.170, 0.1105), 0.0068, 0.0068, 24, 'steel')
        cut(barrel, cyl('b2', P3(0, 0.19, 0.1105), P3(0, 0.180, 0.1105), 0.0046, 0.0046, 16, None))
        extr = box('extr', P3(0.0124, 0.150, 0.1135), P3(0.0131, 0.120, 0.1175), 'parkerized')
        parts += [hood, barrel, extr]
    parts.append(slide)
    # --- frame: dust cover + raked grip (20 deg), beavertail
    fr = [(-0.004, 0.098), (0.172, 0.098), (0.172, 0.0835), (0.120, 0.0835), (0.068, 0.0835), (0.0612, 0.084),
          (0.0343, 0.0105), (-0.0147, 0.0105), (0.0122, 0.084), (0.0045, 0.0905), (-0.0055, 0.0945)]
    frame = extrude('frame', [P(*p) for p in fr], -0.0145, 0.0145, 'poly_black')
    if hi:
        bevel(frame, 0.0024, 3, 30)
        cs = [box('rail%d' % k, P3(-0.03, y + 0.004, 0.0820), P3(0.03, y, 0.0856), None) for k, y in enumerate((0.140, 0.152))]
        for z in (0.066, 0.046, 0.028):                     # finger grooves on the front strap
            Yf = 0.0343 + (z - 0.0105) / (0.084 - 0.0105) * (0.0612 - 0.0343)
            cs.append(cyl('fg', P3(-0.03, Yf + 0.0035 * 0.94, z - 0.0035 * 0.34), P3(0.03, Yf + 0.0035 * 0.94, z - 0.0035 * 0.34),
                          0.0055, 0.0055, 16, None))
        cut(frame, cutters(cs))
        Gz, Gy = 0.052, 0.026
        split_mat(frame, 'poly_stip', lambda c: c.z < 0.080 - Gz and c.z > 0.014 - Gz and c.y > -(0.066 - Gy),
                  planes=[((0, 0, 0.080 - Gz), (0, 0, 1)), ((0, 0, 0.014 - Gz), (0, 0, 1))])
        # controls: slide stop (left), takedown tabs, magazine release
        ss = box('stop', P3(-0.0152, 0.082, 0.0935), P3(-0.0143, 0.058, 0.0972), 'steel')
        td = box('td', P3(-0.0150, 0.1035, 0.0905), P3(0.0150, 0.0985, 0.0965), 'steel')
        mr = box('mrel', P3(-0.0151, 0.0705, 0.0745), P3(0.0151, 0.0630, 0.0815), 'poly_black')
        for o in (ss, td, mr):
            bevel(o, 0.0003, 1)
        parts += [ss, td, mr]
    parts.append(frame)
    # --- trigger guard (square front), trigger
    gpath = [P3(0, 0.118, 0.0850), P3(0, 0.1165, 0.066), P3(0, 0.111, 0.0595), P3(0, 0.098, 0.0578), P3(0, 0.062, 0.0588),
             P3(0, 0.050, 0.0625)]
    guard = sweep('guard', gpath, rrect(0.0105, 0.0042, 0.0012, 1 if not hi else 3), 'poly_black')
    parts.append(guard)
    trig = extrude('trig', [P(*p) for p in [(0.0785, 0.0835), (0.0815, 0.0755), (0.0805, 0.0675), (0.0770, 0.0640),
                                            (0.0752, 0.0660), (0.0765, 0.0745), (0.0745, 0.0835)]], -0.0032, 0.0032, 'poly_black')
    if hi:
        bevel(trig, 0.0006, 2)
        blade = box('blade', P3(-0.0008, 0.0790, 0.0680), P3(0.0008, 0.0770, 0.0790), 'poly_black')
        parts.append(blade)
    parts.append(trig)
    # --- magazine floor plate
    mag = extrude('mag', [P(*p) for p in [(-0.0170, 0.0108), (0.0352, 0.0108), (0.0336, 0.0030), (-0.0160, 0.0030)]],
                  -0.0150, 0.0150, 'poly_black')
    if hi:
        bevel(mag, 0.0012, 2)
    parts.append(mag)
    # --- sights: rear notch with a U outline, front post with a white dot
    rs = box('rsight', P3(-0.0058, 0.0125, 0.1275), P3(0.0058, 0.0040, 0.1340), 'poly_black')
    fs = box('fsight', P3(-0.0019, 0.1755, 0.1275), P3(0.0019, 0.1700, 0.1340), 'poly_black')
    if hi:
        cut(rs, box('notch', P3(-0.0017, 0.02, 0.1305), P3(0.0017, 0.0, 0.14), None))
        bevel(rs, 0.0004, 1)
        bevel(fs, 0.0004, 1)
        dot = cyl('dot', P3(0, 0.1702, 0.1318), P3(0, 0.1696, 0.1318), 0.0011, 0.0011, 12, 'sight_dot')
        parts.append(dot)
    parts += [rs, fs]
    return parts


# ====================================================================== service pistol (metal frame, hammer, wood grips)
GS = (0.030, 0.055)


def pistol_service(hi):
    P, P3 = mk(*GS)
    parts = []
    hw, z0 = 0.0145, 0.100

    def sec(Yp, k=1.0):
        pts = [(hw, z0), (hw, 0.1245), (0.0115, 0.1308), (0.0055, 0.1330), (-0.0055, 0.1330), (-0.0115, 0.1308), (-hw, 0.1245), (-hw, z0)]
        cz = 0.116
        return [P3(x * k, Yp, cz + (z - cz) * k) for x, z in pts]
    slide = loft('slide', [sec(-0.004, 0.95), sec(0.0, 1.0), sec(0.199), sec(0.206, 0.9)], 'blued')
    if hi:
        bevel(slide, 0.0007, 2)
        cs = []
        for k in range(6):
            y0 = 0.005 + k * 0.0055
            cs.append(box('sr', P3(0.0135, y0 + 0.0025, 0.1015), P3(0.03, y0, 0.1235), None))
            cs.append(box('sl', P3(-0.03, y0 + 0.0025, 0.1015), P3(-0.0135, y0, 0.1235), None))
        cs.append(box('port', P3(0.004, 0.150, 0.117), P3(0.03, 0.112, 0.14), None))
        cs.append(cyl('bore', P3(0, 0.215, 0.1125), P3(0, 0.200, 0.1125), 0.0079, 0.0079, 24, None))
        cut(slide, cutters(cs))
        hood = cyl('hood', P3(0, 0.150, 0.1125), P3(0, 0.112, 0.1125), 0.0072, 0.0072, 20, 'steel')
        lev = [box('dec', P3(s * 0.0143, 0.024, 0.1175), P3(s * 0.0160, 0.009, 0.1235), 'blued') for s in (1, -1)]
        parts += [hood] + lev
    parts.append(slide)
    barrel = cyl('barrel', P3(0, 0.2095, 0.1125), P3(0, 0.200, 0.1125), 0.0070, 0.0070, 8 if not hi else 24, 'steel')
    if hi:
        cut(barrel, cyl('b2', P3(0, 0.22, 0.1125), P3(0, 0.205, 0.1125), 0.0047, 0.0047, 16, None))
    parts.append(barrel)
    fr = [(-0.008, 0.100), (0.200, 0.100), (0.200, 0.0855), (0.128, 0.0855), (0.072, 0.0855), (0.064, 0.0860),
          (0.0416, 0.008), (-0.0114, 0.008), (0.0121, 0.090), (0.0040, 0.0940), (-0.0100, 0.0970)]
    frame = extrude('frame', [P(*p) for p in fr], -0.0150, 0.0150, 'alu_black')
    if hi:
        bevel(frame, 0.0018, 3, 30)
        cs = [box('rail%d' % k, P3(-0.03, y + 0.004, 0.0840), P3(0.03, y, 0.0870), None) for k, y in enumerate((0.150, 0.165, 0.180))]
        cut(frame, cutters(cs))
        ss = box('stop', P3(-0.0160, 0.082, 0.0950), P3(-0.0148, 0.050, 0.0985), 'blued')
        pin = cyl('pin', P3(-0.0162, 0.090, 0.093), P3(0.0162, 0.090, 0.093), 0.0018, 0.0018, 12, 'steel')
        mr = box('mrel', P3(-0.0158, 0.068, 0.074), P3(-0.0145, 0.060, 0.082), 'blued')
        parts += [ss, pin, mr]
    parts.append(frame)
    # grip panels (walnut, checkered), proud of the frame on both sides
    gp = [(0.0170, 0.0835), (0.0575, 0.0835), (0.0380, 0.0135), (-0.0070, 0.0135)]
    for s in (1, -1):
        pan = extrude('panel', [P(*p) for p in gp], s * 0.0140, s * 0.0182, 'walnut_chk')
        if hi:
            bevel(pan, 0.0016, 3, 30)
            scr = cyl('screw', P3(s * 0.0178, 0.0195, 0.040), P3(s * 0.0188, 0.0195, 0.040), 0.0028, 0.0026, 12, 'blued')
            parts.append(scr)
        parts.append(pan)
    gpath = [P3(0, 0.128, 0.0870), P3(0, 0.1265, 0.0720), P3(0, 0.121, 0.0625), P3(0, 0.110, 0.0565), P3(0, 0.090, 0.0560),
             P3(0, 0.068, 0.0585), P3(0, 0.056, 0.0650)]
    if not hi:
        gpath = [gpath[0], gpath[2], gpath[4], gpath[6]]
    guard = sweep('guard', gpath, rrect(0.0110, 0.0045, 0.0012, 3) if hi else [(0.0055, 0.00225), (-0.0055, 0.00225), (-0.0055, -0.00225), (0.0055, -0.00225)], 'alu_black')
    parts.append(guard)
    trig = extrude('trig', [P(*p) for p in [(0.0890, 0.0860), (0.0935, 0.0770), (0.0945, 0.0690), (0.0905, 0.0630), (0.0880, 0.0645),
                                            (0.0905, 0.0700), (0.0895, 0.0770), (0.0850, 0.0860)]], -0.0033, 0.0033, 'blued')
    if hi:
        bevel(trig, 0.0007, 2)
    parts.append(trig)
    ham = extrude('hammer', [P(*p) for p in [(-0.0020, 0.1000), (0.0060, 0.1000), (0.0040, 0.1150), (-0.0060, 0.1240), (-0.0135, 0.1265),
                                             (-0.0145, 0.1225), (-0.0075, 0.1175), (-0.0055, 0.1060)]], -0.0042, 0.0042, 'blued')
    if hi:
        bevel(ham, 0.0007, 2)
        for k in range(4):
            cut(ham, box('hs', P3(-0.01, -0.0140 + k * 0.0018 + 0.0008, 0.1235), P3(0.01, -0.0140 + k * 0.0018, 0.13), None))
    parts.append(ham)
    mag = extrude('mag', [P(*p) for p in [(-0.0125, 0.0088), (0.0435, 0.0088), (0.0425, 0.0005), (-0.0115, 0.0005)]], -0.0148, 0.0148, 'alu_black')
    if hi:
        bevel(mag, 0.0012, 2)
    parts.append(mag)
    rs = box('rsight', P3(-0.0058, 0.0105, 0.1318), P3(0.0058, 0.0020, 0.1375), 'blued')
    fs = box('fsight', P3(-0.0016, 0.1985, 0.1318), P3(0.0016, 0.1905, 0.1372), 'blued')
    if hi:
        cut(rs, box('notch', P3(-0.0016, 0.02, 0.1345), P3(0.0016, 0.0, 0.14), None))
        bevel(rs, 0.0004, 1)
        bevel(fs, 0.0004, 1)
        dots = [cyl('dot', P3(x, 0.0020, 0.1352), P3(x, 0.0016, 0.1352), 0.0009, 0.0009, 10, 'sight_dot') for x in (0.0035, -0.0035)]
        dots.append(cyl('dot', P3(0, 0.1907, 0.1352), P3(0, 0.1901, 0.1352), 0.0009, 0.0009, 10, 'sight_dot'))
        parts += dots
    parts += [rs, fs]
    return parts


# ====================================================================== carbine rifle (gas-operated, flat-top, generic)
GR = (0.302, -0.068)


def rifle(hi):
    P, P3 = mk(*GR)
    parts = []
    seg = 24 if hi else 8
    # stock + butt pad
    st = [(0.012, 0.020), (0.175, 0.020), (0.175, -0.026), (0.100, -0.034), (0.024, -0.096), (0.012, -0.100)]
    stock = extrude('stock', [P(*p) for p in st], -0.0215, 0.0215, 'poly_black')
    bevel(stock, 0.0045 if hi else 0.004, 3 if hi else 1, 30)
    pad = extrude('pad', [P(*p) for p in [(0.000, 0.020), (0.0125, 0.020), (0.0125, -0.100), (0.000, -0.103)]], -0.022, 0.022, 'rubber')
    if hi:
        bevel(pad, 0.003, 2)
        cs = [box('sl', P3(-0.03, 0.150, 0.0218), P3(0.03, 0.050, 0.028), None)]
        cut(stock, cutters(cs))
    tube = cyl('tube', P3(0, 0.150, 0.0), P3(0, 0.258, 0.0), 0.0145, 0.0145, seg, 'alu_black')
    parts += [stock, pad, tube]
    # lower receiver
    lw = [(0.255, 0.012), (0.505, 0.012), (0.505, -0.010), (0.468, -0.014), (0.465, -0.064), (0.398, -0.064), (0.397, -0.028),
          (0.335, -0.028), (0.290, -0.026), (0.262, -0.018), (0.255, -0.006)]
    lower = extrude('lower', [P(*p) for p in lw], -0.0115, 0.0115, 'alu_black')
    if hi:
        bevel(lower, 0.0015, 2, 30)
        flare = extrude('flare', [P(*p) for p in [(0.398, -0.040), (0.465, -0.040), (0.466, -0.064), (0.397, -0.064)]], -0.0135, 0.0135, 'alu_black')
        bevel(flare, 0.0012, 2)
        sel = cyl('sel', P3(-0.0128, 0.318, -0.010), P3(-0.0118, 0.318, -0.010), 0.0055, 0.0055, 16, 'alu_black')
        mrel = cyl('mrel', P3(0.0115, 0.405, -0.030), P3(0.0135, 0.405, -0.030), 0.0042, 0.0042, 16, 'steel')
        pins = [cyl('pin', P3(-0.0122, y, z), P3(0.0122, y, z), 0.0022, 0.0022, 12, 'steel') for y, z in ((0.358, -0.012), (0.330, -0.012), (0.497, -0.002), (0.270, 0.004))]
        parts += [flare, sel, mrel] + pins
    parts.append(lower)
    gpath = [P3(0, 0.399, -0.050), P3(0, 0.390, -0.0625), P3(0, 0.345, -0.0625), P3(0, 0.333, -0.052)]
    parts.append(sweep('guard', gpath, [(0.008, 0.002), (-0.008, 0.002), (-0.008, -0.002), (0.008, -0.002)], 'alu_black'))
    trig = extrude('trig', [P(*p) for p in [(0.368, -0.026), (0.371, -0.040), (0.367, -0.050), (0.362, -0.049), (0.365, -0.040), (0.362, -0.026)]], -0.003, 0.003, 'steel')
    parts.append(trig)
    grip = extrude('grip', [P(*p) for p in [(0.334, -0.026), (0.298, -0.024), (0.268, -0.110), (0.276, -0.118), (0.304, -0.118), (0.316, -0.090),
                                            (0.323, -0.064), (0.334, -0.040)]], -0.0135, 0.0135, 'poly_stip')
    bevel(grip, 0.0045 if hi else 0.004, 3 if hi else 1, 30)
    parts.append(grip)
    mg = [(0.399, -0.040), (0.461, -0.040), (0.464, -0.090), (0.474, -0.150), (0.492, -0.205), (0.494, -0.214), (0.426, -0.222),
          (0.424, -0.213), (0.410, -0.155), (0.402, -0.100)]
    mag = extrude('mag', [P(*p) for p in mg], -0.0112, 0.0112, 'poly_tan')
    if hi:
        bevel(mag, 0.0016, 2, 30)
    parts.append(mag)
    # upper receiver, rail, charging handle, forward assist
    upper = box('upper', P3(-0.0125, 0.520, 0.012), P3(0.0125, 0.255, 0.031), 'alu_black')
    rail = box('rail', P3(-0.0105, 0.835, 0.031), P3(0.0105, 0.258, 0.0395), 'alu_black')
    ch = box('ch', P3(-0.018, 0.262, 0.024), P3(0.018, 0.246, 0.036), 'alu_black')
    fa = cyl('fa', P3(0.010, 0.300, 0.018), P3(0.022, 0.288, 0.012), 0.0065, 0.0065, 16 if hi else 6, 'alu_black')
    if hi:
        bevel(upper, 0.0012, 2)
        bevel(ch, 0.001, 2)
        cs = [box('port', P3(0.008, 0.420, 0.014), P3(0.03, 0.350, 0.029), None)]
        cut(upper, cutters(cs))
        bolt = box('bolt', P3(0.006, 0.418, 0.015), P3(0.0105, 0.352, 0.028), 'blued')
        defl = box('defl', P3(0.0125, 0.345, 0.012), P3(0.019, 0.333, 0.026), 'alu_black')
        bevel(defl, 0.0015, 2)
        rs = [box('slot', P3(-0.02, 0.268 + 0.0101 * k + 0.0053, 0.0362), P3(0.02, 0.268 + 0.0101 * k, 0.040), None) for k in range(56)]
        cut(rail, cutters(rs))
        parts += [bolt, defl]
    parts += [upper, rail, ch, fa]
    # free-float handguard
    hs = rrect(0.044, 0.046, 0.011, 4 if hi else 2)
    hring = lambda Yp: [P3(u, Yp, 0.007 + v) for u, v in hs]
    hg = loft('handguard', [hring(0.520), hring(0.800)], 'alu_black')
    if hi:
        bevel(hg, 0.0015, 2, 40)
        sl = []
        for k in range(5):
            y = 0.560 + k * 0.045
            for s in (1, -1):
                sl.append(box('ml', P3(s * 0.017 if s > 0 else -0.03, y + 0.032, -0.0035), P3(0.03 if s > 0 else -0.017, y, 0.0035), None))
            sl.append(box('mb', P3(-0.0035, y + 0.032, -0.03), P3(0.0035, y, -0.012), None))
        cut(hg, cutters(sl))
        inner = cyl('inner', P3(0, 0.525, 0.0), P3(0, 0.795, 0.0), 0.0175, 0.0175, 16, 'alu_black')
        parts.append(inner)
    parts.append(hg)
    brl = cyl('barrel', P3(0, 0.800, 0.0), P3(0, 0.868, 0.0), 0.0090, 0.0090, seg, 'parkerized')
    fh = cyl('hider', P3(0, 0.866, 0.0), P3(0, 0.915, 0.0), 0.0110, 0.0105, seg, 'parkerized')
    if hi:
        cut(fh, cyl('bore', P3(0, 0.905, 0), P3(0, 0.92, 0), 0.0075, 0.0075, 16, None))
        sl = []
        for k in range(4):                                   # four slots in the flash hider
            a = math.pi / 4 + k * math.pi / 2
            c, s_ = math.cos(a), math.sin(a)
            sl.append(sweep('slot', [P3(c * 0.0105, 0.897, s_ * 0.0105), P3(c * 0.0105, 0.918, s_ * 0.0105)], rrect(0.0045, 0.006, 0.001, 1), None))
        cut(fh, cutters(sl))
        parts.append(cyl('crown', P3(0, 0.866, 0), P3(0, 0.872, 0), 0.0118, 0.0118, 24, 'parkerized'))
    parts += [brl, fh]
    # flip-up sights (up)
    rsg = box('rsight', P3(-0.0085, 0.292, 0.0395), P3(0.0085, 0.272, 0.058), 'alu_black')
    fsg = box('fsight', P3(-0.0075, 0.795, 0.0395), P3(0.0075, 0.780, 0.068), 'alu_black')
    if hi:
        cut(rsg, box('ap', P3(-0.0040, 0.283, 0.050), P3(0.0040, 0.280, 0.0575), None))
        cut(fsg, box('win', P3(-0.0045, 0.800, 0.054), P3(0.0045, 0.775, 0.069), None))
        bevel(rsg, 0.0008, 1)
        bevel(fsg, 0.0008, 1)
        post = box('post', P3(-0.0009, 0.789, 0.054), P3(0.0009, 0.786, 0.066), 'alu_black')
        parts.append(post)
    parts += [rsg, fsg]
    return parts


# ====================================================================== pump shotgun (+ sawn-off)
GSH = (0.300, -0.062)


def shotgun(hi, sawn=False):
    P, P3 = mk(*GSH)
    parts = []
    seg = 24 if hi else 8
    if sawn:
        st = [(0.335, 0.012), (0.292, 0.008), (0.250, -0.030), (0.222, -0.098), (0.226, -0.116), (0.256, -0.122), (0.272, -0.100),
              (0.298, -0.070), (0.320, -0.052), (0.335, -0.032)]
    else:
        st = [(0.335, 0.012), (0.300, 0.010), (0.030, -0.025), (0.012, -0.028), (0.012, -0.178), (0.060, -0.173), (0.250, -0.080),
              (0.290, -0.072), (0.320, -0.052), (0.335, -0.032)]
    stock = extrude('stock', [P(*p) for p in st], -0.0195, 0.0195, 'walnut')
    bevel(stock, 0.006 if hi else 0.005, 4 if hi else 1, 30)
    parts.append(stock)
    if not sawn:
        pad = extrude('pad', [P(*p) for p in [(0.000, -0.027), (0.0125, -0.028), (0.0125, -0.178), (0.000, -0.180)]], -0.0200, 0.0200, 'rubber')
        bevel(pad, 0.004 if hi else 0.003, 2 if hi else 1, 30)
        parts.append(pad)
    rc = [(0.335, 0.022), (0.538, 0.022), (0.548, 0.012), (0.548, -0.034), (0.540, -0.040), (0.335, -0.040)]
    rec = extrude('receiver', [P(*p) for p in rc], -0.0145, 0.0145, 'blued')
    if hi:
        bevel(rec, 0.0015, 2)
        cut(rec, box('port', P3(0.008, 0.500, -0.012), P3(0.03, 0.430, 0.012), None))
        bolt = box('bolt', P3(0.006, 0.498, -0.010), P3(0.0115, 0.432, 0.010), 'blued')
        sb = box('safety', P3(-0.006, 0.322, 0.022), P3(0.006, 0.335, 0.027), 'blued')
        rel = box('rel', P3(-0.0155, 0.380, -0.034), P3(-0.0142, 0.366, -0.026), 'blued')
        pins = [cyl('pin', P3(-0.0152, y, -0.033), P3(0.0152, y, -0.033), 0.002, 0.002, 12, 'steel') for y in (0.360, 0.440)]
        parts += [bolt, sb, rel] + pins
    parts.append(rec)
    gpath = [P3(0, 0.430, -0.040), P3(0, 0.426, -0.060), P3(0, 0.412, -0.067), P3(0, 0.370, -0.066), P3(0, 0.350, -0.052)]
    if not hi:
        gpath = [gpath[0], gpath[1], gpath[3], gpath[4]]
    parts.append(sweep('guard', gpath, [(0.0075, 0.002), (-0.0075, 0.002), (-0.0075, -0.002), (0.0075, -0.002)], 'alu_black'))
    parts.append(extrude('trig', [P(*p) for p in [(0.395, -0.040), (0.398, -0.052), (0.394, -0.060), (0.389, -0.059), (0.392, -0.051), (0.389, -0.040)]], -0.003, 0.003, 'alu_black'))
    bend = 0.720 if sawn else 1.000
    tend = 0.698 if sawn else 0.900
    brl = cyl('barrel', P3(0, 0.540, 0.000), P3(0, bend, 0.000), 0.0118, 0.0118, seg, 'blued')
    tube = cyl('tube', P3(0, 0.540, -0.0255), P3(0, tend, -0.0255), 0.0112, 0.0112, seg, 'blued')
    cap = cyl('cap', P3(0, tend, -0.0255), P3(0, tend + 0.016, -0.0255), 0.0124, 0.0118, seg, 'steel')
    parts += [brl, tube, cap]
    if hi:
        cut(brl, cyl('bore', P3(0, bend + 0.01, 0), P3(0, bend - 0.012, 0), 0.0093, 0.0093, 24, None))
        if sawn:
            ring = cyl('rawcut', P3(0, bend - 0.0008, 0), P3(0, bend + 0.0002, 0), 0.0119, 0.0119, 24, 'satin')
            cut(ring, cyl('rb', P3(0, bend + 0.01, 0), P3(0, bend - 0.01, 0), 0.0093, 0.0093, 24, None))
            parts.append(ring)
        else:
            parts.append(cyl('bead', P3(0, 0.991, 0.0115), P3(0, 0.991, 0.0150), 0.0016, 0.0016, 12, 'brass'))
            clamp = box('clamp', P3(-0.0085, 0.896, -0.026), P3(0.0085, 0.884, 0.0), 'blued')
            bevel(clamp, 0.0015, 2)
            parts.append(clamp)
    # pump forend (walnut, grooved)
    f0, f1 = (0.578, 0.690) if sawn else (0.600, 0.800)
    fs = rrect(0.046, 0.044, 0.014, 4 if hi else 2)
    fring = lambda Yp, k: [P3(u * k, Yp, -0.024 + v * k) for u, v in fs]
    fore = loft('forend', [fring(f0, 0.86), fring(f0 + 0.010, 1.0), fring(f1 - 0.010, 1.0), fring(f1, 0.88)], 'walnut')
    if hi:
        cs = [cyl('grv', P3(0, f0 + 0.022 + k * 0.010, -0.024), P3(0, f0 + 0.026 + k * 0.010, -0.024), 0.040, 0.040, 32, None)
              for k in range(int((f1 - f0 - 0.04) / 0.010))]
        for c in cs:
            cut(c, cyl('cc', P3(0, f0, -0.024), P3(0, f1, -0.024), 0.0225, 0.0225, 32, None))
        cut(fore, cutters(cs))
    parts.append(fore)
    return parts


def shotgun_sawn(hi):
    return shotgun(hi, sawn=True)


# ====================================================================== SMG (compact, magwell ahead of the grip)
GSM = (0.1727, -0.090)


def smg(hi):
    P, P3 = mk(*GSM)
    parts = []
    seg = 20 if hi else 8
    rc = [(0.100, 0.030), (0.370, 0.030), (0.385, 0.014), (0.385, -0.020), (0.100, -0.020)]
    rec = extrude('receiver', [P(*p) for p in rc], -0.0160, 0.0160, 'parkerized')
    bevel(rec, 0.0020 if hi else 0.002, 2 if hi else 1, 30)
    lw = [(0.120, -0.020), (0.360, -0.020), (0.360, -0.040), (0.300, -0.046), (0.200, -0.046), (0.150, -0.040), (0.120, -0.030)]
    low = extrude('lower', [P(*p) for p in lw], -0.0145, 0.0145, 'poly_black')
    mw = extrude('magwell', [P(*p) for p in [(0.252, -0.040), (0.304, -0.040), (0.306, -0.074), (0.252, -0.074)]], -0.0150, 0.0150, 'poly_black')
    if hi:
        bevel(low, 0.002, 2)
        bevel(mw, 0.0018, 2)
        cut(rec, box('port', P3(0.009, 0.300, -0.004), P3(0.03, 0.245, 0.018), None))
        bolt = box('bolt', P3(0.007, 0.298, -0.002), P3(0.0125, 0.247, 0.016), 'blued')
        sel = cyl('sel', P3(-0.0160, 0.178, -0.032), P3(-0.0150, 0.178, -0.032), 0.006, 0.006, 16, 'poly_black')
        mrel = box('mrel', P3(-0.0160, 0.252, -0.052), P3(0.0160, 0.246, -0.042), 'poly_black')
        parts += [bolt, sel, mrel]
    parts += [rec, low, mw]
    rail = box('rail', P3(-0.0100, 0.370, 0.030), P3(0.0100, 0.115, 0.0385), 'parkerized')
    if hi:
        cut(rail, cutters([box('s', P3(-0.02, 0.122 + 0.0101 * k + 0.0053, 0.035), P3(0.02, 0.122 + 0.0101 * k, 0.040), None) for k in range(24)]))
    parts.append(rail)
    mag = extrude('mag', [P(*p) for p in [(0.259, -0.060), (0.297, -0.060), (0.302, -0.200), (0.304, -0.214), (0.262, -0.216), (0.264, -0.200)]], -0.0112, 0.0112, 'poly_black')
    if hi:
        bevel(mag, 0.0014, 2, 30)
    parts.append(mag)
    grip = extrude('grip', [P(*p) for p in [(0.205, -0.042), (0.163, -0.042), (0.138, -0.140), (0.146, -0.148), (0.178, -0.148), (0.188, -0.120),
                                            (0.196, -0.085)]], -0.0142, 0.0142, 'poly_stip')
    bevel(grip, 0.0045 if hi else 0.004, 3 if hi else 1, 30)
    parts.append(grip)
    gpath = [P3(0, 0.250, -0.046), P3(0, 0.247, -0.071), P3(0, 0.236, -0.078), P3(0, 0.210, -0.078), P3(0, 0.196, -0.066)]
    if not hi:
        gpath = [gpath[0], gpath[1], gpath[3], gpath[4]]
    parts.append(sweep('guard', gpath, [(0.007, 0.0022), (-0.007, 0.0022), (-0.007, -0.0022), (0.007, -0.0022)], 'poly_black'))
    parts.append(extrude('trig', [P(*p) for p in [(0.228, -0.046), (0.231, -0.058), (0.227, -0.066), (0.222, -0.065), (0.225, -0.057), (0.222, -0.046)]], -0.003, 0.003, 'steel'))
    hs = rrect(0.034, 0.038, 0.009, 3 if hi else 1)
    hg = loft('handguard', [[P3(u, Yp, -0.002 + v) for u, v in hs] for Yp in (0.384, 0.440)], 'poly_black')
    if hi:
        cs = []
        for k in range(3):
            y = 0.392 + k * 0.015
            for s in (1, -1):
                cs.append(box('v', P3(0.013 if s > 0 else -0.03, y + 0.009, -0.004), P3(0.03 if s > 0 else -0.013, y, 0.006), None))
        cut(hg, cutters(cs))
        bevel(hg, 0.0012, 2, 40)
    parts.append(hg)
    parts.append(cyl('barrel', P3(0, 0.440, 0), P3(0, 0.468, 0), 0.0078, 0.0078, seg, 'parkerized'))
    nut = cyl('nut', P3(0, 0.464, 0), P3(0, 0.482, 0), 0.0105, 0.0100, seg, 'parkerized')
    if hi:
        cut(nut, cyl('bore', P3(0, 0.49, 0), P3(0, 0.474, 0), 0.0050, 0.0050, 16, None))
    parts.append(nut)
    # collapsed wire stock: two rods + butt plate
    for s in (1, -1):
        parts.append(cyl('rod', P3(s * 0.0185, 0.030, 0.008), P3(s * 0.0185, 0.300, 0.008), 0.0042, 0.0042, 12 if hi else 5, 'parkerized'))
    bp = box('butt', P3(-0.024, 0.042, -0.062), P3(0.024, 0.028, 0.026), 'rubber')
    bevel(bp, 0.005 if hi else 0.004, 3 if hi else 1)
    parts.append(bp)
    knob = cyl('knob', P3(-0.016, 0.340, 0.012), P3(-0.030, 0.340, 0.012), 0.0050, 0.0055, 16 if hi else 6, 'poly_black')
    rsg = box('rsight', P3(-0.008, 0.150, 0.0385), P3(0.008, 0.132, 0.055), 'parkerized')
    fsg = box('fsight', P3(-0.008, 0.370, 0.0385), P3(0.008, 0.356, 0.058), 'parkerized')
    if hi:
        cut(rsg, box('ap', P3(-0.003, 0.155, 0.046), P3(0.003, 0.128, 0.052), None))
        cut(fsg, box('hood', P3(-0.0055, 0.375, 0.045), P3(0.0055, 0.350, 0.0585), None))
        parts.append(box('post', P3(-0.0009, 0.365, 0.044), P3(0.0009, 0.361, 0.054), 'parkerized'))
        bevel(rsg, 0.0008, 1)
        bevel(fsg, 0.0008, 1)
    parts += [knob, rsg, fsg]
    return parts


# ====================================================================== knife (fixed blade)
GK = (0.060, -0.002)


def knife(hi):
    P, P3 = mk(*GK)
    parts = []
    bl = [(0.120, 0.0110, 1), (0.170, 0.0110, 1), (0.200, 0.0085, 1), (0.222, 0.0045, 1), (0.236, 0.0005, 0), (0.230, -0.0045, 0),
          (0.216, -0.0100, 0), (0.195, -0.0135, 0), (0.135, -0.0140, 0), (0.127, -0.0100, 1), (0.120, -0.0100, 1)]
    blade = extrude('blade', [P(y, z) for y, z, _ in bl], -0.00175, 0.00175, 'satin')
    # flat grind: edge vertices pulled to the centre plane
    edge = [(round(P(y, z)[0], 6), round(P(y, z)[1], 6)) for y, z, f in bl if not f]
    for v in blade.data.vertices:
        if (round(v.co.y, 6), round(v.co.z, 6)) in edge:
            v.co.x *= 0.25
    parts.append(blade)
    guard = box('guard', P3(-0.0055, 0.121, -0.0165), P3(0.0055, 0.115, 0.0150), 'steel')
    if hi:
        bevel(guard, 0.0012, 2)
    parts.append(guard)
    hd = [(0.115, 0.0120), (0.015, 0.0110), (0.004, 0.0130), (0.000, 0.0100), (0.000, -0.0120), (0.010, -0.0160), (0.030, -0.0140),
          (0.045, -0.0170), (0.070, -0.0140), (0.090, -0.0170), (0.108, -0.0150), (0.115, -0.0160)]
    h = extrude('handle', [P(*p) for p in hd], -0.0090, 0.0090, 'rubber_grip')
    bevel(h, 0.0045 if hi else 0.004, 3 if hi else 1, 30)
    parts.append(h)
    pm = box('pommel', P3(-0.0075, 0.003, -0.0125), P3(0.0075, -0.0045, 0.0110), 'steel')
    if hi:
        bevel(pm, 0.002, 2)
        cut(pm, cyl('hole', P3(-0.02, -0.0005, -0.003), P3(0.02, -0.0005, -0.003), 0.0028, 0.0028, 16, None))
        for k in range(2):
            parts.append(cyl('pin', P3(-0.0094, 0.040 + k * 0.045, -0.001), P3(0.0094, 0.040 + k * 0.045, -0.001), 0.0022, 0.0022, 16, 'brass'))
    parts.append(pm)
    return parts


# ====================================================================== golf club (iron)
GG = 0.130


def golf(hi):
    from mathutils import Matrix, Vector
    parts = []
    seg = 24 if hi else 8
    y = lambda Yp: -(Yp - GG)
    gp = [(0.0, 0.0), (0.0005, 0.0115), (0.004, 0.0128), (0.060, 0.0122), (0.180, 0.0108), (0.262, 0.0094), (0.270, 0.0080)]
    grip = lathe('grip', gp if not hi else [(0, 0)] + catmull(gp[1:], 4), seg, 'rubber_grip', (0, y(0), 0))
    shaft = cyl('shaft', (0, y(0.262), 0), (0, y(0.900), 0), 0.0072, 0.0050, 16 if hi else 6, 'chrome')
    hosel = cyl('hosel', (0, y(0.890), 0), (0, y(0.952), 0), 0.0062, 0.0078, 16 if hi else 6, 'chrome')
    parts += [grip, shaft, hosel]
    if hi:
        for k in range(5):
            yy = 0.42 + k * 0.08
            parts.append(lathe('step', [(0, 0.0), (0.0, 0.0065 - k * 0.0003), (0.004, 0.0065 - k * 0.0003)], 16, 'chrome', (0, y(yy), 0), close_ends=False))
        parts.append(cyl('ferrule', (0, y(0.880), 0), (0, y(0.894), 0), 0.0058, 0.0066, 16, 'rubber'))
    # head: blade iron, lie 62 deg, loft 33 deg
    lie, loft_ = math.radians(62), math.radians(33)
    t = Vector((math.sin(lie), -math.cos(lie), 0))
    h = Vector((math.cos(lie), math.sin(lie), 0))
    n = Vector((0, 0, 1))
    R = Matrix.Rotation(-loft_, 3, t)
    hh, nn = R @ h, R @ n
    O = Vector((0, y(0.952), 0)) - hh * 0.006
    M = Matrix((
        (t.x, hh.x, nn.x, O.x), (t.y, hh.y, nn.y, O.y), (t.z, hh.z, nn.z, O.z), (0, 0, 0, 1)))
    # profile in (s along toe, q up the face), extruded along the face normal (x -> s, y -> q after the matrix below)
    pr = [(-0.008, 0.012), (-0.004, 0.000), (0.020, -0.003), (0.060, -0.002), (0.076, 0.004), (0.081, 0.020), (0.076, 0.040),
          (0.064, 0.046), (0.010, 0.030), (-0.004, 0.026)]
    # extrude() takes (y,z) pairs across x; the swizzle S makes y -> s, z -> q, x -> face normal
    S = Matrix(((0, 1, 0, 0), (0, 0, 1, 0), (1, 0, 0, 0), (0, 0, 0, 1)))   # (x,y,z) -> (y,z,x): s=y, q=z, normal=x
    head = extrude('head', pr, -0.009, 0.004, 'satin', M=M @ S)
    if hi:
        bevel(head, 0.0012, 3, 30)
        grooves = []
        for k in range(8):
            q = 0.006 + k * 0.0042
            g = box('g', (0.0035, 0.012, q), (0.006, 0.066, q + 0.0011), None)
            g.data.transform(M @ S)
            grooves.append(g)
        cut(head, cutters(grooves))
        badge = extrude('badge', [(0.030, 0.006), (0.066, 0.008), (0.070, 0.024), (0.030, 0.014)], -0.0098, -0.0088, 'paint_red', M=M @ S)
        parts.append(badge)
    parts.append(head)
    return parts


# ====================================================================== crowbar
GC = 0.15


def crowbar(hi):
    R = 0.045
    pts = [(0.0, 0.0), (0.012, 0.0), (0.25, 0.0), (0.50, 0.0)]
    n = 14 if hi else 7
    for k in range(1, n + 1):
        a = math.radians(205) * k / n
        pts.append((0.50 + R * math.sin(a), R - R * math.cos(a)))
    end = pts[-1]                                            # short straight claw past the bend
    pts.append((end[0] - 0.025 * math.cos(math.radians(25)), end[1] - 0.025 * math.sin(math.radians(25))))
    path = [(0, -(Yp - GC), z) for Yp, z in pts]
    m = len(path)
    sc = [0.45, 0.80] + [1.0] * (m - 3) + [0.55]
    prof = circle(0.0110, 6, start=0.0)
    bar = sweep('bar', path, prof, 'paint_red', scales=sc)
    parts = [bar]
    if hi:
        bevel(bar, 0.0010, 2, 25)
        # claw slot at the hook tip, chisel bevel at the straight end
        tip = path[-1]
        cl = box('claw', (-0.0018, tip[1] - 0.03, tip[2] - 0.03), (0.0018, tip[1] + 0.03, tip[2] + 0.03), None)
        cut(bar, cl)
        # bare steel worn ends (shells)
        parts.append(sweep('end1', [path[0], path[1], (0, path[1][1] - 0.03, 0)], circle(0.0113, 6), 'steel', scales=[0.47, 0.82, 1.03]))
        parts.append(sweep('end2', path[-3:], circle(0.0113, 6), 'steel', scales=[1.03, 1.03, 0.57]))
    return parts


# ====================================================================== molotov cocktail
GM_ = 0.075


def molotov(hi):
    from mathutils import Vector
    parts = []
    seg = 32 if hi else 12
    p0 = (0, GM_, 0)
    bp = [(0, 0), (0.0, 0.031), (0.004, 0.0335), (0.120, 0.0335), (0.150, 0.030), (0.175, 0.017), (0.200, 0.0125), (0.226, 0.0125),
          (0.228, 0.0145), (0.236, 0.0145), (0.238, 0.0110), (0.238, 0)]
    if hi:
        hp = [(0, 0)] + catmull(bp[1:-1], 3) + [(0.238, 0)]
        b = lathe('bottle', hp, seg, 'glass_amb', p0)
        lab = lathe('label', [(0.030, 0.0330), (0.0302, 0.0340), (0.0948, 0.0340), (0.095, 0.0330)], seg, 'label', p0)
        # torn label: cut a ragged wedge out of it
        tear = extrude('tear', [(0.050, 0.004), (0.020, 0.000), (-0.004, 0.012), (0.012, 0.030), (0.050, 0.030)], -0.06, -0.012, None)
        cut(lab, tear)
        ink = lathe('ink', [(0.052, 0.0338), (0.0522, 0.0343), (0.0698, 0.0343), (0.070, 0.0338)], seg, 'label_ink', p0)
        cut(ink, extrude('tear2', [(0.050, 0.004), (0.020, 0.000), (-0.004, 0.012), (0.012, 0.030), (0.050, 0.030)], -0.06, -0.012, None))
        parts += [b, lab, ink]
    else:
        parts.append(lathe('bottle', [bp[0], bp[1], bp[3], bp[4], bp[5], bp[6], bp[8], bp[9], bp[11]], seg, 'glass_amb', p0))
    # rag: stuffed in the neck, out over the lip and hanging down one side
    rag = [(0.0, 0.200, 0.0), (0.0, 0.236, 0.0), (0.002, 0.252, 0.004), (0.012, 0.258, 0.008), (0.024, 0.246, 0.010), (0.030, 0.222, 0.008),
           (0.032, 0.196, 0.002)]
    path = [(x, -(Yp - GM_), z) for x, Yp, z in rag]
    if not hi:
        path = [path[0], path[1], path[3], path[5], path[6]]
    prof = [(0.009, 0.003), (-0.009, 0.003), (-0.009, -0.003), (0.009, -0.003)] if not hi else rrect(0.019, 0.0065, 0.0028, 3)
    parts.append(sweep('rag', path, prof, 'cloth', scales=[0.8] + [1.0] * (len(path) - 2) + [0.9], twist=0.6))
    return parts


# ====================================================================== registry
def _P3(G):
    return mk(*G)[1]


WEAPONS = {
    'pistol_service': dict(build=pistol_service, kind='handgun', cls='small', budget=600, hold='pistol',
                           grips={'grip_r': (0, 0, 0), 'grip_l': (-0.019, 0.004, -0.010)},
                           muzzle=_P3(GS)(0, 0.2095, 0.1125),
                           note='full-size hammer-fired service pistol: blued steel slide, black alloy frame, walnut grips'),
    'pistol_polymer': dict(build=pistol_polymer, kind='handgun', cls='small', budget=600, hold='pistol',
                           grips={'grip_r': (0, 0, 0), 'grip_l': (-0.018, 0.004, -0.010)},
                           muzzle=_P3((0.026, 0.052))(0, 0.186, 0.1105),
                           note='compact striker-fired polymer pistol, 9 mm class (Glock-type silhouette, generic)'),
    'rifle': dict(build=rifle, kind='rifle', cls='medium', budget=1200, hold='rifle',
                  grips={'grip_r': (0, 0, 0), 'grip_l': _P3(GR)(0, 0.665, -0.012)},
                  muzzle=_P3(GR)(0, 0.915, 0.0),
                  note='flat-top carbine with free-float handguard, flip-up sights, tan 30-round magazine'),
    'shotgun': dict(build=shotgun, kind='shotgun', cls='medium', budget=1200, hold='rifle',
                    grips={'grip_r': (0, 0, 0), 'grip_l': _P3(GSH)(0, 0.700, -0.040)},
                    muzzle=_P3(GSH)(0, 1.000, 0.0),
                    note='pump-action 12 gauge, walnut stock and grooved forend, blued steel'),
    'shotgun_sawn': dict(build=shotgun_sawn, kind='shotgun', cls='medium', budget=1200, hold='pistol_two_hand',
                         grips={'grip_r': (0, 0, 0), 'grip_l': _P3(GSH)(0, 0.634, -0.040)},
                         muzzle=_P3(GSH)(0, 0.720, 0.0),
                         note='the pump shotgun cut down: barrel and tube shortened, stock cut to a rough pistol grip'),
    'smg': dict(build=smg, kind='smg', cls='medium', budget=1200, hold='rifle',
                grips={'grip_r': (0, 0, 0), 'grip_l': _P3(GSM)(0, 0.280, -0.085)},
                muzzle=_P3(GSM)(0, 0.482, 0.0),
                note='compact 9 mm sub-machine gun, magazine ahead of the grip (support hand on the magwell), collapsed wire stock'),
    'bat': dict(build=bat, kind='melee', cls='tiny', budget=300, hold='two_hand_swing',
                grips={'grip_r': (0, 0, 0), 'grip_l': (0, 0.09, 0)},
                note='wooden baseball bat, 84 cm, taped handle, stained barrel'),
    'knife': dict(build=knife, kind='melee', cls='tiny', budget=300, hold='one_hand_melee',
                  grips={'grip_r': (0, 0, 0)}, muzzle=None,
                  note='fixed-blade utility knife, 12 cm satin blade, rubber handle'),
    'golf_club': dict(build=golf, kind='melee', cls='tiny', budget=300, hold='two_hand_swing',
                      grips={'grip_r': (0, 0, 0), 'grip_l': (0, 0.08, 0)},
                      note='7-iron: chrome shaft, black rubber grip, satin head'),
    'crowbar': dict(build=crowbar, kind='melee', cls='tiny', budget=300, hold='one_hand_melee',
                    grips={'grip_r': (0, 0, 0), 'grip_l': (0, 0.09, 0)},
                    note='60 cm hex wrecking bar, red paint worn to steel'),
    'molotov': dict(build=molotov, kind='thrown', cls='tiny', budget=300, hold='throwable',
                    grips={'grip_r': (0, 0, 0)},
                    note='amber glass bottle with a torn label and a rag in the neck (the flame is a game effect)'),
}
