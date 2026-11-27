# Traversal job board

Read this first, and again after every context compression. Keep it current: tick an item when it is committed and
pushed, add a new one the moment Yasin asks for it, never delete his rules. Work the queue from the top.
The state of what is built is in `reports/TRAVERSAL STATUS.md`; this file is what is left to do.

## Rules (Yasin)

1. **Remember the study.** Before every step, and after every context compression, read the whole of
   `reports/Hybrid character traversal study.md` and `traversal_lab/study/README.md` again. Follow it "LIKE THE HOLY
   BOOK". A number the study does not give is marked `NOT in the study` in the code and told to him as mine.
2. **Run the audit on everything.** `godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/audit.gd`
   on the exact tree before every commit that touches `traversal_lab/`, and every stage test
   (`tests/test_stage0.gd` to the newest; stage 1 with `-- --minutes=10`). Read the results before saying anything
   about them. The audit stands at 26 of 114 failing; it must not get worse. `bars.json` and `tests/audit.gd` are
   locked: if a line fails, fix the movement, never the line.
3. Change only what he points at. Nothing that was approved is broken, no system-wide edits, no change to every clip.
4. Commit and push after every step, to `claude/intelligent-bardeen-errnbs` only. No pull request, no push to main
   without his word. Never `git add -A`. Raw Mixamo and Kimodo files stay out of git. No keys in files or chat.
5. Before sending an exe: export the pack, start it from an empty folder, count `SCRIPT ERROR` (must be 0).
6. Reports: plain words, short, what was not checked and what was not seen in frames.
7. Kimodo takes: "pick the least wrong ones and fit them into our system". Check the Drive first.

## Queue

- [x] 1. (trav71) Mirror the takes of the squeeze through gaps (27 Nov: "also mirror the squeeze in gap takes"), so that he
      can go through facing either wall.
- [x] 2. (trav72) Stage 17, what is left: the wall-ledge sidle (the study: "For a ledge with a wall behind, allow a sidle
      down to about 0.10 m"). The course has no such ledge: build one in the test.
- [x] 3. (trav73) (27 Nov: "Open the arms to both sides during squeeze in tight places. Also open arms to sides on sidle, head
      should look towards the direction we are moving") and the wall-ledge station on the course ("yes add wall ledge
      station, how else am i supposed o test?").
- [x] 4. (trav73) (27 Nov: "also play the sideway squeeze in any passage smaller than 60cms"): sideways in every gap under
      0.60 m. His word over the study's shoulder turn for 0.45 to 0.60 m.
- [x] 4b. (trav74) (27 Nov: "make the palms face the wall instead of ground on both ledge and squeeze in").
- [x] 5. (trav77) Stage 21: cover, low and high: enter, peek, exit (27 Nov: "Oh I forgot about covers, add them in
      too").
- [x] 6. (trav75) Stage 22: doors: push, then pull.
- [x] 7. (trav76) Stage 23: cars: entry and exit. The bonnet slide is NOT built: no clip exists for it.
- [x] 8. (trav76) Sitting and phone use (27 Nov, his list): stand to sit, walk to sit, sitting idle, sit to stand, sitting
      phone talk, sitting messaging, sitting to type, walking text, standing text, standing call.
- [x] 9. (trav76) Then an exe of all of the above for him.
- [x] 9b. (trav81) The phone grips while walking and seated (27 Nov: "fix the seated and walking phone grabs too").
      Checkpoint 3 taken after it at his word ("after its done take a check point, dont move upto the ragdolls just
      yet"): it is in `reports/TRAVERSAL STATUS.md`.
- [ ] 10. STOP HERE AND WAIT FOR HIS GO (the checkpoint is taken: checkpoint 3). On his go: the ragdolls (27 Nov: "push the ragdolls
      to the end of the queue, add the other moves in succession until them then make another exe and them move onto
      the ragdolls after taking another checkpoint on my go"):
      stage 19, ragdoll on hard impact and long fall, with get-up by lying direction; stage 20, partial ragdoll hit
      reactions.
- [ ] 11. The phone pass of every stage (the study: "Phone testing of each stage follows the desktop pass"). Never
      done for any stage. (The Redmi run comes last.)

## EVERYTHING IN C++ (27 Nov, his ground rule; this comes before the NPC list below)

His words: "gdscript translation really adds up over time and costs a lot, make it m c plus plus"; "writing every
code in c plus plus was a ground rule in the first place. make all the code c plus plus and make god damn sure
nothing ever breaks". So: the player's movement AND the NPCs', all of `traversal_lab/traversal/` that runs in a tick,
goes to C++ in the native module (`native/src`). Tests and tool-time scripts may stay scripts.

How nothing breaks (the rules of the port):
1. **The script version is the reference and is not touched or deleted.** It stands at checkpoint 3 (edf508d0) plus
   the NPC commits (to dd0d211b). It stays the default until he has play-tested the C++ version and says so.
2. **One layer at a time, in the study's build order,** each proven before the next starts: (a) the body (stage 1);
   (b) detection (stage 7); (c) the character: the animation tree, the gait, the corrections (feet, hands, trunk,
   arms, fingers); (d) the traversal moves (stages 8 to 18); (e) doors, sitting, the phone, the car, cover; (f) the
   NPC fitting. A layer is a translation, line for line: no behaviour is changed, no number is changed, nothing is
   "improved" on the way.
3. **Proof of a layer = three things, all read after the runs:** (i) a parity test: the same recorded input run on
   the script and on the C++ version, compared tick by tick (the body's place, speed and state; later every bone);
   (ii) every stage test passes with the C++ layer switched in; (iii) the audit on it is 26 of 114, the same lines.
4. **A switch, not a swap:** the lab starts on the script; `-- --native` switches the proven C++ layers in. The
   default changes only at his word, after his play-test.
5. **Where it is built:** the cloud builds a Linux library to run the tests (godot-cpp branch 4.5 at 27d9dd2, the
   same commit `native/build.sh` uses, in `OUT/native_tools/`, not in git). The Windows exe he play-tests needs the
   Windows library: built in the cloud if the cross compiler can be had there, else on his PC with `native/build.sh`.

- [x] 0. The toolchain (27 Nov): godot-cpp built for Linux in the cloud (`OUT/native_tools/godot-cpp`, needs
      `pip install scons`); `native/traversal/` (its own small library, `bash native/traversal/build.sh linux`);
      one empty class, `TravBody`, loads in the lab and stage 0 still passes with the library present. Windows:
      the cross compiler installs in the cloud (`apt-get update; apt-get install g++-mingw-w64-x86-64`); godot-cpp's
      Windows library and `traversal.windows.x86_64.dll` build here too (`bash native/traversal/build.sh windows`). Not yet
      tried: the dll inside an exported exe on his PC.
      A fresh container has none of this: build godot-cpp again first (about 25 minutes each).
- [x] a. (trav87) The body in C++ (`native/traversal/src/trav_body.*`): 121,600 ticks the same as the script byte for
      byte (`bash tools/traversal/parity.sh <folder>`), every stage test passes with `-- --native`, the audit on it is
      26 of 114, the same lines. For the next layers: add that layer's numbers to `tests/parity_run.gd`.
- [x] b. (trav88) Detection in C++ (`trav_detector.*`): about 146,000 records the same as the script byte for byte;
      every stage test and the audit the same with `-- --native`.
- [x] c. The character and its corrections. (trav91) character.gd itself: `trav_character.*`, every bone the same.
      TRAP FOUND: godot-cpp returns `Animation::get_length()` as a float; the engine and the script have a double:
      read it with `a->get("length")`. Expect the same of other engine values that are doubles in 4.7.
      Earlier (trav89): arm_open, trunk_turn, hand_hold, foot_orient, finger_grip
      (`trav_mods.*`) and hand_place (`trav_hand_place.*`), every bone the same as the script over 121,600 ticks.
      (trav90) foot_place (`trav_foot_place.*`), the same. (feet.gd is the first version's, not used.)
      LEFT in this layer: nothing. (npc/body_fit.gd and npc_character.gd are layer f.)
      HOW A LAYER IS TRANSLATED (learned on the first seven, all byte for byte the same; keep to it):
      (1) every GDScript `float` is a C++ `double`; every part of a Vector3 is widened with `D()` before it is used
      in arithmetic; a Vector3 times or over a scalar goes through `mul()` / `div()` (the scalar is narrowed to a
      float there, as GDScript does); wrapf, lerpf, clampf, rotate_toward, move_toward, smoothstep are the engine's
      own formulas in doubles (`native/traversal/src/trav_math.h`), never godot-cpp's float versions.
      (2) the same names; every variable the other scripts read or set by name is served by `_get` / `_set`; an
      array the scripts change in place stays a godot `Array`.
      (3) the script is not edited beyond the one line where the thing is made (`_made(&"TravX", X)` in
      character.gd; `-- --native` picks the C++ one).
      (4) proof before commit: `bash tools/traversal/parity.sh <folder>` says PARITY RESULT PASS (the files the
      same byte for byte); every stage test and the audit with `-- --native` (scratch `suite_native.sh`); then the
      same with the scripts; then build for Windows too (`bash native/traversal/build.sh windows`).
      (5) a fresh container: `pip install scons`, clone godot-cpp branch 4.5 into `OUT/native_tools/godot-cpp`,
      `scons -j4 platform=linux arch=x86_64 target=template_debug` (25 minutes), then `build.sh linux`, then
      `godot --headless --path traversal_lab --import` once so the lab sees the library.
- [x] d. (trav93) The traversal moves in C++ (`trav_traverse.*`, TravTraverse): the same as the script byte for
      byte, the plan of every move included. Its constants are made from the script by a tool (`*_consts.inc`,
      `*_ctor.inc`, `*_get.inc`), not copied by hand.
- [x] e. (trav94) Doors, sitting, the car, cover in C++ (`trav_interact.*`, TravInteract): the same byte for byte.
      The parity proof has a fourth run for it, `acts` (every station with the act key pressed on the way: 24 moves
      on doors, seats, the car and cover, 50 climbs): 203,200 ticks in all.
      FOUND by that run, in the SCRIPT (not changed, it is the reference; tell Yasin): walking at a wall whose top
      cannot be seen (under a ceiling) traverse.gd line 736 reads `rec["thin"]`, which such a record does not have:
      an error line each tick in the test runs; in the exported game it reads nothing and goes on. Nothing is begun
      either way; only the `refused` text differs. The C++ does as the script does in the tests.
      TRAP for the next translations: a C++ `dict["key"]` on a missing key puts the key in; the script stops with
      an error instead. Where a key may be missing, ask `has` first.
- Still scripts after this: the lab itself (main.gd: camera, course, readout, the input tape) and the test props
  (the door, the car, the seats). Every part of the player's and the NPCs' movement is in C++ behind `-- --native`.
- [x] f. (trav92) The NPC fitting in C++ (`trav_npc.*`): the same as the script byte for byte on npc_04 and npc_03
      (`EXTRA="--npc=npc_04" bash tools/traversal/parity.sh <folder>`).
- [x] (trav96) C++ IS THE DEFAULT (27 Nov, his words after the play-test: "looking fine"; "yes c is the default").
      The scripts stay as they are and are asked for with `-- --script`. Without the built library the lab falls
      back to the scripts (the readout's first line says which). New moves are written in C++ only.
- [x] His play-test of the C++ version; then, at his word, C++ becomes the default. The exe was sent 27 Nov
      (`TraversalLab_trav95.zip`: "Start C++ version.bat" starts it with `-- --native`; "Start script version.bat"
      is the approved one). (trav95) The readout's first line says which is running: "code  C++ (all 4 parts)" or
      "code  scripts". NOT checked: the Windows dll has never been run (no Windows here); if the line says
      "scripts" after the C++ start file, the dll did not load on his PC. Known: the readout's key line now lies
      over the top edge of the height graph (one more line of text).

## THE MERGE (27 Nov, night, his words)

"Okay go ahead with those two. Keep the damage line but double check it doesn't break anything. After those merge
with main and wire the new npcs, cars and movement in." And before: "Your traversals paramount over everything
else, don't merge anything else that is involving play or npc movement".

- [x] Merged into the work branch and MAIN (main = 77bfa296, a fast-forward): the cars (`ccr-744faae9-jbjc01`: 16
      rebuilt or new models with cabins and cut doors) and the damage work (`damage/option-b`). One clash,
      `native/src/city_car.cpp` (includes; both kept). Our traversal files are untouched by both.
- Checked after the merge, here in the cloud (game C++ built for Linux into `native/bin`, not in git): all 48 files
  compile and link; `tests/damage/test_damage.gd` RESULT PASS; `tests/damage/test_car_wall.gd` RESULT PASS;
  `tests/car/test_city_car.gd` RESULT PASS; `tests/car/test_real_doors.gd` RESULT PASS (in a window: headless it
  has no picture to read); `tests/game/test_native_load.gd` RESULT PASS.
  `tests/traffic/test_bus_people.gd` FAILS here before the merges and after them the same way (nobody boards a
  bus; stops served 0 to 2 from run to run on both builds): not from the merge, cause not looked into.
  `tests/game/test_start.gd` cannot run here: no baked city in this container.
- The damage line in the crowd code (`city_crowd.cpp`) is kept at his word. It is marked TEMP in the code: "melee
  test until the traversal lab's strike() arrives - remove then". It calls the damage node from the player's place
  if there is one; it moves nobody.
- NOT merged, by his rule (player or NPC movement): `lab/procedural`, `lab/layered`, `lab/checker`, and the old
  game's animation branches. The 25 old-game branches have no common history with this repo.
- The story of First Gear (8 documents, one of them the music: cues and song lists; no sound files exist on any
  branch) was only on the old branch `claude/dazzling-babbage-p7itst`: copied in, additive.
- [ ] WIRE IN (27 Nov, his words: "Okay go for all of it, go non stop unless something breaks"). The order agreed:
      (1) the traversal player into the game, (2) the 7 new car models given their roles, (3) the game's C++
      rebuilt on his PC, (4) re-bake, (5) export and PC test, (6) the phone run last.
      WHAT THE GAME IS (surveyed 27 Nov; file and line in the survey's words):
      - main scene `tools/city/rig/rig.tscn` (`rig.gd`); `--game` loads `game/boot.tscn` (CityGame). No autoloads,
        no InputMap actions. Jolt only on Android; Godot Physics on the PC (the lab is Jolt everywhere).
      - the player is `CityPlayer : CharacterBody3D` (`native/src/city_player.*`, made with ClassDB.instantiate in
        `rig.gd` `_free_walk`), layer 2, mask 1|16|32; it OWNS the only Camera3D and all input (raw keys, touch
        stick, sensors); about ten C++ files hold a `CityPlayer*` (bike, car door, hud, law, shops, crowd, talk,
        damage, hand_grip).
      - layers: 1 world, 2 player, 5 (16) cars, 6 (32) crowd capsules; `docs/damage/WORLD_CONTRACT.md`: traversal
        probes use mask 1|4|8, the capsule 1|4|8|16|32; a punch's contact calls `strike(...)`.
      - car entry: `CityCar::enter(CityPlayer*)` / `leave()` (`city_car_door.cpp`), driven from CityHud; it uses
        `set_riding`, `stand_at`, `view_vehicle` / `take_view`, `figure()`.
      - the crowd: far people are one MultiMesh of baked poses; only the nearest 12 (cap 18) are real `CityPed`
        skeletons on Rocketbox bodies.
      - car weights `native/src/car_models.h` (weight 0 = never in traffic: the 7 new models); police / ambulance
        models hard-coded in `city_law.cpp:31-32`; bus model `CityTraffic.bus_model`.
      - bake / export: `bash tools/city/rig/phone_rig.sh bake | export | install | run`; the baked runtime is not
        in git (so the game cannot be started in a fresh cloud container without a bake).
      THE PLAN FOR (1), a switch and not a swap: CityPlayer stays the object everything talks to (camera, input,
      its calls); behind a switch it makes a TravBody under it, feeds it its input as the tape's `sample()`,
      follows it, and draws the traversal character instead of its Rocketbox figure. The old player stays the
      default until he has tried the new one in the game. Needs: the traversal sources compiled into the game's
      module (one library, so it also gets the Android build), the lab's runtime files copied to `res://traversal/`
      of the game (the lab is a nested project the game cannot read), the probe mask split from the capsule's
      (contract), Jolt on the PC too or the body proven on Godot Physics.
      DONE SO FAR (27 Nov, night):
      - the traversal sources compile into the game's module (`native/build.sh`: `native/traversal/src/*.cpp` with
        `-DTRAV_IN_GAME`; `register.cpp` gives `trav_register_classes()`, called from `register_types.cpp`). Built
        for Linux in the cloud (to `native/bin`, not in git). NOT built: Windows and Android (his PC).
      - `bash tools/traversal/sync_to_game.sh` copies the lab's run-time files to `res://traversal/` of the game
        (55 MB, not in git; the clips' small data script goes with them). Run it before a bake or an export.
      - `CityPlayer::set_traversal(true)` (city_player.cpp): a TravBody with its Character, Traverse, Interact and
        Hold is made beside him on the player's layer (mask: world and cars, NOT people yet); CityPlayer keeps the
        camera and the input, hands the tick's input over as `sample()`, follows the body, hides its own figure;
        `set_riding` puts the body away, `stand_at` sets it down. Keys in this mode: as the lab (0 to 9, F, X, B,
        Q, H); the game's own F / J combat is not asked for while it is on. `rig.gd`: `-- --trav` switches it on.
      - `tests/game/test_trav_player.gd` RESULT PASS on a made-up street, on the game's own physics (Godot Physics,
        not Jolt): 1.45 m/s, the node never more than 8 cm from the body, kerb, high step, wall (3 moves),
        riding, set down, switched off again. test_native_load, test_damage, test_city_car still RESULT PASS.
      - NOT DONE in (1): never run in the real city (no bake here); getting into a car still uses the game's own
        take and its Rocketbox driver figure (he changes body in the car); the crowd does not collide with him;
        the phone, talk gestures, the bicycle's hold points, his voice, swimming, the game's combat and being
        knocked down are the old player's and do nothing in this mode; the camera is the old one, unchanged; the
        touch stick is passed through but was not tried.
      - (2) THE NEW CARS' ROLES (27 Nov, night): the police drive `police_e` (the patrol car; every other chase unit
        the `police_x`), the ambulance is the `ambulance` model (`city_law.cpp`; before: stern_g in dark blue and
        the white van). They carry their own livery, the paint colour does not show on them. `utility`, `tow`,
        `flatbed` and `van_custom` are rare ambient traffic, weights 2, 1, 2, 3 of 108 (`car_models.h`; the
        weights are mine). Seen in a frame: all 7 in white and in dark blue paint, as the game's car draws them.
        After the rebuild (`bash tools/traversal/build_game_cloud.sh`, the cloud's Linux build of the game module):
        test_city_car, test_native_load, test_damage, test_car_wall, test_trav_player, test_law RESULT PASS.
        NOT checked: the trucks in moving traffic and as parked cars (needs the baked city); their far / light
        models in a frame; the police lights' places on the new roofs. A cloud trap: after `git clean` the
        pictures' `.import` files are gone and every car draws in patches: run `--import` again before a frame.
      - PEOPLE ARE SOLID TO HIM (27 Nov, night): his capsule now meets the crowd's capsules (mask 1|16|32, as the old
        player), and his probes do not (`native/traversal/src/trav_probe.h`: a body with the meta `probe_mask` uses
        it for every ray and shape test; without it, as in the lab, nothing changes). In the game the probes see
        the world and cars (1|16). The contract's layers 4 and 8 (breakables, windows) are NOT in either mask yet:
        the old player does not have them either. test_trav_player (now 12 lines, a person in his way: no nearer
        than 0.55 m, no move begun against it) RESULT PASS; the lab's parity run PASS (203,200 ticks the same).
        The Windows compile of the whole game module was tried in the cloud: all 59 files compile (the cloud's own
        mingw needs `P_WAIT` set aside, a clash of its headers with traffic_sim.h; his PC's llvm-mingw built that
        file before). Not linked here, not run: his PC.
      - 28 Nov, HIS WORDS: "i just need to have a new build asap, even if its crippled, lets move onto an android
        build"; "i need to see the new npcs and the character in the game"; "make all of them replace the old ones";
        "bring everything new in. performance work is after that". So: everything new first, performance after.
      - THE NEW CHARACTER IS THE DEFAULT in the game (`rig.gd`; `-- --oldplayer` gives the old one back; only when
        `res://traversal/` is there). The lab's grey capsule is not drawn in the game.
      - THE NEW PEOPLE, FIRST STEP (`native/src/city_crowd_trav.cpp`, `CityCrowd::set_trav_people`, on with the new
        character; `-- --oldpeople` off): every NEAR figure of the crowd (the pool, 12) is drawn as one of the 39 new
        bodies on the traversal system, a TravBody with its NPC character that walks after its walker's place (the
        old figure is still driven there, not drawn). `tests/people/test_trav_people.gd` RESULT PASS: 11 shown at
        once, 0.33 m from their walker on average (worst 1.75 m), all walking, none under the floor. Seen in one
        frame (a flat floor, no city). CRIPPLED, told to him: what a person does beyond walking and standing
        (sitting, a phone, a fight, lying) is not shown on the new body; shoved or knocked down, the OLD figure is
        drawn while its physical body has it; the far figures are still the old bodies; which body a person gets is
        by pool place, not by who he is (a man can come near as a woman); one body in the frame stood with its
        forearms crossed in front of it (not looked into). All numbers there are mine.
      - OPEN: `tests/traffic/test_law.gd` passed 3 runs of 7 since the new police cars (fails: "an officer ran the
        mugger down (150 s)", once also the mugging itself). It runs on the real clock, so it may have been unsteady
        before; NOT yet run on the old police model to tell. Commit 190fa965's message says it passed: it had failed.
      - STILL TO BRING IN, in this order: NPC acts on the new bodies; the far crowd from the new bodies; into a car
        as the new character; touch buttons for the new moves; the old player's phone / talk / bicycle / swimming /
        combat on the new character; the traversal's own strike in place of the TEMP line.
      - 28 Nov, EVERYTHING IN (his words: "i told i want everything new in the new build"; "get the npcs working with
        every action"; "i especially need the new player character and all of its moves in"; "i need a release
        build, i can only download the new builds. i dont have cables now"):
        PEOPLE: a bench seat = the new body's own sit-down / seated / get-up takes; phone and carried bag, box, case =
        its own holds; every other act and being shoved or knocked down = THE POSE COPY (`native/src/trav_mirror.*`:
        the old figure goes on playing, not drawn; its pose is put on the new skeleton bone by bone). Seen in frames
        beside the old figures: ground sit, lying, fight stance, phone up, duck. Not seen: knocked down, the bench.
        PLAYER: six touch buttons in traversal mode (USE, HANDS, AIM, FIRE, RELOAD, DROP; touch screens or
        `-- --travbuttons`; their places are mine, not tried beside the HUD's buttons); at the wheel and on the
        bicycle he is drawn in the driver's / rider's pose by the pose copy (`set_ride_figure`, `ride_pose`):
        `test_car_entry.gd -- --trav` RESULT PASS, hips 6 cm from the driver's, seen in 4 frames walking to the door
        and getting in; the bicycle NOT run. The four nearest free benches are seats for his own take
        (`CityCrowd::trav_benches`; `tests/people/test_trav_bench.gd` RESULT PASS on a flat floor at the bench's
        height: in the city the bench's own height is not tried). The game's phone (CityHud) = the body's phone
        hold; the game's fight = fists up, the HUD's punch = the fire key (whether blows land is the crowd's count
        as before: not tried). Swimming, talk gestures, his voice: still nothing in this mode.
        THE BUILD: `bash tools/city/rig/publish_build.sh` on his PC (sync, bake, C++, export, GitHub release to
        download). The bake is needed for the damage update (surface names, ground map). NOT run after the bake:
        the traffic's `make_streets.gd` (the map's pieces were not changed by this work).
        Tests on the last module: test_trav_player, test_trav_people, test_trav_bench, test_crowd_game,
        test_native_load, test_car_entry, test_city_car, test_damage, test_player_fight RESULT PASS.
        test_acts RESULT FAIL (2 clip-order lines of the OLD figures; trav people are off there; not checked
        against before this work).
      - the NPC parity run (`EXTRA="--npc=..."`) now FAILS by design: the C++ NPC has its own pace, the frozen
        script NPC has not. The player's parity run still passes.

## CARRYING AND THINGS IN THE HAND (27 Nov evening, his words; after the C++ port)

His words: "we didnt add any of the carry moves yet, nor any combat moves... we are supposed to have a one hand
briefcase or plastic bag carry and two handed box carry, , pick up from ground for both, also the npcs. after C++
port is done, we need to add them in. we have new weapons on a new branch. logic behind them isnt tied yet, lets
just make sure the look correct in player hand. also we got carry props too. copy the weapons and carry props here
and get to work on those animations."

- The props: the carry props (page J, `assets/coronado_kit/props/indoor/carry/`, scenes and grips in
  `map_dc/coronado/city_kit/carry/`) were already here. The weapons (page G, `assets/coronado_kit/props/weapons/`,
  eleven, `manifest_weapons.json`: origin = `grip_r`, the right fist; `grip_l`, `muzzle`; `hold` names the pose
  family) were copied 27 Nov from the branch `ccr-744faae9-jbjc01`, additive.
- [ ] one-hand carry: briefcase or plastic bag, standing, walking, running; put down / pick up from the ground.
- [ ] two-hand carry: a box, the same.
- [ ] the same on the NPCs.
- [ ] each weapon in the player's hand, looking right (no logic behind them yet: the look only).
- [ ] combat moves: NOT asked for yet beyond being named; ask him what the set is before building any.
- 27 Nov, later, his words: "if the takes dont fit our character or npcs, order new ones from kimodo"; "okay tune
  them [the NPCs] while going on with carry and guns. get shooting aiming down sight reload for both single and two
  handed weapons. after they are done make another exe regarding only these moves."
- [ ] guns: aim down the sight, shoot, reload, for a one-handed weapon (pistol) and a two-handed one (rifle /
      shotgun). The look only; no hit logic.
- [ ] NPC tuning alongside (from `reports/NPC cast civilian run.md`): npc_09 and npc_18 (planted foot rises 2 to
      4 cm walking), npc_18 and npc_31 (sit low), npc_09 (sits high), feet hanging when seated (22 bodies over
      5 cm), their own pace.
- [x] (trav100) the exe sent 27 Nov: `TraversalLab_trav100.zip` (Start.bat = C++, the default; the keys are on
      screen). WAITS ON HIS EYES. NOT checked: the Windows library with the new code has never been run.
- WHERE THIS STANDS (27 Nov, night; read before going on):
  - Takes for his body from the Drive are in `traversal_lab/assets_src/carry/` (not in git) and baked to
    `traversal/character/clips/` with a copy of `tools/build_clips.gd` whose SRC is that folder (so no existing
    clip is re-baked): Walking_With_Shopping_Bag, Jogging_With_Box, Box_Turn, Box_Walk_Arc, the briefcase turns,
    Pistol_Idle, Rifle_Standing_Idle, Walk_With_Rifle, Rifle_Start_Run, Walking_While_Aiming_Rifle. Seen on his
    body in frames (small): they stand right.
  - `library.res` rebuilt with them: the 115 animations it had are the same key for key (checked), 22 added.
    NOT COMMITTED YET: it waits for the takes to be final and one run of every test.
  - Kimodo: the first 16 carry takes came out with the arms spread and a wide stance: Kimodo takes the rest pose
    from the character file it is given, and it was given his Texting take as it was. Given the same file with
    every rotation set to zero (his T-pose; scratch `kim2/character_tpose.fbx`) a test take stands right. 46
    takes ordered again with it: pick up / put down / stand / walk for a box and a bag, and for the pistol and the
    rifle: aim, shoot, reload, idle. To do: look at each, keep the least wrong, bake.
  - THE TAKES, LOOKED AT ON HIS BODY IN FRAMES (27 Nov, night; small frames, six moments each):
    - Kimodo, kept (4 of 46): KM_Pick_Box (pick_box seed 2: squats, both hands down, up with them at his waist),
      KM_Put_Box (put_box seed 1), KM_Pick_Bag (pick_bag seed 3: bends and reaches down with one hand),
      KM_Put_Bag (put_bag seed 3). Which hand the bag takes use is NOT yet checked: mirror if it is the left.
    - Kimodo, dropped: standing and walking with a bag (one arm stuck out to the side, no hanging arm), standing
      and walking with a box (arms low and apart, not holding anything), and EVERY gun take (aim, shoot, reload,
      for pistol and rifle: open hands in a wide boxing stance, nothing like holding a gun).
    - So for the guns: his own Mixamo takes for the holds and the reloads (Pistol_Idle, Rifle_Standing_Idle,
      Walk_With_Rifle, Walking_While_Aiming_Rifle, Gun_Reload_While_Walking, Reloading_Rifle_While_Standing, all
      in the library now); aiming down the sight and the shot are to be made from the weapon itself: the weapon
      placed with its sight at his eye and pointing where he looks, the right hand on `grip_r`, the left on
      `grip_l`, the arms solved to them, a short kick for the shot. No take of his body exists for a pistol aimed
      or fired; Mixamo has them ("Shooting Gun", "Pistol Aim", "Firing Rifle"): his PC, if the made poses do not
      look right.
    - For carrying: the arms of Jogging_With_Box (two hands) and Walking_With_Shopping_Bag (one hand), his own.
  - `library.res` as it stands: the 115 old animations the same key for key, 18 added.
  - THE PROPS ARE IN THE LAB (trav98): `traversal_lab/tools/build_props.gd` reads the kit's .glb files and writes
    `traversal/props/<name>.scn` (17: the 11 weapons, 2 briefcases, 2 bags, 2 boxes; under 1 MB with their two
    atlas pages), each with its hand points as child nodes (`grip_r`, `grip_l`, `muzzle`) and its hold as meta.
  - WHERE A THING SITS IN HIS HAND, TRIED AND SEEN IN FRAMES (`tools/traversal/try_hold.gd`, run with
    `xvfb-run -a godot --path traversal_lab --rendering-driver vulkan -s <full path> -- --out=<folder>`; three
    views). The rules that looked right, to be written into the C++ as they are:
    - a hand's frame from its joints: along = wrist to middle knuckle; across = pinky knuckle to index knuckle,
      squared to along; out of the palm = along x across (right hand; the left the other way); the palm point =
      three quarters of the way from wrist to knuckle, 3 cm out of the palm (all four figures mine);
    - a bag or a briefcase: upright in the world, turned side-on to the way he faces, its `grip_r` at the right
      palm point;
    - a box: upright, facing as he does, the middle of its two grips at the middle of his two palm points;
    - a gun: muzzle (+Z) along the right hand, up (+Y) across it, `grip_r` at the right palm point; a long gun is
      then turned so that its own line from `grip_r` to `grip_l` lies on the line from his right palm to his left.
    - Seen: briefcase and plastic bag hanging at his side on the shopping-bag walk; the box between his hands on
      the box jog; the pistol level in his right hand on Pistol_Idle; the rifle across him pointing down-left on
      the rifle idle, and at his shoulder pointing ahead on Walking_While_Aiming_Rifle. NOT seen yet: fingers
      closed on anything, the left hand on a forend, any of it moving.
  - Also kept: `tools/traversal/view_takes.gd` (six moments of any takes of the library on his body) and
    `tools/traversal/npc_cast_run.gd` (the civilian run of one body; `-- --npc=<name>`).
  - (trav99) THINGS IN THE HAND, FIRST VERSION, IN THE LAB (C++ only: `native/traversal/src/trav_hold.*`, the arm
    layer in `trav_character.*`). Keys: 0 nothing, 1 briefcase, 2 plastic bag, 3 box, 4 pistol, 5 rifle, 6 shotgun;
    F held = aimed (long guns). What it does: the arms of a hold take over his movement (right arm for a bag, both
    for a box or a gun); the thing placed at his palm each tick; fingers closed with the study's everyday grip;
    both palms moved onto a box's side points; the left hand turned palm up under a long gun's forend (as the
    texting hold turns the hands). With nothing held the player is the same as the scripts byte for byte.
    His words on it, 27 Nov: "other than brief case being held sideways, they look good"; "the hands dig into the
    box"; "brief case and bag both look like they are attached to the back of his hands"; "same for the weapons";
    "it lands on the side of that hand instead of in the palm"; "yeah exactly like the phone hold during texting";
    "box is okay, just for the rifle"; "rifle looks great now, make sure it translates to every rifle hold when
    moving idle and aimin i mean".
    OPEN: the rifle aimed points off to his left (only the arms come from the aim take, not the turn of his
    trunk); the pistol is rolled about 45 degrees; the bag and the briefcase not yet shown to him close up after the
    palm fix; every long gun (shotgun, smg, sawn-off) to be looked at standing, walking, running and aimed; the
    shot, the reload, aiming a pistol, picking up and putting down, the NPCs; no test of its own yet.
  - (trav100) AIM, SHOT, RELOAD, PUT DOWN / PICK UP, THE FIST FIGHT, in the lab (C++ only, `trav_hold.*`).
    Keys: 0 to 9 what is in his hands (1 briefcase, 2 bag, 3 box, 4 pistol, 5 rifle, 6 shotgun, 7 smg, 8 sawn-off,
    9 fists); F aim; X a shot, or a punch (F+X the combination); B reload, or jab and elbow; Q put down, or with
    empty hands pick up the nearest thing on the ground; H be hit. The readout lists them.
    How: aimed, a long gun's butt is put on his right shoulder, level, pointing the way he faces, and both hands
    are laid on it (his words: "rifle goes into his face when aiming ... place the butt of the rifle onto his
    shoulder and place hands according to that"); the left hand takes the forend only as far along as his arm
    reaches (reaching for the forend's own point bent his whole trunk forward); a pistol aimed is at his eye, both
    hands on it; a shot is a kick of the gun and a flash at its muzzle; reload is his own Mixamo takes' arms;
    put down / pick up / punches / hits are moves on the spot begun on the body (`_spot`), the thing leaving or
    coming into his hands at the moment the take's hands are lowest; he is brought to where the take picks it
    up from (the study's "slide and turn the body over a short fixed time").
    The fight's set (his body's own Mixamo takes; he did not name it): the boxing idle as the stance (arms only),
    cross, lead hook, rear hook, a combination, jab and elbow; being hit: light left / right, medium, body, big
    left / right. In the library but not used yet: Fight_Side_Step, Fight_Walk_Back, Fight_Idle_Still.
    SEEN IN FRAMES: all of it but the jab and elbow, and guns 6 to 8 aimed. KNOWN ROUGH: a box settles the last
    centimetres after he lets go; picking up, the hands are not solved onto the thing before the grip; aimed, the
    rifle's left hand is back by the magazine; in the stance only the arms guard; nothing of this on the NPCs;
    no test of its own.
  - The plan for the code (C++ only): the body takes new keys from the tape (which thing is in the hand, pick up
    / put down, aim, fire, reload); the character gets one more upper-body layer after the phone's (a filtered
    blend: arms and trunk from the hold take, legs from the movement as it is); the prop is a child placed at
    the hand each tick from its own `grip_r` (weapons: origin = right fist, +Z = muzzle; carry props: `grips` in
    `carry_props.json`), the left hand held on `grip_l` by hand_place, fingers closed by finger_grip; picking up
    and putting down are moves (begin_move) like sitting. With nothing in the hand the new layer's weight is 0,
    and parity against the scripts must still pass: that is the proof the player is untouched.
- 27 Nov, late, his words: "correct all of them then let me see them in an exe"; then: "actually let me see it after
  the fist fight animations come too". So the next exe holds: the carry and gun fixes, the shot / reload / aim,
  pick up and put down, AND the fist fight. He did not name the fight's moves: built from what exists for his body
  (Drive: the boxing idle, cross, two hooks, a combo, jab to elbow, the side step and the walk back in a fight
  stance, being hit: light, medium, big, to the face); tell him the set when it is shown.
- [ ] the fist fight: stance, punches, being hit, moving in the stance.
- New code for these is written in C++ from the start (his ground rule), with a script only where a test needs one.

## NPCs (27 Nov, started at his word; the ragdolls still wait for his go)

His words: "i need this system to apply to every npc"; "i dont think all the npcs need the full move set, they just
need basic movements"; "make sure they arent as many triangles as the player"; "will we be able to make them move as
intended without touching the players existing and approved traversal set? we worked hard to get the player right, i
dont want anything messing that up"; "also limit the tests to allowed civilian moves only"; "oh npcs should be able
to get in and out of cars". Order agreed: the fitting first, then the recipe fixed, then the cast in one batch.

- **Rule: nothing of the player's is changed for an NPC.** NPC code lives in `traversal_lab/traversal/npc/`. A change
  inside a file the player uses is shown to him and asked first. The player's 18 tests and the audit (26 of 114,
  the same lines) are run before every commit, as always.
- **The recipe** (`assets/people/meshy/<name>/tasks.json`; the script is not in the repo yet): the player concept
  redrawn as another person in the same pose (nano-banana-2), arms STRAIGHT OUT (arms held low fused the sleeve
  with the shirt on the first woman), image to 3D (t-pose, remeshed to 5,000 triangles), rigging (mixamo skeleton,
  `include_fingers`, height). 41 Meshy credits a body. Then `tools/build_npc.gd -- --name=<name>` (twice, with
  `--import` between).
- **Bodies:** npc_01 (man, 1.79 m), npc_03 (heavy man, 1.74 m), npc_04 (woman, 1.61 m). See one in the lab in the
  player's place: `-- --npc=npc_04`.
- **The civilian moves:** stand, walk, run, starts, stops, turns, kerbs, stairs, slopes, step down, high step,
  shoulder turn, doors, sitting, phone, the car in and out; ragdoll and get-up when built. Add-ons later: cover
  (armed), vault, climb on and mantle (chasers). Everything else is refused to them (not wired yet).
- [x] (trav82, trav83) three trial bodies on the player's skeleton standard, the player's clips unchanged.
- [x] (trav84) the fitting: hips at the height their legs need, their own stride, seated at the seat.
- [ ] a civilian test of their own (`tests/` for NPC bodies; today the player's tests are run on them and some lines
      hold them to the player's size).
- [x] (trav89) the second cast: 34 more bodies (npc_18 to npc_51), 1,394 Meshy credits of the 1,500 he allowed. 50
      NPC bodies in all. About 660 credits left on 27 Nov.
- [x] (trav85, trav86) the cast: twelve more bodies (npc_05 to npc_16) and a second elderly woman (npc_17); who each
      is: `assets/people/meshy/cast.json`. 57 Meshy credits left on 27 Nov (one more body); they reset on 23 Dec.
- [ ] five bodies got no finger bones from Meshy though asked (npc_07, 08, 09, 11, 14, 17): their hands move as one
      piece. Meshy's rigger also adds bones of its own, different on each body: `build_npc.gd` prints them.
- [ ] the texting grip on their hands; the woman's feet when seated (toes 7 cm up on the 0.45 m bench) and in the
      car; stairs up (a foot 3.2 cm off); the big toe at push-off (14 to 16 degrees).
- [x] (27 Nov, at his "Yes to all") an NPC's own pace: the body has a `pace` setting (1 for the player), an NPC sets
      the square root of its leg share (mine). npc_09's planted foot stays down now (rose 6.7 cm, now 3.2 at most).
- [ ] the moves outside the civilian set refused to an NPC.
- [ ] a brain that drives the body in place of the keys; an NPC on the course beside the player.
- [ ] what a phone can afford (never measured).
- [ ] then the cast, in one batch.

## Known weak points (not in the queue until he says so)

- He slows into the mantle and the grab at a run; only their exits are running.
- The grab from standing at 2.60 m is carried 0.54 m above the take's jump; the wall climb at 3.00 m 0.60 m higher.
- Thin walls: stepped off and a plain fall from up to 3 m, unless the stick is let go.
- The climb down ends facing the wall; it is asked for by crouching at the edge (my choice).
- The balance fall from 3.1 m up is always face down.
- Running-jump bands other than the vault are untested; the longer step over a shallow gap under 0.78 m was not
  run; running off the side of a beam was not run.
- Found 27 Nov by stage 1's random walk when a 65th station changed its path (the ledge station is therefore listed
  apart, in the course's `extras`, and the walk is as it was): (1) pressed sideways against the 0.25 m beam (0.5 m
  up) he does nothing: no step onto it, no vault, for as long as the stick is held; the same in trav72, so not new.
  (2) the walk can set him down standing under the 1.5 m overhang, which pushes him 0.3 m into the floor: the
  test's own doing, not a way the player gets there.
- Doors: the pull side is the take's own pace (2.4 s more than walking; the study says about 4 s). At a run he
  still stops and plays the same take. Cars: no bonnet slide; the car is a van with no roof, built round the take.
  Sitting: Stand To Sit is the X Bot take (none was downloaded for his body). The phone holds him to 1.3 m/s (mine);
  there is no take for taking the phone out or putting it away, it fades in over 0.4 s.
- Cover: behind a 0.80 m wall the top of his head shows 0.28 m (his hips are down the most they go; the study says
  these takes show the head behind 0.8 to 1.1 m cover); side-stepping along low cover he rises to 1.41 m, so his
  head shows over walls under 1.4 m while he moves; no take goes from standing into standing cover on his body (the
  take out of it is played backward); the high look round the end is `Standing Cover Turn`, the X Bot take; cover
  is taken only against a wall he faces within 2 m, with E; no cover-to-cover move, no corner turn.
- Fingers do not curl on any hold but the phone (trav79 to trav81: `finger_grip.gd`). On the phone his little finger
  is not under its bottom edge and his thumbs rest, they do not tap. On a call his elbow is out to the side at chin
  height (his arm is too short to hang it lower with the hand at his ear). At the desk T is "hands to the keys", not
  the phone. All grip angles and offsets are mine.
- The sidle is taken to 0.30 m, not the study's 0.25 (mine); his arms hang, they are not spread on the wall; going
  back the way he came in a gap (not on a ledge) is not tested.
- On a beam the walking feet are not brought onto it, only the standing feet.
- His open list, items 3 to 5 (stage 1 random-walk faults, the stops and the kerb step, the 26 audit lines):
  untouched by his rule ("if things dont improve by a 20% ... dont change anything").

## Waiting on Yasin's eyes

- trav80, trav81: the phone gripped (T text: a hand closed round each side; G call: fingers hooked over its edge),
  standing, walking, sitting down, seated and getting up.
- trav78: the car in and out (the jitter), the phone in his hand texting and at his ear on a call.
- trav77: cover on the course's thin and deep walls (E facing a wall; the stick along it; held at its end to look
  round; E or the stick out from it to leave).
- trav75, trav76: the door (both sides), the car (in and out), the bench and the desk, the phone (T text, G call)
  standing, walking and seated. Stations after the wall ledges: `[` from the first station goes back through them.

- trav69: feet on beams and wall tops, the arm flicker in the balance fall, hands on a wall met end on.
- trav72, trav73: the sidle along a ledge with a wall behind; the last station key reaches the course's two ledges
  (0.20 and 0.12 m). Arms open and head turned the way he goes, on the ledge and sideways in a gap.
- trav70, trav71: the squeeze through gaps, either way round. Whether "the character gets lost on many frames" is gone.
