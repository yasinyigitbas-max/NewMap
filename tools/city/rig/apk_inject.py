"""Put changed files into an exported APK instead of exporting a new one (Yasin, 20 Nov: "try to inject your changes in
instead of exporting a new app where applicable"). An export takes ~15 minutes; this takes ~2.

What it can swap:
  --so               the game's C++ library (native/bin/libcoronado_city.android.arm64.so -> lib/arm64-v8a/)
  --gd=a.gd,b.gd     scripts (repo paths): the plain .gd goes in at assets/<path>; the exported .gdc and its .remap are
                     taken out, so the engine loads the plain script (it does in an exported game)
  --file=src:dst     any other file (dst = the path inside the APK)
  --dir=a/b,c/d      every file of these repo folders, at assets/<folder>/ (e.g. the merged rooms: runtime/rooms)
What it cannot: project settings (assets/project.binary is binary: export for those), anything that needs an import
(textures, models, scenes made by the editor's export), and the bake's runtime files are fine to swap only if the
same paths (use --file).
Then: zipalign (16 KB pages for the .so) and apksigner with the Godot debug key, so it installs over the app with -r and
keeps its data (rig_args.txt).

  python -I tools/city/rig/apk_inject.py --in=OUT/citykit_rig.apk --out=OUT/inject/rig_inj.apk --so --gd=tools/city/rig/rig.gd
"""
import hashlib
import os
import struct
import subprocess
import sys
import zipfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
SDK = os.environ.get("ANDROID_SDK", r"C:\Users\yasin\AppData\Local\Android\Sdk")
KEY = os.environ.get("GODOT_DEBUG_KEYSTORE", r"C:\Users\yasin\AppData\Roaming\Godot\keystores\debug.keystore")


def arg(name, default=None):
    for a in sys.argv[1:]:
        if a == "--" + name:
            return True
        if a.startswith("--" + name + "="):
            return a.split("=", 1)[1]
    return default


SPARSE = "assets/assets.sparsepck"


def sparse_index(data, put, drop):
    """The export's file index (a sparse Godot pack, format 4: header, then at 0x68 the count and per file: padded path,
    offset, SIZE, MD5, flags). The engine reads a file by the size listed here: a swapped file of another size came out
    cut short ("file corrupt", 20 Nov). Swapped files get their new size and MD5, added files an entry, removed ones none."""
    n = struct.unpack_from("<I", data, 0x68)[0]
    p = 0x6C
    ents = []
    for _ in range(n):
        ln = struct.unpack_from("<I", data, p)[0]; p += 4
        path = data[p:p + ln].rstrip(b"\0").decode("utf-8"); p += ln
        off, size = struct.unpack_from("<QQ", data, p); p += 16
        md5 = data[p:p + 16]; p += 16
        fl = struct.unpack_from("<I", data, p)[0]; p += 4
        ents.append([path, off, size, md5, fl])
    if p != len(data):
        sys.exit("the sparse index did not parse to its end (%d of %d): format changed?" % (p, len(data)))
    rel = {d[len("assets/"):]: s for d, s in put.items() if d.startswith("assets/")}
    gone = {d[len("assets/"):] for d in drop if d.startswith("assets/")}
    seen = set()
    out_ents = []
    for e in ents:
        if e[0] in gone:
            continue
        if e[0] in rel:
            b = open(rel[e[0]], "rb").read(); e[2] = len(b); e[3] = hashlib.md5(b).digest(); seen.add(e[0])
        out_ents.append(e)
    for path, src in rel.items():
        if path not in seen:
            b = open(src, "rb").read(); out_ents.append([path, 0, len(b), hashlib.md5(b).digest(), 0])
    body = bytearray(data[:0x68]) + struct.pack("<I", len(out_ents))
    for path, off, size, md5, fl in out_ents:
        pb = path.encode("utf-8"); ln = (len(pb) + 1 + 3) // 4 * 4
        body += struct.pack("<I", ln) + pb + b"\0" * (ln - len(pb)) + struct.pack("<QQ", off, size) + md5 + struct.pack("<I", fl)
    print("INJECT index: %d entries (was %d), %d sizes updated" % (len(out_ents), n, len(seen)))
    return bytes(body)


def main():
    src = arg("in"); out = arg("out")
    if not src or not out:
        sys.exit(__doc__)
    put = {}      # path in the APK -> local file
    drop = set()
    if arg("so"):
        put["lib/arm64-v8a/libcoronado_city.android.arm64.so"] = os.path.join(ROOT, "native/bin/libcoronado_city.android.arm64.so")
    for g in (arg("gd") or "").split(","):
        g = g.strip()
        if not g:
            continue
        put["assets/" + g] = os.path.join(ROOT, g)
        drop.add("assets/" + g + ".remap")
        drop.add("assets/" + g[:-3] + ".gdc")
    for dd in (arg("dir") or "").split(","):      # --dir=repo/folder: every file in it, at assets/<repo/folder>/ (not recursive)
        dd = dd.strip().strip("/")
        if not dd:
            continue
        for fn in sorted(os.listdir(os.path.join(ROOT, dd))):
            if os.path.isfile(os.path.join(ROOT, dd, fn)) and not fn.endswith(".import"):
                put["assets/%s/%s" % (dd, fn)] = os.path.join(ROOT, dd, fn)
    for f in (arg("file") or "").split(","):
        if ":" in f:
            s, d = f.split(":", 1)
            put[d] = os.path.join(ROOT, s)
    for d, s in put.items():
        if not os.path.isfile(s):
            sys.exit("missing " + s)
    tmp = out + ".tmp.apk"
    with zipfile.ZipFile(src) as zi, zipfile.ZipFile(tmp, "w") as zo:
        names = set(zi.namelist())
        for it in zi.infolist():
            if it.filename in put or it.filename in drop or it.filename.startswith("META-INF/"):
                continue      # (replaced, taken out, or the old signature: apksigner writes a new one)
            if it.filename == SPARSE:
                zo.writestr(it, sparse_index(zi.read(SPARSE), put, drop), compress_type=it.compress_type)
                continue
            zo.writestr(it, zi.read(it.filename), compress_type=it.compress_type)
        for d, s in put.items():
            # native libraries stored, not deflated (the app maps them straight from the APK)
            zo.write(s, d, compress_type=zipfile.ZIP_STORED if d.endswith(".so") else zipfile.ZIP_DEFLATED)
            print("INJECT %s %s" % ("replaced" if d in names else "added", d))
        for d in sorted(drop & names):
            print("INJECT removed " + d)
    bt = os.path.join(SDK, "build-tools", sorted(os.listdir(os.path.join(SDK, "build-tools")))[-1])
    aligned = out + ".aligned.apk"
    subprocess.check_call([os.path.join(bt, "zipalign.exe"), "-P", "16", "-f", "4", tmp, aligned])
    subprocess.check_call(["cmd", "/c", os.path.join(bt, "apksigner.bat"), "sign", "--ks", KEY, "--ks-pass", "pass:android",
                           "--ks-key-alias", "androiddebugkey", "--out", out, aligned])
    os.remove(tmp); os.remove(aligned)
    print("INJECT_DONE %s (%.0f MB)" % (out, os.path.getsize(out) / 1048576.0))


if __name__ == "__main__":
    main()
