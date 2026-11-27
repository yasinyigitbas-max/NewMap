"""blender -b -P zside.py -- <game_dir> <id> <out.png> [outline.json]
The left side of a built car (zh_build.py's body + its baked AO) for drawing its door outline: panel gaps show dark.
Front to the LEFT; the overlay grid (drawn by zside_grid.py) is in the Godot frame (z forward, y up)."""
import bpy, sys, math
sys.path.insert(0, '/home/user/NewMap/tools/vehicles_doors')
import meshio
argv = sys.argv[sys.argv.index('--') + 1:]
G, ID, OUT = argv[0], argv[1], argv[2]
for o in list(bpy.data.objects): bpy.data.objects.remove(o)
m = bpy.data.materials.new('m'); m.use_nodes = True; nt = m.node_tree
for n in list(nt.nodes): nt.nodes.remove(n)
out = nt.nodes.new('ShaderNodeOutputMaterial'); em = nt.nodes.new('ShaderNodeEmission')
tx = nt.nodes.new('ShaderNodeTexImage'); tx.image = bpy.data.images.load(G + '/tex/' + ID + '_veh_orm.png'); tx.image.colorspace_settings.name = 'Non-Color'
sep = nt.nodes.new('ShaderNodeSeparateColor'); nt.links.new(tx.outputs[0], sep.inputs[0])
pw = nt.nodes.new('ShaderNodeMath'); pw.operation = 'POWER'; pw.inputs[1].default_value = 3.0
nt.links.new(sep.outputs[0], pw.inputs[0]); nt.links.new(pw.outputs[0], em.inputs[0]); nt.links.new(em.outputs[0], out.inputs[0])
j, V, I = meshio.read(G + '/' + ID + '_body')
me = bpy.data.meshes.new('b')
me.from_pydata([meshio.g2b(v[0:3]) for v in V], [], [tuple(I[k:k + 3]) for k in range(0, len(I), 3)])
uv = me.uv_layers.new(name='UV')
for li, l in enumerate(me.loops):
    uv.data[li].uv = (V[l.vertex_index][10], 1 - V[l.vertex_index][11])
me.materials.append(m)
ob = bpy.data.objects.new('b', me); bpy.context.scene.collection.objects.link(ob)
sc = bpy.context.scene; sc.render.engine = 'CYCLES'; sc.cycles.samples = 2
sc.render.resolution_x, sc.render.resolution_y = 2400, 1000
sc.view_settings.view_transform = 'Standard'
cd = bpy.data.cameras.new('c'); cd.type = 'ORTHO'; cd.ortho_scale = 6.0
cam = bpy.data.objects.new('c', cd); sc.collection.objects.link(cam); sc.camera = cam
cam.location = (8, 0, 1.0); cam.rotation_euler = (math.radians(90), 0, math.radians(90))
cam.data.clip_start = 0.1; cam.data.clip_end = 8.5   # (left half of the car only: the far side does not show through)
sc.render.filepath = OUT
bpy.ops.render.render(write_still=True)
