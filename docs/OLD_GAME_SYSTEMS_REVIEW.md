# The old game's systems, one by one: what could be made faster (18 Nov 2026)

Yasin: "check old games systems one by one, and tell me which ones can be made faster and honestly tell me if you
cant make any of them any better."

How this was done: READ ONLY, in `yasinyigitbas-max/coronado-source` at `bd26fce` (code and docs only; nothing was
run, nothing changed there). Five reviewers read the code in parallel; I read the game's own phone reports
(`PERF_*.md`) and checked the strongest claims in the code myself. Every "could save" figure is an estimate unless
it says measured. The phone numbers in that repo are from 11-13 Nov and several systems were rewritten since, so
some have no phone number at all. File paths below are in coronado-source.

## The measured picture (the old game's own Redmi numbers, High preset, 11 Nov)
- 38-43 frames a second. GPU 14-20 ms a frame, scripts 9-11 ms, physics 2.4-3.4 ms, draw preparation 2.8-4 ms.
- The GPU is limited by pixels, not by geometry: about 15 of 20 ms scale with pixels shaded. Road shader 7.6 ms and
  terrain 2.1 ms (both since reworked), sun light + shadow lookup 3.5-4 ms, render scale is the biggest lever.
- Main thread: traffic 2.5-3.2 ms (since rewritten in C++), physics, streaming while driving about 4 ms, crowd.
So no single system hides a 2x gain. What is left is medium and small.

## Verdicts
| System | Faster? | What, and how much |
|---|---|---|
| Cell packages (the 100 m world cells) | YES, medium | Each package arrives as a node tree with its own material copies; far facade kits are one draw per building chunk (21-26 draws, the largest source). Share materials, merge far kits and props per 400 m at bake, ship meshes + data instead of nodes: about 60-70 fewer draws of ~190 (est. 0.6-0.7 ms) and less streaming work. Not a repeat of the new map's 942 -> 65: the old game already sits near 200 |
| Far areas (distant buildings, storefronts) | YES, medium | The far mesh is REBUILT and uploaded whenever the camera moves 0.25 m or turns 0.5 degrees (`buildings/coronado_buildings.gd:22-23`); far merge 0.5-0.8 ms measured, and it sits in 16 % of shader-compile frames. A load-once far world with a per-object distance cut removes the rebuilds and uploads. Needs an S23 check (Adreno is geometry-sensitive) |
| Building streaming | YES, medium (not proven) | Every streamed node passes 16 tree-wide hooks and is classified by path-string tests whose answers are known at bake time. Goes away with node-free packages. Measured today: buildings 1.5-1.9 ms and late work 2.0 ms while driving |
| Walk-in rooms (shops, public, hotel, home) | YES, large for waiting, none for fps | Rooms are NOT already there: Use on a door starts the load, one room in the whole world (`doors/door_gate.gd:7`), polled every 0.25 s, so at least 0.5-0.75 s by my reading; old phone hitches of 293-667 ms are recorded in the code. Baking each room into its building cell removes the load path. Steady cost is only 0.3 ms |
| Loading at start | YES, medium (seconds) | 26-50 s to "world ready" on the Redmi. The shader warm-up list is rebuilt every start (loads up to 260 room scenes and 600 materials), nothing loads while the player sits in the menu, fixed waits (4 s camera spin, 65 idle frames). Trees: 9 of 14 s of staging in the cloud, big JSON parsed at boot |
| Road shader | YES, small to medium | Was 7.6 ms; about 2 ms left by subtraction (not measured). Three procedural noises per pixel (12 hashes) could be baked to small textures with the same look; less anisotropy would look blurrier |
| Sea shader | YES, same look, only at the water | 13 depth reads in a loop with sin and cos per pixel (`terrain/water.gdshader:27`), plus one texture read whose result is multiplied by 0.0 (`:49-50`). Blur the depth map once at load. Never measured |
| Parked cars | YES, small | Near cars are drawn twice: the "shadow proxy" batch is visible, casts no shadow and is filled with every car under 35 m (`vehicles/parked_cars.gd:70-76, 243-248`): up to 10 wasted draws and double-shaded pixels. All ~50 batches are re-uploaded every 0.1 s, changed or not |
| Traffic (C++ core) | small | Already rewritten: 2.4 -> 0.15 ms a tick in the cloud. Left: the step runs on the main thread, the per-tick snapshot for scripts is rebuilt because the hit checks read it, every car gets a full rig even at 400 m. Perhaps 0.5-1 ms on the phone in total (guess; no phone number since the rewrite) |
| Player car | small | Physics is the engine's; wheel visuals are still script every frame (0.2-0.3 ms guess) |
| Terrain | small | Shader already baked (5-12 reads, no loops). Ground outside packages could go from 12 draws to 3-4 |
| Road streaming | small | Far roads are swapped per chunk set; one static far road mesh per block would end the swapping |
| Sun and shadows | small | 3.5-4 ms is the per-pixel light, inside the engine's shader; shadow settings measured as no gain |
| Night lights, fog, film look | small | Cheaper versions look different. Real lamp lights (24) and car beams were added after the last measurements in the repo: a night lap is not in the docs I could read |
| Foliage, far crowd | small | Cheaper shading was already tried and rejected as visible |
| Autoloads as a whole | small | 49 autoloads, 36 tick. `debug/activation_timings.gd` is ON in every build and writes a log each second; those logs are never deleted in normal play (they pile up on the phone). 0.3-0.6 ms guess |
| Voice, radio | small | One hitch when the radio station changes (a sync load) |
| Sky | NO | One table read; already at the floor |
| Terrain shader, building and prop shaders, car paint | NO | 1-2 reads; cheaper lighting was tried and rejected as visible |
| Near crowd (18 skinned bodies) | NO | Only fewer bodies would help, and that would be seen |
| HUD and minimap | NO | Ticks at 5 Hz, minimap baked at 10 Hz |
| Colliders | NO | Baked, attached 1-4 a frame, nearest first |
| Frame budget and loader | NO | Sound as built |
| Physics | NO | Jolt on its own thread at 30 Hz already |
| Player, save, settings, story, jobs, economy, delivery, minigames | NO | They cost so little that a speed-up would not be felt (each under 0.25 ms; most tick at 2 Hz or on events) |
| Small world layers (landmarks, vendors, decals, beach ...) | NO | Under 0.03 ms each in the cloud |

## What would break at 280 km/h (the old fastest car: 210)
- **Tunnelling:** no continuous collision on the car. At 30 physics ticks a second it moves 2.6 m a tick; sign posts
  are 5 cm and signal poles 14 cm in radius.
- **Steering:** the steering limit stops shrinking at 91 km/h (`native/src/car_core.cpp:755`).
- **Traffic ahead:** cars spawn 70-340 m round the camera and never closer than 160 m in view: 2.3 s of travel. The
  road ahead would thin out. Needs a ring pushed forward with speed.
- **Parked cars:** one cell attached per 0.1 s; the 400 m front needs about 25 a second.
- **Engine sound:** the fastest class has no gear table; the last shift is at 130 km/h.
- The old streamer assumed 130 km/h as "above every car's top speed".

## What this means for the new game
- The three world systems that CAN be made clearly faster (packages, far areas, building streaming) are exactly what
  the new map's bake and streamer already do differently (shared models, merged batches with a per-object distance
  cut, one always-loaded far world, no node tree per object).
- The rooms' zero-loading rule was not met by the old game's design; the new interiors plan (rooms inside the
  building, woken by distance) is the right direction.
- The parts I cannot improve (physics, HUD, save, story, jobs, the simple shaders) can be taken as they are IF Yasin
  wants them; nothing here says they must be rewritten for speed.
- The GPU is pixel-bound: for the new game the levers are render scale with the SGSR upscaler, cheap ground and road
  shaders from the start, and keeping real lights inside the light grid's budget.

## Stale notes found on the way (in coronado-source)
- The perf-ideas skill says the render and physics threads are not set; `project.godot:109, 140` set both.
- The phone skill says the game ships capped at 30 fps; `project.godot:16` is 0.
- Docs still describe `TrafficVis` and a script fallback; the code uses `TrafficDraw` with none.
