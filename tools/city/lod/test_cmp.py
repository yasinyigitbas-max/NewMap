"""compare the original tiers with the baked ones (from lod_bake.py --test=DIR) on a sheet"""
import sys, os, glob, numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import glbr, lod_audit
D = sys.argv[1]; names = sys.argv[2].split(',')
items = {n.split('/')[1]: (n, t) for n, t in lod_audit.find(glbr.__file__ and '/workspace/NewMap/assets/coronado_kit')}
rows = []
for nm in names:
    n, t = items[nm]
    near = glbr.load_any(t['near']); om = glbr.load_any(t['mid']); of = glbr.load_any(t['far'])
    def nb(tier):
        z = np.load(D + '/%s_%s.npz' % (n.replace('/', '__'), tier))
        return dict(P=z['P'], N=z['N'], UV=z['UV'], C=np.ones((len(z['P']), 4)), I=z['I'], albedo=D + '/bld_lod_color.png', orm=None, glass_alpha=True)
    nm_, nf = nb('mid'), nb('far')
    for az, el in ((35, 18), (200, 12)):
        R, U, F = glbr.view_basis(az, el)
        P = near['P']; b = ((P @ R).min() - 1, (P @ R).max() + 1, (P @ U).min() - 1, (P @ U).max() + 1)
        def r(m, ppm, orm=None):
            rgb, a, _ = glbr.render(m, az, el, 12.8, b, orm=orm); return glbr.down(glbr.compose(rgb, a), 12.8 / ppm)
        row1 = [r(near, 6.4), r(om, 6.4, near['orm']), r(nm_, 6.4)]
        row2 = [r(near, 1.75), r(of, 1.75), r(nf, 1.75)]
        up = lambda a: np.kron(a, np.ones((4, 4, 1)))[:row1[0].shape[0], :row1[0].shape[1]]
        row2 = [np.pad(up(x), ((0, max(0, row1[0].shape[0] - up(x).shape[0])), (0, max(0, row1[0].shape[1] - up(x).shape[1])), (0, 0)), constant_values=1) for x in row2]
        sep = np.ones((row1[0].shape[0], 6, 3))
        rows.append(np.concatenate(sum([[x, sep] for x in row1 + row2], []), 1))
W = max(x.shape[1] for x in rows)
sheet = np.concatenate([np.pad(x, ((0, 6), (0, W - x.shape[1]), (0, 0)), constant_values=1) for x in rows], 0)
glbr.to_img(sheet).save(sys.argv[3])
print('cols: near@60m | old mid@60m | NEW mid@60m | near@220m | old far@220m | NEW far@220m (x4)')
