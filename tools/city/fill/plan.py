import numpy as np, cv2, json, os
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage as ndi
D=np.load('OUT/fill/coverage.npz'); C=D['cls']; L=D['land']; x0=float(D['x0']); z0=float(D['z0']); res=float(D['res'])
A=np.zeros(C.shape+(3,),np.uint8); A[:]=(45,102,137); A[C==0]=(212,77,67); A[C==1]=(139,157,115); A[(C==2)&L]=(92,164,185)
A[D['road']>0]=(78,76,75)
# downscale 2 m
im=Image.fromarray(A).resize((C.shape[1]//4,C.shape[0]//4)); d=ImageDraw.Draw(im)
f=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',11)
for x in range(-1800,1901,200):
 px=(x-x0)/2; d.line((px,0,px,im.height),fill=(95,105,103),width=1); d.text((px+2,5),str(x),font=f,fill='white')
for z in range(-1800,901,200):
 py=(z-z0)/2; d.line((0,py,im.width,py),fill=(95,105,103),width=1); d.text((2,py+2),str(z),font=f,fill='white')
im.save('/workspace/share/fill_audit/01_coverage_before.png')
# components empty in island
M=(C==0)&L
lab,n=ndi.label(M); sizes=np.bincount(lab.ravel()); ids=np.argsort(sizes[1:])[::-1]+1
rows=[]
objs=ndi.find_objects(lab)
com=ndi.center_of_mass(M,lab,ids[:2000])
for k,i in enumerate(ids):
 if sizes[i]*res*res<1: break
 sl=objs[i-1]; cy,cx=com[k] if k<2000 else ((sl[0].start+sl[0].stop)/2,(sl[1].start+sl[1].stop)/2)
 rows.append({'id':int(i),'m2':float(sizes[i]*res*res),'bbox':[x0+sl[1].start*res,z0+sl[0].start*res,x0+sl[1].stop*res,z0+sl[0].stop*res],'center':[round(x0+cx*res,1),round(z0+cy*res,1)]})
json.dump(rows,open('OUT/fill/gaps.json','w'),indent=1)
np.save('OUT/fill/gap_labels.npy',lab)
print('components >=1m2:',len(rows), 'total m2', sum(r['m2'] for r in rows))
for r in rows[:40]: print(r)
import collections
b=collections.Counter('<10' if r['m2']<10 else '<100' if r['m2']<100 else '<1000' if r['m2']<1000 else '<10000' if r['m2']<1e4 else 'big' for r in rows); print(b)
