extends SceneTree
## Piece n_hs_b2_ninth (high street fill, block 2, part "Ninth Street hall"): u -100..-50, v -190.8..-146, between the
## residential growth on the west, 9th St on the north, the mews' cross alley on the south and the high street's north
## yard (n_hs_b2_amber) on the east. Placed at grid [0, 4.0, 0], yaw 0. Run once; never when locked.
##
## WHY (planner): the church on Amber needs its hall: the COMMUNITY CENTER on 9th St (meetings, the food bank, classes),
## reached on foot from Amber by the church walk and a path along the east side, and by car from the cross alley into
## its lot. A memorial garden on its west side toward the houses, its service side (bins, condensers) on the east.
## LAND: the top of the block, 9th St at 6.15; the hall's pad at the walk's height; the lot falls 0.5 m to the alley.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const B2 := preload("res://tools/city/pilot/pieces/n_hs_b2_site.gd")

const X0 := -100.0
const X1 := -50.0
const ZS := -146.0
const HALL := [-88.0, -190.2, -62.0, -170.8]     # the hall's pad (its porch reaches the 9th St band)
const HALL_Y := 6.15

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b2_ninth"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hs_b2_ninth")
	var yf := B2.L(B2.g)
	var e9 := func(x: float) -> float: return B2.edge9(x)
	var zb := func(_x: float) -> float: return -190.2
	# ================================================================ ground
	# the band along 9th St (flush with its walk)
	H.band(g, "concrete", X0, X1, e9, zb, yf, H.STEP, [-54.77, -51.0])
	var stalls: Array = []
	for k in 17: stalls.append([-98.0 + 2.7 * k - 0.05, -157.5, -98.0 + 2.7 * k + 0.05, -152.5, "white"])
	var paints := [
		[HALL[0], HALL[1], HALL[2], HALL[3], "-"],
		[-52.5, -190.2, -50.0, -152.5, "plaza"],            # the path from the church walk to 9th St, along the east side
		[-98.0, -157.5, -52.5, ZS, "asphalt"],              # the hall's lot (drive along the alley, stalls nose north)
		[-62.0, -190.2, -52.5, -176.0, "concrete"],         # the hall's service side
		[-96.0, -186.0, -90.0, -180.0, "plaza"],            # memorial garden: the sitting place
		[-93.8, -180.0, -92.2, -160.0, "plaza"],            # its path to the lot
	]
	stalls.append_array(paints)
	H.paint(g, X0, -190.2, X1, ZS, stalls, "grass", yf)
	H.level_pad(g, "concrete", HALL[0], HALL[1], HALL[2], HALL[3], HALL_Y - B2.PAD_Y, yf, "sew")
	var wbot := func(_x: float, z: float) -> float: return B2.west_skirt_bot(z)
	H.skirt(g, Vector2(X0, -190.8), Vector2(X0, ZS), yf, "wall", wbot)
	for s: Array in [[X0, -190.8, -54.77, -190.8], [-54.77, -190.8, -51.0, -190.3], [-51.0, -190.3, X1, -190.3]]:
		H.skirt(g, Vector2(float(s[0]), float(s[1])), Vector2(float(s[2]), float(s[3])), yf, "concrete")
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	H.finish(root, g, props, dec, "n_hs_b2_ninth")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	var yh := func(_x: float, _z: float) -> float: return HALL_Y - B2.PAD_Y
	K.building(bl, "civic/civ_community_center", Vector3(-75.0, HALL_Y - B2.PAD_Y, -179.55), 180.0, "hall")   # faces 9th; door u -75; back door u -66
	# ---- memorial garden on the west (toward the houses): a small war memorial, benches facing it, shade, a low hedge
	# to 9th St, the neighbours closed off by the lot-line fence
	P.call("prop_obelisk_monument", "worn", -93.0, -182.0, 0.0)
	P.call("prop_park_bench", "worn", -93.0, -184.9, 0.0)
	P.call("prop_park_bench", "worn", -95.4, -182.0, 90.0)
	for t: Array in [["tree_torrey_pine_b", -96.5, -172.0], ["tree_magnolia_a", -90.5, -166.0], ["tree_jacaranda_a", -97.0, -161.0]]:
		P.call(String(t[0]), "normal", float(t[1]), float(t[2]), float(t[2]) * 3.0)
	H.hedge(props, Vector2(-99.4, -189.8), Vector2(-88.4, -189.8), yf)
	H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(-99.45, -189.6), Vector2(-99.45, -146.4), yf, 2.01)
	# ---- the hall's east side: its bins and condensers (service), the path from the church walk to 9th kept clear
	P.call("prop_dumpster_3yd_green", "worn", -56.2, -184.6, 90.0)          # kitchen of the hall (suppers, the food bank)
	P.call("prop_recycling_receptacle", "worn", -56.0, -182.0, 90.0)
	P.call("prop_ac_condenser", "worn", -61.6, -179.0, 90.0)
	P.call("prop_ac_condenser", "worn", -61.6, -181.2, 90.0)
	P.call("prop_bike_rack", "worn", -53.4, -176.0, 90.0)                    # beside the path, parallel to it
	# ---- between the lot and the hall: a table under its sail for the church's socials, a bench facing the hall
	P.call("prop_picnic_table", "worn", -80.0, -164.0, 0.0)
	P.call("prop_shade_sail", "worn", -80.0, -164.0, 0.0, false)
	P.call("prop_trash_receptacle", "worn", -77.6, -161.2)
	P.call("prop_park_bench", "worn", -69.0, -159.2, 180.0)
	# ---- the lot: wheel stops, two lights behind the stalls
	for k in 16: P.call("prop_wheel_stop_concrete", "worn", -96.65 + 2.7 * k, -156.9, 0.0)
	P.call("prop_lot_light_pole", "worn", -84.0, -158.3)
	P.call("prop_lot_light_pole", "worn", -60.0, -158.3)
	# ================================================================ wear
	for x: float in [-95.3, -89.9, -84.5, -76.4, -71.0, -62.9, -57.5]: W.oil(dec, rr, Vector2(x, -154.5), 0.0, yf, 0.6)
	W.lane_wear(dec, rr, -149.5, -98.0, -52.5, false, yf)
	dec.add(14, Vector2(-56.2, -184.6), 90.0, 3.0, 2.4, yf, Color(1, 1, 1, 0.7))
	dec.add(14, Vector2(-51.25, -170.0), 0.0, 1.2, 30.0, yf, Color(1, 1, 1, 0.3))      # the path's walking line
	dec.add(14, Vector2(-93.0, -184.0), 0.0, 2.0, 2.0, yf, Color(1, 1, 1, 0.35))
