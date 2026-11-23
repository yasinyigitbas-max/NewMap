# Meshy painted the first player's FINGERS paler and pinker than the back of his hand and the rest of his tanned skin
# (fingers r.74 g.48 b.40, back of the hand r.64 g.37 b.26; Yasin 23 Nov: "they are whiter than the rest"). This
# shifts only the fingers' texels to the back-of-hand tone (per channel gain), faded in over the knuckles; the rest
# of the texture, the mesh and the rig are untouched. Measured for the first Meshy player (T-pose, wrist |x| .695).
#   <venv with bpy 4.2>/bin/python tools/people/meshy/match_hand_skin.py IN.glb OUT.glb
import bpy, sys, numpy as np
from PIL import Image, ImageDraw, ImageFilter

a = sys.argv[sys.argv.index('--') + 1:]
IN, OUT = a[0], a[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=IN)
me = [o for o in bpy.data.objects if o.type == 'MESH'][0]
img = [n for n in me.data.materials[0].node_tree.nodes if n.type == 'TEX_IMAGE'][0].image
W, H = img.size
px = np.array(img.pixels[:], dtype=np.float32).reshape(H, W, 4)
uv = me.data.uv_layers.active.data

WRIST0, WRIST1 = 0.80, 0.845   # |x| in metres (T-pose): fade from 0 to full over the knuckles
mask = Image.new('L', (W, H), 0); d = ImageDraw.Draw(mask)
neck_cols = []
for p in me.data.polygons:
    c = me.matrix_world @ p.center
    ax = abs(c.x)
    pts = [(uv[li].uv[0] * W, uv[li].uv[1] * H) for li in p.loop_indices]   # (image rows bottom-up, like px)
    if ax > WRIST0:
        f = min(1.0, (ax - WRIST0) / (WRIST1 - WRIST0))
        d.polygon(pts, fill=int(255 * f))
    n = (me.matrix_world.to_3x3() @ p.normal).normalized()
    if 0.72 < ax < 0.80 and n.z > 0.5:          # back of the hand
        for (u, v) in pts: neck_cols.append(px[int(v) % H, int(u) % W, :3])
mask = mask.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(1.5))
m = np.asarray(mask, dtype=np.float32) / 255.0
neck = np.mean(neck_cols, 0)
skin = (m > 0.99) & (px[..., :3].mean(-1) > 0.3)        # hand skin, not tattoo ink or nails' dark lines
hand = px[skin][:, :3].mean(0)
gain = neck / hand
print('back of hand', np.round(neck, 3), 'fingers', np.round(hand, 3), 'gain', np.round(gain, 3))
g = 1.0 + (gain[None, None, :] - 1.0) * m[..., None]
px[..., :3] = np.clip(px[..., :3] * g, 0, 1)
img.pixels.foreach_set(px.ravel())
img.update(); img.pack()
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', export_animations=False, export_image_format='AUTO')
print('WROTE', OUT)
