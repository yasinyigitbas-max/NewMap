#!/bin/bash
# INDOORS rollout pipeline, in order (repo root). The lean / lean2 flags in bays.json (set by hand per model after the
# budget check) are kept over plan_bays. Godot steps go through the box's Godot lock.
set -e
cd "$(dirname "$0")/../../../../.."
B=map_dc/coronado/city_kit/interiors/builtin
G="flock -w 1800 /tmp/godot.lock.citygame nice timeout 1500 /workspace/tools/godot472/Godot_v4.7.2-stable_linux.x86_64 --headless --path ."
python3 - <<'P' > /tmp/indoors_flags.json
import json; b=json.load(open('map_dc/coronado/city_kit/interiors/builtin/bays.json'))
print(json.dumps({m:{k:v[k] for k in ('lean','lean2','front_only') if k in v} for m,v in b['models'].items()}))
P
python3 tools/city/rooms/builtin/indoors/make_spec.py
python3 tools/city/rooms/builtin/indoors/plan_bays.py
python3 - <<'P'
import json; p='map_dc/coronado/city_kit/interiors/builtin/bays.json'; b=json.load(open(p)); f=json.load(open('/tmp/indoors_flags.json'))
for m,v in b['models'].items(): v.update(f.get(m,{}))
import os; os.remove(p); json.dump(b,open(p,'w'),indent=1)
P
python3 tools/city/rooms/builtin/indoors/make_sets.py
python3 tools/city/rooms/builtin/indoors/layouts.py
$G -s res://tools/city/rooms/builtin/make_interiors.gd
$G -s res://tools/city/rooms/builtin/validate_bays.gd
