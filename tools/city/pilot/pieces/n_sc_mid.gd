extends SceneTree
## Piece n_sc_mid (sc fill: the empty scraps inside the ring, 20 Nov; Yasin: "just fill the tiny spaces empty in the ring
## road", "fill them meaningfully without touching anything that already exists"). Placed at grid [0, 0, 0], yaw 0
## (x = u, y = world height, z = v). Run once.
## THREE SCRAPS round the stadium (edges and heights measured on the current city: n_sc_site.gd R4 / R5 / R7):
##  - STADIUM WALK WEST (R4, u -390.8 .. -305, v -409 .. -391): the unbuilt v -400 street line between the staff
##    townhouses (north) and the stadium shops (south). WHY: people walk from the residential street's junction (west) to
##    the stadium's perimeter drive (east); a street was never built, so a greenway: a 3 m path down the middle, lawn
##    each side, benches facing the path, globe lamps, bins at the ends, bollards where it meets the drive (no cars).
##  - STADIUM WALK EAST (R5, u -95 .. -16, the same line): from the stadium's drive to Amber's junction; the same
##    greenway, ending in a small paved forecourt at Amber with bike racks (people ride in from Amber on game days).
##  - FAN LINK (R7, u -209 .. -191, v -240 .. -209.2): the unbuilt u -200 line between the two fan plazas; paved through
##    as one plaza joining them, two planted beds, benches on the beds' edges, a drinking fountain, bins, lamps.
## LAND: 6.0 .. 6.2 here; the ground follows it and meets every neighbour's edge at its exact height (n_sc_site.g).
const K := preload("res://tools/city/pilot/kit_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_sc_site.gd")

## SUPERCHECKER deletions (sc.py check, 20 Nov; Yasin: "be much more prone to delete a prop"): every item with a finding is out, with the reason
const SC := {"out": [
	["prop_trash_receptacle", -387.5, -402.6, "superchecker bin_open: prop_trash_receptacle stands in the open (16.8 m from a wall, 82.8 m from a fence)"],
	["prop_trash_receptacle", -309.0, -397.4, "superchecker bin_open: prop_trash_receptacle stands in the open (33.9 m from a wall, 4.3 m from a fence)"],
	["prop_trash_receptacle", -24.5, -397.0, "superchecker bin_open: prop_trash_receptacle stands in the open (14.0 m from a wall, 70.8 m from a fence)"],
	["prop_trash_receptacle", -201.5, -213.0, "superchecker bin_open: prop_trash_receptacle stands in the open (36.0 m from a wall, 27.4 m from a fence)"],
	["prop_trash_receptacle", -198.5, -237.5, "superchecker bin_open: prop_trash_receptacle stands in the open (37.7 m from a wall, 3.7 m from a fence)"],
	["prop_park_bench", -375.0, -403.4, "superchecker no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -335.0, -403.4, "superchecker no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -355.0, -396.6, "superchecker no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -318.0, -396.6, "superchecker no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -80.0, -403.4, "superchecker no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -50.0, -403.4, "superchecker no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -65.0, -396.6, "superchecker no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -38.0, -396.6, "superchecker no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -207.0, -229.0, "superchecker no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -207.0, -221.0, "superchecker no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -193.0, -229.0, "superchecker no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -193.0, -221.0, "superchecker no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"]
]}

func _init() -> void: _run.call_deferred()

static func reg(x: float) -> String: return "r4" if x < -300.0 else ("r5" if x > -100.0 else "r7")

func _run() -> void:
	var root := Node3D.new(); root.name = "n_sc_mid"
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var yf := func(x: float, z: float) -> float: return S.g(reg(x), x, z)
	# ---- ground
	H.paint(g, -390.8, -409.0, -305.0, -391.0, [[-390.8, -401.5, -305.0, -398.5, "plaza"]], "grass", yf)
	H.paint(g, -95.0, -409.0, -16.0, -391.0, [[-95.0, -401.5, -16.0, -398.5, "plaza"], [-26.0, -409.0, -16.0, -391.0, "plaza"]], "grass", yf)
	H.paint(g, -209.0, -240.0, -191.0, -209.2, [[-206.0, -234.0, -202.5, -216.0, "mulch"], [-197.5, -234.0, -194.0, -216.0, "mulch"]], "plaza", yf)
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	# ---- STADIUM WALK WEST: benches facing the path, alternate sides; lamps along the north edge of the path; bins at
	#      the two ends; bollards across the east end where the path meets the stadium's drive
	for x: float in [-375.0, -335.0]: P.call("prop_park_bench", "worn", x, -403.4, 180.0)
	for x: float in [-355.0, -318.0]: P.call("prop_park_bench", "worn", x, -396.6, 0.0)
	for x: float in [-382.0, -362.0, -342.0, -322.0]: P.call("prop_lamp_globe", "worn", x, -402.3)
	P.call("prop_trash_receptacle", "worn", -387.5, -402.6); P.call("prop_trash_receptacle", "worn", -309.0, -397.4)
	for z: float in [-401.0, -400.0, -399.0]: P.call("prop_bollard_concrete", "worn", -306.0, z)
	P.call("prop_drinking_fountain", "worn", -348.0, -397.6, 0.0)
	for x: float in [-368.0, -328.0]: P.call("plant_bird_of_paradise", "normal", x, -406.0)
	for x: float in [-345.0, -312.0]: P.call("plant_agave_americana_small", "normal", x, -394.0)
	for x: float in [-372.0, -332.0]: P.call("prop_sprinkler_popup", "normal", x, -405.0, 0.0, false)
	# ---- STADIUM WALK EAST: the same greenway; the Amber forecourt with bike racks and a bin, bollards at the drive
	for x: float in [-80.0, -50.0]: P.call("prop_park_bench", "worn", x, -403.4, 180.0)
	for x: float in [-65.0, -38.0]: P.call("prop_park_bench", "worn", x, -396.6, 0.0)
	for x: float in [-88.0, -68.0, -48.0, -30.0]: P.call("prop_lamp_globe", "worn", x, -402.3)
	for z: float in [-401.0, -400.0, -399.0]: P.call("prop_bollard_concrete", "worn", -94.0, z)
	P.call("prop_bike_rack", "worn", -21.0, -406.0, 90.0); P.call("prop_bike_rack", "worn", -21.0, -394.0, 90.0)
	P.call("prop_trash_receptacle", "worn", -24.5, -397.0)
	for x: float in [-74.0, -44.0]: P.call("plant_bird_of_paradise", "normal", x, -406.0)
	for x: float in [-58.0, -32.0]: P.call("plant_agave_americana_small", "normal", x, -394.0)
	for x: float in [-72.0, -46.0]: P.call("prop_sprinkler_popup", "normal", x, -405.0, 0.0, false)
	# ---- FAN LINK: benches on the beds' outer edges facing the walk between them, fountain and bins on the walk,
	#      lamps at the plaza's ends, planting in the beds
	P.call("prop_park_bench", "worn", -207.0, -229.0, -90.0); P.call("prop_park_bench", "worn", -207.0, -221.0, -90.0)
	P.call("prop_park_bench", "worn", -193.0, -229.0, 90.0); P.call("prop_park_bench", "worn", -193.0, -221.0, 90.0)
	P.call("prop_drinking_fountain", "worn", -200.0, -237.0, 0.0)
	P.call("prop_trash_receptacle", "worn", -201.5, -213.0); P.call("prop_trash_receptacle", "worn", -198.5, -237.5)
	P.call("prop_lamp_globe", "worn", -200.0, -233.0); P.call("prop_lamp_globe", "worn", -200.0, -217.0)
	for z: float in [-231.0, -225.0, -219.0]: P.call("plant_bird_of_paradise", "normal", -204.2, z)
	for z: float in [-231.0, -225.0, -219.0]: P.call("plant_bougainvillea_mound", "normal", -195.8, z)
	H.sc_apply(root, props, dec, SC)
	H.finish(root, g, props, dec, "n_sc_mid")
	quit()
