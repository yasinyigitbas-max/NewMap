# Patch note: contact shadows between models into the bake (for the PC session; 18 Nov, look job 4)

The kit's occlusion is baked per model, so it cannot know where one model meets another. Prototype on this branch:
`tools/city/look/contact_proto.gd` (+ `contact_mul.gdshader`), pictures `review/look_18nov/contact_between/`. Switch:
`ck_look_between` (0 off). No screen-space AO, no texture read.

## What it does
- **A building on the pavement:** a ground strip along each facade of the building's footprint
  (`room_contracts.json` footprint_wd), 0.9 m out, darkest at the wall (multiply to about 0.55).
- **The wall under an awning:** awnings are found in the building's near mesh by their atlas texels (city atlas AW_*
  regions), grouped per facade; a wall strip under the awning's lower edge, 1.5 m down, darkest at the top.
- **Under parked cars:** there are no cars in the map yet; when the game's cars park, each car can carry the same: one
  ground quad under its body (dark 0.6 under the middle, 0 at a 0.4 m border), drawn with the same material. A car
  that moves keeps it under it (it is part of the car), one draw per car or merged per parked row.
- **Under balconies:** not done (the kit's balconies are iron props; the same wall strip under each, found from the prop
  list, would do it).

## Into the bake (`bake_runtime.gd`, after the buildings of a cell)
1. For every building of the cell (the loop that writes `Buildings`), add the four pavement strips and the awning wall
   strips of `contact_proto.gd` (`_quad` with the building's transform) to ONE per-cell mesh `contact`, vertex colour
   alpha = darkness. Awning boxes: compute once per lib mesh (cache by mesh key), not per instance.
2. Material: one shared `contact_mul.gdshader` material in `lib/` (move the shader to `city_kit/shaders/rt/rt_contact.gdshader`).
3. `visibility_range_end` 220 (mid tier end); no shadow casting.
4. Warm-up: add it to `lib/warm.scn`.
## Cost
- One draw per cell, ~400 triangles for the pilot area (39 buildings, 23 awnings).
- Per pixel: a multiply blend on the strips only (thin bands at building feet and under awnings): no texture read,
  ~4 ops; it is alpha blending, so it touches those pixels twice. Small next to the screen.
- Where the pavement is higher than the building's foot the strip can hide under the pavement (it sits 3 cm over the
  foot); the bake could lift it to the ground height (it knows the ground mesh).
