# shared snippets for west-fill specs (text only)
def tables(pts, reason, chairs=True):
    s=''
    for (x,z) in pts:
        s+='\tc.put("prop_cafe_table", "worn", c.gp(%.1f, %.1f), 0.0, "%s")\n'%(x,z,reason)
        if chairs:
            s+='\tc.put("prop_cafe_chair", "worn", c.gp(%.1f, %.1f), 90.0, "%s: a chair at its table", false)\n'%(x-0.8,z,reason.split(':')[0])
            s+='\tc.put("prop_cafe_chair", "worn", c.gp(%.1f, %.1f), -90.0, "%s: a chair at its table", false)\n'%(x+0.8,z,reason.split(':')[0])
    return s
def put(base, x, z, yaw, reason, cond='worn'):
    return '\tc.put("%s", "%s", c.gp(%.2f, %.2f), %.1f, "%s")\n'%(base,cond,x,z,yaw,reason)
def stalls_row(x0, x1, z, yaw, skip=()):
    s=''; x=x0
    while x<=x1+1e-6:
        if not any(a<=x<=b for a,b in skip): s+='\tc.stalls.append([%.2f, %.2f, %.1f, c.yf(%.2f, %.2f)])\n'%(x,z,yaw,x,z)
        x+=2.7
    return s
def stalls_col(x, z0, z1, yaw, skip=()):
    s=''; z=z0
    while z<=z1+1e-6:
        if not any(a<=z<=b for a,b in skip): s+='\tc.stalls.append([%.2f, %.2f, %.1f, c.yf(%.2f, %.2f)])\n'%(x,z,yaw,x,z)
        z+=2.7
    return s
def wear(x0,z0,x1,z1,n=10): return '\tc.cracks(%.1f, %.1f, %.1f, %.1f, %d, 0.5)\n'%(x0,z0,x1,z1,n)
def tyre(x,z,yaw,l=6.0,a=0.45): return '\tc.tyre(Vector2(%.1f, %.1f), %.1f, %.1f, %.2f)\n'%(x,z,yaw,l,a)
def oil(x,z,yaw=0.0): return '\tc.oil(Vector2(%.1f, %.1f), %.1f)\n'%(x,z,yaw)
def chain(pts, side, at, gap, reason, gate="fence_gate_rolling_chainlink", kind="chainlink"):
    return '\tc.ring_fence("%s", [%s], %d, %.2f, %.2f, "%s", "%s")\n'%(kind, ', '.join('Vector2(%.2f, %.2f)'%p for p in pts), side, at, gap, gate, reason)

FP={'beach_blue':(8.6,12.1),'beach_large':(11.5,17.2),'beach_teal':(9.1,11.1),'beach_white':(8.1,12.1),'cape_grey':(9.9,9.7),'cape_large':(10.8,19.6),
 'cape_white':(10.4,9.7),'colonial_blue':(13.0,11.2),'colonial_large_garage':(13.6,17.1),'colonial_white':(12.0,10.7),'contemporary_grey':(12.2,12.2),
 'contemporary_white':(11.2,13.2),'craftsman_cedar':(11.4,15.4),'craftsman_large':(11.9,18.5),'craftsman_olive':(11.4,15.9),'craftsman_sage':(11.4,15.9),
 'craftsman_stucco':(11.4,15.4),'hipranch_grey':(13.0,10.9),'hipranch_nogarage':(11.1,10.4),'hipranch_sand':(12.0,10.4),'mcm_large':(13.5,17.8),
 'mcm_shed':(14.2,11.5),'mcm_teal':(14.0,11.0),'mcm_white':(14.5,11.5),'narrow_2sty_siding':(8.0,16.6),'narrow_2sty_stucco_clay':(8.2,15.9),
 'narrow_cottage_siding':(6.4,15.9),'narrow_cottage_stucco_clay':(6.3,15.4),'ranch_peach':(11.6,11.0),'ranch_pink':(10.1,11.0),'ranch_porch':(10.6,11.0),
 'ranch_siding':(10.6,10.5),'spanish_large':(11.7,17.0),'spanish_peach':(12.6,11.9),'spanish_pink':(13.1,11.8),'spanish_small':(8.3,10.1),
 'spanish_white':(12.6,11.9),'tudor_brick':(12.4,11.6),'tudor_stucco':(12.9,11.1),'victorian_blue':(11.6,15.1),'victorian_yellow':(11.6,15.1)}
YARD=[('prop_bbq_kettle','a grill on the patio'),('prop_patio_set_4','the patio table'),('prop_clothesline','washing on the line'),
      ('prop_adirondack_wood','a chair on the lawn facing the sun'),('prop_swing_set','the kids\' swings'),('prop_bbq_gas_cart','the gas grill'),
      ('prop_adirondack_white','a chair on the lawn'),('prop_picnic_table','a table in the yard')]
def V2(face, al, dp):
    # (along, depth) -> local (x, z)
    return (al, dp) if face in 'ns' else (dp, al)
def houses(tag, face, front, a0, a1, models, rear, seed=0, pad=True):
    """A row of houses on lots between a0..a1 along the street, fronts on `front` (z for n/s, x for e/w), back yards
    closed by fences to a rear fence at `rear` (a gate onto the parking pad between the rear fence and the lane)."""
    n=len(models); lot=(a1-a0)/n
    sgn = 1.0 if face in ('n','w') else -1.0          # the body extends from the front toward +depth for n / w
    sites=[]; paints=[]; body=''
    lines=[a0+i*lot for i in range(n+1)]
    for i,m in enumerate(models):
        w,d=FP[m]; ac=a0+(i+0.5)*lot
        sites.append(('houses/'+m, *V2(face, ac, front), face, '%s_%d'%(tag,i)))
        back=front+sgn*d
        zr=rear-sgn*6.0 if pad else rear                 # rear fence line (pad between it and the lane)
        hl=ac-w/2; hr=ac+w/2; la=lines[i]+0.3; lb=lines[i+1]-0.3
        def F(p,q,why): return '\tc.privacy(Vector2(%.2f, %.2f), Vector2(%.2f, %.2f), "%s")\n'%(p[0],p[1],q[0],q[1],why)
        bk=front+sgn*d*0.5      # the yard's side fences leave the house at its mid-depth (their ends inside the walls)
        body+=F(V2(face,hl+1.0,bk),V2(face,la,bk),'yard: the side fence from the house wall to the lot line')
        body+=F(V2(face,hr-1.0,bk),V2(face,lb,bk),'yard: the side fence from the house wall to the lot line')
        body+=F(V2(face,la,bk),V2(face,la,zr),'yard: the lot-line fence')
        body+=F(V2(face,lb,bk),V2(face,lb,zr),'yard: the lot-line fence')
        gc=ac+(lot*0.25 if i%2==0 else -lot*0.25)
        body+=F(V2(face,la,zr),V2(face,gc-0.6,zr),'yard: the rear fence')
        body+=F(V2(face,gc+0.6,zr),V2(face,lb,zr),'yard: the rear fence')
        g=V2(face,gc,zr); yaw=0.0 if face in 'ns' else 90.0
        if pad: body+='\tc.put("fence_gate_privacy", "worn", Vector3(%.2f, c.yf(%.2f, %.2f), %.2f), %.1f, "yard: the gate to the parking pad", false)\n'%(g[0],g[0],g[1],g[1],yaw)
        else: body+=F(V2(face,gc-0.6,zr),V2(face,gc+0.6,zr),'yard: the rear fence')
        if pad:
            p0=V2(face,gc-2.6,zr+sgn*0.4); p1=V2(face,gc+2.6,rear)
            paints.append(('concrete',min(p0[0],p1[0]),min(p0[1],p1[1]),max(p0[0],p1[0]),max(p0[1],p1[1]),'%s %d: the parking pad off the lane'%(tag,i)))
            sp=V2(face,gc,(zr+rear)/2); body+='\tc.stalls.append([%.2f, %.2f, %.1f, c.yf(%.2f, %.2f)])\n'%(sp[0],sp[1],0.0 if face in 'ns' else 90.0,sp[0],sp[1])
            body+='\tc.oil(Vector2(%.2f, %.2f), %.1f)\n'%(sp[0],sp[1],0.0 if face in 'ns' else 90.0)
        for k in range(2):
            it=YARD[(seed+i*3+k*5)%len(YARD)]
            yp=V2(face, ac+(-0.22 if k==0 else 0.22)*lot, (back+zr)/2+sgn*(k-0.5)*2.0)
            body+='\tc.put("%s", "worn", c.gp(%.2f, %.2f), %.1f, "back yard: %s")\n'%(it[0],yp[0],yp[1],(seed*37+i*61+k*90)%360,it[1])
        mb=V2(face, ac+w/2+1.2, front-sgn*0.6)
        body+='\tc.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(%.2f, %.2f), 0.0, "front: a pot by the walk")\n'%mb
    return sites, paints, body

def ring_block(name, U, V, hdr, doc, rows, lanes, extra_sites=(), extra_paints=(), extra_body='', wall=True, W=177.0, D=182.0):
    """the west strip's house blocks: rows = [(tag, face, front, a0, a1, models, rear, pad)], lanes = paints"""
    sites=list(extra_sites); paints=list(lanes)+list(extra_paints); body=''
    for k,(tag,face,front,a0,a1,models,rear,pad) in enumerate(rows):
        s,p,b=houses(tag,face,front,a0,a1,models,rear,seed=k*3+len(name),pad=pad); sites+=s; paints+=p; body+=b
    if False and wall: body+='\tc.cmu(Vector2(0.6, 0.6), Vector2(0.6, %.1f), "ring road: the sound wall along the back of the houses")\n'%(D-0.6)
    return dict(NAME=name,U=U,V=V,W=W,D=D,Y0=4.15,HDR=hdr,DOC=doc,SITES=sites,PAINTS=paints,BODY='\n'+body+extra_body,GRIME=0.4)
def lane_wear(x0,z0,x1,z1,along_z):
    return '\tc.alley_wear(%.1f, %.1f, %.1f, %.1f, %s)\n'%(x0,z0,x1,z1,'true' if along_z else 'false')
