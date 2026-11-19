"""python3 grade_tile.py <png> gr gg gb lift : colour grade a baked tile in place"""
import sys, numpy as np
from PIL import Image
p=sys.argv[1]; g=np.array([float(x) for x in sys.argv[2:5]]); lift=float(sys.argv[5])
a=np.asarray(Image.open(p).convert('RGB'),np.float32)/255; a=np.clip(a*g+lift,0,1)
Image.fromarray((a*255+.5).astype(np.uint8)).save(p)
