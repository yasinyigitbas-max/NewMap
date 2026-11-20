#!/bin/bash
# compose -> export -> fix -> check (reuses the existing bake in work/)
set -e
cd "$(dirname "$0")"
TAG=${1:-run}
nice -n 19 python3 kcompose.py > ../logs/compose_$TAG.log 2>&1; tail -1 ../logs/compose_$TAG.log
./bl.sh kbl_export.py > ../logs/export_$TAG.log 2>&1; grep -E "EXPORT DONE" ../logs/export_$TAG.log
python3 kfix_glb.py
python3 kcheck.py || true
