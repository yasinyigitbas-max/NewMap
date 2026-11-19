# Ambient occlusion link audit

Date: 19 Nov 2026, Europe/Istanbul. No commits or pushes. `/workspace/push_repo` was not modified. Atlases A/B/C/W/I and `props_atlas.json` were not overwritten.

## What was wrong

Near-tier buildings, modular pieces and parks already have `occlusionTexture` pointing at the packed ORM (R = AO, G = roughness, B = metallic; SPEC line 84).

All 479 prop near GLBs and all 66 fence near GLBs had the ORM as `metallicRoughnessTexture` plus a normal map, but **no `occlusionTexture`**. Mid and far are colour-only with vertex-colour AO in `COLOR_0` by design; they were left alone. Old foliage near GLBs have colour + normal only (no ORM) and are being retired, so they were skipped.

## Is the ORM R channel real AO?

**Yes, for the great majority of used UV islands. Prefer linking; do not rebake or overwrite the atlases.**

Whole-atlas R has min 0 and a high standard deviation because unused atlas padding is often black (or mixed black/white), not because used islands are empty. A UV-island mask was rasterised from every prop and fence near GLB (glTF UV origin = top-left, matching the atlas region convention). Stats below are for island *interiors* after a 2 px erosion, so they exclude padding bleed.

| Atlas | Size | Near files | Used fraction | Interior R mean / std | Interior frac R<16 | Unused R frac=0 | Verdict |
|---|---|---|---|---|---|---|---|
| props_orm.png (A) | 512 | 339 | 54% | 134 / 73 | 12.6% | 29% | Sound structure; some unique tiles are very dark |
| props_b_orm.png | 256 | 93 | 56% | 198 / 65 | 2.1% | 53% | Sound |
| props_c_orm.png | 256 | 3 | 50% | 178 / 66 | 0% | 0% | Sound (manhole lattice is textbook AO) |
| props_i_orm.png | 256 | 62 | 49% | 142 union / **per-prop mean 217** | union 21% / **per-prop 5%** | 14% | Sound. Union looks darker because shared light swatches are counted once; each indoor prop mostly samples light AO |
| props_w_orm.png | 256 | 48 | 64% | 173 / 79 | 5.9% | 24% | Sound, with a couple of dark outliers |

Building reference: `city_orm` / `bld_orm` remapped AO into 128–255 (means 246 and 241). Prop unique tiles were not remapped, so cavities can go to 0.

Per-prop texture-AO means (R under that model’s own UVs):

- page B / I / W / C typical means are 180–230 (similar in spirit to buildings).
- page A typical mean is ~149. 36 of 339 page-A near files have >30% of their island pixels with R<16.
- Indoor (page I) already has strong vertex AO (`COLOR_0` mean ~0.41). Texture AO on top is mild (mean ~217).
- Many street / house / fence models have `COLOR_0` = 1 (no vertex AO), so the ORM is the only AO besides what was baked into the colour map.

Outliers (unique tiles that will go quite dark if occlusion is applied at strength 1, mostly page A, plus 2 streetside). These look like a mix of real deep cavities and a few tiles whose R is solid black on a large face (e.g. solar-panel equipment box, one mailbox door):

- `prop_porch_light_barn_*` (R mean 37, 64% of UVs under 16)
- `prop_wheel_stop_rubber_clean` and `prop_wheel_stop_concrete_clean` (page W)
- `prop_golf_cart_*`, `prop_bbq_gas_cart_*`
- `prop_solar_panel_*`, `prop_vent_box_*`, `prop_mailbox_wall_brass_*`
- `prop_trash_receptacle_*` / `prop_recycling_receptacle_*` have strong but *structured* cavity AO (ribs, opening) — not flat black.

Crops and atlas overlays: `_staging/ao_link/reports/crops/` and `props_*_orm_*.png`.

## What was written (staging only)

Script: `_staging/ao_link/tools/link_occlusion.py`

It copies each near GLB to `_staging/ao_link/assets/coronado_kit/...` (same names, repo-relative paths), adds

```json
"occlusionTexture": {"index": <metallicRoughnessTexture.index>, "strength": 1.0}
```

to every material, and copies the BIN chunk byte-for-byte. JSON is re-packed and 4-byte padded. The pushed repo was not touched. `atlases/` in the staging tree is a symlink to the repo atlases so URIs resolve.

### Files changed, per family (all added, 0 already present, 0 skipped, 0 errors)

| Family | Near GLBs linked |
|---|---|
| props/street | 93 |
| props/house | 84 |
| props/city | 63 |
| props/indoor | 62 |
| props/park | 48 |
| props/construction | 42 |
| props/yard | 39 |
| props/waterfront | 34 |
| props/streetside | 14 |
| fences | 66 |
| **Total** | **545** |

Verification: 545/545 BIN chunks identical to source; 545/545 `occlusionTexture.index` matches the ORM texture; 545/545 load in pygltflib and resolve texture URIs. No mid/far files were written. `gltf-validator` is not installed. Blender 4.5.14 imported the three preview GLBs successfully (one instance, `-t 2`, `nice 19`).

## Before / after

Sheet: `/workspace/coronado_kit_v2/_staging/ao_link/reports/ao_before_after.png`

Individual frames: `ao_{bollard,checkout,trash}_{before,after}.png`.

Blender’s glTF importer *does* wire occlusion into a “glTF Material Output” group when `occlusionTexture` is present, but **Cycles does not render that group**, so a naïve import of before vs after was pixel-identical. The after column therefore multiplies ORM R into Principled Base Color, which is a stronger preview than Godot’s default (AO mainly on ambient / indirect, unless `ao_light_affect` is raised). In-game the effect should be milder than the sheet.

Measured on the sheet (albedo-multiply preview):

- Bollard: visible darkening in cap seams, collar and base bolts; shaft slightly richer. Max |Δ| = 35, not crushed.
- Checkout: almost unchanged (texture AO is already ~0.95; vertex AO is doing the heavy lifting). Max |Δ| = 6.
- Trash: flutes and the opening darken a bit; the body stays readable. Max |Δ| = 57 in cavities, not a black silhouette.

Overall: the effect is visible in crevices and not too dark on typical props. The page-A outliers listed above are the risk if strength stays at 1.0.

## Checkers

Near tiers now fail without `occlusionTexture` pointing at the same texture as `metallicRoughnessTexture`. Mid/far fail if it is present.

Updated in place (not in push_repo):

- `_staging/indoor/tools/i_check.py`
- `_staging/house/tools/h_check.py` — house decorative GLBs that are still being built will start failing this until their exporter also writes `occlusionTexture`
- `props/validate_props.py`

Copies also live under `_staging/ao_link/` so a later push can include them.

## Not done / not broken

- No atlas rebake, no `props_atlas.json` edit.
- Mid, far, collision, buildings, modular, parks, foliage untouched.
- Nothing committed or pushed.
