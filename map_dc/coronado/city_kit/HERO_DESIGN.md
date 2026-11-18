# Hero sites: the bridge landing and the ferry landing (17 Nov; Yasin: bridge option A, ferry landing "is a go")

Picture: `zoning/hero_sketch.png`, made by `tools/city/pilot/zoning/hero_sketch.py`. Grid frame: north is to the upper left. These are hand-made pieces, one of a kind, built after the road fleet.

## Bridge landing (the island's gateway)
**Facts:**
- The game's real bridge deck (OSM "4th Street" motorway) ends at the shore at grid (u 1180, v -905), 6.9 m up.
- Between the deck and the ring (Glorietta Blvd at u 660) lies the park at the bridge foot: u 640-1160, v -1440 to -1000.
- The ring junctions there sit at 2-4 m, so an approach climbs about 3 m over about 500 m, under 1 %.

**Option A (recommended): the bridge comes in on 4th St's axis.**
- **Approach:** a divided 2+2 approach (median palms, the island's welcome) curves through the park and meets the ring at 4th St (660, -1200).
- **The gateway junction:** a 4-way signal; 4th St carries on west as the two-way arterial.
- **Off-ramp:** a one-way branch for traffic coming off the bridge splits from the approach in the park, a smooth Y with a gore and chevrons, and joins the ring at 3rd St (660, -1400), making that a 4-way too.
- **Through the park:** paths cross under the ramps or at signalised crossings.
- **Gateway dress:** a sign, palms and lighting.
- **The skeleton's placeholder bridge node** (660, -1100) is not needed; the ring runs straight through there.
- **Why:** both arterials get bridge traffic as in the real town (3rd St off, 4th St both ways). No traffic has to run along Glorietta Blvd between them, and the gateway is one strong, readable junction.

**Option B (the skeleton placeholder):** one approach meets the ring at (660, -1100) as a T. Traffic then turns along Glorietta Blvd to reach 3rd or 4th. It's simpler, but the ring between them carries all the bridge traffic, and the gateway is just a T.

**Option C:** two one-way ramps like the real couplet: off-bridge to 3rd St, onto the bridge from 4th St. With our two-way arterials, it wastes 4th St's westbound lanes.

## Ferry landing (with the MUST museum)
- **Site:** between 1st St (the ring, v -1600) and the bay shore (v about -1750), u 180-480: about 150 m deep, flat, at about 0-2 m. The quay sits 1.5 m above the sea, as at the waterfront sample.
- **Plan:**
  - a ferry terminal with shops (the "Ferry Landing" marketplace)
  - the museum (maritime and naval air: kit pub_museum / civ_museum), facing a small plaza
  - a seawall promenade along the bay, with benches facing the San Diego skyline (what people watch)
  - the ferry pier and a float out into the bay (kit pier and marina pieces), fishing spots
  - a commuter lot on the west side
  - on 1st St: bus stops both ways, a taxi and drop-off bay, bike racks and a bike-rental rack
- **Wear:** salt grime on the seawall, gull marks on the bollards, worn paths from the drop-off to the pier, oil in the lot.

## Questions for Yasin
1. Bridge: option A (recommended), B or C?
2. Ferry landing: is the plan above right (terminal, museum, promenade, pier, lot)? Anything to add, such as a restaurant on the water, a park, or a bike path along the bay?

## Yasin's answers (17 Nov)
> "Bridge: A, but make sure that the resulting roads arent jagged like thse and curv esmoothly, that includes the
> shore above the bridge too, it looks like minecraft now. landing is a go"

**Smooth geometry** (`tools/city/pilot/zoning/hero_geom.py` -> `zoning/hero_geom.json`; the pieces sample these curves every 2 m):
- **Approach:**
  - 40 m straight off the deck, a reverse curve of two tangent circular arcs, R 234 m (68 deg each way), and 45 m straight into the 4th St signal
  - largest bend between successive 2 m points: 0.49 deg, i.e. a true circle
- **Off-ramp to 3rd St:**
  - a deceleration lane that tapers out with a smoothstep over 90 m to 12 m right of the approach (a planted gore between them)
  - then two tangent arcs, R 225 m and 224 m, and 35 m straight into the ring at 3rd St
  - worst bend 1.5 deg, within the taper
- **Coast:** the water edge is traced from the land-use grid and smoothed into a vector line (Gaussian, sigma 12 m), with no stair-steps. The terrain step bakes the WHOLE island's shore (classes, beach, seawall, sea floor) from such smooth lines, not from the 2.5 m grid.

## The whole island's coast (17 Nov): `tools/city/pilot/zoning/coast.py` -> `zoning/coast.json`, `zoning/coast.png`
- **Smoothing:** the sea and bay mask, plus everything inside the approved coast cut, is Gaussian-smoothed and traced into vector lines every 2 m.
  - sigma 12 m along the real coast
  - sigma 45 m within 250 m of the cut line, so Yasin's straight cut becomes a natural rounded beach
- **Ponds:** inland ponds (golf) keep sigma 4 m; specks under 600 m2 are dropped.
- **Result:** 2 sea lines (3,791 points) and 6 ponds.
- **The terrain step uses these lines,** not the 2.5 m grid, for the land-use classes, the beach, the seawall and the sea floor.
