# Real doors for the old cars, and the parallax cabin

Yasin, 27 Nov: "make the doors off the existing cars truly openable"; "we don't have a real cabin, is it possible to
make the cabin look like it exists with some parallax effect?". The Sakura is done first: its two front doors only (no
bonnet or boot yet).

## What it does
- The car's own body mesh is cut along its door lines (read off the panel gaps in the car's AO map). Every triangle of
  the side skin that crosses the outline is clipped exactly; new vertices take position, normal, tangent and both UV
  sets from their edge, so paint, gap lines and the car maps carry on across the cut. Shut, the car looks as before.
- Each door gets a 5 cm thickness, a dark inner card and an edge strip; the body gets a 6 cm jamb round the opening.
  Each door is its own mesh in its hinge's frame (origin = the hinge, front edge, vertical axis).
- The cabin is not modelled. The glass shows it by interior mapping (`vehicles/car_paint.gdshader`, `cabin_*`): the view
  ray goes into the cabin box and samples a picture of a cabin where it leaves the box, so it moves with the camera.
  The picture (`<car>_cabin.png`, six 90-degree views packed 3 x 2) is rendered by `cabin_cube.py` from the car's own
  shell plus seats, dash, steering wheel and floor that exist only in the picture.
- An open door shows the same picture on an inward-facing cabin hull (`<car>_q_cabin.res`, `vehicles/cabin_box.gdshader`),
  drawn only while a door is open.

## Files (per car, `vehicles/models/`)
| file | what |
|---|---|
| `lod/<car>_q_body.res` | unchanged: the whole body (the traffic still draws this) |
| `lod/<car>_q_body_cut.res` | the body with the door openings and jambs; metas `wheels`, `cartex`, `doors` (hinge, max angle per side), `cabin` (box) |
| `lod/<car>_q_door_l.res`, `_door_r.res` | the doors, each in its hinge frame |
| `lod/<car>_q_cabin.res` | the cabin hull seen through an open door |
| `cartex/<car>_cabin.png` | the cabin picture |

`CityCar` (native/src/city_car.cpp, `fit_doors`, `door_pose`) uses them when all are there: `set_door` swings the
driver's door (left, +x), new `set_door_right` the passenger's, `has_real_doors()`. Other models: unchanged (the
shader's door).

## Rebuild (per car; numbers in `cut_doors.py` CARS and `cabin_cube.py` CABIN)
1. `godot --headless --path <project> -s mesh_dump.gd -- res://vehicles/models/lod/<car>_q_body.res <dump>`
2. `python3 cut_doors.py <dump> <cut_dir> <car>`
3. `blender -b -P cabin_cube.py -- <cut_dir> <car> <cut_dir>/<car>_cabin.png`
4. `godot --headless ... -s mesh_pack.gd -- <cut_dir>/<car>_body res://.../<car>_q_body_cut.res <cut_dir>/<car>_doors.json`,
   the same for `<car>_door_l`, `<car>_door_r`, `<car>_cabin` (-> `_q_cabin.res`)
5. Test: `godot --path . --rendering-method mobile --resolution 960x540 -s res://tests/car/test_real_doors.gd`
   (RESULT PASS and `OUT/real_doors_strip.png`). Review picture: `review/sakura_real_doors_strip.png`.

`build_linux_cloud.sh`: builds the native module for Linux in a cloud session (godot-cpp 4.5 at 27d9dd2 built once
with scons in /opt/native_tools); Yasin's PC keeps using `native/build.sh`.

## Not done / not checked
- Only the Sakura; only the front doors. The other 11 cars need their door outlines drawn (one list per car).
- Dents (`hit`) are drawn on the body only, not on the door meshes.
- The doors have no collision of their own (an open door passes through walls and people).
- Getting in (`test_car_entry.gd`) uses the driver's door through `set_door`; not re-run here (needs the player's
  clips). Nothing in the game opens the passenger's door yet.
- Two more draw calls per car with real doors (each door has its own material for its glass's cabin frame), one more
  while a door is open. Not measured on the phone.
- Tested in a cloud Godot 4.7.2 with the Compatibility renderer (no Vulkan here), not the Mobile renderer.

## 28 Nov: door depth, far wheels
- `cut_doors.py`: a door takes only what lies within `depth` (0.20 m) of the car's outer skin at that point of the side
  view (an outer-x grid, 4 cm cells). With the cabin modelled, the old `|x| > skin_x` also took seat bolsters and the dash's
  ends and the flat card went behind the deepest of them: half-metre black slabs beside every open door. The card is now
  the door's outward skin pushed in 8 cm (hidden behind the door's own modelled trim).
- `install_car.py`: the light model's wheels carry UV2.x = 10 + k; `traffic_car.gdshader` turns them about their hubs
  (`wheel_hub[4]`, from the body mesh's wheels meta) by the row's custom x (roll) and y (steer), set by
  `CityTraffic::mid_wheels`. No wheel batch at 22-85 m, no extra draw.
