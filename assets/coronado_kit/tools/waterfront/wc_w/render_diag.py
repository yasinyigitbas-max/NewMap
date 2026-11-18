# blender -b -P render_diag.py -- <out.png> <near.glb> <mode: hero|wall_left|wall_front|graze_left|graze_front> [res]
import bpy, sys, os, math
from mathutils import Vector
src=open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'render_blender.py')).read()
argv=sys.argv[sys.argv.index('--')+1:]
OUTF,NEAR,MODE=argv[0],argv[1],argv[2]
sys.argv=sys.argv[:sys.argv.index('--')+1]+['/tmp','/nonexist']
exec(src.split('for D in DIRS:')[0])
clear()
if MODE.startswith('graze'):
    # grazing light: sun nearly parallel to the wall, no sky fill -> reveals shading blotches
    w=bpy.context.scene.world; w.node_tree.nodes['Background'].inputs[1].default_value=0.0
    bpy.context.scene.cycles.max_bounces=0   # direct sun only: no bounce light that differs between full and flat renders
    side=MODE.split('_')[1]
    d=Vector({'left':(0.16,0.95,-0.25),'front':(0.95,0.16,-0.25),'right':(-0.16,0.95,-0.25),'back':(0.95,-0.16,-0.25)}[side])
    if os.environ.get('DIAG_FLIP'):   # second grazing angle: sun from the other end of the wall (walls shaded by a porch/wing at the first angle)
        if side in ('front','back'): d.x=-d.x
        else: d.y=-d.y
    d=d.normalized()
    bpy.ops.object.light_add(type='SUN'); L=bpy.context.object
    L.rotation_euler=d.to_track_quat('-Z','Y').to_euler(); L.data.energy=5.0; L.data.angle=math.radians(1)
else:
    lights()
o=imp(NEAR); mn,mx=bounds(o)
if os.environ.get('DIAG_NOSHADOW'):   # staging: no cast shadows, so full/flat isolates normal map + vertex AO only
    for ob_ in bpy.context.scene.objects:
        if ob_.type=='MESH': ob_.visible_shadow=False
if not os.environ.get('DIAG_MASK'): ground(0,80,80)
else:
    bpy.context.scene.world.node_tree.nodes['Background'].inputs[1].default_value=0.0
    bpy.context.scene.cycles.samples=4
def pcam(eye,tgt,lens,res,fn,ortho=None):
    bpy.ops.object.camera_add(location=eye); c=bpy.context.object
    d=Vector(tgt)-Vector(eye); c.rotation_euler=d.to_track_quat('-Z','Y').to_euler(); c.data.lens=lens
    if ortho: c.data.type='ORTHO'; c.data.ortho_scale=ortho
    k=float(os.environ.get('DIAG_RES','1')); res=(int(res[0]*k),int(res[1]*k))
    if os.environ.get('DIAG_SAMPLES'): bpy.context.scene.cycles.samples=int(os.environ['DIAG_SAMPLES'])
    bpy.context.scene.camera=c; bpy.context.scene.render.resolution_x=res[0]; bpy.context.scene.render.resolution_y=res[1]
    bpy.context.scene.render.filepath=fn; bpy.ops.render.render(write_still=True)
cx=(mn[0]+mx[0])/2; cy=(mn[1]+mx[1])/2; sz=max(mx[0]-mn[0],mx[1]-mn[1])
if MODE=='hero':
    pcam((mn[0]-sz*0.55,mn[1]-sz*1.15,1.7+sz*0.28),(cx,cy,mx[2]*0.38),35,(1600,1100),OUTF)
elif MODE=='cam':   # explicit close-up camera: DIAG_EYE / DIAG_TGT = 'x,y,z' in blender coords, DIAG_LENS mm
    pcam(tuple(float(v) for v in os.environ['DIAG_EYE'].split(',')),tuple(float(v) for v in os.environ['DIAG_TGT'].split(',')),float(os.environ.get('DIAG_LENS','28')),(1600,1100),OUTF)
elif MODE=='wallclose':
    pcam((mn[0]+2.6,mn[1]-3.6,1.6),(mn[0]+1.6,mn[1],1.7),30,(1600,1100),OUTF)
elif MODE=='gableclose':
    pcam((mn[0]-4.5,cy-2.5,2.2),(mn[0],cy,2.6),30,(1600,1100),OUTF)
elif MODE in ('wall_front','graze_front'):
    pcam((cx,mn[1]-30,mx[2]*0.4),(cx,mn[1],mx[2]*0.4),50,(1600,900),OUTF,ortho=max((mx[0]-mn[0])+1,float(os.environ.get('DIAG_MIN_ORTHO','0'))))
elif MODE in ('wall_left','graze_left'):
    pcam((mn[0]-30,cy,mx[2]*0.45),(mn[0],cy,mx[2]*0.45),50,(1600,900),OUTF,ortho=max((mx[1]-mn[1])+1,float(os.environ.get('DIAG_MIN_ORTHO','0'))))
elif MODE in ('wall_right','graze_right'):
    pcam((mx[0]+30,cy,mx[2]*0.45),(mx[0],cy,mx[2]*0.45),50,(1600,900),OUTF,ortho=max((mx[1]-mn[1])+1,float(os.environ.get('DIAG_MIN_ORTHO','0'))))
elif MODE in ('wall_back','graze_back'):
    pcam((cx,mx[1]+30,mx[2]*0.4),(cx,mx[1],mx[2]*0.4),50,(1600,900),OUTF,ortho=max((mx[0]-mn[0])+1,float(os.environ.get('DIAG_MIN_ORTHO','0'))))
if os.environ.get('RES_SCALE'): pass
