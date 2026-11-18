# Look pack, buildings (18 Nov 2026)

Yasin wants "a visible jump" in how the game looks. This is the buildings' half of a cheap look pack (the sky, haze and
colour half is done by another session in `tools/city/rig/rig.gd`). Three changes, all in the buildings' runtime
shader `map_dc/coronado/city_kit/shaders/rt/rt_bldg.gdshader`, each with its own switch. Nothing baked changes (no
re-bake needed), no locked piece changes (lock test RESULT PASS), no extra draw, no extra texture read.

Pictures: `map_dc/coronado/city_kit/review/look_18nov/buildings/` (1640x720 JPG, street level).
**Cloud pictures are not phone pictures:** the cloud's software GPU draws the weathered buildings about 40 % too dark,
draws no shadows, and the pictures run with sky reflections off (otherwise it draws the leaves black). The PC session
should take the real ones on the Redmi.

## The switches
Global shader values in `project.godot` `[shader_globals]`, 0 = off (the look before), 1 = on. All default ON.

| Value | Change |
|---|---|
| `ck_look_contact` | 1. contact darkening |
| `ck_look_windows` | 2. night windows |
| `ck_look_glass` | 3. glass by day |
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
- `rt_ground.gdshader` uses no occlusion although `ground_orm.png` has one.
- Cloud setup: Godot 4.7.2 from GitHub releases; `apt-get install mesa-vulkan-drivers`; do NOT point
  `VK_ICD_FILENAMES` at `/opt/lavapipe` (that build draws the trees black); and sky reflections off in cloud shots.

## Commands
```bash
NOSHADOW=1 xvfb-run -a godot --path . --resolution 1640x720 --rendering-method mobile --rendering-driver vulkan -s res://tools/city/look/look_shots.gd -- --out=res://map_dc/coronado/city_kit/review/look_18nov/buildings
```
Options: `--only=centre,apartments,pilot`, `--times=day,night`, `--sets=before,after,contact,windows,glass`, `--ao`,
`--cams=name:x,y,z:tx,ty,tz;...`, `--png`. Needs the baked city (`docs/RUNTIME_BAKE.md` "Commands").
