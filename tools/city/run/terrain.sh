#!/bin/bash
# The terrain pipeline after any piece's ground changed (SKILL "Lessons 17 Nov (terrain ...)"):
# piece ground raster -> piece_ground.npz -> terrain.py -> shore_foam.py -> x_shore_foam piece -> game bake.
cd "$(dirname "$0")/../../.."
export CITYKIT_LAYOUT_ONLY=1 CITYKIT_LAYOUT_EXTRA=res://map_dc/coronado/city_kit/city_grid_layout.json
timeout 1500 xvfb-run -a -s "-screen 0 640x360x24" godot --path . --rendering-method mobile --rendering-driver vulkan -s res://tools/city/pilot/zoning/piece_ground.gd 2>&1 | grep -a RASTER
python3 -c "
import numpy as np,json; m=json.load(open('piece_ground.json')); g=np.fromfile('piece_ground.f32','<f4').reshape(m['ny'],m['nx'])
np.savez_compressed('map_dc/coronado/city_kit/zoning/piece_ground.npz',u0=m['u0'],v0=m['v0'],step=1.0,ground=g)"
(cd tools/city/pilot/zoning && python3 terrain.py | tail -3 && python3 shore_foam.py)
timeout 900 xvfb-run -a -s "-screen 0 640x360x24" godot --path . --rendering-method mobile --rendering-driver vulkan -s res://tools/city/pilot/pieces/x_shore_foam.gd 2>&1 | grep -a "x_shore"
python3 tools/city/pilot/zoning/bake_game_terrain.py | tail -2
# preview export for TERRAIN=res://terrain_grid.json shots and terrain_check.gd
python3 -c "
import numpy as np,json
b=np.load('map_dc/coronado/city_kit/zoning/terrain_grid.npz'); H=b['heights'].astype('<f4'); H.tofile('terrain_grid.f32'); b['sea'].astype(np.uint8).tofile('terrain_sea.u8')
json.dump({'u0':float(b['u0']),'v0':float(b['v0']),'step':float(b['step']),'nx':H.shape[1],'ny':H.shape[0]},open('terrain_grid.json','w'))"
