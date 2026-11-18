"""blender -b -t 2 -P wf_render.py -- job.json : hero / close-up renders of exported glbs (COLOR_0 x base colour like the
game), with an optional water plane and harbour bed for context (render only, not part of any asset).
job: [{"out":..., "glbs":[...], "water":1.5|null, "bed":true, "view":"hero|front|close|top", "fig":true, "res":[w,h],
       "target":[x,y,z] (glTF), "dist":m, "az":deg, "el":deg, "lens":mm, "samples":n}]"""
import bpy, sys, json, math
from mathutils import Vector
job=json.load(open(sys.argv[sys.argv.index('--')+1]))
sc=bpy.context.scene
def reset():
    for o in list(bpy.data.objects): bpy.data.objects.remove(o,do_unlink=True)
    for m in list(bpy.data.meshes): bpy.data.meshes.remove(m)
def mat(name,col,rough=0.6,metal=0.0,trans=0.0,alpha=1.0):
    m=bpy.data.materials.get(name) or bpy.data.materials.new(name); m.use_nodes=True; bs=m.node_tree.nodes['Principled BSDF']
    bs.inputs['Base Color'].default_value=col; bs.inputs['Roughness'].default_value=rough; bs.inputs['Metallic'].default_value=metal
    if 'Transmission Weight' in bs.inputs: bs.inputs['Transmission Weight'].default_value=trans
    bs.inputs['IOR'].default_value=1.33; bs.inputs['Alpha'].default_value=alpha
    return m
def imp(f):
    bpy.ops.import_scene.gltf(filepath=f); o=[x for x in bpy.context.selected_objects if x.type=='MESH'][0]
    for m in o.data.materials:
        nt=m.node_tree; bs=nt.nodes.get('Principled BSDF')
        tex=[n for n in nt.nodes if n.type=='TEX_IMAGE' and 'color' in n.image.name.lower()]
        if tex and bs:
            va=nt.nodes.new('ShaderNodeVertexColor'); mix=nt.nodes.new('ShaderNodeMix'); mix.data_type='RGBA'; mix.blend_type='MULTIPLY'; mix.inputs[0].default_value=1
            nt.links.new(tex[0].outputs['Color'],mix.inputs[6]); nt.links.new(va.outputs['Color'],mix.inputs[7]); nt.links.new(mix.outputs[2],bs.inputs['Base Color'])
    return o
def figure(x,y,z):
    import bmesh
    bm=bmesh.new()
    for (r,z0,z1,xx) in [(0.07,0,0.85,-0.1),(0.07,0,0.85,0.1),(0.19,0.85,1.5,0),(0.05,0.85,1.45,-0.26),(0.05,0.85,1.45,0.26),(0.06,1.5,1.58,0)]:
        bmesh.ops.create_cone(bm,cap_ends=True,segments=10,radius1=r,radius2=r,depth=z1-z0,matrix=__import__('mathutils').Matrix.Translation((xx,0,(z0+z1)/2)))
    bmesh.ops.create_uvsphere(bm,u_segments=12,v_segments=8,radius=0.11,matrix=__import__('mathutils').Matrix.Translation((0,0,1.69)))
    me=bpy.data.meshes.new('fig'); bm.to_mesh(me); ob=bpy.data.objects.new('fig',me); sc.collection.objects.link(ob); ob.location=(x,y,z)
    me.materials.append(mat('fig',(0.32,0.34,0.40,1),0.7)); return ob
for J in job:
    reset()
    sc.render.engine='CYCLES'; sc.cycles.device='CPU'; sc.cycles.samples=J.get('samples',32); sc.cycles.use_denoising=True
    sc.render.threads_mode='FIXED'; sc.render.threads=2; sc.view_settings.view_transform='AgX'; sc.cycles.max_bounces=6
    w=bpy.data.worlds.get('W') or bpy.data.worlds.new('W'); sc.world=w; w.use_nodes=True
    bg=w.node_tree.nodes['Background']; bg.inputs[0].default_value=(0.60,0.70,0.82,1); bg.inputs[1].default_value=0.9
    objs=[]; x=0.0
    for f in J['glbs']:
        o=imp(f); bpy.context.view_layer.update()
        if len(J['glbs'])>1:
            bb=[o.matrix_world@Vector(c) for c in o.bound_box]; mn=min(v.x for v in bb); mx=max(v.x for v in bb)
            o.location.x+=x-mn; x+=mx-mn+J.get('gap',1.0)
        objs.append(o)
    for t in J.get('extra',[]):   # placed extra glbs: {"glb":..., "loc":[x,y,z] blender, "rz":deg}
        o=imp(t['glb']); o.location=t.get('loc',(0,0,0)); o.rotation_mode='XYZ'; o.rotation_euler=(0,0,math.radians(t.get('rz',0))); objs.append(o)
    bpy.context.view_layer.update()
    bb=[o.matrix_world@Vector(c) for o in objs for c in o.bound_box]
    mn=Vector((min(v.x for v in bb),min(v.y for v in bb),min(v.z for v in bb))); mx=Vector((max(v.x for v in bb),max(v.y for v in bb),max(v.z for v in bb)))
    c=(mn+mx)/2; D=(mx-mn).length
    ext=J.get('ground_ext',8.0)
    if J.get('bed',True):
        bpy.ops.mesh.primitive_plane_add(size=1,location=(c.x,c.y,J.get('bed_z',0.0)-0.002)); g=bpy.context.active_object; g.scale=((mx.x-mn.x)+2*ext,(mx.y-mn.y)+2*ext,1)
        g.data.materials.append(mat('bed',(0.46,0.42,0.34,1),0.95))
    if J.get('land') is not None:   # land fill behind a quay (top at deck level), for context
        lx0,ly0,lx1,ly1,lz=J['land']
        bpy.ops.mesh.primitive_cube_add(size=1,location=((lx0+lx1)/2,(ly0+ly1)/2,lz/2-0.004)); l=bpy.context.active_object; l.scale=(lx1-lx0,ly1-ly0,lz)
        l.data.materials.append(mat('land',(0.50,0.49,0.46,1),0.9))
    if J.get('water') is not None:
        bpy.ops.mesh.primitive_plane_add(size=1,location=(c.x,c.y,J['water'])); wp=bpy.context.active_object; wp.scale=((mx.x-mn.x)+2*ext,(mx.y-mn.y)+2*ext,1)
        if J.get('water_clip'):   # keep the water out of the land area
            x0,y0,x1,y1=J['water_clip']; wp.scale=(x1-x0,y1-y0,1); wp.location=((x0+x1)/2,(y0+y1)/2,J['water'])
        wp.data.materials.append(mat('water',(0.10,0.22,0.24,1),0.04,0.0,0.75))
        wp.data.materials[0].node_tree.nodes['Principled BSDF'].inputs['Alpha'].default_value=0.62
    if J.get('fig'):
        fp=J['fig'] if isinstance(J['fig'],list) else [mn.x-0.6,c.y,J.get('fig_z',0.0)]
        figure(*fp)
    sun=bpy.data.lights.new('s','SUN'); sun.energy=3.4; sun.angle=0.1; so=bpy.data.objects.new('s',sun); sc.collection.objects.link(so); so.rotation_euler=(math.radians(J.get('sun_el',50)),0,math.radians(J.get('sun_az',-35)))
    cam=bpy.data.cameras.new('c'); co=bpy.data.objects.new('c',cam); sc.collection.objects.link(co); sc.camera=co
    tgt=Vector(J['target']) if J.get('target') else c
    az=math.radians(J.get('az',-35)); el=math.radians(J.get('el',22)); dist=J.get('dist',D*1.15)
    if J.get('ortho'):
        cam.type='ORTHO'; cam.ortho_scale=J.get('ortho_scale',max(mx.x-mn.x,mx.z-mn.z)*1.15)
    else: cam.lens=J.get('lens',40)
    co.location=tgt+Vector((math.sin(az)*math.cos(el)*dist,-math.cos(az)*math.cos(el)*dist,math.sin(el)*dist))
    co.rotation_euler=(tgt-co.location).to_track_quat('-Z','Y').to_euler()
    cam.clip_end=5000
    sc.render.resolution_x,sc.render.resolution_y=J.get('res',[960,640]); sc.render.resolution_percentage=100
    sc.render.filepath=J['out']; bpy.ops.render.render(write_still=True); print('RENDERED',J['out'],flush=True)
