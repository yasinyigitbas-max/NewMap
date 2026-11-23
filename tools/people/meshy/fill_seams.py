# Fill the texture's empty space around every UV island with the nearest island colour (texture padding), so the
# background grey never shows at a UV seam (Yasin 23 Nov: "fill that grey part too" - grey lines across v3's fingers).
# Only texels no triangle uses are changed; the mesh, the rig and the painted texels stay as Meshy made them.
#   <venv with bpy 4.2 + scipy>/bin/python tools/people/meshy/fill_seams.py IN.glb OUT.glb
import bpy, sys, numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

a = sys.argv[sys.argv.index('--') + 1:]
IN, OUT = a[0], a[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=IN)
me = [o for o in bpy.data.objects if o.type == 'MESH'][0]
uv = me.data.uv_layers.active.data
done = set()
for mat in me.data.materials:
    for node in mat.node_tree.nodes:
        if node.type != 'TEX_IMAGE' or node.image is None or node.image.name in done: continue
        img = node.image; done.add(img.name)
        W, H = img.size
        mask = Image.new('L', (W, H), 0); d = ImageDraw.Draw(mask)
        for p in me.data.polygons:
            d.polygon([(uv[li].uv[0] * W, uv[li].uv[1] * H) for li in p.loop_indices], fill=255)
        used = ndimage.binary_dilation(np.asarray(mask) > 0, iterations=1)   # (rows bottom-up, like pixels)
        px = np.array(img.pixels[:], dtype=np.float32).reshape(H, W, -1)
        _, (iy, ix) = ndimage.distance_transform_edt(~used, return_indices=True)
        filled = px[iy, ix]
        print(img.name, W, H, 'filled texels', int((~used).sum()))
        img.pixels.foreach_set(filled.ravel())
        img.update(); img.pack()
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', export_animations=False, export_image_format='AUTO')
print('WROTE', OUT)
