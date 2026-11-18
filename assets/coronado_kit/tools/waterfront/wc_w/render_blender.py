# blender -b -P render_blender.py -- <outdir> <model_dir> [<model_dir> ...]
import bpy, sys, os, math, glob
from mathutils import Vector
argv=sys.argv[sys.argv.index('--')+1:]
OUT=argv[0]; DIRS=argv[1:]
def clear():
    for o in list(bpy.data.objects): bpy.data.objects.remove(o,do_unlink=True)
    for m in list(bpy.data.meshes): bpy.data.meshes.remove(m)
    for m in list(bpy.data.materials): bpy.data.materials.remove(m)
    for i in list(bpy.data.images): bpy.data.images.remove(i)
def setup():
    sc=bpy.context.scene
    sc.render.engine='CYCLES'; sc.cycles.device='CPU'; sc.cycles.samples=24; sc.cycles.use_denoising=True
    sc.cycles.max_bounces=3; sc.render.film_transparent=False
    sc.view_settings.view_transform='Standard'
    w=bpy.data.worlds.get('W') or bpy.data.worlds.new('W'); sc.world=w; w.use_nodes=True
    bg=w.node_tree.nodes['Background']; bg.inputs[0].default_value=(0.62,0.72,0.85,1); bg.inputs[1].default_value=0.9
def imp(path):
    before=set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new=[o for o in bpy.data.objects if o not in before]
    for o in new:
        if o.type=='MESH':
            for ms in o.material_slots:
                m=ms.material
                if not m or m.get('_vc'): continue
                m['_vc']=1
                nt=m.node_tree; bsdf=[n for n in nt.nodes if n.type=='BSDF_PRINCIPLED'][0]
                inp=bsdf.inputs['Base Color']
                src=inp.links[0].from_socket if inp.links else None
                ca=nt.nodes.new('ShaderNodeVertexColor'); ca.layer_name=o.data.color_attributes[0].name if o.data.color_attributes else ''
                mix=nt.nodes.new('ShaderNodeMix'); mix.data_type='RGBA'; mix.blend_type='MULTIPLY'; mix.inputs[0].default_value=1.0
                if src: nt.links.new(src,mix.inputs[6])
                nt.links.new(ca.outputs[0],mix.inputs[7]); nt.links.new(mix.outputs[2],inp)
                if os.environ.get('DIAG_NOVC'): mix.inputs[0].default_value=0.0
                if os.environ.get('DIAG_MASK'):
                    # emission mask of wall-strip texels (atlas rows 4..732 -> blender v > 0.642)
                    for l in list(inp.links): nt.links.remove(l)
                    uvn=nt.nodes.new('ShaderNodeUVMap'); sep=nt.nodes.new('ShaderNodeSeparateXYZ'); cmp=nt.nodes.new('ShaderNodeMath'); cmp.operation='GREATER_THAN'
                    cmp.inputs[1].default_value=0.642; nt.links.new(uvn.outputs[0],sep.inputs[0]); nt.links.new(sep.outputs[1],cmp.inputs[0])
                    # smooth wall materials only (stucco, siding, brick, board&batten); shingle/stone/half-timber relief is intended texture
                    def band(lo,hi):
                        g1=nt.nodes.new('ShaderNodeMath'); g1.operation='GREATER_THAN'; g1.inputs[1].default_value=lo; nt.links.new(sep.outputs[1],g1.inputs[0])
                        l1=nt.nodes.new('ShaderNodeMath'); l1.operation='LESS_THAN'; l1.inputs[1].default_value=hi; nt.links.new(sep.outputs[1],l1.inputs[0])
                        m1=nt.nodes.new('ShaderNodeMath'); m1.operation='MULTIPLY'; nt.links.new(g1.outputs[0],m1.inputs[0]); nt.links.new(l1.outputs[0],m1.inputs[1]); return m1.outputs[0]
                    acc=None
                    bands_=[(0.871,0.999),(0.643,0.674)]
                    for sp_ in os.environ.get('MASK_EXTRA','').split(';'):   # city atlas: W_concrete rows
                        if sp_.strip(): bands_.append(tuple(float(v) for v in sp_.split(',')))
                    for (lo,hi) in bands_:   # stucco/siding, b&b (brick has mortar relief: checked by atlas_check only)
                        o_=band(lo,hi)
                        if acc is None: acc=o_
                        else:
                            mx_=nt.nodes.new('ShaderNodeMath'); mx_.operation='MAXIMUM'; nt.links.new(acc,mx_.inputs[0]); nt.links.new(o_,mx_.inputs[1]); acc=mx_.outputs[0]
                    if os.environ.get('WC_RECTS'):   # staging (page W): wall mask = explicit atlas rects u0,u1,v0,v1 (blender v)
                        def rng_(sock,lo,hi):
                            g1=nt.nodes.new('ShaderNodeMath'); g1.operation='GREATER_THAN'; g1.inputs[1].default_value=lo; nt.links.new(sock,g1.inputs[0])
                            l1=nt.nodes.new('ShaderNodeMath'); l1.operation='LESS_THAN'; l1.inputs[1].default_value=hi; nt.links.new(sock,l1.inputs[0])
                            m1=nt.nodes.new('ShaderNodeMath'); m1.operation='MULTIPLY'; nt.links.new(g1.outputs[0],m1.inputs[0]); nt.links.new(l1.outputs[0],m1.inputs[1]); return m1.outputs[0]
                        acc=None
                        for r_ in os.environ['WC_RECTS'].split(';'):
                            u0,u1,v0,v1=(float(x) for x in r_.split(','))
                            m2=nt.nodes.new('ShaderNodeMath'); m2.operation='MULTIPLY'; nt.links.new(rng_(sep.outputs[0],u0,u1),m2.inputs[0]); nt.links.new(rng_(sep.outputs[1],v0,v1),m2.inputs[1])
                            if acc is None: acc=m2.outputs[0]
                            else:
                                mx_=nt.nodes.new('ShaderNodeMath'); mx_.operation='MAXIMUM'; nt.links.new(acc,mx_.inputs[0]); nt.links.new(m2.outputs[0],mx_.inputs[1]); acc=mx_.outputs[0]
                    cmp=type('X',(),{'outputs':[acc]})()
                    # colour: R = wall mask, G = fract(x/16), B = fract(y/16) -> plane id by depth
                    geo=nt.nodes.new('ShaderNodeNewGeometry'); sp=nt.nodes.new('ShaderNodeSeparateXYZ'); nt.links.new(geo.outputs['Position'],sp.inputs[0])
                    def fr(sock):
                        a=nt.nodes.new('ShaderNodeMath'); a.operation='MULTIPLY'; a.inputs[1].default_value=1/16; nt.links.new(sock,a.inputs[0])
                        b2=nt.nodes.new('ShaderNodeMath'); b2.operation='ADD'; b2.inputs[1].default_value=8.0; nt.links.new(a.outputs[0],b2.inputs[0])
                        c2=nt.nodes.new('ShaderNodeMath'); c2.operation='FRACT'; nt.links.new(b2.outputs[0],c2.inputs[0]); return c2.outputs[0]
                    cc=nt.nodes.new('ShaderNodeCombineXYZ'); nt.links.new(cmp.outputs[0],cc.inputs[0]); nt.links.new(fr(sp.outputs[0]),cc.inputs[1]); nt.links.new(fr(sp.outputs[1]),cc.inputs[2])
                    em=nt.nodes.new('ShaderNodeEmission'); nt.links.new(cc.outputs[0],em.inputs[0])
                    out=[n for n in nt.nodes if n.type=='OUTPUT_MATERIAL'][0]; nt.links.new(em.outputs[0],out.inputs[0])
                if os.environ.get('DIAG_NONORMAL'):
                    ni=bsdf.inputs['Normal']
                    for l in list(ni.links): nt.links.remove(l)
                if os.environ.get('DIAG_NOTEX') and src:
                    for l in list(mix.inputs[6].links): nt.links.remove(l)
                    mix.inputs[6].default_value=(0.8,0.8,0.8,1)
                # emissive off for day renders
                if 'Emission Strength' in bsdf.inputs: bsdf.inputs['Emission Strength'].default_value=0.0
    return [o for o in new if o.type=='MESH'][0]
def figure(x,y,z=0.0):
    bpy.ops.mesh.primitive_cylinder_add(radius=0.2,depth=1.45,location=(x,y,z+0.725))
    b=bpy.context.object
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.14,location=(x,y,z+1.66))
    h=bpy.context.object
    m=bpy.data.materials.new('fig'); m.use_nodes=True; m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(0.8,0.1,0.05,1)
    for o in (b,h): o.data.materials.append(m)
def lights():
    bpy.ops.object.light_add(type='SUN',rotation=(math.radians(50),0,math.radians(-35)))
    s=bpy.context.object; s.data.energy=3.2; s.data.angle=math.radians(3)
def ground(cx,w,d):
    bpy.ops.mesh.primitive_plane_add(size=1,location=(cx,0,-0.001)); g=bpy.context.object; g.scale=(w,d,1)
    m=bpy.data.materials.new('g'); m.use_nodes=True; m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(0.42,0.42,0.40,1); g.data.materials.append(m)
def bounds(o):
    pts=[o.matrix_world@Vector(c) for c in o.bound_box]
    return [min(p[i] for p in pts) for i in range(3)],[max(p[i] for p in pts) for i in range(3)]
def cam(loc,rot,scale,res):
    bpy.ops.object.camera_add(location=loc,rotation=rot); c=bpy.context.object
    c.data.type='ORTHO'; c.data.ortho_scale=scale; bpy.context.scene.camera=c
    bpy.context.scene.render.resolution_x=res[0]; bpy.context.scene.render.resolution_y=res[1]
setup()
for D in DIRS:
    name=os.path.basename(D.rstrip('/'))
    near=glob.glob(D+'/*_near.glb')[0]; mid=near.replace('_near','_mid'); far=near.replace('_near','_far')
    roof=('_roof_' in name) or name.endswith('_roof')
    # ---- elevations
    clear(); lights()
    o=imp(near); mn,mx=bounds(o); size=max(mx[0]-mn[0],mx[1]-mn[1]); H=mx[2]
    gap=size+2.5
    zmid=0.5*(mn[2]+mx[2]); zspan=max(mx[2]-mn[2],0.8)
    objs=[o]
    for i in range(3):
        c=o.copy(); bpy.context.collection.objects.link(c); objs.append(c)
    for i,(ob,rz) in enumerate(zip(objs,(0,-90,180,90))):
        ob.rotation_mode='XYZ'; ob.rotation_euler=(0,0,math.radians(rz)); ob.location=(i*gap,0,0)
        figure(i*gap-size/2-0.6,-size/2-0.6)
    ground(1.5*gap,4*gap+4,size+8)
    W=4*gap
    if roof:
        Hs=max(zspan+3.0, 4.0)
        res=(2400,int(2400*Hs/W)+40)
        cam((1.5*gap,-60,zmid),(math.radians(90),0,0),W,res)
    else:
        Hs=max(H+1.5,6)
        res=(2400,int(2400*Hs/W)+40)
        cam((1.5*gap,-60,Hs/2-0.3),(math.radians(90),0,0),W,res)
    bpy.context.scene.render.filepath=f'{OUT}/{name}_elev.png'; bpy.ops.render.render(write_still=True)
    # ---- tiers 3/4
    clear(); lights()
    obs=[imp(p) for p in (near,mid,far)]
    for i,ob in enumerate(obs):
        ob.rotation_mode='XYZ'; ob.rotation_euler=(0,0,math.radians(-35)); ob.location=(i*gap,0,0)
    ground(gap,3*gap+6,size+12)
    W3=3*gap
    if roof:
        ang=math.radians(40)
        # look at the deck mid-height so a plate at y=10 or y=31 is in frame
        cam((gap,-70*math.cos(ang),zmid+70*math.sin(ang)),(math.radians(90)-ang,0,0),W3,
            (1800,max(720,int(1800*(zspan+size*math.sin(ang)+1.5)/W3)+40)))
        # figures on the deck, one per tier
        for i in range(3):
            figure(i*gap-size*0.28, size*0.28, mn[2])
    else:
        ang=math.radians(22)
        cam((gap,-60*math.cos(ang),60*math.sin(ang)+H*0.4),(math.radians(90)-ang,0,0),W3,(1800,int(1800*(H*1.1+size*0.6)/W3)+80))
    bpy.context.scene.render.filepath=f'{OUT}/{name}_tiers.png'; bpy.ops.render.render(write_still=True)
    # ---- close-up of the near tier (baked detail) + 3/4 hero
    clear(); lights(); o=imp(near); mn,mx=bounds(o); ground(0,60,60)
    def pcam(eye,tgt,lens,res,fn):
        bpy.ops.object.camera_add(location=eye); c=bpy.context.object
        d=Vector(tgt)-Vector(eye); c.rotation_euler=d.to_track_quat('-Z','Y').to_euler(); c.data.lens=lens
        bpy.context.scene.camera=c; bpy.context.scene.render.resolution_x=res[0]; bpy.context.scene.render.resolution_y=res[1]
        bpy.context.scene.render.filepath=fn; bpy.ops.render.render(write_still=True)
    fy=mn[1]   # front wall side (glTF +Z -> blender -Y)
    dx=float(os.environ.get('CLOSE_X','0'))
    sz=max(mx[0]-mn[0],mx[1]-mn[1])
    if roof:
        # elevated 3/4 (~40°) looking down at the membrane, HVAC, hatch and drains
        el=math.radians(40); az=math.radians(40)
        tgt=((mn[0]+mx[0])/2,(mn[1]+mx[1])/2, mn[2]+0.55*(mx[2]-mn[2]))
        def eye(dist):
            return (tgt[0]+dist*math.sin(az)*math.cos(el),
                    tgt[1]-dist*math.cos(az)*math.cos(el),
                    tgt[2]+dist*math.sin(el))
        figure(mn[0]+0.45, mn[1]+0.55, mn[2])   # 1.8 m figure standing on the deck
        pcam(eye(max(6.0,sz*0.85)), tgt, 32, (1600,1100), f'{OUT}/{name}_closeup.png')
        pcam(eye(max(10.0,sz*1.85)), tgt, 35, (1600,1100), f'{OUT}/{name}_hero.png')
    else:
        pcam((dx-3.2,fy-4.2,1.75),(dx,fy+0.4,1.9),30,(1600,1100),f'{OUT}/{name}_closeup.png')
        pcam((mn[0]-sz*0.55,fy-sz*1.15,1.7+sz*0.28),((mn[0]+mx[0])/2,(mn[1]+mx[1])/2,mx[2]*0.38),35,(1600,1100),f'{OUT}/{name}_hero.png')
