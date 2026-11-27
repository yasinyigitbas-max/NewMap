# Vehicle fleet (new, made in Blender)

28 vehicles made from scratch for Coronado with the kit's Blender tools (`tools/vehicles/`). They replace the 12 old cars
(Sketchfab CC-BY and Quaternius models) once the game uses them. Same categories as the old set, more of each, plus
the service, emergency and work vehicles. All generic: no makers' shapes, badges, names or real people; plates blank;
the campaign vans' candidates are invented.

| class | vehicles |
|---|---|
| compact | `compact` (three-door hatch), `hatch` (five-door) |
| saloon | `saloon`, `saloon_exec` (long, chrome), `wagon` (estate) |
| sports | `coupe`, `sports` (low two-seater), `muscle` |
| suv | `suv`, `suv_large`, `crossover` |
| pickup | `pickup` (crew cab, open bed, drop-down tailgate) |
| service | `taxi` |
| emergency | `police` (cruiser), `ambulance`, `fire_truck` |
| van | `minivan` (sliding doors both sides), `van_panel`, `van_delivery` (high roof), `campaign_a`, `campaign_b` |
| truck | `lorry_box`, `tipper`, `garbage_truck`, `utility_truck` (aerial lift) |
| bus | `bus_city` (12 m), `bus_mini` (8 m) |

Triangles per vehicle (everything: body, every opening part, interior, wheels): cars 3,700-4,150, vans 3,200-4,000,
trucks 2,300-3,200, buses 4,200-4,600 (Yasin: "~4k, as now"). Exact numbers: `manifest_vehicles.json`.

## What each vehicle is made of
One glb per vehicle, `veh_<name>.glb`. Every part is its own node, **placed on its hinge or hub**, so the game opens
or turns it by rotating the node:
- `body` (the shell with real openings cut where the doors and lids are; chassis, cargo box, compactor, locker body...)
- `door_f_l`, `door_f_r`, `door_r_l`, `door_r_r` (hinge at the front edge, vertical axis; each carries its own glass,
  inner trim card and, at the front, the mirror); `door_s_l` / `door_s_r` sliding side doors (pivot at their front edge:
  the game slides them back); `back_door_l` / `back_door_r` barn doors (outer edge); `busdoor1_r`, `busdoor2_r`
  (folding bus doors); `door_b_r` (ambulance box side door)
- `bonnet` (hinge at the cowl), `boot` / `tailgate` (hinge at the roof or rear screen; the pickup's at its bottom edge)
- `bumper_f`, `bumper_r` (separate, for damage), `glass_front`, `glass_rear`, `glass_side` (fixed glass)
- `wheel_fl`, `wheel_fr`, `wheel_rl`, `wheel_rr` (at the hubs; dual rear tyres on trucks and buses), `steering_wheel`
  (at its centre)
- `interior`: cabin lining, floor, seats, dash, console; engine and engine bay under the bonnet; boot well
- extras with their own nodes: `lamps` (all lamp lenses, for lighting them), `lightbar` / `beacons` (flashing),
  `roof_sign` (taxi), `speakers` (campaign vans), `hopper` (refuse truck), `tipper`, `ladder` (fire truck), `boom`
  and `bucket` (utility truck)
- markers (empty nodes `mk_*`): `seat_fl` / `seat_fr` / `seat_rl` / `seat_rr` (hip points), `entry_l` / `entry_r`
  (where a person stands to get in), `head_l/r`, `tail_l/r`, `exhaust`

Frame: metres, Y up, **front +Z, left +X** (the driver's side), origin on the ground under the middle of the car: the
frame of the old cars and `CityCar`.

## Textures
Each vehicle has its own three maps in `tex/`: `veh_<name>_color.png` 1024 (sRGB, AO baked in; **alpha = the area mask
of `vehicles/car_paint.gdshader`: 1 = body paint, takes the car's paint colour; 0.5 = glass; 0 = own colour** -
liveries, trim, lamps, tyres, interior), `veh_<name>_normal.png` 512 (OpenGL / Godot), `veh_<name>_orm.png` 512
(R occlusion, G roughness, B metal). That is the shader's `use_maps` path. Two materials per glb: `veh_<name>` and
`veh_<name>_glass` (alpha blended, double sided: the interior shows through the windows).

## Not done yet (the next phases)
These are models only. The game does not use them yet: opening every door, the new damage, and making every vehicle
drivable and stealable are the next phases (C++, `CityCar` / `CityTraffic`). The far and mid traffic models of the new
fleet (cheap shapes for the multimesh rows) are not made yet either.

## Rebuild
`tools/vehicles/` (Blender 4.5): `blender -b -P vbuild.py -- <name|all> [--quick]`, `python3 vcheck.py`,
`blender -b -P vrender.py -- <dir> [names]`, `blender -b -P vpreview.py -- <dir> <name> [lo|hi]` (shape only, no bake),
`godot/godot_check.sh <godot>` (Godot 4.7 import). Review pictures: `previews/vehicles/`.
