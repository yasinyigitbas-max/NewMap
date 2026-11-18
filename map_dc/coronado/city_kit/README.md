# city_kit: hand-made city pieces (pilot: Amber Ave x 10th St)

Each piece is one frozen scene in `pieces/`: a junction (`j_`), a street piece (`s_`), a downtown block (`b_`), or a
residential row (`r_`).
- **Authoring:** each piece is written once by its own script in `tools/city/pilot/pieces/`, then saved.
- **After approval:** the piece is locked in `locked.json`, and `tests/city_kit/test_locked_pieces.gd` fails if a locked file changes.
- **No regenerate-all:** nothing re-makes the city. Fixing one piece cannot touch another.

- Design and the reason for every feature: `PILOT_DESIGN.md`.
- Shared frame: origin at the junction centre, X east along 10th, -Z north along Amber.
- Placement in the world (not done yet): rotate by Amber's bearing (26 deg), then offset to about (-1752, 7.2, 3297).

## Commands (cloud session, preview project with the kit imported; see tools/city/pilot/preview/)
| What | Command |
|---|---|
| Build one piece | `godot --path PV --rendering-method mobile --rendering-driver vulkan -s res://tools/city/pilot/pieces/<piece>.gd` (needs a real renderer: MultiMesh data is lost under `--headless`) |
| Check all pieces | same with `-s res://tools/city/pilot/validate.gd` (prop overlaps, props inside buildings, blocked doors, props in lanes; must print `CHECKS 0 problems`) |
| Shots | `-s res://tools/city/pilot/preview/shots.gd -- --out=DIR "--cams=name:x,y,z:tx,ty,tz;..."` (env NOSHADOW=1 on lavapipe) |
| Lock after Yasin approves | `python -I tools/city/pilot/lock.py lock <piece> --by=Yasin`; `lock.py status` lists draft / locked |
