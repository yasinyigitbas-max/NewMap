# Build handover (28 Nov): make the downloadable Android build

For the local session on Yasin's PC. Written by the cloud traversal session (branch `claude/intelligent-bardeen-errnbs`,
kept equal to `main`). Yasin has no cable: the build must end as a GitHub release he downloads on the phone.

## What to do
In Git Bash, inside the NewMap clone, with Godot and the editor CLOSED:

    git checkout main
    git pull
    bash tools/city/rig/publish_build.sh

The script does, in order: `tools/traversal/sync_to_game.sh` (copies the new character, clips, props and NPC bodies to
`res://traversal/`, 55 MB, not in git), `phone_rig.sh bake` (needed: the damage system reads surface names and the
ground map from the bake), `phone_rig.sh export` (runs `native/build.sh` first: Windows dll + Android .so, then the
APK to `OUT/citykit_rig.apk`), then `gh release create build-<day><month>-<hhmm>` with the APK, as the builds of 20 and
21 Nov. `NOBAKE=1` skips the bake. Without `gh` it prints the APK's path: upload it at
https://github.com/yasinyigitbas-max/NewMap/releases/new . Give Yasin the release link.

## What is new and never built on this PC
- `native/build.sh` now also compiles `native/traversal/src/*.cpp` into the game module with `-DTRAV_IN_GAME`
  (the traversal classes; new files in `native/src`: `city_crowd_trav.cpp`, `trav_mirror.*`). In the cloud all files
  compiled for Linux and, with the cloud's mingw, for Windows. The Windows link, the Android build and any run on
  Windows or a phone have NOT been done: expect the first errors here. Fix compile errors in place, keep the meaning,
  commit and push to `main` and to `claude/intelligent-bardeen-errnbs`.
- After the bake the traffic's `make_streets.gd` was not added to the script (assumed: no map piece changed). If the
  street data is stale, run the pipeline of `.claude/skills/coronado-traffic-people/SKILL.md` ("after EVERY bake").

## What the build should show (tell Yasin what you saw and what you did not)
- The new character by default (`-- --oldplayer` gives the old one; `-- --oldpeople` the old near crowd).
- Touch buttons at the right edge: USE, HANDS, AIM, FIRE, RELOAD, DROP (places not tried beside the HUD's buttons).
- Up to 12 people near him as the new bodies; the new police cars, ambulance, trucks and van.
- Not tried anywhere yet: the real city, a phone, the bicycle, a bench at its real height, blows landing.

## Rules
Yasin's rules are in `CLAUDE.md`, `reports/TRAVERSAL JOB BOARD.md` (section WIRE IN) and
`.claude/skills/coronado-traversal/SKILL.md`. Do not change `traversal_lab/` (gated, the checks are locked). No keys
in files or chat. Plain short reports that say what was not checked.
