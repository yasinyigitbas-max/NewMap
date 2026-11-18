# Zero-loading interiors for the city kit: plan (17 Nov, interiors session)

Yasin's premise: "indoors arent in other worlds ... walk into a readily waiting indoor room ... zero loading open
world." Every enterable room sits inside its kit building, behind one of that model's real doors, on that
building's floor, and is ready before the player reaches the door.

## What exists now (this branch)
| File | What |
|---|---|
| `room_contracts.gd` | regenerates the contracts and the building list from the kit meshes and stats (Godot, headless, read-only) |
| `room_contracts.json` | one contract per model (99 models). Each has every door and window found in the near mesh (kind, facade, centre, width, sill, head), the floors with their clear height and inside box, and the entrances with the bay each public door owns and the room sets that fit it |
| `sample_buildings.json` | the 242 buildings of the 8 locked samples and the stadium, each with its model and every real door in world coordinates |
| `assign_samples.py` | the hand-made assignment table plus checks. It writes `assignment_samples.json` (52 rooms) and the picture labels |
| `assignment_samples.json` | the 52 enterable rooms: building, door, room set and size, the shop it re-homes (name, goods and hours from shops.json), and why |

### How the doors were found (measured from the meshes, not guessed)
Kit doors are painted onto the shell: each one is a quad mapped onto an opening region of the city atlas
(`textures/city_layout.json`).
- **Door regions:** shopdoor, civic_door, apt_door, patio, rollup, apt_slider.
- **Window regions:** storefront, win_*, glass_plain, civic_win and the others.
- **Method:** triangles mapped into a region are grouped per facade into rectangles. The ground floor sits at the lowest door's sill; upper floors come from the window sills.
- **Check:** for every shop, commercial, civic and urban model, the ground-floor front doors found match the model's own `doors_front` (count and position within 0.4 m).
- **Expected differences:** apartment and motel balcony doors, and garage roll-ups.
- **Not covered:** houses and garages use the separate house atlas, so their doors are not found. They are homes, not shop candidates.
- **Door sizes:** public doors are 1.0-2.4 m wide (median 1.6 m) and about 2.1 m high, so the game's shop door rectangle (1.1 x 2.4 m) does not fit them; each cut uses that door's own rectangle.

## 1. Placing a room (programmer's view)
- **Anchor:** piece + building label + door index, never a position. The world transform follows from the layout (piece position, yaw), the building's transform inside the piece, and the door's facade frame from the contract.
  - Pieces never move once locked, so the anchor is stable.
  - If a sample is copied or mirrored as a variant, the rooms come with it.
- **Room frame:** origin at the door's sill on the inside face of the front wall (0.45 m behind the facade plane). +Z points out through the door, X runs along the facade. The floor is at the building's ground floor: `building y + floors[0].y`. Each sample sits on a grading pad, so the y comes from the layout, never from the terrain.
- **Room size:** the set's maximum size, clipped to the bay the door owns. The bay is the inside width between the walls, or halfway to the next public door on the same facade, by the inside depth. The room is a box inside the shell's inner box. It never touches a window-wall it does not own.
- **Shell:** kit shells have no inside faces, so the room brings all of its own:
  - floor, walls and ceiling, as `shop_interior.gd` builds them today (one merged shell, the layout's style)
  - one inner face on each of the building's other walls inside the bay, if the bay is wider than the room, so the void never shows

## 2. Ready before the door (streaming)
- **Today:**
  - `door_gate.gd` holds one live interior for the whole world.
  - A room is either woken from its cell package (`r_*.scn`) or built over several frames when the player presses Use.
  - Building on Use is where the wait comes from.
- **Proposal:**
  - **Rooms are part of the cell:** each enterable room is baked into its cell's package, like the shops are now.
  - **Wake by distance, not by Use:**
    - A room wakes when the player is within about 35 m of its door: walking pace is about 1.4 m/s and driving is much faster, which gives at least 0.5 s of spread-out work.
    - It sleeps again beyond about 60 m, the kit's near-tier range: past that the door is drawn by the mid tier and the cut cannot be seen.
  - **A small pool instead of one gate:**
    - 2 rooms live and 1 more waking.
    - On a shopping street the next door is ready before the player turns to it.
    - The cap keeps memory flat.
  - **Spread the wake:**
    - Restore the package's mesh and colliders over frames, with the existing `build_step`, `attach_colliders(n)` and `res_prefetch`.
    - Don't draw the room until it is complete. `portal_cull.gd` already draws a room only through its open door.
  - **The door opens itself:** double-acting hinged leaves swing away from the player (in when they enter, out when they leave) when they are within about 2 m (`rooms/door_swing.gd`), and close again behind them. It never waits on loading: if the room is somehow not ready, the leaf stays shut until it is. That should never happen with the 35 m wake.
- **Costs (guesses, from the existing shop numbers, not measured on kit rooms or on the Redmi):**
  - Shop rooms cost at most +10 draws per view, and only while the door is in view and open.
  - With 2-3 rooms live, the CPU cost is waking one room every few seconds on a shopping street.
  - The phone run must measure the wake spike: the hitches skill has the tools.

## 3. Real doors in closed kit shells (the door-opening proposal)
**How the game does it today** (shops; see `shops/interior/door_cut.gd`, `cut_registry.gd`, `interiors_layer.gd`, `tools/gray_bake/bake_doorcuts.gd`, `bake_cellpkg.gd`):
- **Cut:** the near facade triangles inside the door rectangle and the trimesh collision faces there are cut out. Each cut triangle is split into at most 4 pieces outside the rectangle. Mid and far meshes are not cut.
- **Bake:** each cut is stored as a base mesh plus one plug per door. Open doors show the base; closed doors add one plug draw per cut piece.
- **Leaf:** a solid shut leaf with a collider fills the hole until the room is live; then it slides open.

**For kit buildings: do both, the same way.**
1. **Bake-time cut** of the near tier and the collision of every enterable door's building.
   - The cut goes into the baked data (dcut / cell package), **never into the locked piece files**: locked pieces stay byte-identical and the lock test keeps passing.
   - The rectangle is the door's own (width by sill-to-head from the contract), not the shop default.
2. **Mid / far tiers stay closed:** at 58 m or more the painted door reads correctly.
   - **Trap:** `door_cut.is_near_mesh` treats anything not named LOD1 / LOD2 as near, so the kit's `mid` and `far` meshes would be cut too. The kit path must pick the `near` node by name.
3. **Collision:** kit buildings collide as one trimesh of a box. The cut opens the box at the door; the room's own walls and colliders supply the inside, and the leaf blocks the doorway while it is shut.
4. **Hinged leaves** in the door's own size (a pair over 1.3 m), swinging away from the player on approach (`rooms/door_swing.gd`); a collider while shut.

**Costs** (from the last bake reports and the code, not measured on kit buildings):
- **Bake:** about 2.5 s per door, so 52 doors take about 2-3 min. It is part of stage D (dcut_pkg + verify_bakes).
- **Triangles:** about 2-4 extra triangles per cut triangle near the door. A kit door is one quad, so the cut is tens of triangles per building.
- **Draws:** +1 plug draw per cut piece while its door is shut, and about 2 draws per near leaf.

## 3b. Windows are real too (Yasin 17 Nov: "indoors need to be visible from outside too")
Tested on the three waterfront rooms (`rooms/`, pictures in `pictures/rooms/`).
- **The building:** the ground-floor door and window panels of an enterable building's near tier are cut at bake time, the same cut as the door. In the preview this happens in memory; the locked pieces are unchanged.
- **The room fills each opening with the real thing:**
  - reveals through the wall to the facade
  - a 3D frame at the facade, by window type, so the same frame is seen from the street and from inside: storefront mullions and transom, casement and civic mullions
  - the storefront's bulkhead and spandrel
  - an inside window board, which is a deep ledge on storefronts
  - one clear pane
- **What you see:** from the street, the lit room. From inside, the real street, with sun patches through the windows. No baked view textures are needed.
- **Distance:** the room draws exactly as long as the building's near tier does (0-62 m). Past that, the mid tier's painted windows take over and the room's lights fade over the last 12 m.
- **Cost, measured in the PC preview (not on a phone):**
  - each room is 26-32 draws and 13-16k triangles, plus one transparent pane draw
  - the cut adds nothing: 14-20 triangles are removed per building
  - the city is not hidden indoors, because the windows look onto it, so being inside costs about what standing on the street does

## 3c. Indoor checker
`rooms/check_rooms.gd` works like the city validator ("CHECK <kind> ..." lines, then "CHECKS n problems", exit 1 if any). Run it after every room build, next to validate / audit_trees / the lock test. It checks:
- **overlap:** props that overlap; a chair tucked under its table or desk is allowed
- **floating:** an item standing on nothing
- **wall:** a prop sticking out of the floor or into a partition
- **door:** anything in a door's swing zone (the door's width, 1.4 m in)
- **reach:** props no one can walk up to, and floor cut off from the door (0.25 m grid flood with body clearance)

## 4. What the bake needs
- **A kit door-cut source:** bake_doorcuts and bake_cellpkg must read doors from `assignment_samples.json` plus `room_contracts.json` instead of shops.json fronts. The cut finds the building through the piece + label anchor.
- **Room packages** (`r_*.scn`) per assigned door: today's shop bake with the new anchor. Each room's layout set and plan come from the shop entry it re-homes (name, goods and hours unchanged).
- **Switch-over:** shops.json stays live until integration, then a kit `shops` list replaces the OSM fronts. The 120 named shops not re-homed now are listed in `assignment_samples.json` under `not_rehomed`.

## 5. What waits for the rest of the city
- **The grown city:** the road fleet's blocks and the empty blocks. Their corner shops and any further rooms come after their pieces are locked, from the 8-28 rooms left of Yasin's 60-80.
- **Hero sites:** the hotel, the museum, the university, the hospital and the big department stores are one-of-a-kind interiors.
- **Floor heights on graded blocks:** the samples are on flat pads. Pieces on the residential rises need their pad y from the grading plan.
- **The player's flat:** it needs a kit apartment and its own door (home_flat.gd); not part of this list.
- **Public rooms:** the library, city hall and police are on the office set as a placeholder. They need their own public-room types (`public/public_room.gd` has library, gym, hospital and museum).
