#!/bin/bash
# one polish pass: rebuild the prop, add grips, render views + scale reference
set -e; cd /workspace/coronado_kit_v2/_staging/carry; T=$1; N=${2:-bag_paper_kraft}
rm -f kit/props/_bake/tiles/${N}_*
./build.sh incarry $N 2>&1 | grep "BUILT\|FAIL\|Error\|OVER\|Trace" || true
IN_KIT=$PWD/kit python3 kit/props/_tools/c_grips.py incarry $N
python3 fix_occ.py kit/props/indoor/carry/prop_${N}_clean_near.glb
G=kit/props/indoor/carry/prop_${N}_clean_near.glb
./rend.sh renders/p $T $G
while pgrep -f "tools/blender/blender" >/dev/null; do sleep 5; done
TMPDIR=/tmp flock /tmp/coronado_blender_box.lock nice -n 19 /workspace/tools/blender/blender -b -noaudio -t 2 --python-exit-code 1 -P c_scale.py -- renders/p/${N}_${T}_scale.png $G 2>&1 | grep -i "error\|Traceback" | tail -5
python3 /workspace/coronado_kit_v2/_staging/shop_gaps/mont.py renders/p/m_$T.png renders/p/${N}_${T}_{hero,front,side,back,top,low}.png
echo PASS_DONE
