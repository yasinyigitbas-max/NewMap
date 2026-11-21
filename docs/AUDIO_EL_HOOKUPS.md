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
- Car (CityCar), running engine in `engine_sound.cpp` (recorded loops, the old generator is the fallback if the files are missing):
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
- Engine idle / rev: recorded loops `engine_{idle,rev_low,rev_high,rev_up}_<compact|v6|v8|diesel|ev>_0..1`. Equal-power crossfade and pitch 0.85..1.25 by revs; `engine_rev_up` on a sharp throttle-on. The player's car (no distance fall-off, B30) plus the nearest few traffic cars get the full layers (at most 10 loop voices). The old generator is the fallback if a class's files are missing (the player's car only).

## Hooked up (20 Nov, all C++ in native/src; Yasin: "make it c plus plus")
Shared: `el_sfx.h/.cpp` loads a numbered set once (imported, or the raw .ogg when not imported), picks a take at random and never the one played last, and plays one-shots on a self-freeing 3D (or flat UI) player; loops sit on a named child player.
- Player voice (CityPlayer, `audio/player/<m|f>/<kind>_NN.ogg`, gender from the body id "F.." / "M.."): jump (4 in 5), climb (a high wall always, a low one 3 in 5; a step up silent), hard landing (falling faster than 5.5 m/s), hit / knocked (take_hit, a knock > 2 m/s), punch (85 in 100), throw on a shove (CityTalk's shove event), breath after 8 s+ of running when he stops. `vocal(kind)` plays any kind from other code. Pain: a hard knock (> 6 m/s), thrown off his bicycle, a heavy crash at the wheel (sev >= 14; 8-14: hurt). Death is loaded and waits for a death state.
- Footsteps (FootSteps): run takes above 3 m/s; walk takes never twice running. Landing takes (`footstep_land_<surface>`) in CityPlayer on any landing from a jump or a drop.
- NPC voices (CityTalk): each person one of the 8 cast voices (`cast_voice`, from his look); barks in his voice: shoved (hit, again: angry), screams (scared), bumped (complain), a fight (angry), a car hits somebody (run_over, the nearest), a wave (greet), filming / calling / in pain near the player (photos / call_police / pain).
- Car (CityCar): door open / close from the door's swing, belt + engine start by class on taking the wheel, engine off + unbuckle on leaving it, lock chirp + clunk when he has walked off, horn key (H / pad Y) by class, tyre squeal loop by slip, skid (asphalt / sand) on a hard locked stop, sand slide loop, crash >= 10: glass + a creak 0.9 s later, crash >= 5: a scrape half the time, metal_scrape_loop while its side touches a wall or a car (the body's contacts, the player's car only).
- Breakables (CityBreakables): hit_bin / hit_fence / hit_pole by the item's kind when knocked down.
- Bike (CityBike): freewheel loop coasting, chain loop pedalling, bell (H / pad Y), brake squeal on a hard brake.
- Bus (CityTraffic, buses within 70 m): air brake + kneel beep + doors open on stopping at a stop, doors close leaving.
- Doors (CityRooms): wood / glass / metal open and close from the leaf's swing (shops: glass and the shop bell), room tone (shop / home / office from the room's name) from the nearest awake room within 14 m.
- Zone beds (CityAmbience): beach / marina / parks / downtown / homes from the place rings, 3 s crossfade, a zone must hold 3 s.
- Phone / UI (CityPhone, CityHud::stinger): ringtone looped until answered or hung up, msg_ping on a message, camera_shutter on a photo, app_tap opening an app, mission_start on a new mission (CityTalk::set_mission); `stinger("mission_pass" | "mission_fail" | "notify")` is there for the mission code.

## Still waiting
- bus_fare_chime: the player cannot board a bus yet. zone_hospital / campus / industrial: need a zone map. Player death: no death state yet.
