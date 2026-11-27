# Weapons (page G)

Hand-held weapons for the player and NPCs: four handguns and long guns, a sawn-off variant, four melee weapons and a
thrown one. Made by hand in Blender 4.5 from scratch (`tools/weapons/`): each weapon has a detailed source model
(bevels, cut serrations, ports, rail slots, screws, checkering and stippling, grip tape, wood grain) that is baked onto
a light game model. All generic: no maker's names, logos or part-for-part copies.

| file | what | triangles (budget) | length |
|---|---|---|---|
| `prop_pistol_service_*` | full-size hammer-fired service pistol, blued slide, black alloy frame, walnut grips | 272 (600) | 22 cm |
| `prop_pistol_polymer_*` | compact striker-fired polymer pistol (Glock-type silhouette) | 236 (600) | 20 cm |
| `prop_rifle_*` | flat-top carbine, free-float handguard, flip-up sights, tan 30-round magazine | 492 (1,200) | 92 cm |
| `prop_shotgun_*` | pump-action 12 gauge, walnut stock and grooved forend | 380 (1,200) | 100 cm |
| `prop_shotgun_sawn_*` | the same shotgun cut down: short barrel and tube, stock cut to a rough grip | 344 (1,200) | 50 cm |
| `prop_smg_*` | compact 9 mm sub-machine gun, magazine ahead of the grip, collapsed wire stock | 448 (1,200) | 45 cm |
| `prop_bat_*` | wooden baseball bat, taped handle, stained barrel | 240 (300) | 84 cm |
| `prop_knife_*` | fixed-blade utility knife, satin blade, rubber handle | 172 (300) | 24 cm |
| `prop_golf_club_*` | 7-iron, chrome shaft, rubber grip | 170 (300) | 99 cm |
| `prop_crowbar_*` | hex wrecking bar, red paint worn to steel | 140 (300) | 55 cm |
| `prop_molotov_*` | amber bottle, aged printed label, rag in the neck (the flame is a game effect) | 204 (300) | 27 cm |

Budgets are the kit's prop classes (SPEC.md section 4): handguns small (600), long guns medium (1,200), melee and
thrown tiny (300). Everything is well inside, so a weapon held right in front of the camera stays cheap.

## Files and rules (as the carry props on page J)
- `prop_<name>_clean_near.glb`: one mesh, one material (`props_g_atlas`), POSITION / NORMAL / TANGENT / TEXCOORD_0 /
  COLOR_0 (white). Near tier only: a hand prop is never seen past 60 m. One draw call each (+ its shadow).
- `prop_<name>_col.glb`: one box named `col` (for a dropped weapon).
- Textures: the shared page G, `atlases/props_g_color_clean.png` 1024 (sRGB, AO baked in), `props_g_normal.png` 512
  (OpenGL / Godot convention), `props_g_orm.png` 256 (R occlusion, G roughness, B metal); the glbs point at them with
  relative URIs. About 1.8 MB of video memory after ASTC 4x4, for all eleven. Not part of the street props cap.
- `manifest_weapons.json` (in `props/`): per weapon triangles, budget, size, texel density, grips, hold, muzzle, note.

## Frame and hand points
- Metres, Y up, **muzzle / business end towards +Z** (Godot's model front), **origin = `grip_r`** (centre of the
  right fist on the grip), so a weapon parented to the right-hand bone sits in the hand with no offset.
- Child markers of the mesh node: `grip_r` (origin), `grip_l` (support hand: pistols under the right hand, long guns
  on the forend / magwell, bat and club above / below the right hand), `muzzle` (guns only: barrel exit, for
  flashes, tracers and the shot ray).
- `hold` in the manifest names the pose family: `pistol`, `pistol_two_hand` (sawn-off), `rifle`, `two_hand_swing`,
  `one_hand_melee`, `throwable`.

## Rebuild
`tools/weapons/` (needs Blender 4.5): `blender -b -P build.py` (all models, bake at 2048, writes page G, glbs and the
manifest; `-- --quick` for a fast 1024 look-dev bake), `python3 check.py` (budgets, attributes, URIs, grips, UV
overlap, outward faces), `blender -b -P render.py -- <dir>` (preview renders and a lineup), `godot/godot_check.sh
<godot>` (imports and loads every glb in Godot 4.7). Review pictures: `previews/weapons/`.
