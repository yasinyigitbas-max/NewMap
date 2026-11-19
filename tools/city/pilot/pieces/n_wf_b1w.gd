extends SceneTree
## Piece n_wf_b1w (waterfront fill, block 1 WEST: grid u 259.2-331, between Pier St (v 209.2) and the ring (v ~327-330)).
## Yasin 19 Nov: "two blocks next to water front will be waterfront area, not residental"; the proposal he answered
## ("hotel is good, there arent any landmarks there"): Pier St front stepping down to the pier, visitor parking tucked
## behind, holiday flats and cottages on the ring, a walk through to the beach.
##
## WHO COMES HERE AND WHY (city planner): Pier St is the way from town down to the pier and the beach; this west end is
## its quiet top, 6 m above the water, where people stay and set off: the Casa del Mar inn on the B Ave corner (guests
## arrive by car from B Ave, walk down to the beach), a bakery-coffee bar for the morning crowd, the bike hire that sends
## them down Pier St. Behind them the visitor lot (entered from the two driveway openings the streets already have: Pier
## St at u 304-310, B Ave at v 254-260). Behind the lot two blocks of holiday flats face the Beach Walk, a public lane
## that runs the length of the block down to Beach Lane and the sand; south of the lane holiday cottages face the ring.
##
## THE GROUND (land first): Pier St's walk falls 6.15 -> 5.11 m along this piece, B Ave's 6.15 -> 4.15, the ring's
## 4.15 -> 3.47; the land inside lies within 0.3 m of the harmonic fill of those edges (wf_fill_ground.py). Level pads,
## each at the street-front height of what stands on it; a retaining wall wherever two pads meet:
##   inn 6.15 | bakery 6.02 | bike hire 5.86 | drive ramp 5.73 -> 4.90 (3.3 %) | grill with its dining deck 5.47
##   lot 4.90 (B Ave ramp 5.47 -> 4.90, 4.3 %) | flats 4.60 | Beach Walk 4.41 -> 4.00 | cottages 4.15 / 4.15 / 4.08 / 3.95 / 3.78
##   a 2 m strip at the seam with n_wf_b1m (u 329-331) follows the base field, so both pieces share one height line.
## Run: GROUND_ONLY=1 for the ground alone (first check), then without. A draft until Yasin has seen it; never when locked.
const F := preload("res://tools/city/pilot/pieces/wf_fill_lib.gd")

## the ring's walk edge (a straight line on this stretch, measured) and the front of the 2 m band along it
static func ring_v(u: float) -> float: return 330.27 - (u - 259.2) * 0.045497
static func ring_band(u: float) -> float: return ring_v(u) - 2.05

func _init() -> void: _run.call_deferred()
func _run() -> void:
	var b := F.new("n_wf_b1w")
	ground(b)
	if OS.get_environment("GROUND_ONLY") == "1":
		b.finish(true); quit(); return
	b.finish()
	quit()

func ground(b: F) -> void:
	b.band = 2.0
	# ---- Pier St front: one pad per building at its front's walk height (pads run back to v 230, the lot's edge)
	b.terrace(261.2, 211.2, 283.5, 230.0, 6.15, "wall", 0, "inn")
	b.terrace(283.5, 211.2, 295.5, 230.0, 6.02, "wall", 0, "bakery")
	b.terrace(295.5, 211.2, 303.5, 230.0, 5.86, "wall", 0, "bike hire")
	b.terrace(310.5, 211.2, 329.0, 230.0, 5.47, "wall", 0, "grill + dining deck")
	# ---- the visitor lot and the flats behind it
	b.terrace(261.2, 230.0, 331.0, 266.0, 4.90, "wall", 0, "lot (upper level)")
	b.terrace(261.2, 266.0, 329.0, 294.0, 4.60, "wall", 0, "holiday flats")
	# ---- cottages on the ring: each pad at its front walk's height, from the Beach Walk to the ring's band
	b.terrace(261.2, 298.0, 273.0, ring_band(273.0), 4.15, "wall", 0, "cottage 1")
	b.terrace(273.0, 298.0, 285.0, ring_band(285.0), 4.15, "wall", 0, "cottage 2")
	b.terrace(285.0, 298.0, 299.0, ring_band(299.0), 4.08, "wall", 0, "cottage 3")
	b.terrace(299.0, 298.0, 311.0, ring_band(311.0), 3.95, "wall", 0, "cottage 4")
	b.terrace(311.0, 298.0, 323.0, ring_band(323.0), 3.78, "wall", 0, "cottage 5")
	# ---- ramps (drawn after the pads: a slope wins over a pad where both lie)
	b.ramp(303.5, 211.2, 310.5, 236.0, "v", 5.73, 4.90, true)          # Pier St driveway down into the lot
	b.ramp(261.2, 253.5, 275.0, 260.5, "u", 5.47, 4.90, true)          # B Ave driveway (its apron at v 254-260)
	b.ramp(261.2, 294.0, 331.0, 298.0, "u", 4.41, 4.00)                # the Beach Walk, falling east to the beach
	# ---- surfaces of the ground (paint), first match wins
	b.paint(329.0, 230.0, 331.0, 294.0, "grass")                       # seam strip beside the flats
	b.paint(261.2, 211.2, 283.5, 214.0, "plaza")                       # inn forecourt
	b.paint(283.5, 211.2, 303.5, 214.0, "concrete")                    # shop forecourts
	b.paint(310.5, 211.2, 329.0, 214.0, "concrete")
	b.paint(324.5, 214.0, 329.0, 228.0, "plaza")                      # the grill's dining deck
	b.paint(329.0, 211.2, 331.0, 230.0, "mulch")                       # planted gap at the seam
	b.paint(261.2, 214.0, 283.5, 230.0, "grass")                       # inn garden (the building stands on it)
	b.paint(261.2, 260.5, 331.0, 266.0, "grass")                       # planted strip between the lot and the flats
	b.paint(261.2, 266.0, 329.0, 294.0, "grass")                       # flats' gardens
	b.paint(261.2, 294.0, 331.0, 298.0, "plaza")                       # Beach Walk
	b.paint(261.2, 298.0, 329.0, 340.0, "grass")                       # cottage gardens
	b.paint(323.0, 298.0, 331.0, 340.0, "concrete")                    # the footpath down to the ring
