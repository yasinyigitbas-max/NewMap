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
3. [ ] Loading screen (old: core/boot/loading_screen.gd, boot.gd, pack_progress.gd).
4. [ ] Menus: main menu, pause menu, game over (old: core/main_menu.gd, pause_menu.gd, game_over.gd, ui/kit, ui/theme).
5. [ ] Settings (old: core/game_settings.gd, settings_panel.gd, view_distance.gd; per-phone device settings).
6. [ ] Saving and profiles (old: core/save_game.gd slots, profiles.gd, game_state.gd: hour, day, clock).
7. [ ] HUD (old: ui/hud/hud.gd, objectives.gd, ui/health_bar.gd, needs_hud.gd, caption_help.gd).
8. [ ] Minimap and the phone's map (old: ui/phone/map_view.gd, ui/hud/coronado_route.gd: the way on the map from item 2).
9. [ ] The phone UI and its apps (old: ui/phone/*: phone, apps, call, camera, CV, delivery, films, jobs, learn, transit, drone).
10. [ ] Money and ATMs (old: economy/economy.gd, atm.gd, broke_watch.gd).
11. [ ] Jobs and deliveries (old: jobs/jobs.gd, delivery/*, ui/jobs/*, minigames/jobs/*, cityride/city_ride.gd: the taxi).
12. [ ] Lessons (old: lessons/lessons.gd, lesson_panel.gd, lesson_unlocks.gd, ui/phone/learn_app.gd).
13. [ ] Narrator, captions, dialogue (old: voice/*: narrator, captions, dialogue, speech_out; ui/dialogue, ui/npc).
14. [ ] Minigames (old: minigames/*: minigame base, home problems, alien dreams; ui/pc).
15. [ ] What these need that is not listed: char creator / wardrobe (core/char_creator.gd, ui/wardrobe), story chapters
      (story/chapters, core/story.gd), i18n (core/i18n.gd, strings.csv): ask Yasin before porting these.

## Still waiting on Yasin (from before)
- His go for people inside the shops; the voices; a fresh bake, then make_streets.gd, make_places.gd and the tests.

## The very end of the queue (Yasin: "add it to the very end of the queue")
99. [ ] Drivers swerve out of the way and brake hard at the same time when something sudden is in front of them (the
    core now only brakes, then goes round); keep the core's no-overlap veto and the 12 runs passing.
