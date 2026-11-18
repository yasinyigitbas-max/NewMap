"""blender -b -P run.py -- <batch> [only_name]
Indoor props (page I): near + col only. Do not add mid or far keys to PROPS.
Page I is streamed with interiors and is not part of the 8 MB street props cap.
"""
import bpy, sys, os, json, math, importlib, time
sys.path.insert(0,os.path.dirname(__file__))
import pg; importlib.reload(pg)
from mathutils import Vector, Matrix
argv=sys.argv[sys.argv.index('--')+1:]; batch=argv[0]; only=argv[1:] if len(argv)>1 else None
mod=importlib.import_module('b_'+batch)
K=pg.K
BUDGET={'tiny':300,'small':600,'medium':1200,'large':2500,'fence':60,'chainlink':4,'hedge':200,'shrub':500,'palm':1500,'tree':2500,'yardtree':2000}
DENS=128
MIDB={'medium':0.30,'large':0.30,'palm':500,'tree':800,'yardtree':600}
def setup_render():
    sc=bpy.context.scene; sc.render.engine='CYCLES'; sc.cycles.device='CPU'; sc.cycles.samples=24; sc.cycles.use_denoising=True
    sc.cycles.max_bounces=4; sc.render.film_transparent=False; sc.view_settings.view_transform='AgX'; sc.view_settings.look='None'
    sc.render.threads_mode='FIXED'; sc.render.threads=2
    w=bpy.data.worlds.get('W') or bpy.data.worlds.new('W'); sc.world=w; w.use_nodes=True
    bg=w.node_tree.nodes['Background']; bg.inputs[0].default_value=(0.62,0.70,0.80,1); bg.inputs[1].default_value=0.9
def figure():
    import bmesh
    bm=bmesh.new()
    for (r,z0,z1,x) in [(0.07,0,0.85,-0.1),(0.07,0,0.85,0.1),(0.19,0.85,1.5,0),(0.05,0.85,1.45,-0.26),(0.05,0.85,1.45,0.26),(0.06,1.5,1.58,0)]:
        bmesh.ops.create_cone(bm,cap_ends=True,segments=10,radius1=r,radius2=r,depth=z1-z0,matrix=Matrix.Translation((x,0,(z0+z1)/2)))
    bmesh.ops.create_uvsphere(bm,u_segments=12,v_segments=8,radius=0.11,matrix=Matrix.Translation((0,0,1.69)))
    me=bpy.data.meshes.new('fig'); bm.to_mesh(me); ob=bpy.data.objects.new('fig',me); bpy.context.scene.collection.objects.link(ob)
    m=bpy.data.materials.get('figm') or bpy.data.materials.new('figm'); m.diffuse_color=(0.5,0.5,0.55,1); m.use_nodes=True
    m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(0.35,0.37,0.42,1); me.materials.append(m); return ob

def render_preview(objs_rows, out, label):
    """objs_rows: list of (obj, caption) placed left->right"""
    sc=bpy.context.scene
    x=0.0; placed=[]
    fig=figure(); objs_rows=[(fig,'1.8 m')]+objs_rows
    gap=0.35; maxh=0
    for ob,cap in objs_rows:
        bb=[ob.matrix_world@Vector(c) for c in ob.bound_box]
        mnx=min(v.x for v in bb); mxx=max(v.x for v in bb); w=mxx-mnx; h=max(v.z for v in bb)
        ob.location.x+= x-mnx; x+=w+gap; maxh=max(maxh,h)
    total=x-gap
    # ground
    bpy.ops.mesh.primitive_plane_add(size=1,location=(total/2,0,0)); g=bpy.context.active_object; g.scale=(total+4,30,1)
    gm=bpy.data.materials.get('gm') or bpy.data.materials.new('gm'); gm.use_nodes=True; gm.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(0.42,0.41,0.38,1); g.data.materials.append(gm)
    cam=bpy.data.cameras.new('c'); cam.type='ORTHO'; co=bpy.data.objects.new('c',cam); sc.collection.objects.link(co); sc.camera=co
    el=math.radians(12); asp=max(1.0,(total+0.6)/(maxh+0.6))
    cam.ortho_scale=max(total+0.6,(maxh+0.6)*asp)
    co.rotation_euler=(math.pi/2-el,0,0); co.location=(total/2,-40*math.cos(el),maxh/2+40*math.sin(el))
    sc.render.resolution_y=480; sc.render.resolution_x=int(min(3200,max(640,480*asp)))
    sun=bpy.data.lights.new('s','SUN'); sun.energy=3.2; sun.angle=0.15; so=bpy.data.objects.new('s',sun); sc.collection.objects.link(so); so.rotation_euler=(math.radians(50),0,math.radians(-35))
    sc.render.filepath=out; bpy.ops.render.render(write_still=True)
    for o in [g,co,so,fig]: bpy.data.objects.remove(o,do_unlink=True)

def snap_ground(ob,defn):
    """ground props: snap tiny ground penetrations (tilted leg ends, < 1.5 cm) to y=0"""
    if defn.get('mount','ground')!='ground': return
    for v in ob.data.vertices:
        if -0.015<v.co.z<0: v.co.z=0.0
def _sh(b,defn):
    """defn['shift']=(dx,dy): move every tier (and the high-poly) so the origin sits at the footprint centre"""
    if 'shift' not in defn: return
    dx,dy=defn['shift']
    for v in b.bm.verts: v.co.x+=dx; v.co.y+=dy
    b.col=[(c[0],(c[1][0]+dx,c[1][1]+dy,c[1][2]))+tuple(c[2:]) for c in b.col]
def cond_page(ci): return ['clean','worn','dirty'][ci]
def build(defn):
    t0=time.time(); name=defn['name']; cat=defn.get('cat','prop'); cls=defn['cls']
    conds=defn.get('conds',['clean','worn','dirty']); outdir=f"{K}/{defn.get('dir','props/'+batch)}"
    os.makedirs(outdir,exist_ok=True)
    rec={'file_base':f'{cat}_{name}','batch':batch,'class':cls,'budget':defn.get('budget',BUDGET[cls]),'conds':conds,'mount':defn.get('mount','ground'),'tiers':{}}
    pg.TRIM={k:(v[0],tuple(v[1]))+tuple(v[2:]) for k,v in defn.get('trim',{}).items()}; pg.FOCAL=[tuple(map(tuple,fb)) for fb in defn.get('focal',[])]
    import zlib; b=pg.B(seed=zlib.crc32(name.encode())%1000); b.trim_on=bool(pg.TRIM); defn['near'](b); _sh(b,defn)
    ob=pg.to_object(b,f'{cat}_{name}_near'); snap_ground(ob,defn); pg.store_uv(ob)
    pg.bake_ao(ob,ground=defn.get('mount','ground')!='wall_high',wall_y=defn.get('wall_y'))
    dims=ob.dimensions; bb=[Vector(c) for c in ob.bound_box]
    rec.update({'footprint_w':round(dims.x,3),'footprint_d':round(dims.y,3),'height':round(dims.z,3),
                'regions':sorted(set(b.keys))})
    rec['tiers']['near']=len(ob.data.polygons)
    _tr=pg.is_trim(ob.data)
    if any(_tr):
        ta={}
        for p in ob.data.polygons:
            if _tr[p.index]: nm=pg.TKEYS[_tr[p.index]-1]; ta[nm]=ta.get(nm,0)+p.area
        def _tpx(nm): r=pg.REG[nm+'.clean']; return r.get('tile_px',r['px'][2]-8)
        rec['trim']={nm:{'area_m2':round(a_,2),'px_per_m':round(_tpx(nm)/[v for v in pg.TRIM.values() if v[0]==nm][0][1][0],1)} for nm,a_ in ta.items()}
    pg.DZ=0.0
    if defn.get('mount','ground').startswith('wall'):
        mz=min(v.co.z for v in ob.data.vertices); pg.DZ=-mz; rec['mount_height']=round(mz,3)
    baked='high' in defn and not defn.get('no_bake')
    pg.PAGE=defn.get('page','') if (baked or defn.get('page')) else ''
    pg.MID_ON_PAGE=bool(defn.get('uv_from_near')) and bool(pg.PAGE)
    pg.SQUASH_LONG=float(defn.get('squash_long',0.0)); pg.SHARE_THIN=float(defn.get('share_thin',0.0))
    rec['atlas_page']='props_'+(pg.PAGE+'_' if pg.PAGE else '')+'*'
    pg.AO_ZONLY=bool(defn.get('ao_zonly'))
    pg.WX=defn.get('wx')
    if baked:
        area=pg.unique_area(ob); side=int(min(defn.get('max_side',256),max(64,math.ceil(math.sqrt(area*1.35)*defn.get('dens',DENS)/16)*16)))
        if not defn.get('hero'):   # bake-area budget: cap texel density at 128 px/m (SPEC floor for walls), hero props exempt
            side=int(min(side,max(64,math.ceil(math.sqrt(area*1.35)*PXM_CAP/16)*16)))
            side=min(side,int(os.environ.get('SIDE_CAP','4096')))
        if defn.get('side'): side=int(defn['side'])   # fixed slot size (page B layout is fixed; trims freed the space)
        _ex=pg._slots()['slots'].get(defn.get('bake_as',name))
        if _ex and side>_ex[0][2] and not defn.get('side') and not os.environ.get('ALLOW_GROW'): side=_ex[0][2]   # page is full: a rebake never grows an existing slot
        bn=defn.get('bake_as',name)
        while True:   # page full: step the slot down (16 px) until it fits, never below 48 px
            try: slots=pg.alloc_slot(bn,side); break
            except RuntimeError:
                if side<=48: raise
                side-=16; print('slot reduced',bn,side,flush=True)
        if defn.get('planar_uv'):
            pg.planar_uv_xy(ob, float(defn.get('planar_r',0.5)))
        else:
            pg.unique_uv_sym(ob,side)
        tiles_ok=all(os.path.exists(f'{pg.BAKE_DIR}/tiles/{bn}_{c}_col.png') for c in ['clean','worn','dirty'][:len(conds)]) and os.path.exists(f'{pg.BAKE_DIR}/tiles/{bn}_nor.png')
        rebake=os.environ.get('REBAKE','')
        need=(not tiles_ok) or ((rebake=='all' or name in rebake.split(',')) and bn not in DONE_BAKE)
        if not need:
            import struct,zlib as _z
            with open(f'{pg.BAKE_DIR}/tiles/{bn}_nor.png','rb') as fh: hd=fh.read(24)
            tside=struct.unpack('>I',hd[16:20])[0]
            if tside>side:   # downsample the existing bake instead of re-baking (same unique unwrap, normalised UVs)
                for c in [f'{cc}_col' for cc in ['clean','worn','dirty'][:len(conds)]]+['nor','orm']:
                    p=f'{pg.BAKE_DIR}/tiles/{bn}_{c}.png'
                    if os.path.exists(p):
                        im=bpy.data.images.load(p); im.scale(side,side); im.filepath_raw=p; im.file_format='PNG'; im.save(); bpy.data.images.remove(im)
                print('resampled',bn,tside,'->',side,flush=True); tside=side
            need=tside!=side
    if baked and not need:
        rec['high_tris']=man_old.get(name,{}).get('high_tris') or man.get(bn,{}).get('high_tris') or man_old.get(bn,{}).get('high_tris') or next((v.get('high_tris') for v in list(man.values())+list(man_old.values()) if v.get('regions',[''])[0]=='baked:'+bn and v.get('high_tris')),None); rec['bake_slot_px']=side; rec['bake_px_per_m']=round(side/math.sqrt(area*1.35),1)
        print('reusing baked tiles for',name,flush=True)
    if baked and need:
        bh=pg.B(seed=7); defn['high'](bh); _sh(bh,defn); hi=pg.to_object(bh,f'{name}_high')
        if defn.get('bevel',0.004):
            bv=hi.modifiers.new('bv','BEVEL'); bv.width=defn.get('bevel',0.004); bv.segments=2; bv.limit_method='ANGLE'; bv.angle_limit=math.radians(40); bv.harden_normals=False
            bpy.context.view_layer.objects.active=hi; bpy.ops.object.modifier_apply(modifier='bv')
        for p in hi.data.polygons: p.use_smooth=True
        if defn.get('hi_sharp_angle'):
            bpy.context.view_layer.objects.active=hi; hi.select_set(True)
            bpy.ops.object.shade_smooth_by_angle(angle=math.radians(float(defn['hi_sharp_angle'])))
        pg.store_uv(hi)
        rec['high_tris']=len(hi.data.polygons); rec['bake_slot_px']=side; rec['bake_px_per_m']=round(side/math.sqrt(area*1.35),1)
        os.environ['BAKE_CAGE']=str(defn.get('cage',_CAGE0)); os.environ['BAKE_RAY']=str(defn.get('ray',_RAY0))   # per-prop cage (offset parts need a deeper cage)
        DONE_BAKE.add(bn); pg.bake_prop(bn,ob,hi,bh.keys,side,len(conds),ground=defn.get('mount','ground')=='ground',wall_y=defn.get('wall_y'),wear=defn.get('wear',1.0))
        bpy.data.objects.remove(hi,do_unlink=True)
        if defn.get('grade'):   # colour grade of the baked tile (e.g. weathered cedar from a darker wood photo region)
            import subprocess as _sp; g=defn['grade']
            for c in ['clean','worn','dirty'][:len(conds)]:
                _sp.run(['python3',os.path.dirname(__file__)+'/grade_tile.py',f'{pg.BAKE_DIR}/tiles/{bn}_{c}_col.png']+[str(v) for v in g.get('gain',(1,1,1))]+[str(g.get('lift',0.0))],check=True)
    if baked:
        import subprocess; subprocess.run(['python3',os.path.dirname(__file__)+'/props_compose.py']+([pg.PAGE] if pg.PAGE else []),check=True)
        for im in bpy.data.images:
            if im.filepath and 'atlases/props_' in im.filepath: im.reload()
        _ao=pg.AOS[ob.name]; _tl=set(li for p in ob.data.polygons if _tr[p.index] for li in p.loop_indices)
        pg.AOS[ob.name]=[_ao[i] if i in _tl else 1.0 for i in range(len(ob.data.loops))]   # trim faces keep the vertex AO (no baked AO there)
        if defn.get('trim_ao'):   # waterfront: vertex AO on big tiling cells smears a local contact shadow over the whole
            # cell (ramps + seams between neighbouring cells). Weld coincident corners and floor big cells.
            _ta=defn['trim_ao']; _me=ob.data; _A=pg.AOS[ob.name]; _grp={}
            for _p in _me.polygons:
                if not _tr[_p.index]: continue
                _big=max((_me.vertices[_p.vertices[i]].co-_me.vertices[_p.vertices[i-1]].co).length for i in range(len(_p.vertices)))>_ta.get('big',0.4)
                for _li in _p.loop_indices:
                    _v=_me.vertices[_me.loops[_li].vertex_index].co
                    _k=(round(_v.x,3),round(_v.y,3),round(_v.z,3),round(_p.normal.x,1),round(_p.normal.y,1),round(_p.normal.z,1))
                    _grp.setdefault(_k,[]).append((_li,_big))
            for _k,_L in _grp.items():
                _m=sum(_A[li] for li,_ in _L)/len(_L)
                _fl=_ta.get('floor_big',0.88) if any(b for _,b in _L) else _ta.get('floor',0.6)
                for li,_ in _L: _A[li]=max(_m,_fl)
        rec['regions']=['baked:'+bn]+(['vertex_tint'] if defn.get('tint') else [])
        ob.data.materials.clear()
    if defn.get('region_high'):   # shared region baked from its own high-poly model (chain_weave.py): record it for this prop
        _rh=json.load(open(pg.BAKE_DIR+'/region_high.json')).get(defn['region_high'])
        rec['region_high']={defn['region_high']:_rh}
        if not rec.get('high_tris'): rec['high_tris']=_rh
    prev=[]
    for ci,cond in enumerate(conds):
        ob.data.materials.clear(); ob.data.materials.append(pg.preview_mat('near',defn.get('alpha',False),cond_page(ci)))
        if baked:
            pg.slot_uv(ob,slots[0]); pg.trim_uv(ob,cond_page(ci))
        elif pg.TRIM:
            pg.trim_uv(ob,cond_page(ci))
        else:
            pg.apply_uv(ob,b.keys,['clean','worn','dirty'][ci])
        pg.cond_colors(ob,ci,(not baked) and defn.get('mount','ground')=='ground',defn.get('tint'),b.keys,
                       gmask=(_tl if baked and defn.get('mount','ground')=='ground' else None),ttint=defn.get('trim_tint'))
        pg.export_glb(ob,f'{outdir}/{cat}_{name}_{cond}_near.glb','near',defn.get('alpha',False),defn.get('double',False),cond_page(ci))
        cp=ob.copy(); cp.data=ob.data.copy(); bpy.context.scene.collection.objects.link(cp); prev.append((cp,cond))
    tiers=[]
    if 'mid' in defn:
        bm_=pg.B(seed=3)
        if defn.get('trim_mid') and pg.TRIM:   # mid tier on trims too (coarser period); only regions on the mid tier's own page
            mp=pg.PAGE if (pg.MID_ON_PAGE or not baked) else ''
            if all(pg.REG[v[0]+'.clean'].get('page','')==mp for v in pg.TRIM.values()): bm_.trim_on=True; bm_.trim_scale=float(defn['trim_mid'])
        _F=pg.FOCAL; pg.FOCAL=[]; defn['mid'](bm_); pg.FOCAL=_F; _sh(bm_,defn); mo=pg.to_object(bm_,f'{cat}_{name}_mid'); snap_ground(mo,defn); pg.store_uv(mo); pg.bake_ao(mo,wall_y=defn.get('wall_y'))
        rec['tiers']['mid']=len(mo.data.polygons)
        for ci,cond in enumerate(conds):
            mo.data.materials.clear(); mo.data.materials.append(pg.preview_mat('mid',defn.get('alpha',False),cond_page(ci))); pg.apply_uv(mo,bm_.keys,['clean','worn','dirty'][ci]); (pg.transfer_uv(ob,mo,mode=('vertex' if defn.get('uv_from_near')=='vertex' else 'face')) if defn.get('uv_from_near') else None); pg.cond_colors(mo,ci,defn.get('mount','ground')=='ground',defn.get('tint'),bm_.keys,ttint=defn.get('trim_tint')); pg.export_glb(mo,f'{outdir}/{cat}_{name}_{cond}_mid.glb','mid',defn.get('alpha',False),double=defn.get('double',False),cond=cond_page(ci))
            if ci==0: c2=mo.copy(); c2.data=mo.data.copy(); bpy.context.scene.collection.objects.link(c2); tiers.append((c2,'mid'))
        bpy.data.objects.remove(mo,do_unlink=True)
    if 'far' in defn:
        if defn.get('far_region'): pg.MID_ON_PAGE=False   # far keeps page-A regions
        bf=pg.B(seed=4); defn['far'](bf); _sh(bf,defn); fo=pg.to_object(bf,f'{cat}_{name}_far'); snap_ground(fo,defn); pg.store_uv(fo)
        rec['tiers']['far']=len(fo.data.polygons)
        ca=fo.data.color_attributes.new('Col','BYTE_COLOR','CORNER')
        for d in ca.data: d.color=(1,1,1,1)
        if defn.get('tint'):
            rk=fo.data.attributes['reg'].data
            for p in fo.data.polygons:
                kk=bf.keys[rk[p.index].value]
                if kk in defn['tint']:
                    for li in p.loop_indices: ca.data[li].color=tuple(defn['tint'][kk])+(1.0,)
        for ci,cond in enumerate(conds):
            fo.data.materials.clear(); fo.data.materials.append(pg.preview_mat('mid',defn.get('alpha',False),cond_page(ci))); pg.apply_uv(fo,bf.keys,['clean','worn','dirty'][ci]); (pg.transfer_uv(ob,fo,mode=('vertex' if defn.get('uv_from_near')=='vertex' else 'face')) if (defn.get('uv_from_near') and not defn.get('far_region') and not defn.get('far_flat')) else None); pg.export_glb(fo,f'{outdir}/{cat}_{name}_{cond}_far.glb','far',defn.get('alpha',False),double=defn.get('double_far',defn.get('double',False)),cond=cond_page(ci))
            if ci==0: c3=fo.copy(); c3.data=fo.data.copy(); bpy.context.scene.collection.objects.link(c3); tiers.append((c3,'far'))
        bpy.data.objects.remove(fo,do_unlink=True)
    if b.col: pg.export_col(b,f'{outdir}/{cat}_{name}_col.glb'); rec['col']=len(b.col)
    bpy.data.objects.remove(ob,do_unlink=True)
    # preview: clean four sides, then worn/dirty at 3/4, then tiers
    rows=[]
    c0=prev[0][0]
    for k,ang in enumerate((0,90,180,270)):
        o=c0 if k==0 else c0.copy()
        if k: bpy.context.scene.collection.objects.link(o)
        o.rotation_euler.z=math.radians(ang); bpy.context.view_layer.update(); rows.append((o,f'{ang}'))
    for o,cond in prev[1:]: o.rotation_euler.z=math.radians(30); rows.append((o,cond))
    for o,t in tiers: rows.append((o,t))
    bpy.context.view_layer.update()
    pdir=f'{K}/previews/{defn.get("pdir","props_"+batch)}'; os.makedirs(pdir,exist_ok=True)
    render_preview(rows,f'{pdir}/{cat}_{name}.png',name)
    for o,_ in rows: 
        if o.name in bpy.data.objects: bpy.data.objects.remove(o,do_unlink=True)
    for me in list(bpy.data.meshes):
        if me.users==0: bpy.data.meshes.remove(me)
    rec['secs']=round(time.time()-t0,1)
    print('BUILT',name,rec['tiers'],'budget',rec['budget'],rec['secs'],'s',flush=True)
    return rec

pg.clear_scene(); setup_render()
man_p=f'{K}/props/manifest_{batch}.json'
man=json.load(open(man_p)) if os.path.exists(man_p) else {}
man_old=dict(man)
PXM_CAP=float(os.environ.get('PXM_CAP','128'))
_CAGE0=os.environ.get('BAKE_CAGE','0.015'); _RAY0=os.environ.get('BAKE_RAY','0.06')
DONE_BAKE=set()
for d in mod.PROPS:
    if only and d['name'] not in only: continue
    try: man[d['name']]=build(d)
    except Exception as e:
        import traceback; traceback.print_exc(); print('FAILED',d['name'],flush=True)
    json.dump(man,open(man_p,'w'),indent=1)
print('DONE',batch)
