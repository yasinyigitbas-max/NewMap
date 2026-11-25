# Binary FBX round-trip reader / writer (keeps property types), enough to edit animation curves.
import struct, zlib
class Arr:
    def __init__(s, t, data): s.t, s.data = t, data
SC = {'Y':'<h','C':'<b','I':'<i','F':'<f','D':'<d','L':'<q'}
AR = {'f':'f','d':'d','l':'q','i':'i','b':'b'}
def read(path):
    d = open(path,'rb').read()
    ver = struct.unpack_from('<I', d, 23)[0]; big = ver >= 7500
    hs = 25 if big else 13
    def node(o):
        if big: end, nprop, plen = struct.unpack_from('<QQQ', d, o); o += 24
        else: end, nprop, plen = struct.unpack_from('<III', d, o); o += 12
        nl = d[o]; o += 1; name = d[o:o+nl]; o += nl
        if end == 0: return None, o
        props = []
        for _ in range(nprop):
            t = chr(d[o]); o += 1
            if t in SC:
                props.append((t, struct.unpack_from(SC[t], d, o)[0])); o += struct.calcsize(SC[t])
            elif t in AR:
                n, enc, cl = struct.unpack_from('<III', d, o); o += 12
                raw = d[o:o+cl]; o += cl
                if enc: raw = zlib.decompress(raw)
                props.append((t, list(struct.unpack('<%d%s' % (n, AR[t]), raw))))
            elif t in 'SR':
                n = struct.unpack_from('<I', d, o)[0]; o += 4
                props.append((t, d[o:o+n])); o += n
            else: raise Exception('type ' + t)
        kids = []; had_null = False
        while o < end:
            k, o = node(o)
            if k is None: had_null = True; break
            kids.append(k)
        return [name, props, kids, had_null], end
    o = 27; top = []
    while True:
        n, o = node(o)
        if n is None: break
        top.append(n)
    return dict(head=d[:27], ver=ver, top=top, tail=d[o:])
def write(doc, path):
    big = doc['ver'] >= 7500; out = bytearray(doc['head'])
    def node(n):
        name, props, kids, had_null = n
        pb = bytearray()
        for t, v in props:
            pb += t.encode()
            if t in SC: pb += struct.pack(SC[t], v)
            elif t in AR:
                raw = struct.pack('<%d%s' % (len(v), AR[t]), *v)
                if len(raw) > 128:
                    z = zlib.compress(raw); pb += struct.pack('<III', len(v), 1, len(z)) + z
                else: pb += struct.pack('<III', len(v), 0, len(raw)) + raw
            else: pb += struct.pack('<I', len(v)) + v
        start = len(out)
        out.extend(b'\0' * (24 if big else 12)); out.append(len(name)); out.extend(name); out.extend(pb)
        for k in kids: node(k)
        if kids or had_null: out.extend(b'\0' * (25 if big else 13))
        if big: struct.pack_into('<QQQ', out, start, len(out), len(props), len(pb))
        else: struct.pack_into('<III', out, start, len(out), len(props), len(pb))
    for n in doc['top']: node(n)
    out.extend(b'\0' * (25 if big else 13))
    # footer: keep the original id block, re-pad to 16 bytes as the format expects
    tail = doc['tail']; foot_id = tail[:16]
    out.extend(foot_id); out.extend(b'\0' * 4)
    pad = (16 - (len(out) % 16)) % 16 or 16
    out.extend(b'\0' * pad); out.extend(struct.pack('<I', doc['ver'])); out.extend(b'\0' * 120)
    out.extend(bytes([0xf8,0x5a,0x8c,0x6a,0xde,0xf5,0xd9,0x7e,0xec,0xe9,0x0c,0xe3,0x75,0x8f,0x29,0x0b]))
    open(path,'wb').write(out)
def child(n, name): return [k for k in n[2] if k[0] == name]
