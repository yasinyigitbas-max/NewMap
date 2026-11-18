import json, zlib, numpy as np
R="/home/user/coronado-source/"
def terrain():
    m=json.load(open(R+"map_dc/coronado/terrain/data/meta.json"))
    w,h=m["size_px"]
    H=np.frombuffer(zlib.decompress(open(R+"map_dc/coronado/terrain/data/height.f32z","rb").read()),dtype="<f4").reshape(h,w)
    cw,ch=m["class_size"]
    C=np.frombuffer(zlib.decompress(open(R+"map_dc/coronado/terrain/data/class.r8z","rb").read()),dtype=np.uint8).reshape(ch,cw)
    return m,H,C
def roads():
    return json.load(open(R+"map_dc/roads/lane_graph.json"))
