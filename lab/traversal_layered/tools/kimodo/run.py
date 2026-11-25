# Run one Kimodo prediction on Replicate and download its outputs. Usage: python3 -I run.py <name> '<json input>'
import json, sys, time, urllib.request, os
VER = "17111248e89aa145d768cc1e5f7baae228f69d854b996b860becfee287379545"
H = {"User-Agent": "lab-client/1.0", "Authorization": "Bearer proxy-injected", "Content-Type": "application/json", "Prefer": "wait=60"}
def req(url, data=None, method="GET"):
    r = urllib.request.Request(url, data=json.dumps(data).encode() if data else None, headers=H, method=method)
    with urllib.request.urlopen(r, timeout=120) as f: return json.load(f)
name, inp = sys.argv[1], json.loads(sys.argv[2])
import urllib.error
for attempt in range(20):
    try:
        p = req("https://api.replicate.com/v1/predictions", {"version": VER, "input": inp}, "POST"); break
    except urllib.error.HTTPError as e:
        if e.code != 429: print(e.read().decode()[:300]); raise
        time.sleep(11)
while p["status"] not in ("succeeded", "failed", "canceled"):
    time.sleep(3); p = req(p["urls"]["get"])
os.makedirs(f"out/{name}", exist_ok=True)
json.dump(p, open(f"out/{name}/prediction.json", "w"), indent=1)
print(name, p["status"], p.get("error"), "predict_time", (p.get("metrics") or {}).get("predict_time"))
for u in (p.get("output") or []):
    fn = f"out/{name}/" + u.split("/")[-1]
    with urllib.request.urlopen(urllib.request.Request(u, headers={"User-Agent": "lab-client/1.0"}), timeout=120) as f: open(fn, "wb").write(f.read())
    print("  ", fn, os.path.getsize(fn))
