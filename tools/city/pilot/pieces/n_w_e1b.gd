extends SceneTree
## Piece n_w_e1b (WEST FILL, the corner pocket by the ring road): u -966..-930, v 209..240, 36 x 31 m; flat 2.0.
## PLANNER: a BEACH-SIDE POCKET: a rinse shower and a bench for people walking up from the shore, bike racks, a table.
## Layout row (-966.0, 0, 209.0): local x = u - (-966.0), z = v - (209.0), heights absolute. Built by the west fill (University
## session, 20 Nov; review/fill_west/PLAN.md). Ground: the land 8 cm over it, eased over 8 m to the measured height of
## whatever borders each side; buildings on level pads at the highest ground under them (plinth faces downhill).
const L := preload("res://tools/city/pilot/pieces/w_fill_lib.gd")
## site u -966.0..-930.0 v 209.0..240.0 (36.0 x 31.0 m); neighbours N {np.str_('j_rg_w993_s200'): 1, np.str_('s_rg_nw_b124'): 18} S {np.str_('s_rg_b159_1'): 1, '-': 18} W {'-': 15, np.str_('s_rg_b159_1'): 1} E {'-': 16}
const LAND := {"x0": -10.0, "z0": -9.0, "step": 4.0, "nx": 15, "nz": 13, "h": [1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,1.95,2.10,2.09,2.11,2.09,2.11,2.12,2.09,2.10,2.09,2.10,2.09,2.11,2.09,2.11,1.95,2.10,2.09,2.09,2.11,2.09,2.11,2.09,2.11,2.09,2.11,2.09,2.09,2.11,2.09,1.95,2.10,2.11,2.09,2.11,2.10,2.11,2.09,2.10,2.08,2.10,2.11,2.10,2.11,2.10,1.95,2.10,2.10,2.09,2.10,2.08,2.10,2.08,2.10,2.11,2.10,2.11,2.10,2.10,2.08,1.95,1.95,2.10,2.09,2.10,2.08,2.10,2.09,2.10,2.10,2.09,2.10,2.09,2.10,2.09,1.95,1.95,1.95,2.10,2.10,2.07,2.09,2.11,2.09,2.11,2.09,2.11,2.09,2.11,2.09,1.95,1.95,1.95,1.95,2.10,2.10,2.10,2.11,2.10,2.11,2.08,2.09,2.08,2.09,2.11,1.95,1.95,1.95,1.95,1.95,2.10,2.10,2.10,2.09,2.10,2.08,2.10,2.11,2.10,2.11,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.10,2.10,2.08,2.10,2.09,2.10]}
const EDGE_N := [[0.0,2.15],[2.0,2.15],[4.0,2.15],[6.0,2.15],[8.0,2.15],[10.0,2.15],[12.0,2.15],[14.0,2.15],[16.0,2.15],[18.0,2.15],[20.0,2.15],[22.0,2.15],[24.0,2.15],[26.0,2.15],[28.0,2.15],[30.0,2.15],[32.0,2.15],[34.0,2.15],[36.0,2.15]]
const EDGE_S := [[0.0,2.15],[2.0,1.95],[4.0,2.016],[6.0,2.081],[8.0,2.091],[10.0,2.1],[12.0,2.098],[14.0,2.096],[16.0,2.103],[18.0,2.11],[20.0,2.102],[22.0,2.094],[24.0,2.101],[26.0,2.108],[28.0,2.092],[30.0,2.076],[32.0,2.085],[34.0,2.093],[36.0,2.088]]
const EDGE_W := [[0.0,1.988],[2.0,2.063],[4.0,2.099],[6.0,2.097],[8.0,2.095],[10.0,2.092],[12.0,2.093],[14.0,2.099],[16.0,2.101],[18.0,2.099],[20.0,2.097],[22.0,2.096],[24.0,2.073],[26.0,2.028],[28.0,1.992],[30.0,2.15]]
const EDGE_E := [[0.0,1.988],[2.0,2.063],[4.0,2.1],[6.0,2.101],[8.0,2.099],[10.0,2.096],[12.0,2.096],[14.0,2.1],[16.0,2.103],[18.0,2.104],[20.0,2.102],[22.0,2.096],[24.0,2.094],[26.0,2.095],[28.0,2.092],[30.0,2.086]]

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var c := L.new("n_w_e1b", 2.15)
	var W := 36.00; var D := 31.00
	var land := func(x: float, z: float) -> float: return L.land_at(LAND, x, z) + 0.08
	var base := L.edged(land, W, D, EDGE_N, EDGE_S, EDGE_W, EDGE_E, 8.0)
	var SITES := []
	var pads: Array = []
	for st: Array in SITES:
		var r0: Array = L.bld_rect(String(st[0]), st[1], String(st[2]))
		pads.append([maxf(0.0, float(r0[0]) - 0.3), maxf(0.0, float(r0[1]) - 0.3), minf(W, float(r0[2]) + 0.3), minf(D, float(r0[3]) + 0.3)])
	var gl := L.grid_lots(0.0, 0.0, W, D, pads, base)
	c.terrain(gl.lots)
	c.skirt_depth = 0.5
	c.paint("concrete", 0.00, 0.00, 36.00, 5.00)                # walk
	c.paint("sand", 10.00, 10.00, 26.00, 24.00)                # a patch of sand by the shower
	c.paint("grass", 0.0, 0.0, W, D)
	c.build_floor(L.rect_edges(0.0, 0.0, W, D))
	if c.stage == "ground": c.finish(); quit(); return
	var B := {}
	for k in SITES.size():
		c.y0 = float(gl.pads[k][4])
		B[String(SITES[k][3])] = c.bld(String(SITES[k][0]), SITES[k][1], String(SITES[k][2]), false, String(SITES[k][3]), 0.70)

	c.put("prop_beach_shower", "worn", c.gp(18.00, 17.00), 0.0, "pocket: a rinse shower for people off the beach")
	c.put("prop_park_bench", "worn", c.gp(18.00, 6.60), 0.0, "pocket: a bench facing the sand")
	c.put("prop_bike_rack", "worn", c.gp(4.00, 3.00), 0.0, "pocket: bikes")
	c.put("prop_bike_rack", "worn", c.gp(8.00, 3.00), 0.0, "pocket: bikes")
	c.put("prop_bike_rack", "worn", c.gp(28.00, 3.00), 0.0, "pocket: bikes")
	c.put("prop_picnic_table", "worn", c.gp(6.00, 20.00), 0.0, "pocket: a table")
	for k2: String in B:
		var r: Dictionary = B[k2]
		c.services(r, 2.0, 1 if not String(r.folder).begins_with("apartments/") else 2, String(r.folder).begins_with("apartments/") or String(r.folder).begins_with("houses/"))
		for dr: Array in r.doors:
			var q: Vector3 = dr[1]; var o: Vector3 = dr[2]
			c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.6, 1.4, 0.45)
	c.finish()
	quit()
