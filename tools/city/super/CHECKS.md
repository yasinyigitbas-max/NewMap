# The superchecker's list, row by row (19 Nov 2026)

The list Yasin was given before the tool was made, with what stands behind each row now. "Kind" is the name a
finding carries in `<piece>.faults.json`. Fix: **auto** = one right answer, the tool writes the line; **choose** = a
place must be picked by hand for that one item; **report** = not one item (ground, a building, a fence to be added).
Every finding carries a "sure" note; where it says "look", a picture decides.
Tried on two blocks (gritty `g_v1_j4ne`, residential `r_q_m800_m200_ne`), one street piece and twelve rooms.

## Outdoors
| # | What | Kind | Fix |
|---|---|---|---|
| 1, 2 | piece ground under the land / land showing through | `ground_buried` | report |
| 3, 4 | edge standing over / meeting its neighbour at another height | `edge_step` (the face under it is `x_wall_feet`'s job; its presence is not tested) | report |
| 5 | strip of bare land between two pieces | `edge_gap` | report |
| 6 | step inside the piece's own ground with no face | `ground_step` | report |
| 7 | ground at sea level; low pads beside the sea | `ground_sea`, `ground_low` | report |
| 8 | building sunk / floating | `building_sunk`, `building_floats` | report |
| 9 | building on a slope without a pad | `building_slope` | report |
| 10 | door or garage door not meeting the ground | `door_step`, `garage_step` | report |
| 11 | prop in the air / sunk | `in_air`, `sunk`, `off_ground` | auto (over 1.2 m: choose) |
| 12 | fence or wall panel floating / buried | `fence_air`, `fence_sunk` | auto |
| 13 | two props in the same space | `overlap`, `double` | choose / auto |
| 14 | prop inside a building (footprint and the real mesh) | `in_building`, `in_model` | choose |
| 15 | building in building, building off its block | `building_overlap`, `building_off_block` | report |
| 16 | in front of a door, shop front, roll-up, garage, stair, gate, lane mouth | `door`, `opening`, `garage`, `stair_foot`, `gate_blocked`, `lane_mouth` | choose |
| 17 | on a road, stall, drive, path | `on_road`, `in_stall`, `on_asphalt`, `on_path` | choose |
| 18 | walk left narrower than 1.2 m | `walk_narrow` | choose |
| 19 | wall item over an opening or another wall item; services near a door | `over_opening`, `overlap`, `near_door` | choose |
| 20 | wall item with no wall, over the roof; AC not in a window | `no_wall`, `over_roof`, `ac_no_window` | choose |
| 21 | play item not on bark or sand | `play_surface` | choose |
| 22 | pole on asphalt | `pole_asphalt` | report (a pole carries wires) |
| 23, 24 | tree in hard ground, near a fence, on a stall | `tree_hard`, `tree_fence`; for hand-placed trees the tree list's own check | auto / list |
| 25 | seat or table where vehicles go | `on_asphalt` | choose |
| 26 | hydrant or hose reel in the middle of nowhere | `hydrant_nowhere` | choose |
| 27 | bin in the open | `bin_open` | choose |
| 28 | bike rack across a walk | `rack_across` | choose |
| 29 | vending or ice chest on the walk | `vending_on_walk` (+ `door`, `stair_foot`) | choose |
| 30 | bench facing a wall | `seat_faces_wall` | auto turn / choose |
| 31 | stray bench at a picnic table; sail over nothing | `stray_bench`, `sail_over_nothing` | choose / report |
| 32 | lamp or mast arm turned from the road | `arm_away` | auto turn |
| 33 | hanging over the block's edge | `over_edge` | choose |
| 34 | fence end leading nowhere | `fence_end` | report |
| 35 | back yard not closed; no post; stretched; through a building | `yard_open`, `fence_no_post`, `fence_stretched`, `fence_in_building` | report / choose |
| 36 | chain-link along a street; one fence behind another; gate blocked | `chainlink_street`, `double_fence`, `gate_blocked` | report / choose |
| 37 | banned items | `banned` | auto remove |
| 38-40 | wear mark off its surface, over the edge, under a building; tyre marks, oil and patches on a sidewalk; oil with no car place | `wear`, `oil_no_car` | auto remove |
| 41 | dark patch alone on a road; pale patch left white | `patch_alone`, `pale_white` | report |
| 42 | drive meeting the street with no apron | `drive_no_apron` | report |
| 43 | parking stall in a building or a prop in a stall | `stall_in_building`, `in_stall` | report / choose |
| 44 | wire through a building; pole with no wire | `wire_in_building`, `pole_no_wire` | report |
| 45 | open shop behind painted windows or a house door | `shop_painted_windows`, `shop_house_door` | report |
| 46 | shop door with no room; room with no building; room not built | `no_room`, `room_no_building`, `room_not_built` | report |
| 47 | painted sign that names another shop | `sign_wrong` | report |
| 48 | the same tree several times | the tree list's check ("copy pasted") | list |
| 49 | play area with under three items; empty ground | `park_empty`, `empty_area` | report |
| 50 | seat or table with no reason | `no_reason` | report |
| new | no collision on a thing standing on the ground; on a building's column | `no_collision`, `column_no_collision` | auto |
| new | every builder tree out, its well paved | `tree_out`, `well` | auto |

## Indoors
| # | What | Kind | Fix |
|---|---|---|---|
| 51-66 | the existing indoor checker's 25 kinds | `old_<kind>` | report |
| 67 | its notes for locked rooms counted | `old_<kind>` | report |
| 68 | room against its building | `room_outside`, `floor_level`, `opening_no_match`, `opening_missed` | report |
| 69 | tall thing behind glass; empty shop window | `window_blocked`, `window_empty` | choose / report |
| 70 | counter in view from the door | `no_counter`, `counter_hidden` | report |
| 71 | queue space | `queue_blocked`, `counter_faces_wall` | choose / auto turn |
| 72 | first 1.5 m inside the door | `entry_blocked` | choose |
| 73 | till or machine turned wrong | `till_backwards`, `till_sideways`, `till_alone` | auto turn / report |
| 74 | fridge, shelf, washer turned to a wall | `faces_wall` | auto turn / choose |
| 75 | seats and tables without each other | `table_no_seat`, `bar_no_stool`, `mirror_no_chair`, `chair_alone`, `stool_alone` | report |
| 76 | item hovering over or sunk into furniture | `hovers`, `sunk_in` | auto / report |
| 77 | back door blocked; staff door not lined up | `door_blocked`, `staff_door_off` | choose / report |
| 78 | what the shop needs / what does not belong | `shop_lacks`, `shop_odd` (a DRAFT list, not approved) | report |
| 79 | sign board left blank | `sign_blank` | report |
| 80 | lights | `no_light`, `many_lights`, `low_light`, `light_in_prop` | report |
| 81 | wear under furniture or off the floor | `wear_under`, `wear_outside` | auto remove |
| 82 | two rooms with the same layout | `same_layout` | report |
| 83 | whether it reads as a real shop | by eye | - |
| new | thin wall between two shops; a prop through it | `thin_wall`, `shows_through` | report / auto |

## The files
| # | What | Kind |
|---|---|---|
| 84-86 | batch too wide, empty, building without its kit note | `wide_batch`, `empty_batch`, `no_kit_note`, `tier_count` |
| 87 | the layout file | `sc.py layout`: `layout_missing`, `layout_double`, `layout_offset`, `layout_unused` |
| 88 | the lock | printed with every check: "locked, the file is what was locked" or not |
| 89 | cost | printed with every check: draw batches and triangles of the near tier |

## What no check here sees (said with every result)
- Whether a prop makes sense where it stands and whether a room reads as a real shop: by eye (rows 50 and 83 only flag candidates).
- A tyre mark's CAUSE (a braking mark with no stop line): only its surface is checked.
- Street signs and pole cross-arms facing the right way; which end of an outdoor stair is its foot.
- Whether a face really stands under a high edge (row 3): the overlay piece is rebuilt from the same measure instead.
- Loose things closer than 0.5 m to a block edge (only things over the edge are found).
- Other things narrowing a walk beside the one measured.
- The newer kinds were tuned on two blocks: on other kinds of block expect false alarms until their pictures have been looked at.
