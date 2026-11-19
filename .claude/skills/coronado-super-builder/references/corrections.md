# Yasin's corrections, in his words, and the rule each became

Collected from the four zone sessions (branches `claude/grow-residential`, `grow-gritty`, `grow-industrial`,
`grow-strip`, 18-19 Nov 2026) and the 19 Nov rescue session. "Check" names the checker kind that catches it; "eye"
means no check exists and it must be looked at.

## How to work
| His words | The rule |
|---|---|
| "although i explicitly told them not to use a generato, and hand place things, they still did" | No generators. One piece at a time, by hand. |
| "each thing i found by eye and told them to fix ended up as whole quarters being regenerated from scratch" | A fix changes the one thing pointed at, in one piece. |
| "they break much faster than i can catch and always give false positive all pass reports" | Say what a check cannot see. Never present zeros as proof. |
| "half of your work is sunk and you kept sending zero failure reports" | Check ground against the land before anything else. |
| "i didnt tell you to do anything yet" | A complaint or a question is not a go-ahead. |
| "lock them for now. rest is piece by piece correction" / "rest will be handmade adjustments" | After a lock: one piece at a time, each with his word. |
| "act as architect, road / city planner and exterior designer" outdoors; "look from the perspective of interior designer and the customers" indoors | Every prop has a reason where it stands. |
| "do out and indoors together ... i want the shops to look different" | Each shop's room with its building; each zone its own character. |
| "you are not limited to unused buildings or props only, but when you are done make sure that youve used every prop and buildings that makes sense in your part" | End with a kit-usage count; list what fits but is unused. |
| "upgrade the checker with my corrections" | Every class of fault he finds becomes a check, proved on the faulty case. |
| "i didnt see almost any of them, send detailed in and outdoor shots with birds eye view with each quadrant and one more for the entire zone" | Per-block sheets (bird's eye, low view, both streets, every shop inside and front, named) plus whole-zone views. |

## Ground
| His words | The rule | Check |
|---|---|---|
| "Many areas are sunk in too... I think these validators and checkers don't do what they are supposed to do" | Block ground against the land, point by point. | `ground_check.py` |
| "make sure all land is under blocks but blocks dont float too" | Land 5 cm under every piece; no block edge standing over the land beside it. | `ground_check.py` buried / hanging |
| "lower the land in the places that go above the blocks" | No bank of land standing over a block beside it. | `lower_land_to_pieces.py --ease-from` |
| "floor is broken, grass underneath shows", "surface isnt even anymore", "how is this seam fixed?" | A block's edge takes its neighbour's measured height; two new blocks share one line; skirt under every edge. | seam probe, low shots |
| "shop is sunk" | Level pad under every building on a slope, at its street-front level. | eye |
| "wall bulges off the ground" | A fence or wall panel on a slope stands at the lowest ground along its length. | eye |
| "no jagged edges", "smooth heights, no jumps" | Smooth land, smooth coast, no steps except kerbs. | eye |

## Outdoor props and wear
| His words | The rule | Check |
|---|---|---|
| "there is asphalt wear on the grass" | Wear marks only on the surface they belong to; nothing on grass or mulch; nothing over a block edge. | eye (no audit yet) |
| tyre marks (19 Nov list) | On asphalt at traffic lights, crosswalks, stop bars and in front of garages only; never in back yards. | eye |
| "slides shouldnt be on asphalt" | Play items on a bark / sand / rubber pad. | eye |
| "parks are too empty, there is only a slide" | A park: level play pad with 3+ play items, benches facing the play, picnic tables each under its own sail, a grill, fountain, beds along the fence, 4-5 trees, lamps. | eye (`check_life` LIFE_INFO density) |
| "there is a trash bin in the middle of the way" | Nothing on a path; bins against a wall, counter end or fence. | `check_life` path |
| "utility poles are on asphalt" | Poles in the rear easement or on a gravel pad; never on asphalt, never before a garage door. | `check_life` pole |
| "most of the houses fences dont enclosure their back yard and dont touch their back walls" | Every back yard closed: returns from the house's back corners, lot-line fences, back fence with a gate. | `check_life` fence |
| "this metal fence doesnt lead to anywhere" | Every fence end meets a fence, a gate or a wall. | `check_life` fence |
| "prop in the glass", "prop sitting on a window" | Wall items slide clear of every opening or are left out; window ACs sit in a real window. | `check_life` glass |
| "prop overlaps on the wall", "props overlap on the gate" | Services (meters, boxes, AC) 0.35 m off doors and rollups, 0.9 m off windows. | `check_life` glass |
| "something blocking the door" | Sidewalk furniture well away from doors, more than the validator's 1.55 m. | `validate` door + eye |
| "pot in front of interaction zone" | Nothing in front of a walk-up window; kiosks get no door dressing. | eye |
| "ice fridge on peds way" | Vending and ice in an alcove against a side wall, off the walk. | eye |
| "golf car in the stairs" | Nothing under or in front of stairs. | eye |
| "why are those table and chairs there?" | A prop whose reason is not obvious from the picture goes. | eye |
| "picnic table sits next to a stray bench" | A picnic table has its seats; a bench faces a path, a green or a view. | eye |
| "fire hydrant in the middle of nowhere" | Hydrants and hose reels within 2 m of a building wall. | eye |
| "what are those wooden pieces on the road" | Place buildings by their real mesh outline (a marina office's 20 m jetty lay across 1st St). | eye |
| "Are these bike racks? If yes they shouldn't block the pedestrian ways" | Racks beside the walk, not on it. | eye |
| "Trees look like copy pasted now" | Vary tree kinds, sizes and turns. | eye |
| (16 Nov) "looks terrible" | No grass tufts (`plant_lawn_patch`), no square dry mats. | eye |

## Rooms
| His words | The rule | Check (`check_rooms.gd`) |
|---|---|---|
| "many on the wall props overlap, some of them are on windows, some of them are inside the ceiling" | One fit check for every hung item: under the ceiling, clear of openings at any height, of other wall items, of furniture. | ceiling, window, wallover, behind |
| "this thing is overlapping the door" | A wall item never over a door or window. | window |
| "there is a painting behind the mirror" | Nothing hung behind furniture against that wall. | behind |
| "it looks as if you just filled every wall with paintings, its too repetitive" | At most 2 decorations a wall, 6 a room. | deco |
| "there are wall props contacts but themselves arent there" | Frame backs on shared walls inset 0.12 m. | eye |
| "what are those shops filled with vending machines?" | Caps: vending 1, brochure racks 2, fridges 4. | repeat |
| "why is there a filing cabinet in the middle of nowhere", "the bin is in the middle of the room" | Free-standing items against a wall or with their desk. | lone |
| "chair is facing the wrong direction" | Chairs face their desk / counter; no seat faces a wall. | face |
| "there isnt room for benches for people to sit, table is pushed all the way against them" | Leg room in front of every seat. | seat |
| "lube room bench looking out looks awkward put it back" | No waiting bench facing a window at arm's length. | outseat |
| "whats the shop on the left? trash store? it has 3 trash bins inside" | Bins are a small share of a room; a recycling booth's bins are outside. | binshop |
| "most shelves are empty", "cant you fill the shelves with props?" | Stocked shelves; swap models the kit ships empty. | bare |
| "whats that thing flying there?" | Size built parts to what was placed; every part held. | unheld, floating |
| "remove all of the cages, they arent prison cells" | Gritty = run-down and crowded, not a prison. Ask before a heavy motif. | eye |
| "a thick seam like object" (a bulkhead across a door) | No room geometry in a door's passage. | doorway |
| "why doesnt isla bistro have indoors?" | Load only the rooms you shoot; name what you show. | - |
| "nothing indoors is in correct place now" (19 Nov, after 150 rooms + the 12 hand-made rooms were rebuilt in one commit, b2f736ee) | Never rebuild rooms in bulk. The earlier version of every room is in git: restore a room with a copy of its old file. | - |

## What a shop needs (by eye; no check exists)
The counter or desk in view from the door, with staff space behind and a queue space in front, in every one. Then:
| Kind | Must have | Does not belong |
|---|---|---|
| Cafe / coffee | counter with machine and till, menu board, pastry case, tables with chairs, bin by the door, a window seat | shelving aisles, more than one fridge in the room |
| Diner / fast food | service counter, menu over it, booths or tables, drinks fridge, kitchen behind a partition | shop shelves |
| Corner market | till by the door, aisles of stocked shelves 0.9-1.0 m apart, drinks fridges on a wall, papers by the door | seating groups |
| Laundromat | rows of machines on walls, folding tables, waiting seats facing the machines, a change machine, a bin | counter cages, shelves of goods |
| Barber / salon | mirror stations each with its chair facing the mirror, waiting seats, a small till desk | anything hung behind a mirror |
| Pawn / thrift | glass counter, wall shelves, floor stock of mixed goods (bikes, tools, boards), notices | a cage |
| Book / gift shop | shelves on walls, a table display in the window, till, a reading seat | fridges |
| Repair / tyre / lube | service counter, waiting seats facing the room, parts shelves behind the counter, work bay beyond a partition | soft furnishing in the bay |
| Office (tax, credit union, movers) | front desk, desks each with a chair facing it, filing against walls, waiting seats | loose cabinets mid-room |
| Bar | bar with stools, back bar with bottles, tables, warm light | fluorescent tubes, vending |
| Clinic / urgent care | reception desk, waiting rows, leaflet rack, a partition to the rooms behind | shop shelving |
| Motel office | desk with key board behind, two seats, brochure rack (one), ice / vending outside in an alcove | vending inside |
| Gym | reception, equipment in rows with walking space, mirrors on a wall, benches | shelves of goods |
Zone character: gritty rooms are worn and crowded with mismatched chairs and fluorescent tubes (warm light only in
bars and diners); strip rooms are chain-like and bright; industrial rooms are plain counters and work space; the
residential corner shops are small and neighbourly.
