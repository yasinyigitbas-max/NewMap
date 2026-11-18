extends SceneTree
## Piece s_wf (waterfront sample, the south leg): where the town's main street meets the bay. No cars past the
## junction: the south approach ends at a row of bollards and becomes the pier plaza (paving, benches facing the water,
## Victorian lamps like the high street, bike racks along its edges, bins, planters, a life ring at each quay corner).
## The public pier runs out from the quay (kit pier root in the quay line, four 6 m straights, a T-head): lamps every
## 12 m on both rails, life rings, benches and bins on the T-head where people fish and watch the sunset, and off its
## west side a hinged gangway down to the water-taxi float with a skiff and a cruiser tied up.
## Water: records the whole bay of the sample as meta "water" (the preview draws it; the game has its own sea).
## Wear: salt-grey paving, grime round the benches and bins, gull-white on the bollards' tops (pale patches), a worn
## path down the pier's centre, rust under the lamps. Run once; never when locked.
const WF := preload("res://tools/city/pilot/pieces/wf_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const SL := preload("res://tools/city/pilot/pieces/strip_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var root := Node3D.new(); root.name = "s_wf"
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for("s_wf")
	var wy := WF.wy(); var QZ := WF.QZ
	# ---- plaza (z 20 .. quay coping at QZ - 2)
	var paints: Array = []
	paints.append([-9.2, 20.0, 9.2, 21.4, "concrete"])           # the kerb-side apron where the bollards stand
	K.painted_rect(g, -9.2, 20.0, 9.2, QZ - 2.0, paints, S.walk_y, "plaza")      # weathered stone ("paving" read near white)
	for k in 7: I.add(props, "prop_bollard_concrete", "worn", Vector3(-4.8 + k * 1.6, wy, 20.7), 0.0)   # across the lanes: cars stop here (the kerb inlets stay clear)
	for xs: float in [-1.0, 1.0]:
		I.add(props, "prop_lamp_victorian", "worn", Vector3(xs * 8.4, wy, 25.0), 90.0 * xs)
		I.add(props, "prop_lamp_victorian", "worn", Vector3(xs * 8.4, wy, 34.0), 90.0 * xs)
		I.add(props, "prop_park_bench", "worn", Vector3(xs * 5.5, wy, 35.6), 0.0)          # facing the water
		I.add(props, "prop_trash_receptacle", "dirty", Vector3(xs * 3.6, wy, 35.6), 0.0)
		I.add(props, "prop_bike_rack", "worn", Vector3(xs * 8.6, wy, 29.5), 90.0)           # parallel to the plaza edge
		I.add(props, "plant_potted_leafy", "normal", Vector3(xs * 8.3, wy, 22.4), 0.0)
		I.add(props, "prop_lifering_stand", "worn", Vector3(xs * 8.2, wy, QZ - 1.3), 0.0)      # behind the railing, reachable
		dec.add(14, Vector2(xs * 5.5, 36.3), 0.0, 2.4, 1.6, S.walk_y, Color(1, 1, 1, 0.5))   # feet under the benches
		dec.add(14, Vector2(xs * 3.6, 35.6), 0.0, 1.2, 1.2, S.walk_y, Color(1, 1, 1, 0.6))   # round the bin
	I.add(props, "prop_drinking_fountain", "worn", Vector3(-2.2, wy, 22.6), 0.0)
	I.add(props, "prop_newspaper_box_blue", "worn", Vector3(2.4, wy, 22.4), 0.0)
	# ---- quay line under the plaza: the pier root between two plain modules; railing either side of the pier
	WF.quay(props, "straight", -6.0); WF.quay(props, "pier_root", 0.0); WF.quay(props, "straight", 6.0)
	WF.rail_run(props, -9.0, -2.4); WF.rail_run(props, 2.4, 9.0)
	# ---- the pier: four straights and the T-head (kit snap: straights at root + 4, 10, 16, 22; T-head at + 28)
	var root_z := QZ - 1.0
	for k in 4: I.add(props, "prop_pier_straight", "worn", Vector3(0.0, WF.bed(), root_z + 4.0 + k * 6.0), 0.0)
	var tz := root_z + 28.0
	I.add(props, "prop_pier_thead", "worn", Vector3(0.0, WF.bed(), tz), 0.0)
	for zl: float in [QZ + 6.0, QZ + 18.0]:
		for xs2: float in [-1.0, 1.0]: I.add(props, "prop_pier_lamp", "worn", Vector3(xs2 * 1.85, wy, zl), 0.0)
	for c: Vector2 in [Vector2(-5.7, tz - 2.6), Vector2(5.7, tz - 2.6), Vector2(-5.7, tz + 3.0), Vector2(5.7, tz + 3.0)]:
		I.add(props, "prop_pier_lamp", "worn", Vector3(c.x, wy, c.y), 0.0)
	I.add(props, "prop_lifering_stand", "worn", Vector3(1.8, wy, QZ + 12.0), -90.0)
	I.add(props, "prop_lifering_stand", "worn", Vector3(5.6, wy, tz + 0.2), -90.0)
	for bx: float in [-2.6, 2.6]: I.add(props, "prop_park_bench", "worn", Vector3(bx, wy, tz + 2.2), 0.0)    # facing the bay
	I.add(props, "prop_trash_receptacle", "dirty", Vector3(0.0, wy, tz + 2.4), 0.0)
	# the worn centre line of the pier deck and the fishing spots at the T-head rail
	for k2 in 5: dec.add(14, Vector2(rr.randf_range(-0.4, 0.4), QZ + 3.0 + k2 * 5.5), 0.0, 1.2, 4.0, S.walk_y, Color(1, 1, 1, 0.35))
	for fx: float in [-4.0, 4.0]: dec.add(6, Vector2(fx, tz + 2.9), 0.0, 1.0, 0.8, S.walk_y, Color(1, 1, 1, 0.5))   # bait / fish stains
	# ---- water taxi float off the T-head's west side
	I.add(props, "prop_gangway", "worn", Vector3(-11.0, WF.deck(), tz - 0.5), -90.0)
	I.add(props, "prop_marina_float", "worn", Vector3(-19.6, WF.float_y(), tz - 0.5), 0.0)
	for px: float in [-23.0, -16.2]: I.add(props, "prop_marina_pile", "worn", Vector3(px, WF.bed(), tz - 0.5), 0.0)      # at the float ends, clear of the boats alongside
	I.add(props, "prop_marina_pedestal", "worn", Vector3(-21.5, WF.deck(), tz - 0.9), 0.0)
	WF.boat(props, "prop_boat_skiff", -19.6, tz + 2.0, 90.0)
	WF.boat(props, "prop_boat_express", -19.6, tz - 3.6, -90.0)
	# ---- the bay of the whole sample (preview water)
	WF.water_rect(root, -110.0, 20.0, 110.0, 420.0)
	SL.finish(root, g, props, dec, "s_wf", [])
	quit()
