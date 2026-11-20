#!/bin/bash
# layout+bake -> compose -> export -> fix -> check. One Blender at a time (bl.sh: flock, -t 2, nice 19, --python-exit-code 1).
set -e
cd "$(dirname "$0")"
TAG=${1:-run}
./bl.sh kbl_bake.py both > ../logs/bake_$TAG.log 2>&1; grep -E "baked|BAKE DONE" ../logs/bake_$TAG.log
nice -n 19 python3 kcompose.py > ../logs/compose_$TAG.log 2>&1; tail -1 ../logs/compose_$TAG.log
./bl.sh kbl_export.py > ../logs/export_$TAG.log 2>&1; grep -E "EXPORT DONE" ../logs/export_$TAG.log
python3 kfix_glb.py
python3 kcheck.py || true
