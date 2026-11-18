import sys;sys.path.insert(0,'/workspace/coronado_kit_v2/_staging/waterfront/tools');import wf_glb as G,numpy as np
from PIL import Image
from scipy.ndimage import binary_dilation
K='/workspace/coronado_kit_v2/_staging/waterfront/kit/props/waterfront/'
for f in sys.argv[1:]:
    mm=G.mesh(K+f+'_clean_mid.glb'); fa=G.mesh(K+f+'_clean_far.glb'); ims=[]
    for vn in ('front','top'):
        fr=G.frame_of([mm,fa],vn,0.05); res=max(0.02,max(fr[1]-fr[0],fr[3]-fr[2])/256)
        _,_,km=G.raster(mm,vn,fr,res); _,_,kf=G.raster(fa,vn,fr,res); r=max(1,int(round(0.04/res)))
        km=binary_dilation(km,iterations=r); kf=binary_dilation(kf,iterations=r)
        im=np.zeros(km.shape+(3,),np.uint8); im[km&~kf]=(255,0,0); im[kf&~km]=(0,0,255); im[km&kf]=(200,200,200); ims.append(Image.fromarray(im[::-1]).resize((im.shape[1]*3,im.shape[0]*3),0))
    w=sum(i.width for i in ims)+10; h=max(i.height for i in ims); c=Image.new('RGB',(w,h),(40,40,40)); x=0
    for i in ims: c.paste(i,(x,0)); x+=i.width+10
    c.save('/workspace/coronado_kit_v2/_staging/waterfront/work_backup_1003/diag_'+f.split('/')[-1]+'.png'); print('saved',f)
