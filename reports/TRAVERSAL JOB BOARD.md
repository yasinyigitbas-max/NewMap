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
- [ ] b. Detection.
- [ ] c. The character and its corrections.
- [ ] d. The traversal moves.
- [ ] e. Doors, sitting, the phone, the car, cover.
- [ ] f. The NPC fitting.
- [ ] His play-test of the C++ version; then, at his word, C++ becomes the default.

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
- [x] (trav85, trav86) the cast: twelve more bodies (npc_05 to npc_16) and a second elderly woman (npc_17); who each
      is: `assets/people/meshy/cast.json`. 57 Meshy credits left on 27 Nov (one more body); they reset on 23 Dec.
- [ ] five bodies got no finger bones from Meshy though asked (npc_07, 08, 09, 11, 14, 17): their hands move as one
      piece. Meshy's rigger also adds bones of its own, different on each body: `build_npc.gd` prints them.
- [ ] the texting grip on their hands; the woman's feet when seated (toes 7 cm up on the 0.45 m bench) and in the
      car; stairs up (a foot 3.2 cm off); the big toe at push-off (14 to 16 degrees).
- [ ] an NPC's own walking and running pace (his stride is his own; the pace is still the player's 1.45 m/s).
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
