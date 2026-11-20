extends SceneTree
## Piece n_w_c11 (WEST FILL, the stadium's south-east fan plaza): u -191..-95, v -240..-209, 96 x 31 m, flat.
## SITE: the stadium's car park north, the south street (aprons x 4..6.5, 44..51.5) south.
## PLANNER: a FAN PLAZA where the crowd comes off the south street: two ticket and snack kiosks, benches, bins against the
## kiosks, bike racks, bollards against cars, the team statue, a bus shelter on the street.
## Layout row (-191.0, 0, -240.0): local x = u - (-191.0), z = v - (-240.0), heights absolute. Built by the west fill (University
## session, 20 Nov; review/fill_west/PLAN.md). Ground: the land 8 cm over it, eased over 8 m to the measured height of
## whatever borders each side; buildings on level pads at the highest ground under them (plinth faces downhill).
const L := preload("res://tools/city/pilot/pieces/w_fill_lib.gd")
## site u -191.0..-95.0 v -240.0..-209.0 (96.0 x 31.0 m); neighbours N {np.str_('st_stadium'): 49} S {np.str_('j_rs_t_lrr_a'): 6, np.str_('s_rs_b112_a'): 40, np.str_('s_rs_b112_b'): 3} W {'-': 16} E {'-': 16}
const LAND := {"x0": -9.0, "z0": -8.0, "step": 4.0, "nx": 30, "nz": 13, "h": [6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.11,6.11,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.11,6.11,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.11,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.11,6.11,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.11,6.11,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.11,6.11,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.11,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.11,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,6.10,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95,5.95]}
const EDGE_N := [[0.0,6.15],[2.0,6.15],[4.0,6.15],[6.0,6.15],[8.0,6.15],[10.0,6.15],[12.0,6.15],[14.0,6.15],[16.0,6.15],[18.0,6.15],[20.0,6.15],[22.0,6.15],[24.0,6.15],[26.0,6.15],[28.0,6.15],[30.0,6.15],[32.0,6.15],[34.0,6.15],[36.0,6.15],[38.0,6.15],[40.0,6.15],[42.0,6.15],[44.0,6.15],[46.0,6.15],[48.0,6.15],[50.0,6.15],[52.0,6.15],[54.0,6.15],[56.0,6.15],[58.0,6.15],[60.0,6.15],[62.0,6.15],[64.0,6.15],[66.0,6.15],[68.0,6.15],[70.0,6.15],[72.0,6.15],[74.0,6.15],[76.0,6.15],[78.0,6.15],[80.0,6.15],[82.0,6.15],[84.0,6.15],[86.0,6.15],[88.0,6.15],[90.0,6.15],[92.0,6.15],[94.0,6.15],[96.0,6.15]]
const EDGE_S := [[0.0,6.15],[2.0,6.15],[4.0,6.15],[6.0,6.15],[8.0,6.15],[10.0,6.15],[12.0,6.15],[14.0,6.15],[16.0,6.15],[18.0,6.15],[20.0,6.15],[22.0,6.15],[24.0,6.15],[26.0,6.15],[28.0,6.15],[30.0,6.15],[32.0,6.15],[34.0,6.15],[36.0,6.15],[38.0,6.15],[40.0,6.15],[42.0,6.15],[44.0,6.15],[46.0,6.15],[48.0,6.15],[50.0,6.15],[52.0,6.15],[54.0,6.15],[56.0,6.15],[58.0,6.15],[60.0,6.15],[62.0,6.15],[64.0,6.15],[66.0,6.15],[68.0,6.15],[70.0,6.15],[72.0,6.15],[74.0,6.15],[76.0,6.15],[78.0,6.15],[80.0,6.15],[82.0,6.15],[84.0,6.15],[86.0,6.15],[88.0,6.15],[90.0,6.15],[92.0,6.15],[94.0,6.15],[96.0,6.15]]
const EDGE_W := [[0.0,6.1],[2.0,6.1],[4.0,6.1],[6.0,6.1],[8.0,6.1],[10.0,6.1],[12.0,6.1],[14.0,6.1],[16.0,6.1],[18.0,6.1],[20.0,6.1],[22.0,6.1],[24.0,6.1],[26.0,6.1],[28.0,6.1],[30.0,6.025]]
const EDGE_E := [[0.0,6.1],[2.0,6.1],[4.0,6.1],[6.0,6.101],[8.0,6.102],[10.0,6.102],[12.0,6.102],[14.0,6.102],[16.0,6.102],[18.0,6.102],[20.0,6.102],[22.0,6.101],[24.0,6.101],[26.0,6.1],[28.0,6.1],[30.0,6.025]]

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var c := L.new("n_w_c11", 6.15)
	var W := 96.00; var D := 31.00
	var land := func(x: float, z: float) -> float: return L.land_at(LAND, x, z) + 0.08
	var base := L.edged(land, W, D, EDGE_N, EDGE_S, EDGE_W, EDGE_E, 8.0)
	var SITES := [["commercial/com_kiosk", Vector2(30.00, 22.00), "s", "kiosk_w"],
		["commercial/com_kiosk", Vector2(66.00, 22.00), "s", "kiosk_e"]]
	var pads: Array = []
	for st: Array in SITES:
		var r0: Array = L.bld_rect(String(st[0]), st[1], String(st[2]))
		pads.append([maxf(0.0, float(r0[0]) - 0.3), maxf(0.0, float(r0[1]) - 0.3), minf(W, float(r0[2]) + 0.3), minf(D, float(r0[3]) + 0.3)])
	var gl := L.grid_lots(0.0, 0.0, W, D, pads, base)
	c.terrain(gl.lots)
	c.skirt_depth = 0.5
	c.paint("plaza", 0.00, 0.00, 96.00, 31.00)                # the fan plaza
	c.paint("grass", 0.0, 0.0, W, D)
	c.build_floor(L.rect_edges(0.0, 0.0, W, D))
	if c.stage == "ground": c.finish(); quit(); return
	var B := {}
	for k in SITES.size():
		c.y0 = float(gl.pads[k][4])
		B[String(SITES[k][3])] = c.bld(String(SITES[k][0]), SITES[k][1], String(SITES[k][2]), false, String(SITES[k][3]), 0.70)

	c.put("prop_obelisk_monument", "worn", c.gp(48.00, 12.00), 0.0, "fan plaza: the team statue in the middle")
	c.put("prop_park_bench", "worn", c.gp(40.00, 12.00), 90.0, "fan plaza: a bench facing the statue")
	c.put("prop_park_bench", "worn", c.gp(56.00, 12.00), -90.0, "fan plaza: a bench facing the statue")
	c.put("prop_trash_receptacle", "worn", c.gp(26.90, 19.00), 0.0, "fan plaza: a bin against the kiosk's side")
	c.put("prop_recycling_receptacle", "worn", c.gp(69.10, 19.00), 0.0, "fan plaza: recycling against the kiosk's side")
	c.put("prop_bike_rack", "worn", c.gp(8.00, 27.00), 0.0, "fan plaza: bikes")
	c.put("prop_bike_rack", "worn", c.gp(12.00, 27.00), 0.0, "fan plaza: bikes")
	c.put("prop_bike_rack", "worn", c.gp(84.00, 27.00), 0.0, "fan plaza: bikes")
	c.put("prop_bike_rack", "worn", c.gp(88.00, 27.00), 0.0, "fan plaza: bikes")
	c.put("prop_bollard_steel", "worn", c.gp(20.00, 30.00), 0.0, "fan plaza: bollards along the street edge")
	c.put("prop_bollard_steel", "worn", c.gp(24.00, 30.00), 0.0, "fan plaza: bollards along the street edge")
	c.put("prop_bollard_steel", "worn", c.gp(36.00, 30.00), 0.0, "fan plaza: bollards along the street edge")
	c.put("prop_bollard_steel", "worn", c.gp(60.00, 30.00), 0.0, "fan plaza: bollards along the street edge")
	c.put("prop_bollard_steel", "worn", c.gp(72.00, 30.00), 0.0, "fan plaza: bollards along the street edge")
	c.put("prop_bollard_steel", "worn", c.gp(76.00, 30.00), 0.0, "fan plaza: bollards along the street edge")
	c.put("prop_bus_shelter", "worn", c.gp(46.00, 29.40), 0.0, "fan plaza: the game-day shuttle shelter facing the street")
	c.put("prop_lamp_victorian", "worn", c.gp(10.00, 4.00), 0.0, "fan plaza: lit for night games")
	c.put("prop_lamp_victorian", "worn", c.gp(86.00, 4.00), 0.0, "fan plaza: lit for night games")
	for k2: String in B:
		var r: Dictionary = B[k2]
		c.services(r, 2.0, 1 if not String(r.folder).begins_with("apartments/") else 2, String(r.folder).begins_with("apartments/") or String(r.folder).begins_with("houses/"))
		for dr: Array in r.doors:
			var q: Vector3 = dr[1]; var o: Vector3 = dr[2]
			c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.6, 1.4, 0.45)
	c.finish()
	quit()
