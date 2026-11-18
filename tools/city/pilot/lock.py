"""Lock / unlock approved block-kit pieces (map_dc/coronado/city_kit/locked.json).

  python -I tools/city/pilot/lock.py status
  python -I tools/city/pilot/lock.py lock <piece> [<piece> ...] --by=Yasin
  python -I tools/city/pilot/lock.py unlock <piece> --by=Yasin      (only on Yasin's word)
  python -I tools/city/pilot/lock.py lockfile <repo path> [...] --by=Yasin   (approved plans: zoning map, skeleton)
  python -I tools/city/pilot/lock.py unlockfile <repo path> --by=Yasin

A locked piece's .scn must never change; tests/city_kit/test_locked_pieces.gd checks the sha256.
"""
import datetime
import hashlib
import json
import sys

ROOT = "map_dc/coronado/city_kit/"
args = [a for a in sys.argv[1:] if not a.startswith("--")]
opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
db = json.load(open(ROOT + "locked.json", encoding="utf-8"))
pieces = db.setdefault("pieces", {})
files = db.setdefault("files", {})   # repo-relative path -> {sha256, by, date}: approved plans (zoning map, street skeleton)

def sha(name):
    return hashlib.sha256(open(f"{ROOT}pieces/{name}.scn", "rb").read()).hexdigest()

cmd = args[0] if args else "status"
if cmd == "status":
    import os
    for f in sorted(os.listdir(ROOT + "pieces")):
        n = f[:-4]
        if not f.endswith(".scn"):
            continue
        e = pieces.get(n)
        state = "draft" if not e else ("LOCKED ok" if e["sha256"] == sha(n) else "LOCKED BUT CHANGED")
        print(f"{n:16s} {state}")
    for path, e in sorted(files.items()):
        ok = hashlib.sha256(open(path, "rb").read()).hexdigest() == e["sha256"]
        print(f"{path}  {'LOCKED ok' if ok else 'LOCKED BUT CHANGED'}")
    sys.exit(0)
if "by" not in opts:
    sys.exit("say who approved it: --by=Yasin")
for n in args[1:]:
    if cmd == "lock":
        if n in pieces and pieces[n]["sha256"] != sha(n):
            sys.exit(f"{n} is locked and its file changed: unlock it first (Yasin), then lock the new version")
        pieces[n] = {"sha256": sha(n), "by": opts["by"], "date": datetime.date.today().isoformat()}
        print(f"locked {n}")
    elif cmd == "lockfile":
        h = hashlib.sha256(open(n, "rb").read()).hexdigest()
        if n in files and files[n]["sha256"] != h:
            sys.exit(f"{n} is locked and changed: unlockfile it first (Yasin), then lock the new version")
        files[n] = {"sha256": h, "by": opts["by"], "date": datetime.date.today().isoformat()}
        print(f"locked file {n}")
    elif cmd == "unlockfile":
        files.pop(n, None)
        print(f"unlocked file {n} (by {opts['by']})")
    elif cmd == "unlock":
        pieces.pop(n, None)
        print(f"unlocked {n} (by {opts['by']})")
with open(ROOT + "locked.json", "w", encoding="utf-8", newline="\n") as f:
    json.dump(db, f, indent=1)
    f.write("\n")
