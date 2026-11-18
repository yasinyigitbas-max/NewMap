extends SceneTree
## Piece i_va_w600_n1600_se (industrial growth, VARIANT A "port", second dressing; 18 Nov, not locked).
## Site: SE corner of 1st St (bay-front ring) x G Ave, world (-600..-500, -1600..-1500): the industrial zone's east
## end. Past u = 100 the houses begin (E Ave), so this block is the TRANSITION (CITY_PLAN: "an alley, park or yard
## between industrial and residential, never a hard jump").
## BAY BOATWORKS: a boatyard with dry storage. Trailered boats for the island's owners are kept here, an engine shop
## works on them, and a sail loft sits at the back. The bigger boats are "on the hard" waiting for paint.
## Planner's reasons:
##  - It is the quietest industry there is, so it goes next to the houses: no trucks at night, low sheds. The east edge
##    is a stucco wall with bougainvillea on the house side and a grass strip of torrey pines and eucalyptus.
##  - The yacht broker's office (walk-in) holds the boulevard corner. The rest of the boulevard frontage is chain-link,
##    on purpose: the boats ARE the shop window. It is the only see-through run on this sight line, because behind the
##    boats stand the opaque sail loft and the next block's block wall.
##  - G Ave carries the gates at the street's aprons (51, 86 m); the engine shop (walk-in counter) and the boat shed
##    line it.
## Run once; never when locked.
const G := preload("res://tools/city/pilot/pieces/ind_grow_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const NAME := "i_va_w600_n1600_se"
const WL := {"prop_boat_sloop": 1.40, "prop_boat_express": 0.70, "prop_boat_troller": 1.35, "prop_boat_skiff": 0.30}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var sx := 1.0; var sz := 1.0
	var m: Dictionary = await G.measure(self, Vector3(-600.0, 2.0, -1600.0), sx, sz)
	var root := Node3D.new(); root.name = NAME
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(NAME)
	var stl: Array = []
	var paints: Array = G.stall_paint(sx, sz, 26.0, 4, 34.5, -1.0)
	paints.append_array([[92.2, 24.0, 99.8, 99.8, "grass"], [38.0, 70.0, 90.0, 84.0, "gravel"]])   # buffer strip; boats on the hard
	G.floor(g, m, sx, sz, paints)
	var B: Array = []
	var fx := G.front_x(m, 22.0, 40.0)
	B.append([G.put(bl, props, sx, sz, "x", 23.0, fx, "civic/civ_harbor_office", "bay_boatworks_office"), "civic/civ_harbor_office"])
	var fz := G.front_z(m, 22.0, 100.0)
	B.append([G.put(bl, props, sx, sz, "z", 27.0, fz, "industrial/ind_repair", "marine_engines"), "industrial/ind_repair"])
	B.append([G.put(bl, props, sx, sz, "z", 56.0, fz, "industrial/ind_warehouse", "boat_shed"), "industrial/ind_warehouse"])
	B.append([G.put_back(bl, props, sx, sz, "x", 40.0, "ck/mod_stg_row_roofed", "sail_loft"), "ck/mod_stg_row_roofed"])
	G.frontage(props, m, sx, sz, "x", [[23.0, 39.0]], [], "chain", 41.0, 91.8)
	G.frontage(props, m, sx, sz, "z", [[27.0, 45.0], [56.0, 80.0]], [51.0, 86.0], "chain", 45.0, 99.8)
	G.house_buffer(props, rr, sx, sz, G.eu(m, 92.0) + 0.3, 99.8)
	# ---- dry storage: trailered boats in rows, bows to the aisles (the lane from the 51 m gate runs between them)
	for k in 14:
		if rr.randf() < 0.12: continue
		I.add(props, "prop_boat_trailer", "clean", G.q(sx, sz, 41.0 + k * 3.5, 36.0), 180.0)
	for k in 13:
		if rr.randf() < 0.1: continue
		I.add(props, "prop_boat_trailer", "clean", G.q(sx, sz, 41.0 + k * 3.5, 56.2), 0.0)
		if rr.randf() < 0.8: I.add(props, "prop_boat_trailer", "clean", G.q(sx, sz, 41.0 + k * 3.5, 63.6), 180.0)
	# ---- on the hard: keels on the gravel, cones round the painters' work, a skip for scraped paint
	var hard := [["prop_boat_sloop", 48.0, 77.0, 90.0], ["prop_boat_troller", 64.0, 76.5, 92.0], ["prop_boat_express", 80.0, 77.0, 88.0]]
	for b2: Array in hard:
		I.add(props, String(b2[0]), "worn", G.q(sx, sz, float(b2[1]), float(b2[2]), float(WL[String(b2[0])])), float(b2[3]))
	for k2 in 4: I.add(props, "prop_cone_18in", "dirty", G.q(sx, sz, 56.0 + k2 * 0.8, 72.0), k2 * 25.0)
	I.add(props, "prop_dumpster_3yd_blue", "rusty", G.q(sx, sz, 88.0, 83.0), 90.0)
	# ---- the yard's chandlery stock: buoys waiting for their moorings, dock boxes, a kayak rack by the office
	I.add(props, "prop_buoy_mooring", "clean", G.q(sx, sz, 86.0, 47.0), 0.0)
	I.add(props, "prop_buoy_can", "clean", G.q(sx, sz, 88.5, 44.5), 30.0)
	I.add(props, "prop_buoy_nun", "clean", G.q(sx, sz, 88.0, 49.5), 70.0)
	for k3 in 3: I.add(props, "prop_dock_box", "worn", G.q(sx, sz, 62.0 + k3 * 2.2, 83.6), 0.0)
	I.add(props, "prop_kayak_rack", "clean", G.q(sx, sz, 45.5, 19.5), 0.0)
	I.add(props, "prop_lifering_stand", "clean", G.q(sx, sz, 41.6, 24.0), 90.0)
	for p: Vector2 in [Vector2(40.0, 41.0), Vector2(70.0, 41.0), Vector2(88.0, 66.0)]:
		I.add(props, "prop_lot_light_pole", "worn", G.q(sx, sz, p.x, p.y), 0.0)
	# ---- customers' parking behind the broker's office, the engine shop's drums and gas
	stl.append_array(G.stalls(props, sx, sz, 26.0, 4, 34.5, -1.0))
	for k4 in 4: I.add(props, "prop_channelizer_drum", "dirty", G.q(sx, sz, 27.0, 47.0 + k4 * 0.85), 0.0)
	I.back_door_clutter(props, rr, G.q(sx, sz, 38.5, 32.5), 180.0, "shop")
	I.add(props, "prop_propane_cylinder_100lb", "rusty", G.q(sx, sz, 27.5, 41.0), 0.0)
	I.add(props, "prop_hose_reel_cart", "worn", G.q(sx, sz, 36.0, 70.0), 0.0)    # boats are washed down before storage
	# ---- sidewalk: the broker's bin and a paper box
	G.walk_prop(props, m, sx, sz, "x", 37.0, "prop_trash_receptacle", "worn")
	G.walk_prop(props, m, sx, sz, "z", 24.0, "prop_newspaper_box_red", "dirty")
	# ---- wear: trailers' tyre lines into the rows, wash water by the hose, paint scrapings on the hard
	for b: Array in B: I.bld_wear(dec, rr, b[0][0], b[0][1], b[0][2], b[1])
	I.truck_path(dec, rr, Vector2(sx * 9.0, sz * 51.0), Vector2(sx * 82.0, sz * 46.0))
	I.truck_path(dec, rr, Vector2(sx * 9.0, sz * 86.0), Vector2(sx * 38.0, sz * 80.0))
	dec.add(14, Vector2(sx * 36.0, sz * 73.0), 0.0, 6.0, 5.0, S.walk_y, Color(1, 1, 1, 0.6))
	for b3: Array in hard: dec.add(13, Vector2(sx * float(b3[1]), sz * float(b3[2])), 0.0, 4.0, 10.0, S.walk_y, Color(0.6, 0.62, 0.7, 0.35))
	I.yard_wear(dec, rr, sx, sz, 34.0, 30.0, 91.0, 70.0, 1.1)
	I.yard_wear(dec, rr, sx, sz, 22.0, 80.0, 40.0, 99.0, 0.8)
	root.set_meta("stalls", stl)
	I.finish(root, g, props, dec, NAME)
	quit()
