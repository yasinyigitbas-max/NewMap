# Prop wear shader

Godot 4.7, Vulkan **Mobile** renderer. Wear and dirt on props are no longer separate colour atlases. The game ships only the clean colour pages (`atlases/props_color_clean.png` 1024, and `atlases/props_b_color_clean.png` 1024 so sign lettering stays sharp) plus a small tiling grime map (`atlases/props_grime.png`, 512²). `shaders/prop_wear.gdshader` blends the grime over the clean colour.

The old hand-painted worn and dirty pages are in `_archive/props_condition_pages/` for reference. They are **not shipped**.

## Material setup

1. Make a Spatial material that uses `prop_wear.gdshader` (or assign the shader to the imported prop material).
2. Hook the textures:
   - `albedo_tex` — `props_color_clean.png` or `props_b_color_clean.png` (the same page the glTF already references). Turn **sRGB** on (the shader already marks it `source_color`).
   - `normal_tex` — `props_normal.png` (1024) or `props_b_normal.png` (512). This is a normal map (`hint_normal`).
   - `orm_tex` — `props_orm.png` (512) or `props_b_orm.png` (256). Packed **linear** ORM: R = occlusion, G = roughness, B = metallic. Do **not** mark this sRGB / `source_color`.
   - `grime_tex` — `props_grime.png`. sRGB, repeat enabled.
3. Set `wear`:
   - `0.0` = clean
   - `0.5` = worn
   - `1.0` = dirty (also use this for the old `rusty` variants)
4. Leave the other uniforms at their defaults unless you are tuning a specific prop. `grime_meters` is the world-space tile size of the grime (0.45 m). `bottom_bias` and `cavity_bias` pull dirt toward the foot of the object and into the AO cavities.

Vertex colours still tint the albedo (and carry baked AO on some props).

## Per-instance variation

Two adjacent props should not dirty identically.

- By default the shader hashes the object's world origin and varies `wear` by about ±20%.
- To control it yourself, set `INSTANCE_CUSTOM.a > 0.5` and put a 0–1 value in `INSTANCE_CUSTOM.x` (a MultiMesh instance custom data channel works). `instance_variation` scales how much that hash or custom value is allowed to move the look (0 = off).

The glTF worn / dirty / rusty files themselves are unchanged as meshes. They now point at the **clean** colour page, and each file carries `extras.coronado_wear` (0.5 for worn, 1.0 for dirty and rusty) on the root and on the material. On import, read that extra and copy it into the shader's `wear` uniform. Clean files have no extra; use `wear = 0`.

## Compression

Godot 4.7's Mobile importer compresses these PNGs as **ASTC 4×4** with mipmaps. There is **no ASTC 8×8 option** in the importer; do not pre-compress, and do not assume 8×8 in a memory budget.
