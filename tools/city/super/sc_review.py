"""Superchecker: a reading aid for the lines whose new place must be chosen by hand (19 Nov 2026, Yasin: "make judgement
calls and fix everything ... and when in doubt erase problematic props").

It decides nothing. For each "choose" line of <piece>.fixes.json it MEASURES the spots near the item that a person might
pick - along the same wall, against the nearest wall or fence, on the nearest right surface - and says for each spot
what is wrong with it (in a building, at a door or opening, over a window, on another prop, off the block, wrong surface,
over a block edge). The person then writes, for that one item, `pick <n> <spot letter>` or `erase <n>` into a decisions
file, with a reason; `apply` turns the decisions into the fix list (`to`, `chosen`, or `op: remove`).

  python -I tools/city/super/sc_review.py show <piece>                 the table of choose lines and their spots
  python -I tools/city/super/sc_review.py apply <piece> <decisions.txt>  lines: "pick 12 b <reason>" / "erase 12 <reason>" / "keep 12 <why it is not a fault>"
"""
import json, math, os, sys
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sc_lib as L
import sc_find as F

FIND = os.path.join(L.OUT, 'find')


def context(piece):
    rows = L.load_layout(); r = [x for x in rows if x.piece == piece][0]
    return F.Ctx(rows, r)


def item_at(ctx, f):
    loc = np.array(f['at'], float)
    for it in ctx.items:
        if it.base == f['base'] and np.linalg.norm(it.local[9:12] - loc) < 0.003: return it
    return None


def spot_faults(ctx, it, pos, yaw, mount):
    """what is wrong with standing this item at pos (city x, y, z) turned to yaw (radians)"""
    bad = []
    q = L.rect_quad(pos[[0, 2]], it.half, yaw); c = pos[[0, 2]]
    g = ctx.S.ground(c[0], c[1], own=ctx.me.id)
    if mount == 'ground':
        if g is None: bad.append('off its block')
        else:
            if F.has(it.base, F.PLAY) and g[1] not in ('mulch', 'sand'): bad.append('on %s' % g[1])
            elif F.has(it.base, F.SOFT_LIFE) and g[1] in L.HARD: bad.append('on %s' % g[1])
            if any(ctx.S.ground(p[0], p[1], own=ctx.me.id) is None for p in q): bad.append('over the block edge')
    for b in ctx.blds:
        if b.quad is None or abs(b.pos[0] - c[0]) > 40 or abs(b.pos[2] - c[1]) > 40: continue
        inner = L.rect_quad(b.pos[[0, 2]], (max(0.1, b.w * 0.5 - 0.15), max(0.1, b.d * 0.5 - 0.15)), b.yaw)
        if mount == 'ground' and L.quad_hit(q, inner, 1.0): bad.append('in %s' % b.name)
        for nm, dp in b.doors:
            zone = L.rect_quad(b.world([b.local(dp)[0], 0, b.d * 0.5 + 0.8])[[0, 2]], (0.8, 0.85), b.yaw)
            if mount == 'ground' and L.quad_hit(q, zone, 1.0): bad.append('at a door of %s' % b.name)
        if b.open and mount == 'ground':
            for o in b.open.get('openings', []):
                if int(o.get('floor', 0)) != 0 or o['region'] not in ('O_rollup', 'O_garage', 'O_storefront', 'O_shopdoor', 'O_civic_door'): continue
                deep = 4.0 if o['region'] in ('O_rollup', 'O_garage') else 1.2
                fac = o['facade']; al = float(o['along']); hw = float(o['w']) * 0.5
                if fac in ('front', 'back'):
                    s = 1.0 if fac == 'front' else -1.0; zc = b.world([al, 0, s * (b.d * 0.5 + deep * 0.5)]); hx, hz = hw, deep * 0.5
                else:
                    s = 1.0 if fac == 'right' else -1.0; zc = b.world([s * (b.w * 0.5 + deep * 0.5), 0, al]); hx, hz = deep * 0.5, hw
                if L.quad_hit(q, L.rect_quad(zc[[0, 2]], (hx, hz), b.yaw), 1.0): bad.append('before a %s of %s' % (o['region'][2:], b.name)); break
        if b.open and mount == 'wall':
            lp = b.local(pos); fac = None
            if abs(lp[0]) <= b.w * 0.5 + 0.15 and abs(abs(lp[2]) - b.d * 0.5) < 0.45: fac = 'front' if lp[2] > 0 else 'back'; al = lp[0]
            elif abs(lp[2]) <= b.d * 0.5 + 0.15 and abs(abs(lp[0]) - b.w * 0.5) < 0.45: fac = 'right' if lp[0] > 0 else 'left'; al = lp[2]
            if fac:
                hw = float(it.man.get('footprint_w', 0.4)) * 0.5; y0 = lp[1]; y1 = y0 + float(it.man.get('height', 0.4))
                for o in b.open.get('openings', []):
                    if o['facade'] != fac: continue
                    lo_ = float(o['along']) - float(o['w']) * 0.5; hi_ = float(o['along']) + float(o['w']) * 0.5
                    if it.base == 'prop_ac_window': continue
                    if al - hw < hi_ + 0.05 and al + hw > lo_ - 0.05 and y0 < float(o['y1']) and y1 > float(o['y0']): bad.append('over a %s' % o['region'][2:]); break
                    if F.has(it.base, ('prop_meter_', 'prop_hose_reel', 'prop_ac_', 'prop_downspout')) and ('door' in o['region'] or o['region'] == 'O_rollup'):
                        gap = max(lo_ - (al + hw), (al - hw) - hi_)
                        if 0 <= gap < 0.35 and y0 < float(o['y1']) and y1 > float(o['y0']): bad.append('%.0f cm from a door' % (gap * 100)); break
    for o in ctx.near(c, 6.0):
        if o is it or F.has(o.base, F.GROUND_COVER) or F.has(o.base, F.FLAT) or o.base.startswith('prop_shade_sail'): continue
        if (mount == 'wall') != (o.mount == 'wall') and o.kind not in ('fence', 'gate'): continue
        if o.y1 <= pos[1] + 0.05 or o.y0 >= pos[1] + (it.y1 - it.y0) - 0.05: continue
        oq = L.rect_quad(o.ctr, o.half * 0.95, o.yaw) if o.kind != 'tree' else L.rect_quad(o.pos[[0, 2]], (0.3, 0.3), 0.0)
        if L.quad_hit(q, oq, 0.95): bad.append('on %s' % o.base.replace('prop_', '')); break
    return sorted(set(bad))


def spots(ctx, it, kind):
    """candidate spots for one item: [(letter, city pos [3], yaw, what it is)]"""
    out = []
    p0 = it.pos.copy(); yaw0 = it.yaw
    if it.mount == 'wall':
        # along the same wall: slide 0.5 .. 3 m both ways along the item's own x axis
        ax = np.array([math.cos(yaw0), 0.0, -math.sin(yaw0)])
        for d in (0.6, -0.6, 1.2, -1.2, 2.0, -2.0, 3.0, -3.0):
            out.append((p0 + ax * d, yaw0, 'slid %+.1f m along its wall' % d))
        if kind in ('no_wall', 'over_roof', 'ac_no_window'):
            best = None
            for b in ctx.blds:
                if b.quad is None or L.quad_dist(b.quad, p0[[0, 2]]) > 4.0: continue
                lp = b.local(p0); cands = []
                hx = b.w * 0.5; hz = b.d * 0.5
                y = min(lp[1], b.h - 0.6) if kind == 'over_roof' else lp[1]
                for fac, nl, yaw_rel in (('front', [np.clip(lp[0], -hx + 0.4, hx - 0.4), y, hz + 0.05], 0.0), ('back', [np.clip(lp[0], -hx + 0.4, hx - 0.4), y, -hz - 0.05], math.pi),
                                         ('right', [hx + 0.05, y, np.clip(lp[2], -hz + 0.4, hz - 0.4)], math.pi / 2), ('left', [-hx - 0.05, y, np.clip(lp[2], -hz + 0.4, hz - 0.4)], -math.pi / 2)):
                    w = b.world(nl); cands.append((float(np.linalg.norm(w[[0, 2]] - p0[[0, 2]])), w, b.yaw + yaw_rel, 'on the %s wall of %s' % (fac, b.name)))
                if kind == 'ac_no_window' and b.open:
                    for o in b.open.get('openings', []):
                        if int(o.get('floor', 0)) != 0 or not ('win' in o['region'] or o['region'] in ('O_small_white', 'O_small_dark', 'O_ribbon', 'O_glass_plain')): continue
                        fac = o['facade']; al = float(o['along']); yy = float(o['y0']) + 0.05
                        if fac == 'front': nl = [al, yy, hz + 0.12]; yr = 0.0
                        elif fac == 'back': nl = [al, yy, -hz - 0.12]; yr = math.pi
                        elif fac == 'right': nl = [hx + 0.12, yy, al]; yr = math.pi / 2
                        else: nl = [-hx - 0.12, yy, al]; yr = -math.pi / 2
                        w = b.world(nl); cands.append((float(np.linalg.norm(w[[0, 2]] - p0[[0, 2]])), w, b.yaw + yr, 'in a %s window of %s' % (fac, b.name)))
                cands.sort(key=lambda e: e[0]); out += [(w, yw, t) for _, w, yw, t in cands[:4]]
    else:
        # against the nearest walls and fences, and short steps away
        anchors = []
        for b in ctx.blds:
            if b.quad is None: continue
            d = L.quad_dist(b.quad, it.ctr)
            if d < 10.0:
                for k in range(4):
                    a = b.quad[k]; e = b.quad[(k + 1) % 4]; seg = e - a; ln = np.hypot(*seg)
                    t = np.clip(float((it.ctr - a) @ seg) / max(ln * ln, 1e-9), 0.05, 0.95); pnt = a + seg * t
                    nrm = np.array([seg[1], -seg[0]]) / max(ln, 1e-9)
                    if float((pnt - b.pos[[0, 2]]) @ nrm) < 0: nrm = -nrm
                    anchors.append((float(np.hypot(*(pnt - it.ctr))), pnt + nrm * (max(it.half) + 0.15), math.atan2(nrm[0], nrm[1]), 'against the wall of %s' % b.name))
        for o in ctx.all_items:
            if o.kind not in ('fence',) or np.hypot(*(o.ctr - it.ctr)) > 10.0: continue
            ax = o.along(); nrm = np.array([-ax[1], ax[0]])
            s = 1.0 if float((it.ctr - o.ctr) @ nrm) >= 0 else -1.0
            pnt = o.ctr + nrm * s * (max(it.half) + 0.2)
            anchors.append((float(np.hypot(*(pnt - it.ctr))), pnt, math.atan2(nrm[0] * s, nrm[1] * s), 'against the fence (%s)' % o.base.replace('fence_', '')))
        if F.has(it.base, F.PLAY):
            for dx in range(-12, 13, 2):
                for dz in range(-12, 13, 2):
                    g = ctx.S.ground(it.ctr[0] + dx, it.ctr[1] + dz, own=ctx.me.id)
                    if g and g[1] in ('mulch', 'sand'): anchors.append((float(np.hypot(dx, dz)), np.array([it.ctr[0] + dx, it.ctr[1] + dz]), yaw0, 'on the %s bed' % g[1]))
        anchors.sort(key=lambda e: e[0]); seen = []
        for d, pnt, yw, t in anchors:
            if any(np.hypot(*(pnt - s_)) < 1.0 for s_ in seen): continue
            seen.append(pnt)
            g = ctx.S.ground(pnt[0], pnt[1], own=ctx.me.id)
            out.append((np.array([pnt[0], g[0] if g else p0[1], pnt[1]]), yw if 'wall' in t or 'fence' in t else yaw0, '%s, %.1f m away' % (t, d)))
            if len(out) >= 6: break
        for d in (1.5, 3.0):
            for a in (0, 90, 180, 270):
                v = np.array([math.sin(math.radians(a)), math.cos(math.radians(a))]) * d; pnt = it.ctr + v
                g = ctx.S.ground(pnt[0], pnt[1], own=ctx.me.id)
                out.append((np.array([pnt[0], g[0] if g else p0[1], pnt[1]]), yaw0, 'stepped %.1f m %s' % (d, {0: 'south', 90: 'east', 180: 'north', 270: 'west'}[a])))
    res = []
    for k, (pos, yw, t) in enumerate(out[:14]):
        res.append((chr(97 + k), pos, yw, t, spot_faults(ctx, it, pos, yw, it.mount)))
    return res


def brief(piece):
    """one line per open item: what it is, why, and only the spots that are clear"""
    show(piece, quiet=True)
    fx = json.load(open(os.path.join(FIND, piece + '.fixes.json'), encoding='utf-8'))
    sp = json.load(open(os.path.join(FIND, piece + '.spots.json'), encoding='utf-8'))
    for f in fx['fixes']:
        if f.get('mode') != 'choose' or f.get('chosen') or str(f['n']) not in sp: continue
        ok = [x for x in sp[str(f['n'])] if not x[4]]
        why = f['reason'].replace(f['base'], '').strip()
        print('#%-3d %-24s %-58s| %s' % (f['n'], f['base'].replace('prop_', '')[:24], why[:58], '  '.join('%s:%s' % (x[0], x[3].replace('slid ', '').replace(' along its wall', '').replace('against the ', '').replace(', ', ' ')[:30]) for x in ok[:5]) or 'NO CLEAR SPOT'))


def show(piece, quiet=False):
    fx = json.load(open(os.path.join(FIND, piece + '.fixes.json'), encoding='utf-8'))
    ctx = context(piece); out = {}
    for f in fx['fixes']:
        if f.get('mode') != 'choose' or f.get('chosen'): continue
        it = item_at(ctx, f)
        if it is None: print('#%d %s: the item is not found' % (f['n'], f['base'])); continue
        g = ctx.S.ground(it.ctr[0], it.ctr[1])
        sp = spots(ctx, it, f['kind']); out[str(f['n'])] = [[s[0], [float(v) for v in ctx.me.pts_inv([s[1]])[0]], float(s[2]), s[3], s[4]] for s in sp]
        if quiet: continue
        print('#%-3d %-30s %s' % (f['n'], it.base, f['reason'][:110]))
        print('      at (%.1f, %.1f, %.1f) on %s' % (it.pos[0], it.pos[1], it.pos[2], g[1] if g else 'nothing'))
        for letter, pos, yw, t, bad in sp:
            print('      %s %-48s %s' % (letter, t[:48], 'clear' if not bad else '; '.join(bad)))
    json.dump(out, open(os.path.join(FIND, piece + '.spots.json'), 'w'), indent=1)


def apply(piece, dec_path):
    fp = os.path.join(FIND, piece + '.fixes.json'); fx = json.load(open(fp, encoding='utf-8'))
    sp = json.load(open(os.path.join(FIND, piece + '.spots.json'), encoding='utf-8'))
    ctx = context(piece); dec = {}
    for ln in open(dec_path, encoding='utf-8'):
        p = ln.strip().split(None, 3)
        if not p or p[0].startswith('#'): continue
        if p[0] == 'pick': dec[p[1]] = ('pick', p[2], p[3] if len(p) > 3 else '')
        elif p[0] == 'erase': dec[p[1]] = ('erase', None, ' '.join(p[2:]))
        elif p[0] == 'keep': dec[p[1]] = ('keep', None, ' '.join(p[2:]))
    done = 0
    for f in fx['fixes']:
        d = dec.get(str(f['n']))
        if not d: continue
        if d[0] == 'keep':
            f['op'] = 'keep'; f['chosen'] = True; f['reason'] = 'kept as it is: ' + d[2] + ' [' + f['reason'] + ']'
        elif d[0] == 'erase':
            f['op'] = 'remove'; f.pop('to', None); f.pop('turn', None); f['chosen'] = True; f['reason'] = 'erased (in doubt): ' + d[2] + ' [' + f['reason'] + ']'
        else:
            s = next(x for x in sp[str(f['n'])] if x[0] == d[1]); it = item_at(ctx, f)
            f['to'] = s[1]; f['chosen'] = True
            turn = math.degrees(s[2] - it.yaw)
            turn = (turn + 180) % 360 - 180
            if abs(turn) > 0.5: f['turn'] = round(turn, 3)
            f['reason'] = 'moved %s: %s [%s]' % (s[3], d[2], f['reason'])
        done += 1
    kept = [f for f in fx['fixes'] if f.get('op') == 'keep']
    fx['kept'] = fx.get('kept', []) + kept; fx['fixes'] = [f for f in fx['fixes'] if f.get('op') != 'keep']
    json.dump(fx, open(fp, 'w', encoding='utf-8'), indent=1)
    print('APPLIED %d decisions; choose lines still open: %d' % (done, sum(1 for f in fx['fixes'] if f.get('mode') == 'choose' and not f.get('chosen'))))


if __name__ == '__main__':
    a = sys.argv[1:]
    if len(a) >= 2 and a[0] == 'show': show(a[1])
    elif len(a) >= 2 and a[0] == 'brief': brief(a[1])
    elif len(a) >= 3 and a[0] == 'apply': apply(a[1], a[2])
    else: sys.exit(__doc__)
