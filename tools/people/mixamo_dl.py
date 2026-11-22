"""Downloads Mixamo animations through Mixamo's own web API (the one its site uses), for the movement sets (Yasin, 24 Nov:
"cant you download others? i can log into mixamo"). The login token is NOT here: the session's network proxy adds it to
requests to www.mixamo.com (a network secret Yasin saved). Settings as Yasin's own downloads: FBX, without skin, 30 fps,
no keyframe reduction, the moving ones In Place, on his account's character.
  python3 -I tools/people/mixamo_dl.py OUT_DIR "Name=product-id[:inplace]" ...
"""
import json, sys, time, urllib.request, urllib.error, os

API = "https://www.mixamo.com/api/v1"
H = {"X-Api-Key": "mixamo2", "Authorization": "Bearer proxy-injected", "Content-Type": "application/json", "Accept": "application/json"}

def call(path, body=None):
    # (Mixamo answers 429 "too many requests" after ~60 downloads in a row: wait and try again, longer each time)
    for k in range(8):
        req = urllib.request.Request(API + path, data=json.dumps(body).encode() if body is not None else None, headers=H, method="POST" if body is not None else "GET")
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.loads(r.read())
        except urllib.error.HTTPError as e:
            if e.code != 429 or k == 7: raise
            time.sleep(30 * (k + 1))

def export(out_dir, name, pid, inplace, cid):
    d = call(f"/products/{pid}?similar=0&character_id={cid}")
    g = d["details"]["gms_hash"]
    g["inplace"] = bool(inplace) and d["details"].get("supports_inplace", False)
    g["params"] = ",".join(str(p[1]) for p in g.get("params", []))
    body = {"character_id": cid, "gms_hash": [g], "preferences": {"format": "fbx7_2019", "skin": "false", "fps": "30", "reducekf": "0"}, "product_name": name, "type": "Motion"}
    call("/animations/export", body)
    for _ in range(90):
        time.sleep(2)
        m = call(f"/characters/{cid}/monitor")
        if m.get("status") == "completed":
            url = m["job_result"]
            path = os.path.join(out_dir, name + ".fbx")
            with urllib.request.urlopen(url, timeout=120) as r, open(path, "wb") as f: f.write(r.read())
            return path, os.path.getsize(path)
        if m.get("status") == "failed": raise RuntimeError(str(m))
    raise RuntimeError("timed out")

if __name__ == "__main__":
    out = sys.argv[1]; os.makedirs(out, exist_ok=True)
    cid = call("/characters/primary")["primary_character_id"]
    for spec in sys.argv[2:]:
        name, rest = spec.split("=", 1)
        pid, _, ip = rest.partition(":")
        if os.path.exists(os.path.join(out, name + ".fbx")): continue   # (already here)
        try: print("MIXAMO ok", name, *export(out, name, pid, ip != "0", cid), flush=True)
        except Exception as e: print("MIXAMO FAIL", name, e, flush=True)
        time.sleep(4)   # (paced)
