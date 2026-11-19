extends SceneTree
## Piece n_hs_b4_cottages (high street fill, block 4, part "B Ave houses"): u 190..240.8, v 209.2..Ocean Blvd, between
## the service alley (west, u 190..196, from 11th St's alley mouth), 11th St (north), B Ave (east) and Ocean Blvd (south).
## Placed at grid [0, 4.0, 0], yaw 0. Run once; never when locked.
##
## WHY (planner): B Ave is a house street (the residential growth faces it from the east): the block answers with seven
## houses on their own lots facing B Ave, each one different (Victorian, two craftsman, Spanish, Cape, beach cottage, a
## narrow two-storey on the Ocean Blvd corner), garages behind on the service alley; the residents' alley from B Ave's
## alley mouth (v 254..260) crosses it and runs west to the high street's rear lot. Deep back yards: the beach life
## (showers, a kayak rack, surfboards), a bike, washing, a swing set for the corner family.
## LAND: B Ave falls 2 m north to south (6.15 -> 4.15) and the block falls 0.2 m toward the alley: each lot a level pad
## at its middle's height; retaining faces at the lot lines (up to ~0.25 m), steps on the front paths where the face
## crosses them, driveway ramps up / down to the garages.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const B4 := preload("res://tools/city/pilot/pieces/n_hs_b4_site.gd")

const X0 := 190.0
const X1 := 240.8
const XB := 240.2            # behind the 0.6 m band along B Ave
const XG := 196.6            # the garages' fronts / the lots' back line (the alley u 190..196, aprons 0.6 m)
const ALLEY_V := [254.0, 260.0]
const DEAD := 324.0          # the service alley's dead end (a turning stub; Ocean Blvd has no alley mouth)
const XF := 234.5            # the houses' fronts (front gardens 5.7 m)
## [label, house, garage, v0, v1 (0 = to Ocean Blvd), house centre v, garage centre v]   houses yaw 90 (face +u, model x -> -v)
const LOTS := [
	["h1", "houses/craftsman_large", "garages/double_stucco_clay", 209.8, 224.4, 217.1, 217.6],
	["h2", "houses/victorian_blue", "garages/single_siding_comp", 224.4, 239.0, 231.8, 232.4],
	["h3", "houses/cape_grey", "garages/carport_clay", 239.0, 253.4, 246.2, 247.2],
	["h4", "houses/spanish_small", "garages/single_stucco_clay", 260.6, 277.4, 269.0, 272.0],
	["h5", "houses/craftsman_olive", "garages/double_siding_comp", 277.4, 294.2, 285.8, 288.6],
	["h6", "houses/beach_teal", "garages/single_stucco_clay", 294.2, 311.0, 302.6, 306.0],
	["h7", "houses/narrow_2sty_siding", "garages/carport_clay", 311.0, 0.0, 320.0, 318.4],
]

func _init() -> void: _run.call_deferred()

static func lot_v1(l: Array) -> float: return B4.south(XG) - 0.6 if float(l[4]) == 0.0 else float(l[4])
static func pad_y(l: Array) -> float: return B4.g(218.4, (float(l[3]) + lot_v1(l)) * 0.5)
static func bb(l: Array) -> Array: return (K.building_stats(String(l[1])).near as Dictionary).bbox
static func house_u(l: Array) -> float: return XF - float(bb(l)[1][2])
static func door_v(l: Array) -> float:
	var df: Array = K.building_stats(String(l[1])).doors_front
	return float(l[5]) - float(df[0][1])
static func nsteps(l: Array, yf: Callable) -> int:
	var dh := absf(pad_y(l) - B4.PAD_Y - float(yf.call(XB, door_v(l))))
	return 1 if dh < 0.03 else ceili(dh / 0.17)

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b4_cottages"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hs_b4_cottages")
	var yf := B4.L(B4.g)
	var n := func(x: float) -> float: return B4.north(x)
	var sth := func(x: float) -> float: return B4.south(x)
	# ================================================================ ground
	var holes: Array = []
	for l: Array in LOTS: holes.append([XG, float(l[3]), XB, lot_v1(l), "-"])
	for l: Array in LOTS: holes.append([196.0, float(l[6]) - 1.8, XG, float(l[6]) + 1.8, "-"])     # garage ramps
	holes.append_array([
		[X0, 209.2, 196.0, DEAD, "asphalt"],                # the service alley
		[X0, ALLEY_V[0], X1, ALLEY_V[1], "asphalt"],        # the residents' alley
		[X0, 209.2, X1, 209.8, "concrete"],                 # band along 11th St
		[XB, 209.2, X1, 340.0, "concrete"],                 # band along B Ave
	])
	H.paint_band(g, X0, X1, n, sth, holes, "grass", yf)
	for l: Array in LOTS:
		var y := pad_y(l) - B4.PAD_Y
		var yp := func(_x: float, _z: float) -> float: return y
		var v0: float = l[3]; var v1 := lot_v1(l); var dv := door_v(l); var gv: float = l[6]
		var ns := nsteps(l, yf)
		var xs := XB - 0.3 * ns          # the steps' inner end
		# the lot: front path from the steps to the door, the house, the back yard, the garage apron by the alley
		var lp := [[xs, dv - 0.7, XB, dv + 0.7, "-"],
			[XF - 0.2, dv - 0.7, xs, dv + 0.7, "concrete"],
			[XG, gv - 1.8, XG + 7.0, gv + 1.8, "concrete"]]
		H.paint(g, XG, v0, XB, v1, lp, "grass", yp)
		H.steps_x(g, dv, 1.4, XB, xs, float(yf.call(XB, dv)), y)
		H.step_face(g, Vector2(XG, v0), Vector2(XB, v0), yp, yf)
		H.step_face(g, Vector2(XG, v1), Vector2(XB, v1), yp, yf)
		H.step_face(g, Vector2(XB, v0), Vector2(XB, dv - 0.7), yp, yf)
		H.step_face(g, Vector2(XB, dv + 0.7), Vector2(XB, v1), yp, yf)
		H.step_face(g, Vector2(XG, v0), Vector2(XG, gv - 1.8), yp, yf)
		H.step_face(g, Vector2(XG, gv + 1.8), Vector2(XG, v1), yp, yf)
		H.ramp_x(g, "concrete", 196.0, XG, gv - 1.8, gv + 1.8, y, yf)
	H.skirt(g, Vector2(X1, 209.2), Vector2(X1, B4.south(X1)), yf, "concrete")
	H.skirt(g, Vector2(X0, 209.2), Vector2(X1, 209.2), yf, "concrete")
	H.skirt(g, Vector2(X0, B4.south(X0)), Vector2(X1, B4.south(X1)), yf, "concrete")
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	H.finish(root, g, props, dec, "n_hs_b4_cottages")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	var i := 0
	for l: Array in LOTS:
		var y := pad_y(l) - B4.PAD_Y
		var yp := func(_x: float, _z: float) -> float: return y
		var v0: float = l[3]; var v1 := lot_v1(l); var dv := door_v(l); var gv: float = l[6]
		var hu := house_u(l); var hb: float = hu + float(bb(l)[0][2])        # the house's back wall u
		K.building(bl, String(l[1]), Vector3(hu, y, float(l[5])), 90.0, String(l[0]))
		var gst := K.building_stats(String(l[2]))
		var gd: float = gst.footprint_wd[1]
		K.building(bl, String(l[2]), Vector3(XG + gd * 0.5, y, gv), -90.0, String(l[0]) + "_garage")
		# the lot closed all round: picket on B Ave open at the path (iron for the Spanish house), the mailbox at the
		# opening; picket on the lot lines in front of the house, privacy behind it; privacy on the alley line meeting
		# the garage. A lot draws its south line (v1); the first of each group its north one too.
		var fence := "fence_wrought_iron" if String(l[1]).contains("spanish") else "fence_picket_white"
		var post := "fence_post_wrought_iron" if fence == "fence_wrought_iron" else "fence_post_picket"
		var pl := 1.98 if fence == "fence_wrought_iron" else 2.0
		var xf := XB - 0.3 * nsteps(l, yf) - 0.1          # behind the steps
		H.fence(props, fence, post, Vector2(xf, v0 + 0.1), Vector2(xf, dv - 0.9), yp, pl)
		H.fence(props, fence, post, Vector2(xf, dv + 0.9), Vector2(xf, v1 - 0.1), yp, pl)
		H.put(props, "prop_mailbox_post_wood", "worn", xf - 0.3, dv + 1.25, yp, 90.0)
		var lines: Array = [v1 - 0.1]
		if i == 0 or i == 3: lines.append(v0 + 0.1)
		for lv: float in lines:
			H.fence(props, fence, post, Vector2(xf, lv), Vector2(XF + 0.4, lv), yp, pl)
			H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(XF + 0.4, lv), Vector2(XG + gd + 0.1, lv), yp, 2.01)
			H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(XG + gd + 0.1, lv), Vector2(XG + 0.1, lv), yp, 2.01)
		var gbb: Array = (gst.near as Dictionary).bbox
		var gw: float = maxf(-float(gbb[0][0]), float(gbb[1][0])) + 0.05         # (the model's own width, not the stats footprint)
		H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(XG + 0.1, v0 + 0.1), Vector2(XG + 0.1, gv - gw), yp, 2.01)
		H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(XG + 0.1, gv + gw), Vector2(XG + 0.1, v1 - 0.1), yp, 2.01)
		# planting by the path (not before a window door), a street tree in the front garden of every other lot
		H.put(props, "plant_bird_of_paradise", "normal", XF + 2.0, dv - 2.2, yp, 0.0, false)
		H.put(props, "plant_agave_americana_small", "normal", XF + 3.4, dv + 2.6, yp, 0.0, false)
		if i % 2 == 0: H.put(props, ["tree_jacaranda_a", "tree_coral_a", "tree_magnolia_b", "palm_queen_a"][i / 2], "normal", XB - 2.4, v0 + 3.0 if dv > (v0 + v1) * 0.5 else v1 - 3.0, yp, float(i) * 37.0)
		# the back yard tree (kind by owner), away from the garage
		H.put(props, ["tree_ficus_b", "tree_coral_b", "tree_torrey_pine_a", "tree_jacaranda_b", "tree_magnolia_a", "tree_coral_a", "tree_ficus_a"][i], "normal", 212.0, v0 + 3.4 if i % 2 == 0 else v1 - 3.4, yp, float(i) * 53.0)
		# bins beside the garage on the apron's side (not collection day), the condenser at the side wall, hose by the back
		var cz := gv + gw + 0.6 if gv + gw + 1.2 < v1 else gv - gw - 0.6
		for k in 3: H.put(props, ["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", XG + gd + 1.0 + 0.8 * k, cz, yp, 180.0)
		H.put(props, "prop_ac_condenser", "worn", hu - 2.0, v0 + 0.9, yp, 0.0)
		H.put(props, "prop_hose_reel_cart", "worn", hb - 0.8, v1 - 2.8, yp, 180.0)
		# the back yard's life: each family its own
		var cy := (v0 + v1) * 0.5
		match i:
			0: H.put(props, "prop_patio_set_4", "worn", hb - 4.0, cy, yp, 0.0); H.put(props, "prop_bbq_gas_cart", "worn", hb - 1.4, cy + 4.0, yp, 90.0)
			1: H.put(props, "prop_clothesline", "worn", 210.0, cy, yp, 90.0); H.put(props, "prop_adirondack_white", "worn", hb - 3.0, v0 + 2.0, yp, 250.0)
			2: H.put(props, "prop_garden_arbor", "worn", hb - 2.0, cy, yp, 90.0); H.put(props, "prop_bike_stand", "worn", hb - 1.0, v0 + 2.0, yp, 90.0)
			3: H.put(props, "prop_beach_shower", "worn", hb - 1.0, v1 - 1.2, yp, 0.0); H.put(props, "prop_surfboard_rack", "clean", 206.0, v1 - 0.8, yp, 0.0)
			4: H.put(props, "prop_swing_set", "worn", 211.0, cy, yp, 90.0); H.put(props, "prop_patio_set_4", "worn", hb - 3.5, cy + 3.0, yp, 0.0)
			5: H.put(props, "prop_kayak_rack", "worn", 206.0, v0 + 1.4, yp, 0.0); H.put(props, "prop_bbq_kettle", "worn", hb - 2.0, cy, yp, 0.0); H.put(props, "prop_beach_shower", "worn", hb - 1.0, v0 + 1.2, yp, 0.0)
			6: H.put(props, "prop_adirondack_wood", "worn", hb - 3.0, cy - 1.0, yp, 200.0); H.put(props, "prop_adirondack_wood", "worn", hb - 4.4, cy - 1.0, yp, 160.0)
		W.oil(dec, rr, Vector2(XG + 1.5, gv), 90.0, yp, 0.5)
		dec.add(8, Vector2(193.0, gv), 90.0, 1.0, 3.0, yf, Color(1, 1, 1, 0.3))      # the turn in from the alley
		i += 1
	# the alleys: a drain at the dead end (the low corner), a light at the crossing, wear
	P.call("prop_storm_drain_grate", "worn", 193.0, DEAD - 1.5, 0.0, false)
	P.call("prop_lot_light_pole", "worn", 196.4, 261.0)
	W.lane_wear(dec, rr, 193.0, 209.2, DEAD, true, yf)
	W.lane_wear(dec, rr, 257.0, X0, X1, false, yf)
