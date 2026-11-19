# Hospital zone and university campus (branch `claude/fill-high-street`, 19 Nov)

Yasin: "Start working on hospital zone ... act like an exterior designer and city planner, lots of props, lots of life
... take elevation into consideration ... Place a bus station at hospital ... No overlapping props in ground or the
walls, make both indoors and outdoors, university itself included."

Status: **built, checked on area layouts, NOT locked, NOT in the shared layout** (`city_grid_layout.json` untouched), the
land not written, no pictures taken (none looked at). Nobody has seen it.

## Hospital zone (ZONING.md MUST site: u 400..660, v -1600..-1400, 3rd St / Adela / the bay-front ring)
Land: FLAT. Every walk round it is at 2.150; the land under it 1.80 - 2.13. One surface at the walk's height.
The streets round it are locked and have only ONE car opening into each block: Adela's alley aprons 54 - 60 m north of
3rd St. So cars, ambulances and buses all enter there, not off 3rd St as ZONING.md wished; an ER entrance straight off
3rd St needs a driveway cut into the locked 3rd St piece (Yasin's word).

| Piece | What |
|---|---|
| `n_hp_main` | **Island Hospital**: Hospital Drive from Adela's apron; the main hospital (pub_hospital) with its drop-off forecourt; the ER wing (ext_hospital, EMERGENCY painted on) with the ambulance bay and a zebra to the helipad; the walk between them (ER walk-in door); loading dock, fenced plant yard (oxygen tank, generator fuel, transformer, chillers); the visitors' car park (7 rows); the healing garden on the bay curve. |
| `n_hp_transit` | **Island Transit Center** (the bus station Yasin asked for): a 4-bay lay-by along the drive, the platform with 4 shelters, stop signs, benches, timetable cases; the waiting hall (civ_post_office re-used); the coffee kiosk plaza from the 3rd St / Adela crossings; the drivers' break corner; the **helipad** in its fenced field opposite the ER. |
| `n_hp_west` | West of Adela: Medical Plaza Drive from the west apron; the **staff garage**; the **medical office tower** (urgent care) facing the hospital; the **pharmacy** and **Isla Bistro** on 3rd St with delivery stalls; two **care residences** on the bay with their garden court; the **wellness center**. |

## University campus (Crown Bay University; the superblock between nodes (-800, -800) and (-400, -400))
Land: flat at 6.150 on the north and east, FALLING 2 m into the SW corner with J Ave and the south street (4.150). The
ground (`n_un_site.g`): flat, then planes rising inward from the two low walks at 1.65 %, joined by a soft minimum and
eased onto the walks within 3 m. Buildings on level pads at their front's height; raised doors get steps.

| Piece | What |
|---|---|
| `n_un_quad` | **The Quad**: Founders Hall (pub_university) and the University Library facing each other over a lawn quad, four lecture-hall wings, the founders' memorial at the cross walks, students' chairs and tables on the lawn. |
| `n_un_north` | **University Circle** entrance (Founders Green, canary palm avenue, visitors' stalls, drop-off), the **art museum** (steps up its 0.8 m plinth) and the **chapel**; the **rec center** with car park, two tennis courts, the rec field; the **campus garage** and lot. |
| `n_un_west` | The **science tower**, engineering labs, lab wing; the faculty road with stalls; the **solar test field**. |
| `n_un_east` | The **student union**, campus cafe, bookstore round **Union Plaza**; the **bandstand** lawn; **sand volleyball**; the service road. |
| `n_un_south` | **Dorms** on terraces in the low SW corner (grills, washing lines, tables), the **South Loop** with the **campus shuttle stop** and the library plaza, two loop halls, the east dorms with their car parks. |

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
| seams (scratch `OUT/py/seams.py`, 0.25 m) | hospital 0.0 cm on every shared edge (one inverted ground band over the ring's walk found and fixed); campus at most 0.7 cm | faces, looks |
| `ground_check.py` | hospital: 0 m2 under the land; campus: 18,551 m2 under the land, all of it by less than 30 cm (where the real land rises to 6.2 - 6.31 under the flat 6.15) | - |
| `check_rooms.gd --only=g_hp_,g_un_` | 0 problems, 22 rooms | whether a room has what that place needs |

## Not done
- Nobody has looked at it: no pictures (Yasin: none needed last time; say if wanted).
- The land under the campus needs lowering by up to 30 cm on 1.86 ha (dry run only; the land is not written).
- Not in `city_grid_layout.json`, not baked, no phone run; not locked.
- ZONING.md's ER-off-3rd-St needs a driveway in the locked 3rd St piece.
- The kit has no hospital props (beds, wheelchairs, ambulances): the rooms use waiting benches, desks, counters.
