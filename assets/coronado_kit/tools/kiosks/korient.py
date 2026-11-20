"""Inward-face finder: from each near face centroid, cast a ray along its normal and count hits on the whole mesh.
Outward faces of closed parts see an even count (mostly 0); inward faces see an odd count. Reports odd fraction per island."""
import numpy as np, sys, importlib
from kgeo import Mesh
def check(mod, lod='near'):
    m = Mesh(lod, mod.KID); mod.build(m); V = np.array(m.V); F = np.array(m.F)
    ISLf = np.array([m.ISL[f[0]] for f in m.F])
    A, B, C = V[F[:, 0]], V[F[:, 1]], V[F[:, 2]]
    n = np.cross(B-A, C-A); n /= np.linalg.norm(n, axis=1, keepdims=True)
    cen = (A+B+C)/3
    e1, e2 = B-A, C-A
    odd = np.zeros(len(F), bool)
    for i in range(len(F)):
        o = cen[i] + n[i]*1e-4; d = n[i]
        p = np.cross(d, e2); det = np.einsum('ij,ij->i', e1, p)
        ok = np.abs(det) > 1e-12; inv = np.where(ok, 1/np.where(ok, det, 1), 0)
        t_ = o - A; u = np.einsum('ij,ij->i', t_, p)*inv
        q = np.cross(t_, e1); v = (q @ d)*inv; t = np.einsum('ij,ij->i', e2, q)*inv
        hit = ok & (u >= 0) & (v >= 0) & (u+v <= 1) & (t > 1e-5)
        hit[i] = False
        odd[i] = hit.sum() % 2 == 1
    res = {}
    for k in np.unique(ISLf):
        s = ISLf == k; res[k] = (odd[s].mean(), s.sum())
    return res
if __name__ == '__main__':
    mods = sys.argv[1:] or ['k_hotdog', 'k_paleta', 'k_taco', 'k_shaveice', 'k_lemonade']
    for mn in mods:
        mod = importlib.import_module(mn)
        r = check(mod)
        bad = sorted([(round(v[0], 2), k, v[1]) for k, v in r.items() if v[0] >= 0.5], reverse=True)
        print(mod.KID, 'islands with >=50% odd (likely inward):', bad)
