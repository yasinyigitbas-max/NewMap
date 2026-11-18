"""Starter piece catalogue. Every piece: front (exterior) = +Z, origin = bottom centre of its footprint.
House walls: exterior face at z=+T_H/2 after centring; shop fronts: exterior face at z=+T_S/2."""
import numpy as np
from mod_core import *

CREAM=(0.93,0.86,0.72); WHITE=(0.97,0.96,0.93); SAGE=(0.70,0.78,0.66); BLUEG=(0.68,0.76,0.82)
SH_GREEN=(0.25,0.32,0.30)
X=0; Y=1; Z=2

def win(k,c,w=1.0,h=1.5,sill=0.9,**kw):
    t0=FL+sill; return dict(k=k,c=c,w=w,t0=round(t0,3),t1=round(t0+h,3),**kw)

def wall_piece(name,w,ops,wall='W_stucco',tint=CREAM,budget=(220,70,8),cls='house_wall',extra=None,**bkw):
    b=Piece(name,cls,snap=None,drop=[(X,-w/2,-1),(X,w/2,1),(Z,-T_H,-1),(Y,HW,1)],budget=budget,wall=wall,tint=tint,roof='R_comp',style='modular')
    b.floor=FL
    b.add('block',x0=-w/2,x1=w/2,z0=-T_H,z1=0.0,W=HW,roof='flat',parapet=0.0,openings={'front':ops},gutters=False,
          shutter_tint=SH_GREEN,head_trim=('front',),sills=True,**bkw)
    if extra: extra(b)
    b.snap={'grid':GRID,'module':w,'type':'house_wall','ends':[[-w/2,0,T_H/2],[w/2,0,T_H/2]],'face_z':T_H/2,'plate_y':HW}
    return b

def house_wall_window(wall='W_stucco',tint=CREAM,tag='stucco'):
    return wall_piece(f'house_wall_3m_window_{tag}',3.0,[win('dh',0.0,shutters=True)],wall,tint)
def house_wall_window_pair(wall='W_stucco',tint=CREAM,tag='stucco'):
    return wall_piece(f'house_wall_3m_window_pair_{tag}',3.0,[win('casement',-0.65,w=0.9,h=1.4),win('casement',0.65,w=0.9,h=1.4)],wall,tint)
def house_wall_small(wall='W_stucco',tint=CREAM,tag='stucco'):
    return wall_piece(f'house_wall_1p5m_small_{tag}',1.5,[win('small',0.0,w=0.75,h=0.75,sill=1.6)],wall,tint,budget=(120,40,4))
def house_wall_utility(wall='W_stucco',tint=CREAM,tag='stucco'):
    # side/back utility wall: high bathroom window, crawl vent, hose bib, gas meter (never a blank wall)
    return wall_piece(f'house_wall_3m_utility_{tag}',3.0,[win('small',0.6,w=0.75,h=0.75,sill=1.6)],wall,tint,
                      crawl_vents=[('front',-0.6)],hose_bib=[('front',1.1)],meter=[('front',-1.0)])
def house_wall_45_window_small(wall='W_stucco',tint=CREAM,tag='stucco'):
    # 4.5 m side/back module: shuttered double-hung + a high small window (bath/kitchen)
    return wall_piece(f'house_wall_4p5m_window_small_{tag}',4.5,[win('dh',-0.85,shutters=True),win('small',1.35,w=0.75,h=0.75,sill=1.6)],wall,tint,budget=(240,72,8))
def house_wall_45_utility(wall='W_stucco',tint=CREAM,tag='stucco'):
    # 4.5 m utility module: framed casement, high small window, crawl vent, hose bib, gas meter
    return wall_piece(f'house_wall_4p5m_utility_{tag}',4.5,[win('casement',-1.1,w=0.9,h=1.4),win('small',1.0,w=0.75,h=0.75,sill=1.6)],wall,tint,budget=(240,72,8),
                      crawl_vents=[('front',0.0)],hose_bib=[('front',1.8)],meter=[('front',-0.1)])
def house_wall_door(wall='W_stucco',tint=CREAM,tag='stucco',hood='R_comp'):
    # hood='R_clay': clay-tile entry canopy with terracotta edges for clay-roof houses (name suffix _clayhood)
    def ex(b):
        b.add('stoop',side='front',c=0.0,wall=0.0,w=1.6,depth=1.1,rails='simple')   # iron handrail both sides of the steps (detail floor)
        b.add('hood',c=0.0,wall=0.0,y=FL+2.35,w=1.6,depth=0.9,pitch=0.3,brackets=False,roofmat=hood)   # cantilevered entry canopy
        b.add('entry',c=0.0,wall=0.0,door_top=FL+2.1,lamp_x=0.85,num_x=0.95,mailbox=False)
    b=wall_piece(f'house_wall_3m_door_{tag}'+('_clayhood' if hood=='R_clay' else ''),3.0,[dict(k='door',c=0.0,w=1.0,t0=FL,t1=FL+2.1)],wall,tint,extra=ex,budget=(320,100,8))
    b.no_door=False; return b
def house_wall_garage(wall='W_stucco',tint=CREAM,tag='stucco'):
    b=wall_piece(f'house_wall_3m_garage_{tag}',3.0,[dict(k='garage',c=0.0,w=2.4,t0=0.0,t1=2.2)],wall,tint,budget=(160,50,8))
    b.no_door=False; return b

HOUSE=[house_wall_window,house_wall_window_pair,house_wall_small,house_wall_utility,house_wall_45_window_small,house_wall_45_utility,house_wall_door,house_wall_garage]
def catalogue(group):
    out=[]
    if group=='houses':
        for f in HOUSE:
            out.append(('houses',f()))
            out.append(('houses',f('W_siding',BLUEG,'siding')))
            out.append(('houses',f('W_stucco',WHITE,'stucco_white')))
        # clay-tile entry canopy doors for clay-roof houses (cream and white stucco)
        out.append(('houses',house_wall_door(hood='R_clay')))
        out.append(('houses',house_wall_door('W_stucco',WHITE,'stucco_white',hood='R_clay')))
        out+=[('houses',house_trim_corner()),('houses',house_roof_chimney()),('houses',house_roof_chimney(pitch=CPITCH)),('houses',house_roof_run()),('houses',house_roof_run('R_clay','clay')),
              ]
        for e in ('left','right'):
            out+=[('houses',house_roof_end(end=e)),('houses',house_roof_end('R_comp','W_siding',BLUEG,'comp_siding',e)),('houses',house_roof_end('R_clay','W_stucco',CREAM,'clay_stucco',e)),
                  ('houses',house_roof_end('R_clay','W_stucco',WHITE,'clay_stucco_white',e))]
    if group=='shops':
        out+=[('shops',shop_front('cafe_red','SG_cafe','AW_red','r')),('shops',shop_front('books_green','SG_books','AW_green','l')),
              ('shops',shop_front('bakery_navy','SG_bakery','AW_navy','r',(0.97,0.88,0.62))),('shops',shop_front('surf_black','SG_surf','AW_black','l',(0.68,0.76,0.82))),
              ('shops',shop_side()),('shops',shop_side(hand='l')),('shops',shop_back()),('shops',shop_roof('mid')),('shops',shop_roof('end')),('shops',shop_roof('single')),
              ('shops',shop_trim_cornice_corner('r')),('shops',shop_trim_cornice_corner('l'))]
    return out

# ---------------------------------------------------------------- house trims
def house_trim_corner(tint=(0.92,0.92,0.90),tag='white'):
    """outer corner boards: an L of two 13 cm boards covering the corner seam where two wall pieces meet edge to edge.
    Snap: the corner point (where the two exterior faces meet) = origin; walls run toward -X and -Z."""
    b=Piece(f'house_trim_corner_{tag}','house_trim',snap=None,drop=[(Z,0.0,-1),(X,0.0,-1),(Z,0.0,1,1e9)],budget=(40,12,8),trim=tint,style='modular')
    TB={'t':'trim','mat':'T_white','tint':tint}
    b.add('box',x0=-0.13,x1=0.03,y0=0.0,y1=HW,z0=0.0,z1=0.03,top=None,side=TB,meta={'type':'trim'},tiers=('near',))   # top hidden under the eave
    b.add('box',x0=-0.13,x1=0.0,y0=0.0,y1=HW,z0=0.0,z1=0.03,top=None,side=TB,meta={'type':'trim'},tiers=('mid','far'))   # single board, no wrap (no exposed back)
    b.add('box',x0=0.0,x1=0.03,y0=0.0,y1=HW,z0=-0.13,z1=0.0,top=None,side=TB,meta={'type':'trim'},tiers=('near',))
    b.drop=[(Z,0.0,-1),(X,0.0,-1),(Y,HW,1)]   # back against the walls; top tucked under the eave
    b.origin=(0.0,0.0,0.0,0.0); b.col_mode='bbox'
    b.snap={'grid':GRID,'type':'house_corner','corner':[0,0,0],'note':'origin = outer corner point on the plate line at ground; rotate 90 deg steps'}
    return b

# ---------------------------------------------------------------- house roofs (side gable over a 7.5 m deep house, 3 m runs)
DEPTH=7.5; PITCH=0.45; OV=0.45
# clay roofs use the main-kit Spanish profile pitch (houses.spanish: 0.36), so the barrel courses are seen at the same
# angle as on the main-kit clay roofs (same R_clay region, 0.5 m courses, 16 m u period, barrels down the slope)
CPITCH=0.36
def ridge_y(pitch): return HW+0.18+pitch*(DEPTH/2+OV)      # top of the ridge of a 7.5 m house roof
def roof_piece(name,end,roof='R_comp',wall='W_stucco',tint=CREAM,tag='comp'):
    pitch=CPITCH if roof=='R_clay' else PITCH
    w=3.0; z0,z1=-DEPTH/2,DEPTH/2
    drops=[(Z,z1,1),(Z,z0,-1)]
    drops+=[(X,-w/2,-1,HW if end=='left' else 1e9),(X,w/2,1,HW if end=='right' else 1e9)]
    b=Piece(name,'house_roof',snap=None,drop=drops,budget=(240 if end else 160,72 if end else 50,8),wall=wall,tint=tint,roof=roof,style='modular')
    b.floor=FL
    ops={end:[dict(k='vent',c=0.0,w=0.6,t0=HW+0.35,t1=HW+0.75)]} if end else {}
    b.add('block',x0=-w/2,x1=w/2,z0=z0,z1=z1,W=HW,roof='gable',axis='x',pitch=pitch,o=OV,f=0.18,rake=0.3 if end else 0.0,
          rake_ends=(end or 'left',),openings=ops,rafters=True,rafter_spacing=1.5,rafter_sides=('front',),downspouts=(),gutters=True,foundation=False,sills=False)
    if end:
        # one downspout per gable-end piece (diagonal corners of the house): leader on the wall + offset arm under the
        # soffit to the gutter. endl -> back-left corner, endr -> front-right corner; 0.25 m in from the corner (clear of
        # corner boards and of the end wall pieces' openings)
        DS={'t':'trim','mat':'T_white','tint':(0.93,0.93,0.91)}
        c=x_=(-w/2+0.25) if end=='left' else (w/2-0.25); zw,sg=(z0,-1) if end=='left' else (z1,1)
        zz=sorted([zw,zw+sg*0.08]); k=dict(meta={'type':'pipe'},tiers=('near',),overlay=True)
        b.add('box',x0=c-0.04,x1=c+0.04,y0=0.0,y1=HW-0.08,z0=zz[0],z1=zz[1],top=None,side=DS,bottom=None,**k)          # leader
        zz=sorted([zw,zw+sg*(OV+0.06)])
        b.add('box',x0=c-0.04,x1=c+0.04,y0=HW-0.08,y1=HW,z0=zz[0],z1=zz[1],top=None,side=DS,bottom=DS,**k)             # offset arm to the gutter
        b.extra_drop=[(Z,zw,-sg)]; b.ground_reach=True      # leader/arm backs on the wall
    # rafter tails: top tucked 3 mm under the soffit and the wall end on the wall face are never seen
    def hidden(f,cc):
        if f.kind!='trim': return False
        if f.n[1]>0.999 and abs(cc[1]-(HW-0.003))<2e-3: return True
        if abs(f.n[2])>0.999 and min(abs(cc[2]-z1),abs(cc[2]-z0))<0.004 and np.sign(f.n[2])==-np.sign(cc[2]) and cc[1]<HW: return True
        return False
    b.hidden=hidden
    b.clip_soffit=(HW,z1,z0); b.abut_sides={'left':('right',),'right':('left',)}.get(end,('left','right'))
    b.base_y=HW; b.col_mode='roof'
    b.snap={'grid':GRID,'type':'house_roof','run':w,'span':DEPTH,'plate_y':HW,'pitch':pitch,'overhang':OV,
            'note':'origin on the house centre line (z=0 = middle of the 7.5 m depth) at ground; the roof sits on the plate (y=3.5)'+(f'; gable end on the {end} (-X/+X)' if end else '; both ends open')}
    return b
def house_roof_run(roof='R_comp',tag='comp'): return roof_piece(f'house_roof_gable_run_3m_{tag}',None,roof,tag=tag)
def house_roof_end(roof='R_comp',wall='W_stucco',tint=CREAM,tag='comp_stucco',end='left'): return roof_piece(f'house_roof_gable_end{end[0]}_3m_{tag}',end,roof,wall,tint,tag)

def house_roof_chimney(tag='brick',mat='W_brick',tint=(1,1,1),pitch=PITCH):
    """brick chimney straddling the ridge: 0.7 x 0.6 m stack, 0.9 m above the ridge, precast slab cap. Sits on any 3 m roof
    piece (run or end); origin on the house centre line (z = 0) at ground; slide it along x on the 0.5 m grid, keep it
    >= 0.5 m from a gable end. Its foot is buried 0.37 m below the ridge, so it closes against both roof slopes."""
    RID=ridge_y(pitch)                # ridge top of the 3 m roof pieces (5.57 at the comp pitch, 5.19 on clay roofs)
    PITCH_=pitch
    y0=RID-0.37; y1=RID+0.9
    b=Piece(f'house_roof_chimney_{tag}'+('_clay' if pitch==CPITCH else ''),'house_trim',snap=None,drop=[],budget=(90,24,12),style='modular')
    SD={'t':'wall','mat':mat,'tint':tint,'bands':None,'openings':[],'side':None}
    CS={'t':'swatch','mat':'S_concrete','tint':(0.78,0.78,0.77)}
    b.add('box',x0=-0.35,x1=0.35,y0=y0,y1=y1,z0=-0.3,z1=0.3,top=CS,side=SD,bottom=None,meta={'type':'stack'},tiers=('near','mid'))
    b.add('box',x0=-0.35,x1=0.35,y0=y0,y1=y1,z0=-0.3,z1=0.3,top=CS,side=SD,bottom=CS,meta={'type':'stack'},tiers=('far',))   # far: closed box
    b.add('box',x0=-0.41,x1=0.41,y0=y1+0.002,y1=y1+0.10,z0=-0.36,z1=0.36,top=CS,side={'t':'trim','mat':'T_concrete','tint':(0.85,0.85,0.85)},bottom=CS,
          meta={'type':'chimney_cap'},tiers=('near',),overlay=True)
    b.origin=(0.0,0.0,0.0,0.0); b.col_mode='bbox'; b.base_y=round(RID-PITCH_*0.3,3); b.roof_cut=(RID,PITCH_)   # base = where the stack meets the roof at its eave-side faces
    b.cut_box=[-0.35,0.35,y0,RID,-0.3,0.3]   # merge removes other pieces' roof tiles inside the stack
    b.snap={'grid':GRID,'type':'house_chimney','cut_box':b.cut_box,'note':'origin on the house centre line at ground; place at (x,0,0) on any 3 m roof piece, x on the 0.5 m grid, >=0.5 m from a gable end'}
    return b

# ---------------------------------------------------------------- storefronts (city atlas): 6 m bays, shop at grade
def shop_piece(name,w,depth,ops,cls,budget,tint=CREAM,wall='W_stucco',extra=None,parapet=True,**bkw):
    b=Piece(name,cls,snap=None,drop=[(X,-w/2,-1),(X,w/2,1),(Z,-depth,-1),(Y,SW,1)],budget=budget,wall=wall,tint=tint,roof='R_flat',
            trim=(0.95,0.94,0.90),style='modular')
    b.floor=0.0; b.floor_lines=[GF]; b.abuts_all=True
    b.add('block',x0=-w/2,x1=w/2,z0=-depth,z1=0.0,W=SW,roof='flat',parapet=PAR if parapet else 0.0,parapet_sides=('front',),cap='T_white',
          gutters=False,openings={'front':ops},sills=True,sill_tint=(0.95,0.94,0.90),foundation=False,shutter_tint=(0.3,0.3,0.3),far_facade=bkw.pop('far_facade',None),far_tile=bkw.pop('far_tile',None),**bkw)
    if extra: extra(b,w)
    b.snap={'grid':GRID,'module':w,'type':cls,'ends':[[-w/2,0,depth/2],[w/2,0,depth/2]],'face_z':depth/2,'plate_y':SW,'parapet_top':SW+PAR}
    return b

def shop_front(tag,sign,awning,door='r',tint=CREAM,wall='W_stucco'):
    """storefront bay: bulkhead + glazing + transom, recessed glazed door, sign board, awning, two gooseneck lamps,
    pilasters inset at both ends (bays side by side read as paired pilasters), false-front cornice"""
    w=SHOP; PIL=0.32; ia=-w/2+PIL+0.2; ib=w/2-PIL-0.2; dw=1.6
    dc=ib-dw/2 if door=='r' else ia+dw/2
    sa,sb=(ia,dc-dw/2-0.45) if door=='r' else (dc+dw/2+0.45,ib)
    n=max(1,round((sb-sa)/2.0))
    ops=[dict(k='shopdoor',c=round(dc,3),w=dw,t0=0.0,t1=3.0,depth=0.45),dict(k='storefront',c=round((sa+sb)/2,3),w=round(sb-sa,3),t0=0.0,t1=3.0,units=n,depth=0.12)]
    def ex(b,w):
        b.add('sign',side='front',wall=0.0,c=0.0,y=3.12,w=w-2*PIL-0.9,h=0.58,region=sign)
        b.add('awning',side='front',wall=0.0,s0=ia-0.05,s1=ib+0.05,y_top=3.06,depth=1.15,drop=0.5,region=awning)
        for f_ in (0.25,0.75): b.add('gooseneck',side='front',wall=0.0,c=-w/2+w*f_,y=4.05)
        for c in (-w/2+PIL/2+0.06,w/2-PIL/2-0.06): b.add('pilaster',side='front',wall=0.0,c=c,y1=SW+PAR-0.38,w=PIL)
        # two-step false-front cornice running exactly to the snap ends (open ends; corners get shop_trim_cornice_corner_*)
        TB={'t':'trim','mat':'T_white','tint':(0.95,0.94,0.90)}; yc=SW+PAR-0.36
        b.add('box',x0=-w/2,x1=w/2,y0=yc,y1=yc+0.14,z0=0.002,z1=0.08,top=TB,side=TB,bottom=TB,meta={'type':'trim'},tiers=('near',),overlay=True)
        b.add('box',x0=-w/2,x1=w/2,y0=yc+0.142,y1=yc+0.262,z0=0.002,z1=0.2,top=TB,side=TB,bottom=TB,meta={'type':'trim'},tiers=('near',),overlay=True)
    b=shop_piece(f'shop_front_6m_{tag}',w,T_S,ops,'shop_front',(700,210,12),tint,wall,ex,far_facade='F_c_shop_1', far_u0=-3.0)
    b.no_door=False; return b

def shop_side(tag='stucco',tint=CREAM,wall='W_stucco',L=12.0,hand='r'):
    """side elevation, one piece per side (the shop depth module is 12 m): three high windows, two louvres, meter + conduit,
    service door to the back room; parapet stops 0.2 m short of both ends so it butts the front/back parapets' inner faces"""
    # hand 'r' (right side of the shop): service door toward +X = the back. hand 'l' is the mirror image for left sides
    m=1 if hand=='r' else -1
    ops=[dict(k='small',c=-4.0*m,w=0.7,t0=2.0,t1=2.7),dict(k='louver',c=-1.6*m,w=0.9,t0=2.6,t1=3.4),dict(k='small',c=0.6*m,w=0.7,t0=2.0,t1=2.7),
         dict(k='louver',c=2.8*m,w=0.9,t0=2.6,t1=3.4),dict(k='apt_door',c=4.6*m,w=1.0,t0=0.0,t1=2.2)]
    def ex(b,w):
        b.add('fixtures',side='front',wall=0.0,items=[('meter',-2.8*m,0.9),('lamp',5.35*m,2.25)])
        # roof drainage: scupper through the parapet -> conductor head -> 10x8 cm leader on straps -> kick-out shoe at grade
        DS={'t':'trim','mat':'T_white','tint':(0.58,0.60,0.61)}   # painted grey metal (the T_metal swatch renders near-black)
        for c in (-5.4*m,3.75*m):
            k=dict(top=DS,side=DS,bottom=DS,meta={'type':'pipe'},tiers=('near',),overlay=True)
            b.add('box',x0=c-0.12,x1=c+0.12,y0=SW+0.10,y1=SW+0.22,z0=0.0,z1=0.26,**k)                       # scupper
            b.add('box',x0=c-0.17,x1=c+0.17,y0=SW-0.38,y1=SW+0.06,z0=0.0,z1=0.22,**k)                       # conductor head
            b.add('box',x0=c-0.05,x1=c+0.05,y0=0.16,y1=SW-0.38,z0=0.04,z1=0.12,**dict(k,top=None,bottom=None))  # leader
            b.add('box',x0=c-0.055,x1=c+0.055,y0=0.0,y1=0.16,z0=0.04,z1=0.34,**dict(k,bottom=None))        # kick-out shoe
            for h in (1.3,3.0): b.add('box',x0=c-0.075,x1=c+0.075,y0=h,y1=h+0.04,z0=0.0,z1=0.135,**k)        # straps
    b=Piece(f'shop_side_12m_{tag}'+('_l' if hand=='l' else ''),'shop_side',snap=None,drop=[(X,-L/2,-1,SW+PAR),(X,L/2,1,SW+PAR),(Z,-0.3,-1),(Y,SW,1)],budget=(420,126,10),wall=wall,tint=tint,
            roof='R_flat',trim=(0.95,0.94,0.90),style='modular')
    b.floor=0.0; b.floor_lines=[GF]; b.abuts_all=True; b.no_door=False
    b.add('block',x0=-L/2,x1=L/2,z0=-0.3,z1=0.0,W=SW,roof='flat',parapet=0.0,gutters=False,openings={'front':ops},sills=True,
          sill_tint=(0.95,0.94,0.90),foundation=False)
    TB={'t':'trim','mat':'T_white','tint':(0.95,0.94,0.90)}; WL={'t':'wall','mat':wall,'tint':tint,'bands':None,'openings':[],'side':None}
    b.add('box',x0=-L/2,x1=L/2,y0=SW,y1=SW+PAR,z0=-0.2,z1=0.0,top=TB,side=WL,meta={'type':'parapet'})   # full length: closes the corner (front/back parapet ends are open snap faces)
    b.add('box',x0=-L/2,x1=L/2,y0=SW+PAR,y1=SW+PAR+0.08,z0=-0.25,z1=0.05,top=TB,side=TB,bottom=TB,meta={'type':'coping'},tiers=('near',))   # full length, 1 cm proud of the front/back copings: laps them at the corners
    b.extra_drop=[(X,-L/2+0.2,-1),(X,L/2-0.2,1),(Z,0.0,-1)]   # + backs of applied details against the wall
    ex(b,L)
    b.snap={'grid':GRID,'module':L,'type':'shop_side','ends':[[-L/2,0,0.15],[L/2,0,0.15]],'face_z':0.15,'plate_y':SW,'parapet_top':SW+PAR,
            'note':'one piece per side wall of a 12 m deep shop; parapet inset 0.2 m at both ends'}
    return b

def shop_back(tag='stucco',tint=CREAM,wall='W_stucco'):
    """back of house: service door at grade with a lamp, louvre, high window, meter"""
    w=SHOP
    ops=[dict(k='apt_door',c=-1.2,w=1.0,t0=0.0,t1=2.2),dict(k='louver',c=0.9,w=0.9,t0=2.4,t1=3.2),dict(k='small',c=2.2,w=0.7,t0=1.9,t1=2.6)]
    def ex(b,w):
        b.add('fixtures',side='front',wall=0.0,items=[('lamp',-0.45,2.25),('meter',0.9,0.9)])
    b=shop_piece(f'shop_back_6m_{tag}',w,0.3,ops,'shop_back',(300,90,8),tint,wall,ex); b.no_door=False; return b

def shop_roof(kind,depth=12.0):
    """flat roof deck between the parapets (bitumen), one RTU + a vent stack. kind: mid (open both sides), end (parapet
    on -X: deck stops 0.2 m short), single (parapets both sides). Front/back parapets: deck stops 0.2 m short."""
    w=SHOP; pin=0.2
    xa=-w/2+(pin if kind in ('end','single') else 0.0); xb=w/2-(pin if kind=='single' else 0.0)
    za,zb=-depth/2+pin,depth/2-pin
    b=Piece(f'shop_roof_6m_{kind}','shop_roof',snap=None,drop=[(X,xa,-1),(X,xb,1),(Z,za,-1),(Z,zb,1)],budget=(140,42,4),roof='R_flat',
            trim=(0.95,0.94,0.90),style='modular')
    b.floor=0.0
    b.add('block',x0=xa,x1=xb,z0=za,z1=zb,W=SW,roof='flat',parapet=0.0,gutters=False,foundation=False,sills=False)
    b.add('rtu',x=(xa+xb)/2,z=-depth/4,y=SW,w=1.4,d=1.0,h=0.8)
    b.add('roofvent',x=(xa+xb)/2+1.5,z=depth/4,y=SW,vk='stack')
    b.extra_drop=[]
    b.origin=(0.0,0.0,w,depth); b.base_y=SW; b.col_mode='bbox'
    b.snap={'grid':GRID,'type':'shop_roof','module':w,'depth':depth,'plate_y':SW,'kind':kind,
            'note':'origin = bay centre line / building depth centre at ground; deck at y=4.2'}
    return b

def shop_trim_corner_pier(tint=(0.95,0.94,0.90)):
    """corner pier: 0.5 m square pier with plinth and cap, full height to the parapet top; covers the corner where a front
    bay and a side bay meet (origin = outer corner point)"""
    b=Piece('shop_trim_corner_pier','shop_trim',snap=None,drop=[],budget=(80,24,6),trim=tint,style='modular')
    TB={'t':'trim','mat':'T_white','tint':tint}
    top=SW+PAR
    b.add('box',x0=-0.42,x1=0.08,y0=0.0,y1=top-0.25,z0=-0.42,z1=0.08,top=None,side=TB,meta={'type':'trim'},tiers=('near',))
    b.add('box',x0=-0.47,x1=0.13,y0=top-0.25,y1=top+0.06,z0=-0.47,z1=0.13,top=TB,side=TB,bottom=TB,meta={'type':'trim'},tiers=('near',))
    b.add('box',x0=-0.42,x1=0.08,y0=0.0,y1=top+0.06,z0=-0.42,z1=0.08,top=TB,side=TB,meta={'type':'trim'},tiers=('mid','far'))
    b.add('box',x0=-0.46,x1=0.12,y0=0.0,y1=0.5,z0=-0.46,z1=0.12,top=TB,side=TB,meta={'type':'trim'},tiers=('near',))
    b.origin=(0.0,0.0,0.0,0.0); b.col_mode='bbox'; b.base_y=yc
    b.snap={'grid':GRID,'type':'shop_corner','corner':[0,0,0],'note':'origin = outer corner point at ground'}
    return b

def shop_trim_cornice_corner(hand='r',tint=(0.95,0.94,0.90)):
    """corner return of the false-front cornice: closes the cornice end at a front corner and returns 0.3 m along the side
    wall. Origin = the outer front corner point at ground; 'r' for the front-right corner, 'l' for the front-left."""
    m=1 if hand=='r' else -1
    b=Piece(f'shop_trim_cornice_corner_{hand}','shop_trim',snap=None,drop=[(X,0.0,-m)],budget=(40,12,10),trim=tint,style='modular')
    TB={'t':'trim','mat':'T_white','tint':tint}; yc=SW+PAR-0.36
    def bx(a,c): return (min(0,m*a),max(0,m*a))
    x0,x1=bx(0.08,0); b.add('box',x0=x0,x1=x1,y0=yc,y1=yc+0.14,z0=-0.3,z1=0.08,top=TB,side=TB,bottom=TB,meta={'type':'trim'},tiers=('near',))
    x0,x1=bx(0.2,0); b.add('box',x0=x0,x1=x1,y0=yc+0.142,y1=yc+0.262,z0=-0.3,z1=0.2,top=TB,side=TB,bottom=TB,meta={'type':'trim'},tiers=('near',))
    x0,x1=bx(0.2,0); b.add('box',x0=x0,x1=x1,y0=yc,y1=yc+0.262,z0=-0.3,z1=0.2,top=TB,side=TB,bottom=TB,meta={'type':'trim'},tiers=('mid','far'))
    b.origin=(0.0,0.0,0.0,0.0); b.col_mode='bbox'; b.base_y=yc
    b.snap={'grid':GRID,'type':'shop_corner','corner':[0,0,0],'hand':hand,'note':'origin = outer front corner point at ground, no rotation (front faces +Z)'}
    return b
