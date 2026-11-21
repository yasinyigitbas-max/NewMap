#!/usr/bin/env python3
"""build Hotel Bel into _staging/landmarks/lmk_hotel_bel, validate, wall check; print the numbers"""
import sys, os, json, subprocess, shutil
os.environ['KIT_ATLAS'] = 'city'
os.environ.setdefault('MASK_EXTRA', '0.808,0.868')
HERE = os.path.dirname(os.path.abspath(__file__)); KIT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
from export import export_building
import city_hero, wallcheck
b = city_hero.hotel_bel()
STG = KIT + '/_staging'; d = f'{STG}/landmarks/{b.name}'
shutil.rmtree(d, ignore_errors=True)
st = export_building(b, STG, category_dir='landmarks')
print(json.dumps({k: (st[k]['tris'] if isinstance(st.get(k), dict) and 'tris' in st[k] else st.get(k)) for k in ('near', 'mid', 'far', 'budget', 'col_boxes', 'footprint_wd', 'height', 'logic_errors')}, default=str))
js = '/tmp/hbval.json'
env = dict(os.environ, VALIDATE_REPORT_DIR='/tmp/hbvalrep', VALIDATE_JSON=js)
subprocess.run([sys.executable, HERE + '/validate.py', d], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
v = json.load(open(js))[0]; print('validator', v['pass'], v['errors'][:12])
if '--wc' in sys.argv:
    wc = wallcheck.check(f'{d}/{b.cat}_{b.name}_near.glb', '/tmp/hb_wc'); print('wallcheck', {k: (x.get('pass') if isinstance(x, dict) else x) for k, x in wc.items()})
