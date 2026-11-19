# Measured facts and traps

## Streets (measure, never assume)
- Property line from the street centre: residential / standard legs 9.2 m; 3rd / 4th St arterial 14.3 m (tapering to
  8.7 by J Ave); 1st St and the inland ring 14.31 m; Amber's divided stretch 16 m; truck avenues 8.7 m.
- Driveway aprons: `s_ar_*` legs record `"apr"` per side (9 m wide); the ring's arterial stubs have none; stub aprons
  every 35 m from z0+18 where no-parking signs mark them. Residential, standard and two-lane ring legs have only the
  alley apron at 54-60. Arterials and Amber have no alley mouths. 1st St and Alameda have no aprons: offices and
  counters face them, no truck gate.
- Lots are entered at an apron. Service lanes at 54-60 line up with the alley aprons, so alleys run through the block.

## Kit models
- `ext_marina_office` carries a 20 m jetty in its mesh. Car wash +5 m canopy, harbour office +4 m porch, warehouse and
  factory +3.5 m. Use the real near-mesh outline.
- `ck_grt_row2`: windows painted boarded, and its painted windows overlap its own side door: never an open shop.
- `com_shallow_books` / `_cafe`: house doors (`O_apt_door`) the shared room cut does not open. Prefer `O_shopdoor`.
- `prop_tank_vertical` is 9 m across; the dock crane is a 39 x 4 m pedestal jib crane; water tower 11 m; billboard
  14.6 m. Read `footprint_w/d` of every big prop.
- The boat trailer model carries its boat. Containers yaw 0. Enclosure gates count as fence ends.
- A utility pole stands on a gravel pad. Shade sails read as bare poles from above and below: look from eye height.
- Indoor props were rebuilt on 19 Nov and sizes moved (bike_stand 0.7 -> 1.7 m). Kit shelves are stocked since dd8d53a.
- The kit has only `svc_carwash` (no tunnel wash, vacuum or menu board).

## Fences and wall items (geometry that bit)
- A run that is not a whole number of panels: end panels flush with the ends, overlap shared in the middle; a run
  shorter than one panel gets one shortened panel (never stretched), kept away from walls.
- Plants stand at random angles: space them by half their DIAGONAL. Walls are 0.38 m thick.
- Items placed before the fences can end up under them: look again after the fences.
- Fences at corners cut across on the diagonal past the junction's furniture; own-edge walls 0.7 m in from a boundary
  the neighbour leaves open. Loose things keep 0.5 m inside the block's edges.
- Chain-link only round yards inside a block, never along a street, never one fence behind another (layered see-through
  things cost the phone about 40 % more GPU). Opaque walls where something must be enclosed.

## Budgets
- Phone: about 150 draws a view (Yasin's first rule); triangles secondary but report them (say when over ~500k).
- Measured in the cloud, not on the phone: industrial pilot worst view 78 draws / 387k triangles; strip 44-70 draws,
  443-822k triangles, +11.7 MB.
- Rooms are not in the bake: 21-36 draws and 4-6 lights each unmerged; `room_merge.gd` brings a room to about 9 draws.

## The PC (Windows, 2 GB graphics card)
- Godot: `C:\Users\yasin\Godot_v4.7.2-stable_win64.exe --path . --rendering-method mobile ...` (real renderer: mesh and
  MultiMesh data are empty in `--headless`). No `xvfb`, no `godot` on PATH: `checks.sh`, `build.sh`, `terrain.sh` are
  written for the cloud.
- Python: `C:\Users\yasin\AppData\Local\Programs\Python\Python312\python -I`; `python3` is the Windows Store stub.
- Git Bash turns `rev:path` arguments into Windows paths: `export MSYS_NO_PATHCONV=1` before `git show rev:path`.
- The whole city does not fit the card. Load an area: write a layout json with the rows near the place, run with
  `CITYKIT_LAYOUT_ONLY=1 CITYKIT_LAYOUT_EXTRA=<json>` (an absolute path works). Say in the caption that only that area
  is loaded.
- A camera can land inside a tree: open every shot before sending it.
- Scripts and scratch files that are not part of the map go in the session's scratch folder, not the repo.
- A Godot script that hits a SCRIPT ERROR does not quit: kill the stale process before running the same job again.
  `--check-only` every changed script first.

## Checks: how they mislead
- `checks.sh` prints only the LAST 30 validator lines.
- A stale check run reads pieces mid-write and reports nonsense: stop older runs first.
- `check_life.gd --only=<prefix>` does not load the neighbours' fences: fence ends falsely "lead nowhere".
- `free_at()`-style guards silently skip props that collide: COUNT what landed in the saved piece.
- `find_children` on an instanced scene needs `owned=false`.
- After a table change the layout must be regenerated, or you check and photograph without the new pieces.
- The layout json is written with CRLF on Windows: compare the JSON, not the text.

## Beside other sessions
- A peer session's message is information, not Yasin's approval.
- Name by zone prefix; keep your own tables; add lines to the job board, never rewrite others'.
- Import stubs (`.uid` / `.import`) of other sessions' files appear after merges: do not commit them.
- Other sessions' faults are theirs: report, do not fix.
- A private repo you cannot reach: ask for the files to be pushed here; do not route around a refusal.
