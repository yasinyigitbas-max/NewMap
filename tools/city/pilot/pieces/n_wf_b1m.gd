extends SceneTree
## Piece n_wf_b1m (waterfront fill, block 1 MIDDLE: grid u 331-404, between Pier St and the ring).
## WHO COMES HERE AND WHY: the middle of Pier St, where the walk down to the pier gets busy: an ice-cream parlour with a
## swimwear shop and a gift shop in one row, the Pier Steps (a public ramp from Pier St down into the lot and on to the
## Beach Walk: the way drivers walk to the pier), the Tide Bar with its raised deck, and the dive & surf row. Behind: the
## middle of the visitor lot (its ramps take cars down from the upper level), holiday flats, the Beach Walk, cottages.
## THE GROUND: Pier St falls 5.11 -> 2.72 m here, the ring 3.47 -> 1.92. Pads:
##   ice cream row 4.67 | Pier Steps ramp 4.27 -> 3.60 (3.5 %) | Tide Bar with deck 3.88 | dive & surf row 3.17
##   lot: upper level 4.90 continues to u 343, ramps on both aisles 4.90 -> 3.60 (8.1 %), lower-middle level 3.60;
##   planted beds beside the ramps at 3.60 | flats 3.45 | Beach Walk 4.00 -> 2.55 | cottages 3.35 / 2.92 / 2.65 / 2.38 / 2.10
##   2 m strips at both seams follow the base field (shared height lines with n_wf_b1w and n_wf_b1e).
## Run: GROUND_ONLY=1 for the ground alone (first check), then without. A draft until Yasin has seen it; never when locked.
const F := preload("res://tools/city/pilot/pieces/wf_fill_lib.gd")

static func ring_v(u: float) -> float: return 330.27 - (u - 259.2) * 0.045497
static func ring_band(u: float) -> float: return ring_v(u) - 2.05

func _init() -> void: _run.call_deferred()
func _run() -> void:
	var b := F.new("n_wf_b1m")
	ground(b)
	if OS.get_environment("GROUND_ONLY") == "1":
		b.finish(true); quit(); return
	b.finish()
	quit()

func ground(b: F) -> void:
	b.band = 2.0
	# ---- Pier St front
	b.terrace(333.0, 211.2, 356.0, 230.0, 4.67, "wall", 0, "ice cream row")
	b.terrace(360.0, 211.2, 378.0, 230.0, 3.88, "wall", 0, "Tide Bar + deck")
	b.terrace(378.0, 211.2, 401.0, 230.0, 3.17, "wall", 0, "dive & surf row")
	# ---- the lot: upper level (from n_wf_b1w) to u 343, lower-middle level beyond; beds beside the ramps
	b.terrace(331.0, 230.0, 343.0, 266.0, 4.90, "wall", 0, "lot upper level")
	b.terrace(343.0, 230.0, 404.0, 266.0, 3.60, "wall", 0, "lot middle level")
	b.terrace(333.0, 266.0, 401.0, 294.0, 3.45, "wall", 0, "holiday flats")
	b.terrace(333.0, 298.0, 355.0, ring_band(355.0), 3.35, "wall", 0, "holiday flats on the ring")
	b.terrace(355.0, 298.0, 366.0, ring_band(366.0), 2.92, "wall", 0, "cottage 6")
	b.terrace(366.0, 298.0, 378.0, ring_band(378.0), 2.65, "wall", 0, "cottage 7")
	b.terrace(378.0, 298.0, 392.0, ring_band(392.0), 2.38, "wall", 0, "cottage 8")
	b.terrace(392.0, 298.0, 401.0, ring_band(401.0), 2.10, "wall", 0, "cottage 9")
	# ---- ramps
	b.ramp(356.0, 211.2, 360.0, 230.0, "v", 4.27, 3.60)                 # the Pier Steps (a ramp: prams, bikes, beach carts)
	b.ramp(343.0, 235.5, 359.0, 242.5, "u", 4.90, 3.60, true)           # aisle 1 down a level
	b.ramp(343.0, 253.5, 359.0, 260.5, "u", 4.90, 3.60, true)           # aisle 2 down a level
	b.ramp(331.0, 294.0, 404.0, 298.0, "u", 4.00, 2.55)                 # the Beach Walk
	# ---- surfaces
	b.paint(331.0, 230.0, 333.0, 294.0, "grass"); b.paint(401.0, 266.0, 404.0, 294.0, "grass")
	b.paint(331.0, 211.2, 333.0, 230.0, "mulch")
	b.paint(401.0, 211.2, 404.0, 230.0, "mulch")
	b.paint(333.0, 211.2, 401.0, 214.0, "concrete")
	b.paint(356.0, 211.2, 360.0, 230.0, "plaza")
	b.paint(371.5, 214.0, 378.0, 228.0, "plaza")                       # the bar's deck
	b.paint(343.0, 230.0, 359.0, 235.5, "mulch"); b.paint(343.0, 242.5, 359.0, 253.5, "mulch")   # beds beside the ramps
	b.paint(331.0, 260.5, 404.0, 266.0, "grass")
	b.paint(331.0, 266.0, 404.0, 294.0, "grass")
	b.paint(331.0, 294.0, 404.0, 298.0, "plaza")
	b.paint(331.0, 298.0, 404.0, 340.0, "grass")
