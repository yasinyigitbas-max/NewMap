# Paint out grey spots on the hands (Yasin 23 Nov: "fill that grey part too"). v3 was painted from a photo on a grey
# background and some of that grey landed on the fingers (bands across them, grey in the gaps). Texels of the hands
# that are grey (low saturation) take the colour of the nearest skin texel of the hand. Only the hands' grey texels
# change; the mesh and the rig stay as Meshy made them. Run fill_seams.py too (padding).
#   <venv with bpy 4.2 + scipy>/bin/python tools/people/meshy/fix_hand_grey.py IN.glb OUT.glb
import bpy, sys, numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

a = sys.argv[sys.argv.index('--') + 1:]
IN, OUT = a[0], a[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=IN)
me = [o for o in bpy.data.objects if o.type == 'MESH'][0]
arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
wrist_x = abs((arm.matrix_world @ arm.data.bones['LeftHand'].head_local).x)
uv = me.data.uv_layers.active.data
img = [n for n in me.data.materials[0].node_tree.nodes if n.type == 'TEX_IMAGE' and n.image and 'normal' not in n.image.name and 'metal' not in n.image.name][0].image
W, H = img.size
mask = Image.new('L', (W, H), 0); d = ImageDraw.Draw(mask)
for p in me.data.polygons:
    if abs((me.matrix_world @ p.center).x) > wrist_x - 0.01:
        d.polygon([(uv[li].uv[0] * W, uv[li].uv[1] * H) for li in p.loop_indices], fill=255)
hand = np.asarray(mask) > 0
px = np.array(img.pixels[:], dtype=np.float32).reshape(H, W, -1)
rgb = px[..., :3]
mx = rgb.max(-1); mn = rgb.min(-1)
sat = (mx - mn) / np.maximum(mx, 1e-4)
grey = hand & (sat < 0.16) & (mx > 0.12)
grey = ndimage.binary_dilation(grey, iterations=2) & hand
skin = hand & ~grey
_, (iy, ix) = ndimage.distance_transform_edt(~skin, return_indices=True)
fill = rgb[iy, ix]
fill = ndimage.gaussian_filter(fill, sigma=(1.2, 1.2, 0))
rgb[grey] = fill[grey]
px[..., :3] = rgb
print('wrist |x| %.3f' % wrist_x, 'hand texels', int(hand.sum()), 'grey texels painted', int(grey.sum()))
img.pixels.foreach_set(px.ravel()); img.update(); img.pack()
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', export_animations=False, export_image_format='AUTO')
print('WROTE', OUT)
