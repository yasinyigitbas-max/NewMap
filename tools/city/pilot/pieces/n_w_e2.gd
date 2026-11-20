extends SceneTree
## Piece n_w_e2 (WEST FILL, the south-west edge): u -791..-609, v 209..275, 182 x 66 m; the land falls from 4.2 (east) to
## 2.0 (west) toward the shore. SITE: a street north (aprons x 44..51.5, 130..137.5), the ring road south.
## PLANNER: the beach side's houses (beach cottages, ranches, spanish) facing the north street on their own pads down the
## slope, a back lane between the aprons, a sound wall along the ring road behind it.
## Layout row (-791.0, 0, 209.0): local x = u - (-791.0), z = v - (209.0), heights absolute. Built by the west fill (University
## session, 20 Nov; review/fill_west/PLAN.md). Ground: the land 8 cm over it, eased over 8 m to the measured height of
## whatever borders each side; buildings on level pads at the highest ground under them (plinth faces downhill).
const L := preload("res://tools/city/pilot/pieces/w_fill_lib.gd")
## site u -791.0..-609.0 v 209.0..275.0 (182.0 x 66.0 m); neighbours N {np.str_('j_res'): 6, np.str_('s_rs_b125_a'): 40, np.str_('s_rs_b125_b'): 40, np.str_('j_rs_4r_c'): 6} S {np.str_('j_rg_w800_s289'): 4, '-': 88} W {np.str_('j_res'): 6, np.str_('s_rg_se_b009'): 21, np.str_('j_rg_w800_s289'): 7} E {np.str_('j_rs_4r_c'): 6, np.str_('s_rg_se_b017'): 28}
const LAND := {"x0": -9.0, "z0": -9.0, "step": 4.0, "nx": 51, "nz": 22, "h": [1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.96,1.98,2.01,2.04,2.07,2.11,2.16,2.21,2.26,2.32,2.38,2.45,2.51,2.58,2.65,2.73,2.80,2.87,2.95,3.02,3.10,3.17,3.25,3.32,3.39,3.45,3.52,3.58,3.64,3.69,3.74,3.79,3.83,3.86,3.89,3.92,3.94,3.95,3.95,3.95,3.95,3.95,3.95,3.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.96,1.98,2.00,2.03,2.06,2.10,2.14,2.19,2.24,2.30,2.36,2.42,2.49,2.56,2.63,2.70,2.78,2.85,2.92,3.00,3.07,3.15,3.22,3.29,3.36,3.43,3.50,3.56,3.62,3.67,3.73,3.77,3.82,3.85,3.88,3.91,3.93,3.94,3.95,3.95,3.95,3.95,3.95,3.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.97,1.99,2.01,2.04,2.08,2.12,2.17,2.22,2.27,2.33,2.40,2.46,2.53,2.60,2.67,2.74,2.82,2.89,2.97,3.04,3.12,3.19,3.26,3.33,3.40,3.47,3.53,3.59,3.65,3.70,3.75,3.80,3.84,3.87,3.90,3.92,3.94,3.95,3.95,3.95,3.95,3.95,3.95,3.95,1.95,1.95,1.95,2.10,2.10,2.10,2.10,2.11,2.13,2.16,2.19,2.22,2.26,2.31,2.36,2.41,2.47,2.53,2.60,2.66,2.73,2.80,2.88,2.95,3.03,3.10,3.17,3.25,3.32,3.40,3.47,3.54,3.60,3.67,3.73,3.79,3.84,3.89,3.94,3.98,4.01,4.04,4.07,4.09,4.10,4.10,4.10,4.10,3.95,3.95,3.95,1.95,1.95,1.95,2.10,2.10,2.09,2.11,2.14,2.14,2.18,2.19,2.22,2.25,2.31,2.34,2.42,2.49,2.53,2.61,2.66,2.74,2.77,2.86,2.92,3.00,3.10,3.16,3.24,3.30,3.38,3.42,3.50,3.55,3.63,3.71,3.75,3.81,3.85,3.91,3.94,3.97,3.99,4.03,4.07,4.07,4.09,4.09,4.10,3.95,3.95,3.95,1.95,1.95,1.95,2.10,2.11,2.12,2.12,2.13,2.13,2.17,2.18,2.23,2.25,2.31,2.38,2.42,2.47,2.51,2.59,2.63,2.71,2.77,2.85,2.94,2.99,3.08,3.12,3.20,3.26,3.34,3.39,3.47,3.55,3.60,3.68,3.70,3.76,3.80,3.86,3.89,3.94,3.99,4.00,4.05,4.05,4.06,4.07,4.10,3.95,3.95,3.95,1.95,1.95,1.95,2.10,2.09,2.11,2.10,2.13,2.14,2.17,2.19,2.24,2.27,2.30,2.36,2.40,2.47,2.51,2.59,2.63,2.71,2.79,2.82,2.91,2.96,3.05,3.10,3.19,3.24,3.32,3.40,3.43,3.51,3.56,3.63,3.67,3.74,3.77,3.83,3.89,3.91,3.94,3.96,4.01,4.02,4.06,4.07,4.10,3.95,3.95,3.95,1.95,1.95,1.95,2.10,2.09,2.11,2.11,2.14,2.12,2.16,2.17,2.22,2.28,2.30,2.37,2.40,2.47,2.49,2.56,2.61,2.69,2.77,2.82,2.90,2.95,3.04,3.09,3.15,3.20,3.29,3.37,3.41,3.49,3.54,3.61,3.65,3.69,3.73,3.79,3.85,3.87,3.93,3.95,3.99,4.01,4.06,4.05,4.10,3.95,3.95,3.95,1.95,1.95,1.95,2.10,2.07,2.10,2.09,2.12,2.12,2.16,2.21,2.23,2.28,2.29,2.35,2.38,2.45,2.49,2.56,2.64,2.68,2.76,2.81,2.87,2.93,3.01,3.06,3.14,3.22,3.27,3.35,3.40,3.45,3.50,3.57,3.61,3.68,3.74,3.77,3.83,3.86,3.91,3.91,3.96,3.98,4.03,4.08,4.10,3.95,3.95,3.95,1.95,1.95,1.95,2.10,2.08,2.10,2.09,2.12,2.16,2.15,2.19,2.21,2.26,2.29,2.35,2.38,2.45,2.52,2.54,2.62,2.66,2.74,2.79,2.87,2.92,3.00,3.08,3.13,3.19,3.24,3.32,3.37,3.44,3.48,3.56,3.63,3.66,3.73,3.74,3.80,3.82,3.88,3.90,3.96,4.01,4.03,4.09,4.10,3.95,3.95,3.95,1.95,1.95,1.95,2.10,2.09,2.09,2.11,2.11,2.14,2.15,2.20,2.21,2.27,2.29,2.33,2.40,2.43,2.50,2.54,2.62,2.66,2.74,2.79,2.87,2.93,2.98,3.06,3.11,3.19,3.23,3.31,3.36,3.43,3.49,3.53,3.59,3.63,3.70,3.73,3.79,3.81,3.87,3.93,3.93,3.99,4.01,4.07,4.10,3.95,3.95,3.95,1.95,1.95,1.95,2.10,2.11,2.09,2.12,2.11,2.15,2.15,2.18,2.20,2.25,2.31,2.33,2.40,2.43,2.50,2.54,2.60,2.64,2.72,2.80,2.85,2.93,2.98,3.06,3.10,3.18,3.21,3.29,3.36,3.41,3.48,3.52,3.59,3.62,3.69,3.72,3.76,3.82,3.85,3.90,3.93,3.98,4.01,4.07,4.10,3.95,3.95,3.95,1.95,1.95,1.95,2.10,2.11,2.10,2.10,2.10,2.13,2.14,2.18,2.23,2.25,2.31,2.34,2.38,2.42,2.49,2.53,2.60,2.68,2.72,2.80,2.85,2.93,2.96,3.04,3.09,3.16,3.24,3.29,3.37,3.41,3.48,3.50,3.57,3.60,3.67,3.73,3.76,3.82,3.85,3.90,3.93,3.96,3.99,4.04,4.10,3.95,3.95,3.95,1.95,1.95,1.95,2.10,2.10,2.09,2.11,2.10,2.14,2.18,2.19,2.22,2.24,2.30,2.32,2.39,2.42,2.49,2.57,2.61,2.68,2.71,2.79,2.84,2.92,2.96,3.04,3.12,3.17,3.25,3.27,3.35,3.39,3.47,3.50,3.57,3.64,3.67,3.74,3.77,3.80,3.83,3.89,3.91,3.97,4.02,4.05,4.10,3.95,3.95,3.95,1.95,1.95,1.95,2.10,2.11,2.09,2.11,2.12,2.12,2.16,2.18,2.22,2.25,2.30,2.33,2.40,2.44,2.48,2.56,2.60,2.67,2.72,2.80,2.85,2.93,3.01,3.03,3.11,3.16,3.24,3.28,3.36,3.40,3.48,3.55,3.56,3.63,3.66,3.73,3.75,3.81,3.84,3.89,3.95,3.97,4.01,4.03,4.10,3.95,3.95,3.95,1.95,1.95,1.95,2.10,2.10,2.11,2.10,2.13,2.13,2.17,2.18,2.23,2.23,2.29,2.36,2.39,2.46,2.49,2.57,2.61,2.69,2.73,2.79,2.87,2.92,3.00,3.05,3.13,3.18,3.26,3.30,3.36,3.43,3.47,3.55,3.58,3.65,3.68,3.74,3.77,3.83,3.86,3.88,3.94,3.96,4.02,4.04,4.10,3.95,3.95,3.95,1.95,1.95,1.95,2.10,2.09,2.11,2.10,2.13,2.12,2.16,2.17,2.22,2.28,2.30,2.37,2.40,2.47,2.49,2.56,2.61,2.68,2.76,2.81,2.89,2.94,3.02,3.07,3.13,3.18,3.26,3.34,3.38,3.46,3.50,3.57,3.61,3.65,3.68,3.75,3.80,3.83,3.88,3.90,3.96,3.98,4.03,4.03,4.10,3.95,3.95,3.95,1.95,1.95,1.95,2.10,2.08,2.10,2.09,2.12,2.12,2.18,2.22,2.24,2.29,2.30,2.36,2.40,2.47,2.51,2.58,2.66,2.71,2.79,2.84,2.90,2.95,3.03,3.08,3.16,3.24,3.29,3.37,3.41,3.46,3.51,3.58,3.62,3.68,3.75,3.78,3.84,3.86,3.91,3.90,3.95,3.97,4.02,4.08,4.10,3.95,3.95,3.95,1.95,1.95,1.95,2.10,2.10,2.11,2.11,2.13,2.16,2.19,2.21,2.23,2.29,2.32,2.38,2.42,2.49,2.56,2.59,2.66,2.71,2.79,2.85,2.92,2.98,3.07,3.14,3.19,3.25,3.30,3.38,3.42,3.50,3.54,3.62,3.69,3.72,3.79,3.80,3.85,3.87,3.92,3.93,3.98,4.03,4.04,4.10,4.10,3.95,3.95,3.95,1.95,1.95,1.95,1.95,1.95,1.96,1.99,2.13,2.16,2.19,2.21,2.25,2.30,2.34,2.39,2.45,2.51,2.55,2.63,2.69,2.74,2.82,2.90,2.95,3.02,3.10,3.16,3.20,3.29,3.35,3.43,3.47,3.54,3.60,3.65,3.72,3.75,3.82,3.85,3.91,3.91,3.95,4.00,3.99,4.03,4.04,4.09,4.10,3.95,3.95,3.95,1.95,1.95,1.95,1.95,1.95,1.95,1.96,1.98,2.00,2.03,2.06,2.10,2.14,2.19,2.26,2.31,2.37,2.43,2.57,2.64,2.72,2.80,2.90,2.95,3.02,3.10,3.18,3.24,3.32,3.39,3.46,3.52,3.57,3.65,3.71,3.77,3.82,3.87,3.91,3.97,3.97,3.97,4.01,4.02,4.07,4.07,4.10,4.10,3.95,3.95,3.95,1.95,1.95,1.95,1.95,1.95,1.95,1.96,1.98,2.00,2.03,2.06,2.10,2.14,2.18,2.23,2.28,2.33,2.39,2.46,2.52,2.58,2.66,2.73,2.81,2.87,2.95,3.02,3.10,3.16,3.26,3.33,3.39,3.46,3.59,3.65,3.73,3.77,3.87,3.91,3.96,3.99,4.02,4.05,4.07,4.09,4.10,4.10,4.10,3.95,3.95,3.95]}
const EDGE_N := [[0.0,2.15],[2.0,2.15],[4.0,2.15],[6.0,2.15],[8.0,2.15],[10.0,2.15],[12.0,2.151],[14.0,2.153],[16.0,2.158],[18.0,2.163],[20.0,2.171],[22.0,2.18],[24.0,2.191],[26.0,2.203],[28.0,2.217],[30.0,2.232],[32.0,2.249],[34.0,2.267],[36.0,2.287],[38.0,2.307],[40.0,2.329],[42.0,2.352],[44.0,2.377],[46.0,2.402],[48.0,2.429],[50.0,2.456],[52.0,2.484],[54.0,2.513],[56.0,2.544],[58.0,2.574],[60.0,2.606],[62.0,2.638],[64.0,2.672],[66.0,2.705],[68.0,2.739],[70.0,2.774],[72.0,2.81],[74.0,2.845],[76.0,2.881],[78.0,2.918],[80.0,2.954],[82.0,2.991],[84.0,3.028],[86.0,3.066],[88.0,3.103],[90.0,3.141],[92.0,3.178],[94.0,3.216],[96.0,3.253],[98.0,3.29],[100.0,3.327],[102.0,3.364],[104.0,3.401],[106.0,3.437],[108.0,3.473],[110.0,3.508],[112.0,3.543],[114.0,3.578],[116.0,3.612],[118.0,3.645],[120.0,3.678],[122.0,3.71],[124.0,3.741],[126.0,3.772],[128.0,3.801],[130.0,3.83],[132.0,3.858],[134.0,3.885],[136.0,3.911],[138.0,3.936],[140.0,3.959],[142.0,3.982],[144.0,4.003],[146.0,4.023],[148.0,4.042],[150.0,4.06],[152.0,4.075],[154.0,4.09],[156.0,4.103],[158.0,4.115],[160.0,4.125],[162.0,4.133],[164.0,4.14],[166.0,4.145],[168.0,4.148],[170.0,4.15],[172.0,4.15],[174.0,4.15],[176.0,4.15],[178.0,4.15],[180.0,4.15],[182.0,4.15]]
const EDGE_S := [[0.0,2.15],[2.0,2.15],[4.0,2.15],[6.0,2.15],[8.0,1.972],[10.0,1.979],[12.0,1.988],[14.0,1.999],[16.0,2.036],[18.0,2.1],[20.0,2.138],[22.0,2.151],[24.0,2.164],[26.0,2.178],[28.0,2.192],[30.0,2.204],[32.0,2.22],[34.0,2.241],[36.0,2.263],[38.0,2.287],[40.0,2.309],[42.0,2.33],[44.0,2.354],[46.0,2.38],[48.0,2.406],[50.0,2.431],[52.0,2.459],[54.0,2.489],[56.0,2.516],[58.0,2.54],[60.0,2.569],[62.0,2.605],[64.0,2.639],[66.0,2.672],[68.0,2.701],[70.0,2.726],[72.0,2.758],[74.0,2.796],[76.0,2.834],[78.0,2.872],[80.0,2.905],[82.0,2.933],[84.0,2.964],[86.0,2.998],[88.0,3.036],[90.0,3.075],[92.0,3.111],[94.0,3.141],[96.0,3.168],[98.0,3.191],[100.0,3.222],[102.0,3.263],[104.0,3.297],[106.0,3.326],[108.0,3.361],[110.0,3.4],[112.0,3.43],[114.0,3.451],[116.0,3.481],[118.0,3.52],[120.0,3.553],[122.0,3.581],[124.0,3.607],[126.0,3.631],[128.0,3.661],[130.0,3.696],[132.0,3.723],[134.0,3.741],[136.0,3.765],[138.0,3.797],[140.0,3.82],[142.0,3.835],[144.0,3.857],[146.0,3.886],[148.0,3.901],[150.0,3.904],[152.0,3.916],[154.0,3.938],[156.0,3.959],[158.0,3.979],[160.0,3.988],[162.0,3.987],[164.0,3.998],[166.0,4.021],[168.0,4.035],[170.0,4.041],[172.0,4.054],[174.0,4.077],[176.0,4.091],[178.0,4.097],[180.0,4.062],[182.0,3.988]]
const EDGE_W := [[0.0,2.15],[2.0,2.15],[4.0,2.15],[6.0,2.15],[8.0,2.15],[10.0,2.15],[12.0,2.15],[14.0,2.15],[16.0,2.15],[18.0,2.15],[20.0,2.15],[22.0,2.15],[24.0,2.15],[26.0,2.15],[28.0,2.15],[30.0,2.15],[32.0,2.15],[34.0,2.15],[36.0,2.15],[38.0,2.15],[40.0,2.15],[42.0,2.15],[44.0,2.15],[46.0,2.15],[48.0,2.15],[50.0,2.15],[52.0,2.15],[54.0,2.15],[56.0,2.15],[58.0,2.15],[60.0,2.15],[62.0,2.15],[64.0,2.15],[66.0,2.15]]
const EDGE_E := [[0.0,4.15],[2.0,4.15],[4.0,4.15],[6.0,4.15],[8.0,4.15],[10.0,4.15],[12.0,4.15],[14.0,4.15],[16.0,4.15],[18.0,4.15],[20.0,4.15],[22.0,4.15],[24.0,4.15],[26.0,4.15],[28.0,4.15],[30.0,4.15],[32.0,4.15],[34.0,4.15],[36.0,4.15],[38.0,4.15],[40.0,4.15],[42.0,4.15],[44.0,4.15],[46.0,4.15],[48.0,4.15],[50.0,4.15],[52.0,4.15],[54.0,4.15],[56.0,4.15],[58.0,4.15],[60.0,4.15],[62.0,4.15],[64.0,4.15],[66.0,4.15]]

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var c := L.new("n_w_e2", 4.15)
	var W := 182.00; var D := 66.00
	var land := func(x: float, z: float) -> float: return L.land_at(LAND, x, z) + 0.08
	var base := L.edged(land, W, D, EDGE_N, EDGE_S, EDGE_W, EDGE_E, 8.0)
	var SITES := [["houses/beach_white", Vector2(8.67, 3.00), "n", "r0_0"],
		["houses/beach_teal", Vector2(22.00, 3.00), "n", "r0_1"],
		["houses/spanish_small", Vector2(35.33, 3.00), "n", "r0_2"],
		["houses/beach_blue", Vector2(61.40, 3.00), "n", "r1_0"],
		["houses/ranch_peach", Vector2(76.20, 3.00), "n", "r1_1"],
		["houses/spanish_white", Vector2(91.00, 3.00), "n", "r1_2"],
		["houses/beach_large", Vector2(105.80, 3.00), "n", "r1_3"],
		["houses/cape_white", Vector2(120.60, 3.00), "n", "r1_4"],
		["houses/ranch_porch", Vector2(146.67, 3.00), "n", "r2_0"],
		["houses/beach_teal", Vector2(160.00, 3.00), "n", "r2_1"],
		["houses/spanish_pink", Vector2(173.33, 3.00), "n", "r2_2"]]
	var pads: Array = []
	for st: Array in SITES:
		var r0: Array = L.bld_rect(String(st[0]), st[1], String(st[2]))
		pads.append([maxf(0.0, float(r0[0]) - 0.3), maxf(0.0, float(r0[1]) - 0.3), minf(W, float(r0[2]) + 0.3), minf(D, float(r0[3]) + 0.3)])
	var gl := L.grid_lots(0.0, 0.0, W, D, pads, base)
	c.terrain(gl.lots)
	c.skirt_depth = 0.5
	c.paint("asphalt", 0.00, 46.00, 182.00, 52.00)                # the back lane
	c.paint("asphalt", 44.00, 0.00, 52.00, 46.00)                # lane from the north apron
	c.paint("asphalt", 130.00, 0.00, 138.00, 46.00)                # lane from the north apron
	c.paint("concrete", 9.40, 40.40, 14.60, 46.00)                # r0 0: the parking pad off the lane
	c.paint("concrete", 16.07, 40.40, 21.27, 46.00)                # r0 1: the parking pad off the lane
	c.paint("concrete", 36.07, 40.40, 41.27, 46.00)                # r0 2: the parking pad off the lane
	c.paint("concrete", 62.50, 40.40, 67.70, 46.00)                # r1 0: the parking pad off the lane
	c.paint("concrete", 69.90, 40.40, 75.10, 46.00)                # r1 1: the parking pad off the lane
	c.paint("concrete", 92.10, 40.40, 97.30, 46.00)                # r1 2: the parking pad off the lane
	c.paint("concrete", 99.50, 40.40, 104.70, 46.00)                # r1 3: the parking pad off the lane
	c.paint("concrete", 121.70, 40.40, 126.90, 46.00)                # r1 4: the parking pad off the lane
	c.paint("concrete", 147.40, 40.40, 152.60, 46.00)                # r2 0: the parking pad off the lane
	c.paint("concrete", 154.07, 40.40, 159.27, 46.00)                # r2 1: the parking pad off the lane
	c.paint("concrete", 174.07, 40.40, 179.27, 46.00)                # r2 2: the parking pad off the lane
	c.paint("grass", 0.0, 0.0, W, D)
	c.build_floor(L.rect_edges(0.0, 0.0, W, D))
	if c.stage == "ground": c.finish(); quit(); return
	var B := {}
	for k in SITES.size():
		c.y0 = float(gl.pads[k][4])
		B[String(SITES[k][3])] = c.bld(String(SITES[k][0]), SITES[k][1], String(SITES[k][2]), false, String(SITES[k][3]), 0.70)

	c.privacy(Vector2(5.62, 9.05), Vector2(2.30, 9.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(11.72, 9.05), Vector2(15.03, 9.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(2.30, 9.05), Vector2(2.30, 40.00), "yard: the lot-line fence")
	c.privacy(Vector2(15.03, 9.05), Vector2(15.03, 40.00), "yard: the lot-line fence")
	c.privacy(Vector2(2.30, 40.00), Vector2(11.40, 40.00), "yard: the rear fence")
	c.privacy(Vector2(12.60, 40.00), Vector2(15.03, 40.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(12.00, c.yf(12.00, 40.00), 40.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([12.00, 43.00, 0.0, c.yf(12.00, 43.00)])
	c.oil(Vector2(12.00, 43.00), 0.0)
	c.put("prop_adirondack_white", "worn", c.gp(5.73, 26.55), 222.0, "back yard: a chair on the lawn")
	c.put("prop_adirondack_wood", "worn", c.gp(11.60, 28.55), 312.0, "back yard: a chair on the lawn facing the sun")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(13.92, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(18.45, 8.55), Vector2(15.63, 8.55), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(25.55, 8.55), Vector2(28.37, 8.55), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(15.63, 8.55), Vector2(15.63, 40.00), "yard: the lot-line fence")
	c.privacy(Vector2(28.37, 8.55), Vector2(28.37, 40.00), "yard: the lot-line fence")
	c.privacy(Vector2(15.63, 40.00), Vector2(18.07, 40.00), "yard: the rear fence")
	c.privacy(Vector2(19.27, 40.00), Vector2(28.37, 40.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(18.67, c.yf(18.67, 40.00), 40.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([18.67, 43.00, 0.0, c.yf(18.67, 43.00)])
	c.oil(Vector2(18.67, 43.00), 0.0)
	c.put("prop_patio_set_4", "worn", c.gp(19.07, 26.05), 283.0, "back yard: the patio table")
	c.put("prop_adirondack_white", "worn", c.gp(24.93, 28.05), 13.0, "back yard: a chair on the lawn")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(27.75, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(32.18, 8.05), Vector2(28.97, 8.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(38.48, 8.05), Vector2(41.70, 8.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(28.97, 8.05), Vector2(28.97, 40.00), "yard: the lot-line fence")
	c.privacy(Vector2(41.70, 8.05), Vector2(41.70, 40.00), "yard: the lot-line fence")
	c.privacy(Vector2(28.97, 40.00), Vector2(38.07, 40.00), "yard: the rear fence")
	c.privacy(Vector2(39.27, 40.00), Vector2(41.70, 40.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(38.67, c.yf(38.67, 40.00), 40.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([38.67, 43.00, 0.0, c.yf(38.67, 43.00)])
	c.oil(Vector2(38.67, 43.00), 0.0)
	c.put("prop_swing_set", "worn", c.gp(32.40, 25.55), 344.0, "back yard: the kids' swings")
	c.put("prop_patio_set_4", "worn", c.gp(38.27, 27.55), 74.0, "back yard: the patio table")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(40.68, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(58.10, 9.05), Vector2(54.30, 9.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(64.70, 9.05), Vector2(68.50, 9.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(54.30, 9.05), Vector2(54.30, 40.00), "yard: the lot-line fence")
	c.privacy(Vector2(68.50, 9.05), Vector2(68.50, 40.00), "yard: the lot-line fence")
	c.privacy(Vector2(54.30, 40.00), Vector2(64.50, 40.00), "yard: the rear fence")
	c.privacy(Vector2(65.70, 40.00), Vector2(68.50, 40.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(65.10, c.yf(65.10, 40.00), 40.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([65.10, 43.00, 0.0, c.yf(65.10, 43.00)])
	c.oil(Vector2(65.10, 43.00), 0.0)
	c.put("prop_patio_set_4", "worn", c.gp(58.14, 26.55), 333.0, "back yard: the patio table")
	c.put("prop_adirondack_white", "worn", c.gp(64.66, 28.55), 63.0, "back yard: a chair on the lawn")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(66.90, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(71.40, 8.50), Vector2(69.10, 8.50), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(81.00, 8.50), Vector2(83.30, 8.50), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(69.10, 8.50), Vector2(69.10, 40.00), "yard: the lot-line fence")
	c.privacy(Vector2(83.30, 8.50), Vector2(83.30, 40.00), "yard: the lot-line fence")
	c.privacy(Vector2(69.10, 40.00), Vector2(71.90, 40.00), "yard: the rear fence")
	c.privacy(Vector2(73.10, 40.00), Vector2(83.30, 40.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(72.50, c.yf(72.50, 40.00), 40.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([72.50, 43.00, 0.0, c.yf(72.50, 43.00)])
	c.oil(Vector2(72.50, 43.00), 0.0)
	c.put("prop_swing_set", "worn", c.gp(72.94, 26.00), 34.0, "back yard: the kids' swings")
	c.put("prop_patio_set_4", "worn", c.gp(79.46, 28.00), 124.0, "back yard: the patio table")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(83.20, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(86.10, 8.95), Vector2(83.90, 8.95), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(95.90, 8.95), Vector2(98.10, 8.95), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(83.90, 8.95), Vector2(83.90, 40.00), "yard: the lot-line fence")
	c.privacy(Vector2(98.10, 8.95), Vector2(98.10, 40.00), "yard: the lot-line fence")
	c.privacy(Vector2(83.90, 40.00), Vector2(94.10, 40.00), "yard: the rear fence")
	c.privacy(Vector2(95.30, 40.00), Vector2(98.10, 40.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(94.70, c.yf(94.70, 40.00), 40.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([94.70, 43.00, 0.0, c.yf(94.70, 43.00)])
	c.oil(Vector2(94.70, 43.00), 0.0)
	c.put("prop_picnic_table", "worn", c.gp(87.74, 26.45), 95.0, "back yard: a table in the yard")
	c.put("prop_swing_set", "worn", c.gp(94.26, 28.45), 185.0, "back yard: the kids' swings")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(98.50, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(101.05, 11.60), Vector2(98.70, 11.60), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(110.55, 11.60), Vector2(112.90, 11.60), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(98.70, 11.60), Vector2(98.70, 40.00), "yard: the lot-line fence")
	c.privacy(Vector2(112.90, 11.60), Vector2(112.90, 40.00), "yard: the lot-line fence")
	c.privacy(Vector2(98.70, 40.00), Vector2(101.50, 40.00), "yard: the rear fence")
	c.privacy(Vector2(102.70, 40.00), Vector2(112.90, 40.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(102.10, c.yf(102.10, 40.00), 40.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([102.10, 43.00, 0.0, c.yf(102.10, 43.00)])
	c.oil(Vector2(102.10, 43.00), 0.0)
	c.put("prop_clothesline", "worn", c.gp(102.54, 29.10), 156.0, "back yard: washing on the line")
	c.put("prop_picnic_table", "worn", c.gp(109.06, 31.10), 246.0, "back yard: a table in the yard")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(112.75, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(116.40, 7.85), Vector2(113.50, 7.85), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(124.80, 7.85), Vector2(127.70, 7.85), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(113.50, 7.85), Vector2(113.50, 40.00), "yard: the lot-line fence")
	c.privacy(Vector2(127.70, 7.85), Vector2(127.70, 40.00), "yard: the lot-line fence")
	c.privacy(Vector2(113.50, 40.00), Vector2(123.70, 40.00), "yard: the rear fence")
	c.privacy(Vector2(124.90, 40.00), Vector2(127.70, 40.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(124.30, c.yf(124.30, 40.00), 40.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([124.30, 43.00, 0.0, c.yf(124.30, 43.00)])
	c.oil(Vector2(124.30, 43.00), 0.0)
	c.put("prop_bbq_gas_cart", "worn", c.gp(117.34, 25.35), 217.0, "back yard: the gas grill")
	c.put("prop_clothesline", "worn", c.gp(123.86, 27.35), 307.0, "back yard: washing on the line")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(127.00, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(142.50, 8.50), Vector2(140.30, 8.50), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(150.83, 8.50), Vector2(153.03, 8.50), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(140.30, 8.50), Vector2(140.30, 40.00), "yard: the lot-line fence")
	c.privacy(Vector2(153.03, 8.50), Vector2(153.03, 40.00), "yard: the lot-line fence")
	c.privacy(Vector2(140.30, 40.00), Vector2(149.40, 40.00), "yard: the rear fence")
	c.privacy(Vector2(150.60, 40.00), Vector2(153.03, 40.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(150.00, c.yf(150.00, 40.00), 40.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([150.00, 43.00, 0.0, c.yf(150.00, 43.00)])
	c.oil(Vector2(150.00, 43.00), 0.0)
	c.put("prop_swing_set", "worn", c.gp(143.73, 26.00), 84.0, "back yard: the kids' swings")
	c.put("prop_patio_set_4", "worn", c.gp(149.60, 28.00), 174.0, "back yard: the patio table")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(153.17, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(156.45, 8.55), Vector2(153.63, 8.55), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(163.55, 8.55), Vector2(166.37, 8.55), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(153.63, 8.55), Vector2(153.63, 40.00), "yard: the lot-line fence")
	c.privacy(Vector2(166.37, 8.55), Vector2(166.37, 40.00), "yard: the lot-line fence")
	c.privacy(Vector2(153.63, 40.00), Vector2(156.07, 40.00), "yard: the rear fence")
	c.privacy(Vector2(157.27, 40.00), Vector2(166.37, 40.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(156.67, c.yf(156.67, 40.00), 40.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([156.67, 43.00, 0.0, c.yf(156.67, 43.00)])
	c.oil(Vector2(156.67, 43.00), 0.0)
	c.put("prop_picnic_table", "worn", c.gp(157.07, 26.05), 145.0, "back yard: a table in the yard")
	c.put("prop_swing_set", "worn", c.gp(162.93, 28.05), 235.0, "back yard: the kids' swings")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(165.75, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(169.17, 8.90), Vector2(166.97, 8.90), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(177.50, 8.90), Vector2(179.70, 8.90), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(166.97, 8.90), Vector2(166.97, 40.00), "yard: the lot-line fence")
	c.privacy(Vector2(179.70, 8.90), Vector2(179.70, 40.00), "yard: the lot-line fence")
	c.privacy(Vector2(166.97, 40.00), Vector2(176.07, 40.00), "yard: the rear fence")
	c.privacy(Vector2(177.27, 40.00), Vector2(179.70, 40.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(176.67, c.yf(176.67, 40.00), 40.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([176.67, 43.00, 0.0, c.yf(176.67, 43.00)])
	c.oil(Vector2(176.67, 43.00), 0.0)
	c.put("prop_clothesline", "worn", c.gp(170.40, 26.40), 206.0, "back yard: washing on the line")
	c.put("prop_picnic_table", "worn", c.gp(176.27, 28.40), 296.0, "back yard: a table in the yard")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(181.08, 2.40), 0.0, "front: a pot by the walk")
	c.alley_wear(0.0, 46.0, 182.0, 52.0, false)
	c.tyre(Vector2(48.0, 3.0), 0.0, 6.0, 0.45)
	c.tyre(Vector2(134.0, 3.0), 0.0, 6.0, 0.45)
	for k2: String in B:
		var r: Dictionary = B[k2]
		if not String(r.folder).begins_with("houses/"): c.services(r, 2.0, 1 if not String(r.folder).begins_with("apartments/") else 2, String(r.folder).begins_with("apartments/"))
		for dr: Array in r.doors:
			var q: Vector3 = dr[1]; var o: Vector3 = dr[2]
			c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.6, 1.4, 0.40)
	c.finish()
	quit()
