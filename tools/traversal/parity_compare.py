# Compares the files tests/parity_run.gd wrote for the script version and the C++ version. usage: parity_compare.py <dir> <run name>...
import struct, sys, collections
S=sys.argv[1].rstrip('/')+'/'
def read(p):
    b=open(p,'rb').read(); out=[]; i=0
    while i<len(b):
        n=struct.unpack_from('<I',b,i)[0]; i+=4
        chunk=b[i:i+n]; i+=n
        cnt=struct.unpack_from('<I',chunk,4)[0]
        out.append(struct.unpack_from('<%dd'%cnt,chunk,8))
    return out
bad=0
for name in sys.argv[2:]:
    a=read(S+name+'_script.bin'); b=read(S+name+'_native.bin')
    same=open(S+name+'_script.bin','rb').read()==open(S+name+'_native.bin','rb').read()
    first=None; worst=0.0
    for t,(x,y) in enumerate(zip(a,b)):
        d=max(abs(p-q) for p,q in zip(x,y))
        if d>0 and first is None: first=(t,d,[i for i,(p,q) in enumerate(zip(x,y)) if p!=q])
        worst=max(worst,d)
    bad+=0 if same else 1
    print(name,': %d and %d ticks; byte for byte the same: %s; first tick that differs: %s; worst difference: %g'%(len(a),len(b),same,first,worst))
    print('   states',dict(collections.Counter(int(x[4]) for x in a)),' squeeze',dict(collections.Counter(int(x[11]) for x in a)),' narrow',dict(collections.Counter(int(x[10]) for x in a)),' stairs',dict(collections.Counter(int(x[12]) for x in a)),' terrain',dict(collections.Counter(int(x[13]) for x in a)))
    print('   crouched ticks',sum(1 for x in a if x[18]>0),' on-the-spot turn ticks',sum(1 for x in a if x[14]!=0),' jump push ticks',sum(1 for x in a if x[16]>0),' landing hold ticks',sum(1 for x in a if x[17]>0),' phone ticks',sum(1 for x in a if x[21]>0),' thinner shape ticks',sum(1 for x in a if x[15]<0.25))
print('PARITY RESULT PASS' if bad==0 else 'PARITY RESULT FAIL (%d runs differ)'%bad)
sys.exit(1 if bad else 0)
