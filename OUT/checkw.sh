#!/bin/bash
# west fill superchecker, indoors and outdoors
cd /home/user/NewMap
export VK_ICD_FILENAMES=/opt/lavapipe/lvp_icd.json
echo "== INDOORS"
OUT/round_w.sh 2>&1 | grep -a "ASSIGN\|^CHECK\|GEN_DONE\|no front" | grep -v "CHECKS-KIND"
echo "== GROUND"
DUMP_LAYOUT=res://OUT/area/w_layout.json timeout 2400 xvfb-run -a -s "-screen 0 640x360x24" godot --path . --rendering-method mobile --rendering-driver vulkan --resolution 320x180 -s res://OUT/ground_dump_area.gd -- --out=OUT/area/wmine 2>&1 | grep -a "GROUND-DUMP"
python3 /tmp/claude-0/-home-user-NewMap/07ce0345-793c-5370-94bb-91a011bbb531/scratchpad/tools/merge_dump.py OUT/area/full OUT/area/wmine OUT/area/groundW >/dev/null
python3 -I tools/city/audit/ground_check.py OUT/area/groundW >/dev/null
python3 -I -c "
import json
d=json.load(open('OUT/area/groundW_check.json'))['pieces']
m=[p for p in d if p['piece'].startswith(('n_w_','t_w_'))]
print('my pieces',len(m),'buried',sum(p['buried'] for p in m),'hanging',sum(p['hang'] for p in m),'steps',sum(p['step'] for p in m),'under',sum(p['under'] for p in m))"
echo "== OUTDOOR CHECKS"
export CITYKIT_LAYOUT_ONLY=1 CITYKIT_LAYOUT_EXTRA=res://OUT/area/w_area.json
run() { timeout 3600 xvfb-run -a -s "-screen 0 640x360x24" godot --path . --rendering-method mobile --rendering-driver vulkan "$@" 2>&1; }
run -s res://tools/city/pilot/validate.gd > OUT/area/validate_w.txt; echo "VALIDATOR lines naming mine: $(grep -ac 'n_w_\|t_w_' OUT/area/validate_w.txt)"; grep -a 'n_w_\|t_w_' OUT/area/validate_w.txt | head -30
run -s res://tools/city/pilot/check_life.gd > OUT/area/life_w.txt; echo "LIFE mine: $(grep -a 'n_w_\|t_w_' OUT/area/life_w.txt | grep -vc LIFE_INFO)"; grep -a 'n_w_\|t_w_' OUT/area/life_w.txt | grep -v LIFE_INFO | head -30
run -s res://tools/city/pilot/audit_trees.gd | grep -a "^TREES\|n_w_\|t_w_"
run -s res://tools/city/pilot/sink_check.gd | grep -a "SINK_DONE"
unset CITYKIT_LAYOUT_ONLY CITYKIT_LAYOUT_EXTRA
echo "== OWN AUDIT"
timeout 2400 xvfb-run -a -s "-screen 0 640x360x24" godot --path . --rendering-method mobile --rendering-driver vulkan --resolution 320x180 -s res://OUT/wdump.gd 2>&1 | grep -a "WDUMP"
python3 OUT/audit_w.py
echo CHECKW_DONE
