import json, base64, subprocess, sys
tests = json.load(open("ref/r3_tests.json"))
for k, t in tests.items():
    data = base64.b64encode(open(f"ref/r3_{k}.json", "rb").read()).decode()
    inp = {"prompt": t["prompt"], "duration": t["duration"], "num_samples": 16, "output_format": "all",
           "skeleton_mesh": False, "preview": False, "seed": 31, "constraints_json": "data:application/json;base64," + data}
    subprocess.run([sys.executable, "-I", "run.py", "r3c_" + k, json.dumps(inp)])
