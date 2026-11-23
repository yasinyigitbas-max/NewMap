# Usage: <venv with bpy 4.2>/bin/python tools/people/meshy/build_low.py -- 12000 0.02 --out <path without extension>
#   12000 = triangles, 0.02 = head weight (0.02 gave the head ~3,200 of 12,000). Writes <out>.glb and <out>_base_color.png.
# Our own low version of Yasin's character: decimate the 557k shape with the head kept dense, new UVs with the face
# given a big share, colour baked from his 10k Meshy version.
import bpy, bmesh, sys, math, mathutils
HEADW = float(sys.argv[sys.argv.index('--')+2]) if '--' in sys.argv else 0.3
TARGET = int(sys.argv[sys.argv.index('--')+1]) if '--' in sys.argv else 12000
OUT = sys.argv[sys.argv.index('--out')+1] if '--out' in sys.argv else '/tmp/player_low'
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='/home/user/NewMap/assets/people/meshy/yasin_own/model.glb')
hi=[o for o in bpy.context.selected_objects if o.type=='MESH'][0]
bpy.ops.import_scene.fbx(filepath='/home/user/NewMap/assets/people/meshy/yasin_own/lowpoly_10k/model_10k.fbx')
src=[o for o in bpy.context.selected_objects if o.type=='MESH'][0]
for o in (hi,src):
    bpy.context.view_layer.objects.active=o; o.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    o.select_set(False)
# make the target a copy of the high shape
low=hi.copy(); low.data=hi.data.copy(); low.name='player_low'; bpy.context.scene.collection.objects.link(low)
hi.hide_render=True
bpy.context.view_layer.objects.active=low; low.select_set(True)
# merge doubles first (glTF splits)
bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.remove_doubles(threshold=1e-5); bpy.ops.object.mode_set(mode='OBJECT')
# 1) uniform pre-reduce to 120k
m=low.modifiers.new('d0','DECIMATE'); m.ratio=120000/len(low.data.polygons); bpy.ops.object.modifier_apply(modifier='d0')
# 2) weighted: head (above the neck) and hands keep more
zs=[v.co.z for v in low.data.vertices]; zmax=max(zs); zmin=min(zs); H=zmax-zmin
vg=low.vertex_groups.new(name='keep')
for v in low.data.vertices:
    w=0.0
    t=(zmax-v.co.z)/H
    if t<0.13: w=HEADW                       # head
    elif t<0.16: w=HEADW*(1.0-(t-0.13)/0.03) # neck fade
    if abs(v.co.x)>0.30*H/1.9*1.9/1.9 and v.co.z< zmin+0.62*H and v.co.z> zmin+0.42*H: w=max(w,HEADW*0.6)  # hands
    vg.add([v.index], w, 'REPLACE')
def tris(o):
    me=o.data; me.calc_loop_triangles(); return len(me.loop_triangles)
# Decimate with vertex group: try invert both ways, pick by head share; binary search ratio for the total
def trial(ratio, inv, factor, apply=False):
    m=low.modifiers.new('d1','DECIMATE'); m.ratio=ratio; m.vertex_group='keep'; m.invert_vertex_group=inv; m.vertex_group_factor=factor
    dg=bpy.context.evaluated_depsgraph_get(); ev=low.evaluated_get(dg); me=ev.to_mesh(); me.calc_loop_triangles()
    n=len(me.loop_triangles)
    head=sum(1 for t in me.loop_triangles if all((zmax-me.vertices[i].co.z)/H<0.13 for i in t.vertices))
    ev.to_mesh_clear()
    if apply: bpy.ops.object.modifier_apply(modifier='d1')
    else: low.modifiers.remove(m)
    return n, head

n,head=trial(TARGET/len(low.data.polygons)*1.0, True, 0.5, apply=True)
print('LOW tris',tris(low),'head',head)
bpy.ops.object.shade_smooth()
# UVs: scale head up 2.5x before smart project so the face gets ~6x the texture area, then put it back
me=low.data
headc=mathutils.Vector((0,0,zmax-0.065*H))
orig={v.index:v.co.copy() for v in me.vertices}
for v in me.vertices:
    t=(zmax-v.co.z)/H
    k=2.5 if t<0.14 else (1+1.5*max(0,(0.17-t)/0.03) if t<0.17 else 1.0)
    if k!=1.0: v.co=headc+(v.co-headc)*k
bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.002, scale_to_bounds=False)
bpy.ops.uv.pack_islands(rotate=True, margin=0.003)
bpy.ops.object.mode_set(mode='OBJECT')
for v in me.vertices: v.co=orig[v.index]
# source material: his 10k colour
smat=bpy.data.materials.new('src'); smat.use_nodes=True
nt=smat.node_tree; bsdf=nt.nodes['Principled BSDF']
img=nt.nodes.new('ShaderNodeTexImage'); img.image=bpy.data.images.load('/home/user/NewMap/assets/people/meshy/yasin_own/lowpoly_10k/base_color.png')
nt.links.new(img.outputs['Color'], bsdf.inputs['Base Color'])
src.data.materials.clear(); src.data.materials.append(smat)
# target material + bake image
tex=bpy.data.images.new('player_base_color', 2048, 2048)
tmat=bpy.data.materials.new('player'); tmat.use_nodes=True
tn=tmat.node_tree; tb=tn.nodes['Principled BSDF']; ti=tn.nodes.new('ShaderNodeTexImage'); ti.image=tex
tn.links.new(ti.outputs['Color'], tb.inputs['Base Color']); tb.inputs['Roughness'].default_value=0.8
tn.nodes.active=ti
low.data.materials.clear(); low.data.materials.append(tmat)
sc=bpy.context.scene; sc.render.engine='CYCLES'; sc.cycles.device='CPU'; sc.cycles.samples=4
bk=sc.render.bake; bk.use_pass_direct=False; bk.use_pass_indirect=False; bk.use_pass_color=True
bk.use_selected_to_active=True; bk.cage_extrusion=0.015; bk.max_ray_distance=0.05; bk.margin=16
src.hide_render=False
bpy.ops.object.select_all(action='DESELECT'); src.select_set(True); low.select_set(True); bpy.context.view_layer.objects.active=low
bpy.ops.object.bake(type='DIFFUSE')
tex.filepath_raw=OUT+'_base_color.png'; tex.file_format='PNG'; tex.save()
# scale to 1.83 m, feet on 0
bpy.ops.object.select_all(action='DESELECT'); low.select_set(True); bpy.context.view_layer.objects.active=low
k=1.83/H; low.scale=(k,k,k); low.location=(0,0,-zmin*k)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bpy.ops.export_scene.gltf(filepath=OUT+'.glb', use_selection=True, export_format='GLB', export_image_format='JPEG', export_jpeg_quality=92)
print('EXPORTED', tris(low))
