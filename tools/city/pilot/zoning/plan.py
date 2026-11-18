import numpy as np
def ss(a,b,x):
    t=np.clip((x-a)/(b-a),0,1); return t*t*(3-2*t)
# locked samples: name, (u,v) centre, yaw, sample-frame rect x0,x1,z0,z1, label
SAMPLES=[
 ("P",(0,0),0,(-56,150,-100,100),"PILOT\nhigh street +\nhill rows"),
 ("C",(0,-560),0,(-59,59,-100,100),"CITY\nCENTRE"),
 ("A",(300,-560),0,(-102,102,-102,102),"APARTMENT\nBAND"),
 ("V",(-300,-660),0,(-102,102,-102,360),"CIVIC +\nPARKS\n\nSTADIUM"),
 ("G",(-700,-1050),0,(-102,102,-102,102),"GRITTY\nEDGE"),
 ("I",(-760,-1450),0,(-102,102,-102,102),"INDUSTRIAL"),
 ("M",(520,-1130),0,(-102,102,-102,102),"COMMERCIAL\nSTRIP"),
 ("W",(570,250),90,(-102,102,-102,40),"WATER-\nFRONT"),
]
def s2g(s,x,z):
    cu,cv=s[1]; a=np.radians(s[2])
    # godot yaw about +Y: x'=x cos+z sin, z'=-x sin+z cos
    return cu+x*np.cos(a)+z*np.sin(a), cv-x*np.sin(a)+z*np.cos(a)
def rect_g(s,pad=0):
    x0,x1,z0,z1=s[3]; x0-=pad;x1+=pad;z0-=pad;z1+=pad
    return [s2g(s,x,z) for x,z in [(x0,z0),(x1,z0),(x1,z1),(x0,z1)]]
def dist_rect(s,U,V):
    # distance from the sample rect in sample frame
    cu,cv=s[1]; a=np.radians(s[2]); du=U-cu; dv=V-cv
    x=du*np.cos(a)-dv*np.sin(a); z=du*np.sin(a)+dv*np.cos(a)
    x0,x1,z0,z1=s[3]
    dx=np.maximum(np.maximum(x0-x,x-x1),0); dz=np.maximum(np.maximum(z0-z,z-z1),0)
    return np.hypot(dx,dz)
BUF0,BUF1=40.0,220.0          # flat apron round every locked sample, hill starts beyond BUF0, full by BUF1
def bump(U,V,cu,cv,ru,rv,h):
    r=np.sqrt(((U-cu)/ru)**2+((V-cv)/rv)**2)
    return h*ss(0,1,1-r)
HILLS=[  # name, centre, semi-axes, height, label
 ("Crown Hill",(0,-1170),(400,330),12.0,"CROWN HILL\n(real 4-6 m dome, raised)"),
 ("Glorietta Heights",(310,-110),(210,330),7.0,"GLORIETTA\nHEIGHTS"),
 ("Country Club Ridge",(-640,20),(330,300),10.0,"COUNTRY CLUB\nRIDGE"),
 ("Bay Circle",(920,-330),(230,300),8.0,"BAY CIRCLE\nKNOLL"),
]
def pilot_hill(U,V):
    # the pilot's built-in rise (site.gd): level to x 40, smoothstep to +5.9 at x 150, kept east and faded north/south
    return 5.9*ss(40,150,U)*ss(-520,-200,V)*(1-ss(150,330,V))*(1-ss(430,560,U))
def field(U,V):
    h=np.zeros_like(U)
    for n,c,r,hh,_ in HILLS: h=np.maximum(h,bump(U,V,c[0],c[1],r[0],r[1],hh))
    h=np.maximum(h,pilot_hill(U,V))
    m=np.ones_like(U)
    for s in SAMPLES:
        if s[0]=="P": continue
        m=np.minimum(m,ss(BUF0,BUF1,dist_rect(s,U,V)))
    return h*m
# Yasin 17 Nov (red line on draft 1): the land is cut off south of the hotel, from the ocean beach to the waterfront
# quay's south end. Everything inside this world-frame polygon (x east, z south) becomes sea: the Silver Strand, the
# Shores and the amphibious base go; Coronado is an island reached by the bridge (and the ferry).
CUT=[(-2050,3880),(-1932,3871),(-1848,3947),(-1684,3942),(-1499,3924),(-1362,3859),(-1290,3900),(-1150,3980),
     (-600,4300),(-200,4250),(0,4000),(1200,4000),(1200,7400),(-2600,7400),(-2600,3880)]
