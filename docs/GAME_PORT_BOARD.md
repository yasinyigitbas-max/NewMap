# Bringing the old game over: my job board (Yasin, 20 Nov: "make a job board for yourself to make sure you dont forget anything")

Read this after every context compression, with the city kit's JOB_BOARD.md. Tick an item only when its test says
RESULT PASS, and commit and push after every item. The old game is the checkout at
`C:\coronado_b17int19_hud_onelap_rebake1_treevis1_mobilevk1_actprobe1_src6_source\coronado-actprobe1-source\project`
(read only; never written to).

## Yasin's words for this queue
- "REWRITE THESE FULLY INN C PLUS PLUS, zero scripts: 1. cyclists inside the traffic core; 2. route finding in the traffic core"
- "HUD, minimap, the phone UI, menus, settings, loading screen, bring these over from the old game after your queue is
  finished, make jusdgement calls and rewrite in c plus plus if necessary"
- "bring these completely too, lessons, narrator, jobs, money and ATMs, minigames, saving and profiles"
- "only you are working on the cars, no one else"
- "also make the bikes able to crash to cars, make a rideable bike for the player, make sure its designed for touch
  controls, make sure it moves realistic like the cars, our view should wobble riding it. add damage to the bikes, we
  should be able to get ejected if we hit a car hard enough. use all relevant animations"
- "make them try to get out of the way and break hard at the same time. but add it to the very end of the queue"
  (the traffic's drivers, faced with something sudden: swerve AND brake hard, not only brake)
- "dont forget to add our pro animations whereever they apply, for crashes and ejection use your ragdoll system."
- (on the first crash film) "we flew up too much"; "body should have weight, i didnt mean propel when i said eject";
  "they should still end up somersaulting to the other side of the car"; the hands: "turn the left hand 90 degree right
  and right hand 90 degree right"
- "when you come to those items, start the player next to a bike and car in the city center, make sure they land on a
  way rather than in or on a building once the new game button is clicked"
- "we need some updates ffor the hud. upper right mini map should be a phone icon sized box, displaying a 3d looking 2d
  arrow head like shape showing the mission direction in green color, if there is no objective, golden yellow colored
  arrow head showing north. once clicked, it should review the full phone map, both should be adapted to the new layout
  of the map"; "and left corner money and time should fit into same sized box as phone and map"
- "integrate health and needs but keep them inactive for now"
- "so are there holes on the roads?" / "do that now" / "fix all of them then move on with your queue"
- "get the old games control scheme too, copy it as it was, same goes for everywhere else on foot too" (spec:
  docs/OLD_CONTROLS_SPEC.md); the bike: "only activate after we get onto it ... much more subtle. two pedals to acc and
  brk on the lower right and left side of the screen for steering"; "dont add a steering wheel on the left, it should be a
  blank screen only accepting inputs"
- "if there is a saved game, in the main menu, game should take a screenshot from the game will load from, that screen
  should be shown on the loading menu and game should load into that scene directly, seamlessly"; "if there isnt a saved
  game yet, that screen should have a black background"
- "dont forget to copy the controls as it is, double taps on both sides for crouch and jump, and tapping the back sings a
  punch, alternating between right and left once we are in the cobat mode. when phone is swung down in landscape, we
  should enter combat mode, locking onto the nearest npc, and keep locked on until they are or we are defeated. give npcs
  some low health that takes a few jabs to run out and player character should get into fighting mode once we swing down
  hard"
- "make npcs defend themselves attack back or try to dodge sideways once we hit them, they shouldnt get into combat mode
  unless we hit them"; "player will tap the back of the phone for hitsm gyro accelero and mic will be used at the same
  time to detect thoose taps"
- "once they are defeated let them fall to ground ragdolling, but not weightlessly"
- Standing rules: everything per frame or tick in C++ (memory: runtime code in C++); scripts only for tools and tests;
  one question, one run; the phone last; don't waste his usage or his PC; say what was not checked.

## The judgement call (how much becomes C++)
- C++: anything that runs every frame or tick, anything that searches or sorts (route on the map, minimap drawing,
  the HUD's numbers, the phone's map, job and delivery logic, money, the save file's reading and writing, the lesson
  and narrator queues, the minigames' own rules).
- Godot scenes and themes (.tscn / .tres, no script): the panels' layout, fonts, colours, where a C++ node can build
  its controls itself it does. No GDScript in the game's own code.

## The queue (in order)
1. [x] (19 Nov, doc section 34) Cyclists inside the traffic core (K_BIKE, the riders in the crowd's one far draw, the bike batch). Test: tests/traffic/test_bikes.gd + test_traffic_core RESULT PASS.
2. [x] (19 Nov, doc section 34) Route finding in the traffic core (A*, one finder for buses, taxis, scripted cars, the map's way; CityTraffic.route). Test: tests/traffic/test_route.gd.
2b. [x] (19 Nov, tests/traffic/test_bike_hit.gd) Cyclists crash into cars (a car or the player's car hits a cyclist hard: he comes off: the balancing body / a
      fall, the bike lies; gets up, picks it up, rides on, or walks it away hurt).
2c. [x] (19 Nov, doc section 36, tests/people/test_bike_ride.gd) A bike the player rides (C++ node like CityCar): pedalling, gears-free speed, steering by leaning, brakes,
      skids; touch controls (left thumb steer, right thumb pedal / brake, a button to get on and off); the camera
      wobbles with the pedalling and the bumps; damage (bent wheel, chain off, wobbling bar); a hard hit throws the
      player off (his balancing body, falls, gets up); the Quaternius clips that fit (getting on / off, falls, get up).
      Test + one picture.
3. [x] (19 Nov, tests/game/test_shell.gd) Loading screen (old: core/boot/loading_screen.gd, boot.gd, pack_progress.gd).
4. [x] (19 Nov, test_shell) Menus: main menu, pause menu, game over (old: core/main_menu.gd, pause_menu.gd, game_over.gd, ui/kit, ui/theme).
5. [x] (19 Nov, test_shell; the graphics preset and render scale are stored for the city to read, not yet applied to it) Settings (old: core/game_settings.gd, settings_panel.gd, view_distance.gd; per-phone device settings).
6. [x] (19 Nov, test_shell) Saving and profiles (old: core/save_game.gd slots, profiles.gd, game_state.gd: hour, day, clock).
6b. [x] (19 Nov, tests/game/test_start.gd in the real city) NEW GAME START (Yasin): the player set down in the city centre beside a bicycle and a car, on a way (pavement or
      road), never in or on a building.
6c. [x] (19 Nov) HOLES in the city's collision on the ways: tools/city/audit/collision_holes.gd found 89 (each about 1 m,
      49 on the seams between cells; review/collision_holes_19nov/holes.txt); WayFloor (C++) lays a collision floor 3 cm
      under every lane, junction path, pavement and crossing round the camera, so none of them can be fallen through. The
      list went to the city-kit session to mend in the pieces / bake.
6d. [x] (19 Nov, tests/people/test_touch_controls.gd: walk / run, look, both double taps, the car's GAS / BRAKE and reverse, the bike's pedal and steering; the Use plate and the phone button come with the HUD, item 7) THE OLD CONTROL SCHEME copied as it was (docs/OLD_CONTROLS_SPEC.md): on foot the invisible left-half move stick
      and right-half look, double taps (crouch / jump), the Use plate, the phone button; the car's GAS / BRAKE plates and
      speed plate; the bike the same (blank left steering, two pedals at the lower right, only while riding: done in a
      first form). Keys as the old game.
6f. [x] (19 Nov, tests/people/test_player_fight.gd; the phone sensing is written but NOT tried on a phone) COMBAT MODE (Yasin): a hard downward swing of the phone (landscape; the accelerometer) enters it: the player takes
      his fighting stance (PunchKick_Enter / fight idle), locks onto the nearest person and stays locked until one of them
      is beaten; a tap on the BACK of the phone (a sharp spike on the accelerometer) throws a punch, right and left in
      turn (Punch_Jab / Punch_Cross); people have low health (a few jabs), blows and falls by the balancing body, the
      beaten one down (not killed: Yasin earlier "they shouldnt kill each other"); keys for the PC (F fight, mouse click
      punch) to test.
      People never fight unless the player hits them; once hit they defend, hit back or dodge sideways (Yasin). The back
      tap is detected from the GYRO, the ACCELEROMETER and the MICROPHONE together (Yasin): all three must agree.
6e. [x] (19 Nov, tests/game/test_save_picture.gd in a real window; the main thread reads the frame in 6.7 ms on the PC, the shrink and jpg on a thread; NOT measured on the phone) THE SAVED GAME'S PICTURE: the menu and the loading screen show where the save left off (taken from the game),
      Continue fades from it into that place seamlessly; black when there is no save.
7. [x] (20 Nov, tests/game/test_hud.gd in a window RESULT PASS; the phone shows a place for its map: item 8; NOT on the phone: the vibration, the touch) HUD (Yasin's layout: top right a box the size of the phone icon with a "3D-looking" flat arrowhead: GREEN pointing
      to the mission, GOLDEN YELLOW pointing north when there is none; tapping it opens the phone's full map; top left
      money and time in a box of the same size; HEALTH AND NEEDS integrated but INACTIVE for now)
      (Yasin, 19 Nov: "make sure the expansions happens animated along several frames for both the map and the phone, with
      sound effects and vibration when touched. also put an inventory on the left down corner stick to the ui standards
      again, phone sized, when clicked displays weapons we have, none for now in the game"): the map and the phone open
      and close animated over several frames, a sound and a short vibration on each touch; an INVENTORY box bottom left,
      the phone's size and look, that opens the weapons we carry (none yet: an empty list). (old: ui/hud/hud.gd, objectives.gd, ui/health_bar.gd, needs_hud.gd, caption_help.gd).
8. [x] (20 Nov, tests/game/test_phone_map.gd in the real city and test_hud.gd, both RESULT PASS in a window; the enterable rooms = the shops' doors of places.bin; up to 3 player targets routed and saved (Yasin); NOT on the phone: pinch and drag) (the HUD arrow box replaces the minimap, Yasin) The phone's map (old: ui/phone/map_view.gd, ui/hud/coronado_route.gd: the way on the map from item 2).
9. [ ] The phone UI and its apps (old: ui/phone/*: phone, apps, call, camera, CV, delivery, films, jobs, learn, transit, drone).
10. [ ] Money and ATMs (old: economy/economy.gd, atm.gd, broke_watch.gd).
11. [ ] Jobs and deliveries (old: jobs/jobs.gd, delivery/*, ui/jobs/*, minigames/jobs/*, cityride/city_ride.gd: the taxi).
12. [ ] Lessons (old: lessons/lessons.gd, lesson_panel.gd, lesson_unlocks.gd, ui/phone/learn_app.gd).
13. [ ] Narrator, captions, dialogue (old: voice/*: narrator, captions, dialogue, speech_out; ui/dialogue, ui/npc).
14. [ ] Minigames (old: minigames/*: minigame base, home problems, alien dreams; ui/pc).
15. [ ] What these need that is not listed: char creator / wardrobe (core/char_creator.gd, ui/wardrobe), story chapters
      (story/chapters, core/story.gd), i18n (core/i18n.gd, strings.csv): ask Yasin before porting these.

6g. [~] (CARS done 19 Nov: car-tex r3 of the assets branch, 8e579333a: the 12 models' new meshes, trim sheet and per-car normal / AO maps, in the traffic's near and light models (traffic_car.gdshader map_mode 2 / 1), the far shape (volt_x's far colour) and the player's car (car_paint.gdshader); tests/traffic/test_car_damage.gd. BIKES: not on the branch yet, Yasin: "bike is coming wait for it i forgot to push") NEW CARS AND BIKES (Yasin, 19 Nov: "big news, we got new cars and bikes, replace the games cars, players car and
      npc bikes and player bikes with these here https://github.com/yasinyigitbas-max/coronado-source/tree/assets after
      save load"): the traffic's cars, the player's car, the cyclists' bikes and the player's bike from the assets branch.

6h. [x] (19 Nov, tests/traffic/test_car_damage.gd and test_knock.gd RESULT PASS; NOT done: lamps breaking, sparks and glass bits, the player's car's damage in the save, the fuel-station repair) CAR DAMAGE ON EVERY CAR (Yasin: "apply the damage to the new cars too"; "every other car should get damaged too
      once collided"): the old car_damage.gd in C++ (CityCar): dents, scratches, glass, engine power, smoke, crash sounds;
      a knocked traffic or parked car is a CityCar, so it is damaged too; a dented car stays a wreck (no undented row again).
6i. [x] (20 Nov, tests/traffic/test_road_rage.gd RESULT PASS in a window; the car-against-car fight between two drivers is written but NOT seen in a test yet) ROAD RAGE (Yasin, 19 Nov: "once collided, the driver should get out and attack us, unless its a parked car of
      course, then no one gets out, but if a moving car is hit by us first they should get off, then yell and get angry,
      then attack us, putting us in combat mode, also whenever there is an aggressor in the screen, we should get into the
      combat mode"): a moving car the player hits: its driver gets out (a crowd person at the door), yells, attacks; the
      player is put in combat locked on him; any aggressor on screen puts the player in combat. (Yasin: "if other cars hit each other, they should try to attack the aggressor
      car instead": two traffic cars collide: the hit car's driver gets out and goes for the driver who hit him.)

## Queue order from Yasin (19 Nov): after the HUD (7) ONLY the phone map (8). The other phone apps (9) and 10-14 stay
## NOT DONE, kept here for later.

## Found, to trace
- tests/traffic/test_bike_hit.gd: one run in two (19 Nov) the hit cyclist's hips went 19 m up (the other run 1.06 m):
  a rare launch of the thrown rider; not deterministic between runs. Trace the one rider when it happens.

## Still waiting on Yasin (from before)
- His go for people inside the shops; the voices; a fresh bake, then make_streets.gd, make_places.gd and the tests.

## The very end of the queue (Yasin: "add it to the very end of the queue")
99. [ ] Drivers swerve out of the way and brake hard at the same time when something sudden is in front of them (the
    core now only brakes, then goes round); keep the core's no-overlap veto and the 12 runs passing.
    (20 Nov, seen in the road rage runs: drivers already avoid the player's car, several head-ons missed because the
    other driver slowed and steered round; that is the core's brake-then-go-round, not a hard brake AND a swerve at once.
    Yasin: "keep it in mind for later".)
