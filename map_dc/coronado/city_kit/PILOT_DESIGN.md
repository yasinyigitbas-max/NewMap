# Pilot: Amber Ave x 10th St (16 Nov 2026)

The first hand-made pieces of the block-kit city:
- one junction
- two street pieces
- four corner quadrants around them

Each piece is its own scene file. Once Yasin approves a piece it is locked (`locked.json` + test) and never regenerated.

## Site
- **Location:** the game's Amber Avenue (the main shopping street, 93 of today's 169 shop fronts) meets 10th Street at a signalized junction. World position about (-1752, 7.2, 3297). Amber runs at bearing 26 deg; the cross streets at 116 deg.
- **Caricature, not replica:** Amber gets real downtown density (2-4 storey street walls). 10th Street east of Amber is invented as a hill (Coronado is flat), so the residential side climbs.

## Local frame (all pieces)
- Origin = junction centre at street level.
- -Z = north along Amber, +X = east along 10th St, Y up.
- Placed in the world with one rotation (Amber bearing) + one offset. Everything is axis-aligned in this frame, so paint, kerbs and crosswalks are exact rectangles.

## Cross-sections (from centreline, metres)
| | Amber Ave (downtown, divided) | 10th St west (downtown) | 10th St east (residential, hill) |
|---|---|---|---|
| median | 0 - 2.5: raised, planted, queen palms every 12 m | - | - |
| lanes | 2.5 - 9.1: two 3.3 m lanes per direction | 0 - 3.3: one lane per direction | 0 - 3.3: one lane per direction |
| parking | 9.1 - 11.5: parallel stalls 6.7 m | 3.3 - 5.7: parallel | 3.3 - 5.7: parallel |
| kerb | at 11.5, 0.15 m high | at 5.7 | at 5.7 |
| sidewalk | 11.5 - 16.0. Furniture zone 1.5 m at the kerb (round tree wells, lamps, meters), 3 m walking zone | 5.7 - 9.7 | parkway (grass + street trees) 5.7 - 7.7, then sidewalk 7.7 - 9.2 |
| building line | 16.0, zero setback (street wall) | 9.7 | property line 9.2, houses set back 6 m |

## Junction (signalized; Amber is the major road)
- **Kerb returns:** 6 m radius downtown (short crossings, slow turns), 7.5 m on the residential side.
- **Crosswalks:** continental (ladder) bars on all four legs, 3 m wide, 1 m outside the junction box, lined up with the sidewalks they join.
- **Kerb ramps:** two directional ramps per corner, one aimed at each crosswalk, never one diagonal ramp into the junction.
- **Stop bars:** 0.6 m wide, 1.2 m behind each crosswalk.
- **Amber median:** ends in a nose 1 m before the crosswalk; pedestrians cross in one go (signal timed).
- **Lanes and arrows:**
  - Amber inner lane: left + through.
  - Amber outer lane: through + right.
  - 10th St: one shared lane, so no arrows; double yellow centre line on approach.
  - Lane lines dashed (3 m line / 9 m gap), solid for the last 20 m before the stop bar.
  - White edge line between the traffic and parking lanes, with T marks at stall ends.
  - No parking within 6 m of a crosswalk (sight line) or 4.5 m either side of a hydrant.
- **Signals, one pole per corner:**
  - Mast arms over Amber on the far-right corner of each Amber approach: SW for southbound, NE for northbound.
  - Post-mounted heads for 10th St on its far-right corners: SE for eastbound, NW for westbound.
  - Street name signs on the two corners without mast arms.
- **Drainage:**
  - Kerb inlets just upstream of the crosswalks, at the low side.
  - On the hill, water runs down 10th toward the junction, so inlets sit at the foot of the slope on both kerbs.
  - Manholes in the lanes every 60 m (sewer runs under the road).
- **Hydrants:** one at each of two diagonal corners, 1 m behind the kerb, clear of ramps.

## Street furniture logic (why each thing is where it is)
- **Lamps:**
  - Victorian post lamps downtown, every 24 m in the furniture zone, staggered with the trees so each tree sits between two lamps.
  - Cobra lamps on the residential hill, every 40 m, alternating sides.
- **Street trees:**
  - Jacaranda downtown (shade and purple colour) in round wells, trunk centred, every 12 m.
  - None within 10 m of a kerb return (drivers must see pedestrians), none in front of a door or a hydrant.
  - Magnolia and coral trees in the residential parkway, one per lot.
- **Parking meters:** one per stall at the stall line, 0.6 m from the kerb face. No meters on the residential hill (free parking).
- **Bus stops:** far side of the junction in both directions (buses stop after the light, not before it). A 25 m bus zone with no stalls and a no-parking sign.
  - Shelters stand at the back of the sidewalk, so the kerb side stays free for boarding.
  - Northbound: by the theatre, clear of its doors. Southbound: by the pocket park, where riders can wait on a bench.
- **Trash + recycling:** a pair at every downtown corner and mid-block, next to cafes and food places, never in a ramp's landing.
- **Benches:** facing the street under trees by cafes, and around the pocket park.
- **Bike racks:** by the cafe and bookshop.
- **Newspaper boxes:** two by the corner cafe.
- **Mail:** a USPS box by the post office.
- **Behind the shops:** a 6 m service alley.
  - Dumpsters behind each food place (bakery, bar, bistro), not behind the bank or boutiques.
  - Utility poles and transformers in the alley, so the main street has no overhead wires.
  - AC units on the roofs.
- **Pocket park (SW corner):**
  - Bandstand as the focal point, facing the junction.
  - Ring path, benches facing the bandstand, drinking fountain, globe lamps.
  - Magnolias, low boxwood hedge along the street edge (keeps the corner open to view, below 1 m).
- **Residential lots:**
  - 15 m wide; each house faces the street, with a walk from the sidewalk to the door (with steps where the lot sits above the street).
  - Driveway: the kerb drops, an apron crosses the parkway, the sidewalk stays level across it, then the driveway climbs to the garage.
  - House number on the wall; trash carts beside the garage (not at the kerb: it is not collection day).
  - Fences: white picket on the front of some lots, privacy fences between back yards.

## Slope (10th St east)
- **Profile:** the street is level up to x = 40, then rises along a smoothstep to +5.9 m at x = 150.
  - Maximum grade 8% at the mid-point.
  - The grade changes gradually, well inside the `tools/city/check_grades.py` limits.
- **Pavements:** sidewalks follow the street grade.
- **Lots:** each lot is a flat terrace at the height of its own frontage.
  - The difference to the sidewalk is taken up by a low retaining wall at the front.
  - Steps between neighbouring lots are walled along the side lot lines.
  - No building ever stands on a slope; no wall sinks into the ground.

## Buildings (from `assets/coronado_kit`)
- **NW (downtown, west of Amber, north of 10th):**
  - `urb_brick_corner` (4 storeys) on the corner.
  - Then along Amber: `com_orange_row`, `com_bakery`, `com_bar_crown`, `urb_brick_row`.
  - Along 10th: the corner building's side, then `com_shallow_cafe`.
- **NE (downtown, east of Amber, north of 10th):**
  - `com_spanish_arcade_block` on the corner.
  - `lmk_village_theatre` mid-block (the street's landmark, faced by the cafe across Amber).
  - `com_orange_arcade_block`.
- **SE:**
  - `civ_post_office` on the corner, set back 4 m behind a small paved forecourt (flagpole spot, benches, bike rack, USPS box).
  - Then `com_boutique_row`.
- **SW:**
  - Pocket park on the corner.
  - Then `com_bistro` with sidewalk tables, and `com_realty`.
- **Residential hill (both sides of 10th, east of the alley):** a mix of spanish / craftsman / beach / ranch houses with detached garages from `buildings/garages`. No two neighbours share a model.
