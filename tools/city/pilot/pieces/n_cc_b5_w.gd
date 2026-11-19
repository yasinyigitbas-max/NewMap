extends SceneTree
## Piece n_cc_b5_w (city-centre fill, block 5, AMBER, 6TH ST AND THE HILL; claude/fill-city-centre 19 Nov). Layout row
## (0, 6.0, -600), grid frame u = x, v = z - 600. Covers u 16..193, v -900..-809.2: the Amber x 6th corner, Amber's east
## frontage up the hill, the 6th St row to alley B5, the hill behind, and the west half of alley B5.
## LAND (19 Nov dump + zoning/terrain_grid.npz, table LAND): 6.1 by 6th St rising to 9.5 at the north-west. 6th St's walk
## 6.15 (edge v -809.7, easing to -809.2 from u 178 to 189, followed vertex by vertex); Amber's walk 6.15 at v -822
## rising to 9.14 at v -900 (table WA); the housing squares to the north (locked r_q_0_m1000_se, r_q_250_m1000_sw) meet
## this block at 9.51 (u 16..46), 8.99 (46..54), their LANE at u 54..60 (8.98..8.92), 8.91 falling to 7.70 (60..125),
## 8.33 (125..146.5), 7.57 (..168.5), 6.91 (..190), their second LANE at u 190..196 (6.44..6.37).
## PLANNER: the squares' lane at u 190..196 runs on as ALLEY B5 to the driveway apron that already exists on 6th St at u
## 189.4..196.6; the lane at u 54..60 has no street to reach (no apron on Amber or 6th there, streets locked), so it ends
## in a residents' PARKING COURT at its own height (8.95) and LANE L5 takes those cars down to alley B5 (2.4 %). The
## mirror of block 4 across Amber: Amber's narrow brick shop-houses climbing the hill, a 6th St row of shops with flats,
## flats on lane L5, a public green on the slope above the 6th St yards.
## GROUND: buildings on level pads at their street's (lane's) highest point along them, frontage strips flush with the
## walk; the court level; open ground follows the land eased to every edge it meets; retaining faces where they differ.
## Run with CCF_STAGE=ground first. Draft: never when locked.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const O := Vector3(0.0, 6.0, -600.0)
const LAND := {"x0": 12.0, "z0": -304.0, "step": 4.0, "nx": 59, "nz": 25, "h": [3.17,3.24,3.46,3.46,3.46,3.46,3.46,3.46,3.30,3.01,3.08,3.07,3.02,2.96,2.90,2.84,2.77,2.69,2.62,2.54,2.46,2.38,2.29,2.20,2.11,2.02,1.93,1.84,1.56,2.11,2.28,2.28,2.28,1.99,1.22,1.52,1.52,1.52,1.52,0.86,0.86,0.86,0.86,0.86,0.53,0.33,0.33,0.33,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,-0.05,2.95,3.10,3.30,3.46,3.46,3.46,3.46,3.46,3.13,2.80,2.92,2.89,2.85,2.80,2.74,2.68,2.61,2.55,2.48,2.41,2.32,2.24,2.17,2.09,2.00,1.92,1.84,1.75,1.42,1.98,2.28,2.28,2.28,1.96,1.24,1.52,1.52,1.52,1.52,0.86,0.86,0.86,0.86,0.86,0.53,0.30,0.32,0.32,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,-0.05,2.71,2.85,3.44,3.46,3.46,3.46,3.46,3.46,3.19,2.78,2.92,2.89,2.85,2.80,2.74,2.68,2.62,2.55,2.49,2.42,2.33,2.26,2.19,2.12,1.96,1.88,1.80,1.72,1.46,2.03,2.28,2.28,2.28,2.03,1.31,1.52,1.52,1.52,1.52,0.86,0.86,0.86,0.86,0.86,0.68,0.31,0.32,0.32,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,-0.05,2.51,2.64,2.92,3.04,3.08,3.10,3.08,3.04,2.90,2.73,2.71,2.67,2.63,2.58,2.53,2.47,2.42,2.35,2.30,2.23,2.16,2.10,2.03,1.95,1.85,1.78,1.71,1.66,1.62,1.79,1.93,1.95,1.90,1.73,1.46,1.41,1.37,1.31,1.21,0.98,0.87,0.82,0.77,0.71,0.58,0.41,0.33,0.27,0.18,0.16,0.14,0.13,0.13,0.11,0.11,0.11,0.11,0.10,-0.05,2.30,2.42,2.58,2.69,2.74,2.76,2.76,2.72,2.64,2.55,2.50,2.46,2.42,2.37,2.33,2.27,2.23,2.17,2.11,2.06,1.99,1.93,1.87,1.80,1.73,1.68,1.62,1.59,1.58,1.64,1.69,1.69,1.64,1.53,1.39,1.32,1.25,1.18,1.07,0.94,0.84,0.77,0.70,0.63,0.54,0.43,0.36,0.29,0.23,0.19,0.17,0.15,0.14,0.12,0.13,0.12,0.11,0.10,-0.05,2.09,2.21,2.32,2.40,2.45,2.47,2.47,2.44,2.39,2.34,2.30,2.26,2.22,2.18,2.14,2.09,2.04,1.99,1.94,1.89,1.83,1.79,1.73,1.67,1.61,1.56,1.52,1.49,1.48,1.49,1.51,1.50,1.46,1.38,1.28,1.21,1.13,1.06,0.97,0.88,0.80,0.73,0.66,0.58,0.51,0.42,0.36,0.30,0.25,0.21,0.20,0.18,0.15,0.14,0.13,0.12,0.12,0.10,-0.05,1.87,2.01,2.07,2.14,2.18,2.19,2.20,2.19,2.17,2.13,2.10,2.06,2.03,1.99,1.94,1.91,1.86,1.83,1.78,1.74,1.68,1.64,1.58,1.53,1.49,1.44,1.42,1.39,1.38,1.37,1.36,1.33,1.29,1.24,1.16,1.10,1.04,0.97,0.90,0.82,0.74,0.67,0.61,0.54,0.48,0.43,0.38,0.32,0.28,0.24,0.21,0.18,0.16,0.15,0.13,0.13,0.12,0.10,-0.05,1.66,1.80,1.85,1.90,1.94,1.96,1.97,1.96,1.95,1.92,1.90,1.87,1.83,1.81,1.77,1.74,1.70,1.67,1.62,1.58,1.54,1.49,1.46,1.41,1.38,1.34,1.31,1.28,1.26,1.24,1.22,1.20,1.17,1.12,1.06,1.01,0.95,0.89,0.82,0.75,0.69,0.64,0.59,0.53,0.48,0.42,0.37,0.32,0.28,0.25,0.21,0.20,0.18,0.16,0.14,0.13,0.12,0.10,-0.05,1.48,1.61,1.65,1.69,1.72,1.74,1.75,1.75,1.75,1.73,1.71,1.69,1.66,1.64,1.61,1.58,1.54,1.51,1.48,1.44,1.41,1.37,1.33,1.29,1.26,1.23,1.20,1.18,1.16,1.14,1.11,1.09,1.05,1.02,0.97,0.92,0.87,0.82,0.77,0.71,0.66,0.61,0.56,0.51,0.46,0.41,0.36,0.33,0.29,0.26,0.23,0.20,0.18,0.16,0.14,0.13,0.12,0.10,-0.05,1.29,1.42,1.46,1.49,1.52,1.54,1.56,1.56,1.55,1.55,1.53,1.52,1.49,1.48,1.46,1.43,1.40,1.38,1.34,1.31,1.28,1.24,1.21,1.19,1.16,1.13,1.11,1.08,1.06,1.04,1.01,0.99,0.95,0.93,0.89,0.85,0.81,0.76,0.72,0.67,0.62,0.57,0.54,0.49,0.45,0.40,0.36,0.33,0.29,0.26,0.23,0.20,0.19,0.17,0.15,0.13,0.12,0.10,-0.05,1.11,1.24,1.28,1.31,1.34,1.35,1.37,1.38,1.38,1.38,1.37,1.37,1.35,1.33,1.31,1.29,1.27,1.24,1.22,1.19,1.17,1.14,1.11,1.08,1.06,1.03,1.01,0.99,0.97,0.96,0.93,0.91,0.88,0.85,0.82,0.78,0.75,0.71,0.68,0.63,0.60,0.55,0.51,0.47,0.42,0.39,0.35,0.32,0.29,0.27,0.24,0.21,0.19,0.16,0.15,0.13,0.12,0.10,-0.05,0.92,1.07,1.11,1.13,1.17,1.19,1.21,1.22,1.22,1.23,1.22,1.22,1.21,1.20,1.18,1.16,1.15,1.12,1.11,1.08,1.06,1.03,1.01,0.99,0.97,0.95,0.93,0.91,0.89,0.88,0.85,0.83,0.81,0.78,0.77,0.73,0.70,0.66,0.63,0.59,0.56,0.52,0.47,0.45,0.41,0.38,0.34,0.32,0.28,0.26,0.23,0.20,0.18,0.17,0.16,0.14,0.12,0.10,-0.05,0.77,0.91,0.95,0.98,1.01,1.04,1.05,1.07,1.08,1.09,1.09,1.09,1.08,1.07,1.06,1.05,1.04,1.02,1.00,0.98,0.97,0.95,0.93,0.91,0.89,0.87,0.85,0.84,0.82,0.81,0.79,0.77,0.75,0.72,0.70,0.67,0.65,0.61,0.58,0.56,0.52,0.49,0.45,0.42,0.39,0.36,0.33,0.30,0.27,0.25,0.23,0.21,0.19,0.17,0.15,0.13,0.12,0.10,-0.05,0.63,0.76,0.80,0.84,0.87,0.90,0.93,0.95,0.96,0.97,0.97,0.96,0.97,0.96,0.95,0.94,0.94,0.92,0.91,0.89,0.88,0.86,0.85,0.83,0.81,0.81,0.79,0.78,0.76,0.74,0.73,0.71,0.69,0.66,0.64,0.62,0.60,0.57,0.54,0.51,0.48,0.45,0.42,0.40,0.37,0.35,0.32,0.29,0.27,0.24,0.22,0.20,0.18,0.16,0.16,0.14,0.12,0.10,-0.05,0.49,0.62,0.67,0.72,0.75,0.78,0.80,0.83,0.84,0.85,0.86,0.86,0.87,0.86,0.86,0.85,0.85,0.83,0.82,0.81,0.80,0.80,0.78,0.77,0.75,0.74,0.72,0.71,0.70,0.68,0.66,0.65,0.63,0.61,0.59,0.57,0.54,0.52,0.49,0.47,0.45,0.43,0.40,0.38,0.35,0.32,0.30,0.27,0.25,0.23,0.22,0.20,0.18,0.16,0.15,0.13,0.11,0.10,-0.05,0.36,0.50,0.55,0.60,0.64,0.67,0.70,0.72,0.74,0.75,0.77,0.77,0.77,0.77,0.77,0.77,0.76,0.76,0.75,0.74,0.73,0.72,0.71,0.70,0.68,0.67,0.66,0.65,0.64,0.62,0.61,0.59,0.57,0.55,0.53,0.51,0.50,0.48,0.46,0.44,0.41,0.39,0.37,0.34,0.32,0.31,0.29,0.26,0.25,0.23,0.21,0.19,0.17,0.16,0.14,0.13,0.11,0.10,-0.05,0.23,0.39,0.45,0.51,0.55,0.58,0.61,0.63,0.65,0.66,0.68,0.68,0.69,0.69,0.69,0.69,0.68,0.68,0.67,0.66,0.65,0.64,0.64,0.63,0.62,0.60,0.60,0.58,0.57,0.56,0.54,0.53,0.52,0.50,0.48,0.47,0.45,0.43,0.41,0.39,0.37,0.36,0.34,0.32,0.30,0.28,0.26,0.24,0.23,0.21,0.19,0.19,0.17,0.16,0.14,0.13,0.11,0.10,-0.05,0.15,0.30,0.37,0.42,0.46,0.49,0.53,0.55,0.57,0.58,0.59,0.60,0.60,0.61,0.60,0.60,0.60,0.60,0.59,0.59,0.58,0.57,0.56,0.55,0.55,0.53,0.53,0.52,0.51,0.50,0.48,0.47,0.46,0.45,0.43,0.41,0.40,0.39,0.37,0.35,0.34,0.32,0.30,0.29,0.27,0.25,0.24,0.23,0.22,0.20,0.19,0.17,0.16,0.15,0.13,0.12,0.11,0.10,-0.05,0.08,0.22,0.29,0.34,0.39,0.42,0.45,0.47,0.49,0.50,0.50,0.51,0.52,0.52,0.52,0.52,0.52,0.52,0.51,0.50,0.50,0.49,0.49,0.48,0.48,0.47,0.46,0.45,0.44,0.43,0.42,0.41,0.40,0.39,0.38,0.37,0.35,0.34,0.32,0.31,0.30,0.28,0.28,0.26,0.25,0.24,0.22,0.21,0.20,0.18,0.17,0.16,0.16,0.15,0.13,0.12,0.11,0.10,-0.05,0.02,0.17,0.23,0.27,0.32,0.35,0.37,0.39,0.40,0.42,0.43,0.43,0.44,0.44,0.44,0.44,0.44,0.43,0.43,0.43,0.43,0.42,0.42,0.41,0.40,0.40,0.39,0.38,0.38,0.37,0.36,0.35,0.34,0.34,0.32,0.31,0.30,0.29,0.29,0.27,0.26,0.25,0.24,0.23,0.22,0.21,0.20,0.19,0.18,0.17,0.16,0.16,0.14,0.13,0.12,0.11,0.11,0.10,-0.05,-0.02,0.13,0.17,0.21,0.25,0.28,0.30,0.32,0.33,0.34,0.34,0.35,0.35,0.36,0.35,0.36,0.36,0.35,0.35,0.35,0.35,0.34,0.34,0.33,0.33,0.33,0.32,0.32,0.31,0.30,0.30,0.29,0.28,0.27,0.27,0.26,0.26,0.25,0.24,0.23,0.22,0.21,0.20,0.20,0.19,0.19,0.18,0.17,0.16,0.16,0.15,0.14,0.13,0.13,0.12,0.11,0.11,0.10,-0.05,-0.05,0.10,0.10,0.16,0.19,0.22,0.23,0.24,0.25,0.26,0.26,0.27,0.27,0.27,0.27,0.27,0.27,0.27,0.27,0.27,0.27,0.26,0.26,0.26,0.25,0.25,0.25,0.24,0.24,0.24,0.23,0.23,0.22,0.22,0.21,0.21,0.20,0.20,0.19,0.19,0.18,0.18,0.17,0.17,0.16,0.16,0.15,0.15,0.14,0.14,0.14,0.13,0.12,0.12,0.11,0.11,0.10,0.10,-0.05,-0.05,0.10,0.10,0.12,0.14,0.16,0.17,0.17,0.18,0.18,0.18,0.18,0.18,0.18,0.19,0.18,0.19,0.19,0.19,0.19,0.18,0.18,0.18,0.18,0.18,0.18,0.18,0.18,0.17,0.17,0.17,0.16,0.16,0.16,0.16,0.16,0.16,0.15,0.15,0.15,0.14,0.14,0.13,0.13,0.13,0.13,0.13,0.13,0.12,0.12,0.12,0.11,0.11,0.11,0.11,0.10,0.10,0.10,-0.05,-0.05,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05,-0.05,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05]}
## Amber walk height by z (u 15.75), measured every 2 m on the 19 Nov dump
const WA := [[-301.0, 3.191], [-299.0, 3.082], [-297.0, 2.973], [-295.0, 2.864], [-293.0, 2.756], [-291.0, 2.648], [-289.0, 2.540], [-287.0, 2.434], [-285.0, 2.328], [-283.0, 2.223], [-281.0, 2.119], [-279.0, 2.017], [-277.0, 1.916], [-275.0, 1.817], [-273.0, 1.718], [-271.0, 1.622], [-269.0, 1.527], [-267.0, 1.436], [-265.0, 1.344], [-263.0, 1.257], [-261.0, 1.171], [-259.0, 1.089], [-257.0, 1.007], [-255.0, 0.931], [-253.0, 0.855], [-251.0, 0.784], [-249.0, 0.714], [-247.0, 0.650], [-245.0, 0.587], [-243.0, 0.530], [-241.0, 0.474], [-239.0, 0.425], [-237.0, 0.377], [-235.0, 0.335], [-233.0, 0.295], [-231.0, 0.262], [-229.0, 0.231], [-227.0, 0.207], [-225.0, 0.185], [-223.0, 0.170], [-221.0, 0.158], [-219.0, 0.153], [-217.0, 0.150], [-200.0, 0.150]]
func wa(z: float) -> float: return L.prof(WA, z)
const NEW := [[60.0, 2.91], [66.0, 2.83], [74.0, 2.71], [82.0, 2.57], [90.0, 2.42], [98.0, 2.27], [106.0, 2.10], [114.0, 1.93], [122.0, 1.76], [125.0, 1.70]]
func ne(x: float) -> float:
	if x < 46.0: return 3.51
	if x < 54.0: return 2.99
	if x < 60.0: return 2.98 - (x - 54.0) / 6.0 * 0.06
	if x < 125.0: return L.prof(NEW, x)
	if x < 146.5: return 2.33
	if x < 168.5: return 1.57
	if x < 190.0: return 0.91
	if x < 196.0: return 0.44 - (x - 190.0) / 6.0 * 0.07
	if x < 204.0: return 0.37
	return 0.15
func b5(x: float, z: float) -> float: return 0.15 + clampf((-209.2 - z) / 90.8, 0.0, 1.0) * (ne(clampf(x, 190.0, 196.0)) - 0.15)
const COURT := 2.95
func l5(x: float) -> float: return lerpf(COURT, b5(190.0, -279.0), clampf((x - 80.0) / 110.0, 0.0, 1.0))
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var c := L.new("n_cc_b5_w")
	var land := func(x: float, z: float) -> float: return L.land_at(LAND, x, z)
	var flat := func(_a: float) -> float: return 0.15
	var CORNER := ["urban/urb_brick_corner"]
	var cback := -209.7 - L.depth_of(CORNER) - 0.3
	var cpad := maxf(0.15, wa(cback))
	var SIX := ["ck/ck_brk3_row2", "apartments/apt_stucco3_cream", "urban/urb_brick_row", "ck/ck_brk3_row2_fe", "commercial/com_spanish_arcade_block", "ck/ck_brk3_row2", "modular/examples/mod_brk_row", "apartments/apt_beach_condo", "apartments/apt_stucco3_peach", "ck/ck_brk3_corner2"]
	var AMB := ["ck/ck_brk3_row2_fe", "ck/ck_brk3_row2", "ck/ck_brk3_corner2", "ck/ck_brk3_row2", "ck/ck_brk3_row2_fe", "ck/ck_brk3_row2", "ck/ck_brk3_row2_fe", "ck/ck_brk3_corner2", "ck/ck_brk3_row2"]
	var bam := 16.0 + L.depth_of(AMB) + 0.4
	var NR := ["ck/ck_apt3_row3", "modular/examples/mod_apt_row", "apartments/apt_garden_cream", "ck/ck_svc_trade", "ck/ck_apt3_row2", "ck/ck_apt3_row3", "apartments/apt_spanish_revival"]
	var SR := ["ck/ck_svc_trade_1d", "ck/ck_apt3_row2", "modular/examples/mod_svc_row", "apartments/apt_spanish_revival", "ck/ck_apt3_row3", "ck/ck_apt3_row2"]
	var srb := -276.0 + L.depth_of(SR) + 0.5
	var lots: Array = []
	lots.append([190.0, -300.0, 193.0, -209.2, b5])                                                      # alley B5 (west half)
	var fk := c.front_lots(lots, CORNER, 16.3, 1.0, "s", -209.7, flat, cback, 60.0, cpad)
	var cw: float = fk.end
	lots.append([16.0, cback, 16.3, -209.7, func(_x: float, z: float) -> float: return wa(z)])             # flush with Amber beside the corner block
	var f6 := c.front_lots(lots, SIX, cw + 0.1, 1.0, "s", -209.7, flat, -235.0, 189.9)
	lots.append([cw, -235.0, cw + 0.1, -209.7, func(_x: float, _z: float) -> float: return 0.15])
	lots.append([float(f6.end), -235.0, 190.0, -209.7, func(_x: float, _z: float) -> float: return 0.15])  # the pocket by alley B5
	var fa := c.front_lots(lots, AMB, cback, -1.0, "w", 16.3, wa, bam, -298.4, -1e9, 0.3)
	var fn := c.front_lots(lots, NR, 80.1, 1.0, "s", -282.0, l5, -298.5, 189.9)
	lots.append([80.0, -298.5, 80.1, -282.0, func(_x: float, _z: float) -> float: return l5(80.0)])
	lots.append([80.0, -282.0, 190.0, -276.0, func(x: float, _z: float) -> float: return l5(x)])          # lane L5
	var fs := c.front_lots(lots, SR, 80.1, 1.0, "n", -276.0, l5, srb, 189.9)
	lots.append([80.0, -276.0, 80.1, srb, func(_x: float, _z: float) -> float: return l5(80.0)])
	lots.append([bam, -298.5, 80.0, -270.0, func(_x: float, _z: float) -> float: return COURT])          # the parking court
	var edges := [[Vector2(190.0, -298.5), Vector2(190.0, -209.7), func(x: float, z: float) -> float: return b5(190.0, z)],
		[Vector2(cw, -235.0), Vector2(190.0, -235.0), func(_x: float, _z: float) -> float: return 0.15],
		[Vector2(16.0, cback), Vector2(cw, cback), func(_x: float, _z: float) -> float: return cpad],
		[Vector2(16.0, -298.5), Vector2(16.0, float(fa.end)), func(_x: float, z: float) -> float: return wa(z)],
		[Vector2(80.0, -276.0), Vector2(190.0, -276.0), func(x: float, _z: float) -> float: return l5(x)],
		[Vector2(80.0, -282.0), Vector2(190.0, -282.0), func(x: float, _z: float) -> float: return l5(x)],
		[Vector2(80.0, -298.5), Vector2(80.0, -270.0), func(_x: float, _z: float) -> float: return COURT],
		[Vector2(bam, -270.0), Vector2(80.0, -270.0), func(_x: float, _z: float) -> float: return COURT],
		[Vector2(16.0, -298.5), Vector2(193.0, -298.5), func(x: float, _z: float) -> float: return ne(x)]]
	var open := L.eased(land, edges, 8.0)
	if float(fn.end) < 190.0: lots.append([float(fn.end), -298.5, 190.0, -282.0, open])
	if float(fs.end) < 190.0: lots.append([float(fs.end), -276.0, 190.0, srb, open])
	lots.append([bam, -270.0, 80.0, srb, open])
	lots.append([bam, srb, 190.0, -235.0, open])                                                         # the green
	lots.append([bam, -235.0, cw, cback, open])                                                          # the corner block's yard
	lots.append([16.0, -298.5, bam, float(fa.end), open])                                                # north of the Amber row
	for sg: Array in [[16.0, 46.0, 3.51], [46.0, 54.0, 2.99], [125.0, 146.5, 2.33], [146.5, 168.5, 1.57], [168.5, 190.0, 0.91]]:
		var hh: float = sg[2]
		lots.append([float(sg[0]), -300.0, float(sg[1]), -298.5, func(_x: float, _z: float) -> float: return hh])
	lots.append([54.0, -300.0, 125.0, -298.5, func(x: float, _z: float) -> float: return ne(x)])
	c.terrain(lots)
	c.skirt_depth = 0.6
	# 6th St's walk edge eases from v -809.7 (u 178) to -809.2 (u 189): the street's own vertices
	var tp := PackedVector2Array([Vector2(178.0, -209.7)])
	for e: Vector2 in [Vector2(178.5, -209.6785), Vector2(179.0, -209.663), Vector2(179.5, -209.6439), Vector2(180.0, -209.6219), Vector2(180.5, -209.5972), Vector2(181.0, -209.5704), Vector2(181.5, -209.5418), Vector2(182.0, -209.5119), Vector2(182.5, -209.4812), Vector2(183.0, -209.45), Vector2(183.5, -209.4188), Vector2(184.0, -209.3881), Vector2(184.5, -209.3582), Vector2(185.0, -209.3296), Vector2(185.5, -209.3028), Vector2(186.0, -209.2781), Vector2(186.5, -209.2561), Vector2(187.0, -209.237), Vector2(187.5, -209.2215), Vector2(188.0, -209.2098), Vector2(188.5, -209.2025), Vector2(189.0, -209.2), Vector2(190.0, -209.2)]: tp.append(e)
	tp.append(Vector2(190.0, -209.7))
	c.edge_poly("concrete", tp)
	c.paint("plaza", float(f6.end), -235.0, 190.0, -209.7)
	c.paint("grass", bam + 0.6, srb + 0.6, 189.4, -236.0)                                               # the green
	c.paint("concrete", bam + 0.6, -251.6, 190.0, -250.4)                                               # its path from alley B5
	c.paint("mulch", 120.0, -248.0, 130.0, -240.0)                                                      # the play corner
	c.paint("mulch", bam + 2.0, -262.0, 60.0, -254.0)                                                   # the community vegetable beds
	c.paint("grass", 16.4, -298.5, bam - 0.4, float(fa.end) - 0.4)
	var ring: Array = [Vector2(16.0, -300.0), Vector2(193.0, -300.0), Vector2(193.0, -209.2), Vector2(189.0, -209.2)]
	for k in range(tp.size() - 3, -1, -1): ring.append(tp[k])
	ring.append(Vector2(16.0, -209.7))
	c.build_floor(L.ring_edges(ring))
	if c.stage == "ground": c.finish(); quit(); return
	c.neighbours([["s_rs_b093_a", Vector3(0, 6, -800), 90.0], ["s_rs_b093_b", Vector3(250, 6, -800), -90.0], ["j_am_6th", Vector3(0, 6, -800), 0.0], ["s_am_b039_b", Vector3(0, 6, -800), 180.0],
		["r_q_0_m1000_se", Vector3(0, 12, -1000), 0.0], ["r_q_250_m1000_sw", Vector3(250, 6, -1000), 0.0]], O)
	var K: Dictionary = c.front_row(fk, ["amber6ne_corner"], 16.3, 1.0, "s", -209.7)[0]
	var S := c.front_row(f6, ["sixth_ne_tailor", "sixth_ne_noodle_block", "sixth_ne_brick_row", "sixth_ne_games_fe", "sixth_ne_arcade", "sixth_ne_hat_shop", "sixth_ne_shop_row", "sixth_ne_beach_condo", "sixth_ne_taqueria_block", "sixth_ne_alley_corner"], cw + 0.1, 1.0, "s", -209.7)
	var A := c.front_row(fa, ["amber_ne_camera_fe", "amber_ne_perfume", "amber_ne_corner_deli", "amber_ne_luggage", "amber_ne_comics_fe", "amber_ne_violin", "amber_ne_nails_fe", "amber_ne_corner_wine", "amber_ne_maps"], cback, -1.0, "w", 16.3)
	var NN := c.front_row(fn, ["l5n_walkup_w", "l5n_apt_row", "l5n_garden_apts", "l5n_cabinetmaker", "l5n_walkup_m", "l5n_walkup_e", "l5n_spanish_flats"], 80.1, 1.0, "s", -282.0)
	var SS := c.front_row(fs, ["l5s_tyre_shop", "l5s_walkup", "l5s_bakery_depot", "l5s_spanish_flats", "l5s_walkup_m", "l5s_walkup_e"], 80.1, 1.0, "n", -276.0)
	for r: Dictionary in S + A + [K]:
		for dr: Array in c.front_shops(r):
			var dp: Vector3 = dr[1]; var o: Vector3 = dr[2]
			var side := Vector3(-o.z, 0, o.x)
			for s: float in [-1.2, 1.2]:
				var pp := dp + side * (s * 1.08) + o * 0.4
				c.put("plant_potted_succulent", "normal", Vector3(pp.x, c.yf(pp.x, pp.z), pp.z), 0.0, "shops: a pot either side of the door")
	var px0: float = f6.end
	c.put("prop_park_bench", "worn", Vector3(px0 + 1.0, 0.15, -216.0), 90.0, "pocket: a seat off the 6th St walk")
	c.put("prop_bike_rack", "worn", Vector3((px0 + 190.0) * 0.5, 0.15, -224.0), 0.0, "pocket: bikes for the shops, off the walk")
	c.put("prop_trash_receptacle", "worn", Vector3(189.2, 0.15, -214.0), 0.0, "pocket: a bin by the alley mouth")
	c.put("prop_newspaper_box_red", "worn", Vector3(cw + 1.4, 0.15, -209.9), 180.0, "corner: papers by the 6th St walk")
	# ---- services
	for r2: Dictionary in S + NN + SS + [K]: c.services(r2, 3.0, 1, String(r2.folder).contains("apt") or String(r2.folder).contains("stucco") or String(r2.folder).contains("brk3") or String(r2.folder).contains("beach"))
	for r3: Dictionary in A: c.services(r3, 2.0, 1, true)
	for d: Array in [[60.0, "prop_dumpster_3yd_green", "6th St shops: waste, collected along the yards"], [63.0, "prop_dumpster_3yd_blue", "6th St shops: cardboard"], [150.0, "prop_dumpster_3yd_green", "arcade and row shops: waste"], [182.0, "prop_dumpster_3yd_green", "taqueria: kitchen waste by alley B5"]]:
		var dx: float = d[0]
		c.put(String(d[1]), "worn", Vector3(dx, 0.15, -233.6), 0.0, String(d[2]))
	c.put("prop_transformer_substation", "worn", Vector3(110.0, 0.15, -233.0), 0.0, "the 6th St row's transformer (underground wires)")
	c.cracks(cw, -234.0, 189.0, -225.0, 16, 0.4)
	# ---- the parking court and lane L5
	for k in 6:
		var sx := bam + 3.0 + k * 3.0
		if sx > 76.0: break
		c.stalls.append([sx, -296.0, 0.0, COURT]); c.stalls.append([sx, -273.0, 180.0, COURT])
	c.oil(Vector2(bam + 6.0, -296.0), 0.0)
	c.put("prop_lamp_globe", "worn", Vector3(bam + 1.0, COURT, -284.0), 0.0, "court: lit at night")
	c.put("prop_lamp_globe", "worn", Vector3(79.0, COURT, -287.0), 0.0, "court: lit at night")
	c.put("prop_dumpster_3yd_green", "worn", Vector3(79.0, COURT, -291.0), 90.0, "court: the residents' bin store")
	c.put("prop_recycling_receptacle", "worn", Vector3(79.0, COURT, -294.0), 90.0, "court: recycling beside it")
	c.tyre(Vector2(84.0, -279.0), -80.0, 5.0, 0.4); c.tyre(Vector2(187.0, -279.0), 70.0, 5.0, 0.4)
	c.alley_wear(80.0, -282.0, 190.0, -276.0, false)
	c.put("prop_storm_drain_grate", "worn", Vector3(189.0, c.yf(189.0, -279.0) + 0.005, -279.0), 0.0, "lane L5 drains into alley B5 at its foot", false)
	# ---- the green and the vegetable beds
	for t: Array in [[44.0, -244.0, "tree_ficus_b", 0.9], [72.0, -240.0, "tree_jacaranda_a", 0.9], [96.0, -256.0, "tree_magnolia_b", 0.85], [112.0, -242.0, "palm_queen_a", 1.0], [140.0, -256.0, "tree_coral_b", 0.85], [158.0, -242.0, "tree_jacaranda_b", 0.85], [176.0, -256.0, "tree_ficus_a", 0.85]]:
		c.put(String(t[2]), "normal", Vector3(float(t[0]), c.yf(float(t[0]), float(t[1])), float(t[1])), c.rr.randf_range(0, 360), "green: trees in the grass", true, float(t[3]))
	c.put("prop_play_structure", "worn", Vector3(125.0, c.yf(125.0, -244.0), -244.0), 0.0, "green: the play corner on bark")
	c.put("prop_swing_set", "worn", Vector3(134.0, c.yf(134.0, -244.0), -244.0), 90.0, "green: swings beside the play corner")
	for b: Array in [[125.0, -249.2, "green: a parent watches the play corner from the path"], [100.0, -249.2, "green: a bench on the path"], [160.0, -249.2, "green: a bench on the path"], [70.0, -249.2, "green: a bench by the vegetable beds"]]:
		c.put("prop_park_bench", "worn", Vector3(float(b[0]), c.yf(float(b[0]), float(b[1])), float(b[1])), 0.0, String(b[2]))
	c.put("prop_drinking_fountain", "worn", Vector3(112.0, c.yf(112.0, -252.6), -252.6), 0.0, "green: water by the path")
	c.put("prop_hose_reel_cart", "worn", Vector3(62.0, c.yf(62.0, -258.0), -258.0), 0.0, "vegetable beds: the hose")
	c.put("prop_trash_receptacle", "worn", Vector3(186.0, c.yf(186.0, -252.6), -252.6), 0.0, "green: a bin where the path meets the alley")
	for lx: float in [90.0, 145.0, 175.0]: c.put("prop_lamp_globe", "worn", Vector3(lx, c.yf(lx, -249.0), -249.0), 0.0, "green: the path lit at night")
	c.alley_wear(190.0, -298.0, 193.0, -209.2, true)
	c.tyre(Vector2(191.5, -212.0), 15.0, 5.0, 0.4)
	c.roof_plant(K, [[-5.0, -4.0, "prop_ac_condenser"], [0.0, -4.0, "prop_vent_box"], [5.0, -4.0, "prop_ac_condenser"]], "roof plant (corner block)")
	for r4: Dictionary in S + A: c.roof_plant(r4, [[-3.0, -3.0, "prop_ac_condenser_compact"], [2.0, -3.0, "prop_vent_plumbing"]], "roof plant")
	for r5: Dictionary in NN + SS: c.roof_plant(r5, [[0.0, -2.0, "prop_tv_antenna"]], "roof plant (flats)")
	for r6: Dictionary in S + A + NN + SS + [K]:
		for dr2: Array in r6.doors:
			var q: Vector3 = dr2[1]; var o2: Vector3 = dr2[2]
			c.grime(Vector2(q.x + o2.x * 0.9, q.z + o2.z * 0.9), 0.0, 1.6, 1.4, 0.4)
	c.finish()
	quit()
