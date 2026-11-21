# ck_brk3_res2: residential 12 m brick row (pilot, 21 Nov 2026)

Drop-in for ck_brk3_row2 / row2_fe: same shell (sides, backs, roofs, 12 x 14 m, 3 storeys, h 10.3), same pivot, front doors
at x = -1.1 and +3.0 (= row2 / row2_fe). Ground floor: apartment doors with stoop + rails + hood, 6/6 sash windows,
stone plinth, concrete lintels, white belt course, cornice + drip. City atlas regions only (no atlas pixel changed).

Not placed in any piece yet.

Build (scratch kit = copy of the coronado kit tools; the generator is pure Python):
1. `mod_res.py` + `run_res.py` (kit modular/tools): pieces urb_brk_front_6m_3sty_res (646/162/34) and
   urb_brk_front_6m_3sty_walkup_t (702/170/34) -> assets/coronado_kit/modular/pieces/urban/.
2. `merge_modular_gltf.gd -- res://tools/city/pilot/modular/ck_brk3_res2.json` (reads the piece glbs with GLTFDocument
   because the box cannot run the importer) -> near 3328 / col box.
3. LOD match without repacking the shared page: `dump_mesh.gd` (row2 mid/far, res2 mid) -> `front_bake.gd --kit=ck_brk3_res2`
   -> `res2_lod.py` (front charts into the EMPTY rows 2015-2040 of textures/bld_lod_color.png; every other pixel
   unchanged, asserted) -> `apply_res2_lod.gd`. Mid 848, far 34. Budget (SPEC apartment block): 3500 / 1000 / 80.

The new piece glbs have no .import on the box (Godot --import aborts on _staging .blend files): reimport on the PC.
