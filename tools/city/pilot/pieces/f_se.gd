extends SceneTree
## Piece f_se (waterfront sample, SE): the marina.
## Land (z 9.2 .. the quay): the marina office on the drive (harbour staff, slip rentals), its forecourt with a bench
## and the kayak rental rack; the boaters' lot entered through the drive's apron at x 54-60 (two rows round a 7 m
## aisle, lot lights, wheel stops), boat trailers parked nose-out along the east fence where people launch from;
## the seawall promenade (z 30 .. quay): railing on the quay edge except at the gangway, the stair landing and the fuel
## dock; benches every ~15 m facing the boats, pier lamps, life rings, bins next to the benches.
## Quay: 6 m modules; a stair down to a landing at x 30 (dinghies), bollard modules where boats tie up (fuel dock at
## x 84-96 with two pumps on the coping and a cruiser alongside).
## Water: the hinged gangway at x 48 down to the main float (twelve 6 m floats), seven fingers on its south side,
## a boat in each slip bow-in (sloops, express cruisers, a troller, skiffs), piles at the finger tips and float ends,
## shore-power pedestals on the fingers, dock boxes on the main float; skiffs tied on the float's north side; a red and
## a green channel marker at the fairway east of the marina; mooring buoys further out with a sloop on one.
## Wear: oil in every stall and at the fuel dock, tyre marks from the apron, salt grime along the seawall, rust under
## the pumps, cracks and patches in the lot, gull-white on the bollard modules. Run once; never when locked.
const WF := preload("res://tools/city/pilot/pieces/wf_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const SL := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const CC := preload("res://tools/city/pilot/pieces/cc_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var root := Node3D.new(); root.name = "f_se"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for("f_se")
	var paints: Array = []; var stalls: Array = []
	var wy := WF.wy(); var QZ := WF.QZ
	# ---- marina office on the drive
	var off := K.building(bl, "extras/ext_marina_office", Vector3(22.0, wy, 16.7), 180.0, "marina_office", 0.8)
	CC.back_of_house(props, off, "extras/ext_marina_office", false)
	I.bld_wear(dec, rr, off, 14.0, 10.0, "extras/ext_marina_office")
	paints.append([13.0, 9.2, 31.0, 11.7, "concrete"])
	I.add(props, "prop_park_bench", "worn", Vector3(17.0, wy, 10.6), 180.0)     # waiting for the dock master, facing the drive
	I.add(props, "prop_trash_receptacle", "worn", Vector3(27.4, wy, 10.6), 0.0)
	I.add(props, "prop_kayak_rack", "worn", Vector3(33.5, wy, 13.0), 90.0)    # rentals, by the office that rents them
	I.add(props, "prop_kayak_rack", "worn", Vector3(33.5, wy, 17.2), 90.0)
	I.add(props, "prop_bike_rack", "worn", Vector3(13.6, wy, 13.5), 90.0)
	paints.append([31.0, 9.2, 36.0, 22.0, "concrete"])
	# ---- boaters' lot (apron from the drive at x 54-60)
	SL.stalls_u(paints, stalls, 1.0, 1.0, 40.2, 5, 10.0, 1.0)
	SL.stalls_u(paints, stalls, 1.0, 1.0, 60.2, 12, 10.0, 1.0)
	SL.stalls_u(paints, stalls, 1.0, 1.0, 40.2, 19, 28.0, -1.0)
	for lx: float in [50.0, 80.0]: SL.lot_light(props, 1.0, 1.0, lx, 15.8)
	for k in 5: I.add(props, "prop_boat_trailer", "worn", Vector3(95.8, wy, 12.4 + k * 3.5), -90.0)   # nose-out, ready to launch
	I.lot_fence(props, Vector2(99.8, 9.6), Vector2(99.8, 29.0))
	SL.stall_wear(dec, rr, stalls, 0.7)
	SL.aisle_wear(dec, rr, 1.0, 1.0, 40.0, 94.0, 19.0)
	I.truck_path(dec, rr, Vector2(57.0, 9.2), Vector2(57.0, 19.0))
	I.yard_wear(dec, rr, 1.0, 1.0, 38.0, 9.2, 100.0, 29.5, 0.9)
	SL.drains(props, 1.0, 1.0, [Vector2(70.0, 19.0)])
	# ---- seawall promenade
	paints.append([9.2, 29.5, 100.0, QZ - 2.0, "plaza"])
	for k2 in 6:
		var bx := 16.0 + k2 * 15.0
		if absf(bx - 48.0) < 4.0 or bx > 82.0: continue          # not in front of the gangway or at the fuel dock
		I.add(props, "prop_park_bench", "worn", Vector3(bx, wy, 35.4), 0.0)
		I.add(props, "prop_trash_receptacle", "dirty", Vector3(bx + 2.0, wy, 35.4), 0.0)
		dec.add(14, Vector2(bx, 36.1), 0.0, 2.2, 1.4, S.walk_y, Color(1, 1, 1, 0.45))
	for k3 in 8: I.add(props, "prop_pier_lamp", "worn", Vector3(13.0 + k3 * 12.0, wy, 31.0), 0.0)
	for lx2: float in [22.0, 66.0]: I.add(props, "prop_lifering_stand", "worn", Vector3(lx2, wy, QZ - 1.3), 0.0)      # behind the railing, reachable
	# ---- quay: stair at 30, bollards where boats tie up, fuel dock 84-96
	for k4 in 15:
		var qx := 12.0 + k4 * 6.0
		var kind := "stair" if qx == 30.0 else ("straight_bollards" if (qx >= 84.0 or k4 % 3 == 1) else "straight")
		WF.quay(props, kind, qx)
		if kind == "straight_bollards": dec.add(4, Vector2(qx, QZ - 0.6), 0.0, 1.2, 0.6, S.walk_y, Color(0.85, 0.85, 0.82, 0.55))   # gulls
		dec.add(14, Vector2(qx, QZ - 1.9), 90.0, 0.6, 5.8, S.walk_y, Color(1, 1, 1, 0.5))    # salt grime at the coping joint
	WF.rail_run(props, 9.0, 27.0); WF.rail_run(props, 33.0, 46.0); WF.rail_run(props, 50.0, 82.0)
	for fx: float in [87.0, 93.0]:
		I.add(props, "prop_fuel_pump", "worn", Vector3(fx, wy, QZ - 1.1), 0.0)
		W.oil(dec, rr, Vector2(fx, QZ - 0.4), 0.0, S.walk_y, 0.95)
	I.add(props, "prop_sign_no_parking", "worn", Vector3(83.2, wy, QZ - 2.4), 0.0)       # fuel dock: no tying up
	WF.boat(props, "prop_boat_express", 90.0, QZ + 1.8, 90.0)                              # alongside, fuelling
	# ---- the marina
	var fz := QZ + 10.5 + 1.36
	I.add(props, "prop_gangway", "worn", Vector3(48.0, WF.deck(), QZ + 5.0), 0.0)
	for k5 in 12: I.add(props, "prop_marina_float", "worn", Vector3(27.0 + k5 * 6.0, WF.float_y(), fz), 0.0)
	var boats := ["prop_boat_sloop", "prop_boat_express", "prop_boat_troller", "prop_boat_sloop", "prop_boat_skiff", "prop_boat_express", "prop_boat_sloop"]
	for k6 in 7:
		var fx2 := 30.0 + k6 * 9.0
		I.add(props, "prop_marina_finger", "worn", Vector3(fx2, WF.float_y(), fz + 1.36), 0.0)
		I.add(props, "prop_marina_pile", "worn", Vector3(fx2, WF.bed(), fz + 1.36 + 7.9), 0.0)
		I.add(props, "prop_marina_pedestal", "worn", Vector3(fx2 + 1.1, WF.deck(), fz + 2.6), 0.0)
		var blen := float(K.manifest(String(boats[k6])).get("footprint_d", 9.5))
		WF.boat(props, boats[k6], fx2 + 4.5, fz + 1.36 + 0.7 + blen * 0.5, 180.0)       # bow in, 0.7 m off the float
		I.add(props, "prop_dock_box", "worn", Vector3(fx2 + 4.5, WF.deck(), fz - 0.75), 0.0)
	for px: float in [24.0, 96.0]: I.add(props, "prop_marina_pile", "worn", Vector3(px, WF.bed(), fz), 0.0)
	WF.boat(props, "prop_boat_skiff", 66.0, fz - 2.5, 90.0)
	WF.boat(props, "prop_boat_skiff", 76.0, fz - 2.5, -90.0)
	# fairway markers (red right returning: the red nun on the starboard side coming in) and the mooring field
	I.add(props, "prop_buoy_can", "worn", Vector3(104.0, WF.bed(), QZ + 18.0), 0.0)
	I.add(props, "prop_buoy_nun", "worn", Vector3(104.0, WF.bed(), QZ + 34.0), 0.0)
	for mb: Vector2 in [Vector2(40.0, 92.0), Vector2(62.0, 100.0), Vector2(84.0, 94.0)]:
		I.add(props, "prop_buoy_mooring", "worn", Vector3(mb.x, WF.bed(), mb.y), 0.0)
	WF.boat(props, "prop_boat_sloop", 62.0, 106.0, 0.0)        # lying to her mooring, stern to the wind
	# ---- floor
	K.painted_rect(g, 9.2, 9.2, 100.0, QZ - 2.0, paints, S.walk_y, "asphalt")
	SL.finish(root, g, props, dec, "f_se", stalls)
	quit()
