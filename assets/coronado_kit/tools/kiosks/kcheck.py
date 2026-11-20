#!/usr/bin/env python3
"""Kiosk acceptance check (kit SPEC rules + kiosk budgets). exit 1 on fail. usage: kcheck.py [glb_dir] [report.json]"""
import os, sys, json, numpy as np, pygltflib
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kcommon
ROOT = kcommon.ROOT
BUDGET = dict(near=4500, mid=1350, far=200)     # proposed class "street-food kiosk / cart" (maximums), see reports/BUDGET.md
COL_MAX_BOXES = 12
TEX = ['kiosks_color.png', 'kiosks_normal.png', 'kiosks_orm.png']
GLB = sys.argv[1] if len(sys.argv) > 1 else ROOT+'/glb'
REP = sys.argv[2] if len(sys.argv) > 2 else ROOT+'/reports/k_check.json'
TEXDIR = ROOT+'/tex' if os.path.isdir(ROOT+'/tex') else GLB   # repo layout: textures sit next to the GLBs

def load(p):
    g = pygltflib.GLTF2().load(p); blob = g.binary_blob()
    def acc(i):
        a = g.accessors[i]; bv = g.bufferViews[a.bufferView]
        n = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}[a.type]
        dt = {5126: np.float32, 5125: np.uint32, 5123: np.uint16, 5121: np.uint8}[a.componentType]
        arr = np.frombuffer(blob, dt, count=a.count*n, offset=(bv.byteOffset or 0)+(a.byteOffset or 0))
        return arr.reshape(-1, n) if n > 1 else arr
    return g, acc

def check(name, tier, mod):
    p = f'{GLB}/{name}_{tier}.glb'; E = []; info = {'asset': name, 'tier': tier}
    if not os.path.exists(p): return dict(info, errors=['missing'])
    g, acc = load(p)
    meshnodes = [i for i, n in enumerate(g.nodes) if n.mesh is not None]
    if g.cameras or g.animations or g.skins: E.append('cameras/animations/skins present')
    if len(g.meshes) != 1 or len(meshnodes) != 1 or len(g.nodes) != 1: E.append(f'{len(g.meshes)} meshes / {len(g.nodes)} nodes (need 1/1)')
    n0 = g.nodes[meshnodes[0]]
    if (n0.translation and any(abs(t) > 1e-6 for t in n0.translation)) or (n0.rotation and any(abs(r) > 1e-6 for r in n0.rotation[:3])) or (n0.scale and any(abs(s-1) > 1e-6 for s in n0.scale)):
        E.append('node has a transform (must be identity)')
    if tier != 'col' and len(g.materials or []) != 1: E.append(f'{len(g.materials or [])} materials (need 1)')
    tris = 0; verts = 0; flip = 0; area = 0; allP = []
    for i in meshnodes:
        me = g.meshes[g.nodes[i].mesh]
        if len(me.primitives) != 1: E.append(f'{len(me.primitives)} primitives')
        for pr in me.primitives:
            idx = acc(pr.indices).reshape(-1, 3).astype(int); P = acc(pr.attributes.POSITION).astype(float); allP.append(P)
            tris += len(idx); verts += len(P)
            if len(P) > 65000: E.append('over 65k verts')
            at = pr.attributes
            if tier != 'col':
                for k, nm in (('NORMAL', 'normals'), ('TANGENT', 'tangents'), ('TEXCOORD_0', 'UV0')):
                    if getattr(at, k) is None: E.append('no '+nm)
                if at.TEXCOORD_1 is not None: E.append('UV1 present')
                if at.COLOR_0 is not None: E.append('COLOR_0 present')
                Nn = acc(at.NORMAL).astype(float)
                v0, v1, v2 = P[idx[:, 0]], P[idx[:, 1]], P[idx[:, 2]]
                fn = np.cross(v1-v0, v2-v0); a = 0.5*np.linalg.norm(fn, axis=1)
                if (a < 1e-12).sum(): E.append(f'{int((a < 1e-12).sum())} degenerate tris')
                d = (fn*Nn[idx].mean(1)).sum(1); flip += a[d < 0].sum(); area += a.sum()
                uv = acc(at.TEXCOORD_0)
                if uv.min() < -0.001 or uv.max() > 1.001: E.append('UV outside 0..1')
    info['tris'] = tris; info['verts'] = verts
    if tier in BUDGET and tris > BUDGET[tier]: E.append(f'{tris} tris over budget {BUDGET[tier]}')
    if area: info['flip_frac'] = round(float(flip/area), 4)
    if area and flip/area > 0.02: E.append(f'normals disagree with winding on {flip/area:.1%} of area')
    Pa = np.vstack(allP); lo, hi = Pa.min(0), Pa.max(0); info['bounds'] = [lo.round(3).tolist(), hi.round(3).tolist()]
    if lo[1] < -0.01: E.append(f'below ground {lo[1]:.3f}')
    if tier != 'col' and abs(lo[1]) > 0.01: E.append(f'not on ground (ymin {lo[1]:.3f})')
    if tier == 'col':
        nb = tris // 12; info['boxes'] = nb
        if tris % 12 or nb > COL_MAX_BOXES: E.append(f'col {tris} tris (need <= {COL_MAX_BOXES} boxes x 12)')
        if g.meshes[0].name != 'col': E.append('col mesh not named col')
        c0 = kcommon.build(mod, 'near').col[0][0]; cx, cz = getattr(mod, 'FOOT', (c0[0], c0[2]))
        # rule: origin at the footprint centre of the main body (first col box), on the ground
        if abs(cx) > 0.15 or abs(cz) > 0.15: E.append(f'origin off main-body footprint centre dx={cx:.3f} dz={cz:.3f}')
    else:
        mt = g.materials[0]
        if mt.alphaMode not in (None, 'OPAQUE'): E.append('not OPAQUE')
        for im in g.images:
            u = im.uri or ''
            if os.path.basename(u) not in TEX: E.append(f'foreign texture {u}')
            f = os.path.normpath(os.path.join(os.path.dirname(p), u))
            if not os.path.exists(f): E.append(f'missing texture file {u}')
        if tier == 'near':
            if mt.normalTexture is None: E.append('no normalTexture')
            if mt.occlusionTexture is None: E.append('no occlusionTexture')
            elif mt.pbrMetallicRoughness.metallicRoughnessTexture is None or mt.occlusionTexture.index != mt.pbrMetallicRoughness.metallicRoughnessTexture.index:
                E.append('occlusionTexture is not the ORM')
        elif mt.normalTexture is not None or mt.occlusionTexture is not None: E.append('mid/far must be colour only')
    info['errors'] = E
    return info

def main():
    rows = []
    for mod in kcommon.mods():
        for t in ('near', 'mid', 'far', 'col'): rows.append(check(mod.NAME, t, mod))
    mem = 0; texinfo = {}
    for t in TEX:
        w, h = Image.open(f'{TEXDIR}/{t}').size; mb = w*h*4/3/2**20; mem += mb; texinfo[t] = [w, h, round(mb, 3)]
    ok = all(not r['errors'] for r in rows)
    for r in rows: print(('PASS' if not r['errors'] else 'FAIL'), r['asset'], r['tier'], r.get('tris'), '/', BUDGET.get(r['tier'], '-'), '; '.join(r['errors']) or 'ok')
    print(f'texture memory ASTC 4x4 + mips: {mem:.3f} MiB', texinfo)
    os.makedirs(os.path.dirname(REP), exist_ok=True)
    json.dump(dict(rows=rows, tex=texinfo, tex_mib=round(mem, 3), pass_=ok, budget=BUDGET), open(REP, 'w'), indent=1)
    print('ALL PASS' if ok else 'FAILED'); sys.exit(0 if ok else 1)
main()
