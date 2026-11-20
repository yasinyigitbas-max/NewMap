# ElevenLabs sound effects: code hookups (20 Nov 2026)

What came in with the commit "Audio: ElevenLabs sound effects" and what code still has to play it. The file list with each file's trigger, levels and source take is in `audio/EL_MANIFEST.md` / `audio/el_manifest.json`.

Format: OGG Vorbis 44.1 kHz, mono (positional and UI), stereo only for the beds. Loops are cut seamless (equal-power crossfade of the end into the start); set them looping in code (`set_loop(true)`, as CityCrowdExtra already does for the murmur) or with `loop=true` in their `.import`. The new files have no `.import` yet: Godot writes them at the next editor open / `--import`.
Numbering: the new sets start at 0 (`_0` .. `_3`, `_000` .. `_004`); gull_call (1..5) and navy_jet_flyover (1..2) keep their old numbering.

## Plays now (same names, same paths)
- `audio/sfx/car_crash_heavy_0..2`, `car_crash_mid_0..2`, `car_bump_0..2` (CityCar::crash_sound), `audio/sfx/ui_tick.wav` (CityHud), `audio/amb/crowd_murmur.ogg` (CityCrowdExtra): replaced in place.

## Plays after claude/perf-bugs is merged
`city_ambience.cpp` and `foot_steps.cpp` live on claude/perf-bugs (739f8e7d), not on this branch. These files use their exact paths: the 8 beds `audio/amb/{pacific_surf,bay_lapping,gulls_shore,park_birds,night_crickets,wind,traffic_far,rain_loop}.ogg`, `gull_call_1..5`, `navy_jet_flyover_1..2`, `helicopter_flyover`, and `audio/steps/footstep_<concrete|dirt|grass|metal|sand|tile|wood>_000..004.ogg`.
On the merge git reports add/add conflicts on those .ogg files: take this branch's (new) version; the `.import` files come over from perf-bugs unchanged (Godot reimports). The new beds are ~28 s loops (the old were 30-146 s); FootSteps loads metal and tile only if they are added to its surface list.

## Needs code (new files)
- Footsteps (FootSteps): run speed (> ~3 m/s) -> `audio/steps/footstep_run_<surface>_000..004`; landing from a jump / fall -> `footstep_land_<surface>_000..003`.
- Doors (CityRooms, B34 door swing): `audio/sfx/door/door_<wood|glass|metal>_<open|close>_0..3`, shop doors `door_shop_bell_0..3`, locked doors `door_locked_rattle_0..3`.
- Car (CityCar), engine idle / rev stay synthesised in `engine_sound.cpp` (AudioStreamGenerator, samples cannot go there):
  - ignition `audio/sfx/car/engine_start_<compact|v6|v8|diesel|ev>_0..3` by price class; switch-off / stall `engine_stall_0..3`
  - `car_door_open/close_0..3` on enter / exit; `car_lock_chirp_0..3` + `car_lock_mech_0..3`; `seatbelt_buckle/unbuckle_0..3`
  - horn key: `horn_<compact|sedan|sport|van|bus>_0..3` by class
  - `tyre_squeal_loop_0..2` (3D, looping, volume / pitch by lateral slip); `skid_asphalt_0..3` / `skid_sand_0..2` on a hard locked brake; `slide_sand_loop_0..2` while sliding on sand
  - crash sev >= 10: layer `glass_shatter_0..3` over car_crash_heavy; wall side contact `metal_scrape_0..3`, sustained contact `metal_scrape_loop_0..2`; after a heavy crash `metal_creak_0..3`; breakables `hit_pole_0..3`, `hit_fence_0..3`, `hit_bin_0..2`
- Bike: `audio/sfx/bike/bike_freewheel_loop_0..2` (coasting, rate by speed), `bike_chain_loop_0..2` (pedalling), `bike_bell_0..3` (horn key), `bike_brake_squeal_0..3`.
- Bus (traffic bus_stop_tag): `audio/sfx/bus/bus_air_brake_0..3` on stopping, `bus_door_open/close_0..3`, `bus_kneel_beep_0..3`, `bus_fare_chime_0..3` when the player boards.
- Zone beds (CityAmbience, needs a zone map): `audio/amb/zone/zone_<downtown|homes|industrial|marina|beach|parks|hospital|campus>_0.ogg`, stereo loops, crossfade by zone.
- Room tones (CityRooms, while inside): `audio/amb/room/room_<shop|home|office>_0.ogg`, stereo loops.
- Phone / UI: `audio/ui/ringtone_0..2` (one ring cycle, loop until answered), `msg_ping_0..3`, `app_tap_0..3`, `notify_0..3`, `camera_shutter_0..3`, `mission_start/pass/fail_0..3`.

## Not in this commit
- Voices (NPC lines, barks, reactions, and the effort grunts jump / climb / hit / tired / death): on hold for Yasin's line-by-line review.
- Engine idle / rev: synthesised in code.
