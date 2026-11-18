extends SceneTree
## Piece i_green_w951_n1400_se (industrial zone, 19 Nov, Yasin: "roll out to your whole zone"; not locked). Site: the
## strip between Alameda Blvd and the sample's i_sw, south of 3rd St: world u -951..-900, v -1386..-1300.
## ALAMEDA GREEN: a small fenced green where the district's workers eat their lunch: the dive bar and the cash-and-carry
## are across 3rd St, the bus stop is up Alameda, and there are trees against the base fence's glare. A strip 36 m wide
## with no driveway on either street is no place for trucks: a city planner makes it the district's only green.
## Planner's reasons:
##  - Closed fence with ONE gate (Yasin's park rule): wrought iron (bars, nothing layered behind it but trees), the gate
##    on 3rd St where people cross from the bar and the shops.
##  - Tables in the shade of the trees and under one sail, benches facing the green and the paths, bins at the
##    paths, a fountain, a bike rack inside the gate. Trees only in the grass.
## Run once; never when locked.
const G := preload("res://tools/city/pilot/pieces/ind_grow_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const NAME := "i_green_w951_n1400_se"
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var sx := 1.0; var sz := 1.0
	var J := Vector3(-950.889, 2.0, -1400.0)
	var Lu := 50.889
	var mr: Dictionary = await G.measure_rows(self, J, sx, sz, Lu, 100.0, [NAME])
	var root := Node3D.new(); root.name = NAME
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(NAME)
	var vf := float(mr.rows[0][0]); var af := float(mr.rows[0][1])
	# paths: in from the 3rd St gate, a cross path to the tables; the rest grass
	G.floor_rows(g, mr, sx, sz, [[33.0, 0.0, 35.6, 72.0, "gravel"], [19.0, 48.0, 49.0, 50.6, "gravel"], [0.0, 0.0, 60.0, 100.0, "grass"]])
	# ---- the fence: wrought iron all round, a post at every joint, ONE gate on 3rd St
	var iron := func(a: Vector2, b: Vector2) -> void:
		var L := a.distance_to(b)
		if L < 0.5: return
		var n := maxi(1, int(ceil(L / 1.98 - 0.02)))
		var yaw := rad_to_deg(atan2(sx * (b.x - a.x), sz * (b.y - a.y))) + 90.0
		for i in n:
			var c := a.lerp(b, (i + 0.5) / n)
			I.add(props, "fence_wrought_iron", "worn", G.q(sx, sz, c.x, c.y), yaw)
		for i in n + 1:
			var e := a.lerp(b, float(i) / n)
			I.add(props, "fence_post_wrought_iron", "worn", G.q(sx, sz, e.x, e.y), yaw)
	var yl := vf + 0.25
	var ra := G.row_at(mr, 60.0); var al := float(ra[1]) + 0.25 if not ra.is_empty() else af + 0.25
	# the corner: the kerb return eats into the strip, so the fence cuts across it on the diagonal, clear of the
	# junction's sign post (the street's own furniture stands on the walk there)
	var rc := G.row_at(mr, 26.0); var ac := float(rc[1]) + 0.25 if not rc.is_empty() else al
	var u_n := float(G.row_at(mr, yl + 0.6)[1]) + 3.0
	iron.call(Vector2(u_n, yl), Vector2(33.0, yl)); iron.call(Vector2(35.6, yl), Vector2(Lu - 0.3, yl))
	I.add(props, "fence_gate_wrought_iron", "worn", G.q(sx, sz, 34.3, yl), 0.0)
	iron.call(Vector2(u_n, yl), Vector2(ac, 26.0))
	iron.call(Vector2(ac, 26.0), Vector2(al, 99.6)); iron.call(Vector2(al, 99.6), Vector2(Lu - 0.3, 99.6))
	iron.call(Vector2(Lu - 0.3, 91.0), Vector2(Lu - 0.3, 99.6))       # the sample's chain-link closes the rest of the east side
	# ---- trees (in the grass only, clear of paths), mixed species and ages
	var trees := [["tree_coral_a", 23.0, 24.0], ["tree_eucalyptus_a", 44.0, 26.0], ["tree_jacaranda_a", 24.0, 40.0], ["tree_torrey_pine_b", 45.0, 42.0],
		["tree_coral_b", 22.0, 62.0], ["tree_eucalyptus_b", 44.0, 64.0], ["tree_torrey_pine_a", 26.0, 84.0], ["tree_jacaranda_b", 41.0, 88.0], ["tree_eucalyptus_a", 31.0, 95.0]]
	for t: Array in trees: props.add(String(t[0]), "normal", G.q(sx, sz, float(t[1]), float(t[2])), rr.randf_range(0, 360), true, rr.randf_range(0.85, 1.1))
	# ---- the lunch tables (one under a sail), benches facing the green, bins, fountain, bike rack inside the gate
	for t2: Vector2 in [Vector2(26.0, 54.5), Vector2(42.0, 55.0), Vector2(27.0, 73.0), Vector2(41.0, 75.0)]:
		I.add(props, "prop_picnic_table", "worn", G.q(sx, sz, t2.x, t2.y), rr.randf_range(-10, 10))
	I.add(props, "prop_shade_sail", "clean", G.q(sx, sz, 42.0, 55.0), 0.0, false)
	for b2: Array in [[30.0, 46.5, 0.0], [38.5, 46.5, 0.0], [31.5, 31.0, 90.0], [37.4, 33.0, -90.0], [31.4, 66.0, 90.0]]:
		I.add(props, "prop_park_bench", "worn", G.q(sx, sz, float(b2[0]), float(b2[1])), float(b2[2]))
	for b3: Vector2 in [Vector2(36.6, 45.5), Vector2(32.2, 52.0), Vector2(36.8, 70.5)]:
		I.add(props, "prop_trash_receptacle", "worn", G.q(sx, sz, b3.x, b3.y), 0.0)
	I.add(props, "prop_drinking_fountain", "worn", G.q(sx, sz, 37.0, 22.0), -90.0)
	I.add(props, "prop_bike_rack", "worn", G.q(sx, sz, 40.0, 18.6), 0.0)
	I.add(props, "prop_lamp_globe", "worn", G.q(sx, sz, 36.8, 40.0), 0.0); I.add(props, "prop_lamp_globe", "worn", G.q(sx, sz, 31.8, 60.0), 0.0)
	# ---- wear: worn grass where people cut the corner from the gate to the tables (foot wear = grime at low alpha)
	for k in 6: dec.add(14, Vector2(sx * (35.0 - k * 1.4), sz * (50.0 + k * 1.8)), 30.0, 1.0, 1.6, S.walk_y, Color(1, 1, 1, 0.25))
	root.set_meta("stalls", [])
	I.finish(root, g, props, dec, NAME)
	quit()
