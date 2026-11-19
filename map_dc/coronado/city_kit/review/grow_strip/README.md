# Commercial strip growth (18-19 Nov, branch claude/grow-strip) - LOCKED 19 Nov (Yasin: "lock your parts if you are done with them")

Six new blocks round the locked strip sample (`m_*`, Adela Ave x 3rd / 4th / 5th St, up to Glorietta Blvd), each its
own builder script (`tools/city/pilot/pieces/m_gr_*.gd`, shared library `strip_grow_lib.gd`), outdoors and indoors
together: 26 shop rooms (`interiors/assignment_strip.json`, `tools/city/rooms/room_gen_strip.gd`). Table
`review/grow_strip_blocks.json` (picked up by `integrate.py`); pictures in `review/shots/strip_grow/`.

## The variants (Yasin: approve / change before any wider growth)
| | piece | where | what it is, and why there |
|---|---|---|---|
| A | m_gr_ad5ne | Adela-Glorietta, 5th St | **car care corner**: drivers off the bridge loop here. Car wash on the ring corner, quick lube, tyre shop with its container yard, auto parts / phone shop row, chicken drive-thru on the signal pad, diner, taqueria, tax office. |
| B | m_gr_e4s | Glorietta, south of 4th | **bridge-mouth pad**: the most seen, least reachable frontage. A used-car lot (wants to be seen), sales office, its own service garage, bright lot lights. |
| C | m_gr_ad5nw | west of Adela, 5th St | **neighbourhood centre** where the strip meets Crown Hill's houses: discount grocer, laundromat, nails, dentist, pizza, dry cleaner, credit union, can-recycling booth; walls, privet and trees toward the houses. |
| D | m_gr_ad3sw | west of Adela, 3rd St | **hospital side**: urgent care + physio row, visitors' coffee and flower corner at the signal, paid visitor parking with its booth. |
| E | m_gr_ad3se | Adela-Glorietta, 3rd St | **motel and gym**: a two-wing motor court for patients' families and bridge travellers, a 24-hour gym in an old warehouse (hospital shift workers), a walk-up coffee kiosk for staff crossing 3rd St. |
| F | m_gr_e4n | Glorietta, north of 4th | **boat and RV storage**: too narrow and no driveway for a shop; chain-link and barbed wire, boats on trailers, rented containers, a propane refill, the power substation in its own corner, two billboards to the bridge. |

## Rules carried (Yasin's words, and what enforces them)
- Ground meets every neighbour flush (`zoning/strip_grow_ground.py`: one solve for the six blocks; edge heights taken
  from the neighbour's walk; the line between two new blocks solved once; a hidden skirt under every edge; floor cells
  share their corners, no T-joint cracks). Wear marks only on paving. Planting strips paved to the walk.
- A post at every fence joint, fence ends meet a wall, a gate or a fence (`check_life.gd`: 0).
- Trees only in wells / grass (`audit_trees.gd`: 0). Utility poles on gravel pads, never on asphalt.
- Nothing in front of a door or a walk-up window; benches face what people watch; bike racks along the front.
- Indoors: the strip's room rules (`check_rooms.gd --only=g_strip_`: 0 problems in the 26 rooms).

## Kit used
1,803 props of 97 types and 22 buildings of 17 types outdoors (KIT_USAGE.md, "Commercial strip growth"). First use of
the car wash, the tyre shop (ck_svc_trade), com_shallow_surf, the stucco wall and garden gate, privet, iron bollards,
rubber wheel stops, the roof vents / solar / compact AC, torrey and Norfolk pines. Every shop, service and industrial
building of the kit is now placed somewhere in the map; nothing left unused in the kit fits a commercial strip.
Known: the motel model carries its own painted sign "BREEZE MOTEL" (the shop is called Harbor View Motel in the room
table and on the pylon): a kit texture, not changed here.

## Numbers (STRIP_NUMBERS; cloud measurements, NOT the phone)
Baked like the other zones (`bake_runtime.gd --area=522,-1200,200 --nofarground --out=res://OUT/rt_*`: the eight
200 m cells round the strip; BEFORE = the same layout without the six `m_gr_*` rows), measured with `rt_shots.gd` from
12 viewpoints (each block from above and along its street at eye height). Rooms are not in the bake yet.
- **Draws per view: 44-70 after (20-56 before).** Inside the phone's ~150 everywhere.
- **Triangles per view: 443k-822k after (192k-497k before); over the ~500k mark in 9 of 12 views**, worst along Adela
  between C and the sample (753k) and between D/E (822k). Without the far world: +270k to +460k a view from the new
  blocks. Per block (near tier): A 133k, F 103k, E 87k, C 71k, D 67k, B 49k; a sample block is 52-76k. The heavy
  items: the 31 boats on trailers in F (69k, 2.2k each), concrete / rubber wheel stops (68k over the zone, one per
  stall), the ground (68k: its cells are no longer merged into long runs, which removed the hairline cracks). Yasin's rule:
  draws first, triangles are fine, but said here. Cheap cuts if wanted: half the boats as the mid-tier model, wheel
  stops only on the front rows, a coarser ground grid in A.
- **Download: the four cells of the zone grow from 11.6 to 21.3 MB, shared models (lib) +2.0 MB: +11.7 MB in all,
  about 1.6 MB of cells a block** (gritty: 1.6 MB a block).
- **Rooms** (26): built as the other zones' rooms; not in the streamed city (the bake knows no rooms yet).

## Checks (19 Nov)
Validator CHECKS 0 problems, check_life 0 (strip blocks), trees 0 in hard ground, sink 0, indoor checker 0 problems
in the 26 strip rooms, lock test RESULT PASS. LOCKED (Yasin 19 Nov): the six m_gr_* pieces (lock.py lock) and the 26
g_strip_* rooms (lock.py lockfile); lock test RESULT PASS (407 pieces, 45 files). Not merged.
