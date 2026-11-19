---
name: coronado-city-interiors
description: Build the zero-loading walk-in rooms inside Coronado's city-kit buildings (map_dc/coronado/city_kit/interiors) - room contracts measured from the kit meshes, the shop assignment, hand-made rooms with room_lib (real doors and windows cut into the locked building at bake time, frames visible from both sides, hinged swing doors, kit indoor props page I), the indoor checker (check_rooms.gd, works like the city validator), preview shots in the city, and the interior-design rules Yasin set. Use for any city-kit room, "make the X interiors", a room that looks empty / wrong, windows, doors, or indoor props. Not the old game's shop rooms (shops/interior) - Yasin: the old game was flawed, build our own.
---

# City-kit interiors (started 17 Nov 2026)

Premise (Yasin): "indoors arent in other worlds ... walk into a readily waiting indoor room ... zero loading open world".
Every enterable room sits inside its kit building, behind that model's real door, on its floor, streamed with the city,
and is **seen from the street through real windows** (and the street from inside).
Rules from Yasin, in order:
- don't borrow from the old game: "the old game was flawed, implement your own solution"
- old-game props only after showing them to him
- visuals first: "they dont need to be interactable yet, make them look good"
- work like an interior designer and look at it from a customer's perspective

## Files (map_dc/coronado/city_kit/interiors/)
| File | What |
|---|---|
| `room_contracts.gd` -> `room_contracts.json`, `sample_buildings.json` | every door / window of every model, found from the atlas region its near-mesh quad maps to (`textures/city_layout.json` O_* regions), floors, inside boxes, bays per public door |
| `assign_samples.py` -> `assignment_samples.json` | which door of which building is which shop (52 in the 8 samples), with reasons; pictures in `pictures/` |
| `PLAN.md` | anchoring, streaming (wake by distance, pool), bake-time door / window cuts, costs |
| `rooms/room_lib.gd` | the room builder (below) |
| `rooms/rooms_<zone>.gd` | the hand-made rooms of a zone -> `rooms/<name>.scn` |
| `rooms/door_swing.gd` | hinged double-acting leaves: swing AWAY from the player within 2.2 m, close behind them |
| `rooms/check_rooms.gd` | the indoor checker |
| `rooms/room_shots.gd` | preview shots in the city (doors / windows cut in memory only) |
| `rooms/prop_facing.gd` | a kit prop rendered from four sides: which side is +Z |

## How a room is made (room_lib)
- **Frame:** author the room in the BUILDING MODEL's own frame (origin = footprint bottom centre, front = +Z). Place it with the building's transform. Walls 0.30 m, front wall 0.45 m inside the footprint.
- **Walls with openings:** `r.openings(contract, walls)` builds every ground-floor opening of the building from the contract.
  - Never type window or door coordinates by hand: hand-typed storefronts were 10 cm short and left gaps at the sides.
  - Entrances get `door()`: reveal through the wall, metal frame, a transom light over 2.3 m, hinged leaves (shop: aluminium glass pair, kick plate, push bars; civic: wood pair with glass), and a ground slab (`_slab`).
  - **Ground slabs at doors and storefronts are level and look like what they sit on** (Yasin 18 Nov). The kit's pavement stops ~0.45 m short of the facade with grass in the gap. A shop slab is the kit's own `g_concrete` mapped in world space (xz * 0.5, like the street), 1 mm over the sill, 0.9 m out, so the pavement runs through to the door. The room calls `r.place(piece, label)` for the world transform. A civic door (sill 0.3 m) opens onto the building's porch: only the doorway in the wall is filled, in the room's floor material.
  - Back and side doors get `solid_door()`.
  - Windows get `window()` by kind: reveals, a 3D frame at the facade that laps the cut by 3 cm, mullions by type, a storefront bulkhead and spandrel, an inside board, clear glass. Storefronts also get a plinth 0.9 m out.
- **One bay of a building:** for a row with several shops, pass the bay bounds. Only the openings inside the bay are built and cut; the other bays keep their painted fronts.
- **Four walls in one call:** `r.walls4(contract, X0, X1, ZB, ZF, F, H, outer)` builds the walls and every ground-floor opening inside the room. A bay room passes `outer = {"front": true, "back": true, "right": true, "left": false}`: the party wall gets no openings, and only the openings inside the bay are built and cut (the room's meta "cut" lists them, and room_shots cuts exactly those).
- **Props:** `r.prop(base, x, z, yaw, lift)` takes kit indoor props (page I, `props/indoor`) and kit foliage pots.
  - Outdoor kit props are welcome indoors where they fit (Yasin 18 Nov): vending_snack / vending_soda (gym, police lobby, laundromat soap machine), drinking_fountain, ice_chest, usps_collection_box, recycling_receptacle.
  - Facing: at yaw 0 a prop shows its +Z side. Left wall: yaw 90, right wall: -90, back wall: 0, front wall: 180. Which side +Z is was checked by rendering every prop from four sides (18 Nov) - never assume:
    - customer side at +Z: shop_counter, bar_counter, pastry_case, glass cases, fridges, shelves, washer, dryer (door), vending
    - STAFF side at +Z: cash_register (drawer), checkout_counter, laundry_counter, espresso_machine (group heads) - turn them 180 against the counter they sit on
    - office_desk: the knee-hole (sitter) is +Z, so desk yaw = chair yaw + 180; chairs, benches and stools face their yaw
    - filing_cabinet is plain black on all four sides (the kit model)
  - Check a new prop's facing with `rooms/prop_facing.gd -- --props=a,b --out=FILE` (the prop alone, four sides) before placing it. Each prop type is one MultiMesh with the kit's `prop_wear_fix` shader at the "clean" wear (0.2).
  - The shader applies the vertex colours: the plain material leaves plants white and upholstery grey.
  - Garden plants (`plant_bird_of_paradise` ...) have no pot: indoors use `plant_potted_*` or `prop_potted_plant`.
- **Light:** pendants or panels with real omni lights, and a daylight light at the window. The room draws only while the building shows its near tier (0-62 m); lights fade over the last 12 m.
- **Floor:** floors sit 2 cm over the piece's own ground (z-fight).

## Shop signs (`r.sign`, `r.make_signs`)
The kit paints fixed names into its models, and every copy of a model repeats them: 15 models say VILLAGE THEATRE and 8 say CROWN CAFE. Generic models have blank dark boards. A sign that names something else than the room behind it is the first thing a customer notices (Yasin: "it says cinema but inside isnt a cinema").
- `room_contracts.json` "signs" lists every board found in the mesh: SG_* regions (with the painted text) and "blank" boards (T_dark trim of sign size in the shop band).
- A shop room claims its building's boards: `r.sign(contract, facade, along, "TEXT", style, font)`, then `await r.make_signs(self)` before `build()`. That renders the text with the project's OFL fonts (`ui/fonts/Overpass.ttf`, `Nunito.ttf`) into one small atlas, Basis-compressed and embedded in the room scene. The plates sit 2 cm out from the board and draw to 160 m.
- Name every board of the building, blades and side boards included, and the neighbour's blank board in a row (use a real shop from `assignment_samples.json` "not_rehomed").
- Civic buildings whose painted sign already matches (PUBLIC LIBRARY, CITY HALL, POLICE, RECREATION CENTER) keep it.
- The room script's `_run` must `await` the shop functions; run it with the real renderer.

## Interior-design rules (customer's view)
- **Plenty of props from the start** (Yasin 18 Nov, and the job board's "lots of props, lively, lived-in"): a first draft already carries what the place needs to work and look used - leaflets by the door, end caps on aisles, staff chairs and files behind every counter, bins, plants in pots, notices, art, a second seat type. Read `map_dc/coronado/city_kit/JOB_BOARD.md` before a round.
- Enter and **see the service point**: counter, desk or till in view from the door. The first 1.5 m inside the door is clear (the decompression zone).
- **Queue space** in front of every counter (about 1.2 m); the staff side behind it is reachable (the checker's "reach").
- **Aisles** at least 0.9-1.0 m; tables with their chairs pushed in; seats face the window or the room, never a wall.
- **Windows** show the shop to the street: a display or seating in the window, nothing tall right behind the glass.
- **Back of house:** stock rooms, kitchens and offices sit behind a partition with a staff doorway lined up with the back door.
- **Counter set into a partition** (police front desk): leave the partition open over the counters with a header above 2.45 m; staff sit behind, the public queues in front, a staff door at one end. A counter standing in front of a closed partition leaves no room for staff.
- **Lived in:** wear decals where people walk, queue and work; prints and boards on the walls, never behind furniture; plants in pots.

## Indoor checker (`check_rooms.gd`)
It works like `tools/city/pilot/validate.gd`: "CHECK <kind> room: ..." per problem, then "CHECKS n problems", exit 1 on any. Run it after every room build.
- **overlap:** footprints from the kit manifests; a chair tucked under its table or desk is allowed
- **floating:** an item standing on nothing
- **wall:** out of the floor or into a partition
- **door:** anything inside the 1.4 m swing zone
- **reach:** a 0.25 m grid flood from the doors with body clearance; pots and bins are exempt
- **hidden:** a print or board with a taller prop in front; the pegboard over its workbench is allowed. Wall-mounted props are read from the manifests (`mount: wall`: poster_case, menu_board ...), so they are never "floating"
- **pot:** a garden plant on the indoor floor
Run it with the real renderer (MultiMesh data).

## Run (PC preview C:\ck_fix, Godot 4.7.2; same commands in a cloud preview with xvfb)
```bash
godot --path . --rendering-method mobile --resolution 320x180 -s res://map_dc/coronado/city_kit/interiors/rooms/rooms_<zone>.gd
godot --path . --rendering-method mobile --resolution 320x180 -s res://map_dc/coronado/city_kit/interiors/rooms/check_rooms.gd
godot --path . --rendering-method mobile --resolution 1280x720 -s res://map_dc/coronado/city_kit/interiors/rooms/room_shots.gd -- --out=DIR
```

## Locked rooms
All 12 room scenes (`rooms/*.scn`) are locked in `locked.json` "files" (Yasin, 18 Nov); `tests/city_kit/test_locked_pieces.gd` fails if one changes. A room script rebuilds every room it holds, so when adding rooms build only the new ones, or `lock.py unlockfile <path> --by=Yasin` on his word, rebuild, and lock again. Changes to `room_lib.gd` reach a locked room only through such a rebuild.

## Traps
- **A pier in front of the door:** some kit models paint their door partly behind their own pier (ck_brk3_corner2's corner pier covers 0.55 m of the Heave Ho door). `room_contracts.gd` records "clear" [s0, s1] when 0.2 m+ of a doorway is blocked by facade geometry within 0.6 m in front of it. `openings()` then builds the door in the clear part and closes the rest with a dark frame panel. Also flagged: spanish_white, twr_glass and the bigbox / industrial roll-ups.
- **Front-face winding:** Godot front faces wind clockwise, so a cross product of a kit triangle points inward. Flip it before deciding the facade.
- **Packed arrays:** `PackedVector3Array` inside an Array is copied on access, so appends vanish. Keep plain Arrays and pack at build time.
- **The old game's room builder** pulls in about 185 scripts (vehicles, UI, story). It can't run in the slim preview, and Yasin doesn't want it anyway.
- **The kit's door cut** must take the `near` node by name. The old `door_cut.is_near_mesh` would treat `mid` / `far` as near.
- **Cameras inside a building's walls** show "props in the open": check a camera is in the room before calling a finding (lesson from the 17 Nov audit).
- **Room cost** (PC preview, not a phone): 37-41 draws, 16-19k triangles per waterfront shop room. Measure every new room (room_shots prints RS_ROOM).
- **room_shots** takes `--only=room,room` and a door `along` per room (a row or a corner shop has several shop doors).

## Zone rooms (19 Nov)
The strip zone's room corrections (vending caps, max 2 wall items a wall, frame insets, nothing loose mid-room, chairs
face their desk, recycling bins outside, "add the fault to the checker") are in `.claude/skills/coronado-zone-growth/SKILL.md`.
