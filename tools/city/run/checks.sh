#!/bin/bash
# Every check the city kit must pass before showing / locking / pushing (17 Nov rules), on the ASSEMBLED city
# (city_grid_layout.json): validator (CHECKS 0 problems), tree audit (0 in hard ground), sink / float (SINK_DONE 0),
# indoor rooms (CHECKS 0 problems), lock test (RESULT PASS). Real renderer under xvfb (Vulkan Mobile on lavapipe).
# Usage (repo root): tools/city/run/checks.sh            (CITYKIT_LAYOUT_EXTRA=<json> to check a review area instead)
cd "$(dirname "$0")/../../.."
export CITYKIT_LAYOUT_ONLY=1 CITYKIT_LAYOUT_EXTRA=${CITYKIT_LAYOUT_EXTRA:-res://map_dc/coronado/city_kit/city_grid_layout.json}
R="xvfb-run -a -s '-screen 0 640x360x24' godot --path . --rendering-method mobile --rendering-driver vulkan"
run() { timeout 2400 xvfb-run -a -s "-screen 0 640x360x24" godot --path . --rendering-method mobile --rendering-driver vulkan "$@" 2>&1; }
run -s res://tools/city/pilot/validate.gd | grep -a "^CHECK" | tail -30
run -s res://tools/city/pilot/audit_trees.gd | grep -a "^TREES"
run -s res://tools/city/pilot/sink_check.gd | grep -a "SINK_DONE"
run --resolution 320x180 -s res://map_dc/coronado/city_kit/interiors/rooms/check_rooms.gd | grep -a "^CHECKS"
timeout 1200 godot --headless --path . -s res://tests/city_kit/test_locked_pieces.gd 2>&1 | grep -a "RESULT\|locked pieces\|FAIL"
