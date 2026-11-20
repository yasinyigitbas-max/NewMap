# West fill (University session, 20 Nov) - PLAN

Yasin (relayed by the coordinator, then in this session): "populate them ... act like architects and city planners,
build indoors and outdoors, take the elevation of the map into consideration ... run superchecker on everything you
built to bugfix and lock ... plenty of props, plenty of life"; "DONT FORGET TO TAKE THE LAND INTO CONSIDERATION, build
according to it"; plus three small spots he marked (the strip north of the 56 % block, the square in the 51 % block,
the rectangle east of the 18 % block).

Assignment: review/fill_assignment_20nov.json "university" (23 blocks) + the three spots; map:
review/fill_west/university_blocks_yellow.png. Survey: OUT/area/west_survey.json (1 m raster of the whole city's
ground, 20 Nov): every empty rectangle, its land, its neighbours and their heights.

## Rules for every piece
- ONLY empty land; never move, rebuild or touch an existing piece. Own table review/grow_uw_blocks.json.
- One script per piece (tools/city/pilot/pieces/n_w_<site>.gd), hand placement, a reason per prop.
- Ground follows the land (8 cm over it) and eases to the measured heights of every neighbour at its edges (walks,
  other blocks), measured every 2 m; buildings on level pads at the highest ground under them (plinth faces).
- Rooms for every walk-in building (room tools, as on the campus); homes are not entered.
- Trees: a hand-placed t_ piece per area, by docs/TREE_PLAN.md (grass / mulch only, clumps, the 60 m cap).
- Then the superchecker (outdoor: validator, life, trees, sink, ground check, own-ground audit; indoor: check_rooms),
  fix, write the land inside my own pieces only, lock.

## What each area becomes (planner's reading: ZONING.md, the neighbours, the land)
| Area | Empty land | Land | Becomes |
|---|---|---|---|
| Industrial east halves u -500..-409, v -1586..-1414 and -1386..-1214 | 2 x 15,600 m2 | 2.0 / 2.0-4.1 | light industry beside the industrial zone: contractor yards, a marine-supply warehouse, a self-storage yard, truck parking |
| Gritty east half u -500..-409, v -1186..-1009 | 16,100 | 4.0-6.1 | gritty edge: worn walk-ups, a pawn shop, a laundromat, a corner store, a vacant lot |
| North of the campus u -791..-609 v -900..-809, u -591..-409 v -991..-809 (+ the two small squares) | 16,600 + 24,800 | 4.9-6.1 / 5.9-6.1 | where the students live (ZONING): student apartments, a pizza place, a bike shop, a bar, a laundromat, a bus stop |
| West strip u -986..-809 (seven blocks, north to south) | 24,000-32,000 each | 2.0-8.0 (Country Club Ridge) | houses on terraces down the ridge, an elementary school with its field, a church at the crest, a pocket park, the ridge park looking to the beach; apartments at the gritty end (north) |
| Civic / stadium surroundings u -391..0, v -791..-209 (+ the 40 x 40 m holes in the stadium piece) | ~120,000 | 5.9-6.2 (flat) | the civic band: kit parks (tennis courts in the stadium's 40 x 40 holes, a playground, a dog run, a memorial green), stadium parking edges, a fire station, a post office, community uses, apartments facing the parks |
| South-west edge v 209..400, u -1000..-200 | ~120,000 | 1.4-4.1 (down to the shore) | the beach side: houses and a beach park stepping down to the shore, beach access, a lifeguard post, a surf shop |
| Extra spots | 6,700 + 3,200 (north strip), 176 (square), 1,200 (east of 18 %) | | the north strip: a planted buffer and a contractor yard by the industrial edge; the small squares: a pocket garden, a kiosk |

Order: industrial halves, gritty half, north of the campus, civic band, west strip, south-west edge, the spots; each
area committed as it is built; the superchecker at the end of each area and over all of it at the end; then lock.
