"""carry prop review renders (page-J texture x COLOR_0, as the game shows it) + grip marker check.
blender -b -P c_render.py -- <out_dir> <tag> <glb> [glb...] -> <out_dir>/<name>_<tag>_{hero,front,side,back,top,low}.png"""
import bpy, sys, math, os, json, struct
from mathutils import Vector
a=sys.argv[sys.argv.index('--')+1:]; out,tag,glbs=a[0],a[1],a[2:]
os.makedirs(out,exist_ok=True)
for glb in glbs:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc=bpy.context.scene; sc.render.engine='CYCLES'; sc.cycles.device='CPU'; sc.cycles.samples=32; sc.cycles.use_denoising=True
    sc.render.threads_mode='FIXED'; sc.render.threads=2; sc.view_settings.view_transform='AgX'
    bpy.ops.import_scene.gltf(filepath=glb)
    obs=[o for o in sc.objects if o.type=='MESH']
    grips=[o for o in sc.objects if o.type=='EMPTY' and o.name.startswith('grip')]
    for o in obs:
        for m in o.data.materials:
            nt=m.node_tree; bs=next(n for n in nt.nodes if n.type=='BSDF_PRINCIPLED')
            lk=bs.inputs['Base Color'].links
            if lk and o.data.color_attributes:
                src=lk[0].from_socket; ca=nt.nodes.new('ShaderNodeVertexColor'); ca.layer_name=o.data.color_attributes[0].name
                mu=nt.nodes.new('ShaderNodeMix'); mu.data_type='RGBA'; mu.blend_type='MULTIPLY'; mu.inputs['Factor'].default_value=1.0
                nt.links.new(src,mu.inputs['A']); nt.links.new(ca.outputs['Color'],mu.inputs['B']); nt.links.new(mu.outputs['Result'],bs.inputs['Base Color'])
    mn=Vector((min(min((o.matrix_world@Vector(c))[i] for c in o.bound_box) for o in obs) for i in range(3)))
    mx=Vector((max(max((o.matrix_world@Vector(c))[i] for c in o.bound_box) for o in obs) for i in range(3)))
    w=bpy.data.worlds.new('W'); sc.world=w; w.use_nodes=True; w.node_tree.nodes['Background'].inputs[0].default_value=(0.55,0.58,0.62,1); w.node_tree.nodes['Background'].inputs[1].default_value=0.7
    bpy.ops.mesh.primitive_plane_add(size=30); g=bpy.context.active_object
    gm=bpy.data.materials.new('g'); gm.use_nodes=True; gm.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(0.30,0.28,0.26,1); g.data.materials.append(gm)
    # grip markers: small red spheres (review only)
    rm=bpy.data.materials.new('r'); rm.use_nodes=True; rm.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(0.9,0.05,0.03,1)
    for gr in grips:
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.006,location=gr.matrix_world.translation); s_=bpy.context.active_object; s_.data.materials.append(rm); s_.name='mk_'+gr.name
    ctr=(mn+mx)/2; sz=(mx-mn); size=max(sz.x,sz.z,sz.y)
    L=bpy.data.lights.new('k','AREA'); L.energy=60; L.size=1.5; lo=bpy.data.objects.new('k',L); sc.collection.objects.link(lo)
    lo.location=ctr+Vector((-1.2,-1.6,1.9)); lo.rotation_euler=(ctr-lo.location).to_track_quat('-Z','Y').to_euler()
    L2=bpy.data.lights.new('f','AREA'); L2.energy=25; L2.size=2; l2=bpy.data.objects.new('f',L2); sc.collection.objects.link(l2)
    l2.location=ctr+Vector((1.8,-0.6,1.2)); l2.rotation_euler=(ctr-l2.location).to_track_quat('-Z','Y').to_euler()
    cam=bpy.data.cameras.new('c'); co=bpy.data.objects.new('c',cam); sc.collection.objects.link(co); sc.camera=co; cam.lens=60
    name=os.path.basename(glb).replace('prop_','').replace('_clean_near.glb','')
    def shot(nm,dirv,k=1.0,rx=900,ry=900):
        sc.render.resolution_x=rx; sc.render.resolution_y=ry
        d=Vector(dirv).normalized(); dist=size*2.2*k+0.15
        co.location=ctr+d*dist; co.rotation_euler=(ctr-co.location).to_track_quat('-Z','Y').to_euler()
        sc.render.filepath=f'{out}/{name}_{tag}_{nm}.png'; bpy.ops.render.render(write_still=True)
    shot('hero',(0.8,-1.0,0.55)); shot('front',(0.0,-1.0,0.12),k=0.85); shot('side',(-1.0,-0.15,0.25),k=0.9)
    shot('back',(-0.6,1.0,0.45)); shot('top',(0.25,-0.45,1.0),k=0.8); shot('low',(0.7,-0.8,-0.05),k=0.9)
