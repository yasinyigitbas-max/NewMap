"""Preview renders from the exported kiosk glbs (Cycles). usage: kbl_render.py <tag> <kid|lineup> <view,...> [samples]
MODE env: full | nomaps (albedo only, no normal/ORM) | ao (ORM red only) | clay"""
import bpy, sys, os, math, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
from mathutils import Vector, Matrix, Euler
import kcommon
ROOT = kcommon.ROOT
args = sys.argv[sys.argv.index('--')+1:]
tag = args[0]; target = args[1]; views = args[2].split(','); SAMPLES = int(args[3]) if len(args) > 3 else 64
MODE = os.environ.get('MODE', 'full'); RES = float(os.environ.get('RES', 1.0))
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = SAMPLES; sc.cycles.use_denoising = True; sc.cycles.max_bounces = 6
sc.view_settings.view_transform = 'AgX'; sc.view_settings.look = os.environ.get('LOOK', 'AgX - Medium High Contrast'); sc.view_settings.exposure = float(os.environ.get('EXPO', -0.6))
W = bpy.data.worlds.new('w'); sc.world = W; W.use_nodes = True
nt = W.node_tree; bg = nt.nodes['Background']
sky = nt.nodes.new('ShaderNodeTexSky'); sky.sky_type = 'NISHITA'; sky.sun_elevation = math.radians(40); sky.sun_rotation = math.radians(-35)
sky.air_density = 1.0; sky.dust_density = 1.5
nt.links.new(sky.outputs[0], bg.inputs[0]); bg.inputs[1].default_value = 0.30
sun = bpy.data.objects.new('sun', bpy.data.lights.new('sun', 'SUN')); sc.collection.objects.link(sun)
sun.data.energy = 2.6; sun.data.angle = math.radians(1.5); sun.data.color = (1.0, 0.96, 0.9)
sun.rotation_euler = Euler((math.radians(50), 0, math.radians(-35+180+20)), 'XYZ')
fill = bpy.data.objects.new('fill', bpy.data.lights.new('fill', 'AREA')); sc.collection.objects.link(fill)
fill.data.energy = 300; fill.data.size = 6.0; fill.location = (-5, 6, 4)
fill.rotation_euler = (Vector((0, 0, 1)) - fill.location).to_track_quat('-Z', 'Y').to_euler()
pl = bpy.data.meshes.new('ground'); pl.from_pydata([(-60, -60, 0), (60, -60, 0), (60, 60, 0), (-60, 60, 0)], [], [(0, 1, 2, 3)])
gob = bpy.data.objects.new('ground', pl); sc.collection.objects.link(gob)
gm = bpy.data.materials.new('ground'); gm.use_nodes = True; gob.data.materials.append(gm)
gn = gm.node_tree; bs = gn.nodes['Principled BSDF']
nz = gn.nodes.new('ShaderNodeTexNoise'); nz.inputs['Scale'].default_value = 14; nz.inputs['Detail'].default_value = 8
cr = gn.nodes.new('ShaderNodeValToRGB'); cr.color_ramp.elements[0].color = (0.30, 0.27, 0.22, 1); cr.color_ramp.elements[1].color = (0.42, 0.38, 0.31, 1)
gn.links.new(nz.outputs[0], cr.inputs[0]); gn.links.new(cr.outputs[0], bs.inputs['Base Color']); bs.inputs['Roughness'].default_value = 0.9
MODS = {m.KID: m for m in kcommon.mods()}

def fix_mat(o):
    for ms in o.material_slots:
        m = ms.material
        if m is None or not m.use_nodes: continue
        nt = m.node_tree; bsdf = next((n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'), None)
        if MODE == 'clay':
            for k in ('Base Color', 'Normal', 'Roughness', 'Metallic'):
                for l in list(bsdf.inputs[k].links): nt.links.remove(l)
            bsdf.inputs['Base Color'].default_value = (0.6, 0.6, 0.6, 1); bsdf.inputs['Roughness'].default_value = 0.5; bsdf.inputs['Metallic'].default_value = 0
        if MODE in ('nomaps',):
            for k in ('Normal', 'Roughness', 'Metallic'):
                for l in list(bsdf.inputs[k].links): nt.links.remove(l)
            bsdf.inputs['Roughness'].default_value = 0.5; bsdf.inputs['Metallic'].default_value = 0.0
        if MODE == 'ao':
            orm = next((n for n in nt.nodes if n.type == 'TEX_IMAGE' and n.image and 'orm' in n.image.name.lower()), None)
            for k in ('Base Color', 'Normal', 'Roughness', 'Metallic'):
                for l in list(bsdf.inputs[k].links): nt.links.remove(l)
            if orm is not None:
                sep = nt.nodes.new('ShaderNodeSeparateColor'); nt.links.new(orm.outputs['Color'], sep.inputs[0]); nt.links.new(sep.outputs[0], bsdf.inputs['Base Color'])
            bsdf.inputs['Roughness'].default_value = 0.8; bsdf.inputs['Metallic'].default_value = 0.0
        for l in list(bsdf.inputs['Alpha'].links): nt.links.remove(l)
        bsdf.inputs['Alpha'].default_value = 1.0

def load(name, tier, loc=(0, 0, 0), rotz=0.0):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=f'{ROOT}/glb/{name}_{tier}.glb')
    objs = [o for o in bpy.data.objects if o not in before]
    for o in objs:
        if o.type == 'MESH': fix_mat(o)
        if o.parent is None: o.matrix_world = Matrix.Translation(Vector(loc)) @ Matrix.Rotation(rotz, 4, 'Z') @ o.matrix_world
    return objs

cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); sc.collection.objects.link(cam); sc.camera = cam
def g2b(p): return Vector((p[0], -p[2], p[1]))
def shoot(name, pos, tgt, lens=50, res=(1600, 1100), ortho=None):
    cam.location = g2b(pos); cam.data.lens = lens
    if ortho: cam.data.type = 'ORTHO'; cam.data.ortho_scale = ortho
    else: cam.data.type = 'PERSP'
    cam.rotation_euler = (g2b(tgt) - cam.location).to_track_quat('-Z', 'Y').to_euler()
    sc.render.resolution_x, sc.render.resolution_y = int(res[0]*RES), int(res[1]*RES)
    sc.render.filepath = f'{ROOT}/previews/{tag}_{target}_{name}.png' if target != 'lineup' else f'{ROOT}/previews/{tag}_{name}.png'
    bpy.ops.render.render(write_still=True)
os.makedirs(ROOT+'/previews', exist_ok=True)

def figure(loc):
    fm = bpy.data.materials.new('fig'); fm.use_nodes = True; fm.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.35, 0.36, 0.4, 1)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.17, depth=1.56, location=(0, 0, 0.78)); b1 = bpy.context.object
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.12, location=(0, 0, 1.68)); b2 = bpy.context.object
    for o in (b1, b2): o.data.materials.append(fm)
    bpy.ops.object.select_all(action='DESELECT'); b1.select_set(True); b2.select_set(True); bpy.context.view_layer.objects.active = b1
    bpy.ops.object.join(); b1.location = g2b(loc); return b1

if target == 'lineup':
    ks = list(MODS.values()); xs = np.cumsum([0] + [m.LINEUP_W for m in ks]); xs = xs - xs[-1]/2
    for m, x0, x1 in zip(ks, xs[:-1], xs[1:]): load(m.NAME, 'near', g2b(((x0+x1)/2, 0, 0)))
    span = xs[-1]-xs[0]
    for v in views:
        if v == 'front': shoot('lineup_front', (0, 2.2, span*0.95), (0, 1.1, 0), lens=40, res=(2400, 1100))
        if v == 'hero': shoot('lineup_hero', (span*0.35, 3.0, span*0.8), (0, 1.0, 0), lens=40, res=(2400, 1100))
        if v == 'fig':
            figure((xs[0]-0.6, 0, 0.8)); shoot('lineup_scale', (0, 1.2, span*1.4), (0, 1.1, 0), lens=50, res=(2400, 900))
    sys.exit(0)
mod = MODS[target]; NAME = mod.NAME
loaded = None
def ensure(kind):
    global loaded
    if loaded == kind: return
    for o in list(bpy.data.objects):
        if o.name not in ('sun', 'fill', 'ground', 'cam'): bpy.data.objects.remove(o)
    if kind == 'near': load(NAME, 'near')
    if kind == 'tiers':
        for i, t in enumerate(('near', 'mid', 'far')): load(NAME, t, g2b(((i-1)*mod.LINEUP_W*1.05, 0, 0)))
    if kind == 'fig':
        load(NAME, 'near'); figure(mod.FIG)
    loaded = kind
V = mod.VIEWS
for v in views:
    if v == 'tiers':
        ensure('tiers'); w = mod.LINEUP_W*3.3
        shoot('tiers', (0, mod.H*0.55, w*1.25), (0, mod.H*0.45, 0), lens=50, res=(2400, 900))
    elif v == 'fig':
        ensure('fig'); shoot('scale', V['front'][0], V['front'][1], V['front'][2], res=(1600, 1100))
    else:
        ensure('near'); p, t, lens = V[v]; shoot(v, p, t, lens)
