# Patch note: props' normal maps in the bake (for the PC session; 18 Nov, look job 2)

**Why the maps are missing.** `tools/city/pilot/kit_lib.gd` `prop_wear_mat()` names a prop material by its colour atlas
and wear only (`pw_props_color_clean_55.tres`). The first prop that made each file was a mid tier, which has no normal
or ORM map, and every later prop of that page reuses the file. Result: 6 of the 18 `city_kit/materials/pw_*.tres` have
neither map: the kit's main prop page A (`props_color_clean`, benches, bins, lamps, kerb inlets ...) at every wear
level, and page W two-sided. The bake reads the flags from these materials (`bake_runtime.gd` `_props`: `has_n`, `u2y`).

**Done in the shader (this branch).** `ck_look_propmaps` (default 1): near props always read the ORM layer of their page
from `runtime_tex/arr_prop_orm.png` (it holds all five pages). Without it the shader's default ORM (white) made those
props fully metal and fully rough.

**What the bake needs for the normal maps** (`bake_runtime.gd`, `_props()`; not editable here):
1. After `page = _layer("prop_albedo", ...)`: every page has a layer in `arr_prop_normal.png` and `arr_prop_orm.png`, so
   for near props set `has_n = true` and `u2y = 3.0 (+ 4.0 for signals)` whatever the kit material says.
2. The merged meshes then get tangents (`cell.merged[key3].tangents = true` follows from `has_n`). `_merge()` copies
   the model's `ARRAY_TANGENT` when it has one, else writes (1, 0, 0, 1), which is WRONG for a normal map. Generate them
   instead: run the model through `SurfaceTool.create_from_arrays()` + `generate_tangents()` once per lib mesh (cache by
   `_mesh_key`) before merging. Checked here: a mesh without a tangent array still reads a placeholder TANGENT in the
   shader, so the shader cannot tell; the bake has to write real ones.
3. Mid tier: leave as it is (no maps, fewer reads at a distance).
Cost: one more texture read (normal) on near prop pixels of page A; tangents add 16 bytes a vertex to near batches.
