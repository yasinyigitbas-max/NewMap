extends SceneTree
## Piece m_se (commercial strip sample, SE): Crown Grocery, the anchor.
## - The 60 x 44 m big box set back behind the biggest lot on the strip (a row along the landscape strip broken at both
##   arterial driveways, aisle, a row nose-in toward the store split by a planted island, the drop-off lane), a walk
##   with benches, bins, the propane-exchange cylinders, the mailbox, a bike rack.
## - A pharmacy pad on the corner with its own short row.
## - Side street: a thrift store and a pho house right on the sidewalk, the truck lane between them to the back.
## - Behind the store: the delivery yard (trailers at the back wall, the compactor bin, block enclosures, k-rails
##   guarding the corners, oil and tyre marks where trucks turn). Run once; never when locked.
const L := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var sx := 1.0; var sz := 1.0
	var root := Node3D.new(); root.name = "m_se"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for("m_se")
	var paints: Array = []; var stalls: Array = []
	var B: Array = []
	# ---------------------------------------------------------------- the grocery
	var gro := I.put(bl, props, sx, sz, "x", 36.0, 43.5, "commercial/com_grocery_bigbox", "crown_grocery")
	B.append([gro, "commercial/com_grocery_bigbox"])
	paints.append(L.rect(sx, sz, 30.0, 41.5, 97.0, 43.5, "concrete"))
	# walk furniture (doors at local x -26.5, -3.4, 3.4, 26.5; store centre u 66; yaw 180 -> local +x = world -x = smaller u)
	for e: Array in [[-14.0, "prop_park_bench"], [-11.0, "prop_trash_receptacle"], [10.0, "prop_trash_receptacle"], [14.0, "prop_park_bench"], [20.0, "prop_bike_rack"], [-22.0, "prop_usps_collection_box"]]:
		I.add(props, String(e[1]), "worn", L.q(sx, sz, 66.0 - float(e[0]), 42.4), 180.0 if String(e[1]) != "prop_bike_rack" else 0.0)
	for k in 5: I.add(props, "prop_propane_cylinder_100lb", "rusty", L.q(sx, sz, 66.0 + 7.0 + k * 0.45, 42.6), 0.0)
	for lx: float in [-26.5, -3.4, 3.4, 26.5]:
		I.add(props, "plant_potted_succulent", "normal", L.q(sx, sz, 66.0 - lx - 1.5, 43.0), 0.0)
	# ---------------------------------------------------------------- the lot
	for seg: Array in [[30.0, 3], [49.5, 9], [84.5, 4]]:
		L.stalls_u(paints, stalls, sx, sz, float(seg[0]), int(seg[1]), 22.8, -1.0)
	L.stalls_u(paints, stalls, sx, sz, 30.0, 11, 29.8, 1.0)
	L.stalls_u(paints, stalls, sx, sz, 65.0, 11, 29.8, 1.0)
	L.island(paints, props, rr, sx, sz, 59.9, 29.9, 64.9, 35.2, 0)
	L.island(paints, props, rr, sx, sz, 94.9, 29.9, 99.5, 35.2, 0)
	W.red_kerb(dec, Vector2(30.5, 41.5), Vector2(96.5, 41.5), Vector2(0.0, -1.0))
	for seg2: Array in [[12.5, 40.0], [50.0, 75.0], [85.0, 99.5]]:
		L.island(paints, props, rr, sx, sz, float(seg2[0]), 14.6, float(seg2[1]), 17.0, maxi(1, int((float(seg2[1]) - float(seg2[0])) / 9.0)))
	for p: Vector2 in [Vector2(62.4, 32.55), Vector2(28.8, 16.0), Vector2(62.0, 16.0), Vector2(97.2, 32.55), Vector2(91.0, 16.0)]:
		L.lot_light(props, sx, sz, p.x, p.y)
	# kit batch 2 (17 Nov): pylon at the arterial, cart corrals on the walk by the doors, carts people left at the islands
	L.pylon(props, sx, sz, 54.0)
	for cu: float in [84.0, 34.0]: I.add(props, "prop_cart_corral", "worn", L.q(sx, sz, cu, 42.4), 0.0)
	for cp: Vector3 in [Vector3(59.0, 36.4, 20.0), Vector3(65.9, 36.6, -35.0), Vector3(94.0, 36.3, 70.0)]:
		I.add(props, "prop_shopping_cart", "dirty" if cp.z > 30.0 else "worn", L.q(sx, sz, cp.x, cp.y), cp.z)
	# ---------------------------------------------------------------- pharmacy pad on the corner
	var ph := I.put(bl, props, sx, sz, "x", 13.0, 30.0, "modular/examples/mod_svc_row", "corner_pharmacy")
	B.append([ph, "modular/examples/mod_svc_row"])
	paints.append(L.rect(sx, sz, 12.0, 28.0, 26.0, 30.0, "concrete"))
	L.stalls_u(paints, stalls, sx, sz, 12.5, 4, 22.5, 1.0)
	I.add(props, "prop_trash_receptacle", "worn", L.q(sx, sz, 25.4, 29.0), 0.0)
	I.add(props, "prop_newspaper_box_blue", "worn", L.q(sx, sz, 12.4, 29.0), 0.0)
	# ---------------------------------------------------------------- side street: thrift store, pho house
	B.append([I.put(bl, props, sx, sz, "z", 50.0, I.FRONT, "commercial/com_boutique_row", "thrift_store"), "commercial/com_boutique_row"])
	B.append([I.put(bl, props, sx, sz, "z", 86.0, I.FRONT, "commercial/com_bistro", "pho_house"), "commercial/com_bistro"])
	I.walk_prop(props, sx, sz, "z", 68.5, "prop_newspaper_box_red")
	I.walk_prop(props, sx, sz, "z", 85.0, "prop_bike_rack", "worn")
	L.enclosure(props, L.q(sx, sz, 28.0, 92.0), 90.0)
	# ---------------------------------------------------------------- the delivery yard
	for u: float in [47.0, 53.0]:
		I.add(props, "prop_container_20ft_white", "dirty", L.q(sx, sz, u, 91.5), 0.0)    # trailers backed to the dock
	I.add(props, "prop_dumpster_rolloff_20yd", "rusty", L.q(sx, sz, 72.0, 92.0), 0.0)   # compactor
	L.enclosure(props, L.q(sx, sz, 86.0, 92.0), 180.0)
	for k in 2: I.add(props, "prop_k_rail", "worn", L.q(sx, sz, 36.5 + k * 59.0, 90.0), 90.0)
	I.add(props, "prop_utility_pole_transformer", "worn", L.q(sx, sz, 98.5, 94.0), 0.0)
	I.lot_fence(props, Vector2(30.0, 99.8), Vector2(99.8, 99.8)); I.lot_fence(props, Vector2(99.8, 87.5), Vector2(99.8, 99.8))
	L.lot_light(props, sx, sz, 62.0, 97.5)
	# ---------------------------------------------------------------- polish: drains, bollards, fire lane, crossing
	L.drains(props, sx, sz, [Vector2(45.0, 26.3), Vector2(80.0, 26.3), Vector2(50.0, 38.6), Vector2(85.0, 38.6), Vector2(70.0, 95.5)])
	L.bollards(props, sx, sz, [Vector2(61.0, 41.6), Vector2(64.0, 41.6), Vector2(68.0, 41.6), Vector2(71.0, 41.6)])
	for u5: float in [31.0, 96.0]: I.add(props, "prop_sign_no_parking", "worn", L.q(sx, sz, u5, 41.65), 180.0)   # FIRE LANE
	L.crossing(paints, sx, sz, 64.2, 67.8, 35.3, 41.5)
	I.add(props, "prop_sign_ped_crossing", "worn", L.q(sx, sz, 62.4, 34.7), 180.0)
	I.add(props, "prop_recycling_receptacle", "worn", L.q(sx, sz, 78.0, 42.4), 180.0)
	I.add(props, "prop_recycling_receptacle", "worn", L.q(sx, sz, 55.0, 42.4), 180.0)
	I.add(props, "prop_newspaper_box_red", "worn", L.q(sx, sz, 58.2, 42.4), 180.0)
	I.add(props, "prop_hydrant_wet_barrel", "rusty", L.q(sx, sz, 35.6, 16.2), 0.0)
	# ---------------------------------------------------------------- floor + wear
	K.painted_rect(g, L.PROP_S, L.PROP_A, 100.0, 100.0, paints, S.walk_y)
	for b: Array in B: I.bld_wear(dec, rr, b[0][0], b[0][1], b[0][2], b[1])
	L.stall_wear(dec, rr, stalls, 0.65)
	for a: float in L.APR_A: I.truck_path(dec, rr, Vector2(a, L.PROP_A), Vector2(a, 38.0))
	I.truck_path(dec, rr, Vector2(L.PROP_S, 80.0), Vector2(34.0, 80.0))
	I.truck_path(dec, rr, Vector2(34.0, 80.0), Vector2(50.0, 94.0))
	for k in 8: W.oil(dec, rr, Vector2(rr.randf_range(40.0, 92.0), rr.randf_range(88.5, 98.0)), 0.0, S.walk_y, 0.95)
	L.aisle_wear(dec, rr, sx, sz, 30.0, 98.0, 26.3)
	L.aisle_wear(dec, rr, sx, sz, 30.0, 98.0, 38.6)
	I.yard_wear(dec, rr, sx, sz, 9.0, 17.0, 99.0, 41.0, 1.1)
	I.yard_wear(dec, rr, sx, sz, 24.0, 44.0, 36.0, 99.0, 1.2)
	I.yard_wear(dec, rr, sx, sz, 36.0, 88.0, 99.0, 99.0, 1.6)
	L.finish(root, g, props, dec, "m_se", stalls)
	quit()
