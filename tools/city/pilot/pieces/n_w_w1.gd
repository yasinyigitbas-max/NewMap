extends SceneTree
## Piece n_w_w1 (WEST FILL, the strip between the ring road's houses and the gritty edge): u -938..-900, v -1186..-1009,
## 38 x 177 m; land 2.0 (north) to 4.1 (south).
## PLANNER: RIDGE GARDEN NURSERY: rows of plants on gravel inside a chain-link fence, the sales hut at the north end, a
## parking strip, a bench; the land climbs 2 m along it.
## Layout row (-938.0, 0, -1186.0): local x = u - (-938.0), z = v - (-1186.0), heights absolute. Built by the west fill (University
## session, 20 Nov; review/fill_west/PLAN.md). Ground: the land 8 cm over it, eased over 8 m to the measured height of
## whatever borders each side; buildings on level pads at the highest ground under them (plinth faces downhill).
const L := preload("res://tools/city/pilot/pieces/w_fill_lib.gd")
## site u -938.0..-900.0 v -1186.0..-1009.0 (38.0 x 177.0 m); neighbours N {np.str_('j_rg_nw_w952_n1200'): 6, np.str_('s_rg_nw_b072'): 14} S {np.str_('s_rg_nw_b080'): 20} W {np.str_('j_rg_nw_w952_n1200'): 6, np.str_('s_rg_nw_b152_1'): 14, '-': 69} E {np.str_('g_v2_j4sw'): 43, np.str_('g_v3_j5nw'): 46}
const LAND := {"x0": -10.0, "z0": -10.0, "step": 4.0, "nx": 15, "nz": 50, "h": [1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,1.95,1.95,1.95,2.10,2.10,2.12,2.12,2.12,2.12,2.11,2.12,2.11,2.11,2.11,2.10,1.95,1.95,1.95,2.10,2.11,2.13,2.13,2.13,2.15,2.14,2.15,2.14,2.13,2.10,2.10,1.95,1.95,1.95,2.10,2.13,2.13,2.16,2.16,2.18,2.17,2.18,2.17,2.16,2.10,2.10,1.96,1.96,1.96,2.11,2.15,2.16,2.18,2.19,2.22,2.21,2.23,2.22,2.20,2.18,2.12,1.97,1.97,1.98,2.13,2.18,2.19,2.22,2.23,2.25,2.26,2.25,2.26,2.25,2.25,2.24,1.99,1.99,2.00,2.15,2.20,2.22,2.26,2.27,2.28,2.31,2.31,2.32,2.31,2.30,2.29,2.03,2.02,2.03,2.18,2.23,2.26,2.28,2.32,2.33,2.36,2.36,2.38,2.37,2.36,2.35,2.05,2.05,2.05,2.20,2.25,2.30,2.33,2.37,2.38,2.41,2.42,2.44,2.43,2.42,2.41,2.09,2.07,2.09,2.23,2.28,2.35,2.38,2.42,2.44,2.48,2.48,2.48,2.50,2.49,2.48,2.13,2.11,2.13,2.27,2.33,2.40,2.43,2.48,2.50,2.51,2.54,2.55,2.57,2.56,2.55,2.17,2.15,2.24,2.29,2.37,2.45,2.49,2.52,2.57,2.58,2.61,2.62,2.64,2.63,2.62,2.22,2.22,2.35,2.40,2.45,2.49,2.55,2.58,2.62,2.64,2.68,2.68,2.71,2.70,2.68,2.26,2.28,2.42,2.45,2.52,2.55,2.61,2.64,2.69,2.71,2.75,2.76,2.78,2.76,2.75,2.32,2.40,2.47,2.51,2.58,2.62,2.68,2.70,2.75,2.77,2.79,2.82,2.84,2.83,2.81,2.39,2.48,2.52,2.58,2.65,2.68,2.73,2.76,2.78,2.83,2.84,2.88,2.90,2.89,2.87,2.47,2.62,2.63,2.65,2.70,2.74,2.76,2.81,2.83,2.87,2.89,2.93,2.95,2.94,2.93,2.56,2.67,2.71,2.72,2.75,2.79,2.81,2.85,2.87,2.91,2.94,2.98,3.00,2.99,2.98,2.67,2.73,2.77,2.79,2.81,2.85,2.87,2.91,2.92,2.96,2.97,3.02,3.04,3.03,3.02,2.83,2.80,2.82,2.86,2.87,2.91,2.92,2.95,2.96,3.00,3.01,3.03,3.07,3.06,3.06,2.89,2.90,2.90,2.92,2.93,2.96,2.97,3.00,3.01,3.02,3.05,3.05,3.09,3.09,3.08,2.95,2.97,2.97,3.00,3.00,3.02,3.03,3.03,3.05,3.05,3.08,3.07,3.10,3.10,3.10,3.02,3.05,3.04,3.06,3.06,3.06,3.08,3.08,3.10,3.09,3.11,3.10,3.10,3.11,3.11,3.10,3.12,3.11,3.11,3.13,3.12,3.14,3.14,3.14,3.14,3.15,3.13,3.12,3.12,3.13,3.19,3.18,3.19,3.18,3.19,3.18,3.19,3.18,3.19,3.18,3.17,3.17,3.14,3.15,3.16,3.26,3.25,3.26,3.24,3.25,3.24,3.25,3.24,3.22,3.23,3.21,3.20,3.18,3.19,3.19,3.34,3.33,3.33,3.31,3.31,3.30,3.28,3.29,3.27,3.27,3.25,3.25,3.22,3.22,3.22,3.43,3.40,3.39,3.38,3.35,3.36,3.34,3.34,3.33,3.33,3.30,3.30,3.27,3.27,3.34,3.49,3.46,3.44,3.44,3.42,3.42,3.40,3.40,3.38,3.38,3.35,3.33,3.32,3.32,3.41,3.53,3.52,3.50,3.50,3.47,3.47,3.45,3.46,3.44,3.42,3.41,3.39,3.38,3.38,3.45,3.59,3.58,3.56,3.56,3.54,3.53,3.51,3.49,3.49,3.47,3.47,3.44,3.44,3.45,3.48,3.65,3.64,3.61,3.61,3.59,3.57,3.57,3.55,3.55,3.53,3.53,3.51,3.50,3.51,3.50,3.70,3.69,3.67,3.64,3.64,3.62,3.63,3.61,3.61,3.59,3.59,3.58,3.56,3.58,3.58,3.75,3.73,3.72,3.70,3.69,3.67,3.67,3.66,3.66,3.65,3.63,3.64,3.64,3.64,3.66,3.80,3.77,3.77,3.74,3.74,3.73,3.73,3.71,3.70,3.71,3.70,3.71,3.70,3.70,3.66,3.84,3.82,3.81,3.79,3.79,3.78,3.78,3.77,3.75,3.76,3.76,3.77,3.76,3.76,3.66,3.89,3.86,3.86,3.84,3.84,3.82,3.81,3.82,3.81,3.82,3.81,3.83,3.83,3.81,3.66,3.92,3.90,3.90,3.88,3.87,3.87,3.86,3.86,3.86,3.87,3.86,3.88,3.88,3.87,3.66,3.96,3.94,3.92,3.92,3.91,3.91,3.90,3.91,3.90,3.92,3.91,3.91,3.94,3.94,3.83,3.98,3.98,3.96,3.96,3.95,3.96,3.95,3.95,3.95,3.94,3.96,3.96,3.98,3.99,3.99,4.01,4.01,4.00,4.00,3.99,4.00,3.99,3.98,3.99,3.99,4.00,4.00,4.03,4.04,4.08,4.04,4.05,4.03,4.04,4.03,4.02,4.03,4.02,4.03,4.02,4.04,4.04,4.06,4.07,4.10,4.07,4.08,4.07,4.06,4.07,4.06,4.06,4.05,4.07,4.06,4.08,4.07,4.06,4.07,4.08,4.10,4.10,4.10,4.10,4.10,4.10,4.10,4.10,4.10,4.10,4.10,4.10,4.10,4.10,4.10,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95]}
const EDGE_N := [[0.0,2.15],[2.0,2.15],[4.0,2.15],[6.0,2.15],[8.0,2.15],[10.0,2.15],[12.0,2.15],[14.0,2.15],[16.0,2.15],[18.0,2.15],[20.0,2.15],[22.0,2.15],[24.0,2.15],[26.0,2.15],[28.0,2.15],[30.0,2.15],[32.0,2.15],[34.0,2.15],[36.0,2.15],[38.0,2.15]]
const EDGE_S := [[0.0,4.15],[2.0,4.15],[4.0,4.15],[6.0,4.15],[8.0,4.15],[10.0,4.15],[12.0,4.15],[14.0,4.15],[16.0,4.15],[18.0,4.15],[20.0,4.15],[22.0,4.15],[24.0,4.15],[26.0,4.15],[28.0,4.15],[30.0,4.15],[32.0,4.15],[34.0,4.15],[36.0,4.15],[38.0,4.15]]
const EDGE_W := [[0.0,2.15],[2.0,2.15],[4.0,2.15],[6.0,2.15],[8.0,2.15],[10.0,2.15],[12.0,2.15],[14.0,2.152],[16.0,2.156],[18.0,2.161],[20.0,2.169],[22.0,2.178],[24.0,2.188],[26.0,2.2],[28.0,2.214],[30.0,2.228],[32.0,2.241],[34.0,2.255],[36.0,2.27],[38.0,2.286],[40.0,2.164],[42.0,2.182],[44.0,2.223],[46.0,2.263],[48.0,2.316],[50.0,2.369],[52.0,2.401],[54.0,2.433],[56.0,2.46],[58.0,2.487],[60.0,2.516],[62.0,2.544],[64.0,2.59],[66.0,2.636],[68.0,2.674],[70.0,2.711],[72.0,2.744],[74.0,2.776],[76.0,2.806],[78.0,2.836],[80.0,2.872],[82.0,2.908],[84.0,2.943],[86.0,2.979],[88.0,3.015],[90.0,3.051],[92.0,3.081],[94.0,3.112],[96.0,3.148],[98.0,3.185],[100.0,3.219],[102.0,3.253],[104.0,3.288],[106.0,3.324],[108.0,3.356],[110.0,3.388],[112.0,3.415],[114.0,3.441],[116.0,3.47],[118.0,3.499],[120.0,3.528],[122.0,3.557],[124.0,3.585],[126.0,3.613],[128.0,3.635],[130.0,3.657],[132.0,3.684],[134.0,3.711],[136.0,3.734],[138.0,3.757],[140.0,3.782],[142.0,3.806],[144.0,3.827],[146.0,3.849],[148.0,3.871],[150.0,3.893],[152.0,3.907],[154.0,3.921],[156.0,3.94],[158.0,3.96],[160.0,3.979],[162.0,3.998],[164.0,4.016],[166.0,4.034],[168.0,4.05],[170.0,4.066],[172.0,4.083],[174.0,4.1],[176.0,4.025]]
const EDGE_E := [[0.0,2.15],[2.0,2.153],[4.0,2.158],[6.0,2.165],[8.0,2.176],[10.0,2.189],[12.0,2.206],[14.0,2.223],[16.0,2.244],[18.0,2.266],[20.0,2.29],[22.0,2.316],[24.0,2.343],[26.0,2.373],[28.0,2.403],[30.0,2.434],[32.0,2.466],[34.0,2.5],[36.0,2.533],[38.0,2.568],[40.0,2.602],[42.0,2.637],[44.0,2.672],[46.0,2.707],[48.0,2.741],[50.0,2.776],[52.0,2.809],[54.0,2.842],[56.0,2.874],[58.0,2.905],[60.0,2.935],[62.0,2.964],[64.0,2.991],[66.0,3.017],[68.0,3.04],[70.0,3.062],[72.0,3.081],[74.0,3.099],[76.0,3.114],[78.0,3.127],[80.0,3.136],[82.0,3.144],[84.0,3.148],[86.0,3.151],[88.0,3.154],[90.0,3.158],[92.0,3.166],[94.0,3.176],[96.0,3.189],[98.0,3.203],[100.0,3.22],[102.0,3.239],[104.0,3.26],[106.0,3.282],[108.0,3.306],[110.0,3.331],[112.0,3.358],[114.0,3.386],[116.0,3.415],[118.0,3.444],[120.0,3.475],[122.0,3.507],[124.0,3.539],[126.0,3.571],[128.0,3.604],[130.0,3.637],[132.0,3.67],[134.0,3.702],[136.0,3.735],[138.0,3.767],[140.0,3.799],[142.0,3.831],[144.0,3.861],[146.0,3.891],[148.0,3.92],[150.0,3.948],[152.0,3.974],[154.0,3.999],[156.0,4.022],[158.0,4.047],[160.0,4.067],[162.0,4.085],[164.0,4.101],[166.0,4.115],[168.0,4.127],[170.0,4.135],[172.0,4.143],[174.0,4.147],[176.0,4.15]]

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var c := L.new("n_w_w1", 2.15)
	var W := 38.00; var D := 177.00
	var land := func(x: float, z: float) -> float: return L.land_at(LAND, x, z) + 0.08
	var base := L.edged(land, W, D, EDGE_N, EDGE_S, EDGE_W, EDGE_E, 8.0)
	var SITES := [["commercial/com_kiosk", Vector2(19.00, 8.00), "n", "nursery_hut"]]
	var pads: Array = []
	for st: Array in SITES:
		var r0: Array = L.bld_rect(String(st[0]), st[1], String(st[2]))
		pads.append([maxf(0.0, float(r0[0]) - 0.3), maxf(0.0, float(r0[1]) - 0.3), minf(W, float(r0[2]) + 0.3), minf(D, float(r0[3]) + 0.3)])
	var gl := L.grid_lots(0.0, 0.0, W, D, pads, base)
	c.terrain(gl.lots)
	c.skirt_depth = 0.5
	c.paint("gravel", 2.00, 20.00, 36.00, 170.00)                # the nursery's growing rows
	c.paint("asphalt", 2.00, 0.00, 36.00, 6.00)                # the customers' parking strip
	c.paint("grass", 0.0, 0.0, W, D)
	c.build_floor(L.rect_edges(0.0, 0.0, W, D))
	if c.stage == "ground": c.finish(); quit(); return
	var B := {}
	for k in SITES.size():
		c.y0 = float(gl.pads[k][4])
		B[String(SITES[k][3])] = c.bld(String(SITES[k][0]), SITES[k][1], String(SITES[k][2]), false, String(SITES[k][3]), 0.70)

	c.ring_fence("chainlink", [Vector2(1.50, 18.00), Vector2(36.50, 18.00), Vector2(36.50, 172.00), Vector2(1.50, 172.00)], 0, 30.00, 5.80, "fence_gate_rolling_chainlink", "nursery: chain-link round the rows")
	c.put("plant_potted_succulent", "normal", c.gp(6.00, 24.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(6.00, 36.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(6.00, 48.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(6.00, 60.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(6.00, 72.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(6.00, 84.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(6.00, 96.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(6.00, 108.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(6.00, 120.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(6.00, 132.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(6.00, 144.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(6.00, 156.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_leafy", "normal", c.gp(12.50, 24.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_leafy", "normal", c.gp(12.50, 36.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_leafy", "normal", c.gp(12.50, 48.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_leafy", "normal", c.gp(12.50, 60.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_leafy", "normal", c.gp(12.50, 72.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_leafy", "normal", c.gp(12.50, 84.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_leafy", "normal", c.gp(12.50, 96.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_leafy", "normal", c.gp(12.50, 108.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_leafy", "normal", c.gp(12.50, 120.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_leafy", "normal", c.gp(12.50, 132.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_leafy", "normal", c.gp(12.50, 144.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_leafy", "normal", c.gp(12.50, 156.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(19.00, 24.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(19.00, 36.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(19.00, 48.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(19.00, 60.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(19.00, 72.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(19.00, 84.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(19.00, 96.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(19.00, 108.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(19.00, 120.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(19.00, 132.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(19.00, 144.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(19.00, 156.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_leafy", "normal", c.gp(25.50, 24.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_leafy", "normal", c.gp(25.50, 36.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_leafy", "normal", c.gp(25.50, 48.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_leafy", "normal", c.gp(25.50, 60.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_leafy", "normal", c.gp(25.50, 72.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_leafy", "normal", c.gp(25.50, 84.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_leafy", "normal", c.gp(25.50, 96.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_leafy", "normal", c.gp(25.50, 108.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_leafy", "normal", c.gp(25.50, 120.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_leafy", "normal", c.gp(25.50, 132.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_leafy", "normal", c.gp(25.50, 144.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_leafy", "normal", c.gp(25.50, 156.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(32.00, 24.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(32.00, 36.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(32.00, 48.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(32.00, 60.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(32.00, 72.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(32.00, 84.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(32.00, 96.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(32.00, 108.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(32.00, 120.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(32.00, 132.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(32.00, 144.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_potted_succulent", "normal", c.gp(32.00, 156.00), 0.0, "nursery: a row of pots for sale")
	c.put("plant_agave_americana", "worn", c.gp(8.00, 164.00), 0.0, "nursery: agaves in the back row")
	c.put("plant_agave_americana", "worn", c.gp(18.00, 164.00), 0.0, "nursery: agaves in the back row")
	c.put("plant_agave_americana", "worn", c.gp(28.00, 164.00), 0.0, "nursery: agaves in the back row")
	c.put("prop_park_bench", "worn", c.gp(30.00, 12.00), 180.0, "nursery: a bench by the hut facing the street")
	c.put("prop_menu_board", "worn", c.gp(26.00, 6.80), 0.0, "nursery: today's specials")
	for k2: String in B:
		var r: Dictionary = B[k2]
		c.services(r, 2.0, 1 if not String(r.folder).begins_with("apartments/") else 2, String(r.folder).begins_with("apartments/") or String(r.folder).begins_with("houses/"))
		for dr: Array in r.doors:
			var q: Vector3 = dr[1]; var o: Vector3 = dr[2]
			c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.6, 1.4, 0.45)
	c.finish()
	quit()
