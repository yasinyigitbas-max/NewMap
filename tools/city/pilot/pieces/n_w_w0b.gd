extends SceneTree
## Piece n_w_w0b (WEST FILL, the small spot Yasin marked north of the 56 % block): u -937..-900, v -1300..-1214, 37 x 86 m; flat 2.0..2.1.
## PLANNER: the industrial edge's ALLOTMENTS: beds on mulch inside a picket fence with a gate, a tool shed, water,
## benches; workers from the yards next door keep plots here.
## Layout row (-937.0, 0, -1300.0): local x = u - (-937.0), z = v - (-1300.0), heights absolute. Built by the west fill (University
## session, 20 Nov; review/fill_west/PLAN.md). Ground: the land 8 cm over it, eased over 8 m to the measured height of
## whatever borders each side; buildings on level pads at the highest ground under them (plinth faces downhill).
const L := preload("res://tools/city/pilot/pieces/w_fill_lib.gd")
## site u -937.0..-900.0 v -1300.0..-1214.0 (37.0 x 86.0 m); neighbours N {np.str_('i_green_w951_n1400_se'): 19} S {np.str_('j_rg_nw_w952_n1200'): 6, np.str_('s_rg_nw_b072'): 13} W {np.str_('s_rg_nw_b151_2'): 38, np.str_('j_rg_nw_w952_n1200'): 6} E {np.str_('g_v1_j4nw'): 44}
const LAND := {"x0": -11.0, "z0": -8.0, "step": 4.0, "nx": 15, "nz": 27, "h": [1.95,1.95,1.95,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,1.95,1.95,1.95,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,1.95,1.95,1.95,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,1.95,1.95,1.95,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,1.95,1.95,1.95,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,1.95,1.95,1.95,2.10,2.09,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,1.95,1.95,1.95,2.10,2.10,2.10,2.09,2.09,2.09,2.10,2.10,2.10,2.10,2.10,2.10,1.95,1.95,1.95,2.10,2.10,2.09,2.09,2.09,2.09,2.09,2.09,2.10,2.10,2.10,2.10,1.95,1.95,1.95,2.10,2.09,2.09,2.09,2.09,2.09,2.09,2.09,2.10,2.10,2.10,2.10,1.95,1.95,1.95,2.10,2.09,2.08,2.08,2.08,2.08,2.09,2.09,2.09,2.10,2.10,2.10,1.95,1.95,1.95,2.10,2.09,2.08,2.08,2.08,2.08,2.08,2.09,2.09,2.10,2.10,2.10,1.95,1.95,1.95,2.10,2.08,2.07,2.07,2.07,2.07,2.07,2.08,2.09,2.10,2.10,2.10,1.95,1.95,1.95,2.10,2.08,2.07,2.06,2.06,2.06,2.07,2.07,2.09,2.10,2.10,2.10,1.95,1.95,1.95,2.10,2.08,2.07,2.06,2.05,2.05,2.06,2.07,2.08,2.10,2.10,2.10,1.95,1.95,1.95,2.10,2.08,2.06,2.05,2.05,2.05,2.05,2.06,2.08,2.10,2.10,2.10,1.95,1.95,1.95,2.10,2.08,2.06,2.05,2.04,2.05,2.05,2.06,2.08,2.10,2.10,2.10,1.95,1.95,1.95,2.10,2.08,2.06,2.05,2.04,2.04,2.05,2.06,2.08,2.10,2.10,2.10,1.95,1.95,1.95,2.10,2.08,2.06,2.05,2.04,2.04,2.05,2.06,2.08,2.10,2.10,2.10,1.95,1.95,1.95,2.10,2.08,2.06,2.05,2.05,2.04,2.05,2.06,2.08,2.10,2.10,2.10,1.95,1.95,1.95,2.10,2.08,2.06,2.05,2.05,2.05,2.06,2.06,2.08,2.10,2.10,2.10,1.95,1.95,1.95,2.10,2.08,2.07,2.06,2.06,2.06,2.06,2.07,2.08,2.10,2.10,2.10,1.95,1.95,1.95,2.10,2.08,2.08,2.07,2.07,2.07,2.07,2.08,2.08,2.10,2.10,2.10,1.95,1.95,1.95,2.10,2.09,2.08,2.08,2.08,2.08,2.08,2.09,2.09,2.10,2.10,2.10,1.95,1.95,1.95,1.95,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95]}
const EDGE_N := [[0.0,2.15],[2.0,2.15],[4.0,2.15],[6.0,2.15],[8.0,2.15],[10.0,2.15],[12.0,2.15],[14.0,2.15],[16.0,2.15],[18.0,2.15],[20.0,2.15],[22.0,2.15],[24.0,2.15],[26.0,2.15],[28.0,2.15],[30.0,2.15],[32.0,2.15],[34.0,2.15],[36.0,2.15]]
const EDGE_S := [[0.0,2.15],[2.0,2.15],[4.0,2.15],[6.0,2.15],[8.0,2.15],[10.0,2.15],[12.0,2.15],[14.0,2.15],[16.0,2.15],[18.0,2.15],[20.0,2.15],[22.0,2.15],[24.0,2.15],[26.0,2.15],[28.0,2.15],[30.0,2.15],[32.0,2.15],[34.0,2.15],[36.0,2.15]]
const EDGE_W := [[0.0,2.15],[2.0,2.15],[4.0,2.15],[6.0,2.15],[8.0,2.15],[10.0,2.15],[12.0,2.15],[14.0,2.15],[16.0,2.15],[18.0,2.15],[20.0,2.15],[22.0,2.15],[24.0,2.15],[26.0,2.15],[28.0,2.15],[30.0,2.15],[32.0,2.15],[34.0,2.15],[36.0,2.15],[38.0,2.15],[40.0,2.15],[42.0,2.15],[44.0,2.15],[46.0,2.15],[48.0,2.15],[50.0,2.15],[52.0,2.15],[54.0,2.15],[56.0,2.15],[58.0,2.15],[60.0,2.15],[62.0,2.15],[64.0,2.15],[66.0,2.15],[68.0,2.15],[70.0,2.15],[72.0,2.15],[74.0,2.15],[76.0,2.15],[78.0,2.15],[80.0,2.15],[82.0,2.15],[84.0,2.15],[86.0,2.15]]
const EDGE_E := [[0.0,2.15],[2.0,2.15],[4.0,2.15],[6.0,2.15],[8.0,2.15],[10.0,2.15],[12.0,2.15],[14.0,2.15],[16.0,2.15],[18.0,2.15],[20.0,2.15],[22.0,2.15],[24.0,2.15],[26.0,2.15],[28.0,2.15],[30.0,2.15],[32.0,2.15],[34.0,2.15],[36.0,2.15],[38.0,2.15],[40.0,2.15],[42.0,2.15],[44.0,2.15],[46.0,2.15],[48.0,2.15],[50.0,2.15],[52.0,2.15],[54.0,2.15],[56.0,2.15],[58.0,2.15],[60.0,2.15],[62.0,2.15],[64.0,2.15],[66.0,2.15],[68.0,2.15],[70.0,2.15],[72.0,2.15],[74.0,2.15],[76.0,2.15],[78.0,2.15],[80.0,2.15],[82.0,2.15],[84.0,2.15],[86.0,2.15]]

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var c := L.new("n_w_w0b", 2.15)
	var W := 37.00; var D := 86.00
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
	c.paint("mulch", 4.00, 4.00, 33.00, 76.00)                # the allotment beds
	c.paint("concrete", 0.00, 78.00, 37.00, 82.00)                # the path
	c.paint("grass", 0.0, 0.0, W, D)
	c.build_floor(L.rect_edges(0.0, 0.0, W, D))
	if c.stage == "ground": c.finish(); quit(); return
	var B := {}
	for k in SITES.size():
		c.y0 = float(gl.pads[k][4])
		B[String(SITES[k][3])] = c.bld(String(SITES[k][0]), SITES[k][1], String(SITES[k][2]), false, String(SITES[k][3]), 0.70)

	c.ring_fence("picket", [Vector2(3.00, 3.00), Vector2(34.00, 3.00), Vector2(34.00, 77.00), Vector2(3.00, 77.00)], 2, 16.00, 1.10, "fence_gate_picket", "allotments: a picket fence round them")
	c.put("plant_agave_americana_small", "worn", c.gp(8.00, 10.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(8.00, 18.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(8.00, 26.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(8.00, 34.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(8.00, 42.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(8.00, 50.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(8.00, 58.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(8.00, 66.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(15.00, 10.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(15.00, 18.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(15.00, 26.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(15.00, 34.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(15.00, 42.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(15.00, 50.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(15.00, 58.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(15.00, 66.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(22.00, 10.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(22.00, 18.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(22.00, 26.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(22.00, 34.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(22.00, 42.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(22.00, 50.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(22.00, 58.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(22.00, 66.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(29.00, 10.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(29.00, 18.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(29.00, 26.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(29.00, 34.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(29.00, 42.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(29.00, 50.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(29.00, 58.00), 0.0, "allotments: a bed")
	c.put("plant_agave_americana_small", "worn", c.gp(29.00, 66.00), 0.0, "allotments: a bed")
	c.put("prop_container_20ft_blue", "worn", c.gp(28.00, 12.00), 0.0, "allotments: the tool shed")
	c.put("prop_drinking_fountain", "worn", c.gp(18.00, 79.40), 0.0, "path: water")
	c.put("prop_park_bench", "worn", c.gp(8.00, 80.60), 180.0, "path: a bench facing the beds")
	for k2: String in B:
		var r: Dictionary = B[k2]
		c.services(r, 2.0, 1 if not String(r.folder).begins_with("apartments/") else 2, String(r.folder).begins_with("apartments/") or String(r.folder).begins_with("houses/"))
		for dr: Array in r.doors:
			var q: Vector3 = dr[1]; var o: Vector3 = dr[2]
			c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.6, 1.4, 0.45)
	c.finish()
	quit()
