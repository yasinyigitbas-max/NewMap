extends SceneTree
## Piece m_gr_e4n (commercial strip growth, VARIANT F "storage yard", 19 Nov): the narrow lot between the strip sample's
## tyre shop / self-storage and Glorietta Blvd, north of 4th St (grid u 600-645.7, v -1300 to -1214.3), placed at the strip
## junction (500, 4, -1200). The ring falls ~0.9 m along it toward 3rd St; the gravel follows.
## Why this use (city planner): 45 m wide, no driveway from 4th St (palm parkway) or the ring, the self-storage fence
## and the tyre shop's stalls along its back: no shop can live here. An island town on a bay keeps its boats and
## campers somewhere: a boat and RV storage yard behind chain-link and barbed wire, reached through the motel lot to the
## north (m_gr_e4s's back strip, a rolling gate), the power company's substation fenced off in its own corner on 4th St,
## and two billboards facing the ring and the bridge traffic - the land's real income on a corner like this.
## Variant differences: no building at all; boats on trailers (wf kit), storage containers, the substation, barbed wire.
## Run once (tools/city/run/build.sh m_gr_e4n); never when locked.
const G := preload("res://tools/city/pilot/pieces/strip_grow_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const BOATS := ["prop_boat_skiff", "prop_boat_sloop", "prop_boat_express", "prop_boat_troller"]
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var b := G.new("m_gr_e4n", "F storage yard")
	b.paints.append(b.rect(100.0, -100.0, 145.7, -14.3, "gravel"))
	# ---------------------------------------------------------------- the perimeter: chain-link + barbed wire, a post at every joint
	b.fence("chain", 100.0, -99.9, 130.0, -99.9)                              # north side (toward the motel lot) ...
	b.add("fence_gate_rolling_chainlink", "worn", 133.0, -99.9, 0.0)         # ... its gate, closed
	b.fence("chain", 136.0, -99.9, 142.6, -99.9)
	b.fence("chain", 142.6, -99.9, 142.6, -17.6)                              # the ring side, behind its planting
	b.fence("chain", 142.6, -17.6, 100.0, -17.6)                              # 4th St side
	b.fence("chain", 100.0, -17.6, 100.0, -58.0)                              # the back, up to the self-storage fence
	for k in 21: b.add("fence_barbed_wire", "rusty", 101.0 + k * 2.0, -17.6, 0.0, false, 1.86)
	for k in 41: b.add("fence_barbed_wire", "rusty", 142.6, -98.9 + k * 2.0, 90.0, false, 1.86)
	b.island(100.4, -17.3, 142.6, -14.6, 3, ["palm_mexican_fan_a", "palm_mexican_fan_c"])
	b.island(142.9, -99.4, 145.5, -14.6, 5, ["palm_mexican_fan_b", "palm_queen_a", "palm_mexican_fan_a"])
	# ---------------------------------------------------------------- the substation in its own fenced corner on 4th St
	b.fence("chain", 104.0, -34.0, 120.0, -34.0); b.fence("chain", 120.0, -34.0, 120.0, -17.6)
	b.fence("chain", 104.0, -34.0, 104.0, -17.6)
	b.add("prop_transformer_substation", "worn", 112.0, -26.0, 0.0)
	b.add("prop_switch_rack", "rusty", 116.6, -23.0, 90.0)
	b.add("prop_utility_pole_transformer", "worn", 106.0, -31.0, 0.0)
	# ---------------------------------------------------------------- boats and campers on trailers, in rows nose to the fences
	# (the kit's boat trailer carries its boat: one model per stored boat, as in the waterfront's boat storage)
	for k in 17:                                                               # along the ring fence, bows to the east
		var zb := -96.0 + k * 3.4
		if zb > -38.0: break
		b.add("prop_boat_trailer", "worn" if k % 3 else "dirty", 137.0, zb, 90.0)
	for k in 14:                                                               # the middle row, bows to the west
		b.add("prop_boat_trailer", "worn" if k % 4 else "dirty", 117.0, -94.0 + k * 3.4, -90.0)
	for k in 4: b.add(["prop_container_20ft_white", "prop_container_20ft_blue", "prop_container_20ft_green", "prop_container_20ft_red"][k], "dirty", 104.5, -90.0 + k * 2.6, 90.0)   # rented storage boxes
	b.add("prop_golf_cart_blue", "worn", 128.0, -94.0, 0.0)                   # the yard man's cart
	b.add("prop_kayak_rack", "worn", 104.0, -66.0, 90.0)
	# ---------------------------------------------------------------- billboards over the ring, lights, the yard's signs
	b.add("prop_billboard", "worn", 131.0, -46.0, 90.0)
	b.add("prop_billboard", "worn", 131.0, -80.0, 90.0)
	for p: Vector2 in [Vector2(126.0, -60.0), Vector2(110.0, -86.0)]:
		if b.free_at(p.x, p.y, 1.6): b.add("prop_lot_light_pole", "worn", p.x, p.y, 0.0)
	b.add("prop_sign_no_parking", "worn", 131.0, -98.8, 0.0)                  # KEEP CLEAR - GATE
	b.add("prop_cone_28in", "dirty", 128.6, -97.6, 0.0)
	# polish 19 Nov (whole-zone pass): the yard sells propane to the campers - a refill tank behind bollards by the drive
	b.add("prop_tank_horizontal_propane", "worn", 108.0, -48.0, 90.0)
	for q: Vector2 in [Vector2(106.6, -51.2), Vector2(109.4, -51.2), Vector2(106.6, -44.8), Vector2(109.4, -44.8)]:
		b.add("prop_bollard_concrete", "worn", q.x, q.y, 0.0)
	b.add("prop_sign_no_parking", "worn", 110.4, -48.0, -90.0)                # PROPANE - NO SMOKING
	for k in 3: b.add("prop_propane_cylinder_100lb", "worn", 105.6, -47.0 + k * 0.6, 0.0)
	# ---------------------------------------------------------------- wear: tyre ruts on the gravel, oil under the trailers
	b.tyre_path(133.0, -99.0, 127.0, -40.0); b.tyre_path(127.0, -40.0, 108.0, -45.0)
	for k in 12: W.oil(b.dec, b.rr, Vector2(b.rr.randf_range(112.0, 140.0), b.rr.randf_range(-96.0, -40.0)), 90.0, b.yfn, 0.7)
	b.yard_wear(100.5, -99.5, 142.0, -18.0, 0.5)
	b.finish()
	quit()
