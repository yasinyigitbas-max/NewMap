# Obstacles in the Coronado city kit: a measured survey (25 Nov 2026)

What a walking and climbing player really meets in the new map. Every number below comes from the map data in this
repo. Nothing was changed in the map.

## How it was measured (read this first)

- **The pieces.** `map_dc/coronado/city_kit/pieces/*.scn` (1,193 files, binary, zstd-compressed). They were
  decoded with a small Python reader (in `/tmp/claude-0/survey/`, not in the repo). 1,192 pieces were read. One
  piece, `t_ind_w600_n1400_sw.scn`, could not be decompressed and is not counted. `city_grid_layout.json` places 1,159
  of the pieces, almost every one exactly once, so "how many in the pieces" is about "how many in the city".
- **The ground.** Each piece has one collision mesh, `ground_col`. From it I took:
  (a) the slope of every walkable face, weighted by area;
  (b) every vertical face, and the ground height 0.25 m in front of it and 0.25 m behind it. The difference is the
  real height of that kerb, step or drop. A face with ground on one side only is a "skirt" at a piece border and is
  left out (about 68 km of skirt). Lengths are sums over triangles: read them as "about", not exact.
- **Buildings.** Each placed building carries `metadata/kit` (its kit name). Its collision boxes come from the piece.
  For stairs and stoops I also read the visible mesh (`*_near.glb` in `assets/coronado_kit/buildings/`) and listed
  every face that points up: that gives the real riser and tread.
- **Props.** Props are MultiMesh instances in the pieces. "How often" = number of near-tier instances. Sizes come
  from the mesh bounds (glTF accessors), the up-facing faces of the near mesh and the boxes of the `*_col.glb` mesh.
  Prop collision in the pieces (`Props/PropCol`) was also counted.
- **Doors.** From `stats.json` of the kit models (`openings`: width, sill, head) and from
  `interiors/room_contracts*.json` (ground-floor entrances).
- **Not measured.** Parked cars and vans: their meshes live in `vehicles/` (borrowed from the game, outside the
  allowed folders) and the cars are placed by the traffic system at run time, not by the pieces. See section 9.

**The most important finding for a locomotion lab: the collision is often simpler than the picture.** Stair runs,
benches, the bandstand and the skate ramps collide as plain boxes. Section 15 lists them.

---

## 1. Kerbs

| What | Height | Width / depth | How often | Where (pieces) |
|---|---|---|---|---|
| Street kerb (the normal one) | **0.15 m**, a vertical face | kerb face only; walk on top is flat | about **63 km** of kerb face in 484 pieces | every street family: `s_rg_*` (19 km), `s_rs_*` (17 km), `s_am_*`, `s_br_*`, `j_*`, `s_amber_*`, `s_apt`, `s_civ`, `s_grt`, `s_res_*`, ... |
| Bridge approach kerb | **0.16 m** | | about 1.9 km | `s_br_appr_1..6`, `s_br_ramp_1..5` |
| Kerb ramp (curb cut) at crossings | ramps from 0 to 0.15 m | main slope **5-6 deg** (about 1:10), side flares **7-9 deg** | at most junction corners | all `j_*` pieces (e.g. `j_amber_10th`, `j_ar_*`, `j_rs_*`) |
| Kerb on a sloped street | 0.15 m kerb on a street of up to **8 % (4.6 deg)** | | hill streets | `s_res_up/dn*`, `s_rs_*`, `s_ar_*` |

The design files agree: "kerb ... 0.15 m high" (`PILOT_DESIGN.md`). No 10 or 12 cm street kerb was found. Heights of
10-14 cm do exist, but they are pad edges, sills and wheel stops (sections 4 and 13).

## 2. Single steps and stoops

Visible risers are measured on the near mesh. "Collision" is what the player's capsule actually touches.

| What | Visible steps | Collision | How often | Example kit models |
|---|---|---|---|---|
| House stoop to porch | **3 risers of 0.167 m**, tread **0.30 m**, 1.1-1.7 m wide, deck at **0.50 m** | one **0.20 m** box (0.62 m deep), then the 0.50 m deck box (so the capsule meets 0.20 m, then 0.30 m) | **1,079** buildings (nearly every house) | `houses/ranch_porch`, `spanish_small`, `narrow_2sty_*`, `narrow_cottage_*`, `cape_*`, `craftsman_*`, `beach_*` |
| Apartment / civic / tower stoop | **2 risers of 0.15 m**, tread 0.30 m, landing at **0.30 m** | a **0.09 m** box (0.32 m deep, 1.1-5.8 m wide), then the 0.30 m landing box | **468** buildings | `apartments/apt_spanish_revival`, `apt_stucco3_*`, `apt_townhouse_*`, `civic/*`, `urban/twr_glass`, `twr_office` |
| Apartment walkway slab | one 0.30 m step up | 0.30 m box, 1.4 m x 10 m | 31 | `apartments/apt_dingbat_pink` / `_teal` |
| Front-door sill | (on modular walls) door sill 0.15-0.6 m above the ground | | | `modular` apartment doors (`apt_door`, sill 0.0-0.6 m) |

So in the city a single step is **15-18 cm**, never 20 or 24 cm. But the **collision** steps are 9, 20 and 30 cm.

## 3. Stairs

All treads are **0.30 m** (0.27 m on the dingbat stair). Risers are **0.15-0.18 m**.

| Stair | Risers x height | Total rise | Tread | Width | How often | Collision |
|---|---|---|---|---|---|---|
| Courthouse front | **7 x 0.171 m** | 1.20 m (plinth) | 0.30 m | 11.8 m | 1 (`urban/urb_courthouse`) | 0.62 m box + 1.20 m box |
| Museum front | **5 x 0.16 m** | 0.80 m | 0.30 m | 16.4 m | 2 (`public/pub_museum`) | 0.38 m box + 0.80 m box |
| University front | **4 x 0.15 m** | 0.60 m | 0.30 m | 8.8 m | 2 (`public/pub_university`) | 0.27 m box + 0.60 m box |
| Loading-dock stair | **6 x 0.183 m** | 1.10 m (dock) | 0.30 m | 2.2 m | 17 (`industrial/ind_warehouse` 13, `ind_factory` 4) | **0.55 m box** + 1.10 m dock box |
| Hotel Bel terrace | 3 x 0.167 m | 0.50 m | 0.30 m | 1.8 m | 1 (`landmarks/lmk_hotel_bel`) | box |
| Bandstand | 5 x 0.18 m | 0.90 m deck | 0.30 m | | 7 (`prop_bandstand`) | **the whole bandstand is one solid 7.2 m block** |
| Dingbat outside stair (prop) | **16 x 0.18 m** | 2.88 m landing | **0.27 m** | 0.95 m | 16 (`prop_dingbat_stair`: `a_*`, `f_nw`, `g_ne`, ...) | coarse blocks: tops at 0.36, 1.08, 1.80, 2.52 m, then 2.88 m (steps of **0.72 m**) |
| Quay stair to the water | **8 x 0.17 m** | 1.35 m | 0.30 m | 1.2 m | 3 (`prop_quay_stair`: `f_se`, `n_ferry_landing`) | real 0.17 m steps (the only stair whose collision has every step) |

## 4. Ramps and slopes

Area of walkable ground (all `ground_col`, 6.8 km2) by slope:

| Slope | Area | What it is |
|---|---|---|
| 0-2 deg | 5.89 km2 (86 %) | flat streets, walks, pads |
| 2-5 deg | 0.79 km2 (12 %) | hill streets (the steepest traffic lane is **8.0 % = 4.6 deg**, `traffic/streets_report.txt`), sloped yards |
| 5-6 deg | 16,000 m2 | kerb ramps, driveways |
| 6-10 deg | 40,000 m2 | kerb-ramp flares, some street legs (`fl_m*`, `n_eb_*`, `n_fe_*`) |
| 10-15 deg | 6,300 m2 | banks on fill land (`fl_*`, `n_fw_*`, `n_cc_*`) |
| 15-25 deg | 1,760 m2 | banks: `fl_m9_1`, `n_fw_crest`, `n_fw_slope`, `n_ferry_landing` (shore) |
| 25-45 deg | 240 m2 | small bank spots: `fl_m9_1`, `fl_3_1`, `g_v3_g4sw` |
| 45-60 deg | 290 m2 | tiny bank spots: `fl_m9_1`, `g_v3_j5se`, `n_cc_b6`, `n_eb_ne` |

- Open land outside the pieces (terrain grid, `zoning/terrain_grid.npz`, 4 m cells): 88 % under 2 deg, steepest
  cell 27.6 deg. A 4 m grid smooths small banks, so this is a lower bound.
- Gangway to the floating dock (`prop_gangway`, 11 m long): **about 5.5 deg** (rise 1.05 m). 3 pieces.
- No built wheelchair ramps were found on buildings. Ramps of 10, 15 or 25 deg exist only as grass banks.

## 5. Ledges and drops

Drops measured on `ground_col` (vertical faces with walkable ground on both sides):

| Drop height | Length (about) | Pieces | What it is |
|---|---|---|---|
| under 5 cm | 33 km | 297 | seams, small pad joints |
| 5-14 cm | 32 km | 379 | yard pads against the walk, tree wells, pad seams (mostly `r_q_*`, `n_hs_*`, `n_w_*`) |
| **15 cm** | **63 km** | 484 | kerbs (section 1) |
| 17-30 cm | 25 km | 122 | edges of lots on a slope |
| 30-60 cm | 26 km | 110 | lot pads and terraces on the hill (`r_q_*`, `n_hs_*`, `n_cc_*`, `n_wf_*`) |
| 0.6-1.0 m | 10 km | 70 | terraces (`r_q_*` 7 km, `n_hs_*`, `n_wf_*`, `r_n`, `r_s`) |
| 1.0-2.0 m | 3.9 km | 41 | terraces and retaining edges (`r_n`/`r_s` 1.0 and 1.2 m, `n_wf_b2*` up to 2.0 m, `n_fw_slope`) |
| 2.0-3.2 m | 0.2 km | 10 | the highest: `n_wf_b2m` (3.2 m), `r_q_0_m1400_se`, `r_q_m600_0_sw` |

Important: on a hill a lot pad is flat and the walk is sloped. So the **edge height changes along its length**
(e.g. from 0 to 0.9 m over 30 m). Most drops of 0.17-1.0 m are like that. The ground mesh cannot tell whether a wall
or fence stands on the edge.

Built ledges (from building collision and props):

| Ledge | Height | Size | How often |
|---|---|---|---|
| Apartment / civic stoop landing | 0.30 m | 1.3-2.4 m x 1.05-1.85 m | 468 buildings |
| House porch deck | **0.50 m** | 1.6-10.3 m wide x 1.05-2.4 m deep, rails 1.0 m high on some sides | 1,079 buildings |
| Museum plinth | 0.80 m | 16.6 x 3.25 m | 2 |
| University plinth | 0.60 m | 9.0 x 3.45 m | 2 |
| Loading dock | **1.10 m** | 2.4-2.6 m x 2.05-2.25 m | 17 |
| Courthouse plinth | **1.20 m** | 12.0 x 4.25 m | 1 |
| Play structure deck | 1.25-1.26 m | small deck, about 0.55 x 1.9 m collision | 50 |
| Lifeguard tower deck | 2.0 m (its access ramp collides as a 2.0 m block) | about 2.3 x 2.3 m | 18 |
| Dingbat stair landing | 2.88 m | 1.25 x 0.95 m | 16 |
| Quay edge to floating dock | **1.05 m** (quay top 0.15 m, float top -0.90 m in `s_wf`; same in `n_ferry_landing`) | | `s_wf`, `f_se`, `n_ferry_landing` |
| Quay edge to the sea | about 1.5 m (from the design note "walk 1.5 m above the sea", `STREETS.md`; not measured) | | waterfront |
| Pier deck | 3.0 m above the pier's base, deck flush with the walk | 4.2 x 6 m sections | 8 |
| Promenade boardwalk | 0.32 m | 4 x 3 m sections | 56 (`f_sw`, `n_ea_cape`, `n_ea_shore`) |

## 6. Walls, fences and railings

Lengths = number of near instances x panel length. Collision boxes come from the pieces (`PropCol`).

| Kind | Visible height | Thickness | Collision box (h x thick) | How many | Length (about) | Example pieces |
|---|---|---|---|---|---|---|
| Wood privacy fence | **1.84 m** | 0.12 m | 1.84 x 0.16 | 21,147 panels + 31,336 posts (0.12 x 1.84) | **42 km** | 85 pieces, e.g. `a_ne`, `r_q_*`, `n_w_*` |
| Wrought iron fence | 1.26 m (posts 1.32) | 0.06 m | 1.24 x 0.13 | 6,634 | 13 km | 78, e.g. `a_ne` |
| Weathered board fence | 1.55 m | 0.10 m | 1.52 x 0.16 | 5,227 | 10.5 km | 33 |
| White picket fence | **1.10 m** | 0.10 m | 1.05 x 0.16 (kit col 1.0) | 3,700 | 7.4 km | 49 |
| Chain-link, lot | 1.86 m (posts 2.11) | 0.03 m | 1.90 x 0.10 | 3,172 | 6.3 km | 38 |
| Vinyl canal rail | 1.12 m (rails at 0.17, 0.59, 1.05) | 0.15 m | 1.14 x 0.16 | 2,631 | 5.3 km | 20 |
| Chain-link, yard | 1.52 m (posts 1.59) | 0.03 m | 1.56 x 0.10 | 2,122 | 4.2 km | 31 |
| Barbed wire (on top of chain-link) | 0.16 m strand set | | | 503 | 1 km | 9 |
| Stucco wall | **2.18 m** at the top, cap at 1.86 m | **0.38 m** (cap about 0.25 m) | **2.0 x 0.32** | 2,063 | 4.2 km | 29 |
| CMU block wall (+ graffiti CMU) | 2.18 m | 0.38 m | 2.0 x 0.32 | 836 + 172 | 2 km | 43 + 32 |
| Brick wall | 2.18 m | 0.38 m | 2.0 x 0.32 | 18 | 36 m | 1 |
| Low boxwood hedge | **0.94 m** | 0.70 m | 0.90 x 0.60 | 1,656 | 3.3 km | 84 |
| Privet hedge | 1.55 m | 0.95 m | | 605 | 1.2 km | 29 |
| Promenade rail | 1.08 m | 0.17 m | 1.08 x 0.17 | 90 x 4.1 m + 19 x 2 m | 0.4 km | `f_se`, `n_ea_shore`, `n_ferry_landing`, `n_fw_slope`, `s_wf` |
| Porch railing (on houses) | 1.0 m above the 0.5 m deck (1.5 m above ground) | 0.08 m | 1.0 x 0.08 | on about 580 houses | | `houses/*` |
| Balcony railing | 1.0 m above a 3.4 m balcony | 0.08 m | | | | `contemporary_*`, `narrow_2sty_stucco_clay`, `spanish_large`, `beach_large` |
| Industrial stair rails | 1.75 m tall boxes | 0.08 m | | | | `ind_warehouse`, `ind_factory`, `ind_repair`, `svc_carwash` |
| Gates (privacy / picket / iron / rolling) | 1.80 / 1.10 / 1.30 / 1.86 m | 0.06-0.10 m | **solid colliders** (they do not open) | 870 / 155 / 138 / 47 | | |

Fence posts are at every joint (a house rule), so every 2 m there is a post 0.08-0.18 m wide.

## 7. Benches, tables and seats

| Prop | Seat height | Top / back | Size (w x d) | Collision | How many (pieces) |
|---|---|---|---|---|---|
| Park bench `prop_park_bench` | **0.47-0.48 m** | back 0.88 m | 1.80 x 0.60 | **one box 0.87-0.90 m high** (no seat) | 939 (234) |
| Bus-stop bench `prop_bench_bus_stop` | **0.46 m** | back 0.92 m | 1.90 x 0.67 | box 0.87-0.95 m | 129 (119) |
| Picnic table | seats 0.48 m | table 0.79 m | 1.83 x 1.50 | box 0.79 m | 407 (153) |
| Adirondack chair (white + wood) | about 0.4 m | 1.05 m | 0.86 x 1.06 | box about 1.0 m | 1,223 |
| Patio set (4 chairs) | | table about 0.75 m | 1.91 x 1.91 | box 0.85 m | 586 |
| Bus shelter seat | 0.49 m | roof 2.62 m | 4.6 x 1.9 | seat box 0.49 m, **roof box at 2.5 m** | 43 |

## 8. Planters, bins and small street furniture

There is **no raised street planter** in the kit. Trees stand in flat wells or grass.

| Prop | Height | Footprint | Collision | How many |
|---|---|---|---|---|
| Large potted plant `plant_potted_leafy` | pot rim 0.40 m, plant 1.01 m | 1.4 x 1.12 | cylinder 0.54 m wide, 1.01 m high | parks (e.g. `park_pocket_orange`) |
| Potted succulent | 0.46 m | 0.53 x 0.50 | 0.30 x 0.46 | many (house cells) |
| Street trash can `prop_trash_receptacle` | **1.10 m** | 0.62 x 0.64 | cylinder 0.61 x 1.06 | 504 (270 pieces) |
| Recycling can | 1.10 m | 0.62 x 0.64 | | 73 |
| Wheelie bins (black, green, blue) | 1.03 m | 0.66 x 0.90 | 0.66 x 1.03 x 0.84 | 2,232 |
| Dumpster 3 yd | **1.66 m** (lid 1.60) | 2.0 x 1.35 | box 1.66 | 336 |
| Roll-off dumpster 20 yd | 1.67 m | 2.55 x 6.83 | | 49 |
| Newspaper box | 1.10 m | 0.50 x 0.46 | 0.50 x 1.09 x 0.46 | 229 |
| Fire hydrant | 0.86 m | 0.41 x 0.33 | 0.42 x 0.87 | 344 (318 pieces) |
| Bollards (steel / concrete / iron) | 1.06 / 0.88 / 0.95 m | 0.22-0.33 m wide | cylinders | 221 / 102 / 76 |
| AC condenser | 0.86 m | 0.92 x 1.08 | 0.92 x 0.87 | 1,665 |
| Bike rack | 1.02 m | 2.52 x 0.12 | 2.54 x 1.03 x 0.16 | 360 |
| Storm-drain kerb inlet | **0.18 m** hump behind the kerb | 2.79 x 1.15 | 0.18 m box | 543 (248 pieces) |
| Manhole cover | 0.01 m | 1.16 m | none | 459 |

## 9. Parked cars and vans

- The pieces have **no car meshes**. Parked cars are put in by the traffic system at run time. The car meshes are in
  `vehicles/` (outside the folders this survey may read), so **bonnet and roof heights of the real parked cars were
  not measured.**
- How many places: **3,010 kerb stalls + 1,514 car-park stalls** (`traffic/streets_report.txt`). Downtown kerb stalls
  are parallel, **6.7 m long** (`PILOT_DESIGN.md`). Wheel stops in car parks: 4,633 (section 13).
- The only car-like meshes allowed here (estimates from the meshes, not from parked cars):
  - `prop_showroom_car` (indoor showroom car): 4.6 x 2.03 m. Bonnet top faces at **0.85-0.95 m**, roof at
    **1.26-1.35 m**. Collision one box 1.36 m high. A low sports car, not a family car.
  - Golf cart: roof **1.78-1.80 m**, seat about 0.68 m, 1.24 x 2.56 m. 15.
  - Boat on trailer: 1.75 m, 2.0 x 6.74 m. 142.
  - Shipping container: **2.59 m** high, 2.44 x 6.06 m, flat top, one box. 442 (industrial, gritty).
- No van data in the allowed folders.

## 10. Narrow wall tops (things to balance on)

| Top | Width | Height |
|---|---|---|
| Stucco / CMU / brick wall cap | about 0.25 m visible, **0.32 m** collision | 1.86 m cap, 2.0 m collision |
| K-rail (concrete road barrier) | 0.20 m top, 0.60 m base | 0.82 m |
| Water barrier | about 0.17 m top, 0.55 m base | 0.98 m |
| Promenade rail cap | 0.17 m | 1.08 m |
| Vinyl canal rail | 0.15 m | 1.12 m |
| Privacy fence top rail | 0.12 m | 1.84 m |
| Picket fence | 0.10-0.12 m | 1.1 m |
| Porch / stair rail | 0.08 m | 1.0 m above the deck |
| Wrought iron fence | 0.06-0.08 m | 1.26 m |
| Wheel stop | 0.15 m | 0.108 m |
| Kerb top | (open walk) | 0.15 m |
| Low hedge (soft) | 0.60 m collision | 0.90 m |

## 11. Doors and doorways

| Door | Width | Height | Sill | Where |
|---|---|---|---|---|
| House front door | **1.0 m** | 2.1 m | 0.5 m (at the porch deck) | modular houses and most kit houses |
| Apartment door | 1.0 m | 2.2 m | 0.0-0.6 m | `urb_brk_front_*`, `urb_grt_*`, `urb_wh_back_*`, `urb_civ_back_*` |
| Shop door | **1.2-1.8 m** (median 1.6) | up to 3.0 m (glazed) | 0-0.3 m | storefronts, `urb_twr_front_*` |
| Civic door | 1.8 m (1.4 m on some) | | | civic buildings |
| Patio slider | 1.6-2.4 m (1.8 m usual) | | | apartments |
| Garage door | 2.4 m | 2.2 m | 0 | house garages |
| Roll-up door | 3.2-4.4 m | 3.2-4.4 m | 0 | stores, warehouses |

Ground-floor entrances listed in the room contracts (one row per kit model, not per placement): residential 1.0 m
(419), shop 1.6 m (129), slider 1.8 m (124), civic 1.8 m (34), service bays 2.6-6.0 m.

Opening: most outside doors are only painted insets (5-15 cm deep, `SPEC.md`). Where a walk-in room is cut, the door
is a **double-acting hinged leaf** (a pair when wider than 1.3 m). It **swings away from the player by itself** when
the player is within about 2 m (in when entering, out when leaving), and is a collider while shut
(`interiors/PLAN.md`). So there is no push or pull choice. The design notes give public doors 1.0-2.4 m wide,
median 1.6 m, about 2.1 m high.

## 12. Cover-height objects

| About 1.0 m (crouch cover) | Height | | About 2.0 m (full cover) | Height |
|---|---|---|---|---|
| K-rail | 0.82 m | | Wall (stucco / CMU / brick) | 2.0 m col (2.18 visible) |
| AC condenser | 0.87 m | | Privacy fence | 1.84 m |
| Bench (collision) | 0.87-0.95 m | | Chain-link lot fence | 1.86 m (see-through) |
| Low hedge | 0.90 m | | Dumpster 3 yd | 1.66 m |
| Water barrier | 0.98 m | | Golf cart | 1.80 m |
| Wheelie bin | 1.03 m | | Vending machine | 1.83 m |
| Trash can, newspaper box | 1.10 m | | Container | 2.59 m |
| Steel bollard | 1.06 m | | Transformer substation | 2.65 m |

## 13. Gaps

Clear gaps between neighbouring buildings (collision boxes taller than 1.8 m, same piece):

| Gap | Pairs | Mostly between |
|---|---|---|
| 0-0.3 m | 97 | garages in a row (`garages/*`), row buildings (`ck/*`) |
| 0.3-0.5 m | 66 | row buildings `ck/*`, apartments |
| **0.5-0.8 m** | **32** | `ck/*` rows, shops and apartments (e.g. `b_nw`, `b_sw`, `g_v2_g4nw`, `g_v2_j4se`) |
| 0.8-1.2 m | 88 | houses, apartments (side passages) |
| 1.2-1.6 m | 74 | houses (side yards) |
| 1.6-2.5 m | 213 | houses, apartments |

Row buildings with 0.3-1.0 m gaps are also roof-to-roof jump gaps (roofs about 10 m high for `ck_apt3_row*`).
Water gap: floating docks lie 1.05 m below the quay, reached by the gangway.

## 14. Low ceilings and overhangs

| Overhang | Clear height | Collision? | How often |
|---|---|---|---|
| Garden arbor | 2.20-2.36 m | posts only | 153 |
| Bus shelter roof | **2.50 m** | yes, box | 43 |
| Under the pier deck (from the pier's base) | 2.64 m | yes | 8 |
| Porch roofs | about 2.6 m above the deck (3.1 m above ground) | **no** (you walk through) | most houses |
| Shade sails | 2.8-3.1 m | posts only | 151 |
| Balconies over the walk | **3.05 m** | yes | apartments, motels, condos |
| Dingbat tuck-under parking | **3.10 m** | yes | 31 |
| Gas station canopy | 4.20 m | yes | 3 |
| Museum / university portico | 4.1-4.4 m | yes | 4 |

**Nothing near 1.25 m was found** in outdoor walkable space. The lowest thing across a path is a clothesline wire
at 2.06 m (324, back yards). Tree crowns can hang down to about 2.5 m (`JOB_BOARD.md`).

## 15. Where collision and picture differ (important for traversal)

- **Stairs collide as blocks.** House stoop: 0.20 m then 0.30 m (picture: 3 x 0.167 m). Apartment stoop: 0.09 m then
  0.21 m. Dock stair: **0.55 m then 0.55 m**. Courthouse: **0.62 m then 0.58 m**. Museum: 0.38 m then 0.42 m.
  Dingbat stair: blocks of 0.72 m. Only the quay stair has a box per step.
- **Benches are 0.87-0.95 m boxes**, not seats. Picnic tables are 0.79 m boxes.
- **The bandstand is one solid block** (7.2 m high). You cannot climb its 5 steps.
- **Skate items are boxes:** quarter pipe 1.50 m block, bowl 1.80 m block, funbox 0.55 m block, grind rail 0.39 m.
- **Gates do not open**; they are 1.1-1.86 m walls.
- **Porch roofs, awnings and canopies have no collision** (SPEC rule): you can stand under them but not on them.
- **Wheel stops:** 4,633 placed, but only about 840 have collision (0.11 m).
- **Walls:** 2.18 m visible, 2.0 m collision.

## 16. Real kit pieces for a short "real street" test stretch

All are self-contained files. The `.scn` pieces embed their meshes and collision; they only need the materials and
atlases listed. The `.glb` models need the atlas PNGs their glTF names (relative paths shown).

1. **Street with kerbs, bench and bin**: `map_dc/coronado/city_kit/pieces/s_apt.scn` (138 KB).
   18.4 m wide x 80 m long, road at y 0, walks at **0.15 m** with a vertical kerb on both sides (144 m of kerb face).
   Has a bus bench (at x -8.8, z 38.5), a trash can, a hydrant, 6 lamps, 2 kerb inlets. Needs
   `map_dc/coronado/city_kit/materials/{wear_decal,g_asphalt,g_white,g_yellow,g_grass,g_curb,g_concrete,pw_props_*}.tres`,
   `map_dc/coronado/city_kit/shaders/*.gdshader`, `assets/coronado_kit/atlases/props_*`, `assets/roads/*.jpg`,
   `map_dc/coronado/streets/street_wear/wear_atlas.png`. (A junction with kerb ramps: `pieces/j_res.scn`, 40 x 40 m,
   102 KB.)
2. **House with porch, stoop and rails**: `assets/coronado_kit/buildings/houses/ranch_porch/house_ranch_porch_near.glb`
   + `house_ranch_porch_col.glb` (needs `assets/coronado_kit/textures/bld_*.png`). 10 x 8 m footprint, 6.18 m high.
   Porch deck 0.50 m (2.4 x 1.8 m), 3 risers of 0.167 m, tread 0.30 m, 1.2 m wide, rails 1.0 m above the deck, door
   1.0 x 2.1 m. Collision: 11 boxes (step 0.20 m, deck 0.50 m, rails 0.08 m thick).
3. **Loading dock with a real stair**: `assets/coronado_kit/buildings/industrial/ind_warehouse/warehouse_ind_warehouse_near.glb`
   + its `*_col.glb` (needs `textures/city_*.png`). 24 x 24 m, 6.6 m high. Dock 1.10 m (2.4 x 2.05 m), 6 risers of
   0.183 m, tread 0.30 m, 2.2 m wide, rails 1.75 m boxes. For big public stairs use
   `buildings/urban/urb_courthouse/` (7 x 0.171 m, 11.8 m wide, plinth 1.2 m).
4. **Fence**: `assets/coronado_kit/fences/fence_picket_white_clean_near.glb` + `fence_picket_white_col.glb` (2.0 m panel,
   1.10 m high, 0.10 m thick) with `fence_post_picket_*` (0.10 x 1.10 m). For the common tall fence:
   `fence_wood_privacy_clean_near.glb` + `_col.glb` (2.0 x 1.84 x 0.12 m) and `fence_post_privacy_*`. Needs
   `assets/coronado_kit/atlases/props_*.png`.
5. **Bench**: `assets/coronado_kit/props/park/prop_park_bench_clean_near.glb` + `prop_park_bench_col.glb`
   (1.80 x 0.60 m, seat 0.47 m, back 0.88 m, collision box 0.90 m).
6. **Cover and a narrow top** (optional): `assets/coronado_kit/props/construction/prop_k_rail_clean_near.glb` + `_col.glb`
   (3.8 x 0.6 m base, 0.20 m top, 0.82 m high) and `assets/coronado_kit/fences/fence_stucco_wall_clean_near.glb`
   + `_col.glb` (2.03 m panel, 2.18 m visible, collision 2.0 x 0.32 m).

---

## Things the course list may miss

Checked against: kerbs 10/12/15/16 cm, steps 20/24 cm, stairs 17/28 and 19/25, ramps 5/10/15/25 deg, blocks 0.3-3.2 m,
fences 0.9/1.1/1.3 m, car bonnet 0.85 / roof 1.45, van roof 1.9, bench 0.45, planter 0.6, drops 0.3-4.0 m, wall tops
60/30/20 cm, 10 cm pipe, 1.25 m low ceiling, cover walls 1.0 and 2.0 m, doors, 0.6 m gap.

**Covered well by the list:** 15 and 16 cm kerbs, 17 cm risers, 5 deg ramps, blocks 0.3-3.2 m, 1.1 m fence, bench
0.45, drops, 30 and 20 cm wall tops, 1.0 and 2.0 m cover, 0.6 m gap, doors.

**In the list but not in the city (or very rare):**
- 10 and 12 cm kerbs (none; 10-14 cm only as pad edges and sills).
- 20 and 24 cm single steps in the picture (real visible steps are 15-18 cm). But the **collision** has 20 cm and
  9 cm steps (see below).
- 19/25 stairs (real treads are 30 cm, the dingbat stair 27 cm).
- 10, 15 and 25 deg ramps as built ramps (only as grass banks, small areas).
- A 1.25 m low ceiling (none found; the lowest overhang is 2.2 m).
- A 0.6 m planter (no raised planters; pots are 0.40-0.46 m, the low hedge is 0.90 m).
- 0.9 m and 1.3 m fences exist only roughly (1.26 m iron, 1.0 m porch rail).

**In the city but not in the list:**
1. **Tall fences 1.5-1.9 m are the most common obstacle**: privacy fence 1.84 m (about 42 km), chain-link 1.52 and
   1.86 m, board fence 1.55 m, hedge 1.55 m. Walls are 2.0 m (collision) / 2.18 m. The list stops at 1.3 m.
2. **Collision stairs as big blocks**: 0.55 m (dock), 0.62 m (courthouse), 0.72 m (dingbat stair), 0.38-0.42 m
   (museum). A stair test with real steps does not test this.
3. **Small collision steps of 9 cm and 20 cm** at every stoop (468 + 1,079 buildings).
4. **Stair treads of 0.30 m with risers of 15-18.3 cm** (stairs 15/30, 16/30, 17/30, 18/27, 18.3/30).
5. **Ledges whose height changes along their length** (lot pads on a slope, 0 to 0.9 m and more). About 66 km of
   edges between 17 cm and 3.2 m.
6. **Kerb on a sloped street** (0.15 m kerb plus a 4.6 deg grade), and kerb ramps of 5-6 deg with 8-9 deg flares.
7. **Porch with rails**: a 0.5 m deck with a 1.0 m rail on top (1.5 m from the ground, 8 cm thick) - vaulting a
   rail that stands on a ledge.
8. **Box-shaped seats**: bench collision 0.87-0.95 m, picnic table 0.79 m, play deck 1.25 m.
9. **Water edges**: quay to floating dock 1.05 m, quay to sea about 1.5 m, a 5.5 deg gangway, 0.32 m boardwalk.
10. **Trip hazards**: wheel stops 0.108 m high and 0.15 m wide (4,633), kerb inlets 0.18 m (543), riprap boulders
    0.46 m (1,439, collision 0.65 m).
11. **Closed gates** (1.1-1.86 m) that behave as walls.
12. **Thin posts and rails**: fence posts every 2 m (0.08-0.18 m wide), rail boxes 0.08 m, skate grind rail 0.39 m
    high, bike rack 1.02 m.
13. **Head-height wires**: clotheslines at 2.06 m in back yards (324).
14. **Gaps too narrow to enter** (0.1-0.5 m between row buildings and garages, 163 pairs) next to passable side
    passages of 0.8-1.6 m (162 pairs).
15. **Flat-topped climb targets**: containers 2.59 m (442), dumpsters 1.66 m, substations 2.65 m, lifeguard tower
    deck 2.0 m, dingbat landing 2.88 m.
16. **Parked cars could not be measured here**; check bonnet and roof heights against the real meshes in
    `vehicles/` before fixing 0.85 / 1.45 / 1.9 m. The showroom car is 0.85-0.95 / 1.35 m.
