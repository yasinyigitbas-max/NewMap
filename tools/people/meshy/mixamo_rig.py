#!/usr/bin/env python3
"""Rig a character with Mixamo's auto-rigger through its web API (the calls its own site makes; the login token is a
network secret the proxy adds for www.mixamo.com). Markers are given in metres in Blender axes (z up, facing -y) and
sent in Mixamo's model space (cm, y up, facing +z).
  mixamo_rig.py upload FILE.fbx                 -> prints the character id
  mixamo_rig.py rig ID markers.json [lod]  -> markers.json: {"chin":[x,y,z], "lwrist":..., "rwrist", "lelbow",
                                                   "relbow", "lknee", "rknee", "groin"}; waits until rigged
"""
import json, subprocess, sys, time, urllib.request
API = "https://www.mixamo.com/api/v1"
H = {"X-Api-Key": "mixamo2", "Authorization": "Bearer proxy-injected", "Accept": "application/json"}

def call(method, path, body=None):
    h = dict(H)
    if body is not None: h["Content-Type"] = "application/json; charset=utf-8"
    req = urllib.request.Request(API + path, data=json.dumps(body).encode() if body is not None else None, headers=h, method=method)
    with urllib.request.urlopen(req, timeout=60) as r:
        t = r.read(); return json.loads(t) if t else {}

def upload(path):
    out = subprocess.run(["curl", "-sS", "-m", "300", "-X", "POST", API + "/characters", "-H", "X-Api-Key: mixamo2",
                          "-H", "Authorization: Bearer proxy-injected", "-H", "Accept: application/json",
                          "-F", "file=@" + path + ";type=application/octet-stream"], capture_output=True, text=True, check=True)
    cid = json.loads(out.stdout)["uuid"]
    for _ in range(100):
        s = call("GET", "/characters/" + cid).get("status")
        if s != "processing": break
        time.sleep(3)
    print(cid, s)

def rig(cid, markers_path, lod=""):   # "" = the full 65-bone skeleton with fingers
    m = json.load(open(markers_path))
    inputs = {k: {"x": v[0] * 100, "y": v[2] * 100, "z": -v[1] * 100} for k, v in m.items()}
    inputs.update({"orientation": {"x": 0, "y": 0, "z": 0, "w": 1}, "symmetric": True, "for": "both", "skeleton-lod": lod})
    print(call("PUT", f"/characters/{cid}/rig", {"rigging_inputs": inputs}))
    for _ in range(60):
        time.sleep(5)
        s = call("GET", "/characters/" + cid).get("status")
        print(s, flush=True)
        if s in ("ready", "needs_rigging", "failed"): return s

if __name__ == "__main__":
    if sys.argv[1] == "upload": upload(sys.argv[2])
    elif sys.argv[1] == "rig": rig(sys.argv[2], sys.argv[3], *(sys.argv[4:5] or []))
