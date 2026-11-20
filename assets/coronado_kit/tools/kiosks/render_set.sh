#!/bin/bash
# usage: render_set.sh TAG "views" [samples] [kids]   (sequential, one Blender at a time via bl.sh)
cd "$(dirname "$0")"
TAG=$1; VIEWS=$2; S=${3:-48}; KIDS=${4:-"hotdog paleta taco shaveice lemonade"}
for k in $KIDS; do ./bl.sh kbl_render.py $TAG $k "$VIEWS" $S > ../logs/render_${TAG}_$k.log 2>&1 || echo "FAIL $k"; done
echo done > ../logs/render_$TAG.done
