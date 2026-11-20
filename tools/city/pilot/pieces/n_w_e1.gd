extends SceneTree
## Piece n_w_e1 (WEST FILL, the south-west edge's west end): u -930..-809, v 209..256, 121 x 47 m; flat at 2.0.
## SITE: a street north (apron x 69..76.5), the ring road south. PLANNER: beach cottages facing the north street, a shared
## lot off the apron between them, their yards fenced against the sound wall to the ring road.
## Layout row (-930.0, 0, 209.0): local x = u - (-930.0), z = v - (209.0), heights absolute. Built by the west fill (University
## session, 20 Nov; review/fill_west/PLAN.md). Ground: the land 8 cm over it, eased over 8 m to the measured height of
## whatever borders each side; buildings on level pads at the highest ground under them (plinth faces downhill).
const L := preload("res://tools/city/pilot/pieces/w_fill_lib.gd")
## site u -930.0..-809.0 v 209.0..256.0 (121.0 x 47.0 m); neighbours N {np.str_('s_rg_nw_b124'): 55, np.str_('j_res'): 6} S {np.str_('s_rg_b159_1'): 2, '-': 59} W {'-': 23, np.str_('s_rg_b159_1'): 1} E {np.str_('j_res'): 6, np.str_('s_rg_se_b009'): 18}
const LAND := {"x0": -10.0, "z0": -9.0, "step": 4.0, "nx": 36, "nz": 17, "h": [1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,1.95,1.95,1.95,2.09,2.10,2.09,2.11,2.09,2.11,2.12,2.10,2.10,2.08,2.09,2.08,2.10,2.08,2.09,2.10,2.08,2.07,2.05,2.06,2.05,2.06,2.06,2.07,2.09,2.07,2.08,2.05,2.07,2.06,2.08,2.08,2.10,1.95,1.95,1.95,2.09,2.11,2.09,2.09,2.11,2.09,2.11,2.09,2.10,2.08,2.10,2.08,2.09,2.09,2.06,2.07,2.04,2.05,2.03,2.04,2.03,2.04,2.06,2.03,2.04,2.03,2.05,2.03,2.06,2.05,2.08,2.11,2.10,1.95,1.95,1.95,2.08,2.10,2.11,2.10,2.11,2.10,2.11,2.09,2.10,2.07,2.08,2.10,2.08,2.08,2.06,2.06,2.04,2.04,2.00,2.01,2.02,2.01,2.02,2.01,2.02,2.01,2.03,2.02,2.03,2.06,2.06,2.09,2.10,1.95,1.95,1.95,2.11,2.10,2.11,2.10,2.10,2.08,2.10,2.08,2.09,2.11,2.09,2.10,2.08,2.09,2.04,2.05,2.02,2.02,2.03,2.00,2.01,1.99,2.01,1.99,1.99,1.98,2.00,2.02,2.02,2.05,2.05,2.09,2.10,1.95,1.95,1.95,2.10,2.09,2.10,2.09,2.10,2.09,2.10,2.08,2.10,2.11,2.07,2.09,2.06,2.07,2.05,2.05,2.02,2.02,2.03,1.99,1.99,1.97,1.98,1.97,1.98,1.97,1.99,2.02,2.01,2.03,2.03,2.08,2.10,1.95,1.95,1.95,2.11,2.09,2.11,2.09,2.11,2.09,2.09,2.10,2.08,2.10,2.08,2.09,2.07,2.08,2.05,2.04,2.05,2.02,2.02,1.99,2.00,1.97,1.98,1.97,1.98,1.98,1.97,2.00,1.99,2.03,2.03,2.08,2.10,1.95,1.95,1.95,2.11,2.08,2.09,2.08,2.09,2.11,2.09,2.11,2.09,2.10,2.08,2.08,2.06,2.07,2.08,2.05,2.06,2.03,2.03,2.00,1.99,1.96,1.97,1.99,1.97,1.99,1.97,2.00,2.00,2.03,2.02,2.06,2.10,1.95,1.95,1.95,2.10,2.08,2.10,2.11,2.10,2.11,2.10,2.10,2.08,2.09,2.07,2.08,2.09,2.07,2.08,2.06,2.05,2.02,2.03,2.00,2.01,2.01,1.98,2.00,1.98,1.99,1.96,1.99,1.98,2.02,2.05,2.06,2.10,1.95,1.95,1.95,2.10,2.10,2.08,2.10,2.09,2.10,2.09,2.10,2.08,2.10,2.11,2.09,2.09,2.06,2.08,2.05,2.06,2.04,2.04,2.05,2.02,2.03,1.99,1.99,1.97,1.99,1.98,2.00,2.02,2.02,2.06,2.05,2.10,1.95,1.95,1.95,1.95,2.10,2.10,2.10,2.10,2.11,2.09,2.11,2.10,2.09,2.10,2.08,2.09,2.07,2.08,2.06,2.07,2.07,2.04,2.05,2.03,2.04,2.01,2.02,1.99,2.01,2.02,1.99,2.02,2.02,2.05,2.06,2.10,1.95,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.10,2.10,2.10,2.11,2.10,2.11,2.09,2.10,2.06,2.08,2.09,2.07,2.08,2.06,2.07,2.05,2.06,2.03,2.03,2.04,2.01,2.03,2.01,2.04,2.03,2.06,2.07,2.10,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.10,2.10,2.10,2.10,2.07,2.09,2.10,2.09,2.10,2.08,2.09,2.06,2.07,2.05,2.06,2.08,2.05,2.07,2.04,2.06,2.04,2.04,2.03,2.06,2.09,2.10,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.08,2.09,2.07,2.09,2.10,2.09,2.10,2.08,2.08,2.06,2.07,2.05,2.07,2.09,2.08,2.11,2.10,1.95,1.95,1.95]}
const EDGE_N := [[0.0,2.15],[2.0,2.15],[4.0,2.15],[6.0,2.15],[8.0,2.15],[10.0,2.15],[12.0,2.15],[14.0,2.15],[16.0,2.15],[18.0,2.15],[20.0,2.15],[22.0,2.15],[24.0,2.15],[26.0,2.15],[28.0,2.15],[30.0,2.15],[32.0,2.15],[34.0,2.15],[36.0,2.15],[38.0,2.15],[40.0,2.15],[42.0,2.15],[44.0,2.15],[46.0,2.15],[48.0,2.15],[50.0,2.15],[52.0,2.15],[54.0,2.15],[56.0,2.15],[58.0,2.15],[60.0,2.15],[62.0,2.15],[64.0,2.15],[66.0,2.15],[68.0,2.15],[70.0,2.15],[72.0,2.15],[74.0,2.15],[76.0,2.15],[78.0,2.15],[80.0,2.15],[82.0,2.15],[84.0,2.15],[86.0,2.15],[88.0,2.15],[90.0,2.15],[92.0,2.15],[94.0,2.15],[96.0,2.15],[98.0,2.15],[100.0,2.15],[102.0,2.15],[104.0,2.15],[106.0,2.15],[108.0,2.15],[110.0,2.15],[112.0,2.15],[114.0,2.15],[116.0,2.15],[118.0,2.15],[120.0,2.15]]
const EDGE_S := [[0.0,2.15],[2.0,2.15],[4.0,2.016],[6.0,2.081],[8.0,2.081],[10.0,2.081],[12.0,2.091],[14.0,2.1],[16.0,2.1],[18.0,2.1],[20.0,2.104],[22.0,2.108],[24.0,2.102],[26.0,2.097],[28.0,2.102],[30.0,2.107],[32.0,2.096],[34.0,2.084],[36.0,2.091],[38.0,2.098],[40.0,2.084],[42.0,2.069],[44.0,2.075],[46.0,2.081],[48.0,2.087],[50.0,2.093],[52.0,2.082],[54.0,2.071],[56.0,2.077],[58.0,2.082],[60.0,2.07],[62.0,2.057],[64.0,2.063],[66.0,2.069],[68.0,2.058],[70.0,2.047],[72.0,2.053],[74.0,2.058],[76.0,2.049],[78.0,2.039],[80.0,2.035],[82.0,2.03],[84.0,2.035],[86.0,2.04],[88.0,2.029],[90.0,2.018],[92.0,2.025],[94.0,2.032],[96.0,2.024],[98.0,2.016],[100.0,2.027],[102.0,2.037],[104.0,2.034],[106.0,2.031],[108.0,2.047],[110.0,2.063],[112.0,2.068],[114.0,2.072],[116.0,2.086],[118.0,2.1],[120.0,2.025]]
const EDGE_W := [[0.0,1.988],[2.0,2.063],[4.0,2.099],[6.0,2.098],[8.0,2.097],[10.0,2.095],[12.0,2.097],[14.0,2.103],[16.0,2.107],[18.0,2.108],[20.0,2.106],[22.0,2.1],[24.0,2.098],[26.0,2.099],[28.0,2.096],[30.0,2.09],[32.0,2.091],[34.0,2.098],[36.0,2.099],[38.0,2.093],[40.0,2.092],[42.0,2.097],[44.0,2.063],[46.0,2.15]]
const EDGE_E := [[0.0,2.15],[2.0,2.15],[4.0,2.15],[6.0,2.15],[8.0,2.15],[10.0,2.15],[12.0,2.15],[14.0,2.15],[16.0,2.15],[18.0,2.15],[20.0,2.15],[22.0,2.15],[24.0,2.15],[26.0,2.15],[28.0,2.15],[30.0,2.15],[32.0,2.15],[34.0,2.15],[36.0,2.15],[38.0,2.15],[40.0,2.15],[42.0,2.15],[44.0,2.15],[46.0,2.15]]

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var c := L.new("n_w_e1", 4.15)
	var W := 121.00; var D := 47.00
	var land := func(x: float, z: float) -> float: return L.land_at(LAND, x, z) + 0.08
	var base := L.edged(land, W, D, EDGE_N, EDGE_S, EDGE_W, EDGE_E, 8.0)
	var SITES := [["houses/beach_white", Vector2(9.50, 3.00), "n", "w_0"],
		["houses/beach_teal", Vector2(24.50, 3.00), "n", "w_1"],
		["houses/spanish_small", Vector2(39.50, 3.00), "n", "w_2"],
		["houses/beach_blue", Vector2(54.50, 3.00), "n", "w_3"],
		["houses/beach_blue", Vector2(92.75, 3.00), "n", "e_0"],
		["houses/beach_teal", Vector2(110.25, 3.00), "n", "e_1"]]
	var pads: Array = []
	for st: Array in SITES:
		var r0: Array = L.bld_rect(String(st[0]), st[1], String(st[2]))
		pads.append([maxf(0.0, float(r0[0]) - 0.3), maxf(0.0, float(r0[1]) - 0.3), minf(W, float(r0[2]) + 0.3), minf(D, float(r0[3]) + 0.3)])
	var gl := L.grid_lots(0.0, 0.0, W, D, pads, base)
	c.terrain(gl.lots)
	c.skirt_depth = 0.5
	c.paint("asphalt", 64.00, 0.00, 82.00, 44.00)                # the shared lot off the apron (x 69..76.5)
	c.paint("grass", 0.0, 0.0, W, D)
	c.build_floor(L.rect_edges(0.0, 0.0, W, D))
	if c.stage == "ground": c.finish(); quit(); return
	var B := {}
	for k in SITES.size():
		c.y0 = float(gl.pads[k][4])
		B[String(SITES[k][3])] = c.bld(String(SITES[k][0]), SITES[k][1], String(SITES[k][2]), false, String(SITES[k][3]), 0.70)

	c.privacy(Vector2(6.45, 9.05), Vector2(2.30, 9.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(12.55, 9.05), Vector2(16.70, 9.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(2.30, 9.05), Vector2(2.30, 46.00), "yard: the lot-line fence")
	c.privacy(Vector2(16.70, 9.05), Vector2(16.70, 46.00), "yard: the lot-line fence")
	c.privacy(Vector2(2.30, 46.00), Vector2(12.65, 46.00), "yard: the rear fence")
	c.privacy(Vector2(13.85, 46.00), Vector2(16.70, 46.00), "yard: the rear fence")
	c.privacy(Vector2(12.65, 46.00), Vector2(13.85, 46.00), "yard: the rear fence")
	c.put("prop_adirondack_white", "worn", c.gp(6.20, 29.55), 222.0, "back yard: a chair on the lawn")
	c.put("prop_adirondack_wood", "worn", c.gp(12.80, 31.55), 312.0, "back yard: a chair on the lawn facing the sun")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(14.75, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(20.95, 8.55), Vector2(17.30, 8.55), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(28.05, 8.55), Vector2(31.70, 8.55), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(17.30, 8.55), Vector2(17.30, 46.00), "yard: the lot-line fence")
	c.privacy(Vector2(31.70, 8.55), Vector2(31.70, 46.00), "yard: the lot-line fence")
	c.privacy(Vector2(17.30, 46.00), Vector2(20.15, 46.00), "yard: the rear fence")
	c.privacy(Vector2(21.35, 46.00), Vector2(31.70, 46.00), "yard: the rear fence")
	c.privacy(Vector2(20.15, 46.00), Vector2(21.35, 46.00), "yard: the rear fence")
	c.put("prop_patio_set_4", "worn", c.gp(21.20, 29.05), 283.0, "back yard: the patio table")
	c.put("prop_adirondack_white", "worn", c.gp(27.80, 31.05), 13.0, "back yard: a chair on the lawn")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(30.25, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(36.35, 8.05), Vector2(32.30, 8.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(42.65, 8.05), Vector2(46.70, 8.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(32.30, 8.05), Vector2(32.30, 46.00), "yard: the lot-line fence")
	c.privacy(Vector2(46.70, 8.05), Vector2(46.70, 46.00), "yard: the lot-line fence")
	c.privacy(Vector2(32.30, 46.00), Vector2(42.65, 46.00), "yard: the rear fence")
	c.privacy(Vector2(43.85, 46.00), Vector2(46.70, 46.00), "yard: the rear fence")
	c.privacy(Vector2(42.65, 46.00), Vector2(43.85, 46.00), "yard: the rear fence")
	c.put("prop_swing_set", "worn", c.gp(36.20, 28.55), 344.0, "back yard: the kids' swings")
	c.put("prop_patio_set_4", "worn", c.gp(42.80, 30.55), 74.0, "back yard: the patio table")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(44.85, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(51.20, 9.05), Vector2(47.30, 9.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(57.80, 9.05), Vector2(61.70, 9.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(47.30, 9.05), Vector2(47.30, 46.00), "yard: the lot-line fence")
	c.privacy(Vector2(61.70, 9.05), Vector2(61.70, 46.00), "yard: the lot-line fence")
	c.privacy(Vector2(47.30, 46.00), Vector2(50.15, 46.00), "yard: the rear fence")
	c.privacy(Vector2(51.35, 46.00), Vector2(61.70, 46.00), "yard: the rear fence")
	c.privacy(Vector2(50.15, 46.00), Vector2(51.35, 46.00), "yard: the rear fence")
	c.put("prop_picnic_table", "worn", c.gp(51.20, 29.55), 45.0, "back yard: a table in the yard")
	c.put("prop_swing_set", "worn", c.gp(57.80, 31.55), 135.0, "back yard: the kids' swings")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(60.00, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(89.45, 9.05), Vector2(84.30, 9.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(96.05, 9.05), Vector2(101.20, 9.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(84.30, 9.05), Vector2(84.30, 46.00), "yard: the lot-line fence")
	c.privacy(Vector2(101.20, 9.05), Vector2(101.20, 46.00), "yard: the lot-line fence")
	c.privacy(Vector2(84.30, 46.00), Vector2(96.53, 46.00), "yard: the rear fence")
	c.privacy(Vector2(97.72, 46.00), Vector2(101.20, 46.00), "yard: the rear fence")
	c.privacy(Vector2(96.53, 46.00), Vector2(97.72, 46.00), "yard: the rear fence")
	c.put("prop_patio_set_4", "worn", c.gp(88.90, 29.55), 333.0, "back yard: the patio table")
	c.put("prop_adirondack_white", "worn", c.gp(96.60, 31.55), 63.0, "back yard: a chair on the lawn")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(98.25, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(106.70, 8.55), Vector2(101.80, 8.55), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(113.80, 8.55), Vector2(118.70, 8.55), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(101.80, 8.55), Vector2(101.80, 46.00), "yard: the lot-line fence")
	c.privacy(Vector2(118.70, 8.55), Vector2(118.70, 46.00), "yard: the lot-line fence")
	c.privacy(Vector2(101.80, 46.00), Vector2(105.28, 46.00), "yard: the rear fence")
	c.privacy(Vector2(106.47, 46.00), Vector2(118.70, 46.00), "yard: the rear fence")
	c.privacy(Vector2(105.28, 46.00), Vector2(106.47, 46.00), "yard: the rear fence")
	c.put("prop_swing_set", "worn", c.gp(106.40, 29.05), 34.0, "back yard: the kids' swings")
	c.put("prop_patio_set_4", "worn", c.gp(114.10, 31.05), 124.0, "back yard: the patio table")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(116.00, 2.40), 0.0, "front: a pot by the walk")
	c.stalls.append([66.50, 6.00, 90.0, c.yf(66.50, 6.00)])
	c.stalls.append([66.50, 8.70, 90.0, c.yf(66.50, 8.70)])
	c.stalls.append([66.50, 11.40, 90.0, c.yf(66.50, 11.40)])
	c.stalls.append([66.50, 14.10, 90.0, c.yf(66.50, 14.10)])
	c.stalls.append([66.50, 16.80, 90.0, c.yf(66.50, 16.80)])
	c.stalls.append([66.50, 19.50, 90.0, c.yf(66.50, 19.50)])
	c.stalls.append([66.50, 22.20, 90.0, c.yf(66.50, 22.20)])
	c.stalls.append([66.50, 24.90, 90.0, c.yf(66.50, 24.90)])
	c.stalls.append([66.50, 27.60, 90.0, c.yf(66.50, 27.60)])
	c.stalls.append([66.50, 30.30, 90.0, c.yf(66.50, 30.30)])
	c.stalls.append([66.50, 33.00, 90.0, c.yf(66.50, 33.00)])
	c.stalls.append([66.50, 35.70, 90.0, c.yf(66.50, 35.70)])
	c.stalls.append([66.50, 38.40, 90.0, c.yf(66.50, 38.40)])
	c.stalls.append([79.50, 6.00, -90.0, c.yf(79.50, 6.00)])
	c.stalls.append([79.50, 8.70, -90.0, c.yf(79.50, 8.70)])
	c.stalls.append([79.50, 11.40, -90.0, c.yf(79.50, 11.40)])
	c.stalls.append([79.50, 14.10, -90.0, c.yf(79.50, 14.10)])
	c.stalls.append([79.50, 16.80, -90.0, c.yf(79.50, 16.80)])
	c.stalls.append([79.50, 19.50, -90.0, c.yf(79.50, 19.50)])
	c.stalls.append([79.50, 22.20, -90.0, c.yf(79.50, 22.20)])
	c.stalls.append([79.50, 24.90, -90.0, c.yf(79.50, 24.90)])
	c.stalls.append([79.50, 27.60, -90.0, c.yf(79.50, 27.60)])
	c.stalls.append([79.50, 30.30, -90.0, c.yf(79.50, 30.30)])
	c.stalls.append([79.50, 33.00, -90.0, c.yf(79.50, 33.00)])
	c.stalls.append([79.50, 35.70, -90.0, c.yf(79.50, 35.70)])
	c.stalls.append([79.50, 38.40, -90.0, c.yf(79.50, 38.40)])
	c.tyre(Vector2(72.8, 3.0), 0.0, 6.0, 0.45)
	c.cracks(64.0, 0.0, 82.0, 44.0, 6, 0.5)
	for k2: String in B:
		var r: Dictionary = B[k2]
		if not String(r.folder).begins_with("houses/"): c.services(r, 2.0, 1 if not String(r.folder).begins_with("apartments/") else 2, String(r.folder).begins_with("apartments/"))
		for dr: Array in r.doors:
			var q: Vector3 = dr[1]; var o: Vector3 = dr[2]
			c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.6, 1.4, 0.40)
	c.finish()
	quit()
