"""The whole city's piece ground, written from the superchecker's read-outs in the form the land tools read
(tools/city/audit/ground_check.py, tools/city/pilot/zoning/lower_land_to_pieces.py, wall_feet.py): <out>.json,
<out>_v.bin, <out>_i.bin - the same three files tools/city/audit/ground_dump.gd writes.
Why: on the PC the whole-city ground_dump.gd run dies on the 2 GB card and had to be done in parts of 70 rows; the
read-outs are made one scene at a time and are already there. Reads only.

  python -I tools/city/super/sc_ground.py [<out base, default OUT/super/ground>]
"""
import json, os, sys
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sc_lib as L


def write(out=None):
    out = out or os.path.join(L.OUT, 'ground')
    rows = L.load_layout()
    L.ensure_dumps(sorted(set(r.piece for r in rows)), say=False)
    recs = []; vo = 0; io = 0; cache = {}
    with open(out + '_v.bin', 'wb') as fv, open(out + '_i.bin', 'wb') as fi:
        for r in rows:
            if r.piece.startswith(('w_', 't_')): continue
            if r.piece not in cache:
                try: cache[r.piece] = L.Dump(r.piece).ground()
                except Exception: cache[r.piece] = []
            G = cache[r.piece]
            if not G: continue
            R = r.R       # the row's turn: city = local @ R.T + pos; the tools read basis columns x, y, z then the origin
            rec = {'id': r.id, 'piece': r.piece, 'from': r.frm, 'xf': [float(R[0, 0]), float(R[1, 0]), float(R[2, 0]), float(R[0, 1]), float(R[1, 1]), float(R[2, 1]), float(R[0, 2]), float(R[1, 2]), float(R[2, 2])] + [float(v) for v in r.pos], 'surf': []}
            for name, T in G:
                V = T.reshape(-1, 3).astype('<f4'); n = len(V)
                fv.write(V.tobytes()); fi.write(np.arange(n, dtype='<i4').tobytes())
                rec['surf'].append([name, vo, n, io, n]); vo += n; io += n
            recs.append(rec)
    json.dump(recs, open(out + '.json', 'w'))
    print('GROUND written from the read-outs: %d ground meshes, %d triangles -> %s.json' % (len(recs), io // 3, os.path.relpath(out, L.REPO)))
    return out


if __name__ == '__main__':
    a = [x for x in sys.argv[1:] if not x.startswith('--')]
    write(a[0] if a else None)
