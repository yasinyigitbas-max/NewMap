# Performance on the phone, 20 Nov 2026 (the perf / bug-board session, branch claude/perf-bugs)

Phone: POCO X4 GT / Redmi Note 11T Pro (22041216UG, Dimensity 8100, Mali-G610 MC6), Android 13, the rig app
(com.yasin.citykit.rig) exported from this branch with the game's engine build (coronado_all7). 720p (scale 0.67) unless
said. Read `docs/DRAW_CENSUS.md` first: at 720p the phone lowers its GPU clock to just make 60 fps, so GPU ms at 720p
do not show costs; small costs need `--scale=1.5`. Two identical runs 3 minutes apart (19 Nov, people_on / people_on2)
gave 17.2 and 7.7 ms of GPU: one run is one run.

## 1. Crashes and freezes found and fixed

| What | Seen | Cause | Fix | Checked |
|---|---|---|---|---|
| The rig froze for good (03:14 and 03:30) | zones lap at 210 km/h; stream lap with traffic and people | leaving cells were freed only in frames with no cell loading (never at speed); 16k orphan nodes kept their buildings' slots in the engine's instance-uniform buffer (rt_bldg: 5 a building); it overflowed and the GPU hung (main thread stuck in vkQueueSubmit, stack in review/phone/crash_20nov_0314/freeze_threads_0320.txt) | buffer 65,536 -> 262,144 slots (4 MB); leaving cells freed on a reaper thread (stream3) | pb_zones: the whole lap, 210 km/h included; pb_stream_life: no freeze (with the earlier fix) |
| SIGABRT on going to the menu / quitting (B1, 3 tombstones of 19 Nov) | the end of walk runs | CityTalk::_exit_tree asked a raw pointer to the phone's speech plugin, already freed (symbolised: the same day's library rebuilt with symbols, code segment the same size to the byte) | the plugin held by its object id | pb_walk_quit: the world torn down with the plugin present, no crash |
| The native module would not load (found before install) | export log, Windows error 1114 | a Godot type (PackedByteArray) as a C++ static: built when the library loads, before the engine is connected | plain C++ statics; tests/game/test_native_load.gd | RESULT PASS |

## 2. Where the frame goes (phone runs pb2_*, 20 Nov, review/phone/pb2_*.txt)

The phone was hot for the census runs (battery 34.5 -> 38.3 C): read differences under ~1 ms as noise.

| Finding | Numbers | What it means / what was done |
|---|---|---|
| **The sea and the plane under it: 13 ms** | waterfront at 1.5x: 46.6 ms GPU with the sea, 33.4 ms with --sea=0 (pb2_census_base / _nosea) | the old census's "unexplained 30.9 ms". The sea's shader is cheap; two full-screen surfaces (the sea and the rig's 6 km green plane 2 m under it) were shaded under every building. FIX READY in C++ (CitySea, sea1): both drawn after the city (render priority), so hidden water is never shaded. Waiting for the script call sites to be switched (look.gd, rig.gd: Yasin's word). |
| Traffic and people | centre 31.1 -> 32.2 ms, apartments 42.4 -> 44.8 ms at 1.5x (pb2_census_life vs _base); main thread 0.3 + 0.3 ms a frame | life costs 1-2 ms at 1.5x; the ~40 fps of the life stream runs is the phone's heat cap (below) |
| The streamer's cleanup | 210 km/h + traffic + people: 6,686 parts waited (script); 0 waiting with the reaper thread | the freeze's cause, fixed (stream3, now C++ CityStream) |
| Teleports | 236 / 386 ms frames (pb_zones) -> 55 / 63 ms (pb2_zones) | removals no longer run while a place is prepared |
| Collision for stairs and columns (B15) | +2-11 % collision a zone (gritty 304k -> 337k units); bodies within 0.6 s | cheap |
| FXAA | 1.0-2.2 ms at 1.5x | a look change: Yasin's call |
| Sun shadows | 0.8-2.8 ms at 1.5x (2048 map: no saving) | a look change: Yasin's call |
| Plants (cut-out) | 0.3-3.2 ms (plants_opaque) | the tree models (docs/TREE_ARTIST_BRIEF.md) |
| Draw stalls on the CPU side | single frames of 35-47 ms in "draw" with the GPU at 14 ms, nothing loading | open: possibly the cleanup thread freeing render instances under the server's lock; the next phone build A/B's it |
| The tier fade (B6, rig --tiers) | the first five zones as without it (gritty 59.9, centre 54.8, waterfront 58.9, industrial 58.8 fps; apartments 52.2 -> 47.8); from the sixth on EVERY drive at 39.4-39.8 fps | the step is the phone, not the fade: at 38.5-39 C it capped itself near 40 fps. The fade's own cost looks small (apartments -4 fps); to be measured again on a cool phone before turning it on |
| **The phone's heat cap** | a sudden, flat 39.4-39.8 fps in every drive once the battery is past ~38 C (pb2_zones_tiers from 'pilot' on; the same ceiling in pb_stream_life / pb2_stream_life) | the '40 fps with traffic and people' was mostly this cap. Long runs must be read with the temperature; the game should lower its own load before the phone does (a heat-aware quality step: a candidate) |

## 3. The C++ streamer on the phone (pb3_zones, pb3_stream_life, pb4_zones)
- Day zones as with the script (55-72 fps; 210 km/h 54.8-54.9 fps); traffic and people 44-46 fps (the script's build 39.6-44.5); no freeze.
- A regression found and fixed: night drives had 33 frames over 50 ms each (pb3) - city_lights.gd reads the cell table once per cell and the
  C++ getter rebuilt it on every read (~20,000 builds an update). Kept and rebuilt only on change (stream5): pb4 night centre 48.8 -> 55.0 fps,
  gritty 51.7 -> 58.3 fps, no frame over 50 ms.
- Still failing the gate narrowly: teleport frames of 62-137 ms (the script build: 55-63) and 3-7 frames over 33 ms in a few zones. Open.
- The 76 "Failed to free RID" errors with traffic and people (B27): still there. Open.

## 4. Teleports, frame by frame (pb5 / pb6, the streamer's own report: "RIG teleport worst")
- After brk3 a cell's arrival costs 2.8-3.6 ms again (CityBreakables had searched every arriving cell inside its arrival frame: 25-27 ms).
- Driving is clean in every zone (pb5 / pb6: no frame over 50 ms; 0-3 over 33 ms a zone; 210 km/h 55 fps; night 55-58 fps).
- Teleport frames, two kinds:
  1. 32-48 ms (most): 11-21 collision bodies made in the frame (the 4x teleport budget), then 7-19 ms waiting for the physics thread.
     Under the 50 ms gate; it buys the quick "ready" (0.3-2.7 s). Kept.
  2. 62-355 ms (one or two a lap, the size varies run to run): the streamer did NOTHING in the frame (0.02 ms, nothing added or made,
     physics and render waits ~0) while one or two cells were loading on its loader threads. The main thread was held elsewhere - the
     19 Nov "draw stall while a heavy cell loads, not understood". Most likely the loader thread holding the graphics device while it
     uploads a big cell's meshes (resource load), and the frame's draw waiting for it. Engine level (Yasin: last resort); it happens
     only while a teleport loads (behind the fade, the old view still on screen), never in the drives. Open.
