# Bug board (Yasin, 20 Nov: "make these a bug board in the branch", "ill be adding more")

One line per bug or wish, in Yasin's words where he gave them. Status: OPEN, FIXED (with the commit / test), or
NOT REPRODUCED (what was tried). Add new ones at the bottom of OPEN. Owner: who works on it (this session = the
traffic / people / game session; "runtime" = the phone runtime / streaming session; "superchecker" = the city pieces).

## OPEN
| # | Bug / wish | Owner | Notes |
|---|---|---|---|
| B1 | "game crashes whenever we go to the main menu" | this session | NOT REPRODUCED on the PC: tests/game/test_menu_back.gd (New game in the real city, pause, Main menu, Continue, Main menu, New game) RESULT PASS, no crash. The phone's crash log holds one crash (19 Nov 17:33: a mutex used after it was destroyed, inside the engine during a frame), none from today. Next: the phone's logcat the moment it happens. |
| B2 | "we can click the hud but being able to control the character happens much later, i think the world load slow, hide it behind the loading" | this session | The loading screen ends after 45 quiet frames; the start hold (ground under the player) can end later. To do: keep the loading screen up until the player stands on the ground and can move. |
| B3 | "add ambient sounds based on zones" | this session | wish |
| B4 | "high quality car sounds with convincing shifts and higher gears" | this session | the car has no engine sound yet (CityCar); the gearbox exists in veh_dyn |
| B5 | "car is too prone to slide" | this session | CityCar's tyre grip / handling |
| B6 | "lod snaps in, we need to ease it in" (also "might be the same lod bug that makes tiers snap") | runtime | the bake's tiers (bake_runtime / city_stream) |
| B7 | "far roads stay loaded, roads never load outside of the city, once we get out of the car they load again"; "when roads dont switch, i fall into a gap" | runtime | streaming while driving; WayFloor (this session) covers the ways round the camera only |
| B8 | "next to where we spawn city centers corner pavements are missing" | superchecker | the pieces at the city centre (start: about x -12, z -606) |
| B9 | "small props should be breakable" | this session | the old game had world_fx breakables |
| B10 | "inspect for every animation in the game, talk, fight, walk etc, all of them" (frame by frame, as the climbs) | this session | tool ready: tests/people/trace_moves.gd (climbs); to widen to every clip and the crowd's people |
| B11 | the hands on a climb: held only while in reach (the 5 cm target met while holding); Yasin wants them pinned till he lets go | this session | test_step_up PASS; watch it |
| B12 | tests/game/test_start.gd failed once (no ground under the player 5 s in) | this session | flaky; streaming timing |
| B13 | tests/traffic/test_bike_hit.gd: once a hit rider's hips went 19 m up | this session | flaky; trace the rider when it happens |

## FIXED (20 Nov)
| # | Bug | Fix |
|---|---|---|
| F1 | "bike doesnt work, when we get on it our character becomes a grey person, bike doesnt move" | The rider now takes the player's body and clothes. The bicycle stood stuck on a kerb's edge: its body box went down to 7.5 cm; now from 35 cm up (the wheels' rays take kerbs). The old GET OFF plate drawn over the money box is gone. tests/game/test_start.gd: pedalling 3 s, 3.7 m/s, RESULT PASS. |
| F2 | "game just runs laps instead of showing the menu or releasing us into the world when started" | The app running laps on the phone is the measuring rig (com.yasin.citykit.rig, a lap plan). The game starts at the menu (game/boot.tscn); the worktrees under .claude/worktrees still start at the rig. rig.gd: started by the game it now ignores a measuring run's leftover user://rig_args.txt. |
| F3 | no way to get into a car on the phone | The Use button (GET IN / OUT, GET ON / OFF), tests/game/test_start.gd. |
| F4 | step-up jitter; climbs placed wrong; hands and feet off the surfaces | traced frame by frame (tests/people/trace_moves.gd), fixed: tests/people/test_step_up.gd RESULT PASS |
