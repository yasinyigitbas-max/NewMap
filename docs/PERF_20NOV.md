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

## 2. Where the frame goes (to be filled from pb2_* runs)
