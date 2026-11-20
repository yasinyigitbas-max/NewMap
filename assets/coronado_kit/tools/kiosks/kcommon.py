"""Shared (pure python) pipeline helpers: kiosk registry, layout over all kiosks/tiers, canonical-face ownership."""
import os, sys, json, importlib
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kgeo, pack
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KIOSK_MODULES = [m for m in os.environ.get('KIOSKS', 'k_hotdog,k_paleta,k_taco,k_shaveice,k_lemonade').split(',')
                 if os.path.exists(os.path.join(os.path.dirname(os.path.abspath(__file__)), m+'.py'))]
SPACING = 12.0   # bake layout: kiosk i sits at x = i*SPACING
_cache = {}

def mods():
    return [importlib.import_module(n) for n in KIOSK_MODULES]

def build(mod, lod):
    k = (mod.KID, lod)
    if k not in _cache:
        m = kgeo.Mesh(lod, mod.KID); mod.build(m); _cache[k] = m
    return _cache[k]

def owners():
    """island -> kid of the first kiosk with canonical near faces on it (only that kiosk's faces are baked/rastered)."""
    own = {}
    for mod in mods():
        m = build(mod, 'near')
        for f, fb in zip(m.F, m.FB):
            if fb: own.setdefault(m.ISL[f[0]], mod.KID)
    return own

def layout(write=True):
    isl = {}; used = set()
    for mod in mods():
        for lod in ('near', 'mid', 'far'):
            m = build(mod, lod)
            for k, v in m.islands.items(): isl.setdefault(k, v)
            used |= set(m.ISL[i] for f in m.F for i in f)
    for mod in mods():
        for lod in ('near', 'mid', 'far'):
            m = build(mod, lod)
            AB = np.array(m.AB); ISL = np.array(m.ISL)
            for k in set(ISL.tolist()) & used:
                sel = ISL == k
                mx = AB[sel].max(0)
                isl[k] = dict(isl[k], w=max(isl[k]['w'], float(mx[0])+0.001), h=max(isl[k]['h'], float(mx[1])+0.001))
    s, rects = pack.pack(isl, used)
    L = dict(scale=s, rects=rects, islands={k: isl[k] for k in used}, kiosks=[m.KID for m in mods()])
    if write:
        os.makedirs(ROOT+'/work', exist_ok=True)
        json.dump(L, open(ROOT+'/work/layout.json', 'w'), indent=1, default=float)
    return L

def uv_array(m, L):
    rects = L['rects']; isl = L['islands']
    AB = np.asarray(m.AB); uv = np.zeros((len(m.V), 2))
    for i, k in enumerate(m.ISL):
        if k in rects: uv[i] = pack.uv_of(rects[k], isl[k], AB[i, 0], AB[i, 1])
    return uv

if __name__ == '__main__':
    L = layout()
    print('px/m at 2048 work:', round(L['scale'], 1), '-> colour 1024:', round(L['scale']/2, 1), 'px/m, normal/ORM 512:', round(L['scale']/4, 1))
    tot = 0
    for mod in mods():
        print(mod.KID, {lod: build(mod, lod).tris() for lod in ('hp', 'near', 'mid', 'far')})
    print('islands', len(L['rects']))
