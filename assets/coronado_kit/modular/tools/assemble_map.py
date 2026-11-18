"""Merged snap-in layouts for the 1 km kit map (MAP_NEEDS_16nov.md item 1).
usage: assemble_map.py houses|shops|urban [name ...]
Writes modular/examples_map/<name>/layout.json and bakes it with merge_assembly (near/mid merged, far = closed outline hull
with the openings of the placed pieces baked on the far atlas, col = outline boxes). No Blender.
Each layout uses its own temp dir so it never collides with another job's merge."""
import sys, os, json, shutil
import numpy as np
HERE=os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0,HERE)
GROUP=sys.argv[1]
os.environ['KIT_ATLAS']={'houses':'house','shops':'city','urban':'city','roofed':'city'}[GROUP]
from mod_core import KIT
sys.path.insert(0,KIT+'/tools')
import merge_assembly as MA
OUT=KIT+'/modular/examples_map'

GLZ=('shopdoor','storefront','french','slider','glass','civic_win')
DOORK=('door','door_craftsman','door_spanish','door_modern','apt_door','garage','garage_double','rollup')
def far_ops(ops,gap=0.5):
    """openings for the punched far bake (a LOD of the mid openings):
    - a shop door and its storefront closer than 0.5 m become one glazed band (the 0.45 m pier is under a pixel at 220 m)
    - garage doors are white panels on near/mid, so they are painted light (tag 'door' -> F_trim_white), not dark"""
    out={}
    for sd,L in ops.items():
        L=sorted([dict(o) for o in L],key=lambda o:o['c']-o['w']/2); M=[]
        for o in L:
            if M:
                p=M[-1]; pe=p['c']+p['w']/2; os_=o['c']-o['w']/2
                if os_-pe<gap and min(p['t1'],o['t1'])-max(p['t0'],o['t0'])>0.5 and (p['k'] in GLZ or o['k'] in GLZ or (p['k'] not in DOORK and o['k'] not in DOORK)):
                    a=min(p['c']-p['w']/2,os_); b=max(pe,o['c']+o['w']/2)
                    M[-1]=dict(k='storefront' if (p['k'] in GLZ or o['k'] in GLZ) else p['k'],c=round((a+b)/2,3),w=round(b-a,3),t0=min(p['t0'],o['t0']),t1=max(p['t1'],o['t1'])); continue
            M.append(o)
        out[sd]=[dict(o,tag='door') if o.get('k') in ('garage','garage_double') else o for o in M]
    return out

def outline_building(name,ol,ops):
    """merge_assembly.outline_building, but the far front is PUNCHED from the placed pieces' real openings (blank wall
    strip + glass / door / dark holes, build._far_opening_faces) instead of a generic window stamp, and brick / tower
    rows use their own storey strips (F_c_brick_3, 3 m tile) so far matches mid in openings and colour."""
    from mod_core import FL,HW,SW,PAR,GF
    from build import Building
    W,D=ol['W'],ol['D']; ops=far_ops(ops,float(ol.get('far_gap',0.5)))
    if ol.get('far_front'): ops=dict(ops); ops['front']=[dict(o) for o in ol['far_front']]   # explicit far LOD of the front openings
    wall=ol['wall']; blank='F_'+wall[2:]+'_blank'
    if ol['kind']=='house':
        eq=Building(name,'mod',wall=wall,tint=tuple(ol['tint']),roof=ol['roof'],style='modular'); eq.floor=FL; eq.storeys=1; eq.budget=ol['budget'].replace('mod_','')
        fr=ops.get('front',[]); gar=[o for o in fr if o.get('tag')=='door' and o['k'].startswith('garage')]
        if gar and len(gar)==len(fr):
            # garage: the white doors fill the front, so far paints one white door band (F_trim_white) across the doors
            a=min(o['c']-o['w']/2 for o in gar); b=max(o['c']+o['w']/2 for o in gar)
            fops=dict(ops); fops['front']=[dict(k='garage',tag='door',c=round((a+b)/2,3),w=round(b-a,3),t0=0.0,t1=max(o['t1'] for o in gar))]
            kw=dict(openings=fops,far_facade={'front':blank},far_tile=6.0)
        else:
            # house: the 1-storey far stamp (1.0 m openings every 3.2 m) shifted so its openings land on the front's real
            # window / door centres (a punched front costs ~30 far tris; the 40 cap cannot hold it)
            cs=sorted(o['c'] for o in fr); u0=(cs[0]-1.3) if cs else 0.0
            kw=dict(openings=ops,far_facade={'front':'F_'+wall[2:]+'_1'},far_u0=round(u0,3))
        eq.add('block',x0=-W/2,x1=W/2,z0=-D/2,z1=D/2,W=HW,roof=ol.get('roof_shape','gable'),axis='x',pitch=ol.get('pitch',0.45),o=0.45,f=0.18,rake=0.3,downspouts=(),foundation=False,**kw)
    elif ol['kind']=='shop':
        eq=Building(name,'mod',wall=wall,tint=tuple(ol['tint']),roof='R_flat',style='modular'); eq.floor=0.0; eq.storeys=1; eq.budget=ol['budget']; eq.frontage=W
        eq.floor_lines=[GF]
        eq.add('block',x0=-W/2,x1=W/2,z0=-D/2,z1=D/2,W=SW,roof='flat',parapet=PAR,cap='T_white',gutters=False,openings={'front':ops.get('front',[])},foundation=False,
               far_facade={'front':blank,'back':blank,'left':blank,'right':blank},far_tile=6.0)
    else:
        fl=float(ol.get('floor',0.3)); st=float(ol.get('storey',3.0)); sty=int(ol.get('storeys',1))
        Ht=fl+sty*st
        eq=Building(name,'mod',wall=wall,tint=tuple(ol['tint']),roof='R_flat',style='modular')
        eq.floor=fl; eq.storeys=sty; eq.budget=ol['budget']; eq.floor_lines=[fl+st*i for i in range(1,sty+1)]
        if ol['budget']=='shop': eq.frontage=W
        kw=dict(openings=ops,sills=ol.get('sills',False),foundation=ol.get('foundation',True),
                gutters=False,parapet=float(ol.get('parapet',0.9)),cap='T_white',roof='flat')
        if ol.get('far_facade'): kw['far_facade']=ol['far_facade']; kw['far_tile']=ol.get('far_tile',3.0)
        if ol.get('far_tint'): kw['far_tint']=tuple(ol['far_tint'])
        if ol.get('far_u0') is not None: kw['far_u0']=float(ol['far_u0'])
        if ol.get('far_punch'):
            kw['openings']={'front':ops.get('front',[])}; kw['far_facade']={'front':blank,'back':blank,'left':blank,'right':blank}
        fp=ol.get('far_paint')
        if fp: kw['far']=False
        eq.add('block',x0=-W/2,x1=W/2,z0=-D/2,z1=D/2,W=Ht,**kw)
        if fp: _far_painted_box(eq,ol,W,D,Ht+float(ol.get('parapet',0.9)),wall,blank,fp)
        # far pediments over merged civic fronts: (x0,x1,y0,y1,z0,z1) triangular prisms (8 tris each)
        import mod_phased  # noqa: registers Building._tri_prism
        PS={'t':'swatch','mat':'S_stucco','tint':tuple(ol['tint'])}
        for (x0,x1,y0,y1,z0,z1) in ol.get('far_pediments',()):
            eq.add('tri_prism',x0=x0,x1=x1,y0=y0,y1=y1,z0=z0,z1=z1,side=PS,bottom=PS,tiers=('far',),meta={'type':'trim'},name='far_pediment',overlay=True)
        # far rooftop plant (the mid RTU cabinets show over the parapet): dark boxes
        MT={'t':'trim','mat':'T_metal','tint':(0.2,0.2,0.21)}
        for (x0,x1,y0,y1,z0,z1) in ol.get('far_boxes',()):
            eq.add('box',x0=x0,x1=x1,y0=y0,y1=y1,z0=z0,z1=z1,top=MT,side=MT,bottom=MT,tiers=('far',),meta={'type':'rtu'},name='far_rtu',overlay=True)
    return eq

def _far_painted_box(eq,ol,W,D,Hf,wall,blank,fp):
    """painted far (stg rows): one closed 10-tri box to the parapet top. The front face maps onto its own painted slot of
    a far stretch strip (fp = {'key': strip, 'u': slot start m}); the slot is the mid front elevation baked by
    tools/paint_far_stg.py, so sign band, roll-up doors and coping read as on mid. Sides / back: the blank wall strip.
    Rooftop plant over the parapet (mid RTU cabinets): closed 8-tri wedges 1 cm above the deck (a coplanar bottom is culled
    and opens the hull), ridge along x so the front elevation shows
    a rectangle (ol['far_wedges'] = (x0,x1,y0,y1,z0,z1))."""
    from build import Building
    from city_parts import _nsolid
    from geom import box_planes, Solid
    if not hasattr(Building,'_rawsolids'):
        Building._rawsolids=lambda s,tier,sol,tiers=('near','mid','far'): list(sol) if tier in tiers else []
    x0,x1,z0,z1=-W/2,W/2,-D/2,D/2; tint=tuple(ol['tint'])
    def role(sd,key,u0,tn,tile=None):
        return {'t':'wall','mat':wall,'tint':tn,'bands':None,'openings':[],'side':sd,'far':key,'far_tint':tn,'far_u0':u0,'far_tile':tile}
    rl=[role('right',blank,0.0,tint,6.0),role('left',blank,0.0,tint,6.0),{'t':'roof','mat':'R_flat','tint':(1,1,1)},None,
        role('front',fp['key'],x0-float(fp['u']),(1,1,1)),role('back',blank,0.0,tint,6.0)]
    so=_nsolid(box_planes(x0,x1,0.0,Hf,z0,z1),rl,'farpaint')
    eq.add('rawsolids',sol=[(so,rl,{'type':'wall','box':(x0,x1,0.0,Hf,z0,z1)})],tiers=('far',))
    MT={'t':'roof','mat':'R_metal','tint':(0.2,0.2,0.21)}   # far: F_metal x dark tint (a 'trim' role maps to F_trim_white)
    sol=[]
    for (a,b,y0,y1,c,d) in ol.get('far_wedges',()):
        hd=(d-c)/2; H=y1-y0
        nf=np.array([0.0,hd,H]); nf/=np.linalg.norm(nf); nb=np.array([0.0,hd,-H]); nb/=np.linalg.norm(nb)
        pl=[((1.0,0.0,0.0),b),((-1.0,0.0,0.0),-a),((0.0,-1.0,0.0),-y0),(tuple(nf),float(nf@np.array([0,y0,d]))),(tuple(nb),float(nb@np.array([0,y0,c])))]
        r=[MT]*5; w=Solid(pl,r,'far_rtu'); w.nocut=True; w.overlay=True
        sol.append((w,r,{'type':'rtu'}))
    if sol: eq.add('rawsolids',sol=sol,tiers=('far',))

def cull_hidden(m,passes=3):
    """drop merged triangles that face into another piece: a ray from the centroid along the normal hits a back face first
    (e.g. a roof deck's end face flush against the inside of a parapet / side wall). Same test as validate.py's inward check,
    including its exemption for wall patches under thin applied details (<=0.12 m, parallel). These faces cannot be seen."""
    import numpy as np, validate as V
    for _ in range(passes):
        I=m['idx'].reshape(-1,3); P=m['pos'].astype(np.float64)
        V0,V1,V2=P[I[:,0]],P[I[:,1]],P[I[:,2]]
        cr=np.cross(V1-V0,V2-V0); fn=cr/np.maximum(np.linalg.norm(cr,axis=1,keepdims=True),1e-12); cen=(V0+V1+V2)/3
        t,hi=V.ray_first(cen+fn*1e-3,fn,V0,V1,V2)
        hit=hi>=0; d=np.zeros(len(I)); d[hit]=(fn[hi[hit]]*fn[hit]).sum(1)
        back=hit&(d>1e-3)&~((d>0.99)&(t<=0.12))
        if not back.any(): break
        m=dict(m); m['idx']=I[~back].reshape(-1)
    return m

def merge(path,d):
    """merge_assembly.merge_layout with a per-process temp dir (same folder depth as buildings/<cat>/<name>/)"""
    L=json.load(open(path)); MA._setup(L['group'])
    from geom import write_glb
    from export import export_building, BUDGET
    P=KIT+'/modular/pieces'; name=L['name']; tri={}
    for tier in ('near','mid'):
        m=cull_hidden(MA.merge_tier(P,L['group'],L['pieces'],tier)); write_glb(f'{d}/mod_{name}_{tier}.glb',m,tier,f'mod_{name}_{tier}'); tri[tier]=len(m['idx'])//3
    ol=L['outline']; eq=outline_building(name,ol,MA.world_openings(P,L['group'],L['pieces']))
    tmp=KIT+f'/_tmp_eqmap{os.getpid()}'
    try:
        st=export_building(eq,tmp,category_dir='eq')
        for t in ('far','col'): shutil.copy(f'{tmp}/eq/{name}/mod_{name}_{t}.glb',f'{d}/mod_{name}_{t}.glb')
    finally: shutil.rmtree(tmp,ignore_errors=True)
    tri['far']=st['far']['tris']
    bud=list(MA.MOD_BUDGET.get(ol['budget']) or BUDGET[ol['budget']])
    if ol['budget']=='shop': bud=[v*int(round(ol['W']/6.0)) for v in bud]
    if ol['budget']=='tower': nu=max(1.0,float(ol.get('storeys',10))/10.0); bud=[int(round(v*nu)) for v in bud]
    L.update(budget_class=ol['budget'],budget=bud,tris=tri,col_boxes=st['col_boxes'],far_from='snapped outline hull',
             merged={'near_mid':'pieces merged, 1 mesh/1 primitive/1 material','far_col':'outline hull + <=12 boxes'})
    json.dump(L,open(f'{d}/layout.json','w'),indent=1)
    return L

def put(name,g,items,outline):
    d=f'{OUT}/{name}'; os.makedirs(d,exist_ok=True)
    lay={'name':name,'group':g,'outline':outline,'pieces':items}
    json.dump(lay,open(f'{d}/layout.json','w'),indent=1)
    L=merge(f'{d}/layout.json',d); t,b=L['tris'],L['budget']
    over=[k for k,i in zip(('near','mid','far'),range(3)) if t[k]>b[i]]
    print(name,t,'budget',b,'OVER '+str(over) if over else 'ok',flush=True)

def designs_houses():
    sys.argv=[sys.argv[0],'houses']; import assemble as A
    from mod_pieces import CREAM,WHITE,BLUEG
    def H(name,W,sides,roof_tag,end_tag,**kw):
        g,items,eq,budget=A.house(name,W,7.5,sides,roof_tag,end_tag,**kw)
        if name.startswith('garage'): items=[i for i in items if 'chimney' not in i[0]]   # no chimney on a garage
        return name,g,[dict(piece=n,x=round(x,3),z=round(z,3),rot_y=th) for (n,x,z,th) in items],eq._outline
    yield H('house_w6_comp',6.0,{
        'front':['house_wall_3m_window_stucco','house_wall_3m_door_stucco'],
        'right':['house_wall_4p5m_window_small_stucco','house_wall_3m_window_stucco'],
        'back':['house_wall_3m_utility_stucco','house_wall_3m_window_stucco'],
        'left':['house_wall_3m_window_stucco','house_wall_4p5m_utility_stucco']},'comp','comp_stucco')
    yield H('house_w6_comp_siding',6.0,{
        'front':['house_wall_3m_window_pair_siding','house_wall_3m_door_siding'],
        'right':['house_wall_4p5m_window_small_siding','house_wall_3m_window_siding'],
        'back':['house_wall_3m_utility_siding','house_wall_3m_window_siding'],
        'left':['house_wall_3m_window_siding','house_wall_4p5m_utility_siding']},'comp','comp_siding',wall='W_siding',tint=BLUEG,corners=True)
    yield H('house_w6_clay',6.0,{
        'front':['house_wall_3m_window_pair_stucco_white','house_wall_3m_door_stucco_white_clayhood'],
        'right':['house_wall_4p5m_window_small_stucco_white','house_wall_3m_window_stucco_white'],
        'back':['house_wall_3m_utility_stucco_white','house_wall_3m_window_stucco_white'],
        'left':['house_wall_3m_window_stucco_white','house_wall_4p5m_utility_stucco_white']},'clay','clay_stucco_white',roofmat='R_clay',tint=WHITE)
    # detached garages from the snap-in pieces: vehicle doors on the front, a person door (utility wall) on a side.
    # They carry the snap-in house class (mod_house_small): the piece walls alone exceed the 300-tri garage class.
    yield H('garage_w6_stucco',6.0,{
        'front':['house_wall_3m_garage_stucco','house_wall_3m_garage_stucco'],
        'right':['house_wall_4p5m_window_small_stucco','house_wall_3m_door_stucco'],
        'back':['house_wall_3m_window_stucco','house_wall_3m_utility_stucco'],
        'left':['house_wall_3m_window_stucco','house_wall_4p5m_window_small_stucco']},'comp','comp_stucco')
    yield H('garage_w9_siding',9.0,{
        'front':['house_wall_3m_garage_siding','house_wall_3m_garage_siding','house_wall_3m_garage_siding'],
        'right':['house_wall_4p5m_window_small_siding','house_wall_3m_door_siding'],
        'back':['house_wall_4p5m_window_small_siding','house_wall_4p5m_utility_siding'],
        'left':['house_wall_3m_window_siding','house_wall_4p5m_window_small_siding']},'comp','comp_siding',wall='W_siding',tint=BLUEG,corners=True)
    yield H('garage_w9_clay',9.0,{
        'front':['house_wall_3m_garage_stucco_white','house_wall_3m_garage_stucco_white','house_wall_3m_garage_stucco_white'],
        'right':['house_wall_4p5m_window_small_stucco_white','house_wall_3m_door_stucco_white_clayhood'],
        'back':['house_wall_4p5m_window_small_stucco_white','house_wall_4p5m_utility_stucco_white'],
        'left':['house_wall_3m_window_stucco_white','house_wall_4p5m_window_small_stucco_white']},'clay','clay_stucco_white',roofmat='R_clay',tint=WHITE)

    # nice-to-have finishes: peach stucco + clay roof with the porch wall; pink stucco under a complete clay hip roof
    from mod_map_houses import PEACH, PINK
    yield H('house_w6_peach_porch',6.0,{
        'front':['house_wall_3m_window_stucco_peach','house_wall_3m_porch_stucco_peach_clay'],
        'right':['house_wall_4p5m_window_small_stucco_peach','house_wall_3m_window_stucco_peach'],
        'back':['house_wall_3m_utility_stucco_peach','house_wall_3m_window_stucco_peach'],
        'left':['house_wall_3m_window_stucco_peach','house_wall_4p5m_utility_stucco_peach']},'clay','clay_stucco_peach',roofmat='R_clay',tint=PEACH)
    n,g,items,ol=H('house_w9_pink_hip',9.0,{
        'front':['house_wall_3m_window_stucco_pink','house_wall_3m_door_stucco_pink_clayhood','house_wall_3m_window_pair_stucco_pink'],
        'right':['house_wall_4p5m_window_small_stucco_pink','house_wall_3m_window_stucco_pink'],
        'back':['house_wall_3m_utility_stucco_pink','house_wall_3m_window_stucco_pink','house_wall_3m_window_stucco_pink'],
        'left':['house_wall_3m_window_stucco_pink','house_wall_4p5m_utility_stucco_pink']},'clay','clay_stucco_pink',roofmat='R_clay',tint=PINK)
    items=[i for i in items if not i['piece'].startswith('house_roof_gable')]+[dict(piece='house_roof_hip_9x7p5_clay',x=0.0,z=0.0,rot_y=0)]
    ol=dict(ol,roof_shape='hip')
    yield n,g,items,ol

def designs_shops():
    sys.argv=[sys.argv[0],'shops']; import assemble as A
    def S(name,bays,**kw):
        g,items,eq,budget=A.shop(name,bays,**kw)
        return name,g,[dict(piece=n,x=round(x,3),z=round(z,3),rot_y=th) for (n,x,z,th) in items],eq._outline
    yield S('shop_row2_surf_cafe',['surf_black','cafe_red'])
    yield S('shop_row3',['bakery_navy','books_green','cafe_red'],tint=(0.97,0.90,0.78))
    yield S('shop_row4',['cafe_red','surf_black','books_green','bakery_navy'],tint=(0.95,0.86,0.74))

def designs_urban():
    import assemble_phased as AP
    from mod_phased import UFL, UST
    it=AP.item
    def brk(name,n):
        W,D,T=6.0*n,14.0,0.45; pcs=[]
        fr=['urb_brk_front_6m_3sty_walkup' if (n<3 and i==n//2) else 'urb_brk_front_6m_3sty' for i in range(n)]
        for i,p in enumerate(fr): pcs.append(it(p,-W/2+3.0+6.0*i,D/2-T/2,0))
        for i in range(n): pcs.append(it('urb_brk_back_6m_3sty',W/2-3.0-6.0*i,-D/2+0.15,180))
        pcs.append(it('urb_brk_side_14m_3sty',W/2-0.15,0.0,90)); pcs.append(it('urb_brk_side_14m_3sty',-W/2+0.15,0.0,270))
        # plant (RTU, hatch) on one bay; rows of 3+ get the quieter run deck on the other bays
        for i in range(n): pcs.append(it('urb_brk_roof_6x14_3sty' if (n<3 or i==n//2) else 'urb_brk_roof_6x14_3sty_run',-W/2+3.0+6.0*i,0.0,0))
        L=AP.layout(name,'block',W,D,3,'W_brick',AP.BRK,'apartment',pcs,parapet=1.0,sills=True,foundation=False,far_facade='F_c_brick_3',far_tile=3.0)
        return name,'urban',L['pieces'],L['outline']
    yield brk('brk3_row2',2)
    yield brk('brk3_row3',3)
    # corner rules demo: corner-entry bay on the street corner, 1 m corner piers centred 0.35 m inside both outer faces at the
    # two front corners (0.15 m proud of front and side, covering the slab ends), door-free backs either side of the service door
    W,D,T=12.0,14.0,0.45; pcs=[]
    for i,p in enumerate(['urb_brk_front_6m_3sty_walkup','urb_brk_front_6m_3sty_corner']): pcs.append(it(p,-W/2+3.0+6.0*i,D/2-T/2,0))
    for i,p in enumerate(['urb_brk_back_6m_3sty','urb_brk_back_6m_3sty_blank']): pcs.append(it(p,W/2-3.0-6.0*i,-D/2+0.15,180))
    pcs.append(it('urb_brk_side_14m_3sty',W/2-0.15,0.0,90)); pcs.append(it('urb_brk_side_14m_3sty',-W/2+0.15,0.0,270))
    for i in range(2): pcs.append(it('urb_brk_roof_6x14_3sty',-W/2+3.0+6.0*i,0.0,0))
    for sx in (-1,1): pcs.append(it('urb_brk_corner_pier_3sty',sx*(W/2-0.35),D/2-0.35,0))
    L=AP.layout('brk3_corner2','block',W,D,3,'W_brick',AP.BRK,'apartment',pcs,parapet=1.0,sills=True,foundation=False,far_facade='F_c_brick_3',far_tile=3.0)
    yield 'brk3_corner2','urban',L['pieces'],L['outline']
    W,D,T=8.0,20.0,0.45; pcs=[it('urb_twr_front_8m_10sty',0.0,D/2-T/2,0),it('urb_twr_back_8m_10sty',0.0,-D/2+0.15,180),it('urb_twr_roof_8x20',0.0,0.0,0),
        it('urb_twr_side_20m_10sty',W/2-0.15,0.0,90),it('urb_twr_side_20m_10sty',-W/2+0.15,0.0,270)]
    L=AP.layout('twr_bay1','tower',W,D,10,'W_stucco',AP.GREY,'tower',pcs,parapet=0.9,sills=False,foundation=True,far_facade='F_c_tower_3',far_tile=3.47)
    L['outline']['far_tint']=[0.44,0.44,0.43]   # 9 storey bands over 31.2 m: 10 x 3 m tiles x 4 sides would be 82 > 80
    yield 'twr_bay1','urban',L['pieces'],L['outline']
    # big box service row closed with its own side / back / roof pieces (5.4 m plate): docks + service door at the back
    def svb(name,n):
        W,D,T=6.0*n,12.0,0.45; pcs=[]
        for i in range(n): pcs.append(it('urb_svc_front_6m_bigbox',-W/2+3.0+6.0*i,D/2-T/2,0))
        backs=(['urb_svc_back_6m_bigbox_dock','urb_svc_back_6m_bigbox']+['urb_svc_back_6m_bigbox_blank']*n)[:n]
        for i,bk in enumerate(backs): pcs.append(it(bk,W/2-3.0-6.0*i,-D/2+0.15,180))
        pcs.append(it('urb_svc_side_12m_bigbox',W/2-0.15,0.0,90)); pcs.append(it('urb_svc_side_12m_bigbox',-W/2+0.15,0.0,270))
        for i in range(n): pcs.append(it('urb_svc_roof_6x12_bigbox',-W/2+3.0+6.0*i,0.0,0))
        L=AP.layout(name,'block',W,D,1,'W_stucco',AP.GREY,'shop',pcs,floor=0.0,storey=5.4,parapet=1.1,sills=False,foundation=False,far_facade='F_c_tower_3',far_tile=6.0)
        L['outline']['far_punch']=True; L['outline']['far_gap']=0.8; L['outline']['far_tint']=[0.80,0.77,0.74]   # the 0.7 m piers between entry bays are sub-pixel at far range: one glazed band
        return name,'urban',L['pieces'],L['outline']
    # merged civic example: window / entry / window bays under a moulded cornice and a pediment over the entry,
    # closed by the civic side (cornice returns), back and roof pieces
    W,D=18.0,12.0; pcs=[]
    for x,n in ((-6.0,'urb_civ_window_6m'),(0.0,'urb_civ_entry_6m'),(6.0,'urb_civ_window_6m')):
        pcs.append(it(n,x,D/2-(0.225 if 'entry' in n else 0.15),0))
    pcs.append(it('urb_civ_cornice_6m',-6.0,D/2+0.14,0,y=4.8)); pcs.append(it('urb_civ_cornice_6m',6.0,D/2+0.14,0,y=4.8))
    pcs.append(it('urb_civ_pediment_6m',0.0,D/2+0.24,0,y=4.8))
    for x,n in ((6.0,'urb_civ_back_6m_blank'),(0.0,'urb_civ_back_6m'),(-6.0,'urb_civ_back_6m_blank')): pcs.append(it(n,x,-D/2+0.15,180))
    pcs.append(it('urb_civ_trim_return_r',W/2,D/2,0)); pcs.append(it('urb_civ_trim_return_l',-W/2,D/2,0))
    pcs.append(it('urb_civ_side_12m_r',W/2-0.15,0.0,90)); pcs.append(it('urb_civ_side_12m_l',-W/2+0.15,0.0,270))
    for x in (-6.0,0.0,6.0): pcs.append(it('urb_civ_roof_6x12',x,0.0,0))
    L=AP.layout('civ_hall3','block',W,D,1,'W_stucco',AP.WHITE,'civic',pcs,floor=0.6,storey=4.2,parapet=0.44,sills=True,foundation=True)
    L['outline']['far_punch']=True
    # far LOD of the front: one glazed band per window bay (the pair is one column at 220 m) and one dark entry band
    L['outline']['far_front']=[dict(k='civic_win',c=-6.0,w=2.9,t0=1.5,t1=4.3),dict(k='glass',c=0.0,w=3.0,t0=0.7,t1=2.8,far_dark=True),dict(k='civic_win',c=6.0,w=2.9,t0=1.5,t1=4.3),
        dict(k='glass',c=0.0,w=18.0,t0=4.44,t1=4.60,far_dark=True)]   # + the shadow line under the cornice / architrave (a dark row on mid)
    L['outline']['far_pediments']=[(-2.9,2.9,5.25,6.30,D/2-0.30,D/2+0.24)]
    yield 'civ_hall3','urban',L['pieces'],L['outline']
    yield svb('svb_row2',2)
    yield svb('svb_row3',3)

def designs_roofed():
    """item 4: apartment / storage rows closed with the other job's roof decks (urb_apt_roof_6x12 = the 3-storey 9.3 m plate,
    urb_stg_roof_6x12 = the 4.2 m plate). Pieces are only read, never edited."""
    import assemble_phased as AP
    it=AP.item
    def apt(name,fronts,budget):
        n=len(fronts); W,D,T=6.0*n,12.0,0.45; pcs=[]
        for i,f in enumerate(fronts): pcs.append(it(f,-W/2+3.0+6.0*i,D/2-T/2,0))
        for i in range(n): pcs.append(it('urb_apt_back_6m',W/2-3.0-6.0*i,-D/2+0.15,180))
        pcs.append(it('urb_apt_side_12m',W/2-0.15,0.0,90)); pcs.append(it('urb_apt_side_12m',-W/2+0.15,0.0,270))
        for i in range(n): pcs.append(it('urb_apt_roof_6x12',-W/2+3.0+6.0*i,0.0,0))
        L=AP.layout(name,'block',W,D,3,'W_stucco',AP.WHITE,budget,pcs,parapet=0.8,sills=True,foundation=True,far_facade='F_c_apt_3',far_tile=3.0)   # the apt pieces' own far strip
        L['outline']['far_u0']=-(W/2-6.0)   # same stamp window as the 2-bay row (its entry bay sits at u=-6..0)
        return name,'urban',L['pieces'],L['outline']
    def stg(name,n):
        W,D,T=6.0*n,12.0,0.45; pcs=[]
        for i in range(n): pcs.append(it('urb_stg_front_6m',-W/2+3.0+6.0*i,D/2-T/2,0))
        for i in range(n): pcs.append(it('urb_stg_back_6m',W/2-3.0-6.0*i,-D/2+0.15,180))
        pcs.append(it('urb_stg_side_12m',W/2-0.15,0.0,90)); pcs.append(it('urb_stg_side_12m',-W/2+0.15,0.0,270))
        for i in range(n): pcs.append(it('urb_stg_roof_6x12',-W/2+3.0+6.0*i,0.0,0))
        L=AP.layout(name,'warehouse',W,D,1,'W_stucco',AP.GREY,'warehouse',pcs,floor=0.0,storey=4.2,parapet=0.6,sills=False,foundation=False,far_facade='F_c_tower_3',far_tile=6.0)
        # far: the punched front (doors only) read 1 opening row against the mid's 3-4 (rooftop plant over the parapet, sign
        # band, roll-up doors) and 3 bays of punched doors already filled the 40-tri cap. Painted far instead: the front maps onto
        # a slot of F_bb_1 (u 100-118 m, free in every far_color user) holding the baked mid front view of the 3-bay row
        # (tools/paint_far_stg.py; stg_row2 samples its first 12 m), plus one 8-tri wedge per roof bay for the RTU cabinet.
        L['outline']['far_paint']={'key':'F_bb_1','u':100.0}
        L['outline']['far_wedges']=[(-W/2+6.0*i+2.47,-W/2+6.0*i+3.75,4.81,5.09,-2.35,-2.05) for i in range(n)]
        return name,'urban',L['pieces'],L['outline']
    yield apt('apt3_row2',['urb_apt_front_6m_balcony','urb_apt_front_6m_open'],'apartment')
    yield apt('apt3_row3',['urb_apt_front_6m_open','urb_apt_front_6m_open','urb_apt_front_6m_open'],'apartment_large')
    yield stg('stg_row2',2)
    yield stg('stg_row3',3)

# the phase-B examples' doubled mod_mod_ prefix: see fix_mod_prefix.py (clean-named copies in examples_renamed/, geometry unchanged)

if __name__=='__main__':
    want=set(sys.argv[2:])
    gen={'houses':designs_houses,'shops':designs_shops,'urban':designs_urban,'roofed':designs_roofed}[GROUP]
    for name,g,items,ol in gen():
        if want and name not in want: continue
        put(name,g,items,ol)
