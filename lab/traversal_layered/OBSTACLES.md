# Coronado city kit: what a walking / climbing player really meets (survey, 25 Nov 2026)

**What was measured.** All 1,193 hand-made pieces in `map_dc/coronado/city_kit/pieces/*.scn`. 1,159 of them are placed
in `city_grid_layout.json` (1,214 layout rows). Also the kit meshes in `assets/coronado_kit/` (854 `*_col.glb` collision
meshes and their `*_near.glb` meshes), the kit `SPEC.md` / `README.md`, the city-kit plans, the door contracts
(`interiors/room_contracts*.json`) and the terrain heightmaps (`map_dc/coronado/terrain/data*/height.f32z`).

**How.**
1. The pieces are binary `.scn`. They were loaded read-only in a throw-away Godot 4.7.2 project under `/tmp` (a copy of
   the four allowed folders, with 4x4 stand-in textures). Every `CollisionShape3D` was dumped in the piece frame:
   - `ground_col` (the walkable ground: roads, walks, kerbs, terraces);
   - `Buildings/<name>/col`;
   - `Props/PropCol` (one convex hull or trimesh per prop instance);
   - the MultiMesh instance counts per prop type.
2. Python then measured those collision faces directly:
   - **Ground steps:** every vertical face of `ground_col`, sampled every 0.25 m. For each sample, the walkable height was
     read 8 cm in front of the face and 8 cm behind it. A "step" is the difference between the two. Piece-border skirts,
     with no ground on one side, were thrown out.
   - **Stairs:** found by walking uphill from each 5-30 cm riser in 2 cm steps.
   - **Slopes:** the angle of every walkable triangle, weighted by area.
   - **Building and prop collision:** the boxes in the building collision, split into connected parts.
   - **Seats, lids and decks:** the heights of upward faces on the visual meshes.

**Counting.** "Count" means instances in the piece files. Most pieces are used once, so the counts in the layout are
nearly the same; where they differ, both are given. Lengths are metres of edge. Everything is collision unless it says
"visual". **(est.)** marks an estimate or an inference.

---

## 1. Kerbs and small lips (ground collision)

| Item | Height | Width / depth | Count | Where |
|---|---|---|---|---|
| Street kerb | **0.15 m** (all kerbs, all street families) | vertical face; walk 1.5-6 m wide behind it | **60.2 km** of kerb face (65.0 km counted in the layout) in 486 pieces | all `s_*`, `j_*` street and junction pieces (`s_rg` 19.1 km, `s_rs` 16.8 km, `s_am`, `s_br`, `s_ar`, `j_rg` ...), `n_ferry_landing` (0.93 km) |
| Kerb on a slope / terrace kerb | 0.16-0.19 m | vertical face | 5.3 km | mostly `r_q_*` lot edges, `n_wf_*`, `n_hs_*` |
| Walk-to-verge lip | 0.04 m (walk at 0.15, land / grass strip at 0.11) | long edge | 5.2 km in 240 pieces (3.0 km in `s_rg_*`) | outer edge of the walk on `s_rg_*` and other blocks |
| Tiny seams | 0.02-0.03 m | long edges | 4.9 km in 315 pieces | `n_w_*`, `r_q_*`, `n_hs_*`, `n_fn_strip` |
| Low steps / terrace edges | 0.05-0.09 m | | 9.4 km | `r_q_*` (4.1 km), `n_w_*`, `n_hs_*`, `n_cc_*` (stepped plazas: 6-10 cm terraces in `n_cc_b3_main`) |
| Low steps / terrace edges | 0.10-0.14 m | | 8.7 km | `r_q_*` lot terraces (5.0 km), `n_hs_*`, `n_w_*`, `n_cc_*` |
| Kerb ramp (kerb cut) | from 0.15 down to about 0 | about 1.1-1.4 m long; surface tilted 4-8 deg (sampled in `j_am_11th`) | design rule: two directional ramps per corner (PILOT_DESIGN.md); not counted | junction corners `j_*` |
| Storm-drain kerb inlet (prop) | 0.18 m | 2.43 x 0.81 m | 543 | `s_*`, `j_*` at kerbs |
| Wheel stop (prop) | 0.10 m | 1.83 x 0.15 m | 4,633 concrete + 443 rubber | car parks: `n_hs_*`, `m_*`, `i_*`, strip pieces |
| Manhole cover / grate | 0.01 m (flush) | 1.16 m dia. | 459 / 99 | lanes |

## 2. Steps and stairs

**Single steps on buildings.** These are collision boxes, one box per step run (SPEC.md section 1).

| Item | Riser(s) | Tread / size | Count | Where |
|---|---|---|---|---|
| House front step, then porch | ground -> **0.20** -> **0.50** (risers 0.20 + 0.30) | step box 0.62 deep x 1.1-1.7 m wide; porch 1.05-1.8 x 1.3-5.6 m | 907 buildings | houses: `narrow_2sty_*`, `narrow_cottage_*`, `ranch_porch`, `cape_*`, `colonial_*` ... (kit `buildings/houses/*/house_*_col.glb`) |
| Three-step entry | 0 -> 0.10 -> 0.20 -> 0.50 (0.10 / 0.10 / 0.30) | step boxes 0.61 x 1.19 m | 171 buildings | houses (kit house variants) |
| Low entry | 0 -> 0.09 -> 0.30 (0.09 / 0.21) | step 0.32 deep x 1.1-2.8 m | 210 buildings | shops, civic, apartments (`civ_post_office`, `com_*`, `apt_*`), e.g. `b_se` |
| Single stoop | 0 -> 0.30 | 1.05-1.45 x 1.3-2.4 m | 226 buildings | apartments, shops |
| Loading-dock style block | 0 -> 0.55 -> 1.10 | dock 2.05-2.25 x 2.4-2.6 m (kit `mod_urb_wh_dock_12m`: 12 x 2.4 m at 1.1, step 1.8 x 1.5 m at 0.55) | 17 buildings | `contractor_shed`, `brewhouse`, `dollar_plus_market`, `coastline_paving` (`g_*`, `i_*`, `m_*`) |
| All building step boxes | tops 0.09 / 0.10 / 0.20 | | 2,285 boxes on 1,296 buildings | |
| All porch / stoop boxes | tops 0.30 / 0.50 | | 2,769 boxes on 1,569 buildings (2,884 buildings in all) | |

**Stairs in the ground** (detected flights of 2 or more risers with a 0.28-0.40 m tread)

| Item | Riser | Tread | Pitch | Steps | Width | Count | Where |
|---|---|---|---|---|---|---|---|
| Front-walk stairs up to a terraced lot | 0.09-0.18 (mode 0.14-0.16) | **0.30** | 17-31 deg | 2 (63), 3 (39), 4 (32), 5 (12), 6 (6), 9 (1) | 1.25-6.25 m (often 1.25 / 2.5 / 3.75) | **153 flights** in 70 pieces | `r_q_*` (131), `n_hs_*` (e.g. `n_hs_b6_hill` 0.15-0.18 / 0.30, up to 6 steps), `n_un_*` (0.15 / 0.35-0.36), `n_fn_*`, `r_s` |
| Long-tread garden / promenade steps | 0.13-0.17 (mostly 0.16-0.167) | **0.40-0.95** (0.50-0.86 typical) | 9-21 deg | 2-11 | 2-11.5 m (mostly 4 m) | 19 flights | waterfront `n_wf_b1*`, `n_wf_b2*` (e.g. `n_wf_b2m`: 11 x 0.164 / 0.50; 6 x 0.167 / 0.86) |
| Stepped plaza | 0.06-0.10 | metres apart | | many | | about 10 edges | `n_cc_b3_main` (0.15 -> 0.86 in 9 small terraces) |
| Dingbat outdoor stair, **visual** | 0.18 | 0.28 | 32.7 deg | 16 risers to a 2.88 m landing | 0.85 m | 16 | `prop_dingbat_stair` (`props/streetside/residential/`), e.g. `g_ne` |
| Dingbat stair, **collision** | **none:** one solid box 4.2 x 3.83 x 0.95 m (plus 2.68 m posts) | | | | | 16 | cannot be climbed as stairs |
| Quay stair, **visual** | 0.169 | 0.30 | 29 deg | 7 risers, landing at 1.65 m, top at 3.0 m | 1.2 m | 3 | `prop_quay_stair` (`props/waterfront/quay/`) |
| Quay stair, **collision** | **none:** a 3.0 m solid block 6 x 1.75 m plus a thin plate | | | | | 3 | `n_wf_*` |

There are also 8 cases of two vertical faces 0.1-0.2 m apart along the Amber frontages (`n_hs_b2..b6_amber`,
`n_cc_b4_e`). In effect each is one 0.3-0.5 m edge, not a stair **(est.)**.

## 3. Ramps and slopes

| Item | Angle | Area / length | Where |
|---|---|---|---|
| Street grades | at most 8 % = **4.6 deg** (STREETS.md / ROADKIT_SPEC.md); smoothstep profiles | 99.0 % of all walkable piece ground is 5 deg or less (75 % under 1 deg) | hill streets `s_rs_*`, `s_10th_e` (the pilot hill: +5.9 m over 110 m) |
| Kerb ramps | **4-8 deg** (measured; 0.15 m over about 1.1-1.4 m) | about 2 per corner | `j_*` |
| Gentle banks, fill land | 5-10 deg | 56,000 m2 (5-8 deg: 51,000 m2) | `fl_m9_*` (22,000 m2 at 6-8 deg), `n_eb_*`, `fl_m4/m5/m8` |
| Steeper banks | 10-15 deg | 6,250 m2 | `fl_m8_*`, `fl_m9_*`, `n_fw_*`, `n_cc_*`, `n_ferry_landing` |
| Steep banks / boat ramp | 15-25 deg | 1,760 m2 | `n_ferry_landing` (630 m2), `n_fw_*`, `n_cc_*` |
| Very steep (riprap, embankment) | 25-90 deg | 625 m2 | `fl_m9_*`, `g_v3_*` |
| Riprap props (boulders / piles / slopes) | uneven rock | 1,439 / 789 / 397 | bay edge `fl_*`, `n_wf_*` |
| Terrain heightmap (4 m grid, the whole map incl. San Diego hills, not only the city) | land cells: 87.5 % under 2 deg, 94 % under 5, 96 % under 10, 97 % under 15, 98.7 % under 25 deg; max 80 deg | 1.04 M cells | `terrain/data_citykit/height.f32z` |
| Banks where the land meets lowered land (JOB_BOARD 19 Nov, not re-measured) | 600 spots over 0.5 m, 153 over 1 m, largest 3.91 m | | terrain |

## 4. Walls, fences, railings, hedges

| Item | Height (collision) | Thickness / panel | Count (panels or posts) | Where (kit mesh) |
|---|---|---|---|---|
| CMU / stucco / graffiti / brick wall | **2.0** (kit col); the piece hulls measure **1.88** (visual near 2.18; panels seem placed about 0.94 scale, est.) | **0.32 m** (visual 0.38) | 2,063 stucco + 836 CMU + 172 graffiti + 18 brick = 3,089 panels (about 6 km) | `fences/fence_stucco_wall`, `fence_cmu_wall`, `fence_graffiti_cmu_panel`, `fence_brick_wall`; `n_hs_*`, `m_*`, `g_*`, `r_q_*` |
| Wood privacy fence | **1.80-1.84** | 0.12 (hull 0.16), 2 m panels; posts 0.12 sq x 1.84 | 21,147 panels, 31,336 posts | `fence_wood_privacy`, `fence_post_privacy`: back yards in `r_q_*` |
| Privacy gate | 1.80 | 1.0 x 0.12 | 870 | `fence_gate_privacy` |
| Chain-link | 1.52-1.53 (posts 1.59, 0.08 sq) | 0.06 | 2,122 panels | `fence_chainlink` |
| Chain-link, lot | 1.86 (posts 2.13, 0.10 sq) | 0.06 | 3,172 panels | `fence_chainlink_lot`: industrial yards |
| Rolling chain-link gate | 1.88 | 5.6 x 0.08 | 47 | `fence_gate_rolling_chainlink` |
| Weathered board | 1.50-1.55 | 0.10-0.12 | 5,227 | `fence_weathered_board`: gritty edge `g_*` |
| Wrought iron | **1.20-1.26** (posts 1.32, 0.08 sq) | 0.06-0.08 | 6,634 panels, 7,176 posts | `fence_wrought_iron`: parks, civic |
| Wrought-iron gate | 1.20-1.30 | 1.0 m | 138 | |
| Vinyl canal rail | **1.10-1.14** (posts 1.12, 0.15 sq) | 0.14-0.15 | 2,631 | `fence_vinyl_canal_rail` |
| White picket | **1.00-1.10** (posts 1.10, 0.10 sq) | 0.10-0.12 | 3,700 panels, 4,276 posts | `fence_picket_white`: front yards |
| Picket gate | 1.0-1.1 | 1.0 m | 155 | |
| Barbed-wire top | 0.16-0.25 (on top of fences) | 0.16-0.24 | 503 | `fence_barbed_wire` |
| Temporary fence panel | 1.83 | 3.0 x 0.22 | 186 | `props/construction/fence_temp_fence_panel*` |
| Promenade rail | **1.08** | 0.17, 4 m / 2 m | 90 + 19 | `props/waterfront/promenade/prop_prom_rail*`: `n_wf_*` |
| Porch railing (building collision) | **1.0** on a 0.5 m porch (1.5 above the ground) | **0.08** | 2,004 rail boxes | houses |
| Balcony railing | 1.0, base 3.4 m | 0.08 | 465 | apartments |
| Low wall beside a walk-up stoop | 1.2 | 0.20 x 1.14 | 42 | `walkup_*`, `law_flats`, `apts_b0` (n_apt / n_cc) |
| Low boxwood hedge | **0.90** | 0.60 (visual 0.70) | 1,656 | `foliage/hedge_boxwood_low_2m` |
| Privet hedge | **1.50** | 0.80 (visual 0.95) | 605 | `foliage/hedge_privet_2m` |
| Bougainvillea on a wall | 2.8 | 0.5 | 128 | `foliage/plant_bougainvillea_wall` |
| K-rail (jersey barrier) | **0.82** | 0.60 base, about 0.2 top (est.) | 64 | `props/construction/prop_k_rail` |
| Water barrier | 0.98 | 1.8 x 0.6 | 39 orange + 20 white | |
| Retaining faces between lot terraces (ground) | 0.30-0.49 m: 11.1 km; 0.50-0.99: 8.5 km; 1.00-1.49: 1.7 km; 1.50-1.99: 0.64 km; 2.0-3.3: 0.15 km | vertical faces (no wall-top thickness in the ground) | see section 8 | `r_q_*`, `r_n` / `r_s` (6 terraces of exactly 0.36 / 0.68 / 0.97 / 1.02 / 1.17 / 1.18 m, 42 m each), `n_wf_*`, `n_cc_*`, `n_hs_*` |

## 5. Street furniture (collision = what blocks; seat or top = visual upward face)

| Item | Collision h x w x d | Seat / top (visual) | Count | Kit mesh |
|---|---|---|---|---|
| Park bench | 0.90 x 1.86 x 0.62 (one box, back included) | seat **0.47-0.48** | 939 | `props/park/prop_park_bench` |
| Bus-stop bench | 0.95 x 1.95 x 0.60 | seat **0.46** | 129 | `props/street/prop_bench_bus_stop` |
| Picnic table | 0.79 x 1.83 x 1.60 (solid) | seat 0.48-0.52, top 0.79 | 407 | `prop_picnic_table` |
| Patio set (table + 4 chairs) | 0.73 table + 0.92 chairs | seat 0.47, top 0.73 | 586 | `prop_patio_set_4` |
| Adirondack chair | 1.00 x 0.88 x 0.90 | seat 0.30-0.38 sloped, arms 0.58 | 1,223 (white + wood) | |
| Cafe chair / table | | seat 0.51 / top 0.75 | 48 / 38 | |
| Bollard, steel | 1.06 x 0.22 | | 221 | `props/street/prop_bollard_steel` |
| Bollard, concrete | 0.88 x 0.32 | top 0.87 | 102 | `prop_bollard_concrete` |
| Bollard, iron | 0.95 x 0.24 | | 76 | `prop_bollard_iron` |
| Trash receptacle / recycling | 1.10 x 0.62 x 0.62 | lid 1.09 | 504 / 73 | `prop_trash_receptacle`, `prop_recycling_receptacle` |
| Wheelie trash cart | 1.04 x 0.66 x 0.84 | lid 1.03 | 2,232 (black 1,068 / green 851 / blue 313) | `prop_trash_cart_*` |
| Potted plant, succulent | 0.46 x 0.53 x 0.50 | pot rim 0.22 | 866 | `foliage/plant_potted_succulent` |
| Potted plant, leafy | about 1.0 x 1.4 x 1.1 | pot rim 0.40 | 296 | `plant_potted_leafy` |
| Planter at 0.6 m | **not found** (no raised planter box in the kit or the ground) | | 0 | |
| Hydrant | 0.86 x 0.34 | | 344 | `prop_hydrant_red` |
| Newspaper box | 1.10 x 0.50 x 0.46 | top 1.05-1.08 | 229 | |
| USPS box | 1.26 x 0.53 x 0.48 | top 1.25 | 50 | |
| Drinking fountain | 0.96 x 0.52 | basin 0.91 | 144 | |
| Bike rack | 1.00 x 2.50 x 0.12 | | 360 | |
| Parking meter / pay station | 1.50 x 0.20 / 1.63 x 0.45 | | 95 / 59 | |
| AC condenser | 0.87 x 0.92 x 0.92 | top 0.80-0.86 | 1,665 (+523 compact) | |
| Dumpster 3 yd | 1.66 x 2.00 x 1.30 | lid **1.60-1.66** | 336 | `props/city/prop_dumpster_3yd_*` |
| Roll-off dumpster 20 yd | 1.60 x 2.55 x 6.90 | rim 1.59-1.67 | 49 | |
| Shipping container 20 ft | **2.59** x 2.44 x 6.06 | roof 2.59 | 342 | `prop_container_20ft_*` |
| Transformer substation | 2.69 x 3.40 x 2.80 | plinth 0.20, top 1.9-1.97 | 28 | |
| Bus shelter | solid box 2.5 x 4.0 x 1.6 (you cannot walk in) + 0.12 roof slab at 2.5 | bench 0.49, roof 2.62 | 43 | `prop_bus_shelter` |
| Utility pole / cobra lamp / Victorian lamp | 12.0 x 0.34 / 8.6 x 0.60 / 4.42 x 0.46 | | 464 / 769 / 565 | |
| Shopping cart | 1.08 x 1.18 x 0.54 | | 71 | |
| Traffic cone 28 in / channelizer drum | 0.71 / 1.06 | | 221 / 118 | |
| Skate funbox / quarter pipe / bowl / grind rail | 0.55 / 1.50 / 1.80 / 0.39 | deck 0.55; rail 0.38 | 4 / 8 / 5 / 6 | `props/city/prop_skate_*` |
| Play structure / slide / swing set | 3.15 / 2.12 / 2.45 | deck 1.26; slide top 1.59 | 50 / 43 / 224 | |
| Bandstand | 7.2 x 10.1 (one solid hull) | floor 0.90 | 7 | `prop_bandstand` |
| Lifeguard tower | 4.25 | deck 2.0 | 18 | |
| Dock box | 0.62 x 1.56 x 0.70 | lid 0.62 | 13 | waterfront |
| Ice chest / soda vending | 1.27 / 1.83 | top 1.24 / 1.83 | 24 / 19 | |

## 6. Vehicles

| Item | Height | Size | Count | Where |
|---|---|---|---|---|
| Cars and vans | **not in any piece.** Parked and moving cars come from the traffic code (outside this survey); streets_report.txt lists 3,010 kerb stalls and 1,514 car-park stalls | | 0 in the pieces | `traffic/streets_report.txt` |
| Golf cart (blue / white) | collision one solid box **1.80** x 1.24 x 2.46; visual floor 0.30, seat 0.68-0.75, roof **1.78-1.80** | | 9 + 6 | `props/city/prop_golf_cart_*`, `n_hs_*` |
| Boat on trailer | collision 7 boxes up to 1.6; visual deck 0.76, top 1.10 | 2.3 x 6.2 | 142 | `props/waterfront/small/prop_boat_trailer` |
| Passenger ferry | | | 1 | `vehicles/ferry`, `n_ferry_landing` |

## 7. Ledges and drops (raised floors you can step off)

| Item | Drop | Size | Count | Where |
|---|---|---|---|---|
| House porch edge | **0.50** | 1.05-1.8 x 1.3-5.6 m; railing 1.0 high on part of the edge | about 1,450 porch boxes | houses |
| Stoop / low porch | **0.30** | 1.05-2.4 m | about 1,290 | shops, apartments, civic |
| Loading dock | **1.10** | 2.05-2.6 x 2.4 m (kit dock 12 x 2.4 m) | 17 | industrial / gritty |
| Raised plaza / courthouse plinth | 1.2 | 12 x 4.25 m | 1 | `n_cc_b1_court` |
| Lot-terrace drops (ground) | 0.3-0.5: 11.1 km; 0.5-1.0: 8.5 km; 1.0-1.5: 1.7 km; 1.5-2.0: 0.64 km; 2.0-3.3: 0.15 km | | | `r_q_*` (most), `n_wf_*`, `n_cc_*`, `n_hs_*`, `r_n`, `r_s` |
| Waterfront terraces / seawall tiers | 1.0, 1.2, 1.4, 1.6, 1.8, 1.9, 2.0 m (round values), deepest **3.2 m** | | 0.1-0.2 km each | `n_wf_b2e`, `n_wf_b2m`, `n_wf_b2w`, `n_wf_b1*` |
| Quay edge | 3.0 m to the quay foot (sea level not collision) | 6 x 1.75 m modules | 39 + 11 + 3 + 3 | `prop_quay_straight*`, `prop_quay_stair`, `prop_quay_corner_out` |
| Pier deck | top 3.0 (deck slab 2.64-3.0), piles 0.34 sq, 2.34 high | 4 x 6 m modules | 8 + 2 | `prop_pier_straight`, `prop_pier_thead` |
| Marina float | top 0.71-0.75 | 6 x 2.66 m | 14 | `prop_marina_float` |
| Boardwalk | 0.32 | 4 x 3 m | 56 | `prop_prom_boardwalk` |
| Dingbat stair landing (visual only, collision is a box to 3.83 m) | 2.88 | 1.25 x 0.97 m | 16 | |
| Lifeguard tower deck / play deck / bandstand floor | 2.0 / 1.26 / 0.90 | | 18 / 50 / 7 | |
| Edges BETWEEN pieces (not measured here) | JOB_BOARD 19 Nov: of the 5,072 m of residential edge shared between blocks, 3,123 m jump more than 0.20 m (usually 0.66 m, at most 2.86 m); 6-12 % of the residential edge against the streets steps about 0.27 m | | | joins between `r_q_*` blocks |

## 8. Narrow surfaces (wall tops, rails)

| Item | Top width | Height | Count | Where |
|---|---|---|---|---|
| Masonry wall top | **0.32** (col) | 1.88-2.0 | 3,089 panels | `fence_*_wall` |
| K-rail top | about 0.2 **(est.** from the 0.76 m2 top face / 3.8 m) | 0.82 | 64 | |
| Promenade rail | 0.17 | 1.08 | 109 | `n_wf_*` |
| Vinyl canal rail | 0.14-0.15 | 1.10 | 2,631 | |
| Privacy fence top | 0.12 | 1.80 | 21,147 | |
| Porch and balcony rails | **0.08** | 1.0 above the deck | 2,501 | buildings |
| Wheel stop | 0.15 | 0.10 | 5,076 | car parks |
| Skate grind rail | 0.42 (box) | 0.39 | 6 | |
| Narrow raised strips in the ground (top under 1.2 m wide, drop of 0.3 m or more) | 0.4-0.75 | 0.3-0.6 | only 24 m in all (`n_hs_b6_garden`, `n_fn_*`, `n_un_*`) | essentially none: retaining edges have the terrace behind them |

## 9. Doors and doorways (`interiors/room_contracts*.json`: measured from the atlas regions of 139 models; ground floor)

| Item | Width | Height | Sill | Count | Notes |
|---|---|---|---|---|---|
| Apartment / house-type door (`O_apt_door`) | **0.9-1.0** | **2.2** | 0.30 (119) or 0 (86) | 215 in 85 models | single leaf |
| Shop door (`O_shopdoor`) | 1.0-2.4 (median 1.6) | region 2.1-3.0 (median 3.0 incl. transom); leaf about 2.1 (PLAN.md) | 0 (68), 0.5 (20), 0.3 (8), 0.2 (4) | 101 in 67 models | |
| Civic door | 1.4-2.4 (median 1.8) | 2.15-2.8 | 0.30 mostly | 24 in 22 models | |
| Patio door | 1.6-2.4 | 2.2 | 0.3 / 0 | 12 | |
| Roll-up door | 1.0-6.0 (median 3.0) | 2.1-5.0 (median 3.2) | 0 (41), 0.5 (15: dock height) | 56 in 35 models | |
| House doors (house atlas) | not measured; SPEC says doors are 2.0-2.2 m high | | on the 0.5 m porch | about 1,400 | `traffic/places_report.txt`: 1,402 home doors, 31 shop doors reachable from a walk |
| How they open | Kit doors are **painted on closed shells** (building collision is closed). Only the **33 enterable rooms** (`assignment_all.json`) get a cut doorway with **double-acting hinged leaves that swing away from the player** within about 2 m (a pair over 1.3 m). Handles are not modelled (painted), so handle height is unknown. | | | | interiors/PLAN.md |

## 10. Low ceilings and overhangs

| Item | Clear height | Notes |
|---|---|---|
| Awnings, canopies, porch roofs, entablatures | no collision (SPEC.md) | you walk through them; their visual height was not measured |
| Bus shelter | roof 2.5-2.62 | but the shelter body collides as a solid 2.5 m box |
| Under the pier deck | 2.34 (piles) to 2.64 (deck underside) | over the beach / water |
| Picnic table | 0.79 top | the collision is solid down to the ground, so you cannot crawl under it |
| Interiors (room floors) | 2.4-8.1, median 2.7 (95 floors); also 2.9 / 3.2 / 3.7 | room_contracts `clear_h` |
| A 1.25 m crawl ceiling | **none found** outdoors | |

## 11. Gaps

| Item | Gap | Count | Where |
|---|---|---|---|
| Between buildings (wall-to-wall in collision, same piece) | 0.0-0.2 m | 117 pairs | blocks with touching or near-touching facades: `b_ne`, `i_vb_*` lock-ups, `a_sw` garages |
| | 0.3-0.5 m | 88 pairs | `a_sw` garages, `g_v2_*`, `b_nw` (`com_bakery`/`com_orange_row`), `b_sw` |
| | 0.6-0.9 m | 62 pairs | `g_v2_*` walk-ups, `a_ne`, `n_cc_b3_arm` |
| | 1.0-3.0 m | about 780 pairs | side passages between shops, apartments, industrial sheds |
| Between houses | over 3 m (15 m lots, PILOT_DESIGN.md) | | `r_q_*`, `r_n`, `r_s` |
| Jump gaps (edge to edge over a drop) | none in the ground collision **(est.)**. Over water: piers, marina floats and quay are separate props, and the gaps between them were not measured | | `n_wf_*`, `f_*` |

---

## Compared to the brief's course list

| Brief value | In the city? | Real value / note |
|---|---|---|
| Kerb 10 cm | no kerb; yes as a terrace step (8.7 km of 10-14 cm edges) | |
| Kerb 12 cm | as a terrace step only | |
| **Kerb 15 cm** | **YES, the only kerb height: 60 km** | 0.15 m everywhere, also on slopes |
| Kerb 16 cm | rare (5.3 km of 16-19 cm edges, slope / terrace kerbs) | |
| Step 20 cm | **yes** | house step box 0.20 (about 1,450 runs); 0.21 riser on 0.09 -> 0.30 entries |
| Step 24 cm | rare | not a design value; 0.20-0.29 m edges are 10 km of terrace edges |
| Stair 17 / 28 | close, visual only | dingbat stair 18 / 28 (16 risers), but its collision is a solid box; quay stair 16.9 / 30, also solid |
| Stair 19 / 25 | **no** | |
| Real stairs (collision) | not in the list | **0.10-0.18 / 0.30** (2-6 steps, 153 flights) and waterfront **0.16 / 0.50-0.86** (up to 11 steps) |
| Ramp 5 deg | **yes** | kerb ramps 4-8 deg; street grades up to 4.6 deg (8 %) |
| Ramp 10 deg | yes, on banks | 56,000 m2 at 5-10 deg |
| Ramp 15 deg | yes, small | 6,250 m2 at 10-15 deg |
| Ramp 25 deg | rare | 1,760 m2 at 15-25 deg (boat ramp at the ferry landing, banks); 625 m2 steeper |
| Blocks 0.3-3.2 m | **yes, many** | 0.30 stoop, 0.50 porch, 0.55 / 1.10 dock, 0.62 dock box, 0.82 k-rail, 0.87 AC, 1.66 dumpster, 2.0 wall, 2.59 container, 2.69 substation, 3.0 quay |
| Fence 0.9 m | yes as a hedge | boxwood hedge 0.90 (1,656) |
| Fence 1.1 m | **yes** | picket 1.0-1.1 (3,700), vinyl rail 1.10-1.14 (2,631), promenade rail 1.08 |
| Fence 1.3 m | close | wrought iron 1.20-1.26, posts 1.32 (6,634) |
| Fences the list misses | | **privacy 1.80-1.84 (21,147, the most common)**, chain-link 1.52 / 1.86, board 1.50, masonry wall 1.88-2.0 |
| Car bonnet 0.85 / roof 1.45 | **not in the pieces** | cars come from the traffic code; nearest prop: golf cart (solid 1.80 box) |
| Van roof 1.9 | not in the pieces | golf cart roof 1.80, dumpster lid 1.66 |
| Bench 0.45 | **yes** | seat 0.46-0.48 (1,068 benches); but the collision box is 0.90-0.95 high (back included) |
| Planter 0.6 | **no** | pots 0.46 / about 1.0; dock box 0.62 |
| Drops 0.3-4.0 m | **yes, 0.3-3.3 m** | 22 km of terrace edges 0.3-3.3 m; porch 0.5; dock 1.1; quay 3.0; worst 3.2 (`n_wf_b2m`) |
| Wall top 60 cm | **no** | |
| Wall top 30 cm | **yes** | masonry walls 0.32 |
| Wall top 20 cm | about (est.) | k-rail top about 0.2; promenade rail 0.17; vinyl 0.15; privacy 0.12 |
| Pipe 10 cm | **yes** | rails 0.08 (2,501 porch / balcony rails), fence posts 0.08-0.15, bike rack 0.12 |
| Ceiling 1.25 m | **no** | lowest overhead is 2.34-2.64 under the pier; awnings have no collision |
| Cover wall 1.0 m | yes | picket 1.0, k-rail 0.82, barrier 0.98, hedge 0.9, porch rail 1.0 |
| Cover wall 2.0 m | **yes** | masonry walls 1.88-2.0 (3,089 panels), privacy fences 1.84 |
| Doors | yes | apartment 0.9-1.0 x 2.2; shop 1.0-2.4 x about 2.1; sills 0 / 0.3 / 0.5; openable only at the 33 rooms |
| Gap 0.6 m | yes | 88 building pairs 0.3-0.5 m apart, 62 pairs 0.6-0.9 m |

**What the city has that the list misses**
- **4 cm verge lips** (5.2 km) and **2-3 cm seams** (4.9 km): small trip edges for foot placement.
- **5-14 cm terrace steps** (18 km), mostly at the residential lots (`r_q_*`).
- Wheel stops (0.10 x 0.15 m, 5,076) and kerb inlets (0.18 m, 543).
- **Stairs with solid collision:** dingbat stair and quay stair. You see stairs but collide with a block.
- **Long-tread garden steps:** 0.16 / 0.5-0.86 m, up to 11 in a row.
- Retaining edges whose height **changes along their length** on the hill. Lot terraces step 0.1-2.5 m, and the step is
  different at every lot.
- Porch rails that stand **1.5 m above the street** (1.0 m on a 0.5 m porch). Gates in fences (privacy 870, picket 155,
  iron 138).
- Many thin posts: 31k privacy posts, 7k iron, 4k picket. Also porch columns 0.14-0.34 m square, 2.2-3.5 m high (3,002).
- Solid 'furniture' boxes: the bus shelter, picnic tables, the bandstand as one hull, golf carts.
- Riprap rock (2,600 pieces) and 15-25 deg banks / boat ramp at the ferry landing.
- Skate items: funbox 0.55, quarter pipe 1.5, bowl 1.8, grind rail 0.39.
- Playground decks at 1.26 m. Marina floats at 0.71-0.75 m. Boardwalk at 0.32 m.

## A short "real street" test stretch (pieces to copy)

All five pieces below are LOCKED pilot pieces. They sit together in one frame (layout pos [0,0,0], yaw 0 for all), so
loaded at the origin they form one continuous stretch around Amber Ave x 10th St. **Meshes and collision shapes are
embedded in the `.scn` files** (ArrayMesh, Concave / Convex shapes, MultiMesh props). The dependencies are only
materials, shaders and textures (from `ResourceLoader.get_dependencies`, recursive).

| Piece | What it gives | Depends on (besides itself) |
|---|---|---|
| `map_dc/coronado/city_kit/pieces/j_amber_10th.scn` | junction: 0.15 m kerbs, kerb ramps 4-8 deg, signal poles, hydrants, kerb inlets | materials `g_asphalt`, `g_concrete`, `g_curb`, `g_tactile`, `g_white`, `g_yellow`, `pw_props_b_color_clean_20`, `pw_props_b_color_clean_55`, `pw_props_color_clean_55`, `wear_decal` (.tres in `city_kit/materials/`); shaders `city_kit/shaders/prop_wear_fix.gdshader`, `wear_decal.gdshader`; textures `assets/coronado_kit/atlases/props_{color_clean,normal,orm,b_color_clean,b_normal,b_orm,grime}.png`, `assets/roads/{asphalt026c_color.jpg,concrete034_color.jpg,roadlines022a_white_worn.png,roadlines022a_yellow_worn.png}`, `map_dc/coronado/streets/street_wear/wear_atlas.png` (borrowed from the game) |
| `.../pieces/s_10th_e.scn` | residential hill street: kerb 0.15 on the 8 % grade (4.6 deg), parkway grass, cobra lamps, bike rack, bin, newspaper box | as above, plus `g_grass.tres`, `pw_props_c_color_clean_55.tres`, `atlases/props_c_{color_clean,normal,orm}.png`, `terrain/textures/grass004/grass_albedo.jpg` (no `g_tactile`, no `_20`) |
| `.../pieces/s_amber_s.scn` | downtown walk: kerb 0.15, bus shelter (solid), parking meters x20, bins, USPS box, Victorian lamps, bike rack | as `s_10th_e`, plus `pw_props_w_color_clean_55.tres`, `pw_props_w_color_clean_55_2s.tres`, `shaders/prop_wear_fix_2s.gdshader`, `atlases/props_w_{color_clean,normal,orm}.png` |
| `.../pieces/b_se.scn` | post office forecourt and shop row: entry steps 0.09 -> 0.30, stoops 0.30, **2 park benches (seat 0.47)**, bike rack, low boxwood hedge 0.9, potted plants, painted doors (`civ_post_office` civic door, `com_boutique_row` shop doors), dumpsters | `bw_bld_lod_color_65.tres`, `bw_city_color_65.tres`, `g_asphalt`, `g_paving`, `g_white`, `pw_props_b_color_clean_55`, `pw_props_color_clean_55`, `wear_decal`; shaders `bldg_wear`, `prop_wear_fix`, `wear_decal`; `assets/coronado_kit/textures/{city_color,city_normal,city_orm,city_emissive,bld_lod_color,far_color}.png`, `atlases/props_*` (A, B, grime), `atlases/trees_shrubs_{color,normal}.png`, `assets/roads/{asphalt026c_color.jpg,roadlines022a_white_worn.png}`, `terrain/textures/travertine009/albedo.jpg`, `wear_atlas.png` |
| `.../pieces/r_s.scn` | residential row: lot terraces with retaining faces 0.36 / 0.68 / 0.97 / 1.02 / 1.17 / 1.18 m, front-walk stair (2 x 0.14 / 0.30), porch steps 0.20 -> 0.50 with 1.0 rails (0.08), **114 privacy fence panels (1.84)**, picket and wrought-iron fences, trash carts, patio sets, house doors | `bw_bld_color_65.tres`, `g_concrete`, `g_grass`, `g_wall`, `pw_props_b_color_clean_55`, `pw_props_color_clean_55`, `pw_props_color_clean_55_2s`, `wear_decal`; shaders `bldg_wear`, `prop_wear_fix`, `prop_wear_fix_2s`, `wear_decal`; `textures/{bld_color,bld_normal,bld_orm,bld_emissive,far_color}.png`, `atlases/props_*` (A, B, grime), `atlases/trees_{broadleaf,shrubs}_{color,normal}.png`, `assets/roads/concrete034_color.jpg`, `terrain/textures/grass004/grass_albedo.jpg`, `wear_atlas.png` |
| optional `.../pieces/r_q_m400_0_sw.scn` | more stairs (5 x 0.14 / 0.30, 3 x 0.16 / 0.30) and terrace drops 0.35-0.94 m | adds `bw_bld_color_70/80`, `g_mulch`, `pw_props_color_clean_20/100`, `terrain/textures/ground037/dry_albedo.jpg` |
| optional `.../pieces/n_hs_b6_hill.scn` | stairs 0.15-0.18 / 0.30 up to 6 steps, 0.6-0.73 m terrace walls | adds `g_plaza`, `bw_city_color_65`, `travertine009/albedo.jpg` |

Copy notes:
- Keep the `res://` paths. Every `.tres` and `.gdshader` keeps its `.uid` sidecar, and `wear_atlas.png` must exist at
  `res://map_dc/coronado/streets/street_wear/wear_atlas.png`.
- The shaders use no global uniforms.
- The README warns that MultiMesh data is lost when a piece is *built* under `--headless`. Loading in a real renderer is
  fine. Under `--headless` the MultiMesh transforms read as zero, but the `PropCol` shapes keep the prop positions.

## What this survey cannot see (honest limits)

- **Cars, vans, buses, people.** They are spawned by the traffic / crowd code, not stored in pieces. Their sizes were
  not measured (out of scope).
- **The terrain under and between pieces, and the joins between pieces.** Steps along piece borders were thrown out on
  purpose (no ground on one side). The between-block jumps (up to 2.86 m) are quoted from JOB_BOARD, not measured.
  The terrain slope figures cover the whole 8.4 x 5.5 km heightmap, including San Diego hills, not only the city.
- **Collision vs visual.**
  - Numbers marked "visual" (seat heights, stair risers of props, lids) come from mesh faces. What the player collides
    with is often a bigger solid box: bench 0.90 high, dingbat / quay stairs solid, bus shelter solid, golf cart solid.
  - Prop collision in pieces is a convex hull per instance, so a hull also fills concave parts (under tables, between
    chair legs).
  - The masonry walls measure 1.88 m in the piece hulls against 2.0 m in the kit col. The scale is inferred, not read.
- **Classification is automatic.**
  - "Step", "terrace edge" and "kerb" are inferred from height and the surroundings. Lengths are sampled every 0.25 m,
    so short edges are rounded.
  - Stair detection needs a riser of 5-30 cm and a tread under 1.2 m. It missed nothing obvious in spot checks but was
    not checked by eye.
  - About 18 detected "flights" are artefacts (double faces 10 cm apart, or very long faces) and are left out of the
    stair counts.
- **Buildings.**
  - Porch, step and rail data come from building collision boxes. Doors come from atlas regions (house doors not covered).
  - Door leaf heights, handle heights and swing direction exist only for the 33 cut rooms (described in PLAN.md, not
    measured).
  - Awnings and canopies have no collision, and their visual clearance was not measured.
  - Interiors (rooms, counters, indoor stairs) were not surveyed beyond floor clear heights.
- **Counts are per piece file.** A few pieces are placed twice or not at all in `city_grid_layout.json`. Where it
  matters, layout-weighted figures are given. Props are counted from near-tier MultiMesh instance counts.
- **Gaps** were measured only building to building inside one piece. Fence-to-wall, prop-to-prop and over-water gaps were
  not measured.
- **Nothing was run in the game.** No physics or character test: these are geometry measurements only. Step-up limits,
  ledge grab and the like still need a test in an engine.
