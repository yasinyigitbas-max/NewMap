extends SceneTree
## Piece v_nw (civic + parks band, NW): SPORT. A (corner): the public tennis courts (kit tennis centre re-dressed, chain-
## link with posts and one gate toward the avenue, a walk from the sidewalk to the gate, benches outside for the next
## pair waiting). B (avenue): the rec centre - the neighbourhood gym - with a paved forecourt, bike racks along its
## front, members' lot behind entered from the lane. C (side street): the playground village (kit park, worn) with
## picnic tables and the snack kiosk parents queue at. D (inside, off both lanes): the skate park - a concrete pad with
## bowl, quarter pipes, funbox and rail, the skate shed, chain-link with one gate, tagged block walls, benches and
## bikes where skaters sit and watch. Run once; never when locked.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const C := preload("res://tools/city/pilot/pieces/civ_lib.gd")
const A := preload("res://tools/city/pilot/pieces/apt_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const SL := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var sx := -1.0; var sz := -1.0
	var ctx := C.begin("v_nw", sx, sz)
	var props = ctx.props; var paints: Array = ctx.paints; var rr: RandomNumberGenerator = ctx.rr; var dec = ctx.dec
	# ---- A: tennis
	C.park(ctx, "park_tennis_courts", 31.6, 31.6, "-v")
	paints.append(A.rect(sx, sz, 30.6, A.PROP, 32.6, 11.6, "concrete"))
	for k in 2: I.add(props, "prop_park_bench", "worn", A.q(sx, sz, 26.0 + k * 11.0, 10.4), 0.0)     # waiting, facing the courts
	I.add(props, "prop_trash_receptacle", "worn", A.q(sx, sz, 34.4, 10.4), 0.0)
	I.add(props, "prop_bike_rack", "worn", A.q(sx, sz, 44.0, 10.3), 0.0)
	# ---- B: rec centre (the gym)
	var rec := C.bld(ctx, "civic/civ_rec_center", 80.0, 22.2, "-v", "rec_center", A.PROP, 6.0)
	for k in 2: I.add(props, "prop_bike_rack", "worn", A.q(sx, sz, 66.0 + k * 3.0, 14.4), 0.0)
	I.add(props, "prop_park_bench", "worn", A.q(sx, sz, 92.0, 13.4), 180.0)
	I.add(props, "prop_drinking_fountain", "worn", A.q(sx, sz, 72.5, 14.4), 0.0)
	I.add(props, "prop_vending_soda", "worn", A.q(sx, sz, 86.0, 14.6), 180.0 if sz > 0 else 0.0)    # by the gym door: after the workout
	I.add(props, "prop_vending_snack", "worn", A.q(sx, sz, 87.4, 14.6), 180.0 if sz > 0 else 0.0)
	# audit fix (17 Nov): the members' lot behind the gym becomes its outdoor side - a fenced tot lot for parents at
	# classes and a paved picnic court with tables under sails (members park in the civic garage, v_ne D)
	C.park(ctx, "park_pocket_orange", 70.0, 42.0, "-v", "fence_wrought_iron", "fence_post_wrought_iron")
	paints.insert(0, A.rect(sx, sz, 80.0, 33.0, 98.0, 52.0, "plaza"))
	for k in 3:
		I.add(props, "prop_picnic_table", "worn", A.q(sx, sz, 84.0 + k * 5.5, 39.0), 90.0)
		I.add(props, "prop_shade_sail", "worn", A.q(sx, sz, 84.0 + k * 5.5, 39.0), 90.0)
	for k in 2: I.add(props, "prop_park_bench", "worn", A.q(sx, sz, 85.0 + k * 8.0, 49.5), 180.0 if sz > 0 else 0.0)
	I.add(props, "prop_drinking_fountain", "worn", A.q(sx, sz, 81.5, 34.5), 0.0)
	I.add(props, "prop_trash_receptacle", "dirty", A.q(sx, sz, 81.5, 45.0), 0.0)
	I.add(props, "prop_recycling_receptacle", "worn", A.q(sx, sz, 81.5, 46.2), 0.0)
	for lu: float in [81.0, 97.0]: I.add(props, "prop_lamp_globe", "worn", A.q(sx, sz, lu, 51.5), 0.0)
	for k2 in 8: dec.add(14, Vector2(sx * rr.randf_range(82.0, 97.0), sz * rr.randf_range(35.0, 50.0)), rr.randf_range(0, 180), 2.0, 1.6, S.walk_y, Color(1, 1, 1, 0.35))
	# ---- C: playground village + snack kiosk + picnic
	C.park(ctx, "park_playground_village", 31.6, 80.0, "-u")
	var kio := A.place(ctx.bl, sx, sz, "commercial/com_kiosk", 20.0, 95.5, "-v", "snack_kiosk")
	ctx.blds.append(kio)
	for k in 2: I.add(props, "prop_picnic_table", "worn", A.q(sx, sz, 40.0 + k * 6.0, 96.0), 90.0)
	for k in 2: I.add(props, "prop_shade_sail", "worn", A.q(sx, sz, 40.0 + k * 6.0, 96.0), 0.0)   # one sail OVER each table (Yasin 17 Nov: one sail between two tables shaded neither)
	I.add(props, "prop_trash_receptacle", "dirty", A.q(sx, sz, 25.0, 93.0), 0.0)
	I.add(props, "prop_recycling_receptacle", "worn", A.q(sx, sz, 26.0, 93.0), 0.0)
	dec.add(14, Vector2(sx * 20.0, sz * 91.5), 0.0, 3.0, 2.0, S.walk_y, Color(1, 1, 1, 0.55))    # the queue
	paints.append(A.rect(sx, sz, A.PROP, 79.0, 16.6, 81.0, "concrete"))
	# ---- D: skate park
	paints.insert(0, A.rect(sx, sz, 63.0, 63.0, 97.0, 97.0, "concrete"))
	for seg: Array in [[62.0, 62.0, 98.0, 62.0], [98.0, 62.0, 98.0, 98.0], [98.0, 98.0, 62.0, 98.0], [62.0, 98.0, 62.0, 81.2], [62.0, 78.8, 62.0, 62.0]]:
		A.privacy(props, Vector2(sx * float(seg[0]), sz * float(seg[1])), Vector2(sx * float(seg[2]), sz * float(seg[3])), "fence_chainlink", "fence_chainlink_post")
	I.add(props, "fence_gate_wrought_iron", "worn", A.q(sx, sz, 62.6, 80.6), 45.0)
	paints.append(A.rect(sx, sz, 60.0, 79.0, 63.0, 81.0, "concrete"))
	I.add(props, "prop_skate_bowl_section", "worn", A.q(sx, sz, 85.0, 86.0), 0.0)
	I.add(props, "prop_skate_quarter_pipe", "worn", A.q(sx, sz, 94.0, 70.0), -90.0)
	I.add(props, "prop_skate_quarter_pipe", "worn", A.q(sx, sz, 69.0, 72.0), 90.0)
	I.add(props, "prop_skate_funbox", "worn", A.q(sx, sz, 80.0, 71.0), 0.0)
	I.add(props, "prop_skate_grind_rail", "worn", A.q(sx, sz, 75.0, 79.0), 90.0)
	var shed := A.place(ctx.bl, sx, sz, "public/pub_skate_shed", 70.0, 91.5, "-v", "skate_shed")   # back wall 1.5 m inside the fence
	ctx.blds.append(shed)
	for k in 3: I.add(props, "fence_graffiti_cmu_panel", "worn", A.q(sx, sz, 88.0 + k * 2.03, 97.0), 0.0)
	for k in 2: I.add(props, "prop_park_bench", "dirty", A.q(sx, sz, 64.5, 66.0 + k * 3.0), -90.0 if sx > 0 else 90.0)
	I.add(props, "prop_trash_receptacle", "dirty", A.q(sx, sz, 64.5, 75.0), 0.0)
	I.add(props, "prop_bike_rack", "rusty", A.q(sx, sz, 61.0, 86.0), 90.0)
	SL.lot_light(props, sx, sz, 96.0, 64.0)
	for k in 14:   # wheel marks and scuffs where they land tricks
		dec.add(8 if k % 2 == 0 else 14, Vector2(sx * rr.randf_range(66.0, 95.0), sz * rr.randf_range(65.0, 95.0)), rr.randf_range(0, 180), rr.randf_range(0.5, 1.2), rr.randf_range(2.0, 4.0), S.walk_y, Color(1, 1, 1, 0.5))
	C.done(ctx)
	quit()
