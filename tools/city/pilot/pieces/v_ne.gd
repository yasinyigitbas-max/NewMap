extends SceneTree
## Piece v_ne (civic + parks band, NE): CIVIC HEART. A (corner): the memorial green - lawn, a paved plaza round the
## obelisk, the path from the corner (kit park, worn); benches round it face the monument. B (avenue): city hall set
## back behind a wide paved forecourt (where people gather, protest, wait for the bus), planters, benches facing the
## street, the mailbox, bike racks along the front; staff lot behind off the lane. C (side street): the public library
## with its forecourt, the book drop (mailbox stands in), bikes, benches under a shade tree. D (inside): the civic lot
## for visitors, entered from both lanes. Run once; never when locked.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const C := preload("res://tools/city/pilot/pieces/civ_lib.gd")
const A := preload("res://tools/city/pilot/pieces/apt_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const SL := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var sx := 1.0; var sz := -1.0
	var ctx := C.begin("v_ne", sx, sz)
	var props = ctx.props; var paints: Array = ctx.paints; var rr: RandomNumberGenerator = ctx.rr; var dec = ctx.dec
	# ---- A: memorial green, its path toward the corner
	C.park(ctx, "park_memorial_green", 31.6, 27.0, "+v")
	paints.append(A.rect(sx, sz, 30.1, A.PROP, 33.1, 12.0, "paving"))
	# (the kit green already rings its plaza with hedge and benches facing the obelisk)
	for p: Vector2 in [Vector2(14.0, 47.0), Vector2(49.0, 47.0)]: I.add(props, "tree_magnolia_a", "normal", A.q(sx, sz, p.x, p.y), p.x * 7.0)
	# ---- B: city hall
	C.bld(ctx, "civic/civ_city_hall", 80.0, 26.7, "-v", "city_hall", A.PROP, 12.0)
	for k in 4: I.add(props, "plant_potted_leafy", "normal", A.q(sx, sz, 70.0 + k * 6.6, 17.6), 0.0)
	for k in 2: I.add(props, "prop_park_bench", "worn", A.q(sx, sz, 72.0 + k * 16.0, 11.0), 180.0 if sz < 0 else 0.0)   # facing the street
	I.add(props, "prop_usps_collection_box", "worn", A.q(sx, sz, 64.5, 11.0), 0.0)
	_pad(ctx, 63.2, A.PROP, 66.0, 12.4)
	for k in 2: I.add(props, "prop_bike_rack", "worn", A.q(sx, sz, 92.0 + k * 3.0, 15.5), 0.0)
	I.add(props, "prop_trash_receptacle", "worn", A.q(sx, sz, 95.5, 11.0), 0.0)
	SL.bollards(props, sx, sz, [Vector2(70.5, 9.8), Vector2(74.5, 9.8), Vector2(85.5, 9.8), Vector2(89.5, 9.8)])
	for k in 10: dec.add(14, Vector2(sx * rr.randf_range(70.0, 90.0), sz * rr.randf_range(10.0, 18.0)), rr.randf_range(0, 180), 2.5, 2.0, S.walk_y, Color(1, 1, 1, 0.35))
	_courtyard(ctx, 62.0, 37.0, 98.0, 52.5)
	# ---- C: library
	C.bld(ctx, "civic/civ_library", 23.2, 80.0, "-u", "library", A.PROP, 8.0)
	I.add(props, "prop_usps_collection_box", "worn", A.q(sx, sz, 13.2, 71.0), -90.0)     # the book drop
	_pad(ctx, A.PROP, 69.6, 14.6, 72.4)
	for k in 2: I.add(props, "prop_bike_rack", "worn", A.q(sx, sz, 13.0, 90.0 + k * 3.0), 90.0)
	I.add(props, "tree_ficus_a", "normal", A.q(sx, sz, 44.0, 64.5), 20.0)
	for k in 2: I.add(props, "prop_park_bench", "worn", A.q(sx, sz, 40.0 + k * 6.0, 63.0), 0.0 if sz < 0 else 180.0)
	I.add(props, "prop_trash_receptacle", "worn", A.q(sx, sz, 50.0, 63.0), 0.0)
	# ---- D: visitors' lot
	_garage(ctx, 82.0, 80.0)
	C.done(ctx)
	quit()

## audit fix (17 Nov): a paved pad (mail boxes, book drops, papers stood on the lawn)
func _pad(ctx: Dictionary, u0: float, v0: float, u1: float, v1: float) -> void:
	(ctx.paints as Array).insert(0, A.rect(float(ctx.sx), float(ctx.sz), u0, v0, u1, v1, "plaza"))

## audit fix (17 Nov, Yasin: "civic band reads as a suburban campus"): the staff lot behind city hall becomes its
## courtyard - paving, four planted beds with a shade tree each (trees stand in soil, never in the paving), benches on
## the beds' edges facing the middle, two tables under sails, globe lamps, bins, bike racks for the staff
func _courtyard(ctx: Dictionary, u0: float, v0: float, u1: float, v1: float) -> void:
	var sx: float = ctx.sx; var sz: float = ctx.sz; var props = ctx.props; var paints: Array = ctx.paints; var rr: RandomNumberGenerator = ctx.rr
	var cu := (u0 + u1) * 0.5; var cv := (v0 + v1) * 0.5
	var beds: Array = [Vector2(cu - 11.0, cv - 3.0), Vector2(cu + 11.0, cv - 3.0), Vector2(cu - 11.0, cv + 3.5), Vector2(cu + 11.0, cv + 3.5)]
	paints.insert(0, A.rect(sx, sz, u0, v0, u1, v1, "plaza"))     # the paving first: the beds inserted after it come before it, and the first matching paint wins
	for k in beds.size():
		var b: Vector2 = beds[k]
		paints.insert(0, A.rect(sx, sz, b.x - 2.0, b.y - 1.6, b.x + 2.0, b.y + 1.6, "mulch" if k % 2 == 0 else "grass"))
		I.add(props, ["tree_ficus_a", "tree_jacaranda_b", "tree_magnolia_b", "tree_coral_a"][k], "normal", A.q(sx, sz, b.x, b.y), k * 70.0)
		I.add(props, "plant_bird_of_paradise", "normal", A.q(sx, sz, b.x + 1.3, b.y + 0.9), 0.0)
		var face := (Vector2(cu, cv) - b).normalized()
		var bp := b + Vector2(signf(cu - b.x) * 3.2, 0.0)
		I.add(props, "prop_park_bench", "worn", A.q(sx, sz, bp.x, bp.y), rad_to_deg(atan2(sx * signf(cu - b.x), 0.0)))
	for t: float in [cu - 3.5, cu + 3.5]:
		I.add(props, "prop_picnic_table", "worn", A.q(sx, sz, t, cv), 90.0)
		I.add(props, "prop_shade_sail", "worn", A.q(sx, sz, t, cv), 90.0)
	for l: float in [u0 + 2.0, u1 - 2.0]: I.add(props, "prop_lamp_globe", "worn", A.q(sx, sz, l, cv), 0.0)
	I.add(props, "prop_drinking_fountain", "worn", A.q(sx, sz, cu, v0 + 1.2), 0.0)
	I.add(props, "prop_trash_receptacle", "worn", A.q(sx, sz, cu + 1.5, v0 + 1.2), 0.0)
	I.add(props, "prop_trash_receptacle", "dirty", A.q(sx, sz, cu - 7.0, v1 - 1.0), 0.0)
	for k2 in 2: I.add(props, "prop_bike_rack", "worn", A.q(sx, sz, u1 - 6.0 - k2 * 3.0, v1 - 1.0), 0.0)
	for k3 in 10: (ctx.dec as K.Decals).add(14, Vector2(sx * rr.randf_range(u0 + 3, u1 - 3), sz * rr.randf_range(v0 + 1, v1 - 1)), rr.randf_range(0, 180), 2.2, 1.6, S.walk_y, Color(1, 1, 1, 0.3))

## audit fix (17 Nov): ONE parking structure for the whole civic band (city hall, library, courts, church, school
## visitors) instead of a surface lot in every quadrant; the ramp faces the service lane, the pay station at the way in
func _garage(ctx: Dictionary, u: float, v: float) -> void:
	var sx: float = ctx.sx; var sz: float = ctx.sz
	var gb := A.place(ctx.bl, sx, sz, "extras/ext_parking_garage", u, v, "-u", "civic_garage", 0.75)
	ctx.blds.append(gb)
	(ctx.paints as Array).insert(0, A.rect(sx, sz, A.AL1, v - 6.0, u - float(gb.d) * 0.5, v + 6.0, "asphalt"))
	I.add(ctx.props, "prop_pay_station", "worn", A.q(sx, sz, A.AL1 + 1.0, v - 7.0), 0.0)
	I.add(ctx.props, "prop_sign_no_parking", "worn", A.q(sx, sz, A.AL1 + 1.0, v + 7.0), 0.0)
	SL.lot_light(ctx.props, sx, sz, u - float(gb.d) * 0.5 - 1.0, v + 9.0)
	for k in 6: W.oil(ctx.dec, ctx.rr, Vector2(sx * (A.AL1 + 1.0 + k * 0.8), sz * (v + (ctx.rr as RandomNumberGenerator).randf_range(-3.0, 3.0))), 0.0, S.walk_y, 0.7)
