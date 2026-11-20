extends SceneTree
## Piece n_w_q3 (WEST FILL, a small hole left inside the civic heart (v_sw)): u -238..-209, v -568..-548, 29 x 20 m, flat.
## PLANNER: a LUNCH CORNER for the civic offices: two tables and a bike rack.
## Layout row (-238.0, 0, -568.0): local x = u - (-238.0), z = v - (-568.0), heights absolute. Built by the west fill (University
## session, 20 Nov; review/fill_west/PLAN.md). Ground: the land 8 cm over it, eased over 8 m to the measured height of
## whatever borders each side; buildings on level pads at the highest ground under them (plinth faces downhill).
const L := preload("res://tools/city/pilot/pieces/w_fill_lib.gd")
## site u -238.0..-209.0 v -568.0..-548.0 (29.0 x 20.0 m); neighbours N {np.str_('v_sw'): 15} S {np.str_('v_sw'): 15} W {np.str_('v_sw'): 11} E {np.str_('s_civ'): 11}
const LAND := {"x0": -10.0, "z0": -8.0, "step": 4.0, "nx": 13, "nz": 10, "h": [6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,5.95,5.95,5.95,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,5.95,5.95,5.95,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,5.95,5.95,5.95,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,5.95,5.95,5.95,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,5.95,5.95,5.95,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,5.95,5.95,5.95,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,5.95,5.95,5.95,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,5.95,5.95,5.95,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,5.95,5.95,5.95,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,5.95,5.95,5.95]}
const EDGE_N := [[0.0,6.15],[2.0,6.15],[4.0,6.15],[6.0,6.15],[8.0,6.15],[10.0,6.15],[12.0,6.15],[14.0,6.15],[16.0,6.15],[18.0,6.15],[20.0,6.15],[22.0,6.15],[24.0,6.15],[26.0,6.15],[28.0,6.15]]
const EDGE_S := [[0.0,6.15],[2.0,6.15],[4.0,6.15],[6.0,6.15],[8.0,6.15],[10.0,6.15],[12.0,6.15],[14.0,6.15],[16.0,6.15],[18.0,6.15],[20.0,6.15],[22.0,6.15],[24.0,6.15],[26.0,6.15],[28.0,6.15]]
const EDGE_W := [[0.0,6.15],[2.0,6.15],[4.0,6.15],[6.0,6.15],[8.0,6.15],[10.0,6.15],[12.0,6.15],[14.0,6.15],[16.0,6.15],[18.0,6.15],[20.0,6.15]]
const EDGE_E := [[0.0,6.15],[2.0,6.15],[4.0,6.15],[6.0,6.15],[8.0,6.15],[10.0,6.15],[12.0,6.15],[14.0,6.15],[16.0,6.15],[18.0,6.15],[20.0,6.15]]

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var c := L.new("n_w_q3", 6.15)
	var W := 29.00; var D := 20.00
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
	c.paint("concrete", 0.00, 0.00, 29.00, 20.00)                # paving
	c.paint("grass", 0.0, 0.0, W, D)
	c.build_floor(L.rect_edges(0.0, 0.0, W, D))
	if c.stage == "ground": c.finish(); quit(); return
	var B := {}
	for k in SITES.size():
		c.y0 = float(gl.pads[k][4])
		B[String(SITES[k][3])] = c.bld(String(SITES[k][0]), SITES[k][1], String(SITES[k][2]), false, String(SITES[k][3]), 0.70)

	c.put("prop_picnic_table", "worn", c.gp(8.00, 10.00), 0.0, "lunch corner: a table")
	c.put("prop_picnic_table", "worn", c.gp(20.00, 10.00), 0.0, "lunch corner: a table")
	c.put("prop_bike_rack", "worn", c.gp(14.00, 18.60), 0.0, "lunch corner: bikes")
	for k2: String in B:
		var r: Dictionary = B[k2]
		c.services(r, 2.0, 1 if not String(r.folder).begins_with("apartments/") else 2, String(r.folder).begins_with("apartments/") or String(r.folder).begins_with("houses/"))
		for dr: Array in r.doors:
			var q: Vector3 = dr[1]; var o: Vector3 = dr[2]
			c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.6, 1.4, 0.45)
	c.finish()
	quit()
