# register west-fill specs in review/grow_uw_blocks.json: usage reg.py spec1 spec2 ...
import sys, json, runpy, os
p='/home/user/NewMap/map_dc/coronado/city_kit/review/grow_uw_blocks.json'; d=json.load(open(p))
sys.path.insert(0,'/home/user/NewMap/OUT/wgen')
for f in sys.argv[1:]:
    S=runpy.run_path(f)
    first=S['DOC'].strip().split('\n')[0]
    plan=S['DOC'].split('PLANNER:')[1].strip().replace('\n',' ')[:300] if 'PLANNER:' in S['DOC'] else ''
    d['rows']=[r for r in d['rows'] if r['piece']!=S['NAME']]+[{"piece":S['NAME'],"pos":[S['U'],0.0,S['V']],"yaw":0.0,"site":first,"variant":plan}]
json.dump(d,open(p,'w'),indent=1); print(len(d['rows']),'rows')
