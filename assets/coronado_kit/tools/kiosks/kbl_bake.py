"""Bake HP -> near for ALL kiosks in one pass (kiosk i at x = i*SPACING): tangent normal + AO (with a ground plane), 2048."""
import bpy, sys, os, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from kbl_common import *
args = sys.argv[sys.argv.index('--')+1:]
which = args[0] if args else 'both'
RES = int(os.environ.get('BAKE_RES', 2048)); AO_SAMPLES = int(os.environ.get('AO_SAMPLES', 64))
clear()
L = kcommon.layout()
own = kcommon.owners()
hps = []; los = []
for i, mod in enumerate(kcommon.mods()):
    off = (i*SPACING, 0, 0)
    hp = make_obj(kcommon.build(mod, 'hp'), 'hp_'+mod.KID, L, offset=off); hps.append(hp)
    lo = make_obj(kcommon.build(mod, 'near'), 'lo_'+mod.KID, L, canon_only=True, owner=own, bake_only=True, offset=off)
    if lo: los.append(lo)
    print(mod.KID, 'hp tris', len(kcommon.build(mod, 'hp').F), 'lo faces', len(lo.data.polygons) if lo else 0)
# join lo pieces into one target
bpy.ops.object.select_all(action='DESELECT')
for o in los: o.select_set(True)
bpy.context.view_layer.objects.active = los[0]; bpy.ops.object.join(); lo = los[0]; lo.name = 'lo'
bpy.ops.object.select_all(action='DESELECT')
for o in hps: o.select_set(True)
bpy.context.view_layer.objects.active = hps[0]; bpy.ops.object.join(); hp = hps[0]; hp.name = 'hp'
# ground plane (contact AO)
gp = bpy.data.meshes.new('ground'); n = len(kcommon.mods())
gp.from_pydata([(-6, -6, -0.001), (n*SPACING, -6, -0.001), (n*SPACING, 6, -0.001), (-6, 6, -0.001)], [], [(0, 1, 2, 3)])
gob = bpy.data.objects.new('ground', gp); bpy.context.scene.collection.objects.link(gob)
for a in ('visible_camera', 'visible_diffuse', 'visible_glossy', 'visible_transmission', 'visible_volume_scatter', 'visible_shadow'):
    setattr(lo, a, False)
sc = bpy.context.scene
sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'
w = bpy.data.worlds.new('w'); sc.world = w
w.light_settings.distance = float(os.environ.get('AO_DIST', 0.32))
mat = bpy.data.materials.new('bake'); mat.use_nodes = True; lo.data.materials.append(mat)
nt = mat.node_tree; img_node = nt.nodes.new('ShaderNodeTexImage'); nt.nodes.active = img_node
hm = bpy.data.materials.new('hpm'); hm.use_nodes = True; hp.data.materials.append(hm)
print('hp tris total', len(hp.data.polygons), 'lo faces', len(lo.data.polygons))
def run(kind, samples, fn):
    img = bpy.data.images.new(kind, RES, RES, alpha=False, float_buffer=True)
    img.colorspace_settings.name = 'Non-Color'
    img.generated_color = (0.5, 0.5, 1.0, 1.0) if kind == 'NORMAL' else (1, 1, 1, 1)
    img_node.image = img
    sc.cycles.samples = samples
    bpy.ops.object.select_all(action='DESELECT'); hp.select_set(True); lo.select_set(True); bpy.context.view_layer.objects.active = lo
    t = time.time()
    bpy.ops.object.bake(type=kind, use_selected_to_active=True, cage_extrusion=0.03, max_ray_distance=0.06,
                        normal_space='TANGENT', margin=8, margin_type='EXTEND', use_clear=True)
    print(kind, 'baked in', round(time.time()-t, 1), 's')
    sc.render.image_settings.file_format = 'PNG'; sc.render.image_settings.color_depth = '16'
    sc.render.image_settings.color_mode = 'RGB'; sc.view_settings.view_transform = 'Standard'
    img.save_render(fn, scene=sc)
os.makedirs(ROOT+'/work', exist_ok=True)
if which in ('both', 'normal'): run('NORMAL', 4, ROOT+'/work/bake_normal.png')
if which in ('both', 'ao'): run('AO', AO_SAMPLES, ROOT+'/work/bake_ao.png')
print('BAKE DONE')
