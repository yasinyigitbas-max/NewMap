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
- [ ] 2. Stage 17, what is left: the wall-ledge sidle (the study: "For a ledge with a wall behind, allow a sidle
      down to about 0.10 m"). The course has no such ledge: build one in the test.
- [ ] 3. Stage 19: ragdoll on hard impact and long fall, with get-up by lying direction.
- [ ] 4. Stage 20: partial ragdoll hit reactions.
- [ ] 5. Stage 21: cover, low and high: enter, peek, exit.
- [ ] 6. Stage 22: doors: push, then pull.
- [ ] 7. Stage 23: cars: bonnet slide, then entry and exit. (No bonnet slide clip exists.)
- [ ] 8. The phone pass of every stage (the study: "Phone testing of each stage follows the desktop pass"). Never
      done for any stage.
- [ ] 9. Sitting and phone use (27 Nov, his list, to the end of the queue): stand to sit, walk to sit, sitting idle,
      sit to stand, sitting phone talk, sitting messaging, sitting to type, walking text, standing text, standing
      call.

## Known weak points (not in the queue until he says so)

- He slows into the mantle and the grab at a run; only their exits are running.
- The grab from standing at 2.60 m is carried 0.54 m above the take's jump; the wall climb at 3.00 m 0.60 m higher.
- Thin walls: stepped off and a plain fall from up to 3 m, unless the stick is let go.
- The climb down ends facing the wall; it is asked for by crouching at the edge (my choice).
- The balance fall from 3.1 m up is always face down.
- Running-jump bands other than the vault are untested; the longer step over a shallow gap under 0.78 m was not
  run; running off the side of a beam was not run.
- In a 0.26 m gap a forearm joint is 0.025 m into a wall. Fingers do not curl on any hold (no finger correction).
- On a beam the walking feet are not brought onto it, only the standing feet.
- His open list, items 3 to 5 (stage 1 random-walk faults, the stops and the kerb step, the 26 audit lines):
  untouched by his rule ("if things dont improve by a 20% ... dont change anything").

## Waiting on Yasin's eyes

- trav69: feet on beams and wall tops, the arm flicker in the balance fall, hands on a wall met end on.
- trav70: the squeeze through gaps. Whether "the character gets lost on many frames" is gone.
