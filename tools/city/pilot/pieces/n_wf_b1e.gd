extends SceneTree
## Piece n_wf_b1e (waterfront fill, block 1 EAST: grid u 404 to the ring's corner at u 560.8, with Beach Lane - the
## strip u 470-560.8, v 300-322 between the sample's beach parking (f_nw, locked) and the ring).
## WHO COMES HERE AND WHY: the bottom of Pier St, 50 m from the pier plaza: the Fish House (the seafood place, with a
## deck to eat on), a bait & tackle shop for the people who fish off the pier, the surf shop, and a kayak / SUP hire
## kiosk at the corner by the sample. Behind them the lowest level of the visitor lot, a small playground with picnic
## tables for beach families, the end of the Beach Walk and BEACH LANE: palms, benches, a shower, bike racks and a rental
## stand, the walk the whole block uses to get to the sand (it meets the street corner across from the beach).
## THE GROUND: Pier St falls 2.72 -> 1.50 m, the ring 1.92 -> 1.50, the sample's quadrant f_nw is flat at 1.50. Pads:
##   Fish House with deck 2.25 | bait & tackle 1.67 | surf shop 1.54 | kiosk 1.50
##   lot middle level 3.60 to u 420, ramps on both aisles 3.60 -> 2.30 (8.1 %), lower level 2.30 (a planted wall at its
##   east end, down to the field at 1.5) | holiday flats 2.25 | playground 1.60 | Beach Walk 2.55 -> 1.50
##   cottages 1.85 / 1.68 / 1.55 | Beach Lane: the base field, 1.50 (flat).
## Run: GROUND_ONLY=1 for the ground alone (first check), then without. A draft until Yasin has seen it; never when locked.
const F := preload("res://tools/city/pilot/pieces/wf_fill_lib.gd")

static func ring_v(u: float) -> float: return 330.27 - (u - 259.2) * 0.045497
static func ring_band(u: float) -> float: return ring_v(u) - 2.05

func _init() -> void: _run.call_deferred()
func _run() -> void:
	var b := F.new("n_wf_b1e")
	ground(b)
	if OS.get_environment("GROUND_ONLY") == "1":
		b.finish(true); quit(); return
	b.finish()
	quit()

func ground(b: F) -> void:
	b.band = 2.0
	# ---- Pier St front
	b.terrace(405.5, 211.2, 441.0, 230.0, 2.25, "wall", 0, "Fish House + deck")
	b.terrace(441.0, 211.2, 453.5, 230.0, 1.67, "wall", 0, "bait & tackle")
	b.terrace(453.5, 211.2, 465.0, 230.0, 1.54, "wall", 0, "surf shop")
	# ---- the lot: middle level (from n_wf_b1m) to u 420, lower level beyond
	b.terrace(404.0, 230.0, 420.0, 266.0, 3.60, "wall", 0, "lot middle level")
	b.terrace(420.0, 230.0, 464.0, 266.0, 2.30, "wall", 0, "lot lower level")
	b.terrace(405.5, 266.0, 438.0, 294.0, 2.25, "wall", 0, "holiday flats")
	b.terrace(442.0, 268.0, 466.0, 292.0, 1.60, "wall", 0, "playground + picnic")
	b.terrace(405.5, 298.0, 417.0, ring_band(417.0), 1.85, "wall", 0, "cottage 10")
	b.terrace(417.0, 298.0, 429.0, ring_band(429.0), 1.68, "wall", 0, "cottage 11")
	b.terrace(429.0, 298.0, 441.0, ring_band(441.0), 1.55, "wall", 0, "cottage 12")
	# ---- ramps
	b.ramp(420.0, 235.5, 436.0, 242.5, "u", 3.60, 2.30, true)
	b.ramp(420.0, 253.5, 436.0, 260.5, "u", 3.60, 2.30, true)
	b.ramp(404.0, 294.0, 470.0, 298.0, "u", 2.55, 1.50)                 # the Beach Walk, on into Beach Lane
	# ---- surfaces
	b.paint(404.0, 266.0, 405.5, 294.0, "grass")
	b.paint(404.0, 211.2, 405.5, 230.0, "mulch")
	b.paint(405.5, 211.2, 470.0, 214.0, "concrete")
	b.paint(431.0, 214.0, 441.0, 228.0, "plaza")                       # Fish House deck
	b.paint(420.0, 230.0, 436.0, 235.5, "mulch"); b.paint(420.0, 242.5, 436.0, 253.5, "mulch")
	b.paint(404.0, 260.5, 466.0, 266.0, "grass")
	b.paint(405.5, 266.0, 442.0, 294.0, "grass")
	b.paint(442.0, 268.0, 466.0, 292.0, "sand")                          # play pad: sand under the play things
	b.paint(404.0, 294.0, 470.0, 298.0, "plaza")
	b.paint(405.5, 298.0, 441.0, 340.0, "grass")
	b.paint(441.0, 266.0, 562.0, 340.0, "plaza")                         # the lane's end and Beach Lane
	b.paint(464.0, 230.0, 470.0, 266.0, "grass")                        # bank below the lot's east wall
