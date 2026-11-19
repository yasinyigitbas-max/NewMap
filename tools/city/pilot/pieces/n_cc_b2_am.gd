extends SceneTree
## Piece n_cc_b2_am (city-centre fill, block 2, AMBER EAST WALL; claude/fill-city-centre 19 Nov). Layout row (0, 6.0,
## -600), grid frame u = x, v = z - 600. Covers u 16..50, v -790.3..-697.5: Amber's east frontage north of the locked
## c_ne up to 6th St, and alley A2 behind it.
## LAND: flat. Land 5.95..6.11 m; the Amber walk (s_am_b040_a, j_am_6th), the 6th St walk (s_rs_b093_a, edge v -790.3)
## and its alley apron at u 44..50, c_ne's floor and alley (6.15) all measured on the 19 Nov dump: one pad at 6.15.
## PLANNER: Amber x 6th is the centre's north gateway. Block 1 has the 59 m glass tower on its west corner; this corner
## takes the block's VERY TALL building (Yasin: "add one very tall building to every block you make, alternative in
## between them"): the 50 m condo tower, so the two towers frame Amber as you drive in. People live in it: its garden
## (lawn, grill, table, benches) is behind it, closed to 6th St by iron and a gate. Alley A2 carries c_ne's alley on to
## the 6th St apron at u 44..50: deliveries never use Amber.
## ARCHITECT: condo tower 50 m (36 m along Amber); a 3-storey brick row (ice cream, jewellery, a gallery), a 4-storey
## stucco block with a wine bar under the flats, a brick shop-and-flat with fire escapes (shoes), and a 7 m passage to
## the alley beside c_ne's corner block. EXTERIOR: door pots, bike racks parallel to the fronts, the service yard
## (bins by the back doors, meters, condensers, a transformer), the alley worn hardest.
## Run with CCF_STAGE=ground first. Draft: never when locked.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const O := Vector3(0.0, 6.0, -600.0)
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var c := L.new("n_cc_b2_am")
	c.pad(16.0, -190.3, 50.0, -97.5)
	c.paint("grass", 34.0, -189.6, 43.4, -158.0)            # the condo residents' garden
	c.paint("concrete", 34.0, -158.0, 43.4, -156.8)         # its path to the back door side
	c.paint("plaza", 16.0, -102.2, 44.0, -97.5)             # the passage beside c_ne's corner block
	c.build_floor(L.rect_edges(16.0, -190.3, 50.0, -97.5))
	if c.stage == "ground": c.finish(); quit(); return
	c.neighbours([["s_am_b040_a", Vector3(0, 6, -800), 0.0], ["j_am_6th", Vector3(0, 6, -800), 0.0], ["s_rs_b093_a", Vector3(0, 6, -800), 90.0],
		["c_ne", Vector3(0, 6, -600), 0.0], ["d_cc", Vector3(0, 6, -600), 0.0], ["s_am_fill_cc", Vector3(0, 6, -600), 0.0], ["s_cc_amber_n", Vector3(0, 6, -600), 0.0]], O)
	var y := c.y0
	# ---- the Amber wall, facing west, stats facades on the property line u 16 (as c_ne stands)
	var R := c.row(["urban/twr_condo_shores", "urban/urb_brick_row", "apartments/apt_stucco3_peach", "ck/ck_brk3_row2_fe"],
		["amber6e_condo", "amber_e_brick_row", "amber_e_wine_block", "amber_e_shoes_fe"], -190.2, 1.0, "w", 16.0, true)
	var CT: Dictionary = R[0]; var BR: Dictionary = R[1]; var WB: Dictionary = R[2]; var FE: Dictionary = R[3]
	# ---- street side (Amber's walk): pots at the shop doors, racks along the fronts
	for r: Dictionary in [BR, WB, FE]:
		for dr: Array in c.front_shops(r):
			var dp: Vector3 = dr[1]
			for s: float in [-1.2, 1.2]: c.put("plant_potted_succulent", "normal", Vector3(dp.x - 0.4, y, dp.z + s * 1.08), 0.0, "shops: a pot either side of the door")
	c.put("prop_bike_rack", "worn", c.at(BR, 7.6, 7.5), -90.0, "brick row: bikes parallel to the front (ice cream customers)")
	c.put("prop_bike_rack", "worn", c.at(WB, -7.8, 6.6), -90.0, "wine bar: bikes parallel to the front")
	c.put("prop_newspaper_box_red", "worn", c.at(CT, -15.4, 8.6), -90.0, "condo corner: papers at the gateway corner")
	c.put("prop_trash_receptacle", "worn", c.at(CT, -16.6, 8.6), -90.0, "condo corner: a bin at the crossing")
	# the passage beside c_ne: a planter at each end, a bench against the wine block's side for people waiting
	c.put("plant_potted_leafy", "normal", Vector3(17.4, y, -100.0), 0.0, "passage: a planter marks it from Amber")
	c.put("prop_bike_rack", "worn", Vector3(38.0, y, -100.2), 0.0, "passage: bikes along the wall, off the way through")
	# ---- the condo's garden (residents only): lawn, a table, a grill, benches, trees; iron to 6th St and the alley
	for t: Array in [[36.5, -186.0, "tree_jacaranda_a", 0.9], [41.0, -171.0, "tree_magnolia_b", 0.85], [36.0, -162.5, "tree_coral_a", 0.9]]:
		c.put(String(t[2]), "normal", Vector3(float(t[0]), y, float(t[1])), c.rr.randf_range(0, 360), "condo garden: trees in the lawn", true, float(t[3]))
	c.put("prop_picnic_table", "worn", Vector3(39.4, y, -178.0), 90.0, "condo garden: residents eat out")
	c.put("prop_bbq_gas_cart", "worn", Vector3(42.4, y, -182.4), -90.0, "condo garden: the shared grill")
	c.put("prop_park_bench", "worn", Vector3(42.6, y, -166.0), -90.0, "condo garden: bench facing the lawn")
	c.put("prop_adirondack_white", "worn", Vector3(37.0, y, -167.6), 160.0, "condo garden: a lounger in the sun")
	c.put("prop_adirondack_white", "worn", Vector3(38.4, y, -168.4), 200.0, "condo garden: a lounger in the sun")
	c.iron(Vector2(33.9, -190.0), Vector2(43.6, -190.0), "condo garden: iron fence to 6th St")
	c.iron(Vector2(43.6, -190.0), Vector2(43.6, -160.4), "condo garden: iron fence to the alley")
	c.put("fence_gate_wrought_iron", "worn", Vector3(43.6, y, -159.85), 90.0, "condo garden: the residents' gate from the alley", false)
	c.iron(Vector2(43.6, -159.3), Vector2(43.6, -156.6), "condo garden: iron fence to the alley")
	c.iron(Vector2(43.6, -156.6), Vector2(33.6, -156.6), "condo garden: iron fence to the service yard")
	# ---- service yard and alley A2: bins by the back doors, meters, condensers, the block's transformer
	c.services(CT, -15.0, 2, false)
	c.put("prop_dumpster_3yd_green", "worn", Vector3(42.4, y, -153.4), 90.0, "condo: residents' waste by the alley")
	c.put("prop_dumpster_3yd_blue", "worn", Vector3(42.4, y, -150.4), 90.0, "condo: recycling by the alley")
	c.services(BR, -4.0, 2, false)
	c.put("prop_dumpster_3yd_green", "rusty", Vector3(42.4, y, -141.0), 90.0, "ice cream / gallery: shop waste")
	c.put("prop_ice_chest", "worn", Vector3(32.0, y, -139.4), 90.0, "ice cream shop: the ice chest by its back door")
	c.services(WB, 4.0, 2, true)
	c.put("prop_dumpster_3yd_blue", "worn", Vector3(42.4, y, -125.0), 90.0, "wine bar: bottles and cardboard")
	c.put("prop_recycling_receptacle", "worn", Vector3(33.0, y, -116.8), 90.0, "wine bar: empties by the back door")
	c.services(FE, -2.0, 1, true)
	c.put("prop_transformer_substation", "worn", Vector3(40.4, y, -110.0), 90.0, "the block's transformer (wires underground in the centre)")
	c.put("prop_bollard_steel", "worn", Vector3(42.6, y, -112.2), 0.0, "protects the transformer from trucks turning")
	c.put("prop_bollard_steel", "worn", Vector3(42.6, y, -107.8), 0.0, "protects the transformer from trucks turning")
	c.stalls.append([38.0, -133.0, -90.0]); c.oil(Vector2(38.0, -133.0), 90.0)     # the wine bar owner's car in the yard
	c.alley_wear(44.0, -190.3, 50.0, -97.5, true)
	c.tyre(Vector2(47.0, -187.0), -25.0, 5.0, 0.4); c.tyre(Vector2(45.6, -186.6), -15.0, 5.0, 0.35)
	c.put("prop_manhole_cover", "worn", Vector3(47.0, y + 0.005, -170.0), 0.0, "sewer under the alley", false)
	c.put("prop_storm_drain_grate", "worn", Vector3(47.0, y + 0.005, -128.0), 0.0, "the alley drains to its middle", false)
	c.cracks(33.6, -155.0, 43.6, -105.0, 14, 0.4)
	# ---- roofs
	c.roof_plant(CT, [[-12.0, -5.0, "prop_ac_condenser"], [-6.0, -5.0, "prop_ac_condenser"], [6.0, -5.0, "prop_ac_condenser"], [12.0, -5.0, "prop_vent_box"], [0.0, 4.0, "prop_satellite_dish"]], "roof plant (condo tower)")
	c.roof_plant(BR, [[-6.0, -3.0, "prop_vent_box"], [0.0, -3.0, "prop_ac_condenser"], [6.0, -3.0, "prop_ac_condenser_compact"], [3.0, 2.0, "prop_vent_turbine"]], "roof plant (old brick)")
	c.roof_plant(FE, [[3.0, -3.0, "prop_tv_antenna"], [-3.5, 3.0, "prop_vent_plumbing"]], "roof plant (flats)")
	for r2: Dictionary in [CT, BR, WB, FE]:
		for dr2: Array in r2.doors:
			var q: Vector3 = dr2[1]; var o: Vector3 = dr2[2]
			c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.6, 1.4, 0.4)
	c.finish()
	quit()
