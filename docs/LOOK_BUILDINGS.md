# Look pack, buildings (18 Nov 2026)

Yasin wants "a visible jump" in how the game looks. This is the buildings' half of a cheap look pack (the sky, haze and
colour half is another session's, in `tools/city/rig/rig.gd`), plus the PC session's queue of look jobs and the real
rooms behind every shop. All on branch `claude/look-buildings`, nothing merged. Locked pieces unchanged: lock test
RESULT PASS after every step. The rig and the bake / streamer were not touched; what needs them is a patch note in
`docs/look_patches/`.

**Cloud pictures are not phone pictures:** the cloud's software GPU draws the weathered buildings about 40 % too dark,
draws no shadows, and the pictures run with sky reflections off (otherwise it draws the leaves black). The PC session
should take the real ones on the Redmi. NOTHING here has been measured on the phone.

## After the merge into the working branch (19 Nov)
`rt_bldg.gdshader` now also carries the tier window (`rt_tier.gdshaderinc`, `ck_pivot`, `ck_win`) and the census's
`#ifdef CK_CHEAP` (colour only). Looked over after merging `claude/festive-faraday-20ltx2` (0b8ede7) back into this
branch: everything of the look pack sits in the full (`#else`) branch and reads right - the window cell (`v_win`) and the
atlas test (`v_city`) are computed after the tier collapse in the vertex shader, which only matters for collapsed
(invisible) vertices; the CK_CHEAP branch skips glass, windows, signs, contact and detail, as a "colour only" measure
should (so the census measures the whole look pack together, plus the kit's own wear). Re-baked (141 cells) and
re-shot: the centre and the high street by day and night look as before the merge. Lock test PASS.
- Rooms: four cloud sessions grow the residential, strip, industrial and gritty zones and make the rooms for their own
  new shops with `tools/city/rooms/room_gen.gd`. Do NOT run `room_gen.gd` without `--only=` over the whole
  `assignment_all.json`: it would rebuild rooms that are theirs.

## Everything at a glance
Switches are global shader values (`project.godot` `[shader_globals]`, 0 off / 1 on, all default 1), set from code with
`RenderingServer.global_shader_parameter_set()`. Pictures under `map_dc/coronado/city_kit/review/`.
| Change | Switch | Where | Pictures | Cost on the phone (estimate, not measured) | On by default on the phone? |
|---|---|---|---|---|---|
| Buildings sit on the street (kit AO in sunlight + a foot line) | `ck_look_contact` | `rt_bldg` | `look_18nov/buildings/*_contact`, `*_ao_*` | ~5 ops a building pixel, no read | Yes |
| Night windows, each its own light | `ck_look_windows` | `rt_bldg` | `look_18nov/buildings/*_night_*` | ~20 ops, night only, no new read | Yes |
| Glass reflects the sky by day | `ck_look_glass` | `rt_bldg` | `look_18nov/buildings/*_day_*`, `*_glass` | ~40 ops on glass pixels only, no read | Yes; measure |
| Props read their ORM map (queue 2) | `ck_look_propmaps` | `rt_prop.gdshaderinc` | `look_18nov/props/` | +1 read on near page-A prop pixels | Yes (it fixes a fault) |
| Props' normal maps (queue 2) | (bake) | patch `look_patches/prop_maps.md` | - | +1 read near, tangents in near batches | Yes, after the patch |
| Close-up wall grain (queue 3) | `ck_look_detail` | `rt_bldg` + `city_kit/look/detail_wall.png` | `look_18nov/detail/` | +1 read on building pixels within 12 m | Try on; the first to switch off if a frame step is lost (it is the only one that costs a read on large areas) |
| Contact shadows between models (queue 4) | `ck_look_between` | prototype `tools/city/look/contact_proto.gd`; patch `look_patches/contact_between.md` | `look_18nov/contact_between/` | +1 draw a cell, a blend on thin strips | Yes, after the patch |
| Far buildings' night windows (queue 5) | (`ck_look_windows`) | patch `look_patches/far_windows.md` | `look_18nov/far_windows/` | no read (mask in the atlas alpha), ~20 ops at night; +2 MB | Yes, after the patch |
| Shop signs glow at night (queue 6) | `ck_look_signs` | `rt_bldg` | `look_18nov/signs/` | ~12 ops on sign texels at night | Yes |
| Fake rooms behind glass (queue 1) | - | DROPPED: Yasin keeps real rooms | `look_18nov/waterfront_rooms/` | - | - |
| Real rooms behind every shop | (per room, visible to 62 m) | `interiors/rooms/` (162 rooms); patch `look_patches/rooms_bake.md` | `rooms_18nov/` | raw 26 draws a room, merged ~9; real lights 2-6 a room; glass is alpha-blended | Only after the merge and a light budget, and a run on the Redmi with and without |
What I would do on the phone first: one zones run with everything on, one with all `ck_look_*` = 0, one with only
`ck_look_detail` = 0; the rooms only once the bake carries them.

## The switches
Global shader values in `project.godot` `[shader_globals]`, 0 = off (the look before), 1 = on. All default ON.

| Value | Change |
|---|---|
| `ck_look_contact` | 1. contact darkening |
| `ck_look_windows` | 2. night windows |
| `ck_look_glass` | 3. glass by day |
| `ck_look_propmaps` | props' ORM maps (queue job 2) |
| `ck_look_detail` | close-up wall grain (queue job 3) |
| `ck_look_between` | contact shadows between models (queue job 4, prototype layer) |
| `ck_look_signs` | shop signs glow at night (queue job 6) |
| `ck_look_sky_top`, `ck_look_sky_horizon` | the day sky colours the glass reflects (set to the rig's sky; the sky session or the game's day cycle should set these to its own sky) |

From code: `RenderingServer.global_shader_parameter_set(&"ck_look_glass", 0.0)`. Takes effect the next frame, no reload.

## What each one does
**1. Contact (`ck_look_contact`).** Changed after the PC session checked the kit (Yasin: "our assets were supposed to
have AO already"): the kit already has ambient occlusion baked into the base colour and in the ORM texture's red channel,
and `rt_bldg` already used it (`AO = orm.r`, the wear's cavity and foot band). So no second foot or eave gradient was
added. What is added:
- `AO_LIGHT_AFFECT = 0.6`: the kit's own occlusion now also dims SUNLIGHT a little, not only the ambient light (before,
  recesses, sills and eaves were dark only in the shade).
- a thin dark line where a wall stands on the ground (bottom 0.45 m, at most 50 % darker at the very foot), so the
  building does not float on the pavement.
How visible the kit's existing AO is: `*_ao_off` / `*_ao_on` pictures (look changes all off in both; the AO switched off
in memory). Measured on the three `_a` views: it changes 4-5 % of the pixels by day by more than a small step, 2-3 % at
night. It is there, but subtle. The new contact change touches 3 % of the pixels by day, 1 % at night: also gentle, as asked.

**2. Night windows (`ck_look_windows`).** Before: 3 m x 3 m bays of world position, all one orange, so a big window was
cut into differently lit blocks and a whole tower looked like one orange chequerboard. Now:
- a window is found from its own geometry: each kit window is one quad showing one atlas window, and "place along the
  wall minus place in the atlas" is (nearly) constant over it. A 3 m cell of that value holds whole windows: measured on
  all 120 kit buildings, 4-6 % of window triangles are still cut, against about 40 % for the old bays. Wide glass bands
  (the towers) are cut into 3 m bays, which reads as offices.
- each window: on or off (a third stay dark, the rest switch on one by one at dusk with `ck_night`, as before),
  brightness 0.3-0.95 of the old maximum (kept under 1 so big shopfronts do not burn white), and a light colour: mostly
  warm bulbs (2700-3000 K), some neutral white (3500 K), one in twelve a
  dimmer, bluish cold tube or a TV. Two neighbouring windows on a floor share a colour (one home or office).
- it uses model space, so near and mid tiers of a building show the same pattern (no change when the tier switches),
  and the per-building `lit_seed` makes copies of a model differ.
- `ck_night` works as before; by day nothing is computed.

**3. Glass by day (`ck_look_glass`).** Glass is found from the ORM texture the shader already reads (roughness 0.08 and
not metal: in the kit's atlases nothing else is under 0.25). On glass: a sky gradient (`ck_look_sky_horizon` ->
`ck_look_sky_top`) picked by the reflected view ray, with a Fresnel rise at grazing angles; low windows reflect the dark
fronts across the street, high ones see over the roofs; each window leans a tiny bit and is a little brighter or darker,
so a glass tower shows panes instead of one sheet. It fades out at night. No texture: the brief allowed one texture read,
this uses none.

## Queue job 1, shop windows with depth: DROPPED (Yasin)
The PC session's queue asked for a fake room behind ground-floor glass (interior mapping). Yasin, 18 Nov: "we had fake
windows, i didnt like them and we switched to real indoor showing windows"; "we already have real indoor windows, and
id like to keep them, in the shops on water front"; "ideally, id like to have those store signs, real windows and see
thru doors of those shops all over the map". So no fake rooms: the prototype (a room atlas and a box behind the glass)
was taken out again before it was committed. Nothing of it is in the shader.
- The waterfront shops with real rooms were checked with the interiors' own preview:
  `review/look_18nov/waterfront_rooms/` (cafe, beach shop, marina and harbour office: signs, clear glass, furnished
  rooms). The look pack does not touch them: in the preview they use the kit's `bldg_wear` shader, and once the bake
  cuts their windows, what shows is the room's own clear glass, not `rt_bldg`.
- FOUND: the real rooms are NOT in the runtime bake yet (`bake_runtime.gd` has no rooms and no window / door cuts;
  `interiors/PLAN.md` sections 3-4). In the streamed city on the phone these shops show the kit's painted glass, and
  the look pack's glass and night windows apply to it like everywhere else.
- Real rooms everywhere (Yasin's wish), what it takes: 12 rooms are built (4 waterfront, 4 civic, 4 apartments) of
  52 shop doors assigned in the 8 sample zones; the whole city has roughly 100 buildings with about 150 shop doors (a
  count from the baked cells and `room_contracts.json`, approximate). Each room is designed by hand with `room_lib`
  (the interiors skill) and checked; each brings its own signs. The bake then has to cut the doors / windows and pack
  the rooms into the cells (PLAN.md section 4), which is the streaming work the PC session is changing now. Phone
  cost: each room adds draws and lights while within 62 m; not measured on the phone.

## Rooms on all shops (Yasin, 18 Nov: "i want them on all shops")
Real rooms behind every shop front of the map, seen through real windows and glass doors, the shop's own name on its
sign board. Instead of fake rooms (dropped, see above).
| Step | State |
|---|---|
| Who is where: `tools/city/rooms/list_buildings.gd` -> `interiors/all_buildings.json` (242 buildings); `assign_all.py` -> `interiors/assignment_all.json` | 161 shops: the samples' 52 kept as they were, 109 new by district, what the building fits and its neighbours (no kind twice in one building, rare kinds not repeated nearby, the building's own name first, names made up). A supermarket's other doors stay its exits |
| Rooms: `tools/city/rooms/room_gen.gd` (the interiors' `room_lib`, 23 shop kinds) -> `interiors/rooms/g_*.scn` | 150 generated + the 12 hand-made ones untouched. Fitted to each building's measured walls, door and windows; service point in view of the door, door swing and the walk to the counter free, queue and staff space, 1 m aisles, low display or seats in the window, back of house behind a partition, plants, bins, prints, wear. Indoor checker (`interiors/rooms/check_rooms.gd`): **0 problems over 162 rooms** |
| Pictures: `tools/city/rooms/gen_shots.gd` | `review/rooms_18nov/` (high street day / night / closed, each shop outside and in, city centre) |
| Phone cost: `tools/city/rooms/room_merge.gd` (prototype) | a room 26 -> 9 draws (4,249 -> 1,435 over all rooms): props in one mesh with the city's own prop material, the shell in one mesh over `runtime_tex/arr_room.png` (`make_room_array.py`). Looks the same; the walls lose their bump maps |
| Into the streamed city | NOT done: the bake must cut the openings and pack the rooms (`docs/look_patches/rooms_bake.md`; the bake is the PC session's work now) |
- Raw rooms add 57-122 draws to a high-street view (`amber_*` against `amber_*_closed`); the phone's budget is 150 a
  view, so the merge (or something like it) is a must before they go on the phone. Lights: a room has 2-6 real lights;
  the patch note proposes real lights for the nearest rooms only.
- Generated, not hand-designed: the rooms follow the rules but are plainer than the hand-made ones (fewer one-off
  touches). Yasin should look at the pictures and say which kinds need a hand pass.
- Not checked: on the phone (draws, pixels, lights), and the generated rooms' signs at night.

## Queue job 2, props' maps (`ck_look_propmaps`)
Why most near props had no normal or roughness map: `kit_lib.prop_wear_mat()` names a prop material by its colour atlas
only; the first prop to make each file was a mid tier without maps, and every near prop of that page reuses it. 6 of
the 18 `materials/pw_*.tres` have no maps: the main prop page A (benches, bins, lamps, kerb inlets) at every wear, and
page W two-sided. Without an ORM the shader took those props as fully metal and fully rough.
- Fixed in `rt_prop.gdshaderinc`: with `ck_look_propmaps` = 1 (default) near props always read their page's ORM layer
  (the texture array has it for every page). Pictures `review/look_18nov/props/` (`corner`, `bench`): the false metal
  shine goes, concrete and plastic read as such; 6-10 % of the pixels change.
- Normal maps: need tangents the bake does not write for these props: `docs/look_patches/prop_maps.md`.
- Cost: one more texture read (ORM) on near pixels of page-A props only; with the patch, one more (normal).

## Queue job 3, close-up detail (`ck_look_detail`)
Walls go soft at arm's length (one atlas texel is 1-2 cm of wall). One small tiling grain texture
(`city_kit/look/detail_wall.png`, 256 x 256 grey, made by `tools/city/look/make_detail.py` from noise, VRAM-compressed
with mipmaps) multiplies the wall colour by about +-10 %, world-mapped (0.7 m tile, the same planar mapping as the
grime), full strength to 4 m, gone by 12 m, never on glass. Pictures `review/look_18nov/detail/` (1 m and 5 m).
- Cost: one texture read on building pixels within 12 m of the camera (a branch skips it beyond), ~6 ops. None farther.
- Tunable per material: `detail_amount`, `detail_m`, `detail_near`, `detail_far`. Not checked: how it reads on the phone's
  720p screen (the effect is small by design; it may be too subtle to notice there).

## Queue job 4, contact shadows between models (`ck_look_between`, prototype)
Where one model meets another, which the kit's per-model occlusion cannot know: the pavement at a building's foot (a
strip along every facade, 0.9 m out) and the wall under an awning (found from the awning texels in the mesh, 1.5 m
down). `tools/city/look/contact_proto.gd` builds them for chosen cells into one multiply mesh (`contact_mul.gdshader`,
no lighting, no texture read): the pilot area = 39 buildings, 23 awnings, 358 triangles, one draw. Pictures
`review/look_18nov/contact_between/` (`awn`, `foot`). Parked cars: none in the map yet; the patch note says how a car
would carry its own. Into the bake: `docs/look_patches/contact_between.md`.
- Cost: one draw per cell; a blend on the strips' pixels only, ~4 ops.

## Queue job 5, night windows at a distance (patch note; `rt_far` is not mine to edit)
Far buildings (beyond 220 m) did not light their windows (the far atlas has no glow mask). Cheapest way: the window
mask goes into the far atlas's ALPHA (`tools/city/look/make_far_glow.py` finds the painted windows: 9.9 % of the atlas),
and the far shader lights it at night with the near windows' rule and palette: no extra texture read. The change to
`rt_far.gdshaderinc` and the bake is written out in `docs/look_patches/far_windows.md`; tried in memory
(`tools/city/look/far_glow_shots.gd`): `review/look_18nov/far_windows/`.
- Cost: no extra read; ~20 ops on far-building pixels at night only; +2 MB for the atlas's alpha.

## Queue job 6, signs at night (`ck_look_signs`)
The kit paints its shop names into the city atlas (sign boards, `city_layout.json` SG_*). At night, in `rt_bldg`, the
texels of those boards glow: the letters (lighter than their board) strongly, the board a little, like a lit box sign;
one sign in seven flickers slowly and irregularly (a time hash per sign and building). Only the city atlas has signs;
which atlas a material uses is read from one fixed texel per VERTEX (no per-pixel cost). Pictures
`review/look_18nov/signs/` (`*_night_no_signs` / `*_night_after`): 1-3 % of the pixels change in a street view.
- Cost: no texture read (the albedo is already read); on sign texels at night ~12 ops; elsewhere a branch on a uniform
  and one range test. Flicker can only be seen moving (not in a still).
- Not covered: the kit's billboards and blade-sign PROPS (prop shader), and the generated rooms' own name plates
  (`room_lib` sign mesh: they would need an emissive letter colour at night; for the room bake).

## Picture files
`<view>_<day|night>_<set>.jpg`, views `centre_a/b` (city centre, 0,-600), `apartments_a/b` (250,-600), `pilot_a/b`
(high street, 0,0), eye 1.7 m above the road. Sets: `before` (all three off) and `after` (all on) for every view;
for the `_a` views also each change alone (`contact`, `windows`, `glass`) and the kit's own AO off / on
(`ao_off`, `ao_on`).
What to look for: by day the glass (tower in `centre_a`, shopfronts and upper windows everywhere); at night the
windows. The night "after" is less orange than "before": warm, with some neutral and a few cold windows, instead of
one orange everywhere. If Yasin prefers the old orange, `ck_look_windows = 0` gives it back, or the mix can be tuned.

## What it should cost (per pixel, building pixels only)
No new texture read, no screen-space effect, no new draw, no new material.
| Change | Per building pixel | When |
|---|---|---|
| contact | ~5 arithmetic ops (one smoothstep, multiplies); `AO_LIGHT_AFFECT` adds a multiply per light | always |
| windows | ~20 ops more than before (two `sin` hashes instead of one, a few mixes); same emission read as before | night only (uniform branch, `ck_night > 0`) |
| glass | ~6 ops to find the glass; ~40 more on glass pixels only (hash, two normalizes, reflect, Fresnel) | day (on glass) |
| vertex | one more varying (2 floats, `v_win`) and ~6 ops per vertex | always |
A guess, not measured: a few percent of the building shader's cost, under 0.3 ms a frame at 720p on the Mali-G610.
The phone sits at the 60 fps step at 720p, so it shows only if it pushes frames over the step.

## Not checked (needs the phone / the PC)
- How it looks on a real GPU (the cloud draws buildings ~40 % too dark, so the glass and the contact line look
  stronger in the cloud pictures than they will on the phone, the windows the same).
- The frame cost on the Redmi: run the zones plan with all three on, then with `ck_look_*` = 0 (needs a rig switch or
  the args file, the rig was not touched: the sky session owns `rig.gd`).
- With shadows on (the cloud draws none): the contact line and the sun-dimmed AO next to real shadows.
- Mid tier at 60-220 m: should show the same, from the code; looked at only in the pictures' background.
- Far tier (beyond 220 m, `rt_far`): unchanged: far buildings get no glass and no night windows (as before).

## Found on the way (not fixed)
- (Corrected 18 Nov.) An earlier note here said `rt_ground.gdshader` ignores an occlusion map. Wrong: the city's ground
  is drawn from nine tiling textures (asphalt, concrete, grass, dry ground, travertine, two road-line sheets, gravel,
  sand; `make_arrays.py` "ground"), and none of them has an occlusion map. `ground_orm.png` belongs to the kit's ground
  atlas, which the built ground does not use. So there is nothing there to switch on. Grass, gravel and travertine do
  have normal maps; using them would be one more texture read on the ground, which covers most of the screen: the most
  expensive pixels on the phone. Not done.
- Cloud setup: Godot 4.7.2 from GitHub releases; `apt-get install mesa-vulkan-drivers`; do NOT point
  `VK_ICD_FILENAMES` at `/opt/lavapipe` (that build draws the trees black); and sky reflections off in cloud shots.

## Commands
```bash
NOSHADOW=1 xvfb-run -a godot --path . --resolution 1640x720 --rendering-method mobile --rendering-driver vulkan -s res://tools/city/look/look_shots_bld.gd -- --out=res://map_dc/coronado/city_kit/review/look_18nov/buildings
```
Options: `--only=centre,apartments,pilot`, `--times=day,night`, `--sets=before,after,contact,windows,glass`, `--ao`,
`--cams=name:x,y,z:tx,ty,tz;...`, `--png`. Needs the baked city (`docs/RUNTIME_BAKE.md` "Commands").
