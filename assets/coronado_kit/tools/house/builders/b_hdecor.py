"""House + store decor — original geometry, page H, near+col only.

36 pieces: framed prints, mirrors, clocks, vases, bowls, candles,
figurines, sculptures, wall plates, bookends, globe, clutter.
Art uses one inset decal quad per frame, stretch-fit to a page-H art_* slot
(painterly / poster work in the y=512–1023 bank). A paper mat surrounds it.
Delete stale _bake/tiles/<name>_* after any geometry change.
"""
import math
from mathutils import Vector, Matrix

def sg(hi, lo, hi_n):
    return hi_n if hi else lo

def screw(b, c, n=(0,0,1), hi=False, key='steel', r=0.0045):
    n=Vector(n).normalized(); c=Vector(c); seg=sg(hi,8,14)
    b.tube(c-n*0.002, c+n*0.003, r, r*0.92, seg, key, cap0=False, cap1=True, smooth=True)
    if hi:
        b.tube(c-n*0.010, c-n*0.001, r*0.45, r*0.45, 8, key, cap0=True, cap1=False, smooth=True)

def maker_plate(b, c, hi=False, w=0.05, h=0.012, rz=0.0, key='badge'):
    b.box(c,(w,0.005,h),key,rz=rz)
    if hi:
        screw(b,(c[0]-w*0.35,c[1]+0.003,c[2]),(0,-1,0),True,'steel',0.002)

def pq(b, xa, xb, za, zb, y, k, dy=0.0):
    b.quad([Vector((xa,y-dy,za)),Vector((xb,y-dy,za)),Vector((xb,y-dy,zb)),Vector((xa,y-dy,zb))],k)

def disc_xz(b, cx, y, cz, r, n, key, a0=0.0, a1=None, decal=False):
    if a1 is None: a1=2*math.pi
    pts=[Vector((cx+r*math.cos(a0+(a1-a0)*i/n), y, cz+r*math.sin(a0+(a1-a0)*i/n))) for i in range(n)]
    luv=[(p.x, p.z) for p in pts]
    b.faces(pts,[tuple(range(n))],key,[luv],decal=decal)

def hang(b, W, D, H, hi=False):
    """Thin hanging wire fully on the back face, inset from the edges so it
    cannot read as corner tabs in a 3/4 view. No D-ring or bumper boxes."""
    y=D*0.5+0.006
    b.tube((-W*0.5+0.10, y, H-0.10),(0.0, y, H-0.02),0.0025,0.0025,sg(hi,6,8),'steel',cap0=True,cap1=False,smooth=True)
    b.tube(( W*0.5-0.10, y, H-0.10),(0.0, y, H-0.02),0.0025,0.0025,sg(hi,6,8),'steel',cap0=True,cap1=True,smooth=True)

def frame_shell(b, W, D, H, fw, key, step_key=None, back='paper'):
    # horizontal rails run the full width; verticals sit between them so
    # overlapping end-caps do not show as dark corner tabs
    b.box((0,0,0.0),(W,D,fw),key,skip=('bottom',))
    b.box((0,0,H-fw),(W,D,fw),key)
    b.box((-(W*0.5)+fw*0.5,0,fw),(fw,D,H-2*fw),key,skip=('bottom','top'))
    b.box(((W*0.5)-fw*0.5,0,fw),(fw,D,H-2*fw),key,skip=('bottom','top'))
    fw2=max(0.012, fw*0.42)
    sk=step_key or key
    b.box((0,-0.006,fw-0.004),(W-fw, max(0.016,D*0.35), fw2),sk)
    b.box((0,-0.006,H-fw-fw2+0.004),(W-fw, max(0.016,D*0.35), fw2),sk)
    b.box((-(W*0.5)+fw+fw2*0.5-0.004,-0.006,fw),(fw2, max(0.016,D*0.35), H-2*fw),sk)
    b.box(((W*0.5)-fw-fw2*0.5+0.004,-0.006,fw),(fw2, max(0.016,D*0.35), H-2*fw),sk)
    b.box((0, D*0.5-0.005, fw),(W-2*fw, 0.010, H-2*fw),back)
    return fw+0.008, H-fw-0.008, -(W*0.5)+fw+0.008, (W*0.5)-fw-0.008, -D*0.5+0.004

def rococo_corners(b, W, D, H, fw):
    # gilt bosses at corners and mid-sides
    for x,z in ((-W*0.5+fw*0.4,fw*0.4),(W*0.5-fw*0.4,fw*0.4),
                (-W*0.5+fw*0.4,H-fw*0.4),(W*0.5-fw*0.4,H-fw*0.4),
                (0,fw*0.35),(0,H-fw*0.35),
                (-W*0.5+fw*0.35,H*0.5),(W*0.5-fw*0.35,H*0.5)):
        b.box((x,-D*0.15,z),(0.034,D*0.55,0.034),'gilt')

def art_panel(b, x0,x1,z0,z1,y, key, mat='paper'):
    """Paper mat + a single art_* decal quad, stretch-fit to the page-H slot."""
    pq(b,x0,x1,z0,z1,y,mat)
    w,h=x1-x0, z1-z0
    m=max(0.006, min(0.014, 0.05*min(w,h)))
    ax0,ax1,az0,az1=x0+m,x1-m,z0+m,z1-m
    b.quad([Vector((ax0,y-0.001,az0)),Vector((ax1,y-0.001,az0)),
            Vector((ax1,y-0.001,az1)),Vector((ax0,y-0.001,az1))], key, decal=True)

# ------------------------------------------------------------------ frames

def _frame(b, W, D, H, fw, key, step, art_key, hi=False, rococo=False, mat='paper'):
    z0,z1,x0,x1,y=frame_shell(b,W,D,H,fw,key,step)
    art_panel(b,x0,x1,z0,z1,y,art_key,mat)
    if rococo: rococo_corners(b,W,D,H,fw)
    hang(b,W,D,H,hi)
    maker_plate(b,(0,0.0,0.016),hi,w=0.04,h=0.010)
    b.cbox((0,0,0),(W,D+0.02,H))

def frame_print_small(b, hi=False):
    _frame(b,0.28,0.045,0.36,0.022,'wash','walnut','art_surf',hi)

def frame_print_medium(b, hi=False):
    _frame(b,0.50,0.050,0.65,0.032,'walnut','walnut','art_botanical',hi)

def frame_print_large(b, hi=False):
    _frame(b,0.90,0.055,0.70,0.038,'walnut','brass','art_hotel',hi)

def frame_print_tall(b, hi=False):
    _frame(b,0.40,0.050,0.90,0.030,'wash','walnut','art_palms',hi)

def frame_ocean(b, hi=False):
    _frame(b,0.70,0.050,0.50,0.036,'wash','wash','art_seascape',hi)

def frame_mcm_abstract(b, hi=False):
    _frame(b,0.60,0.050,0.60,0.034,'walnut','brass','art_mcm',hi)

def frame_motel_floral(b, hi=False):
    _frame(b,0.45,0.055,0.55,0.040,'gilt','gilt','art_floral',hi,rococo=True)

def frame_stand_photo(b, hi=False):
    W,D,H,fw=0.16,0.016,0.20,0.014
    # standing frame: easel back, sits on a table
    z0,z1,x0,x1,y=frame_shell(b,W,D,H,fw,'gilt','gilt')
    art_panel(b,x0,x1,z0,z1,y,'art_portrait')
    # easel strut
    b.box((0, 0.06, 0.0),(0.018,0.008,0.16),'gilt',rx=18)
    b.box((0, 0.04, 0.0),(0.08,0.04,0.008),'gilt')  # feet
    maker_plate(b,(0,0.0,0.01),hi,w=0.03,h=0.008)
    b.cbox((0,0.03,0),(0.16,0.12,0.20))

# ------------------------------------------------------------------ mirrors + clocks

def ring_xz(b, cx, y, cz, r, rad, n, key, hi):
    pts=[]
    for i in range(n):
        a=2*math.pi*i/n
        pts.append((cx+r*math.cos(a), y, cz+r*math.sin(a)))
    seg=sg(hi,5,8)
    for i in range(n):
        b.tube(pts[i], pts[(i+1)%n], rad, rad, seg, key, cap0=False, cap1=False, smooth=True)

def mirror_round(b, hi=False):
    # rattan-wrapped round mirror, hanging loop
    R=0.31; D=0.06; cy=0.0; cz=R
    # glass
    disc_xz(b,0,-D*0.15,cz,R-0.035,sg(hi,24,32),'mirror')
    disc_xz(b,0, D*0.20,cz,R-0.035,sg(hi,24,32),'paint_grey')  # back
    # rattan wrap (two rings) + brass inner lip
    ring_xz(b,0,-0.005,cz,R-0.008,0.016,sg(hi,14,18),'rattan',hi)
    ring_xz(b,0, 0.012,cz,R-0.008,0.014,sg(hi,14,18),'rattan',hi)
    ring_xz(b,0, 0.0,cz,R-0.028,0.007,sg(hi,14,18),'brass',hi)
    # hanging loop
    b.tube((0,0,2*R-0.01),(0,0,2*R+0.03),0.008,0.008,sg(hi,8,10),'brass',cap0=True,cap1=False,smooth=True)
    b.tube((-0.025,0,2*R+0.03),(0.025,0,2*R+0.03),0.007,0.007,sg(hi,8,10),'brass',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0,0.0,0.03),hi,w=0.04,h=0.010)
    b.ccyl((0,0,0),R+0.02,2*R+0.04)

def mirror_rect(b, hi=False):
    W,D,H,fw=0.50,0.060,0.80,0.040
    z0,z1,x0,x1,y=frame_shell(b,W,D,H,fw,'walnut','brass',back='paint_grey')
    # opaque glass with a slight inset
    pq(b,x0,x1,z0,z1,y,'mirror')
    # inner bevel strip (painted, not alpha)
    pq(b,x0,x1,z0,z0+0.012,y,'brass',0.001)
    pq(b,x0,x1,z1-0.012,z1,y,'brass',0.001)
    pq(b,x0,x0+0.012,z0,z1,y,'brass',0.001)
    pq(b,x1-0.012,x1,z0,z1,y,'brass',0.001)
    hang(b,W,D,H,hi)
    maker_plate(b,(0,0.0,0.016),hi)
    b.cbox((0,0,0),(W,D+0.02,H))

def clock_wall_sunburst(b, hi=False):
    cz=0.275; y=0.0
    # rays (12, 4-seg tubes — keep the silhouette, stay under the 550 target)
    n=12
    for i in range(n):
        a=2*math.pi*i/n
        ca,sa=math.cos(a),math.sin(a)
        long=0.26 if i%2==0 else 0.19
        b.tube((0.055*ca,0,cz+0.055*sa),(long*ca,0,cz+long*sa),
               0.009 if i%2==0 else 0.005, 0.0025, 4,'brass',cap0=True,cap1=True,smooth=True)
    # face
    disc_xz(b,0,-0.012,cz,0.105,12,'paint_cream')
    disc_xz(b,0, 0.016,cz,0.105,12,'paint_grey')
    ring_xz(b,0,0,cz,0.108,0.007,10,'brass',hi)
    # ticks
    for i in range(12):
        a=2*math.pi*i/12
        ca,sa=math.cos(a),math.sin(a)
        L=0.016 if i%3==0 else 0.010
        b.tube((0.078*ca,-0.014,cz+0.078*sa),( (0.078+L)*ca,-0.014,cz+(0.078+L)*sa),
               0.003,0.003,sg(hi,4,6),'paint_navy',cap0=True,cap1=True,smooth=True)
    # hands + hub
    b.tube((0,-0.018,cz),(0.055, -0.018, cz+0.01),0.004,0.002,sg(hi,5,6),'paint_navy',cap0=True,cap1=True,smooth=True)
    b.tube((0,-0.020,cz),(0.02, -0.020, cz+0.06),0.004,0.002,sg(hi,5,6),'paint_navy',cap0=True,cap1=True,smooth=True)
    b.tube((0,-0.016,cz-0.01),(0,-0.022,cz+0.01),0.010,0.010,sg(hi,8,10),'brass',cap0=True,cap1=True,smooth=True)
    # hanger
    b.tube((0,0,cz+0.26),(0,0,cz+0.275+0.02),0.006,0.006,sg(hi,6,8),'brass',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0,0.0,0.03),hi)
    # start the hull above the ray tips so wall-mount DZ cannot push col under y=0
    b.ccyl((0,0,0.04),0.28,0.275*2)

def clock_mantel(b, hi=False):
    W,D,H=0.28,0.12,0.32
    # case
    b.box((0,0,0.0),(W,D,0.03),'walnut',skip=('bottom',))
    b.box((0,0,0.03),(W-0.02,D-0.02,H-0.06),'walnut')
    b.box((0,0,H-0.03),(W-0.01,D-0.01,0.03),'walnut')
    # brass feet
    for x,y in ((-W*0.38,-D*0.32),(W*0.38,-D*0.32),(-W*0.38,D*0.32),(W*0.38,D*0.32)):
        b.tube((x,y,0.0),(x,y,0.018),0.012,0.010,sg(hi,8,10),'brass',cap0=True,cap1=True,smooth=True)
    # face recess + glass
    disc_xz(b,0,-D*0.42,0.17,0.09,sg(hi,14,18),'paint_cream')
    disc_xz(b,0,-D*0.48,0.17,0.095,sg(hi,14,18),'glass')
    ring_xz(b,0,-D*0.44,0.17,0.096,0.006,sg(hi,12,16),'brass',hi)
    for i in range(12):
        a=2*math.pi*i/12 + math.pi/2
        ca,sa=math.cos(a),math.sin(a)
        b.tube((0.07*ca,-D*0.46,0.17+0.07*sa),((0.07+0.012)*ca,-D*0.46,0.17+(0.07+0.012)*sa),
               0.0025,0.0025,4,'paint_navy',cap0=True,cap1=True,smooth=True)
    b.tube((0,-D*0.50,0.17),(0.05,-D*0.50,0.18),0.003,0.002,5,'paint_navy',cap0=True,cap1=True,smooth=True)
    b.tube((0,-D*0.51,0.17),(0.0,-D*0.51,0.23),0.003,0.002,5,'paint_navy',cap0=True,cap1=True,smooth=True)
    b.tube((0,-D*0.48,0.16),(0,-D*0.52,0.18),0.008,0.008,sg(hi,6,8),'brass',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0,D*0.4,0.04),hi,w=0.05,h=0.012)
    b.cbox((0,0,0),(W,D,H))

# ------------------------------------------------------------------ vases, bowls, tray

def profile_rev(b, rings, key, hi, inner_lip=True):
    """rings: list of (z, r). Open vessel."""
    seg=sg(hi,12,16)
    for i in range(len(rings)-1):
        z0,r0=rings[i]; z1,r1=rings[i+1]
        last=i==len(rings)-2
        b.tube((0,0,z0),(0,0,z1),r0,r1,seg,key,cap0=(i==0),cap1=False,smooth=True)
    if inner_lip:
        z,r=rings[-1]
        b.tube((0,0,z),(0,0,z+0.006),r,max(0.008,r-0.012),seg,key,cap0=False,cap1=True,smooth=True)

def vase_tall(b, hi=False):
    profile_rev(b,[(0.00,0.055),(0.02,0.060),(0.10,0.085),(0.22,0.090),(0.30,0.050),(0.38,0.040),(0.42,0.048)],'ceramic_white',hi)
    # glaze band
    b.tube((0,0,0.18),(0,0,0.24),0.091,0.088,sg(hi,12,16),'ceramic_teal',cap0=False,cap1=False,smooth=True)
    maker_plate(b,(0,0.06,0.03),hi,w=0.03,h=0.008)
    b.ccyl((0,0,0),0.095,0.43)

def vase_bud(b, hi=False):
    profile_rev(b,[(0.00,0.028),(0.015,0.032),(0.07,0.038),(0.11,0.022),(0.15,0.018),(0.16,0.022)],'ceramic_teal',hi)
    maker_plate(b,(0,0.03,0.02),hi,w=0.02,h=0.006)
    b.ccyl((0,0,0),0.04,0.165)

def vase_ginger(b, hi=False):
    profile_rev(b,[(0.00,0.06),(0.02,0.08),(0.10,0.11),(0.16,0.11),(0.20,0.07),(0.22,0.045)],'ceramic_coral',hi,inner_lip=False)
    # lid + finial
    b.tube((0,0,0.22),(0,0,0.245),0.055,0.070,sg(hi,12,16),'ceramic_coral',cap0=True,cap1=False,smooth=True)
    b.tube((0,0,0.245),(0,0,0.265),0.070,0.02,sg(hi,12,16),'ceramic_coral',cap0=False,cap1=True,smooth=True)
    b.tube((0,0,0.265),(0,0,0.28),0.014,0.010,sg(hi,8,12),'ceramic_white',cap0=False,cap1=True,smooth=True)
    maker_plate(b,(0,0.08,0.03),hi,w=0.03,h=0.008)
    b.ccyl((0,0,0),0.115,0.28)

def vase_lava(b, hi=False):
    profile_rev(b,[(0.00,0.05),(0.02,0.06),(0.10,0.08),(0.18,0.075),(0.24,0.045),(0.26,0.05)],'ceramic_lava',hi)
    # fat lava lumps on the shoulder
    for a in (0,72,144,216,288):
        ca,sa=math.cos(math.radians(a)),math.sin(math.radians(a))
        r=0.078
        b.tube((r*ca,r*sa,0.10),( (r+0.014)*ca,(r+0.014)*sa,0.15),0.018,0.010,5,'ceramic_lava',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0,0.06,0.02),hi,w=0.024,h=0.007)
    b.ccyl((0,0,0),0.10,0.26)

def bowl_ceramic(b, hi=False):
    se=sg(hi,14,18)
    # foot, wall, flared lip
    b.tube((0,0,0.0),(0,0,0.012),0.05,0.05,se,'ceramic_white',cap0=True,cap1=False,smooth=True)
    b.tube((0,0,0.012),(0,0,0.03),0.05,0.07,se,'ceramic_white',cap0=False,cap1=False,smooth=True)
    b.tube((0,0,0.03),(0,0,0.08),0.07,0.12,se,'ceramic_white',cap0=False,cap1=False,smooth=True)
    b.tube((0,0,0.08),(0,0,0.10),0.12,0.14,se,'ceramic_white',cap0=False,cap1=False,smooth=True)
    # interior well, clearly recessed
    b.tube((0,0,0.02),(0,0,0.085),0.045,0.115,se,'ceramic_teal',cap0=True,cap1=False,smooth=True)
    maker_plate(b,(0,0.11,0.03),hi,w=0.03,h=0.008)
    b.ccyl((0,0,0),0.145,0.11)

def bowl_wood(b, hi=False):
    profile_rev(b,[(0.00,0.05),(0.01,0.055),(0.03,0.13),(0.08,0.16),(0.09,0.155)],'walnut',hi)
    b.tube((0,0,0.015),(0,0,0.075),0.045,0.140,sg(hi,12,16),'teak',cap0=True,cap1=False,smooth=True)
    # turned ring
    b.tube((0,0,0.055),(0,0,0.065),0.161,0.161,sg(hi,12,16),'walnut',cap0=False,cap1=False,smooth=True)
    maker_plate(b,(0,0.14,0.03),hi,w=0.03,h=0.008)
    b.ccyl((0,0,0),0.165,0.09)

def bowl_shell(b, hi=False):
    # 5-lobe scallop dish, shallow aqua well. Budget is tight (260).
    n=sg(hi,20,24); lobes=5
    def ring(z, r0, amp):
        pts=[]
        for i in range(n):
            a=2*math.pi*i/n
            r=r0 + amp*(0.5+0.5*math.cos(lobes*a))
            pts.append(Vector((r*1.20*math.cos(a), r*0.82*math.sin(a), z)))
        return pts
    def stitch(a,c,key):
        for i in range(n):
            j=(i+1)%n
            b.quad([a[i],a[j],c[j],c[i]], key)
    def cap(pts, z, key, inward=False):
        c=Vector((0,0,z)); luv=[[(0,0),(pts[i].x,pts[i].y),(pts[(i+1)%n].x,pts[(i+1)%n].y)] for i in range(n)]
        faces=[(0,i+1,1+((i+1)%n)) for i in range(n)]
        if inward: faces=[(f[0],f[2],f[1]) for f in faces]
        b.faces([c]+pts, faces, key, luv)
    foot,belly,rim=ring(0.000,0.028,0.000),ring(0.022,0.055,0.016),ring(0.058,0.088,0.036)
    stitch(foot,belly,'ceramic'); stitch(belly,rim,'ceramic')
    cap(foot,0.000,'ceramic')
    # inner well, slightly below the rim
    well=ring(0.040,0.062,0.022)
    stitch(well, [Vector((p.x*0.98,p.y*0.98,0.054)) for p in rim], 'paint_aqua')
    cap(well,0.040,'paint_aqua')
    maker_plate(b,(0,0.07,0.016),hi,w=0.024,h=0.007)
    b.cbox((0,0,0),(0.28,0.20,0.07))

def decorative_tray(b, hi=False):
    W,D,H=0.36,0.24,0.04
    b.box((0,0,0.006),(W-0.02,D-0.02,0.006),'walnut',skip=('bottom',))  # well
    # gallery rail
    b.box((0,0,0.0),(W,D,0.008),'walnut',skip=('bottom',))
    for y,s in ((-D*0.5+0.006,1),(D*0.5-0.006,-1)):
        b.box((0,y,0.008),(W,0.010,0.022),'walnut')
    for x in (-W*0.5+0.006, W*0.5-0.006):
        b.box((x,0,0.008),(0.010,D,0.022),'walnut')
    # brass handles
    for x,s in ((-W*0.5-0.01,-1),(W*0.5+0.01,1)):
        b.tube((x, -0.05, 0.028),(x, 0.05, 0.028),0.006,0.006,sg(hi,8,10),'brass',cap0=True,cap1=True,smooth=True)
        b.tube((x-s*0.01, -0.05, 0.016),(x, -0.05, 0.028),0.005,0.005,sg(hi,6,8),'brass',cap0=True,cap1=True,smooth=True)
        b.tube((x-s*0.01,  0.05, 0.016),(x,  0.05, 0.028),0.005,0.005,sg(hi,6,8),'brass',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0, D*0.5-0.02, 0.010),hi,w=0.04,h=0.008)
    b.cbox((0,0,0),(W+0.04,D,H+0.01))

# ------------------------------------------------------------------ candles

def _candlestick(b, x, h_stem, hi):
    se=6
    b.tube((x,0,0.0),(x,0,0.012),0.032,0.030,se,'brass',cap0=True,cap1=True,smooth=True)
    b.tube((x,0,0.012),(x,0,0.04),0.016,0.014,se,'brass',cap0=False,cap1=False,smooth=True)
    b.tube((x,0,0.04),(x,0,0.07),0.014,0.022,se,'brass',cap0=False,cap1=False,smooth=False)
    b.tube((x,0,0.07),(x,0,h_stem),0.010,0.010,se,'brass',cap0=False,cap1=False,smooth=True)
    b.tube((x,0,h_stem),(x,0,h_stem+0.018),0.016,0.018,se,'brass',cap0=False,cap1=True,smooth=True)
    b.tube((x,0,h_stem+0.016),(x,0,h_stem+0.09),0.011,0.010,se,'wax',cap0=False,cap1=True,smooth=True)
    b.tube((x,0,h_stem+0.09),(x,0,h_stem+0.10),0.0015,0.0015,4,'paint_black',cap0=True,cap1=True,smooth=True)

def candle_pair_brass(b, hi=False):
    _candlestick(b,-0.07,0.16,hi)
    _candlestick(b, 0.07,0.12,hi)
    maker_plate(b,(0,0.03,0.02),hi,w=0.03,h=0.008)
    b.cbox((0,0,0),(0.24,0.08,0.28))

def candle_pillar(b, hi=False):
    b.tube((0,0,0.0),(0,0,0.008),0.055,0.055,sg(hi,10,14),'brass',cap0=True,cap1=True,smooth=True)  # saucer
    b.tube((0,0,0.008),(0,0,0.14),0.045,0.042,sg(hi,10,14),'wax',cap0=False,cap1=False,smooth=True)
    # melted crown
    b.tube((0,0,0.14),(0,0,0.155),0.042,0.050,sg(hi,10,14),'wax',cap0=False,cap1=True,smooth=True)
    b.tube((0,0,0.155),(0,0,0.165),0.002,0.002,sg(hi,4,6),'paint_black',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0,0.05,0.01),hi,w=0.024,h=0.006)
    b.ccyl((0,0,0),0.055,0.17)

def hurricane_lamp(b, hi=False):
    b.tube((0,0,0.0),(0,0,0.02),0.07,0.065,sg(hi,10,14),'brass',cap0=True,cap1=True,smooth=True)
    b.tube((0,0,0.02),(0,0,0.05),0.03,0.03,sg(hi,8,12),'brass',cap0=False,cap1=False,smooth=True)
    # candle
    b.tube((0,0,0.05),(0,0,0.14),0.018,0.016,sg(hi,8,10),'wax',cap0=True,cap1=True,smooth=True)
    b.tube((0,0,0.14),(0,0,0.15),0.002,0.002,4,'paint_black',cap0=True,cap1=True,smooth=True)
    # brass gallery (horizontal ring in XY at z=0.16)
    n=sg(hi,10,14)
    for i in range(n):
        a0=2*math.pi*i/n; a1=2*math.pi*(i+1)/n
        p0=(0.05*math.cos(a0),0.05*math.sin(a0),0.16)
        p1=(0.05*math.cos(a1),0.05*math.sin(a1),0.16)
        b.tube(p0,p1,0.005,0.005,sg(hi,5,6),'brass',cap0=False,cap1=False,smooth=True)
    # glass chimney (opaque)
    b.tube((0,0,0.16),(0,0,0.30),0.055,0.048,sg(hi,12,16),'glass',cap0=False,cap1=True,smooth=True)
    # handle
    b.tube((0.06,0,0.18),(0.09,0,0.22),0.005,0.005,sg(hi,6,8),'brass',cap0=True,cap1=False,smooth=True)
    b.tube((0.09,0,0.22),(0.09,0,0.26),0.005,0.005,sg(hi,6,8),'brass',cap0=False,cap1=False,smooth=True)
    b.tube((0.09,0,0.26),(0.06,0,0.28),0.005,0.005,sg(hi,6,8),'brass',cap0=False,cap1=True,smooth=True)
    maker_plate(b,(0,0.05,0.03),hi,w=0.03,h=0.008)
    b.ccyl((0,0,0),0.08,0.32)

# ------------------------------------------------------------------ figurines / sculptures

def figurine_bird(b, hi=False):
    # spend remaining budget on smoother segments, not extra parts
    se=sg(hi,10,14)
    b.tube((0,0,0.0),(0,0,0.010),0.048,0.046,se,'ceramic_teal',cap0=True,cap1=True,smooth=True)
    b.tube((-0.014,0.008,0.010),(-0.016,0.016,0.055),0.005,0.004,sg(hi,8,10),'paint_sand',cap0=True,cap1=True,smooth=True)
    b.tube(( 0.014,0.008,0.010),( 0.016,0.016,0.055),0.005,0.004,sg(hi,8,10),'paint_sand',cap0=True,cap1=True,smooth=True)
    # plump egg body
    b.tube((0,0.016,0.055),(0.010,0.000,0.105),0.032,0.026,se,'ceramic_white',cap0=True,cap1=False,smooth=True)
    # rounded head (no boxy cap)
    b.tube((0.016,-0.004,0.105),(0.024,-0.014,0.128),0.018,0.016,se,'ceramic_white',cap0=False,cap1=False,smooth=True)
    b.tube((0.024,-0.014,0.128),(0.026,-0.016,0.144),0.016,0.009,se,'ceramic_white',cap0=False,cap1=True,smooth=True)
    b.tube((0.030,-0.028,0.130),(0.058,-0.040,0.124),0.007,0.002,sg(hi,6,8),'paint_sand',cap0=True,cap1=True,smooth=True)
    # tapered tail, not a box
    b.tube((-0.008,0.024,0.080),(-0.042,0.042,0.068),0.016,0.006,sg(hi,8,10),'ceramic_white',cap0=True,cap1=True,smooth=True)
    b.tube((0.034,-0.026,0.134),(0.038,-0.030,0.134),0.0035,0.0035,6,'paint_black',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0,0.04,0.008),hi,w=0.024,h=0.006)
    b.cbox((0.01,0,0),(0.14,0.10,0.16))

def figurine_cat(b, hi=False):
    # seated silhouette: planted haunches, upright chest, short rounded ears
    se=sg(hi,10,14)
    b.tube((0,0,0.0),(0,0,0.010),0.050,0.048,se,'walnut',cap0=True,cap1=True,smooth=True)
    b.tube((0,0.016,0.010),(0,0.020,0.070),0.042,0.038,se,'paint_black',cap0=True,cap1=False,smooth=True)
    # folded forepaws
    b.tube((0,-0.026,0.010),(0,-0.030,0.034),0.022,0.018,sg(hi,10,12),'paint_black',cap0=True,cap1=True,smooth=True)
    # chest
    b.tube((0,-0.010,0.065),(0,-0.018,0.125),0.030,0.024,se,'paint_black',cap0=False,cap1=False,smooth=True)
    # round head
    b.tube((0,-0.020,0.122),(0,-0.022,0.168),0.022,0.020,se,'paint_black',cap0=False,cap1=True,smooth=True)
    # short, wide ears (not spikes)
    for x in (-0.011,0.011):
        b.tube((x,-0.028,0.164),(x,-0.030,0.186),0.010,0.004,sg(hi,6,8),'paint_black',cap0=True,cap1=True,smooth=True)
    # tail tucked around the haunch
    b.tube((0.030,0.020,0.016),(0.048,0.008,0.058),0.009,0.008,sg(hi,8,10),'paint_black',cap0=True,cap1=False,smooth=True)
    b.tube((0.048,0.008,0.058),(0.036,-0.022,0.072),0.008,0.006,sg(hi,8,10),'paint_black',cap0=False,cap1=True,smooth=True)
    b.tube((0,-0.018,0.118),(0,-0.018,0.128),0.026,0.026,sg(hi,8,10),'brass',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0,0.05,0.01),hi,w=0.024,h=0.006)
    b.cbox((0,0,0),(0.12,0.10,0.22))

def figurine_horse(b, hi=False):
    # stylised MCM horse: arched neck, bean body, thick tapered legs
    # budget is tight (290); no extra parts, just better curves
    se=sg(hi,8,10); bse=sg(hi,10,12)
    b.tube((0,0,0.0),(0,0,0.008),0.065,0.062,bse,'gilt',cap0=True,cap1=True,smooth=True)
    b.tube((-0.045,0,0.055),(0.040,0,0.070),0.028,0.024,bse,'ceramic_coral',cap0=True,cap1=True,smooth=True)
    b.tube((0.040,0,0.070),(0.048,-0.006,0.115),0.016,0.012,se,'ceramic_coral',cap0=False,cap1=False,smooth=True)
    b.tube((0.048,-0.006,0.115),(0.072,-0.016,0.112),0.012,0.008,se,'ceramic_coral',cap0=False,cap1=True,smooth=True)
    b.tube((0.052,-0.010,0.122),(0.056,-0.012,0.136),0.004,0.002,5,'ceramic_coral',cap0=True,cap1=True,smooth=True)
    # legs thick at the body, taper to the hoof (no stick legs, no extra hoof boxes)
    b.tube((-0.035, 0.016,0.050),(-0.040, 0.018,0.008),0.012,0.006,se,'ceramic_coral',cap0=True,cap1=True,smooth=True)
    b.tube((-0.035,-0.016,0.050),(-0.040,-0.018,0.008),0.012,0.006,se,'ceramic_coral',cap0=True,cap1=True,smooth=True)
    b.tube(( 0.030, 0.014,0.058),( 0.040, 0.016,0.008),0.011,0.005,se,'ceramic_coral',cap0=True,cap1=True,smooth=True)
    b.tube(( 0.030,-0.014,0.058),( 0.042,-0.016,0.008),0.011,0.005,se,'ceramic_coral',cap0=True,cap1=True,smooth=True)
    b.tube((0.030,0.010,0.100),(0.018,0.012,0.068),0.005,0.004,6,'paint_navy',cap0=True,cap1=True,smooth=True)
    b.tube((-0.050,0,0.055),(-0.075,0.008,0.020),0.007,0.003,6,'paint_navy',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0,0.05,0.008),hi,w=0.024,h=0.006)
    b.cbox((0,0,0),(0.20,0.10,0.17))

def statue_bust(b, hi=False):
    # smoother head and sloping shoulders; remaining budget goes into segments
    se=sg(hi,14,18)
    b.tube((0,0,0.0),(0,0,0.016),0.072,0.072,se,'walnut',cap0=True,cap1=True,smooth=True)
    b.tube((0,0,0.016),(0,0,0.050),0.046,0.044,se,'walnut',cap0=False,cap1=True,smooth=True)
    b.box((0,-0.046,0.028),(0.050,0.005,0.012),'brass')
    # chest as a tapered mass, not a box
    b.tube((0,0.000,0.050),(0,0.008,0.115),0.078,0.055,se,'plaster',cap0=False,cap1=False,smooth=True)
    b.tube((-0.055,0.000,0.090),(-0.078,0.006,0.108),0.028,0.016,sg(hi,10,12),'plaster',cap0=True,cap1=True,smooth=True)
    b.tube(( 0.055,0.000,0.090),( 0.078,0.006,0.108),0.028,0.016,sg(hi,10,12),'plaster',cap0=True,cap1=True,smooth=True)
    b.tube((0,0.006,0.112),(0,0.010,0.155),0.020,0.018,se,'plaster',cap0=False,cap1=False,smooth=True)
    # ball-like head
    b.tube((0,0.010,0.155),(0,0.012,0.210),0.032,0.038,se,'plaster',cap0=False,cap1=False,smooth=True)
    b.tube((0,0.012,0.210),(0,0.010,0.255),0.038,0.024,se,'plaster',cap0=False,cap1=True,smooth=True)
    b.tube((0,-0.028,0.215),(0,-0.032,0.225),0.022,0.018,sg(hi,8,10),'plaster',cap0=True,cap1=True,smooth=True)
    b.tube((0,-0.032,0.200),(0,-0.048,0.208),0.008,0.005,sg(hi,6,8),'plaster',cap0=True,cap1=True,smooth=True)
    b.tube((0,0.018,0.215),(0,0.028,0.262),0.036,0.022,se,'paint_grey',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0,0.04,0.025),hi,w=0.04,h=0.010)
    b.cbox((0,0,0),(0.20,0.14,0.28))

def sculpture_organic(b, hi=False):
    b.tube((0,0,0.0),(0,0,0.025),0.07,0.068,sg(hi,10,14),'walnut',cap0=True,cap1=True,smooth=True)
    # biomorphic loop: two arms that meet, leaving a hole
    b.tube((0.02,0,0.03),(0.07,0.02,0.16),0.032,0.022,sg(hi,10,12),'stone',cap0=True,cap1=False,smooth=True)
    b.tube((0.07,0.02,0.16),(0.00,0.03,0.26),0.022,0.020,sg(hi,10,12),'stone',cap0=False,cap1=False,smooth=True)
    b.tube((0.00,0.03,0.26),(-0.06,0.00,0.16),0.020,0.022,sg(hi,10,12),'stone',cap0=False,cap1=False,smooth=True)
    b.tube((-0.06,0.00,0.16),(-0.02,-0.01,0.05),0.022,0.028,sg(hi,10,12),'stone',cap0=False,cap1=True,smooth=True)
    maker_plate(b,(0,0.05,0.02),hi,w=0.03,h=0.008)
    b.cbox((0,0,0),(0.20,0.14,0.28))

def sculpture_coral(b, hi=False):
    # tapered, slightly curved branches (two segments each)
    se=sg(hi,8,10); bse=sg(hi,6,8)
    b.tube((0,0,0.0),(0,0,0.016),0.065,0.060,se,'paint_sand',cap0=True,cap1=True,smooth=True)
    b.tube((0,0,0.016),(0.008,0.004,0.110),0.020,0.010,se,'ceramic_coral',cap0=True,cap1=False,smooth=True)
    for x0,y0,z0,x1,y1,z1,x2,y2,z2,r0,r1,r2 in (
        (0.008,0.004,0.080,  0.050,0.020,0.140,  0.070,0.030,0.200, 0.009,0.006,0.002),
        (0.008,0.004,0.070,  0.040,-0.030,0.130, 0.060,-0.040,0.180, 0.008,0.005,0.002),
        (0.000,0.004,0.090, -0.040,0.020,0.150, -0.050,0.040,0.210, 0.009,0.006,0.002),
        (0.000,0.004,0.060, -0.030,-0.030,0.120,-0.050,-0.020,0.170, 0.008,0.005,0.002),
        (0.008,0.004,0.100,  0.020,0.010,0.160,  0.030,0.000,0.220, 0.007,0.004,0.002),
    ):
        b.tube((x0,y0,z0),(x1,y1,z1),r0,r1,bse,'ceramic_coral',cap0=True,cap1=False,smooth=True)
        b.tube((x1,y1,z1),(x2,y2,z2),r1,r2,bse,'ceramic_coral',cap0=False,cap1=True,smooth=True)
    maker_plate(b,(0,0.06,0.01),hi,w=0.024,h=0.006)
    b.cbox((0,0,0),(0.18,0.14,0.24))

# ------------------------------------------------------------------ plates, books, globe, basket, decanter

def wall_plate_fish(b, hi=False):
    R=0.14; cz=R
    disc_xz(b,0,-0.008,cz,R-0.012,sg(hi,16,22),'ceramic_teal')
    disc_xz(b,0, 0.010,cz,R-0.012,sg(hi,16,22),'ceramic_white')
    ring_xz(b,0,0,cz,R-0.004,0.012,sg(hi,14,18),'ceramic_white',hi)
    # stylised fish, readable in 3/4
    y=-0.012
    b.quad([Vector((0.07,y,cz)),Vector((0.02,y,cz+0.038)),
            Vector((-0.05,y,cz)),Vector((0.02,y,cz-0.032))],'paint_navy')
    b.quad([Vector((-0.05,y,cz)),Vector((-0.105,y,cz+0.038)),
            Vector((-0.08,y,cz)),Vector((-0.105,y,cz-0.038))],'paint_navy')
    # dorsal fin
    b.quad([Vector((0.00,y,cz+0.030)),Vector((0.02,y,cz+0.058)),
            Vector((-0.02,y,cz+0.048)),Vector((-0.03,y,cz+0.018))],'paint_navy')
    disc_xz(b,0.04,y-0.002,cz+0.008,0.008,8,'paint_cream')
    pq(b,-0.01,0.05,cz-0.006,cz+0.006,y-0.001,'paint_mustard')
    # hanger
    b.tube((0,0.0,2*R-0.01),(0,0.0,2*R+0.015),0.004,0.004,sg(hi,6,8),'steel',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0,0.0,0.03),hi,w=0.024,h=0.006)
    b.ccyl((0,0,0),R+0.01,2*R+0.02)

def wall_plate_floral(b, hi=False):
    R=0.12; cz=R
    disc_xz(b,0,-0.008,cz,R-0.012,sg(hi,16,22),'paint_cream')
    disc_xz(b,0, 0.010,cz,R-0.012,sg(hi,16,22),'ceramic_white')
    ring_xz(b,0,0,cz,R-0.004,0.012,sg(hi,14,18),'gilt',hi)
    # three flowers
    for a,r in ((90,0.035), (210,0.03), (330,0.03)):
        cx=0.04*math.cos(math.radians(a)); czz=cz+0.04*math.sin(math.radians(a))
        disc_xz(b,cx,-0.012,czz,r,8,'paint_coral')
        disc_xz(b,cx,-0.014,czz,r*0.4,6,'paint_mustard')
    b.tube((0,0.0,2*R-0.01),(0,0.0,2*R+0.015),0.004,0.004,sg(hi,6,8),'steel',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0,0.0,0.03),hi,w=0.024,h=0.006)
    b.ccyl((0,0,0),R+0.01,2*R+0.02)

def _book(b, c, w,d,h, spine, hi=False, rz=0.0):
    x,y,z=c
    b.box((x,y,z+h*0.5),(w,d,h),spine,rz=rz)
    # page edge (front, +Y or -Y depending)
    b.box((x, y - d*0.5 + 0.004, z+h*0.5),(w-0.01,0.006,h-0.008),'paper',rz=rz)
    # headband
    b.box((x, y, z+h-0.004),(w-0.004,d-0.004,0.006),'linen_mustard',rz=rz)

def bookends(b, hi=False):
    # two brass L-ends and a short run of books
    for s,x in ((-1,-0.11),(1,0.11)):
        b.box((x,0,0.01),(0.04,0.16,0.02),'brass')             # foot
        b.box((x+s*0.01,0,0.11),(0.02,0.16,0.20),'brass')       # upright
        # simple horse-head silhouette on the outside
        b.tube((x+s*0.02,0,0.20),(x+s*0.04,0.0,0.24),0.02,0.014,sg(hi,8,10),'brass',cap0=True,cap1=True,smooth=True)
        b.tube((x+s*0.04,0,0.24),(x+s*0.06,-0.01,0.25),0.014,0.010,sg(hi,6,8),'brass',cap0=False,cap1=True,smooth=True)
    _book(b,(-0.05,0,0.02),0.04,0.14,0.20,'spine_navy',hi)
    _book(b,(-0.01,0.005,0.02),0.036,0.135,0.18,'spine_red',hi)
    _book(b,(0.03,0.0,0.02),0.04,0.14,0.22,'spine_green',hi)
    maker_plate(b,(0,0.08,0.03),hi,w=0.03,h=0.008)
    b.cbox((0,0,0),(0.30,0.18,0.26))

def books_stack(b, hi=False):
    _book(b,(0,0,0.0),0.22,0.16,0.04,'spine_navy',hi,rz=8)
    _book(b,(0.01,0.01,0.04),0.20,0.15,0.045,'spine_red',hi,rz=-6)
    _book(b,(-0.01,0.0,0.085),0.21,0.155,0.05,'spine_green',hi,rz=4)
    # bookmark
    b.box((0.08,0.0,0.135),(0.012,0.002,0.04),'linen_mustard')
    maker_plate(b,(0,0.08,0.02),hi,w=0.024,h=0.006)
    b.cbox((0,0,0),(0.24,0.20,0.15))

def globe_desktop(b, hi=False):
    # stand
    for a in (0,120,240):
        ca,sa=math.cos(math.radians(a)),math.sin(math.radians(a))
        b.tube((0.02*ca,0.02*sa,0.0),(0.07*ca,0.07*sa,0.01),0.008,0.008,sg(hi,6,8),'brass',cap0=True,cap1=True,smooth=True)
        b.tube((0.07*ca,0.07*sa,0.01),(0.02*ca,0.02*sa,0.05),0.006,0.006,sg(hi,6,8),'brass',cap0=True,cap1=True,smooth=True)
    b.tube((0,0,0.05),(0,0,0.08),0.02,0.016,sg(hi,8,10),'brass',cap0=True,cap1=True,smooth=True)
    # meridian ring (XZ + a bit of tilt via points) and axis
    cz=0.20
    ring_xz(b,0,0,cz,0.12,0.004,sg(hi,14,18),'brass',hi)
    b.tube((0,0,cz-0.13),(0,0,cz+0.13),0.004,0.004,sg(hi,6,8),'brass',cap0=True,cap1=True,smooth=True)
    # sphere — UV, ocean + a few land patches
    su,sv=sg(hi,12,16),sg(hi,8,10)
    r=0.11
    verts=[]
    for j in range(sv+1):
        ph=math.pi*j/sv
        for i in range(su):
            th=2*math.pi*i/su
            verts.append(Vector((r*math.sin(ph)*math.cos(th), r*math.sin(ph)*math.sin(th), cz+r*math.cos(ph))))
    def vid(j,i): return j*su + (i%su)
    north=Vector((0,0,cz+r)); south=Vector((0,0,cz-r))
    pi_n=len(verts); pi_s=len(verts)+1
    verts.extend([north,south])
    ocean=[]; land=[]; ouv=[]; luv=[]
    def add(face,uv,is_land):
        if is_land: land.append(face); luv.append(uv)
        else: ocean.append(face); ouv.append(uv)
    for j in range(sv):
        for i in range(su):
            th=2*math.pi*(i+0.5)/su; ph=math.pi*(j+0.5)/sv
            # irregular land masses (not square patches)
            is_land=False
            for th0,ph0,rth,rph in (
                (0.70,1.20,0.55,0.70),  # Americas-ish
                (0.85,1.70,0.35,0.40),
                (3.40,1.10,0.70,0.65),  # Afro-Eurasia-ish
                (3.80,1.55,0.55,0.45),
                (4.20,1.00,0.35,0.35),
                (5.10,1.40,0.40,0.30),  # Pacific-ish
            ):
                dth=min(abs(th-th0), 2*math.pi-abs(th-th0))/max(rth,1e-6)
                dph=abs(ph-ph0)/max(rph,1e-6)
                if dth*dth+dph*dph < 1.0: is_land=True; break
            if j==0:
                add((pi_n, vid(1,i), vid(1,i+1)),
                    [(0.5,0),(i/su,1/sv),((i+1)/su,1/sv)], is_land)
            elif j==sv-1:
                add((vid(sv-1,i), vid(sv-1,i+1), pi_s),
                    [(i/su,(sv-1)/sv),((i+1)/su,(sv-1)/sv),(0.5,1)], is_land)
            else:
                a,b_,c,d=vid(j,i),vid(j,i+1),vid(j+1,i+1),vid(j+1,i)
                add((a,b_,c,d),[(i/su,j/sv),((i+1)/su,j/sv),((i+1)/su,(j+1)/sv),(i/su,(j+1)/sv)], is_land)
    if ocean: b.faces(verts,ocean,'paint_navy',ouv,smooth=True)
    if land: b.faces(verts,land,'paint_olive',luv,smooth=True)
    # cartouche plate
    b.box((0, -0.12, 0.06),(0.04,0.004,0.016),'brass')
    maker_plate(b,(0,0.06,0.04),hi,w=0.03,h=0.008)
    b.ccyl((0,0,0),0.13,0.34)

def decanter(b, hi=False):
    # faceted body (unsmoothed)
    seg=sg(hi,8,10)
    b.tube((0,0,0.0),(0,0,0.015),0.04,0.045,seg,'glass',cap0=True,cap1=False,smooth=False)
    b.tube((0,0,0.015),(0,0,0.12),0.055,0.050,seg,'glass',cap0=False,cap1=False,smooth=False)
    b.tube((0,0,0.12),(0,0,0.18),0.050,0.018,seg,'glass',cap0=False,cap1=False,smooth=False)
    # neck ring + neck
    b.tube((0,0,0.18),(0,0,0.195),0.022,0.022,seg,'brass',cap0=True,cap1=True,smooth=True)
    b.tube((0,0,0.195),(0,0,0.24),0.016,0.018,seg,'glass',cap0=False,cap1=False,smooth=True)
    # pour lip + stopper
    b.tube((0,0,0.24),(0,0,0.25),0.018,0.022,seg,'glass',cap0=False,cap1=True,smooth=True)
    b.tube((0,0,0.25),(0,0,0.28),0.012,0.008,seg,'glass',cap0=False,cap1=True,smooth=True)
    maker_plate(b,(0,0.05,0.02),hi,w=0.024,h=0.007)
    b.ccyl((0,0,0),0.06,0.28)

def woven_basket(b, hi=False):
    # Solid rattan vessel: weave lives in the trim; hoops, rim and handles keep the silhouette.
    seg=sg(hi,12,16)
    b.tube((0,0,0.0),(0,0,0.012),0.09,0.09,seg,'rattan',cap0=True,cap1=False,smooth=True)
    b.tube((0,0,0.012),(0,0,0.18),0.09,0.13,seg,'rattan',cap0=False,cap1=False,smooth=True)
    # inner well (opaque)
    b.tube((0,0,0.012),(0,0,0.17),0.078,0.118,seg,'rattan',cap0=True,cap1=False,smooth=True)
    # raised hoops
    for z,r in ((0.06,0.108),(0.12,0.122)):
        b.tube((0,0,z-0.006),(0,0,z+0.006),r,r,seg,'rattan',cap0=False,cap1=False,smooth=True)
    # rim wrap
    b.tube((0,0,0.18),(0,0,0.20),0.13,0.138,seg,'rattan',cap0=False,cap1=True,smooth=True)
    # handles
    for s in (-1,1):
        b.tube((s*0.10,0,0.20),(s*0.13,0,0.26),0.009,0.009,sg(hi,6,8),'rattan',cap0=True,cap1=False,smooth=True)
    b.tube((-0.13,0,0.26),(0.13,0,0.26),0.009,0.009,sg(hi,6,8),'rattan',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0,0.12,0.04),hi,w=0.03,h=0.008)
    b.ccyl((0,0,0),0.15,0.27)

# ------------------------------------------------------------------ materials + registry

PM=(0.875,0.875)
TR={
    'walnut':('th_walnut',PM),'teak':('th_walnut',PM),'wash':('th_wash',PM),'oak_light':('th_wash',PM),
    'paint_cream':('th_paint',PM),'paint_white':('th_paint',PM),'paint_black':('th_paint',PM),
    'paint_navy':('th_paint',PM),'paint_mustard':('th_paint',PM),'paint_olive':('th_paint',PM),
    'paint_coral':('th_paint',PM),'paint_aqua':('th_paint',PM),'paint_sand':('th_paint',PM),
    'paint_red':('th_paint',PM),'paint_orange':('th_paint',PM),'paint_grey':('th_paint',PM),
    'linen':('th_linen',PM),'linen_sand':('th_linen',PM),'linen_olive':('th_linen',PM),'linen_mustard':('th_linen',PM),
    'steel':('th_metal',PM),'chrome':('th_metal',PM),'brass':('th_brass',PM),'gilt':('th_brass',PM),
    'ceramic':('th_ceramic',PM),'ceramic_white':('th_ceramic',PM),'ceramic_teal':('th_ceramic',PM),
    'ceramic_coral':('th_ceramic',PM),'ceramic_lava':('th_ceramic',PM),
    'glass':('th_glass',PM),'mirror':('th_glass',PM),
    'rattan':('th_rattan',PM),'stone':('th_stone',PM),'plaster':('th_stone',PM),
    'wax':('th_paint',PM),'leather':('th_walnut',PM),'paper':('th_paint',PM),
    'spine_navy':('th_paint',PM),'spine_red':('th_paint',PM),'spine_green':('th_paint',PM),
    'art_seascape':('art_seascape',PM),'art_hotel':('art_hotel',PM),'art_palms':('art_palms',PM),
    'art_mcm':('art_mcm',PM),'art_botanical':('art_botanical',PM),'art_surf':('art_surf',PM),
    'art_floral':('art_floral',PM),'art_portrait':('art_portrait',PM),
}
TINT={
    'walnut':(1.00,1.00,1.00),'teak':(1.15,0.95,0.70),'wash':(1.00,1.00,1.00),'oak_light':(1.05,0.98,0.88),
    'paint_cream':(1.04,1.00,0.92),'paint_white':(1.10,1.10,1.08),'paint_black':(0.12,0.12,0.12),
    'paint_navy':(0.12,0.16,0.32),'paint_mustard':(0.90,0.68,0.16),'paint_olive':(0.32,0.38,0.22),
    'paint_coral':(0.78,0.32,0.28),'paint_aqua':(0.40,0.62,0.62),'paint_sand':(0.86,0.78,0.62),
    'paint_red':(0.62,0.10,0.08),'paint_orange':(0.95,0.42,0.06),'paint_grey':(0.28,0.29,0.31),
    'linen':(1.00,1.00,1.00),'linen_sand':(1.05,0.98,0.85),'linen_olive':(0.55,0.58,0.36),'linen_mustard':(0.95,0.72,0.28),
    'steel':(1.00,1.00,1.00),'chrome':(1.15,1.16,1.18),'brass':(1.00,1.00,1.00),'gilt':(1.18,1.02,0.62),
    'ceramic':(1.00,1.00,1.00),'ceramic_white':(1.08,1.07,1.04),'ceramic_teal':(0.35,0.55,0.52),
    'ceramic_coral':(0.85,0.40,0.32),'ceramic_lava':(0.22,0.14,0.12),
    'glass':(1.00,1.00,1.00),'mirror':(1.20,1.28,1.36),
    'rattan':(1.15,1.10,1.00),'stone':(1.00,1.00,1.00),'plaster':(1.06,1.04,0.98),
    'wax':(1.08,1.04,0.92),'leather':(0.70,0.40,0.28),'paper':(1.12,1.10,1.02),
    'spine_navy':(0.14,0.16,0.32),'spine_red':(0.50,0.12,0.10),'spine_green':(0.18,0.32,0.22),
}

_C=dict(dir='props/house/decor',pdir='house_decor',trim=TR,trim_tint=TINT,page='h',
        conds=['clean'],cat='prop',max_side=80,bevel=0.003)
def _p(name,fn,cls,budget=None,**kw):
    d=dict(_C,name=name,near=lambda b,fn=fn: fn(b,False),high=lambda b,fn=fn: fn(b,True),cls=cls,**kw)
    if budget is not None: d['budget']=budget
    return d

PROPS=[
    _p('frame_print_small',frame_print_small,'tiny',250,mount='wall'),
    _p('frame_print_medium',frame_print_medium,'small',400,mount='wall'),
    _p('frame_print_large',frame_print_large,'small',500,mount='wall'),
    _p('frame_print_tall',frame_print_tall,'small',400,mount='wall'),
    _p('frame_ocean',frame_ocean,'small',450,mount='wall'),
    _p('frame_mcm_abstract',frame_mcm_abstract,'small',450,mount='wall'),
    _p('frame_motel_floral',frame_motel_floral,'small',450,mount='wall'),
    _p('frame_stand_photo',frame_stand_photo,'tiny',220,shift=(0,-0.085)),
    _p('mirror_round',mirror_round,'small',550,mount='wall'),
    _p('mirror_rect',mirror_rect,'small',500,mount='wall'),
    _p('clock_wall_sunburst',clock_wall_sunburst,'small',550,mount='wall'),
    _p('clock_mantel',clock_mantel,'small',520),  # raised from 400, still under cap 600
    _p('vase_tall',vase_tall,'small',350),
    _p('vase_bud',vase_bud,'tiny',180),
    _p('vase_ginger',vase_ginger,'small',400),
    _p('vase_lava',vase_lava,'tiny',260),
    _p('bowl_ceramic',bowl_ceramic,'tiny',250),
    _p('bowl_wood',bowl_wood,'tiny',250),
    _p('bowl_shell',bowl_shell,'tiny',260),  # raised from 220, still under cap 300
    _p('decorative_tray',decorative_tray,'tiny',220),
    _p('candle_pair_brass',candle_pair_brass,'tiny',280),
    _p('candle_pillar',candle_pillar,'tiny',180),
    _p('hurricane_lamp',hurricane_lamp,'small',400),
    _p('figurine_bird',figurine_bird,'tiny',260),
    _p('figurine_cat',figurine_cat,'tiny',280),
    _p('figurine_horse',figurine_horse,'tiny',290),
    _p('statue_bust',statue_bust,'small',450),
    _p('sculpture_organic',sculpture_organic,'small',450),
    _p('sculpture_coral',sculpture_coral,'tiny',280),
    _p('wall_plate_fish',wall_plate_fish,'tiny',250,mount='wall'),
    _p('wall_plate_floral',wall_plate_floral,'tiny',250,mount='wall'),
    _p('bookends',bookends,'small',450),
    _p('globe_desktop',globe_desktop,'small',550),
    _p('books_stack',books_stack,'tiny',250),
    _p('decanter',decanter,'tiny',280),
    _p('woven_basket',woven_basket,'small',400),
]
INDOOR_LOOK=True
