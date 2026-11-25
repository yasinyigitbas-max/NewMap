import struct, zlib, sys
def parse(path):
    d=open(path,'rb').read()
    ver=struct.unpack_from('<I',d,23)[0]
    big=ver>=7500
    def node(o):
        if big:
            end,nprop,plen=struct.unpack_from('<QQQ',d,o); o+=24
        else:
            end,nprop,plen=struct.unpack_from('<III',d,o); o+=12
        nl=d[o]; o+=1
        name=d[o:o+nl].decode('latin1'); o+=nl
        if end==0: return None,o
        props=[]
        for _ in range(nprop):
            t=chr(d[o]); o+=1
            if t in 'YCIFDL':
                fmt={'Y':'<h','C':'<b','I':'<i','F':'<f','D':'<d','L':'<q'}[t]
                props.append(struct.unpack_from(fmt,d,o)[0]); o+=struct.calcsize(fmt)
            elif t in 'fdlib':
                n,enc,cl=struct.unpack_from('<III',d,o); o+=12
                raw=d[o:o+cl]; o+=cl
                if enc: raw=zlib.decompress(raw)
                fmt={'f':'f','d':'d','l':'q','i':'i','b':'b'}[t]
                props.append(list(struct.unpack('<%d%s'%(n,fmt),raw)))
            elif t in 'SR':
                n=struct.unpack_from('<I',d,o)[0]; o+=4
                props.append(d[o:o+n].decode('latin1') if t=='S' else d[o:o+n]); o+=n
            else: raise Exception(t)
        kids=[]
        sent=25 if big else 13
        while o<end:
            k,o=node(o)
            if k is None: break
            kids.append(k)
        return (name,props,kids),end
    o=27; top=[]
    while o<len(d)-200:
        n,o=node(o)
        if n is None: break
        top.append(n)
    return ver,top
def find(nodes,name): return [n for n in nodes if n[0]==name]
def main(p):
    ver,top=parse(p)
    T={n[0]:n for n in top}
    print('FBX version',ver)
    for n in T['FBXHeaderExtension'][2]:
        if n[0] in('Creator',): print(n[0],n[1])
        if n[0]=='SceneInfo':
            for k in n[2]:
                if k[0]=='Properties70':
                    for pp in k[2]:
                        if 'Application' in str(pp[1][0]) or 'Original' in str(pp[1][0]): print('  ',pp[1])
    for k in T['GlobalSettings'][2]:
        if k[0]=='Properties70':
            for pp in k[2]: print('  GS',pp[1])
    objs={}
    for n in T['Objects'][2]:
        objs[n[1][0]]=(n[0],n[1][1].split('\x00')[0],n[1][2],n)
    par={}; conns=[]
    for c in T['Connections'][2]:
        conns.append(c[1])
    return ver,T,objs,conns
if __name__=='__main__':
    ver,T,objs,conns=main(sys.argv[1])
    models={i:o for i,o in objs.items() if o[0]=='Model'}
    par={}
    for c in conns:
        if c[0]=='OO' and c[1] in models and (c[2] in models or c[2]==0): par[c[1]]=c[2]
    kids={}
    for c,p in par.items(): kids.setdefault(p,[]).append(c)
    def lcl(n):
        r={}
        for k in n[2]:
            if k[0]=='Properties70':
                for pp in k[2]:
                    if pp[1][0] in('Lcl Translation','Lcl Rotation','Lcl Scaling','PreRotation','RotationOrder','InheritType'): r[pp[1][0]]=[round(x,3) if isinstance(x,float) else x for x in pp[1][4:]]
        return r
    cnt=[0]
    def walk(i,dep):
        o=models[i]; 
        if o[2]=='LimbNode': cnt[0]+=1
        print('  '*dep+o[1],'['+o[2]+']',lcl(o[3]) if '-v' in sys.argv else '')
        for k in kids.get(i,[]): walk(k,dep+1)
    for i in models:
        if par.get(i,0) not in models: walk(i,0)
    print('LimbNode count',cnt[0], 'Model count',len(models))
    # animation
    cn={i:o for i,o in objs.items() if o[0]=='AnimationCurveNode'}
    cv={i:o for i,o in objs.items() if o[0]=='AnimationCurve'}
    print('AnimStacks',[ (o[1],) for o in objs.values() if o[0]=='AnimationStack'])
    for o in objs.values():
        if o[0]=='AnimationStack':
            for k in o[3][2]:
                if k[0]=='Properties70':
                    for pp in k[2]: print('  stack',pp[1])
    tgt={}
    for c in conns:
        if c[0]=='OP' and c[1] in cn and c[2] in models:
            tgt.setdefault(models[c[2]][1],[]).append(c[3])
    from collections import Counter
    print('curve nodes',len(cn),'curves',len(cv))
    print('channel pattern counts',Counter(tuple(sorted(v)) for v in tgt.values()))
    print('bones with translation keyed',len([k for k,v in tgt.items() if 'Lcl Translation' in v]))
    print('models without any curve',[o[1] for i,o in models.items() if o[1] not in tgt])
    # key counts & hips translation range
    cvpar={}
    for c in conns:
        if c[0]=='OP' and c[1] in cv and c[2] in cn: cvpar[c[1]]=(c[2],c[3])
    cnmodel={}
    for c in conns:
        if c[0]=='OP' and c[1] in cn and c[2] in models: cnmodel[c[1]]=(models[c[2]][1],c[3])
    kc=Counter()
    for i,o in cv.items():
        n=o[3]; kt=[k for k in n[2] if k[0]=='KeyTime'][0][1][0]; kv=[k for k in n[2] if k[0]=='KeyValueFloat'][0][1][0]
        kc[len(kt)]+=1
        m=cnmodel.get(cvpar.get(i,(0,))[0])
        if m and m[0].endswith('Hips') and m[1]=='Lcl Translation':
            print('Hips T',cvpar[i][1],'keys',len(kt),'min',round(min(kv),2),'max',round(max(kv),2),'first',round(kv[0],2),'last',round(kv[-1],2),'dt(s)',round((kt[1]-kt[0])/46186158000,5) if len(kt)>1 else None,'dur',round((kt[-1]-kt[0])/46186158000,3))
    print('keycount histogram',kc.most_common(8))
