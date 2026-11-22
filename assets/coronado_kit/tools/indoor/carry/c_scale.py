"""scale reference: 1.8 m figure carrying the prop by its grip_r in the right hand + the prop standing on the floor.
blender -b -P c_scale.py -- <out.png> <glb>"""
import bpy, sys, math, os
from mathutils import Vector, Matrix
a=sys.argv[sys.argv.index('--')+1:]; out,glb=a[0],a[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
sc=bpy.context.scene; sc.render.engine='CYCLES'; sc.cycles.device='CPU'; sc.cycles.samples=32; sc.cycles.use_denoising=True
sc.render.threads_mode='FIXED'; sc.render.threads=2; sc.view_settings.view_transform='AgX'
import bmesh
bm=bmesh.new()
# 1.8 m mannequin (same proportions as run.py's preview figure), right arm hanging with the hand at x=+0.26, z=0.80
for (r,z0,z1,x) in [(0.07,0,0.85,-0.1),(0.07,0,0.85,0.1),(0.19,0.85,1.5,0),(0.05,0.85,1.45,-0.26),(0.05,0.85,1.45,0.26),(0.06,1.5,1.58,0)]:
    bmesh.ops.create_cone(bm,cap_ends=True,segments=12,radius1=r,radius2=r,depth=z1-z0,matrix=Matrix.Translation((x,0,(z0+z1)/2)))
bmesh.ops.create_uvsphere(bm,u_segments=16,v_segments=10,radius=0.11,matrix=Matrix.Translation((0,0,1.69)))
bmesh.ops.create_uvsphere(bm,u_segments=10,v_segments=8,radius=0.045,matrix=Matrix.Translation((0.26,0,0.81)))   # fist
me=bpy.data.meshes.new('fig'); bm.to_mesh(me); fig=bpy.data.objects.new('fig',me); sc.collection.objects.link(fig)
fm=bpy.data.materials.new('fm'); fm.use_nodes=True; fm.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(0.35,0.37,0.42,1); me.materials.append(fm)
def load():
    before=set(sc.objects); bpy.ops.import_scene.gltf(filepath=glb); new=[o for o in sc.objects if o not in before]
    root=[o for o in new if o.parent is None]
    return new,root
def tint(obs):
    for o in obs:
        if o.type!='MESH': continue
        for m in o.data.materials:
            nt=m.node_tree; bs=next(n for n in nt.nodes if n.type=='BSDF_PRINCIPLED'); lk=bs.inputs['Base Color'].links
            if lk and o.data.color_attributes:
                src=lk[0].from_socket; ca=nt.nodes.new('ShaderNodeVertexColor'); ca.layer_name=o.data.color_attributes[0].name
                mu=nt.nodes.new('ShaderNodeMix'); mu.data_type='RGBA'; mu.blend_type='MULTIPLY'; mu.inputs['Factor'].default_value=1.0
                nt.links.new(src,mu.inputs['A']); nt.links.new(ca.outputs['Color'],mu.inputs['B']); nt.links.new(mu.outputs['Result'],bs.inputs['Base Color'])
new,root=load(); tint(new)
grip=next(o for o in new if o.name.startswith('grip_r')); bpy.context.view_layer.update()
gp=grip.matrix_world.translation.copy()
for r in root:   # carried: grip_r at the fist centre, handle bar along the walking direction (wide face to the side)
    r.rotation_mode='XYZ'; r.rotation_euler.z+=math.radians(90); bpy.context.view_layer.update()
gp=grip.matrix_world.translation.copy()
for r in root: r.location+=Vector((0.26,0,0.81))-gp
new2,root2=load(); tint(new2)
for r in root2: r.rotation_mode='XYZ'; r.location+=Vector((0.75,0.0,0)); r.rotation_euler.z=math.radians(-25)   # on the floor
w=bpy.data.worlds.new('W'); sc.world=w; w.use_nodes=True; w.node_tree.nodes['Background'].inputs[0].default_value=(0.62,0.66,0.72,1); w.node_tree.nodes['Background'].inputs[1].default_value=0.8
bpy.ops.mesh.primitive_plane_add(size=30); g=bpy.context.active_object
gm=bpy.data.materials.new('g'); gm.use_nodes=True; gm.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(0.32,0.30,0.28,1); g.data.materials.append(gm)
sun=bpy.data.lights.new('s','SUN'); sun.energy=3.0; sun.angle=0.1; so=bpy.data.objects.new('s',sun); sc.collection.objects.link(so); so.rotation_euler=(math.radians(50),0,math.radians(-30))
cam=bpy.data.cameras.new('c'); co=bpy.data.objects.new('c',cam); sc.collection.objects.link(co); sc.camera=co; cam.lens=50
tgt=Vector((0.35,0,0.9)); co.location=tgt+Vector((0.9,-4.2,0.5)); co.rotation_euler=(tgt-co.location).to_track_quat('-Z','Y').to_euler()
sc.render.resolution_x=900; sc.render.resolution_y=1100; sc.render.filepath=out; bpy.ops.render.render(write_still=True)
