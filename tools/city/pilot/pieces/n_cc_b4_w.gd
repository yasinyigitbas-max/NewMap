extends SceneTree
## Piece n_cc_b4_w (city-centre fill, block 4, C AVE SIDE AND ALLEY A4; claude/fill-city-centre 19 Nov). Layout row
## (0, 6.0, -600), grid frame u = x, v = z - 600. Covers u -190.8..-143, v -900..-809.2: the C Ave x 6th corner, the C Ave
## frontage up the hill, and the west half of alley A4 (the other half is in n_cc_b4_e; the seam runs down its middle).
## LAND (read first, 19 Nov dump + zoning/terrain_grid.npz, table LAND below): rises from 6.0 by 6th St to 7.4 at the
## north edge. 6th St's walk 6.15 (edge v -809.2; the C Ave corner's curb return from (-190.8, -811.7) to (-188.3,
## -809.2)); C Ave's walk 6.15 at v -822 rising to 7.15 at v -900 (table WC); the housing square to the north (locked
## r_q_m200_m1000_se) meets this block at 7.34 (u < -154), 7.40 (u -154..-146) and its LANE at u -146..-140 (7.40..7.47).
## PLANNER: the square's lane was built to run on: alley A4 carries it straight down to the driveway apron that already
## exists on 6th St at u -146.6..-139.4, so the housing square gets a way out and this block a service alley.
## GROUND: the tower and the corner on a pad at 6.15; the C Ave flats each on a level pad at C Ave's highest point along
## the building, with a frontage strip flush with the walk in front; open ground (the residents' garden, the parking
## court, the yard behind the tower) follows the land, eased smoothly to every edge it meets (the walk, the alley, the
## square); a retaining face wherever a pad and open ground meet more than 2 cm apart.
## ARCHITECT: the block's VERY TALL building is the 50 m CONDO TOWER on the C Ave x 6th corner (Yasin: "add one very
## tall building to every block you make, alternative in between them": block 4 the condo, block 5 the glass); a paved
## pocket between it and the alley; walk-up and Spanish flats climbing C Ave (the edge toward the apartment band).
## EXTERIOR: the tower's entrance (pots, bikes, papers), the pocket (benches, trees in wells, a kiosk), the residents'
## garden on the slope (trees, a table, washing), parking off the alley, bins by back doors, the alley worn.
## Run with CCF_STAGE=ground first. Draft: never when locked.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const O := Vector3(0.0, 6.0, -600.0)
const LAND := {"x0": -192.0, "z0": -304.0, "step": 4.0, "nx": 46, "nz": 25, "h": [1.06,1.29,1.29,1.29,1.29,1.29,1.29,1.29,1.29,1.23,1.32,1.42,1.44,1.40,2.47,2.59,2.59,2.59,2.51,3.14,3.19,3.19,3.19,2.27,2.33,2.41,2.49,2.57,2.65,2.72,2.80,2.86,2.93,2.99,3.05,3.08,3.06,3.18,3.32,3.32,3.32,3.32,3.32,3.32,3.29,3.14,0.99,1.29,1.29,1.29,1.29,1.29,1.29,1.29,1.29,1.26,1.31,1.32,1.35,1.30,2.29,2.59,2.59,2.59,2.51,3.14,3.19,3.19,3.19,2.12,2.20,2.28,2.35,2.42,2.50,2.57,2.63,2.70,2.76,2.82,2.87,2.90,2.85,2.96,3.32,3.32,3.32,3.32,3.32,3.29,3.07,2.92,0.91,1.03,1.29,1.29,1.29,1.29,1.29,1.29,1.29,1.26,1.30,1.32,1.36,1.33,2.32,2.59,2.59,2.59,2.54,3.14,3.19,3.19,3.19,2.13,2.21,2.28,2.36,2.43,2.50,2.57,2.64,2.70,2.76,2.82,2.87,2.90,2.82,2.79,3.32,3.32,3.32,3.32,3.32,2.89,2.85,2.70,0.84,0.95,1.08,1.13,1.16,1.17,1.19,1.20,1.21,1.23,1.26,1.32,1.40,1.56,1.95,2.20,2.30,2.37,2.46,2.67,2.76,2.74,2.64,2.29,2.21,2.21,2.24,2.29,2.34,2.40,2.45,2.51,2.55,2.61,2.64,2.66,2.68,2.72,2.90,2.96,2.97,2.94,2.88,2.67,2.64,2.49,0.77,0.88,0.96,1.00,1.05,1.07,1.09,1.12,1.14,1.18,1.22,1.30,1.39,1.54,1.76,1.93,2.06,2.15,2.25,2.36,2.42,2.41,2.34,2.20,2.12,2.11,2.12,2.15,2.19,2.24,2.28,2.33,2.36,2.39,2.43,2.46,2.49,2.53,2.62,2.65,2.66,2.63,2.56,2.46,2.42,2.27,0.69,0.80,0.86,0.91,0.94,0.98,1.01,1.04,1.07,1.12,1.17,1.25,1.34,1.45,1.61,1.74,1.86,1.94,2.03,2.10,2.15,2.14,2.10,2.05,2.00,1.99,1.99,2.02,2.04,2.08,2.11,2.14,2.17,2.20,2.24,2.26,2.29,2.32,2.37,2.38,2.38,2.36,2.31,2.25,2.21,2.06,0.62,0.73,0.77,0.82,0.86,0.90,0.93,0.97,1.01,1.06,1.11,1.17,1.26,1.36,1.48,1.58,1.68,1.75,1.83,1.88,1.91,1.93,1.91,1.89,1.86,1.86,1.86,1.88,1.89,1.91,1.94,1.97,2.00,2.02,2.05,2.07,2.10,2.11,2.13,2.15,2.14,2.13,2.09,2.05,2.01,1.86,0.55,0.66,0.70,0.75,0.79,0.83,0.86,0.91,0.95,0.99,1.05,1.11,1.18,1.26,1.35,1.43,1.52,1.58,1.64,1.69,1.72,1.74,1.73,1.73,1.72,1.72,1.72,1.73,1.75,1.76,1.79,1.80,1.83,1.84,1.87,1.89,1.90,1.92,1.92,1.93,1.92,1.91,1.88,1.85,1.80,1.65,0.48,0.60,0.64,0.69,0.73,0.77,0.80,0.84,0.89,0.93,0.98,1.03,1.10,1.17,1.24,1.31,1.37,1.43,1.48,1.52,1.55,1.57,1.57,1.58,1.58,1.57,1.58,1.59,1.60,1.61,1.63,1.65,1.67,1.68,1.69,1.71,1.71,1.73,1.72,1.73,1.72,1.71,1.68,1.66,1.61,1.46,0.42,0.53,0.58,0.63,0.67,0.71,0.75,0.79,0.83,0.87,0.92,0.97,1.03,1.08,1.13,1.20,1.24,1.30,1.34,1.38,1.40,1.42,1.43,1.43,1.44,1.44,1.45,1.46,1.47,1.48,1.49,1.50,1.51,1.52,1.53,1.54,1.55,1.55,1.55,1.54,1.53,1.51,1.49,1.47,1.42,1.27,0.35,0.47,0.52,0.56,0.61,0.65,0.70,0.73,0.78,0.82,0.86,0.90,0.95,1.00,1.04,1.09,1.13,1.18,1.21,1.25,1.27,1.29,1.30,1.30,1.31,1.32,1.33,1.33,1.34,1.35,1.36,1.36,1.37,1.38,1.38,1.39,1.39,1.39,1.38,1.37,1.35,1.33,1.32,1.29,1.24,1.09,0.29,0.41,0.46,0.51,0.56,0.60,0.65,0.68,0.73,0.76,0.81,0.84,0.88,0.93,0.96,1.01,1.04,1.08,1.10,1.13,1.15,1.16,1.18,1.18,1.20,1.20,1.21,1.21,1.22,1.22,1.23,1.24,1.24,1.24,1.24,1.25,1.24,1.24,1.23,1.21,1.19,1.17,1.15,1.12,1.07,0.92,0.22,0.36,0.41,0.46,0.51,0.55,0.60,0.63,0.67,0.71,0.74,0.78,0.81,0.86,0.89,0.93,0.95,0.99,1.01,1.03,1.05,1.06,1.07,1.08,1.09,1.09,1.10,1.10,1.10,1.11,1.11,1.12,1.11,1.12,1.12,1.12,1.11,1.09,1.08,1.06,1.04,1.02,0.99,0.96,0.91,0.76,0.18,0.31,0.37,0.41,0.46,0.50,0.54,0.58,0.61,0.65,0.68,0.72,0.75,0.79,0.82,0.85,0.87,0.90,0.92,0.94,0.96,0.97,0.98,0.98,0.99,0.99,0.99,1.00,1.00,1.01,1.01,1.01,1.01,1.01,1.00,0.99,0.98,0.97,0.96,0.93,0.91,0.88,0.85,0.81,0.76,0.61,0.13,0.26,0.32,0.37,0.41,0.45,0.49,0.53,0.56,0.59,0.62,0.66,0.69,0.72,0.74,0.77,0.80,0.82,0.84,0.85,0.87,0.88,0.89,0.90,0.90,0.91,0.91,0.91,0.91,0.91,0.91,0.91,0.90,0.90,0.89,0.88,0.87,0.86,0.84,0.81,0.79,0.75,0.71,0.67,0.62,0.47,0.09,0.22,0.28,0.32,0.36,0.40,0.44,0.48,0.50,0.54,0.56,0.60,0.62,0.64,0.67,0.69,0.72,0.74,0.76,0.77,0.79,0.80,0.80,0.81,0.81,0.82,0.82,0.82,0.82,0.83,0.82,0.81,0.81,0.80,0.80,0.78,0.77,0.75,0.74,0.71,0.68,0.64,0.59,0.54,0.50,0.35,0.05,0.19,0.23,0.28,0.32,0.36,0.39,0.43,0.45,0.48,0.51,0.53,0.56,0.58,0.60,0.62,0.65,0.66,0.68,0.69,0.70,0.71,0.72,0.73,0.73,0.73,0.73,0.74,0.74,0.73,0.73,0.73,0.72,0.71,0.71,0.70,0.69,0.67,0.64,0.62,0.58,0.54,0.49,0.43,0.38,0.23,0.02,0.16,0.20,0.25,0.28,0.32,0.35,0.38,0.40,0.42,0.45,0.47,0.49,0.51,0.53,0.55,0.57,0.58,0.59,0.61,0.61,0.63,0.63,0.64,0.64,0.65,0.65,0.64,0.65,0.64,0.64,0.64,0.64,0.63,0.62,0.61,0.59,0.58,0.55,0.53,0.49,0.45,0.40,0.33,0.30,0.14,-0.01,0.13,0.17,0.21,0.25,0.28,0.30,0.32,0.35,0.37,0.39,0.41,0.43,0.45,0.46,0.48,0.49,0.50,0.51,0.53,0.53,0.54,0.54,0.55,0.55,0.55,0.56,0.56,0.56,0.56,0.56,0.55,0.55,0.54,0.53,0.52,0.51,0.49,0.47,0.45,0.41,0.37,0.32,0.25,0.22,0.07,-0.03,0.11,0.15,0.19,0.21,0.23,0.26,0.28,0.30,0.32,0.34,0.35,0.37,0.38,0.39,0.40,0.41,0.43,0.43,0.44,0.45,0.46,0.46,0.46,0.47,0.47,0.47,0.47,0.47,0.47,0.47,0.46,0.46,0.45,0.44,0.44,0.42,0.41,0.39,0.37,0.34,0.30,0.25,0.19,0.16,0.02,-0.04,0.10,0.13,0.16,0.18,0.20,0.22,0.23,0.25,0.26,0.28,0.29,0.30,0.31,0.32,0.33,0.34,0.35,0.35,0.36,0.36,0.36,0.37,0.37,0.38,0.38,0.38,0.38,0.38,0.38,0.37,0.37,0.37,0.37,0.36,0.35,0.34,0.33,0.32,0.30,0.27,0.24,0.20,0.14,0.12,-0.02,-0.05,0.10,0.12,0.14,0.15,0.17,0.18,0.19,0.20,0.21,0.22,0.23,0.23,0.24,0.25,0.26,0.26,0.27,0.27,0.27,0.28,0.28,0.28,0.28,0.29,0.29,0.29,0.29,0.28,0.29,0.28,0.28,0.28,0.28,0.27,0.27,0.26,0.25,0.24,0.23,0.21,0.19,0.15,0.10,0.10,-0.05,-0.05,0.10,0.11,0.12,0.13,0.13,0.14,0.15,0.15,0.16,0.16,0.16,0.17,0.17,0.17,0.18,0.18,0.18,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.18,0.18,0.18,0.17,0.16,0.16,0.14,0.12,0.10,0.10,-0.05,-0.05,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,-0.05]}
## C Ave walk height (m over the 6.0 datum) by z, measured every 2 m on the 19 Nov dump at u -191.25
const WC := [[-301.0, 1.164], [-299.0, 1.127], [-297.0, 1.089], [-295.0, 1.052], [-293.0, 1.014], [-291.0, 0.977], [-289.0, 0.941], [-287.0, 0.904], [-285.0, 0.868], [-283.0, 0.832], [-281.0, 0.796], [-279.0, 0.761], [-277.0, 0.726], [-275.0, 0.693], [-273.0, 0.659], [-271.0, 0.626], [-269.0, 0.594], [-267.0, 0.563], [-265.0, 0.532], [-263.0, 0.502], [-261.0, 0.473], [-259.0, 0.446], [-257.0, 0.418], [-255.0, 0.393], [-253.0, 0.367], [-251.0, 0.344], [-249.0, 0.321], [-247.0, 0.300], [-245.0, 0.279], [-243.0, 0.260], [-241.0, 0.243], [-239.0, 0.227], [-237.0, 0.212], [-235.0, 0.199], [-233.0, 0.187], [-231.0, 0.177], [-229.0, 0.168], [-227.0, 0.161], [-225.0, 0.156], [-223.0, 0.153], [-221.0, 0.151], [-219.0, 0.150], [-200.0, 0.150]]
func wc(z: float) -> float: return L.prof(WC, z)
## the housing square's edge at v -900 (z -300)
func ne(x: float) -> float:
	if x < -154.0: return 1.34
	if x < -146.0: return 1.40
	if x < -140.0: return 1.40 + (x + 146.0) / 6.0 * 0.07
	return 2.64
## alley A4: from 6th St's apron (0.15 at z -209.2) straight up to the square's lane end (z -300), cross-fall as the lane
func a4(x: float, z: float) -> float: return 0.15 + clampf((-209.2 - z) / 90.8, 0.0, 1.0) * (ne(clampf(x, -146.0, -140.001)) - 0.15)
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var c := L.new("n_cc_b4_w")
	var land := func(x: float, z: float) -> float: return L.land_at(LAND, x, z)
	var TOWER := ["urban/twr_condo_shores"]
	var tb := -209.2 - L.depth_of(TOWER) - 0.3                     # behind the tower
	var CAVE := ["ck/ck_apt3_row3", "apartments/apt_spanish_revival", "ck/ck_apt3_row2", "ck/ck_apt3_row3", "apartments/apt_garden_cream", "ck/ck_apt3_row2"]
	var cb := -190.8 + L.depth_of(CAVE) + 0.5                       # behind the C Ave flats
	var lots: Array = []
	var ft := c.front_lots(lots, TOWER, -188.3, 1.0, "s", -209.2, func(_a: float) -> float: return 0.15, tb, -152.0)
	var tw_end: float = ft.end
	lots.append([-190.8, tb, -188.3, -209.2, func(_x: float, _z: float) -> float: return 0.15])          # beside the tower, to C Ave and its curb return
	lots.append([tw_end, tb, -146.0, -209.2, func(_x: float, _z: float) -> float: return 0.15])          # the pocket
	lots.append([-146.0, -300.0, -143.0, -209.2, a4])                                                    # alley A4 (west half)
	var fc := c.front_lots(lots, CAVE, tb - 0.5, -1.0, "w", -190.5, wc, cb, -298.4, -1e9, 0.3)
	var c_end: float = fc.end
	# open ground follows the land, eased to the walk, the alley, the square and the tower's pad
	var edges := [[Vector2(-190.8, -298.5), Vector2(-190.8, tb), func(_x: float, z: float) -> float: return wc(z)],
		[Vector2(-146.0, -298.5), Vector2(-146.0, tb), func(x: float, z: float) -> float: return a4(x, z)],
		[Vector2(-190.8, -298.5), Vector2(-146.0, -298.5), func(x: float, _z: float) -> float: return ne(x)],
		[Vector2(-190.8, tb), Vector2(-146.0, tb), func(_x: float, _z: float) -> float: return 0.15]]
	var open := L.eased(land, edges, 8.0)
	lots.append([-190.8, tb - 0.5, cb, tb, open])                                                       # between the tower and the flats
	lots.append([-190.8, -298.5, cb, c_end, open])                                                      # north of the flats
	lots.append([cb, -298.5, -146.0, tb, open])                                                         # the garden and the parking court
	lots.append([-190.8, -300.0, -154.0, -298.5, func(_x: float, _z: float) -> float: return 1.34])      # seam with the housing square
	lots.append([-154.0, -300.0, -146.0, -298.5, func(_x: float, _z: float) -> float: return 1.40])
	c.terrain(lots)
	c.skirt_depth = 0.6
	c.paint("plaza", tw_end, tb, -146.0, -209.2)                                                         # the pocket
	c.paint("grass", cb + 0.6, -296.0, -146.6, -262.0)                                                   # the residents' garden
	c.paint("concrete", cb + 0.6, -280.6, -146.0, -279.4)                                                # its path from the alley
	c.paint("grass", -190.8 + 0.5, -298.5, cb, c_end - 0.6)                                              # the corner of lawn north of the flats
	c.paint("grass", -190.4, tb + 0.4, -188.7, -212.0)                                                   # planting beside the tower
	c.well(tw_end + 2.0, -213.0); c.well(-147.6, -213.0)
	c.build_floor(L.rect_edges(-190.8, -300.0, -143.0, -209.2))
	if c.stage == "ground": c.finish(); quit(); return
	c.neighbours([["s_rs_b092_a", Vector3(-200, 6, -800), 90.0], ["j_apt", Vector3(-200, 6, -800), -90.0], ["s_rs_b031_b", Vector3(-200, 6, -800), -180.0], ["r_q_m200_m1000_se", Vector3(-200, 8, -1000), 0.0]], O)
	var T: Dictionary = c.front_row(ft, ["cave6_condo_tower"], -188.3, 1.0, "s", -209.2)[0]
	var CV := c.front_row(fc, ["cave_walkup_s", "cave_spanish_flats", "cave_walkup_m", "cave_walkup_n", "cave_garden_apts", "cave_walkup_top"], tb - 0.5, -1.0, "w", -190.5)
	# ---- the tower's entrance and the pocket
	for dr: Array in c.front_shops(T):
		var dp: Vector3 = dr[1]
		for s: float in [-1.4, 1.4]: c.put("plant_potted_leafy", "normal", Vector3(dp.x + s * 1.2, 0.15, dp.z + 0.6), 0.0, "tower: planters either side of the lobby door")
	c.put("prop_newspaper_box_red", "worn", Vector3(tw_end - 4.0, 0.15, -210.0), 180.0, "tower: papers for residents walking out")
	c.put("prop_bike_rack", "worn", Vector3(-189.6, 0.15, -216.0), 90.0, "tower: residents' bikes by the C Ave side, off the walk")
	c.put("prop_bike_rack", "worn", Vector3(-189.6, 0.15, -220.0), 90.0, "tower: residents' bikes by the C Ave side, off the walk")
	c.put("prop_park_bench", "worn", Vector3(tw_end + 1.0, 0.15, -218.0), 90.0, "pocket: a seat facing the alley's mouth and the street")
	c.put("prop_park_bench", "worn", Vector3(tw_end + 1.0, 0.15, -222.0), 90.0, "pocket: a second seat in the tower's shade")
	c.put("prop_trash_receptacle", "worn", Vector3(-146.8, 0.15, -217.0), 0.0, "pocket: a bin by the alley")
	c.put("prop_cafe_table", "worn", Vector3(tw_end + 3.2, 0.15, -224.0), 0.0, "pocket: a table where tower residents sit with a coffee")
	c.put("prop_drinking_fountain", "worn", Vector3(-147.0, 0.15, -224.0), 90.0, "pocket: water by the alley mouth")
	for wx: float in [tw_end + 2.0, -147.6]: c.put("tree_ficus_a", "normal", Vector3(wx, 0.15, -213.0), c.rr.randf_range(0, 360), "pocket: shade trees in wells", true, 0.8)
	# ---- the tower's service side and the flats' backs
	c.services(T, -10.0, 2, false, "left")
	c.put("prop_dumpster_3yd_green", "worn", Vector3(-160.0, c.yf(-160.0, tb - 2.0), tb - 2.0), 0.0, "tower: waste, collected from alley A4")
	c.put("prop_dumpster_3yd_blue", "worn", Vector3(-157.0, c.yf(-157.0, tb - 2.0), tb - 2.0), 0.0, "tower: recycling")
	for r: Dictionary in CV: c.services(r, 3.0, 1, true)
	# ---- the residents' parking court off alley A4 (the flats have no other place for cars)
	for k in 4:
		var sz := -232.0 - k * 3.0
		c.stalls.append([-150.5, sz, 90.0, c.yf(-150.5, sz)])
	c.oil(Vector2(-150.5, -235.0), 90.0)
	c.put("prop_lamp_globe", "worn", Vector3(-154.0, c.yf(-154.0, -244.0), -244.0), 0.0, "parking court: lit at night")
	# ---- the residents' garden on the slope
	for t: Array in [[-170.0, -268.0, "tree_jacaranda_a", 0.85], [-156.0, -290.0, "tree_magnolia_b", 0.85], [-166.0, -288.0, "palm_queen_b", 1.0], [-152.0, -266.0, "tree_coral_a", 0.85]]:
		c.put(String(t[2]), "normal", Vector3(float(t[0]), c.yf(float(t[0]), float(t[1])), float(t[1])), c.rr.randf_range(0, 360), "garden: trees in the grass", true, float(t[3]))
	c.put("prop_picnic_table", "worn", Vector3(-160.0, c.yf(-160.0, -284.0), -284.0), 0.0, "garden: the residents' table off the path")
	c.put("prop_park_bench", "worn", Vector3(-164.0, c.yf(-164.0, -278.6), -278.6), 180.0, "garden: a bench on the path facing down the hill")
	c.put("prop_clothesline", "worn", Vector3(-168.0, c.yf(-168.0, -292.0), -292.0), 0.0, "garden: washing in the sun")
	c.put("prop_bbq_kettle", "worn", Vector3(-156.0, c.yf(-156.0, -286.0), -286.0), 0.0, "garden: the shared grill by the table")
	c.iron(Vector2(-146.6, -296.0), Vector2(-146.6, -281.4), "garden: iron fence on alley A4")
	c.put("fence_gate_wrought_iron", "worn", Vector3(-146.6, c.yf(-146.6, -280.0), -280.0), 90.0, "garden: its gate on the path", false)
	c.iron(Vector2(-146.6, -278.6), Vector2(-146.6, -262.0), "garden: iron fence on alley A4")
	c.iron(Vector2(-146.6, -262.0), Vector2(cb + 0.6, -262.0), "garden: iron fence to the parking court")
	# ---- alley A4 (west half)
	c.alley_wear(-146.0, -298.0, -143.0, -209.2, true)
	c.tyre(Vector2(-144.5, -212.0), 15.0, 5.0, 0.4)
	c.put("prop_manhole_cover", "worn", Vector3(-144.5, c.yf(-144.5, -250.0) + 0.005, -250.0), 0.0, "sewer under alley A4", false)
	c.roof_plant(T, [[-12.0, -4.0, "prop_ac_condenser"], [0.0, -4.0, "prop_vent_box"], [12.0, -4.0, "prop_ac_condenser"], [-6.0, 3.0, "prop_vent_plumbing"], [6.0, 3.0, "prop_vent_turbine"]], "roof plant (tower)")
	for r2: Dictionary in CV: c.roof_plant(r2, [[-3.0, 0.0, "prop_tv_antenna"], [3.0, 0.0, "prop_vent_plumbing"]], "roof plant (flats)")
	for r3: Dictionary in [T] + CV:
		for dr2: Array in r3.doors:
			var q: Vector3 = dr2[1]; var o: Vector3 = dr2[2]
			c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.6, 1.4, 0.4)
	c.finish()
	quit()
