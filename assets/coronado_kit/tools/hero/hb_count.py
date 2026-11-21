import sys, os, collections
os.environ['KIT_ATLAS'] = 'city'
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import export, city_hero, geom
if os.environ.get('NOSTREAK'): geom.STREAK_CELLS = False
b = city_hero.hotel_bel()
import time; T0=time.time()
for tier in sys.argv[1:] or ['near']:
    faces, sol = b.build(tier)
    tris = export.weld_tris(faces, sol)
    c = collections.Counter(); r = collections.Counter()
    for t in tris:
        so, rl, m = sol[t.f.sid]
        c[(m.get('type'), so.name)] += 1; r[t.f.reg] += 1
    print(tier, len(tris), round(time.time()-T0)); sys.stdout.flush()
    for k, v in c.most_common(40): print('  ', v, k)
    print('  regions', r.most_common(15))
