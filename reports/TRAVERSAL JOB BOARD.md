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
- [ ] 10. STOP HERE AND WAIT FOR HIS GO. On his go: take a checkpoint, then the ragdolls (27 Nov: "push the ragdolls
      to the end of the queue, add the other moves in succession until them then make another exe and them move onto
      the ragdolls after taking another checkpoint on my go"):
      stage 19, ragdoll on hard impact and long fall, with get-up by lying direction; stage 20, partial ragdoll hit
      reactions.
- [ ] 11. The phone pass of every stage (the study: "Phone testing of each stage follows the desktop pass"). Never
      done for any stage. (The Redmi run comes last.)

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
- Fingers do not curl on any hold (no finger correction).
- The sidle is taken to 0.30 m, not the study's 0.25 (mine); his arms hang, they are not spread on the wall; going
  back the way he came in a gap (not on a ledge) is not tested.
- On a beam the walking feet are not brought onto it, only the standing feet.
- His open list, items 3 to 5 (stage 1 random-walk faults, the stops and the kerb step, the 26 audit lines):
  untouched by his rule ("if things dont improve by a 20% ... dont change anything").

## Waiting on Yasin's eyes

- trav77: cover on the course's thin and deep walls (E facing a wall; the stick along it; held at its end to look
  round; E or the stick out from it to leave).
- trav75, trav76: the door (both sides), the car (in and out), the bench and the desk, the phone (T text, G call)
  standing, walking and seated. Stations after the wall ledges: `[` from the first station goes back through them.

- trav69: feet on beams and wall tops, the arm flicker in the balance fall, hands on a wall met end on.
- trav72, trav73: the sidle along a ledge with a wall behind; the last station key reaches the course's two ledges
  (0.20 and 0.12 m). Arms open and head turned the way he goes, on the ledge and sideways in a gap.
- trav70, trav71: the squeeze through gaps, either way round. Whether "the character gets lost on many frames" is gone.
