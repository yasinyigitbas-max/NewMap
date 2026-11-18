# Zoning map (APPROVED and LOCKED 17 Nov, Yasin: "do 1")

Picture: `zoning/zoning_map.png`. Made by `tools/city/pilot/zoning/render.py`. Positions, hills and zone areas are in
`plan.py` and `zones.py`; `chk.py` checks grades and the flat pads.

**Rule (Yasin, 17 Nov): the samples we made sit on flat ground, and elevation goes only into the transitions and extensions,
so no existing part needs rework.**

## Yasin's answers on draft 1
- **Crown Hill: yes.**
- **Pilot is NOT flat and is NOT reworked.**
  - Its high street (west of x 40) is flat.
  - Its hill rows climb +5.9 m to x 150, as built and locked.
  - Glorietta Heights continues that rise exactly, so the pilot fits as it is.
  - Draft 1's label "flat" was wrong.
- **Coast cut (red line, south of the hotel, from the ocean beach to the waterfront quay's south end):**
  - Everything south of it becomes sea: the Silver Strand, the Shores, the amphibious base. Polygon `CUT` in `plan.py`.
  - Coronado is now an island, reached by the bridge and the ferry.
  - The Shores towers and the Strand strip extension are dropped.
  - The new shore gets a rounded beach and a seawall (no straight edge), done in the terrain step.
  - The game's terrain and roads south of the line are removed at integration (terrain classes + lane graph).

## Frame
- **Grid frame:**
  - origin: Amber x 10th (world -1757, 3296)
  - u: along 10th, toward ESE (= the pieces' +x)
  - v: along Amber, toward SSW (= the pieces' +z)
  - Amber's bearing is 26 deg, as in the README.
- **Street spacing:** OSM numbered streets are about 176 m apart along v (1st at v -1590, 10th at v 0). The lettered avenues are about 85 m apart along u.
- **Base map:** only the OSM road layer (`map_dc/roads/lane_graph.json`), plus the terrain height and land-use classes.

## Locked samples: where they go (u, v, yaw)

| Sample | Position | Why there | Real ground under it | Pad |
|---|---|---|---|---|
| Pilot (high street + hill rows) | (0, 0), Amber x 10th | already planned in the README; the main street toward the hotel | 6.6-8.0 | 7.1, plus its own built rise of +5.9 m to the east |
| City centre | (0, -560), Amber x 7th | flat middle of town, at the foot of Crown Hill | 8.0-9.1 | 8.7 |
| Apartment band | (300, -560) | between the centre and the east houses | 8.5-10.3 | 9.9 |
| Civic + parks + stadium | (-300, -660) | civic heart next to the centre; the stadium's lots face the campus | 6.1-8.4 | 7.3 |
| Gritty edge | (-700, -1050) | on 4th St toward the base gate | 6.0-7.0 | 6.4 |
| Industrial | (-760, -1450) | by the naval air station and the bay (base contractors, marine supply) | 3.6-5.8 | 4.5 |
| Commercial strip | (520, -1130) | where the bridge traffic lands (3rd/4th couplet): gas, drive-thrus, motels | 5.4-7.3 | 6.1 |
| Waterfront | (570, 250), yaw 90 | west shore of Glorietta Bay (marina + bay beach), next to the hotel | 0-7.9 | quay 1.5 above the sea |

- **Pads:** each sample sits on a level pad with a 40 m flat margin around it. The pad is cut or filled at most 1.5 m (the waterfront: the ground behind its quay climbs back up).
- **Its own ground does not change.** The pilot keeps its built-in rise of +5.9 m at x 150. Glorietta Heights continues that rise exactly (0.00 m difference).

## Hills (invented, added on top of the real ground)

| Hill | Centre | Height | Steepest | Character |
|---|---|---|---|---|
| Crown Hill | (0, -1170) | +12 m | 6.3 % | The real 4-6 m dome around 3rd-5th St, raised: villas on top, apartments climbing the west slope, a chapel on the rise (hero). Amber and the 3rd/4th bridge route cross it at 6 % or less. |
| Glorietta Heights | (310, -110) | +7 m | 8.0 % (the pilot's own rise) | East of the pilot, continuing its hill rows; the Glorietta mansion (hero). |
| Country Club Ridge | (-640, 20) | +10 m | 5.3 % | West houses, running down to the beach and the park. |
| Bay Circle Knoll | (920, -330) | +8 m | 5.2 % | The peninsula inside the golf course, with bay views. |

All grades are 8 % or less (Yasin's pilot limit). Hills fade out over 40-220 m from every sample.

## Zone extensions
- **City centre:** Amber 6th-8th.
- **High street:** Amber 8th to the hotel.
- **Apartments:**
  - east of the centre
  - Crown Hill's west slope
- **Civic + parks:** around the civic sample.
- **University campus (MUST):** west of the stadium, which it shares; students live in the gritty edge next door.
- **Gritty edge:** 3rd-5th St west.
- **Industrial:** 1st-3rd St west, plus the base fringe.
- **Commercial strip:** the bridge corridor.
- **Waterfront:**
  - Glorietta Bay
  - the ocean promenade along the beach
  - the ferry landing
- **Residential:** everything else, as hill-row variants (the ~30 unused house types).

## MUST sites
- **Hospital:** 1st-2nd St east of the strip, on flat ground. ER and ambulances come off 3rd St (the bridge route), with a helipad.
- **University:** west of the stadium (see above).
- **Museum:** maritime and naval air, at the ferry landing.
- **Courthouse:** on the centre square, next to the police.

## Not decided / open
- **The caricature street grid:** samples are 204 m square, but Coronado's blocks are 85 x 176 m. Growth snaps the streets to the samples, never the reverse.
- **The Strand (trunk) used to cross the waterfront site:** after the cut, it ends at the waterfront's streets.
- **Golf courses, the naval air station and the park at the bridge foot stay as they are** (outside the city kit).

## Locked (17 Nov, Yasin: "do 1")
- **Locked files:** `tools/city/pilot/zoning/plan.py`, `zones.py`, `map_dc/coronado/city_kit/zoning/zoning_map.png`.
- **How the lock works:** the files are listed under "files" in `locked.json`. `lock.py lockfile` / `unlockfile` manages them, and the lock test checks them.
- **Positions:** the zoning map fixes the zones, the hills, the coast cut and the MUST sites. The sample positions in `plan.py` are approximate; the street skeleton (`STREETS.md`) snaps each sample onto its junction lattice and is the authority for exact positions. A snap moves a sample by about 100 m at most and does not change its zone.
