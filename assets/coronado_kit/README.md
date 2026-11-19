# Coronado kit (Crownado): buildings, props, fences, foliage, parks

The finished, validated assets for the Coronado city, built to `SPEC.md` (model rules and performance budget for Android, Redmi Note / Mali class). Every piece here passed the final audit; see `reports/final_audit.md` (per-piece result) and `reports/pass_list.md` (wall checks).

## Contents
| folder | what | count |
|---|---|---|
| buildings/houses | small and two-storey houses (ranch, Spanish, craftsman, cape, colonial, tudor, victorian, mid-century, contemporary, beach) | 31 |
| buildings/apartments | apartments, dingbats, garden courts, townhouses, condo | 12 |
| buildings/commercial | shops, cafe, bistro, bank, bar, gas station, shop rows | 11 |
| buildings/civic | city hall, library, police, fire, post office, school wing, church, museum, rec and community centres, harbour office | 11 |
| buildings/extras | hospital, motel, grocery market, marina office, parking garage | 5 |
| buildings/landmarks | hotel annex, chapels, theatre, ferry landing, mansion, lookout, boathouse, tollhouse, navy gatehouse | 10 |
| props/<batch> | city (21), construction (14), house (28), park (16), street (31), yard (13) manifest entries; clean / worn / dirty meshes remain, but worn and dirty colour pages are gone — wear is the shader + `props_grime.png` | 123 |
| props/waterfront | waterfront set: quay / seawall edge (straight, bollards, stair, inside and outside corner, pier root), timber pier (straight, T-head, railed end, lamp, gangway), marina (float, finger, pile, dock box, pedestal), moored boats (sloop, express cruiser, troller, skiff), promenade (rail, rail to wall, boardwalk) and small props (life-ring stand, mooring buoy, nun and can markers, fuel pump, boat on trailer, kayak rack, beach shower, volleyball net, open and closed umbrellas) on the 0.5 m snap grid, page W atlas; see `props/waterfront/README.md` | 34 |
| props/streetside | streetside / lot / motel / residential props (pylon and bus-stop signs, drive-thru menu, vending machines, ice chest, wheel stops, shopping cart and corral, balcony clutter, dingbat stair, buzzer panel, clothesline) on page W; see `props/streetside/README.md` | 14 |
| props/indoor | indoor shop fixtures (shared, food, grocery, clothing, salon, gift, office, services, sport, venue) on page I, near+col only; see `props/indoor/README.md` | 62 |
| props/house/{decor,furn,rugs} | interior house set: 36 decorative objects, 8 rugs and 26 furniture pieces on page H, near+col only; see `props/house/README.md` | 70 |
| fences | fence and wall panels (2 m) + posts, manifest in props/manifest_fences.json | 22 |
| foliage | trees, palms, shrubs, hedges (manifest_foliage.json) | 33 |
| parks | park layouts (`park_*.json`: kit prop/foliage instances) + their ground meshes | 11 |
| textures | shared building atlases (house `bld_*`, city `city_*`, far `far_color.png`, park ground `ground_*`) + layout JSONs | |
| atlases | shared props (`props_color_clean`, `props_b_color_clean`, `props_c_*`, waterfront `props_w_*`, indoor `props_i_*`, house `props_h_*`, halved normals and ORM, `props_grime`) and tree atlases | |
| shaders | `prop_wear.gdshader`: procedural worn/dirty overlay on the clean prop pages (wear 0 / 0.5 / 1) | |
| modular | snap-in starter set: house and shop pieces, 5 merged example assemblies, `godot/export_layout.gd`, tools, validation report. Loose pieces are editor-only; finished assemblies are one mesh per tier. Snap-in houses use the 1650 / 500 / 40 cap and include a chimney and step railing. | |
| previews | one near hero picture (JPEG) per building, park, prop and plant | |

## Tiers
| tier | distance | content | maps |
|---|---|---|---|
| near | 0-60 m | full model | colour (AO baked in) + normal + ORM (R occlusion, G roughness, B metallic) |
| mid | 60-220 m | about 30 % of near tris, no small parts | colour only |
| far | 220-1500 m | closed box hull with baked facade (far atlas) | colour only |
| col | - | collision, at most 12 main boxes + 16 post/rail boxes | none |

Small props are near only. Indoor shop props (`props/indoor/`) and the house interior set (`props/house/decor`, `furn`, `rugs`) ship near and collision only — they are not drawn at mid or far. Trees use a 2-tri camera-facing card as far. Files are named `<category>_<name>_<tier>.glb`; props use `<name>_<clean|worn|dirty|rusty|lush|dry|normal>_<tier>.glb`.

## Budgets (maximum triangles near / mid / far, SPEC.md section 4)
| category | near | mid | far |
|---|---|---|---|
| small house (< 120 m2) | 1500 | 450 | 40 |
| snap-in house (modular, < 120 m2, single storey) | 1650 | 500 | 40 |
| large / two-storey house | 2500 | 750 | 60 |
| apartment, court, condo (<= 30 m) | 3500 | 1000 | 80 |
| large apartment, motel (> 30 m) | 5000 | 1500 | 120 |
| shop bay (per 6 m) | 1200 | 350 | 20 |
| corner shop, bank, gas station | 2500 | 750 | 60 |
| civic | 5000 | 1500 | 120 |
| warehouse, parking garage | 2000 | 600 | 40 |
| landmark | 8000 | 2500 | 200 |
| props tiny / small / medium / large | 150-300 / 300-600 / 600-1200 / 1500-2500 | | |
| fence panel | 60 (chain-link 4) | | |
| street tree / palm / yard tree | 2500 / 1500 / 2000 | 800 / 500 / 600 | 2 |

Every asset's `stats.json` (buildings) or manifest entry (props, foliage) lists its tris per tier, budget, atlas regions, footprint and height. Nothing in this folder exceeds its budget. The red dry-barrel hydrant (590 tris) is an approved exception: it stays in the small-prop class (600 cap) instead of the tiny class.

## How to import (Godot 4)
1. Keep the folder layout. The `.glb` files reference the shared PNGs by relative path (`../../../textures/...` for buildings, `../../atlases/...` for props (`../../../atlases/...` for `props/waterfront/*`, `props/streetside/*`, `props/indoor/*` and `props/house/{decor,furn,rugs}/*`), `../atlases/...` for fences and foliage, `../../textures/ground_*` for park grounds), so moving one folder breaks its textures.
2. Godot imports the glbs and PNGs on first open. Set the PNG imports to VRAM compressed (ASTC 4x4 with mipmaps; Godot 4.7 Vulkan Mobile has no ASTC 8x8 option). The sources are uncompressed PNGs on purpose.
3. Set up the near/mid/far switch with `visibility_range_begin/end` on the three tier instances: near 0-60 m, mid 60-220 m, far 220-1500 m. Turn off shadow casting on mid and far.
4. Collision: use the `*_col.glb` boxes as StaticBody3D shapes (or create the shapes from the mesh).
5. Wall colour variety comes from the vertex colour tint already in the meshes. Window night glow is the shared emissive mask (`*_emissive.png`); drive its strength from the time of day.
6. Parks: `park_*.json` lists each instance (`base` asset, `cond` variant, `pos`, `rot_y`, `file` path relative to this folder) on top of `park_*/park_*_ground_<tier>.glb`. Spawn the props from `props/` and `foliage/` with one MultiMesh per prop type.

## Texture memory (15 Nov 2026)
- Props colour page A is 1024; page B stays 1024 so sign lettering stays sharp. Props normals are 1024 (page A) and 512 (page B); ORM is 512 and 256. Building `bld_*` and `city_*` normals and ORM are 1024; colour pages stay 2048.
- Worn and dirty prop colour pages are not shipped. Assign `shaders/prop_wear.gdshader` and read `extras.coronado_wear` from the worn/dirty/rusty glTFs (0.5 worn, 1.0 dirty or rusty). See `shaders/README.md`.
- 17 Nov 2026: waterfront page W (colour 1024, normal 512, ORM 256) adds 1.75 MB; props total 7.58 MB of the 8 MB cap (approved by Yasin). The marina (5), streetside batch (14), boats (4), promenade (3) and waterfront small props (11) share that page, so they add 0 MB.
- 17 Nov 2026: indoor page I (colour 1024, normal 512, ORM 256 = 1.75 MB) is streamed only with interiors and is not counted in the 8 MB street-resident cap. Street pages A + B + C + grime + W stay at 7.583 MB of 8 MB. Indoor props ship near and collision tiers only (no mid or far).
- 19 Nov 2026: house page H (colour 1024, normal 512, ORM 256 = 1.75 MB) is streamed only with interiors and is not counted in the 8 MB street-resident cap. Street pages A + B + C + grime + W stay at 7.583 MB of 8 MB. The 70-piece house interior set (36 decor, 8 rugs, 26 furniture) ships near and collision tiers only (no mid or far).
- 29 buildings were re-exported so every rail end meets a wall (flange or return) or a grounded post. Mid and far tiers were unchanged.

Licences and sources: `CREDITS.md` (building and ground atlases) and `CREDITS_props.md` (props and foliage). All texture sources are CC0, and all geometry and bakes were made from scratch.
