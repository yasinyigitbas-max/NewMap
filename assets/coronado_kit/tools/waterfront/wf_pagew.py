"""page W slot-area usage report: used / free px in rows 384-1023, free 64-px blocks, boat slots"""
import json,sys,numpy as np
d=json.load(open('/workspace/coronado_kit_v2/_staging/waterfront/kit/props/_bake/slots_w.json'))['slots']
m=np.zeros((1024,1024),bool)
for k,v in d.items():
    for x,y,w,h in v: m[y:y+h,x:x+w]=True
free=int((~m[384:]).sum()); c=sum(1 for y in range(384,1024,64) for x in range(0,1024,64) if not m[y:y+64,x:x+64].any())
print(json.dumps({'slots':len(d),'slot_area_px':640*1024,'used_px':640*1024-free,'free_px':free,'free_pct':round(100*free/(640*1024),2),'free_64_blocks':c,
  **({'filter':{k:v for k,v in d.items() if any(s in k for s in sys.argv[1:])}} if sys.argv[1:] else {})}))
