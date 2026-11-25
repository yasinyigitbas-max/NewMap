"""Minimal binary-FBX reader: per file, the skeleton's bone names, frame rate, unit, clip length and the hips' travel.
Usage: python -I fbx_scan.py <dir-or-files...>  -> one tab-separated line per file."""
import os, struct, sys, zlib

TICK = 46186158000.0
FPS_MODE = {0: None, 1: 120, 2: 100, 3: 60, 4: 50, 5: 48, 6: 30, 7: 30, 8: 30, 9: 29.97, 10: 25, 11: 24, 13: 96, 14: 72, 15: 59.94, 17: 120}


def read_nodes(b, p, end, v64):
    out = []
    while p < end:
        if v64:
            eo, npr, plen = struct.unpack_from("<QQQ", b, p); p += 24
        else:
            eo, npr, plen = struct.unpack_from("<III", b, p); p += 12
        nl = b[p]; p += 1
        if eo == 0:
            break
        name = b[p:p + nl].decode("latin1"); p += nl
        props = []
        q = p
        for _ in range(npr):
            t = chr(b[q]); q += 1
            if t in "YCIFDL":
                fmt = {"Y": "<h", "C": "<?", "I": "<i", "F": "<f", "D": "<d", "L": "<q"}[t]
                props.append(struct.unpack_from(fmt, b, q)[0]); q += struct.calcsize(fmt)
            elif t in "fdlib":
                n, enc, cl = struct.unpack_from("<III", b, q); q += 12
                raw = b[q:q + cl]; q += cl
                if enc == 1:
                    raw = zlib.decompress(raw)
                fmt = {"f": "f", "d": "d", "l": "q", "i": "i", "b": "?"}[t]
                props.append(list(struct.unpack("<%d%s" % (n, fmt), raw[:n * struct.calcsize(fmt)])))
            elif t in "SR":
                n = struct.unpack_from("<I", b, q)[0]; q += 4
                props.append(b[q:q + n] if t == "R" else b[q:q + n].decode("utf8", "replace")); q += n
        p = p + plen
        kids = read_nodes(b, p, eo, v64) if p < eo else []
        out.append((name, props, kids))
        p = eo
    return out


def find(nodes, name):
    return [n for n in nodes if n[0] == name]


def scan(path):
    b = open(path, "rb").read()
    if not b.startswith(b"Kaydara FBX Binary"):
        return {"err": "not binary fbx"}
    ver = struct.unpack_from("<I", b, 23)[0]
    top = read_nodes(b, 27, len(b), ver >= 7500)
    info = {"ver": ver}
    gs = find(top, "GlobalSettings")
    if gs:
        for p70 in find(gs[0][2], "Properties70"):
            for P in p70[2]:
                k = P[1][0]
                if k == "TimeMode": info["fps"] = FPS_MODE.get(P[1][4], "mode%s" % P[1][4])
                if k == "CustomFrameRate" and P[1][4] > 0: info["custom_fps"] = P[1][4]
                if k == "UnitScaleFactor": info["unit"] = P[1][4]
    objs = find(top, "Objects")[0][2] if find(top, "Objects") else []
    models, curves, cnodes = {}, {}, {}
    for n, pr, kids in objs:
        if n == "Model":
            models[pr[0]] = (pr[1].split("\x00")[0], pr[2])
        elif n == "AnimationCurve":
            kt = find(kids, "KeyTime"); kv = find(kids, "KeyValueFloat")
            if kt and kv: curves[pr[0]] = (kt[0][1][0], kv[0][1][0])
        elif n == "AnimationCurveNode":
            cnodes[pr[0]] = pr[1].split("\x00")[0]
    bones = [nm for nm, ty in models.values() if ty in ("LimbNode", "Root", "Null")]
    info["bones"] = len([1 for nm, ty in models.values() if ty == "LimbNode"])
    hips = [i for i, (nm, ty) in models.items() if nm.lower().endswith("hips") or nm.lower().endswith("pelvis")]
    info["hips_name"] = models[hips[0]][0] if hips else "?"
    pfx = info["hips_name"].rsplit("Hips", 1)[0] if "Hips" in info["hips_name"] else ""
    info["prefix"] = pfx
    info["fingers"] = sum(1 for nm in bones if any(k in nm for k in ("Index", "Middle", "Ring", "Pinky", "Thumb", "Finger")))
    info["toes"] = sum(1 for nm in bones if "Toe" in nm)
    # connections
    conns = find(top, "Connections")[0][2] if find(top, "Connections") else []
    cn_target, curve_of = {}, {}
    for n, pr, _ in conns:
        if pr[0] == "OP":
            child, parent, prop = pr[1], pr[2], pr[3]
            if child in cnodes and parent in models: cn_target[child] = (parent, prop)
            if child in curves and parent in cnodes: curve_of.setdefault(parent, {})[prop] = child
    t0, t1 = None, None
    for cid, (kt, kv) in curves.items():
        if kt:
            t0 = kt[0] if t0 is None else min(t0, kt[0]); t1 = kt[-1] if t1 is None else max(t1, kt[-1])
    info["len_s"] = round((t1 - t0) / TICK, 3) if t0 is not None else 0.0
    if hips:
        for cn, (m, prop) in cn_target.items():
            if m == hips[0] and "Translation" in prop:
                ax = curve_of.get(cn, {})
                def ends(k):
                    c = curves.get(ax.get(k))
                    return (c[1][0], c[1][-1], min(c[1]), max(c[1]), len(c[1])) if c else None
                X, Y, Z = ends("d|X"), ends("d|Y"), ends("d|Z")
                if X and Z:
                    info["hips_dx"] = round(X[1] - X[0], 1); info["hips_dz"] = round(Z[1] - Z[0], 1)
                    info["hips_xz_range"] = round(max(X[3] - X[2], Z[3] - Z[2]), 1)
                if Y:
                    info["hips_y0"] = round(Y[0], 1); info["hips_y_min"] = round(Y[2], 1); info["hips_y_max"] = round(Y[3], 1); info["keys"] = Y[4]
    return info


def main():
    files = []
    for a in sys.argv[1:]:
        if os.path.isdir(a):
            files += [os.path.join(a, f) for f in sorted(os.listdir(a)) if f.lower().endswith(".fbx")]
        else:
            files.append(a)
    cols = ["fps", "custom_fps", "unit", "bones", "fingers", "toes", "prefix", "len_s", "keys", "hips_y0", "hips_y_min", "hips_y_max", "hips_dx", "hips_dz", "hips_xz_range", "err"]
    print("file\t" + "\t".join(cols))
    for f in files:
        try:
            i = scan(f)
        except Exception as e:  # noqa
            i = {"err": repr(e)[:80]}
        print(os.path.basename(f) + "\t" + "\t".join(str(i.get(c, "")) for c in cols))


main()
