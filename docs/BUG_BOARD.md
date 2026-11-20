# Bug board (Yasin, 20 Nov: "make these a bug board in the branch", "ill be adding more")

> **STANDING RULE (Yasin, 20 Nov): code for game systems is C++** ("code requiring systems must be C PLUS PLUS").
> Everything that runs in the game (per frame or per tick, any system: sounds, footsteps, vehicles, people, UI, streaming
> logic) goes in the native module (`native/src`). GDScript only for tools, bakes and tests.

One line per bug or wish, in Yasin's words where he gave them. Status: OPEN, FIXED (with the commit / test), or
NOT REPRODUCED (what was tried). Add new ones at the bottom of OPEN. Owner: who works on it ("people" = the traffic / people /
game session; "perf" = the bugs + phone performance session (branch claude/perf-bugs); "runtime" = the phone runtime /
streaming session; "superchecker" = the city pieces). Since 20 Nov 03:20 the perf session owns every OPEN line except
B10 and B11 (agreed with the people session).

## OPEN
| # | Bug / wish | Owner | Notes |
|---|---|---|---|
| B1 | "game crashes whenever we go to the main menu" | perf | FOUND AND FIXED on claude/perf-bugs: the phone's three crashes (19 Nov, review/phone/crash_20nov_0314/tombstone_19nov_*.txt) symbolised with the same day's native library rebuilt with symbols (code segment the same size to the byte): CityTalk::_exit_tree -> Object::is_connected on the phone's speech plugin through a KEPT POINTER to an object already freed: its signal lock was destroyed, SIGABRT. Only the phone has the plugin, so the PC test never crashed. Now held by its id and looked up each use (a freed one reads as none). Not yet run on the phone (Main menu round trip there next). |
| B0 | the rig froze on the POCO (20 Nov 03:14, zones lap, 210 km/h drive) | perf | FOUND: leaving cells were freed only in frames with no cell loading (never at 210 km/h): 16k orphan nodes kept their slots in the engine's per-building shader buffer, it overflowed (482 errors), the GPU hung (main thread stuck in vkQueueSubmit, review/phone/crash_20nov_0314/freeze_threads_0320.txt). FIX on claude/perf-bugs (4d069b2b4): removals go on under load, the buffer 4x. Not yet run on the phone. |
| B2 | "we can click the hud but being able to control the character happens much later, i think the world load slow, hide it behind the loading" | perf | FIX on claude/perf-bugs (4d069b2b4): the loading screen closes only once the player is let go (ground under him, he can move) and 45 quiet frames have passed; the bar stops at 95 % until then. Not yet run (test_start next). |
| B3 | "add ambient sounds based on zones" | perf | wish |
| B4 | "high quality car sounds with convincing shifts and higher gears" | perf | the car has no engine sound yet (CityCar); the gearbox exists in veh_dyn |
| B5 | "car is too prone to slide" | perf | FIX on claude/perf-bugs: traction and stability control in veh_dyn (the pedal eased off while a driven wheel spins past its grip peak or the body slides wider than 6-8 degrees), a touch more rear grip. Console test (native/tests/run_veh_test.sh) RESULT PASS: full throttle in a 50 km/h turn swung the tail 47-90 degrees on the rear-drive cars, now 7-29; sakura_t IV no longer spins in a steady turn; 0-100, braking and the handbrake turn about as before. Not yet driven in the game. |
| B6 | "lod snaps in, we need to ease it in" (also "might be the same lod bug that makes tiers snap") | runtime | the bake's tiers (bake_runtime / city_stream) |
| B7 | "far roads stay loaded, roads never load outside of the city, once we get out of the car they load again"; "when roads dont switch, i fall into a gap" | runtime | streaming while driving; WayFloor (this session) covers the ways round the camera only |
| B8 | "next to where we spawn city centers corner pavements are missing" | superchecker | the pieces at the city centre (start: about x -12, z -606) |
| B9 | "small props should be breakable" | perf | the old game had world_fx breakables |
| B10 | "inspect for every animation in the game, talk, fight, walk etc, all of them" (frame by frame, as the climbs) | people | tool ready: tests/people/trace_moves.gd (climbs); to widen to every clip and the crowd's people |
| B11 | the hands on a climb: held only while in reach (the 5 cm target met while holding); Yasin wants them pinned till he lets go | people | test_step_up PASS; watch it |
| B12 | tests/game/test_start.gd failed once (no ground under the player 5 s in) | perf | flaky; streaming timing |
| B13 | tests/traffic/test_bike_hit.gd: once a hit rider's hips went 19 m up | perf | flaky; trace the rider when it happens |
| B14 | "none of the shops appear in the game, i think they were forgotten to be cut in the bake step" | perf | the interiors (city_kit/interiors, room_lib: doors and windows cut into the locked building at bake time) are not in the runtime bake |
| B15 | "stairs around or columns under buildings dont have colliders, add them" | perf | open |
| B16 | "add footsteps to the game based on terrain" | perf | open; C++ (standing rule) |
| B17 | "we can see thru the windows of all cars up close, i mean see behind, its bugged" | perf | open |
| B18 | "new bikes and biking animations for npcs arent in the game" | perf | open |

## FIXED (20 Nov)
| # | Bug | Fix |
|---|---|---|
| F1 | "bike doesnt work, when we get on it our character becomes a grey person, bike doesnt move" | The rider now takes the player's body and clothes. The bicycle stood stuck on a kerb's edge: its body box went down to 7.5 cm; now from 35 cm up (the wheels' rays take kerbs). The old GET OFF plate drawn over the money box is gone. tests/game/test_start.gd: pedalling 3 s, 3.7 m/s, RESULT PASS. |
| F2 | "game just runs laps instead of showing the menu or releasing us into the world when started" | The app running laps on the phone is the measuring rig (com.yasin.citykit.rig, a lap plan). The game starts at the menu (game/boot.tscn); the worktrees under .claude/worktrees still start at the rig. rig.gd: started by the game it now ignores a measuring run's leftover user://rig_args.txt. |
| F3 | no way to get into a car on the phone | The Use button (GET IN / OUT, GET ON / OFF), tests/game/test_start.gd. |
| F4 | step-up jitter; climbs placed wrong; hands and feet off the surfaces | traced frame by frame (tests/people/trace_moves.gd), fixed: tests/people/test_step_up.gd RESULT PASS |
