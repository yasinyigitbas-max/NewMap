extends SceneTree
## Piece n_cc_b4_e (city-centre fill, block 4, 6TH ST, AMBER AND THE HILL; claude/fill-city-centre 19 Nov). Layout row
## (0, 6.0, -600), grid frame u = x, v = z - 600. Covers u -143..-16, v -900..-809.2: the east half of alley A4, the 6th
## St row east of it, the Amber x 6th corner, the Amber frontage up the hill, and the hill behind.
## LAND (19 Nov dump + zoning/terrain_grid.npz, table LAND): 6.1 by 6th St rising to 8.6..9.4 at the north edge. 6th
## St's walk 6.15 (edge v -809.2, easing to -809.7 from u -139 to -127.5, followed vertex by vertex); Amber's walk 6.15
## at v -822 rising to 9.14 at v -900 (table WA, 5.4 % at the top); the housing square to the north (locked
## r_q_0_m1000_sw / r_q_m200_m1000_se) meets it at 8.64 (u -140..-120), 9.24 (-120..-100), 8.20..8.96 (-100..-46, with
## the square's second LANE ending at u -60..-54 at 8.95) and 9.37 (-46..-16).
## PLANNER: the square's second lane (u -60..-54) has no street apron to run on to (6th St and Amber have none here and
## the streets are locked), so it ends in a residents' PARKING COURT at its own height (8.95), and LANE L4 links the
## court down to alley A4 (2.4 %), so those cars still reach 6th St through A4's apron. 6th St: a continuous row of
## shops with flats over them (this is the centre's north edge); Amber climbs the hill with narrow brick shop-houses
## that step up one by one; north of lane L4 flats look down over it; south of it workshops and flats, and below them a
## public green on the slope between the hill and the 6th St yards (the block's open space, reached from A4).
## GROUND: every building on a level pad at its street's (or lane's) highest point along it, with a frontage strip
## flush with the walk; the corner block's pad at Amber's height at its back (6.20); the court level; open ground (the
## green, yards) follows the land eased to every edge it meets; a retaining face wherever a pad and open ground differ.
## ARCHITECT: 3-4 storeys on 6th and Amber, 2-3 on the lane; the brick corner block holds the corner. EXTERIOR: door pots,
## papers and racks on 6th, a paved pocket at the Amber end, the court (stalls, lamps, bins), the green (trees, benches,
## a play corner, a path), the lane and alley worn, bins and meters at back doors, roof plant.
## Run with CCF_STAGE=ground first. Draft: never when locked.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const O := Vector3(0.0, 6.0, -600.0)
const LAND := {"x0": -192.0, "z0": -304.0, "step": 4.0, "nx": 46, "nz": 25, "h": [1.06,1.29,1.29,1.29,1.29,1.29,1.29,1.29,1.29,1.23,1.32,1.42,1.44,1.40,2.47,2.59,2.59,2.59,2.51,3.14,3.19,3.19,3.19,2.27,2.33,2.41,2.49,2.57,2.65,2.72,2.80,2.86,2.93,2.99,3.05,3.08,3.06,3.18,3.32,3.32,3.32,3.32,3.32,3.32,3.29,3.14,0.99,1.29,1.29,1.29,1.29,1.29,1.29,1.29,1.29,1.26,1.31,1.32,1.35,1.30,2.29,2.59,2.59,2.59,2.51,3.14,3.19,3.19,3.19,2.12,2.20,2.28,2.35,2.42,2.50,2.57,2.63,2.70,2.76,2.82,2.87,2.90,2.85,2.96,3.32,3.32,3.32,3.32,3.32,3.29,3.07,2.92,0.91,1.03,1.29,1.29,1.29,1.29,1.29,1.29,1.29,1.26,1.30,1.32,1.36,1.33,2.32,2.59,2.59,2.59,2.54,3.14,3.19,3.19,3.19,2.13,2.21,2.28,2.36,2.43,2.50,2.57,2.64,2.70,2.76,2.82,2.87,2.90,2.82,2.79,3.32,3.32,3.32,3.32,3.32,2.89,2.85,2.70,0.84,0.95,1.08,1.13,1.16,1.17,1.19,1.20,1.21,1.23,1.26,1.32,1.40,1.56,1.95,2.20,2.30,2.37,2.46,2.67,2.76,2.74,2.64,2.29,2.21,2.21,2.24,2.29,2.34,2.40,2.45,2.51,2.55,2.61,2.64,2.66,2.68,2.72,2.90,2.96,2.97,2.94,2.88,2.67,2.64,2.49,0.77,0.88,0.96,1.00,1.05,1.07,1.09,1.12,1.14,1.18,1.22,1.30,1.39,1.54,1.76,1.93,2.06,2.15,2.25,2.36,2.42,2.41,2.34,2.20,2.12,2.11,2.12,2.15,2.19,2.24,2.28,2.33,2.36,2.39,2.43,2.46,2.49,2.53,2.62,2.65,2.66,2.63,2.56,2.46,2.42,2.27,0.69,0.80,0.86,0.91,0.94,0.98,1.01,1.04,1.07,1.12,1.17,1.25,1.34,1.45,1.61,1.74,1.86,1.94,2.03,2.10,2.15,2.14,2.10,2.05,2.00,1.99,1.99,2.02,2.04,2.08,2.11,2.14,2.17,2.20,2.24,2.26,2.29,2.32,2.37,2.38,2.38,2.36,2.31,2.25,2.21,2.06,0.62,0.73,0.77,0.82,0.86,0.90,0.93,0.97,1.01,1.06,1.11,1.17,1.26,1.36,1.48,1.58,1.68,1.75,1.83,1.88,1.91,1.93,1.91,1.89,1.86,1.86,1.86,1.88,1.89,1.91,1.94,1.97,2.00,2.02,2.05,2.07,2.10,2.11,2.13,2.15,2.14,2.13,2.09,2.05,2.01,1.86,0.55,0.66,0.70,0.75,0.79,0.83,0.86,0.91,0.95,0.99,1.05,1.11,1.18,1.26,1.35,1.43,1.52,1.58,1.64,1.69,1.72,1.74,1.73,1.73,1.72,1.72,1.72,1.73,1.75,1.76,1.79,1.80,1.83,1.84,1.87,1.89,1.90,1.92,1.92,1.93,1.92,1.91,1.88,1.85,1.80,1.65,0.48,0.60,0.64,0.69,0.73,0.77,0.80,0.84,0.89,0.93,0.98,1.03,1.10,1.17,1.24,1.31,1.37,1.43,1.48,1.52,1.55,1.57,1.57,1.58,1.58,1.57,1.58,1.59,1.60,1.61,1.63,1.65,1.67,1.68,1.69,1.71,1.71,1.73,1.72,1.73,1.72,1.71,1.68,1.66,1.61,1.46,0.42,0.53,0.58,0.63,0.67,0.71,0.75,0.79,0.83,0.87,0.92,0.97,1.03,1.08,1.13,1.20,1.24,1.30,1.34,1.38,1.40,1.42,1.43,1.43,1.44,1.44,1.45,1.46,1.47,1.48,1.49,1.50,1.51,1.52,1.53,1.54,1.55,1.55,1.55,1.54,1.53,1.51,1.49,1.47,1.42,1.27,0.35,0.47,0.52,0.56,0.61,0.65,0.70,0.73,0.78,0.82,0.86,0.90,0.95,1.00,1.04,1.09,1.13,1.18,1.21,1.25,1.27,1.29,1.30,1.30,1.31,1.32,1.33,1.33,1.34,1.35,1.36,1.36,1.37,1.38,1.38,1.39,1.39,1.39,1.38,1.37,1.35,1.33,1.32,1.29,1.24,1.09,0.29,0.41,0.46,0.51,0.56,0.60,0.65,0.68,0.73,0.76,0.81,0.84,0.88,0.93,0.96,1.01,1.04,1.08,1.10,1.13,1.15,1.16,1.18,1.18,1.20,1.20,1.21,1.21,1.22,1.22,1.23,1.24,1.24,1.24,1.24,1.25,1.24,1.24,1.23,1.21,1.19,1.17,1.15,1.12,1.07,0.92,0.22,0.36,0.41,0.46,0.51,0.55,0.60,0.63,0.67,0.71,0.74,0.78,0.81,0.86,0.89,0.93,0.95,0.99,1.01,1.03,1.05,1.06,1.07,1.08,1.09,1.09,1.10,1.10,1.10,1.11,1.11,1.12,1.11,1.12,1.12,1.12,1.11,1.09,1.08,1.06,1.04,1.02,0.99,0.96,0.91,0.76,0.18,0.31,0.37,0.41,0.46,0.50,0.54,0.58,0.61,0.65,0.68,0.72,0.75,0.79,0.82,0.85,0.87,0.90,0.92,0.94,0.96,0.97,0.98,0.98,0.99,0.99,0.99,1.00,1.00,1.01,1.01,1.01,1.01,1.01,1.00,0.99,0.98,0.97,0.96,0.93,0.91,0.88,0.85,0.81,0.76,0.61,0.13,0.26,0.32,0.37,0.41,0.45,0.49,0.53,0.56,0.59,0.62,0.66,0.69,0.72,0.74,0.77,0.80,0.82,0.84,0.85,0.87,0.88,0.89,0.90,0.90,0.91,0.91,0.91,0.91,0.91,0.91,0.91,0.90,0.90,0.89,0.88,0.87,0.86,0.84,0.81,0.79,0.75,0.71,0.67,0.62,0.47,0.09,0.22,0.28,0.32,0.36,0.40,0.44,0.48,0.50,0.54,0.56,0.60,0.62,0.64,0.67,0.69,0.72,0.74,0.76,0.77,0.79,0.80,0.80,0.81,0.81,0.82,0.82,0.82,0.82,0.83,0.82,0.81,0.81,0.80,0.80,0.78,0.77,0.75,0.74,0.71,0.68,0.64,0.59,0.54,0.50,0.35,0.05,0.19,0.23,0.28,0.32,0.36,0.39,0.43,0.45,0.48,0.51,0.53,0.56,0.58,0.60,0.62,0.65,0.66,0.68,0.69,0.70,0.71,0.72,0.73,0.73,0.73,0.73,0.74,0.74,0.73,0.73,0.73,0.72,0.71,0.71,0.70,0.69,0.67,0.64,0.62,0.58,0.54,0.49,0.43,0.38,0.23,0.02,0.16,0.20,0.25,0.28,0.32,0.35,0.38,0.40,0.42,0.45,0.47,0.49,0.51,0.53,0.55,0.57,0.58,0.59,0.61,0.61,0.63,0.63,0.64,0.64,0.65,0.65,0.64,0.65,0.64,0.64,0.64,0.64,0.63,0.62,0.61,0.59,0.58,0.55,0.53,0.49,0.45,0.40,0.33,0.30,0.14,-0.01,0.13,0.17,0.21,0.25,0.28,0.30,0.32,0.35,0.37,0.39,0.41,0.43,0.45,0.46,0.48,0.49,0.50,0.51,0.53,0.53,0.54,0.54,0.55,0.55,0.55,0.56,0.56,0.56,0.56,0.56,0.55,0.55,0.54,0.53,0.52,0.51,0.49,0.47,0.45,0.41,0.37,0.32,0.25,0.22,0.07,-0.03,0.11,0.15,0.19,0.21,0.23,0.26,0.28,0.30,0.32,0.34,0.35,0.37,0.38,0.39,0.40,0.41,0.43,0.43,0.44,0.45,0.46,0.46,0.46,0.47,0.47,0.47,0.47,0.47,0.47,0.47,0.46,0.46,0.45,0.44,0.44,0.42,0.41,0.39,0.37,0.34,0.30,0.25,0.19,0.16,0.02,-0.04,0.10,0.13,0.16,0.18,0.20,0.22,0.23,0.25,0.26,0.28,0.29,0.30,0.31,0.32,0.33,0.34,0.35,0.35,0.36,0.36,0.36,0.37,0.37,0.38,0.38,0.38,0.38,0.38,0.38,0.37,0.37,0.37,0.37,0.36,0.35,0.34,0.33,0.32,0.30,0.27,0.24,0.20,0.14,0.12,-0.02,-0.05,0.10,0.12,0.14,0.15,0.17,0.18,0.19,0.20,0.21,0.22,0.23,0.23,0.24,0.25,0.26,0.26,0.27,0.27,0.27,0.28,0.28,0.28,0.28,0.29,0.29,0.29,0.29,0.28,0.29,0.28,0.28,0.28,0.28,0.27,0.27,0.26,0.25,0.24,0.23,0.21,0.19,0.15,0.10,0.10,-0.05,-0.05,0.10,0.11,0.12,0.13,0.13,0.14,0.15,0.15,0.16,0.16,0.16,0.17,0.17,0.17,0.18,0.18,0.18,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.18,0.18,0.18,0.17,0.16,0.16,0.14,0.12,0.10,0.10,-0.05,-0.05,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,-0.05]}
## Amber walk height by z (u -15.75), measured every 2 m on the 19 Nov dump
const WA := [[-301.0, 3.191], [-299.0, 3.082], [-297.0, 2.973], [-295.0, 2.864], [-293.0, 2.756], [-291.0, 2.648], [-289.0, 2.540], [-287.0, 2.434], [-285.0, 2.328], [-283.0, 2.223], [-281.0, 2.119], [-279.0, 2.017], [-277.0, 1.916], [-275.0, 1.817], [-273.0, 1.718], [-271.0, 1.622], [-269.0, 1.527], [-267.0, 1.436], [-265.0, 1.344], [-263.0, 1.257], [-261.0, 1.171], [-259.0, 1.089], [-257.0, 1.007], [-255.0, 0.931], [-253.0, 0.855], [-251.0, 0.784], [-249.0, 0.714], [-247.0, 0.650], [-245.0, 0.587], [-243.0, 0.530], [-241.0, 0.474], [-239.0, 0.425], [-237.0, 0.377], [-235.0, 0.335], [-233.0, 0.295], [-231.0, 0.262], [-229.0, 0.231], [-227.0, 0.207], [-225.0, 0.185], [-223.0, 0.170], [-221.0, 0.158], [-219.0, 0.153], [-217.0, 0.150], [-200.0, 0.150]]
func wa(z: float) -> float: return L.prof(WA, z)
## the housing squares' edge at v -900 (z -300)
func ne(x: float) -> float:
	if x < -140.0: return 1.40 + (clampf(x, -146.0, -140.0) + 146.0) / 6.0 * 0.07
	if x < -120.0: return 2.64
	if x < -100.0: return 3.24
	if x < -46.0: return L.prof([[-100.0, 2.20], [-94.0, 2.31], [-86.0, 2.46], [-78.0, 2.61], [-70.0, 2.74], [-62.0, 2.86], [-54.0, 2.96], [-46.0, 2.96]], x)
	return 3.37
func a4(x: float, z: float) -> float: return 0.15 + clampf((-209.2 - z) / 90.8, 0.0, 1.0) * (ne(clampf(x, -146.0, -140.001)) - 0.15)
const COURT := 2.95
## lane L4 (z -282..-276) from alley A4 up to the court at u -66
func l4(x: float) -> float: return lerpf(a4(-140.0, -279.0), COURT, clampf((x + 140.0) / 74.0, 0.0, 1.0))
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var c := L.new("n_cc_b4_e")
	var land := func(x: float, z: float) -> float: return L.land_at(LAND, x, z)
	var flat := func(_a: float) -> float: return 0.15
	var CORNER := ["urban/urb_brick_corner"]
	var cback := -209.7 - L.depth_of(CORNER) - 0.3
	var cpad := maxf(0.15, wa(cback))
	var SIX := ["ck/ck_brk3_corner2", "urban/urb_brick_row", "apartments/apt_stucco3_peach", "ck/ck_brk3_row2", "modular/examples/mod_brk_row", "ck/ck_brk3_row2_fe", "apartments/apt_beach_condo"]
	var AMB := ["ck/ck_brk3_row2", "ck/ck_brk3_corner2", "ck/ck_brk3_row2_fe", "ck/ck_brk3_row2", "ck/ck_brk3_row2_fe", "ck/ck_brk3_row2", "ck/ck_brk3_corner2", "ck/ck_brk3_row2", "ck/ck_brk3_row2_fe"]
	var bam := -16.0 - L.depth_of(AMB) - 0.4                             # behind the Amber row
	var NR := ["ck/ck_apt3_row2", "apartments/apt_garden_cream", "ck/ck_svc_trade", "ck/ck_apt3_row3", "ck/ck_apt3_row2"]
	var SR := ["modular/examples/mod_svc_row", "ck/ck_apt3_row2", "apartments/apt_spanish_revival", "ck/ck_svc_trade_1d", "ck/ck_apt3_row2"]
	var srb := -276.0 + L.depth_of(SR) + 0.5                             # behind the lane's south row
	var lots: Array = []
	lots.append([-143.0, -300.0, -140.0, -209.2, a4])                                                    # alley A4 (east half)
	var fk := c.front_lots(lots, CORNER, -16.3, -1.0, "s", -209.7, flat, cback, -60.0, cpad)
	var cw: float = fk.end
	lots.append([-16.3, cback, -16.0, -209.7, func(_x: float, z: float) -> float: return wa(z)])          # flush with Amber beside the corner block
	var f6 := c.front_lots(lots, SIX, -139.9, 1.0, "s", -209.7, flat, -235.0, cw - 0.1)
	lots.append([-140.0, -235.0, -139.9, -209.7, func(_x: float, _z: float) -> float: return 0.15])
	lots.append([float(f6.end), -235.0, cw, -209.7, func(_x: float, _z: float) -> float: return 0.15])    # the pocket by the corner
	var fa := c.front_lots(lots, AMB, cback, -1.0, "e", -16.3, wa, bam, -298.4, -1e9, 0.3)
	var fn := c.front_lots(lots, NR, -139.9, 1.0, "s", -282.0, l4, -298.5, -66.4)
	lots.append([-140.0, -298.5, -139.9, -282.0, func(_x: float, _z: float) -> float: return l4(-140.0)])
	lots.append([-140.0, -282.0, -66.0, -276.0, func(x: float, _z: float) -> float: return l4(x)])        # lane L4
	var fs := c.front_lots(lots, SR, -139.9, 1.0, "n", -276.0, l4, srb, -66.4)
	lots.append([-140.0, -276.0, -139.9, srb, func(_x: float, _z: float) -> float: return l4(-140.0)])
	lots.append([-66.0, -298.5, bam, -270.0, func(_x: float, _z: float) -> float: return COURT])          # the parking court
	# open ground follows the land, eased to everything it meets
	var edges := [[Vector2(-140.0, -298.5), Vector2(-140.0, -209.7), func(x: float, z: float) -> float: return a4(-140.0, z)],
		[Vector2(-140.0, -235.0), Vector2(cw, -235.0), func(_x: float, _z: float) -> float: return 0.15],
		[Vector2(cw, cback), Vector2(-16.0, cback), func(_x: float, _z: float) -> float: return cpad],
		[Vector2(-16.0, -235.0), Vector2(-16.0, cback), func(_x: float, z: float) -> float: return wa(z)],
		[Vector2(-16.0, -298.5), Vector2(-16.0, float(fa.end)), func(_x: float, z: float) -> float: return wa(z)],
		[Vector2(-140.0, -276.0), Vector2(-66.0, -276.0), func(x: float, _z: float) -> float: return l4(x)],
		[Vector2(-140.0, -282.0), Vector2(-66.0, -282.0), func(x: float, _z: float) -> float: return l4(x)],
		[Vector2(-66.0, -298.5), Vector2(-66.0, -270.0), func(_x: float, _z: float) -> float: return COURT],
		[Vector2(-66.0, -270.0), Vector2(bam, -270.0), func(_x: float, _z: float) -> float: return COURT],
		[Vector2(-140.0, -298.5), Vector2(-16.0, -298.5), func(x: float, _z: float) -> float: return ne(x)]]
	var open := L.eased(land, edges, 8.0)
	lots.append([float(fn.end), -298.5, -66.0, -282.0, open])
	lots.append([float(fs.end), -276.0, -66.0, srb, open])
	lots.append([-66.0, -270.0, bam, srb, open])
	lots.append([-140.0, srb, bam, -235.0, open])                                                       # the green
	lots.append([cw, -235.0, bam, cback, open])                                                         # the corner block's yard
	lots.append([bam, -298.5, -16.0, float(fa.end), open])                                              # north of the Amber row
	for sg: Array in [[-140.0, -120.0, 2.64], [-120.0, -100.0, 3.24], [-46.0, -16.0, 3.37]]:
		var hh: float = sg[2]
		lots.append([float(sg[0]), -300.0, float(sg[1]), -298.5, func(_x: float, _z: float) -> float: return hh])
	lots.append([-100.0, -300.0, -46.0, -298.5, func(x: float, _z: float) -> float: return ne(x)])
	c.terrain(lots)
	c.skirt_depth = 0.6
	# 6th St's walk edge eases from v -809.2 (u -139) to -809.7 (u -127.5): the street's own vertices
	var tp := PackedVector2Array([Vector2(-140.0, -209.7), Vector2(-140.0, -209.2)])
	for e: Vector2 in [Vector2(-139.0, -209.2), Vector2(-138.0, -209.21), Vector2(-137.5, -209.22), Vector2(-137.0, -209.24), Vector2(-136.5, -209.26), Vector2(-136.0, -209.28), Vector2(-135.5, -209.30), Vector2(-135.0, -209.33), Vector2(-134.5, -209.36), Vector2(-134.0, -209.39), Vector2(-133.5, -209.42), Vector2(-133.0, -209.45), Vector2(-132.5, -209.48), Vector2(-132.0, -209.51), Vector2(-131.5, -209.54), Vector2(-131.0, -209.57), Vector2(-130.5, -209.60), Vector2(-130.0, -209.62), Vector2(-129.5, -209.64), Vector2(-129.0, -209.66), Vector2(-128.5, -209.68), Vector2(-128.0, -209.69), Vector2(-127.5, -209.70)]: tp.append(e)
	c.edge_poly("concrete", tp)
	c.paint("plaza", float(f6.end), -235.0, cw, -209.7)                                                  # the pocket
	c.paint("grass", -139.4, srb + 0.6, bam - 0.6, -236.0)                                               # the green
	c.paint("concrete", -139.4, -251.6, bam - 0.6, -250.4)                                               # its path across from the alley
	c.paint("mulch", -96.0, -248.0, -86.0, -240.0)                                                       # the play corner on bark
	c.paint("grass", bam + 0.4, -298.5, -16.4, float(fa.end) - 0.4)
	var ring: Array = [Vector2(-143.0, -300.0), Vector2(-16.0, -300.0), Vector2(-16.0, -209.7)]
	for k in range(tp.size() - 1, 1, -1): ring.append(tp[k])
	ring.append(Vector2(-143.0, -209.2))
	c.build_floor(L.ring_edges(ring))
	if c.stage == "ground": c.finish(); quit(); return
	c.neighbours([["s_rs_b092_a", Vector3(-200, 6, -800), 90.0], ["s_rs_b092_b", Vector3(0, 6, -800), -90.0], ["j_am_6th", Vector3(0, 6, -800), 0.0], ["s_am_b039_b", Vector3(0, 6, -800), 180.0],
		["r_q_m200_m1000_se", Vector3(-200, 8, -1000), 0.0], ["r_q_0_m1000_sw", Vector3(0, 12, -1000), 0.0]], O)
	var K: Dictionary = c.front_row(fk, ["amber6n_corner"], -16.3, -1.0, "s", -209.7)[0]
	var S := c.front_row(f6, ["sixth_n_corner_deli", "sixth_n_brick_row", "sixth_n_stucco_block", "sixth_n_florist", "sixth_n_shop_row", "sixth_n_bookshop_fe", "sixth_n_beach_condo"], -139.9, 1.0, "s", -209.7)
	var A := c.front_row(fa, ["amber_n_tea", "amber_n_corner_bar", "amber_n_records_fe", "amber_n_tattoo", "amber_n_vintage_fe", "amber_n_bike", "amber_n_corner_cafe", "amber_n_frames", "amber_n_yoga_fe"], cback, -1.0, "e", -16.3)
	var NN := c.front_row(fn, ["l4n_walkup_w", "l4n_garden_apts", "l4n_joiner", "l4n_walkup_m", "l4n_walkup_e"], -139.9, 1.0, "s", -282.0)
	var SS := c.front_row(fs, ["l4s_upholstery", "l4s_walkup", "l4s_spanish_flats", "l4s_glazier", "l4s_walkup_e"], -139.9, 1.0, "n", -276.0)
	# ---- 6th St and Amber fronts: pots at shop doors, papers, racks
	for r: Dictionary in S + A + [K]:
		for dr: Array in c.front_shops(r):
			var dp: Vector3 = dr[1]; var o: Vector3 = dr[2]
			var side := Vector3(-o.z, 0, o.x)
			for s: float in [-1.2, 1.2]:
				var pp := dp + side * (s * 1.08) + o * 0.4
				c.put("plant_potted_succulent", "normal", Vector3(pp.x, c.yf(pp.x, pp.z), pp.z), 0.0, "shops: a pot either side of the door")
	c.put("prop_newspaper_box_red", "worn", Vector3(-137.0, 0.15, -209.9), 180.0, "deli corner by the alley: papers")
	c.put("prop_newspaper_box_blue", "worn", Vector3(-136.2, 0.15, -209.9), 180.0, "deli corner by the alley: papers")
	var px0: float = f6.end
	c.put("prop_park_bench", "worn", Vector3(px0 + 1.0, 0.15, -216.0), 90.0, "pocket: a seat off the 6th St walk")
	c.put("prop_bike_rack", "worn", Vector3((px0 + cw) * 0.5, 0.15, -222.0), 0.0, "pocket: bikes for the shops, off the walk")
	c.put("prop_trash_receptacle", "worn", Vector3(cw - 0.8, 0.15, -212.0), 0.0, "pocket: a bin at the corner")
	c.put("plant_potted_leafy", "normal", Vector3((px0 + cw) * 0.5, 0.15, -233.0), 0.0, "pocket: a planter closes it toward the yards")
	# ---- service sides
	for r2: Dictionary in S + NN + SS + [K]: c.services(r2, 3.0, 1, String(r2.folder).contains("apt") or String(r2.folder).contains("stucco") or String(r2.folder).contains("brk3") or String(r2.folder).contains("beach"))
	for r3: Dictionary in A: c.services(r3, 2.0, 1, true)
	for d: Array in [[-130.0, "prop_dumpster_3yd_green", "deli and 6th St shops: waste by alley A4"], [-127.0, "prop_dumpster_3yd_blue", "6th St shops: cardboard"]]:
		var dx: float = d[0]
		c.put(String(d[1]), "worn", Vector3(dx, 0.15, -233.6), 0.0, String(d[2]))
	c.put("prop_transformer_substation", "worn", Vector3(-110.0, 0.15, -233.0), 0.0, "the 6th St row's transformer (underground wires)")
	c.cracks(-139.0, -234.0, cw, -225.0, 14, 0.4)
	# ---- the parking court and lane L4
	for k in 6:
		var sx := -62.0 + k * 3.0
		if sx > bam - 2.0: break
		c.stalls.append([sx, -296.0, 0.0, COURT])
	for k2 in 4:
		var sx2 := -62.0 + k2 * 3.0
		c.stalls.append([sx2, -273.0, 180.0, COURT])
	c.oil(Vector2(-56.0, -296.0), 0.0); c.oil(Vector2(-59.0, -273.0), 180.0)
	c.put("prop_lamp_globe", "worn", Vector3(-65.0, COURT, -284.0), 0.0, "court: lit at night")
	c.put("prop_lamp_globe", "worn", Vector3(bam - 1.0, COURT, -284.0), 0.0, "court: lit at night")
	c.put("prop_dumpster_3yd_green", "worn", Vector3(-65.0, COURT, -291.0), 90.0, "court: the residents' bin store")
	c.put("prop_recycling_receptacle", "worn", Vector3(-65.0, COURT, -288.0), 90.0, "court: recycling beside it")
	c.put("prop_sign_no_parking", "worn", Vector3(-66.4, COURT, -278.5), 90.0, "court: keep the lane mouth clear")
	c.tyre(Vector2(-70.0, -279.0), 80.0, 5.0, 0.4); c.tyre(Vector2(-137.0, -279.0), -70.0, 5.0, 0.4)
	c.alley_wear(-140.0, -282.0, -66.0, -276.0, false)
	c.put("prop_storm_drain_grate", "worn", Vector3(-139.0, c.yf(-139.0, -279.0) + 0.005, -279.0), 0.0, "lane L4 drains into alley A4 at its foot", false)
	# ---- the green
	for t: Array in [[-132.0, -258.0, "tree_jacaranda_b", 0.9], [-118.0, -244.0, "tree_ficus_a", 0.9], [-104.0, -256.0, "tree_magnolia_a", 0.85], [-78.0, -246.0, "tree_coral_a", 0.85], [-64.0, -258.0, "palm_queen_a", 1.0], [-48.0, -244.0, "tree_jacaranda_a", 0.85], [-122.0, -239.0, "palm_queen_b", 1.0]]:
		c.put(String(t[2]), "normal", Vector3(float(t[0]), c.yf(float(t[0]), float(t[1])), float(t[1])), c.rr.randf_range(0, 360), "green: trees in the grass", true, float(t[3]))
	c.put("prop_play_structure", "worn", Vector3(-91.0, c.yf(-91.0, -244.0), -244.0), 0.0, "green: the play corner on bark")
	for b: Array in [[-91.0, -249.2, 0.0, "green: a parent watches the play corner from the path"], [-112.0, -249.2, 0.0, "green: a bench on the path, looking down the slope"], [-70.0, -249.2, 0.0, "green: a bench on the path"]]:
		c.put("prop_park_bench", "worn", Vector3(float(b[0]), c.yf(float(b[0]), float(b[1])), float(b[1])), float(b[2]), String(b[3]))
	c.put("prop_drinking_fountain", "worn", Vector3(-100.0, c.yf(-100.0, -252.6), -252.6), 0.0, "green: water by the path")
	c.put("prop_trash_receptacle", "worn", Vector3(-136.0, c.yf(-136.0, -252.6), -252.6), 0.0, "green: a bin where the path meets the alley")
	c.put("prop_picnic_table", "worn", Vector3(-56.0, c.yf(-56.0, -252.0), -252.0), 0.0, "green: a table under the trees")
	c.put("prop_lamp_globe", "worn", Vector3(-126.0, c.yf(-126.0, -249.0), -249.0), 0.0, "green: the path lit at night")
	c.put("prop_lamp_globe", "worn", Vector3(-80.0, c.yf(-80.0, -249.0), -249.0), 0.0, "green: the path lit at night")
	# ---- alley A4 (east half)
	c.alley_wear(-143.0, -298.0, -140.0, -209.2, true)
	c.tyre(Vector2(-141.5, -212.0), -15.0, 5.0, 0.4)
	c.put("prop_storm_drain_grate", "worn", Vector3(-141.5, 0.155, -212.0), 0.0, "alley A4 drains to the street at its mouth", false)
	# ---- roofs and doors
	c.roof_plant(K, [[-5.0, -4.0, "prop_ac_condenser"], [0.0, -4.0, "prop_vent_box"], [5.0, -4.0, "prop_ac_condenser"]], "roof plant (corner block)")
	for r4: Dictionary in S + A: c.roof_plant(r4, [[-3.0, -3.0, "prop_ac_condenser_compact"], [2.0, -3.0, "prop_vent_plumbing"]], "roof plant")
	for r5: Dictionary in NN + SS: c.roof_plant(r5, [[0.0, -2.0, "prop_tv_antenna"]], "roof plant (flats)")
	for r6: Dictionary in S + A + NN + SS + [K]:
		for dr2: Array in r6.doors:
			var q: Vector3 = dr2[1]; var o2: Vector3 = dr2[2]
			c.grime(Vector2(q.x + o2.x * 0.9, q.z + o2.z * 0.9), 0.0, 1.6, 1.4, 0.4)
	c.finish()
	quit()
