import sys, os, glob, json, subprocess, numpy as np
sys.path.insert(0, '../scripts')
from clean_kimodo import clean; from fix_kimodo import fix; from measure import measure, summary
rows = []
for d in sorted(glob.glob('out/*')):
    f = d + '/kimodo_motion_00.fbx'
    if not os.path.exists(f): print('no fbx', d); continue
    try:
        clean(f, d + '/clean.fbx'); r = fix(d + '/clean.fbx', d + '/kimodo_motion_00.npz', d + '/fixed.fbx')
        s = summary(d + '/fixed.fbx'); s['clip'] = os.path.basename(d); s['foot_slide'] = r['foot_slide']; rows.append(s)
        if not os.path.exists(d + '/sheet.png'):
            subprocess.run(['ffmpeg','-loglevel','error','-y','-i',d+'/preview.mp4','-vf','fps=3,scale=384:-1,tile=6x3','-frames:v','1',d+'/sheet.png'])
    except Exception as e: print('ERR', d, repr(e)[:200])
json.dump(rows, open('out/measure.json', 'w'))
c = ['dur','fwd','side','rise','speed','yaw_delta','hips_y0','hips_ymin','hips_ymax','hips_y1','feet_y1','feet_max_low','hand_min','hand_max','head_min','head_max','foot_slide','loop_err']
print('clip | ' + ' '.join(c))
for s in rows: print(s['clip'], '|', ' '.join(str(round(s[k], 2)) for k in c))
