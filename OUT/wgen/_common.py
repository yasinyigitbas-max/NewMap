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
