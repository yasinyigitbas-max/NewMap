extends SceneTree
## Piece n_cc_b3_am (city-centre fill, block 3, AMBER EAST WALL SOUTH OF 7TH; claude/fill-city-centre 19 Nov). Layout
## row (0, 6.0, -600), grid frame u = x, v = z - 600. Covers u 16..50, v -502.5..-409.7: Amber's east frontage south of
## the locked c_se down to 8th St, and alley A3 behind it.
## LAND: Amber's walk and c_se are flat at 6.15; 8th St's walk rises from 6.15 at Amber to 6.24 at u 50 (measured every
## 4 m on the 19 Nov dump); the land 6.10..6.27. Ground: level at 6.15, and its last 18 m (z 172..190.3) eased up to
## 8th St's walk height across its whole width, so the alley mouth and the yard meet the walk flush (no step).
## PLANNER: Amber x 8th is the south gateway of the centre: the block's VERY TALL building stands on it (Yasin: "add
## one very tall building to every block you make, alternative in between them"; block 3 takes the 59 m glass tower,
## block 2 the condo, block 1 the glass). Alley A3 carries c_se's alley on to the 8th St apron that exists at u 44..50.
## ARCHITECT: glass tower 59 m; then (north) a brick shop-and-flat (a flower shop), a 4-storey stucco block (a Greek
## taverna under flats), a 3-storey brick row (opticians, a stationer, a tailor's alterations), a brick corner (a
## coffee roaster's cafe) by the passage to c_se. EXTERIOR: pots, racks, papers at the tower door, the yard and alley.
## The tower stands on its pad at 6.15; where the ground eases up to 8th St under its south-east corner its base is up
## to 4 cm lower than the ground there (not looked at from 8th St yet).
## Run with CCF_STAGE=ground first. Draft: never when locked.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const O := Vector3(0.0, 6.0, -600.0)
## 8th St walk height (m over the 6.0 pad datum) by u, measured on the dump at v -409.6
const T8 := [[16.0, 0.15], [28.0, 0.153], [36.0, 0.172], [44.0, 0.206], [52.0, 0.255]]
func h8(x: float) -> float: return L.prof(T8, x)
func ramp(x: float, z: float) -> float: return 0.15 + (h8(x) - 0.15) * clampf((z - 172.0) / 18.3, 0.0, 1.0)
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var c := L.new("n_cc_b3_am")
	c.terrain([[16.0, 97.5, 50.0, 172.0, func(_x: float, _z: float) -> float: return 0.15], [16.0, 172.0, 50.0, 190.3, ramp]])
	c.paint("plaza", 16.0, 97.5, 44.0, 102.1)              # the passage beside c_se's cafe
	c.build_floor(L.rect_edges(16.0, 97.5, 50.0, 190.3))
	if c.stage == "ground": c.finish(); quit(); return
	c.neighbours([["s_am_b041_b", Vector3(0, 6, -400), 180.0], ["j_am_8th", Vector3(0, 6, -400), 0.0], ["s_rs_b105_a", Vector3(0, 6, -400), 90.0],
		["c_se", Vector3(0, 6, -600), 0.0], ["d_cc", Vector3(0, 6, -600), 0.0], ["s_am_fill_cc", Vector3(0, 6, -600), 180.0], ["s_cc_amber_s", Vector3(0, 6, -600), 0.0]], O)
	var y := 0.15
	var T: Dictionary = c.row(["urban/twr_glass"], ["amber8_glass_tower"], 190.2, -1.0, "w", 16.0, true)[0]
	var R := c.row(["ck/ck_brk3_row2", "apartments/apt_stucco3_cream", "modular/examples/mod_brk_row", "ck/ck_brk3_corner2"],
		["amber_se_florist", "amber_se_taverna_block", "amber_se_brick_row", "amber_se_corner_cafe"], 165.86, -1.0, "w", 16.0, true)
	for r: Dictionary in [T] + R:
		for dr: Array in c.front_shops(r):
			var dp: Vector3 = dr[1]
			for s: float in [-1.2, 1.2]: c.put("plant_potted_succulent", "normal", Vector3(dp.x - 0.4, y, dp.z + s * 1.08), 0.0, "shops: a pot either side of the door")
	c.put("prop_newspaper_box_red", "worn", c.at(T, 6.6, 12.4), -90.0, "tower: papers where office staff walk in")
	c.put("prop_newspaper_box_blue", "worn", c.at(T, 7.4, 12.4), -90.0, "tower: papers where office staff walk in")
	c.put("plant_potted_leafy", "normal", Vector3(17.4, y, 100.0), 0.0, "passage: a planter marks it from Amber")
	c.put("prop_bike_rack", "worn", Vector3(38.0, y, 100.2), 0.0, "passage: bikes along the wall, off the way through")
	# ---- yard and alley A3
	c.services(T, -5.5, 2, false)
	for r2: Dictionary in R: c.services(r2, 4.0, 1, String(r2.folder).contains("brk3") or String(r2.folder).contains("stucco"))
	c.put("prop_dumpster_3yd_green", "worn", Vector3(42.4, 0.15, 160.0), 90.0, "tower: office waste by the alley")
	c.put("prop_dumpster_3yd_blue", "worn", Vector3(42.4, 0.15, 157.0), 90.0, "tower: paper recycling")
	c.put("prop_dumpster_3yd_green", "rusty", Vector3(42.4, 0.15, 130.0), 90.0, "taverna: kitchen waste")
	c.put("prop_propane_cylinder_100lb", "worn", Vector3(32.4, 0.15, 136.5), 0.0, "taverna: grill propane by its back door")
	c.put("prop_transformer_substation", "worn", Vector3(40.4, 0.15, 112.0), 90.0, "the strip's transformer (underground wires)")
	for bz: float in [109.8, 114.2]: c.put("prop_bollard_steel", "worn", Vector3(42.6, 0.15, bz), 0.0, "protects the transformer from trucks turning")
	c.stalls.append([38.0, 147.0, -90.0]); c.oil(Vector2(38.0, 147.0), 90.0)     # the florist's van
	c.alley_wear(44.0, 97.5, 50.0, 190.3, true)
	c.tyre(Vector2(47.0, 187.6), 25.0, 5.0, 0.4); c.tyre(Vector2(45.6, 187.0), 15.0, 5.0, 0.35)
	c.put("prop_manhole_cover", "worn", Vector3(47.0, 0.155, 125.0), 0.0, "sewer under the alley", false)
	c.put("prop_storm_drain_grate", "worn", Vector3(47.0, c.yf(47.0, 186.0) + 0.005, 186.0), 0.0, "the alley drains to the street at its mouth", false)
	c.cracks(32.0, 104.0, 43.6, 165.0, 12, 0.4)
	c.roof_plant(T, [[-6.0, -6.0, "prop_ac_condenser"], [0.0, -6.0, "prop_ac_condenser"], [6.0, -6.0, "prop_ac_condenser"], [-5.0, 5.0, "prop_vent_box"], [5.0, 5.0, "prop_vent_plumbing"]], "roof plant (tower)")
	for r3: Dictionary in R: c.roof_plant(r3, [[-4.0, -3.0, "prop_ac_condenser_compact"], [3.0, -3.0, "prop_vent_plumbing"], [0.0, 2.0, "prop_vent_turbine"]], "roof plant")
	for r4: Dictionary in [T] + R:
		for dr2: Array in r4.doors:
			var q: Vector3 = dr2[1]; var o: Vector3 = dr2[2]
			c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.6, 1.4, 0.4)
	c.finish()
	quit()
