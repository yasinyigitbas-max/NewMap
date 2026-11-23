#!/usr/bin/env python3
"""Meshy API helper for Coronado's characters (see docs/CHARACTERS_MESHY.md).

The key is a network secret on the environment: the proxy injects the Authorization header, so this script
sends a placeholder. Each character keeps its task ids in tools/people/meshy/cast/<name>.json; downloads land in
assets/people/meshy/<name>/.

  meshy.py balance
  meshy.py preview <name>          text-to-3D preview (mesh, no texture) from cast/<name>.json "prompt"
  meshy.py refine <name>           texture the preview
  meshy.py rig <name>              auto-rig the refined model (Mixamo-style humanoid skeleton)
  meshy.py remesh <name> <tris>    a lower-triangle copy (LOD) of the refined model
  meshy.py wait <name> <step>      poll a step until it ends, then download its files
"""
import json, os, ssl, sys, time, urllib.request

API = "https://api.meshy.ai/openapi"
ROOT = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(ROOT, "..", "..", ".."))
CA = "/root/.ccr/ca-bundle.crt"
CTX = ssl.create_default_context(cafile=CA) if os.path.exists(CA) else ssl.create_default_context()

ENDPOINT = {  # step -> GET path prefix
    "preview": "/v2/text-to-3d/", "refine": "/v2/text-to-3d/",
    "rig": "/v1/rigging/", "remesh": "/v1/remesh/",
}


def call(method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(API + path, data=data, method=method, headers={
        "Authorization": "Bearer proxy-injected", "Content-Type": "application/json"})
    with urllib.request.urlopen(req, context=CTX, timeout=60) as r:
        return json.loads(r.read() or b"{}")


def cast_path(name):
    return os.path.join(ROOT, "cast", name + ".json")


def load(name):
    with open(cast_path(name)) as f:
        return json.load(f)


def save(name, c):
    with open(cast_path(name), "w") as f:
        json.dump(c, f, indent=2)
        f.write("\n")


def start(name, step, body, path):
    c = load(name)
    r = call("POST", path, body)
    c.setdefault("tasks", {})[step] = r["result"]
    save(name, c)
    print(step, "task", r["result"])


def download(url, dest):
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    with urllib.request.urlopen(urllib.request.Request(url), context=CTX, timeout=300) as r, open(dest, "wb") as f:
        f.write(r.read())
    print("  saved", os.path.relpath(dest, REPO), os.path.getsize(dest), "bytes")


def wait(name, step):
    c = load(name)
    tid = c["tasks"][step]
    while True:
        t = call("GET", ENDPOINT[step] + tid)
        print(step, t.get("status"), t.get("progress"), flush=True)
        if t.get("status") in ("SUCCEEDED", "FAILED", "CANCELED", "EXPIRED"):
            break
        time.sleep(15)
    out = os.path.join(REPO, "assets", "people", "meshy", name)
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, step + "_task.json"), "w") as f:
        json.dump(t, f, indent=2)
    if t.get("status") != "SUCCEEDED":
        print("FAILED:", t.get("task_error"))
        sys.exit(1)
    urls = {}
    if step in ("preview", "refine", "remesh"):
        mu = t.get("model_urls", {})
        for fmt in ("glb", "fbx"):
            if mu.get(fmt):
                urls[f"{step}.{fmt}"] = mu[fmt]
        if t.get("thumbnail_url"):
            urls[f"{step}_thumb.png"] = t["thumbnail_url"]
        for i, tex in enumerate(t.get("texture_urls") or []):
            for k, u in tex.items():
                urls[f"{step}_tex{i}_{k}.png"] = u
    elif step == "rig":
        res = t.get("result", {})
        for k in ("rigged_character_glb_url", "rigged_character_fbx_url"):
            if res.get(k):
                urls["rigged." + k.split("_")[-2]] = res[k]
        for k, u in (res.get("basic_animations") or {}).items():
            if isinstance(u, str) and u.startswith("http") and "glb" in k:
                urls[f"anim_{k}.glb"] = u
    for fn, u in urls.items():
        download(u, os.path.join(out, fn))


def main(a):
    cmd = a[0]
    if cmd == "balance":
        print(call("GET", "/v1/balance"))
    elif cmd == "preview":
        c = load(a[1])
        start(a[1], "preview", {
            "mode": "preview", "prompt": c["prompt"], "art_style": "realistic", "ai_model": "latest",
            "topology": "triangle", "target_polycount": c.get("tris", 12000), "should_remesh": c.get("remesh", True),
            "symmetry_mode": "auto", "pose_mode": "t-pose",
        }, "/v2/text-to-3d")
    elif cmd == "refine":
        c = load(a[1])
        body = {"mode": "refine", "preview_task_id": c["tasks"]["preview"], "enable_pbr": False,
                "ai_model": "latest"}
        if c.get("texture_prompt"):
            body["texture_prompt"] = c["texture_prompt"]
        start(a[1], "refine", body, "/v2/text-to-3d")
    elif cmd == "rig":
        c = load(a[1])
        start(a[1], "rig", {"input_task_id": c["tasks"]["refine"], "height_meters": c.get("height_m", 1.8)},
              "/v1/rigging")
    elif cmd == "remesh":
        c = load(a[1])
        start(a[1], "remesh", {"input_task_id": c["tasks"]["refine"], "target_formats": ["glb"],
                               "topology": "triangle", "target_polycount": int(a[2])}, "/v1/remesh")
    elif cmd == "wait":
        wait(a[1], a[2])
    else:
        print(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:] or ["help"])
