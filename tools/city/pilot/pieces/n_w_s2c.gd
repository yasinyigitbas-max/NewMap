extends SceneTree
## Piece n_w_s2c (WEST FILL, the pocket between the gritty edge's lot and the student strip): u -545..-500,
## v -940..-900, 45 x 40 m, flat.
## PLANNER: a STUDENT POCKET PARK behind the strip: a mural wall against the gritty lot, lawn, tables, a ping-pong-less
## corner of benches facing the lawn, bike racks, a drinking fountain; reached from the strip's back lane and the market
## block.
## Layout row (-545.0, 0, -940.0): local x = u - (-545.0), z = v - (-940.0), heights absolute. Built by the west fill (University
## session, 20 Nov; review/fill_west/PLAN.md). Ground: the land 8 cm over it, eased over 8 m to the measured height of
## whatever borders each side; buildings on level pads at the highest ground under them (plinth faces downhill).
const L := preload("res://tools/city/pilot/pieces/w_fill_lib.gd")
## site u -545.0..-500.0 v -940.0..-900.0 (45.0 x 40.0 m); neighbours N {np.str_('g_se'): 23} S {'-': 23} W {np.str_('g_se'): 21} E {'-': 21}
const LAND := {"x0": -11.0, "z0": -8.0, "step": 4.0, "nx": 17, "nz": 15, "h": [6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.09,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.09,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.09,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.09,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.09,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.09,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.09,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.09,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.09,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.08,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.08,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.08,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.08,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.07,6.09,6.09,6.09,6.09,6.09,6.09,6.09,6.09,6.09,6.09,6.09,6.09,6.08,6.08,6.08,6.07,6.05]}
const EDGE_N := [[0.0,6.15],[2.0,6.15],[4.0,6.15],[6.0,6.15],[8.0,6.15],[10.0,6.15],[12.0,6.15],[14.0,6.15],[16.0,6.15],[18.0,6.15],[20.0,6.15],[22.0,6.15],[24.0,6.15],[26.0,6.15],[28.0,6.15],[30.0,6.15],[32.0,6.15],[34.0,6.15],[36.0,6.15],[38.0,6.15],[40.0,6.15],[42.0,6.15],[44.0,6.15]]
const EDGE_S := [[0.0,6.1],[2.0,6.1],[4.0,6.1],[6.0,6.1],[8.0,6.1],[10.0,6.1],[12.0,6.1],[14.0,6.1],[16.0,6.1],[18.0,6.1],[20.0,6.1],[22.0,6.1],[24.0,6.1],[26.0,6.1],[28.0,6.1],[30.0,6.1],[32.0,6.1],[34.0,6.1],[36.0,6.1],[38.0,6.1],[40.0,6.1],[42.0,6.1],[44.0,6.1]]
const EDGE_W := [[0.0,6.15],[2.0,6.15],[4.0,6.15],[6.0,6.15],[8.0,6.15],[10.0,6.15],[12.0,6.15],[14.0,6.15],[16.0,6.15],[18.0,6.15],[20.0,6.15],[22.0,6.15],[24.0,6.15],[26.0,6.15],[28.0,6.15],[30.0,6.15],[32.0,6.15],[34.0,6.15],[36.0,6.15],[38.0,6.15],[40.0,6.15]]
const EDGE_E := [[0.0,6.1],[2.0,6.1],[4.0,6.1],[6.0,6.1],[8.0,6.1],[10.0,6.1],[12.0,6.1],[14.0,6.1],[16.0,6.1],[18.0,6.1],[20.0,6.1],[22.0,6.1],[24.0,6.1],[26.0,6.1],[28.0,6.1],[30.0,6.1],[32.0,6.1],[34.0,6.1],[36.0,6.1],[38.0,6.1],[40.0,6.1]]

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var c := L.new("n_w_s2c", 6.15)
	var W := 45.00; var D := 40.00
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
	c.paint("concrete", 0.00, 0.00, 45.00, 4.00)                # walk along the mural wall
	c.paint("concrete", 20.00, 4.00, 24.00, 40.00)                # the path through it
	c.paint("concrete", 0.00, 36.00, 45.00, 40.00)                # the walk on the strip's side
	c.paint("grass", 0.0, 0.0, W, D)
	c.build_floor(L.rect_edges(0.0, 0.0, W, D))
	if c.stage == "ground": c.finish(); quit(); return
	var B := {}
	for k in SITES.size():
		c.y0 = float(gl.pads[k][4])
		B[String(SITES[k][3])] = c.bld(String(SITES[k][0]), SITES[k][1], String(SITES[k][2]), false, String(SITES[k][3]), 0.70)

	for pt: Array in [[8.0, 14.0], [36.0, 14.0], [8.0, 26.0], [36.0, 26.0]]: c.put("prop_picnic_table", "worn", c.gp(float(pt[0]), float(pt[1])), 0.0, "pocket park: tables for lunch from the strip")
	for bn: Array in [[19.0, 10.0, 90.0], [25.0, 30.0, -90.0]]: c.put("prop_park_bench", "worn", c.gp(float(bn[0]), float(bn[1])), float(bn[2]), "pocket park: a bench on the path facing the lawn")
	c.put("prop_drinking_fountain", "worn", c.gp(24.8, 20.0), 0.0, "pocket park: water by the path")
	for br: float in [4.0, 38.0, 41.0]: c.put("prop_bike_rack", "worn", c.gp(br, 38.0), 0.0, "pocket park: bikes on the strip side")
	c.put("prop_trash_receptacle", "worn", c.gp(22.0, 1.8), 0.0, "pocket park: a bin against the mural wall")
	for pl: Array in [[3.0, 20.0], [42.0, 20.0]]: c.put("plant_bird_of_paradise", "normal", c.gp(float(pl[0]), float(pl[1])), c.rr.randf_range(0, 360), "pocket park: flower beds at its sides")
	for k2: String in B:
		var r: Dictionary = B[k2]
		if not String(r.folder).begins_with("houses/"): c.services(r, 2.0, 1 if not String(r.folder).begins_with("apartments/") else 2, String(r.folder).begins_with("apartments/"))
		for dr: Array in r.doors:
			var q: Vector3 = dr[1]; var o: Vector3 = dr[2]
			c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.6, 1.4, 0.45)
	c.finish()
	quit()
