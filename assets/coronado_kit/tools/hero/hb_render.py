# bl.sh hb_render.py -- <out.png prefix> <glb> [<glb> ...]   views from env VIEWS="name:x,y,z:tx,ty,tz:lens;..." (Blender Z-up, model +Z(gltf) -> -Y blender)
import bpy, sys, os, math
from mathutils import Vector
argv = sys.argv[sys.argv.index('--') + 1:]
OUT = argv[0]; GLBS = argv[1:]
for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
sc = bpy.context.scene
sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = int(os.environ.get('SPP', 16)); sc.cycles.use_denoising = True
sc.cycles.max_bounces = 3; sc.view_settings.view_transform = 'Standard'
w = bpy.data.worlds.new('W'); sc.world = w; w.use_nodes = True
bg = w.node_tree.nodes['Background']; bg.inputs[0].default_value = (0.55, 0.68, 0.88, 1); bg.inputs[1].default_value = 1.0
for i, g in enumerate(GLBS):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=g)
    new = [o for o in bpy.data.objects if o not in before]
    off = float(os.environ.get('SPACING', 0)) * i
    for o in new:
        if o.parent is None: o.location.x += off
        if o.type != 'MESH': continue
        for ms in o.material_slots:
            m = ms.material
            if not m or m.get('_vc'): continue
            m['_vc'] = 1; nt = m.node_tree; bsdf = [n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'][0]
            inp = bsdf.inputs['Base Color']; src = inp.links[0].from_socket if inp.links else None
            ca = nt.nodes.new('ShaderNodeVertexColor'); ca.layer_name = o.data.color_attributes[0].name if o.data.color_attributes else ''
            mix = nt.nodes.new('ShaderNodeMix'); mix.data_type = 'RGBA'; mix.blend_type = 'MULTIPLY'; mix.inputs[0].default_value = 1.0
            if src: nt.links.new(src, mix.inputs[6])
            nt.links.new(ca.outputs[0], mix.inputs[7]); nt.links.new(mix.outputs[2], inp)
            if 'Emission Strength' in bsdf.inputs: bsdf.inputs['Emission Strength'].default_value = 0.0
            if 'Alpha' in bsdf.inputs:
                for l in list(bsdf.inputs['Alpha'].links): nt.links.remove(l)
                bsdf.inputs['Alpha'].default_value = 1.0
bpy.ops.object.light_add(type='SUN', rotation=(math.radians(48), 0, math.radians(float(os.environ.get('SUNZ', -40)))))
s = bpy.context.object; s.data.energy = 3.4; s.data.angle = math.radians(2)
bpy.ops.mesh.primitive_plane_add(size=400, location=(0, 0, -0.01)); gp = bpy.context.object
gm = bpy.data.materials.new('g'); gm.use_nodes = True; gm.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.45, 0.44, 0.40, 1); gp.data.materials.append(gm)
# a 1.8 m figure at the front steps
bpy.ops.mesh.primitive_cylinder_add(radius=0.22, depth=1.5, location=(float(os.environ.get('FIGX', 0)), float(os.environ.get('FIGY', -12)), 0.75))
fm = bpy.data.materials.new('f'); fm.use_nodes = True; fm.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.7, 0.1, 0.05, 1); bpy.context.object.data.materials.append(fm)
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.14, location=(float(os.environ.get('FIGX', 0)), float(os.environ.get('FIGY', -12)), 1.65)); bpy.context.object.data.materials.append(fm)
sc.render.resolution_x = int(os.environ.get('RX', 1280)); sc.render.resolution_y = int(os.environ.get('RY', 720))
sc.render.image_settings.file_format = 'JPEG'; sc.render.image_settings.quality = 88
for v in os.environ['VIEWS'].split(';'):
    nm, p, t, lens = v.split(':')
    p = Vector([float(q) for q in p.split(',')]); t = Vector([float(q) for q in t.split(',')])
    bpy.ops.object.camera_add(location=p); c = bpy.context.object; c.data.lens = float(lens); c.data.clip_end = 2000
    d = t - p; c.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler(); sc.camera = c
    sc.render.filepath = f'{OUT}_{nm}.jpg'; bpy.ops.render.render(write_still=True)
