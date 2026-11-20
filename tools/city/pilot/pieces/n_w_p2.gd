extends SceneTree
## Piece n_w_p2 (WEST FILL, the 40 x 30 m hole inside the civic heart v_ne, the spot Yasin marked east of the 18 % block):
## u -188..-148, v -642..-612, flat.
## PLANNER: a SUCCULENT GARDEN for the civic offices' lunch break: a dry garden on mulch, a path, benches, a table.
## Layout row (-188.0, 0, -642.0): local x = u - (-188.0), z = v - (-642.0), heights absolute. Built by the west fill (University
## session, 20 Nov; review/fill_west/PLAN.md). Ground: the land 8 cm over it, eased over 8 m to the measured height of
## whatever borders each side; buildings on level pads at the highest ground under them (plinth faces downhill).
const L := preload("res://tools/city/pilot/pieces/w_fill_lib.gd")
## site u -188.0..-148.0 v -642.0..-612.0 (40.0 x 30.0 m); neighbours N {np.str_('v_ne'): 21} S {np.str_('v_ne'): 21} W {np.str_('v_ne'): 16} E {np.str_('v_ne'): 16}
const LAND := {"x0": -8.0, "z0": -10.0, "step": 4.0, "nx": 15, "nz": 13, "h": [5.95,5.95,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,5.95,5.95,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,5.95,5.95,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,5.95,5.95,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,5.95,5.95,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,5.95,5.95,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,5.95,5.95,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,5.95,5.95,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,5.95,5.95,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,5.95,5.95,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,5.95,5.95,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95]}
const EDGE_N := [[0.0,6.15],[2.0,6.15],[4.0,6.15],[6.0,6.15],[8.0,6.15],[10.0,6.15],[12.0,6.15],[14.0,6.15],[16.0,6.15],[18.0,6.15],[20.0,6.15],[22.0,6.15],[24.0,6.15],[26.0,6.15],[28.0,6.15],[30.0,6.15],[32.0,6.15],[34.0,6.15],[36.0,6.15],[38.0,6.15],[40.0,6.15]]
const EDGE_S := [[0.0,6.15],[2.0,6.15],[4.0,6.15],[6.0,6.15],[8.0,6.15],[10.0,6.15],[12.0,6.15],[14.0,6.15],[16.0,6.15],[18.0,6.15],[20.0,6.15],[22.0,6.15],[24.0,6.15],[26.0,6.15],[28.0,6.15],[30.0,6.15],[32.0,6.15],[34.0,6.15],[36.0,6.15],[38.0,6.15],[40.0,6.15]]
const EDGE_W := [[0.0,6.15],[2.0,6.15],[4.0,6.15],[6.0,6.15],[8.0,6.15],[10.0,6.15],[12.0,6.15],[14.0,6.15],[16.0,6.15],[18.0,6.15],[20.0,6.15],[22.0,6.15],[24.0,6.15],[26.0,6.15],[28.0,6.15],[30.0,6.15]]
const EDGE_E := [[0.0,6.15],[2.0,6.15],[4.0,6.15],[6.0,6.15],[8.0,6.15],[10.0,6.15],[12.0,6.15],[14.0,6.15],[16.0,6.15],[18.0,6.15],[20.0,6.15],[22.0,6.15],[24.0,6.15],[26.0,6.15],[28.0,6.15],[30.0,6.15]]

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var c := L.new("n_w_p2", 6.15)
	var W := 40.00; var D := 30.00
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
	c.paint("concrete", 0.00, 13.00, 40.00, 17.00)                # path
	c.paint("mulch", 2.00, 2.00, 38.00, 12.00)                # dry garden
	c.paint("mulch", 2.00, 18.00, 38.00, 28.00)                # dry garden
	c.paint("grass", 0.0, 0.0, W, D)
	c.build_floor(L.rect_edges(0.0, 0.0, W, D))
	if c.stage == "ground": c.finish(); quit(); return
	var B := {}
	for k in SITES.size():
		c.y0 = float(gl.pads[k][4])
		B[String(SITES[k][3])] = c.bld(String(SITES[k][0]), SITES[k][1], String(SITES[k][2]), false, String(SITES[k][3]), 0.70)

	c.put("plant_agave_americana", "worn", c.gp(6.00, 6.00), 0.0, "succulent garden: agaves on mulch")
	c.put("plant_agave_americana", "worn", c.gp(18.00, 8.00), 0.0, "succulent garden: agaves on mulch")
	c.put("plant_agave_americana", "worn", c.gp(30.00, 6.00), 0.0, "succulent garden: agaves on mulch")
	c.put("plant_agave_americana", "worn", c.gp(10.00, 24.00), 0.0, "succulent garden: agaves on mulch")
	c.put("plant_agave_americana", "worn", c.gp(26.00, 22.00), 0.0, "succulent garden: agaves on mulch")
	c.put("plant_agave_americana", "worn", c.gp(34.00, 25.00), 0.0, "succulent garden: agaves on mulch")
	c.put("plant_potted_succulent", "worn", c.gp(12.00, 12.30), 0.0, "succulent garden: pots along the path")
	c.put("plant_potted_succulent", "worn", c.gp(28.00, 12.30), 0.0, "succulent garden: pots along the path")
	c.put("prop_park_bench", "worn", c.gp(8.00, 17.80), 0.0, "succulent garden: a bench facing the garden")
	c.put("prop_park_bench", "worn", c.gp(32.00, 17.80), 0.0, "succulent garden: a bench facing the garden")
	c.put("prop_picnic_table", "worn", c.gp(20.00, 23.00), 0.0, "succulent garden: a lunch table")
	c.put("prop_drinking_fountain", "worn", c.gp(20.00, 12.40), 0.0, "succulent garden: water")
	for k2: String in B:
		var r: Dictionary = B[k2]
		c.services(r, 2.0, 1 if not String(r.folder).begins_with("apartments/") else 2, String(r.folder).begins_with("apartments/") or String(r.folder).begins_with("houses/"))
		for dr: Array in r.doors:
			var q: Vector3 = dr[1]; var o: Vector3 = dr[2]
			c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.6, 1.4, 0.45)
	c.finish()
	quit()
