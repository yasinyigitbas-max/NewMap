# Hospital zone and university campus (branch `claude/fill-high-street`, 19 Nov)

Yasin: "Start working on hospital zone ... act like an exterior designer and city planner, lots of props, lots of life
... take elevation into consideration ... Place a bus station at hospital ... No overlapping props in ground or the
walls, make both indoors and outdoors, university itself included."

Status (19 Nov, end): **through the superchecker, hand trees placed, LOCKED** (Yasin: "then lock it"); NOT in the shared layout (`city_grid_layout.json` untouched), the
land not written, no pictures taken (none looked at). Nobody has seen it.

## Hospital zone (ZONING.md MUST site: u 400..660, v -1600..-1400, 3rd St / Adela / the bay-front ring)
Land (Yasin, after the first build: "Don't forget about the elevation, build according to it"): every walk round it is
at 2.150; the land under it 1.51 - 2.12. The ground FOLLOWS THE LAND (`n_hp_site.g`: 5 cm over the land's own 4 m
nodes, exported to `n_hp_land.gd` by `tools/city/pilot/zoning/export_land_patch.py`, read-only on the land), eased onto
the walks within 12 m of every street. Ground 1.85 - 2.17.
The streets round it are locked and have only ONE car opening into each block: Adela's alley aprons 54 - 60 m north of
3rd St. So cars, ambulances and buses all enter there, not off 3rd St as ZONING.md wished; an ER entrance straight off
3rd St needs a driveway cut into the locked 3rd St piece (Yasin's word).

| Piece | What |
|---|---|
| `n_hp_main` | **Island Hospital**: Hospital Drive from Adela's apron; the main hospital (pub_hospital) with its drop-off forecourt; the ER wing (ext_hospital, EMERGENCY painted on) with the ambulance bay and a zebra to the helipad; the walk between them (ER walk-in door); loading dock, fenced plant yard (oxygen tank, generator fuel, transformer, chillers); the visitors' car park (7 rows); the healing garden on the bay curve. |
| `n_hp_transit` | **Island Transit Center** (the bus station Yasin asked for): a 4-bay lay-by along the drive, the platform with 4 shelters, stop signs, benches, timetable cases; the waiting hall (civ_post_office re-used); the coffee kiosk plaza from the 3rd St / Adela crossings; the drivers' break corner; the **helipad** in its fenced field opposite the ER. |
| `n_hp_west` | West of Adela: Medical Plaza Drive from the west apron; the **staff garage**; the **medical office tower** (urgent care) facing the hospital; the **pharmacy** and **Isla Bistro** on 3rd St with delivery stalls; two **care residences** on the bay with their garden court; the **wellness center**. |

## University campus (Crown Bay University; the superblock between nodes (-800, -800) and (-400, -400))
Land: the walks are at 6.150 on the north and east, FALLING 2 m into the SW corner with J Ave and the south street
(4.150); the land under the campus 3.95 - 6.31. The ground FOLLOWS THE LAND (`n_un_site.g`, the land table
`n_un_land.gd`), 5 cm over it, eased onto each walk within 12 m (the first build's flat 6.15 sheet had the land over it
on 1.86 ha: replaced).

| Piece | What |
|---|---|
| `n_un_quad` | **The Quad**: Founders Hall (pub_university) and the University Library facing each other over a lawn quad, four lecture-hall wings, the founders' memorial at the cross walks, students' chairs and tables on the lawn. |
| `n_un_north` | **University Circle** entrance (Founders Green, canary palm avenue, visitors' stalls, drop-off), the **art museum** (steps up its 0.8 m plinth) and the **chapel**; the **rec center** with car park, two tennis courts, the rec field; the **campus garage** and lot. |
| `n_un_west` | The **science tower**, engineering labs, lab wing; the faculty road with stalls; the **solar test field**. |
| `n_un_east` | The **student union**, campus cafe, bookstore round **Union Plaza**; the **bandstand** lawn; **sand volleyball**; the service road. |
| `n_un_south` | **Dorms** on terraces in the low SW corner (grills, washing lines, tables), the **South Loop** with the **campus shuttle stop** and the library plaza, two loop halls, the east dorms with their car parks. |

## Buildings on the land (both zones)
Every building stands on a level PAD (footprint + 0.3 m; the dorms + 0.5 m) at the height of the highest ground under it,
so the land never shows through a pad cut into a slope; round each pad the ground is GRADED up to it at 6 % at most
(`hs_fill_lib.graded`), so a door meets a graded apron, not a kerb (the hospital's entrance and the ER's ambulance doors
stood 14 - 17 cm over the walk before the grading). On the campus the aprons ease back onto the plain ground within 4 m
of a walk, and the south row grades to the library's pad across the piece line. Raised door sills (the museum's 0.8 m
plinth, Founders Hall 0.6 m, the civic buildings 0.3 m) get steps.

## Emergency Drive off 3rd St (Yasin: "make the drive way ... make triple sure your changes dont effect any other road")
The locked 3rd St piece `s_rg_nw_b071` was unlocked on his word, patched IN PLACE (not rebuilt from its script) by
`tools/city/pilot/patch_driveway.gd` and relocked: between u 588.60 and 596.43 (two whole parkway panels, so no
triangle was split) the parkway's 4 grass triangles and the kerb face's 4 triangles were taken out, and a concrete
apron sloping from the walk (2.150) to the road (2.000) plus two curb returns were added. Proof, three ways:
1. sha256 of all 555 piece files before / after: only `s_rg_nw_b071.scn` differs.
2. The patch tool refuses to save unless every old vertex, normal, tangent and uv is unchanged, every old triangle outside
   the cut is still there and every other node equals the saved file.
3. An independent before / after reader: 56 / 56 nodes identical except the ground; ground triangles 2466 -> 2462
   (8 gone, 4 added, 0 of their vertices outside the cut); no wear decal over the cut. Lock test RESULT PASS (521 pieces);
   `locked.json` changed only in that piece's entry.
On my side (`n_hp_transit`): EMERGENCY DRIVE from the cut straight north across Hospital Drive into the ER's ambulance bay
(the bus lay-by and platform shortened by 10 m; the vending, a bench, two plants and a palm moved). Seam 0.0 cm.

## Polish pass (Yasin: "run a polish pass on the whole zone, plenty of relevant props, lots of life")
516 more props over the 8 pieces (after 9 the validator found on other props were taken out again): trees on open lawn
away from buildings, shrubs and sprinklers near them, benches / picnic tables / garden chairs in the healing garden, the
care court, the dorm courts, the union lawn and the South Green, benches, planters, bins, racks, fountains and paper
boxes on the wide paving. Each on a free spot found by a scratch tool (`OUT/py/freespots_hp.py`, not part of the build),
chosen per kind of place and frozen as a literal POLISH list in each piece script. Kept clear: the helipad field, the
Emergency Drive, the rec field and courts, the solar field, the quad lawn's middle, Founders Green's avenue, the
volleyball court, the bandstand. Props now: hospital 841, campus 1,331. The rooms were not changed in this pass.

## Rooms (22, `room_gen_hp.gd` = room_gen_hs + kinds clinic / transit / lecture; `assign_hp.py`)
Hospital: main lobby, Atrium Cafe, Emergency Department, Transit Center waiting hall, urgent care, pharmacy, bistro,
wellness center. Campus: admissions, library, 3 lecture halls, faculty commons, rec center desk, art museum, science
tower advisers, engineering lecture hall, science reading room, union food court, campus cafe, bookstore.
Contracts for pub_hospital, ext_hospital, pub_university, pub_museum measured by `room_contracts_hp.gd` (the shared
contracts file untouched). 9 single items taken out by hand (room_drop_prop) where the checker found them unreachable or
blocking a seat. Not walk-in: garages, the chapel (no contract), the coffee kiosk (house door), residences.

## Checks (area layouts: my pieces + the streets round them; real renderer)
| Check | Result | Cannot see |
|---|---|---|
| `validate.gd` | 0 problems (hospital area, 1,498 props; campus area, 1,724 props) | heights, whether a prop makes sense |
| `check_life.gd` | 0 on these pieces (6 in the strip's locked pieces, not mine); the plant-yard fence ends were moved into the ER wall | as in the high street README |
| `audit_trees.gd` | 177 / 414 trees, 0 in hard ground | - |
| seams (scratch `OUT/py/seams.py`, 0.25 m) | hospital at most 1 cm on every shared edge (one inverted ground band over the ring's walk found and fixed); campus at most 1 cm, except 1 m at 2.9 cm where the library's pad corner meets the south piece | faces, looks |
| land over my ground (scratch `OUT/py/buried.py`, 1 m cells, the land bilinear) | 0 cells in both zones (the closest: my ground 2.7 cm over the land) | - |
| grades (scratch `OUT/py/grade.py`, 1 m) | hospital: median 0.3 %, 99 % of the ground under 4.8 %, none over 8 %; campus: median 0.2 %, 99 % under 2.7 %, 0.12 % over 8 % (the steps to raised doors) | - |
| `check_rooms.gd --only=g_hp_,g_un_` | 0 problems, 22 rooms | whether a room has what that place needs |

## Not done
- Nobody has looked at it: no pictures (Yasin: none needed last time; say if wanted).
- Not in `city_grid_layout.json`, not baked, no phone run; not locked.
- The kit has no hospital props (beds, wheelchairs, ambulances): the rooms use waiting benches, desks, counters.

## Superchecker pass and lock (Yasin: "use super checker in your entire zone and weed out the unnecessary parts, remove every
## tree, fill their wells ... place new trees according to the tree plan ... be very prone to delete ... then lock it")
The superchecker (`tools/city/super/`, brought in unchanged from `claude/festive-faraday-20ltx2`; `sc_lib.LAYOUT` may be an
area layout, `SC_LAYOUT`) checked all 8 pieces and their 22 rooms. The pieces were unlocked drafts, so the fixes were made
at the source, in each script, as a literal list with the checker's reason per line (`const SC`, `hs_fill_lib.sc_apply`):
- every builder tree and palm out (353); the 7 mulch wells closed (the paving round them runs over)
- deleted, as Yasin's rule says when no plainly safe place exists: 165 seats / tables with no reason, 54 bins in the
  open, 37 things over the piece's edge, 22 on a path, 4 narrowing a walk, a rack across a walk, 2 stray benches, a
  sail over nothing, 2 wall items with no wall (285); 21 oil marks where no car stands
- 13 lamps turned back over their road; 33 collision boxes on building columns (the checker's measured sizes)
- the 106 plants given collision (Yasin: "all of them should have collision"; the kit's own collision meshes)
- steps rebuilt closed down to the ground (0.35 m treads, riser, sides, back), empty prop batches dropped
- rooms: 5 items blocking a door or a shop window erased on proven copies (PROOF RESULT PASS), installed
Re-check: only report-only findings left: `wide_batch` (a draw-cost note) and `empty_area` (the open lawns, kept open).

Trees came back only by hand (`zoning/trees/hp_*.json`, `un_*.json`, each line with its why; the plan's "civic and parks"
rule for the hospital and campus grounds, "one tree per court" for the dorm and care courts): 46 trees in 8 tree pieces
`t_<area>`, every list `sc.py trees` ok (ground, walls, doors, fences, props, stalls, spacing, at most 3 broadleaf and 6
trees in view from any street point against the plan's 8 / 12).

Final checks (area layouts with the tree pieces): validate 0 / 0; check_life 0 on these pieces; trees 0 in hard ground;
check_rooms 0 (22 rooms). Locked: the 8 pieces, the 8 tree pieces, the 22 room files; lock test RESULT PASS (537 pieces,
125 files).

## Colliders true to size (hospital zone only; Yasin: "match all colliders to their object sizes, not bigger not smaller",
## "keep the uni out of your work this time")
The 6 hospital files (n_hp_main / transit / west and their tree pieces) were unlocked on his word, patched in place by
`tools/city/pilot/exact_colliders.gd` (not rebuilt) and relocked: every prop and tree collider rebuilt from its own drawn
near mesh, triangle for triangle (per-axis scale, so a shortened fence panel collides at its drawn length); the fence posts
and palm that had none given one; column boxes replaced by the building's own post triangles, or set to the measured post
where its faces run past the box. Sprinklers and iceplant ground cover stay without (walked over by design).
Proof: a separate reader pairs every collider with the drawn prop at its place, one to one, and compares every corner:
656 colliders, largest gap 0.1 mm, none without a prop under it; every other node identical (checked by the tool before
saving); sha256 of all piece files: only those 6 changed; validate 0; lock test RESULT PASS. The campus pieces were
restored byte for byte to their locked state and not changed.
