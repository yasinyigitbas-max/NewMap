extends SceneTree
## Piece n_w_e3 (WEST FILL, the south-west edge): u -591..-409, v 209..288, 182 x 79 m; land 2.0..4.2 toward the shore.
## SITE: a street north (aprons x 44..51.5, 130..137.5), the ring road south.
## PLANNER: beach-side houses facing the north street, a back lane, the sound wall to the ring road.
## Layout row (-591.0, 0, 209.0): local x = u - (-591.0), z = v - (209.0), heights absolute. Built by the west fill (University
## session, 20 Nov; review/fill_west/PLAN.md). Ground: the land 8 cm over it, eased over 8 m to the measured height of
## whatever borders each side; buildings on level pads at the highest ground under them (plinth faces downhill).
const L := preload("res://tools/city/pilot/pieces/w_fill_lib.gd")
## site u -591.0..-409.0 v 209.0..288.0 (182.0 x 79.0 m); neighbours N {np.str_('j_rs_4r_c'): 6, np.str_('s_rs_b126_a'): 40, np.str_('s_rs_b126_b'): 40, np.str_('j_rs_4r_d'): 6} S {np.str_('j_rg_se_w600_s302'): 2, '-': 90} W {np.str_('j_rs_4r_c'): 6, np.str_('s_rg_se_b017'): 28, np.str_('j_rg_se_w600_s302'): 6} E {np.str_('j_rs_4r_d'): 6, np.str_('s_rg_se_b027'): 34}
const LAND := {"x0": -9.0, "z0": -9.0, "step": 4.0, "nx": 51, "nz": 25, "h": [3.95,3.95,3.95,3.95,3.95,3.95,3.94,3.93,3.91,3.89,3.86,3.82,3.78,3.74,3.69,3.63,3.57,3.51,3.45,3.38,3.31,3.24,3.16,3.09,3.02,2.94,2.87,2.79,2.72,2.65,2.57,2.51,2.44,2.37,2.31,2.26,2.20,2.15,2.11,2.07,2.03,2.00,1.98,1.96,1.95,1.95,1.95,1.95,1.95,1.95,1.95,3.95,3.95,3.95,3.95,3.95,3.95,3.94,3.93,3.91,3.88,3.85,3.82,3.77,3.72,3.67,3.62,3.56,3.50,3.43,3.36,3.29,3.22,3.15,3.08,3.00,2.93,2.85,2.78,2.70,2.63,2.56,2.49,2.43,2.36,2.30,2.24,2.19,2.14,2.10,2.06,2.03,2.00,1.98,1.96,1.95,1.95,1.95,1.95,1.95,1.95,1.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.93,3.91,3.88,3.85,3.81,3.77,3.71,3.65,3.61,3.55,3.49,3.42,3.35,3.28,3.21,3.14,3.06,2.99,2.91,2.84,2.76,2.69,2.62,2.55,2.48,2.41,2.35,2.29,2.22,2.18,2.13,2.09,2.05,2.02,1.99,1.97,1.96,1.95,1.95,1.95,1.95,1.95,1.95,3.95,3.95,3.95,4.10,4.10,4.10,4.10,4.09,4.07,4.04,4.01,3.98,3.94,3.89,3.84,3.79,3.73,3.67,3.60,3.54,3.47,3.40,3.32,3.25,3.17,3.10,3.03,2.95,2.88,2.80,2.73,2.66,2.60,2.53,2.47,2.41,2.36,2.31,2.26,2.22,2.19,2.16,2.13,2.11,2.10,2.10,2.10,2.10,1.95,1.95,1.95,3.95,3.95,3.95,4.10,4.10,4.08,4.08,4.05,4.04,3.98,3.96,3.94,3.88,3.85,3.79,3.75,3.68,3.63,3.53,3.48,3.42,3.34,3.28,3.20,3.14,3.06,3.00,2.91,2.83,2.78,2.69,2.63,2.56,2.52,2.44,2.40,2.34,2.30,2.25,2.19,2.17,2.13,2.13,2.10,2.11,2.09,2.10,2.10,1.95,1.95,1.95,3.95,3.95,3.95,4.10,4.10,4.04,4.04,4.00,3.99,3.97,3.92,3.90,3.84,3.81,3.72,3.68,3.61,3.56,3.52,3.44,3.38,3.30,3.25,3.16,3.08,3.00,2.94,2.89,2.80,2.75,2.67,2.62,2.54,2.47,2.40,2.36,2.30,2.27,2.24,2.19,2.17,2.13,2.13,2.07,2.08,2.06,2.08,2.10,1.95,1.95,1.95,3.95,3.95,3.95,4.10,4.08,4.04,4.02,3.98,3.96,3.94,3.87,3.84,3.78,3.75,3.68,3.64,3.57,3.53,3.48,3.38,3.33,3.24,3.19,3.11,3.05,2.97,2.92,2.86,2.78,2.70,2.62,2.58,2.50,2.46,2.39,2.35,2.32,2.26,2.23,2.16,2.14,2.10,2.10,2.07,2.08,2.10,2.08,2.10,1.95,1.95,1.95,3.95,3.95,3.95,4.10,4.08,4.03,3.99,3.97,3.92,3.90,3.84,3.81,3.75,3.72,3.65,3.59,3.55,3.47,3.43,3.35,3.30,3.22,3.16,3.08,3.03,2.95,2.87,2.82,2.73,2.68,2.60,2.56,2.48,2.44,2.38,2.32,2.29,2.23,2.21,2.16,2.14,2.11,2.10,2.11,2.06,2.08,2.07,2.10,1.95,1.95,1.95,3.95,3.95,3.95,4.10,4.06,4.04,3.98,3.96,3.90,3.88,3.82,3.77,3.70,3.67,3.63,3.56,3.52,3.45,3.40,3.32,3.27,3.17,3.12,3.07,2.98,2.93,2.85,2.80,2.72,2.67,2.57,2.52,2.48,2.41,2.37,2.31,2.28,2.22,2.20,2.16,2.12,2.12,2.08,2.09,2.07,2.08,2.07,2.10,1.95,1.95,1.95,3.95,3.95,3.95,4.10,4.05,4.03,3.97,3.93,3.87,3.84,3.78,3.75,3.72,3.65,3.61,3.54,3.48,3.40,3.36,3.28,3.23,3.18,3.10,3.05,2.97,2.92,2.81,2.76,2.68,2.63,2.59,2.51,2.47,2.40,2.37,2.28,2.25,2.20,2.18,2.17,2.12,2.12,2.09,2.10,2.08,2.07,2.06,2.10,1.95,1.95,1.95,3.95,3.95,3.95,4.10,4.04,4.01,3.95,3.92,3.86,3.83,3.80,3.74,3.68,3.61,3.58,3.50,3.46,3.39,3.34,3.30,3.22,3.17,3.06,3.01,2.93,2.88,2.80,2.75,2.70,2.62,2.58,2.48,2.44,2.38,2.34,2.28,2.25,2.23,2.18,2.17,2.13,2.10,2.07,2.08,2.06,2.08,2.11,2.10,1.95,1.95,1.95,3.95,3.95,3.95,4.10,4.04,4.01,3.95,3.92,3.86,3.80,3.77,3.71,3.67,3.60,3.57,3.50,3.46,3.39,3.31,3.27,3.19,3.14,3.06,3.01,2.92,2.87,2.83,2.72,2.67,2.60,2.55,2.48,2.44,2.38,2.34,2.32,2.23,2.21,2.17,2.16,2.12,2.11,2.09,2.10,2.11,2.10,2.10,2.10,1.95,1.95,1.95,3.95,3.95,3.95,4.10,4.02,3.99,3.96,3.89,3.86,3.80,3.77,3.70,3.67,3.58,3.54,3.50,3.43,3.39,3.31,3.26,3.18,3.14,3.05,2.98,2.93,2.85,2.80,2.72,2.67,2.60,2.56,2.48,2.42,2.39,2.32,2.30,2.24,2.22,2.18,2.17,2.13,2.13,2.11,2.09,2.11,2.09,2.11,2.10,1.95,1.95,1.95,3.95,3.95,3.95,4.10,4.06,3.99,3.96,3.90,3.87,3.78,3.75,3.68,3.65,3.62,3.55,3.51,3.43,3.39,3.29,3.25,3.17,3.12,3.07,2.99,2.94,2.85,2.81,2.73,2.66,2.58,2.54,2.50,2.43,2.40,2.33,2.31,2.25,2.24,2.17,2.16,2.15,2.12,2.13,2.11,2.12,2.10,2.12,2.10,1.95,1.95,1.95,3.95,3.95,3.95,4.10,4.07,3.98,3.95,3.88,3.85,3.79,3.76,3.73,3.66,3.63,3.53,3.50,3.42,3.38,3.30,3.26,3.21,3.13,3.08,3.00,2.92,2.84,2.79,2.71,2.67,2.62,2.55,2.51,2.44,2.38,2.32,2.30,2.24,2.23,2.22,2.18,2.18,2.15,2.15,2.10,2.11,2.09,2.10,2.10,1.95,1.95,1.95,3.95,3.95,3.95,4.10,4.06,3.99,3.96,3.89,3.87,3.84,3.75,3.72,3.66,3.62,3.55,3.52,3.44,3.40,3.36,3.25,3.21,3.12,3.07,2.99,2.94,2.86,2.81,2.76,2.68,2.61,2.54,2.50,2.43,2.40,2.34,2.32,2.30,2.25,2.24,2.18,2.18,2.15,2.15,2.12,2.13,2.13,2.10,2.10,1.95,1.95,1.95,3.95,3.95,3.95,4.10,4.07,4.00,3.95,3.92,3.86,3.83,3.77,3.74,3.68,3.65,3.58,3.52,3.48,3.41,3.36,3.28,3.23,3.15,3.10,3.01,2.96,2.89,2.81,2.76,2.68,2.64,2.56,2.52,2.45,2.42,2.37,2.32,2.30,2.25,2.24,2.20,2.20,2.17,2.17,2.17,2.12,2.12,2.09,2.10,1.95,1.95,1.95,3.95,3.95,3.95,4.10,4.06,4.03,3.97,3.94,3.88,3.86,3.80,3.75,3.69,3.66,3.62,3.56,3.52,3.44,3.40,3.32,3.25,3.16,3.11,3.06,2.97,2.92,2.83,2.79,2.71,2.66,2.56,2.52,2.49,2.43,2.40,2.34,2.33,2.28,2.27,2.23,2.20,2.20,2.16,2.16,2.13,2.13,2.10,2.10,1.95,1.95,1.95,3.95,3.95,3.95,4.10,4.06,4.04,3.99,3.95,3.89,3.87,3.82,3.79,3.76,3.70,3.67,3.60,3.54,3.46,3.42,3.34,3.29,3.24,3.15,3.09,3.01,2.95,2.84,2.80,2.71,2.67,2.63,2.56,2.52,2.46,2.43,2.35,2.33,2.28,2.27,2.26,2.22,2.21,2.18,2.18,2.14,2.12,2.09,2.10,1.95,1.95,1.95,3.95,3.95,3.95,4.10,4.05,4.04,3.99,3.98,3.93,3.91,3.90,3.84,3.79,3.73,3.70,3.63,3.60,3.52,3.48,3.43,3.35,3.29,3.17,3.12,3.03,2.97,2.89,2.84,2.79,2.71,2.67,2.57,2.54,2.47,2.44,2.39,2.36,2.34,2.29,2.28,2.24,2.20,2.17,2.16,2.13,2.13,2.13,2.10,1.95,1.95,1.95,3.95,3.95,3.95,4.10,4.08,4.07,4.03,4.02,3.99,3.94,3.93,3.88,3.85,3.79,3.76,3.70,3.66,3.60,3.52,3.48,3.39,3.33,3.23,3.17,3.08,3.02,2.97,2.86,2.81,2.73,2.69,2.61,2.58,2.51,2.48,2.45,2.37,2.34,2.29,2.27,2.22,2.22,2.18,2.17,2.17,2.14,2.12,2.10,1.95,1.95,1.95,3.95,3.95,3.95,4.10,4.10,4.10,4.08,4.04,4.04,4.01,4.00,3.95,3.93,3.84,3.81,3.78,3.72,3.67,3.61,3.56,3.48,3.40,3.29,3.20,3.14,3.05,3.00,2.91,2.86,2.78,2.73,2.66,2.59,2.56,2.49,2.45,2.39,2.36,2.30,2.28,2.24,2.22,2.19,2.15,2.15,2.12,2.13,2.10,1.95,1.95,1.95,3.95,3.95,3.95,3.95,4.10,4.10,4.10,4.10,4.09,4.07,4.05,4.02,3.99,3.95,3.90,3.86,3.83,3.74,3.70,3.61,3.61,3.45,3.36,3.26,3.21,3.12,3.06,2.98,2.90,2.81,2.76,2.67,2.63,2.60,2.52,2.48,2.41,2.35,2.29,2.27,2.22,2.20,2.20,2.16,2.16,2.13,2.14,2.10,1.95,1.95,1.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.94,3.93,3.92,3.89,3.86,3.86,3.87,3.81,3.78,3.74,3.70,3.62,3.55,3.47,3.40,3.33,3.25,3.18,3.10,3.02,2.95,2.87,2.80,2.73,2.67,2.62,2.53,2.48,2.40,2.36,2.29,2.27,2.25,2.21,2.19,2.13,2.13,2.10,2.11,2.10,1.95,1.95,1.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.95,3.94,3.92,3.89,3.86,3.82,3.78,3.74,3.69,3.64,3.59,3.53,3.46,3.40,3.33,3.26,3.18,3.13,3.08,3.00,2.92,2.88,2.86,2.78,2.71,2.67,2.62,2.53,2.48,2.41,2.35,2.31,2.26,2.22,2.19,2.16,2.13,2.11,2.10,2.10,2.10,1.95,1.95,1.95]}
const EDGE_N := [[0.0,4.15],[2.0,4.15],[4.0,4.15],[6.0,4.15],[8.0,4.15],[10.0,4.15],[12.0,4.149],[14.0,4.147],[16.0,4.142],[18.0,4.137],[20.0,4.129],[22.0,4.12],[24.0,4.109],[26.0,4.097],[28.0,4.083],[30.0,4.068],[32.0,4.051],[34.0,4.033],[36.0,4.013],[38.0,3.993],[40.0,3.971],[42.0,3.948],[44.0,3.923],[46.0,3.898],[48.0,3.871],[50.0,3.844],[52.0,3.816],[54.0,3.787],[56.0,3.756],[58.0,3.726],[60.0,3.694],[62.0,3.662],[64.0,3.628],[66.0,3.595],[68.0,3.561],[70.0,3.526],[72.0,3.49],[74.0,3.455],[76.0,3.419],[78.0,3.382],[80.0,3.346],[82.0,3.309],[84.0,3.272],[86.0,3.234],[88.0,3.197],[90.0,3.159],[92.0,3.122],[94.0,3.084],[96.0,3.047],[98.0,3.01],[100.0,2.973],[102.0,2.936],[104.0,2.899],[106.0,2.863],[108.0,2.827],[110.0,2.792],[112.0,2.757],[114.0,2.722],[116.0,2.688],[118.0,2.655],[120.0,2.622],[122.0,2.59],[124.0,2.559],[126.0,2.528],[128.0,2.499],[130.0,2.47],[132.0,2.442],[134.0,2.415],[136.0,2.389],[138.0,2.364],[140.0,2.341],[142.0,2.318],[144.0,2.297],[146.0,2.277],[148.0,2.258],[150.0,2.24],[152.0,2.225],[154.0,2.21],[156.0,2.197],[158.0,2.185],[160.0,2.175],[162.0,2.167],[164.0,2.16],[166.0,2.155],[168.0,2.152],[170.0,2.15],[172.0,2.15],[174.0,2.15],[176.0,2.15],[178.0,2.15],[180.0,2.15],[182.0,2.15]]
const EDGE_S := [[0.0,4.15],[2.0,4.15],[4.0,3.983],[6.0,4.048],[8.0,4.081],[10.0,4.081],[12.0,4.081],[14.0,4.081],[16.0,4.081],[18.0,4.08],[20.0,4.077],[22.0,4.072],[24.0,4.066],[26.0,4.059],[28.0,4.049],[30.0,4.038],[32.0,4.026],[34.0,4.012],[36.0,3.996],[38.0,3.978],[40.0,3.961],[42.0,3.944],[44.0,3.927],[46.0,3.909],[48.0,3.889],[50.0,3.867],[52.0,3.849],[54.0,3.835],[56.0,3.806],[58.0,3.763],[60.0,3.731],[62.0,3.708],[64.0,3.674],[66.0,3.63],[68.0,3.606],[70.0,3.601],[72.0,3.563],[74.0,3.49],[76.0,3.431],[78.0,3.387],[80.0,3.341],[82.0,3.294],[84.0,3.255],[86.0,3.226],[88.0,3.19],[90.0,3.148],[92.0,3.111],[94.0,3.081],[96.0,3.045],[98.0,3.003],[100.0,2.962],[102.0,2.922],[104.0,2.882],[106.0,2.841],[108.0,2.806],[110.0,2.777],[112.0,2.741],[114.0,2.699],[116.0,2.667],[118.0,2.646],[120.0,2.627],[122.0,2.608],[124.0,2.579],[126.0,2.54],[128.0,2.511],[130.0,2.49],[132.0,2.462],[134.0,2.425],[136.0,2.393],[138.0,2.364],[140.0,2.334],[142.0,2.303],[144.0,2.282],[146.0,2.273],[148.0,2.256],[150.0,2.233],[152.0,2.217],[154.0,2.209],[156.0,2.203],[158.0,2.198],[160.0,2.185],[162.0,2.164],[164.0,2.154],[166.0,2.154],[168.0,2.147],[170.0,2.133],[172.0,2.128],[174.0,2.133],[176.0,2.127],[178.0,2.109],[180.0,2.063],[182.0,1.988]]
const EDGE_W := [[0.0,4.15],[2.0,4.15],[4.0,4.15],[6.0,4.15],[8.0,4.15],[10.0,4.15],[12.0,4.15],[14.0,4.15],[16.0,4.15],[18.0,4.15],[20.0,4.15],[22.0,4.15],[24.0,4.15],[26.0,4.15],[28.0,4.15],[30.0,4.15],[32.0,4.15],[34.0,4.15],[36.0,4.15],[38.0,4.15],[40.0,4.15],[42.0,4.15],[44.0,4.15],[46.0,4.15],[48.0,4.15],[50.0,4.15],[52.0,4.15],[54.0,4.15],[56.0,4.15],[58.0,4.15],[60.0,4.15],[62.0,4.15],[64.0,4.15],[66.0,4.15],[68.0,4.15],[70.0,4.15],[72.0,4.15],[74.0,4.15],[76.0,4.15],[78.0,4.15]]
const EDGE_E := [[0.0,2.15],[2.0,2.15],[4.0,2.15],[6.0,2.15],[8.0,2.15],[10.0,2.15],[12.0,2.15],[14.0,2.15],[16.0,2.15],[18.0,2.15],[20.0,2.15],[22.0,2.15],[24.0,2.15],[26.0,2.15],[28.0,2.15],[30.0,2.15],[32.0,2.15],[34.0,2.15],[36.0,2.15],[38.0,2.15],[40.0,2.15],[42.0,2.15],[44.0,2.15],[46.0,2.15],[48.0,2.15],[50.0,2.15],[52.0,2.15],[54.0,2.15],[56.0,2.15],[58.0,2.15],[60.0,2.15],[62.0,2.15],[64.0,2.15],[66.0,2.15],[68.0,2.15],[70.0,2.15],[72.0,2.15],[74.0,2.15],[76.0,2.15],[78.0,2.15]]

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var c := L.new("n_w_e3", 4.15)
	var W := 182.00; var D := 79.00
	var land := func(x: float, z: float) -> float: return L.land_at(LAND, x, z) + 0.08
	var base := L.edged(land, W, D, EDGE_N, EDGE_S, EDGE_W, EDGE_E, 8.0)
	var SITES := [["houses/spanish_peach", Vector2(8.67, 3.00), "n", "r0_0"],
		["houses/beach_blue", Vector2(22.00, 3.00), "n", "r0_1"],
		["houses/ranch_pink", Vector2(35.33, 3.00), "n", "r0_2"],
		["houses/craftsman_stucco", Vector2(61.40, 3.00), "n", "r1_0"],
		["houses/beach_white", Vector2(76.20, 3.00), "n", "r1_1"],
		["houses/mcm_teal", Vector2(91.00, 3.00), "n", "r1_2"],
		["houses/spanish_small", Vector2(105.80, 3.00), "n", "r1_3"],
		["houses/ranch_siding", Vector2(120.60, 3.00), "n", "r1_4"],
		["houses/beach_large", Vector2(146.67, 3.00), "n", "r2_0"],
		["houses/spanish_white", Vector2(160.00, 3.00), "n", "r2_1"],
		["houses/cape_grey", Vector2(173.33, 3.00), "n", "r2_2"]]
	var pads: Array = []
	for st: Array in SITES:
		var r0: Array = L.bld_rect(String(st[0]), st[1], String(st[2]))
		pads.append([maxf(0.0, float(r0[0]) - 0.3), maxf(0.0, float(r0[1]) - 0.3), minf(W, float(r0[2]) + 0.3), minf(D, float(r0[3]) + 0.3)])
	var gl := L.grid_lots(0.0, 0.0, W, D, pads, base)
	c.terrain(gl.lots)
	c.skirt_depth = 0.5
	c.paint("asphalt", 0.00, 56.00, 182.00, 62.00)                # the back lane
	c.paint("asphalt", 44.00, 0.00, 52.00, 56.00)                # lane from the north apron
	c.paint("asphalt", 130.00, 0.00, 138.00, 56.00)                # lane from the north apron
	c.paint("concrete", 9.40, 50.40, 14.60, 56.00)                # r0 0: the parking pad off the lane
	c.paint("concrete", 16.07, 50.40, 21.27, 56.00)                # r0 1: the parking pad off the lane
	c.paint("concrete", 36.07, 50.40, 41.27, 56.00)                # r0 2: the parking pad off the lane
	c.paint("concrete", 62.50, 50.40, 67.70, 56.00)                # r1 0: the parking pad off the lane
	c.paint("concrete", 69.90, 50.40, 75.10, 56.00)                # r1 1: the parking pad off the lane
	c.paint("concrete", 92.10, 50.40, 97.30, 56.00)                # r1 2: the parking pad off the lane
	c.paint("concrete", 99.50, 50.40, 104.70, 56.00)                # r1 3: the parking pad off the lane
	c.paint("concrete", 121.70, 50.40, 126.90, 56.00)                # r1 4: the parking pad off the lane
	c.paint("concrete", 147.40, 50.40, 152.60, 56.00)                # r2 0: the parking pad off the lane
	c.paint("concrete", 154.07, 50.40, 159.27, 56.00)                # r2 1: the parking pad off the lane
	c.paint("concrete", 174.07, 50.40, 179.27, 56.00)                # r2 2: the parking pad off the lane
	c.paint("grass", 0.0, 0.0, W, D)
	c.build_floor(L.rect_edges(0.0, 0.0, W, D))
	if c.stage == "ground": c.finish(); quit(); return
	var B := {}
	for k in SITES.size():
		c.y0 = float(gl.pads[k][4])
		B[String(SITES[k][3])] = c.bld(String(SITES[k][0]), SITES[k][1], String(SITES[k][2]), false, String(SITES[k][3]), 0.70)

	c.privacy(Vector2(4.50, 8.95), Vector2(2.30, 8.95), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(12.83, 8.95), Vector2(15.03, 8.95), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(2.30, 8.95), Vector2(2.30, 50.00), "yard: the lot-line fence")
	c.privacy(Vector2(15.03, 8.95), Vector2(15.03, 50.00), "yard: the lot-line fence")
	c.privacy(Vector2(2.30, 50.00), Vector2(11.40, 50.00), "yard: the rear fence")
	c.privacy(Vector2(12.60, 50.00), Vector2(15.03, 50.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(12.00, c.yf(12.00, 50.00), 50.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([12.00, 53.00, 0.0, c.yf(12.00, 53.00)])
	c.oil(Vector2(12.00, 53.00), 0.0)
	c.put("prop_adirondack_white", "worn", c.gp(5.73, 31.45), 222.0, "back yard: a chair on the lawn")
	c.put("prop_adirondack_wood", "worn", c.gp(11.60, 33.45), 312.0, "back yard: a chair on the lawn facing the sun")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(16.17, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(18.70, 9.05), Vector2(15.63, 9.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(25.30, 9.05), Vector2(28.37, 9.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(15.63, 9.05), Vector2(15.63, 50.00), "yard: the lot-line fence")
	c.privacy(Vector2(28.37, 9.05), Vector2(28.37, 50.00), "yard: the lot-line fence")
	c.privacy(Vector2(15.63, 50.00), Vector2(18.07, 50.00), "yard: the rear fence")
	c.privacy(Vector2(19.27, 50.00), Vector2(28.37, 50.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(18.67, c.yf(18.67, 50.00), 50.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([18.67, 53.00, 0.0, c.yf(18.67, 53.00)])
	c.oil(Vector2(18.67, 53.00), 0.0)
	c.put("prop_patio_set_4", "worn", c.gp(19.07, 31.55), 283.0, "back yard: the patio table")
	c.put("prop_adirondack_white", "worn", c.gp(24.93, 33.55), 13.0, "back yard: a chair on the lawn")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(27.50, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(31.28, 8.50), Vector2(28.97, 8.50), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(39.38, 8.50), Vector2(41.70, 8.50), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(28.97, 8.50), Vector2(28.97, 50.00), "yard: the lot-line fence")
	c.privacy(Vector2(41.70, 8.50), Vector2(41.70, 50.00), "yard: the lot-line fence")
	c.privacy(Vector2(28.97, 50.00), Vector2(38.07, 50.00), "yard: the rear fence")
	c.privacy(Vector2(39.27, 50.00), Vector2(41.70, 50.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(38.67, c.yf(38.67, 50.00), 50.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([38.67, 53.00, 0.0, c.yf(38.67, 53.00)])
	c.oil(Vector2(38.67, 53.00), 0.0)
	c.put("prop_swing_set", "worn", c.gp(32.40, 31.00), 344.0, "back yard: the kids' swings")
	c.put("prop_patio_set_4", "worn", c.gp(38.27, 33.00), 74.0, "back yard: the patio table")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(41.58, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(56.70, 10.70), Vector2(54.30, 10.70), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(66.10, 10.70), Vector2(68.50, 10.70), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(54.30, 10.70), Vector2(54.30, 50.00), "yard: the lot-line fence")
	c.privacy(Vector2(68.50, 10.70), Vector2(68.50, 50.00), "yard: the lot-line fence")
	c.privacy(Vector2(54.30, 50.00), Vector2(64.50, 50.00), "yard: the rear fence")
	c.privacy(Vector2(65.70, 50.00), Vector2(68.50, 50.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(65.10, c.yf(65.10, 50.00), 50.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([65.10, 53.00, 0.0, c.yf(65.10, 53.00)])
	c.oil(Vector2(65.10, 53.00), 0.0)
	c.put("prop_patio_set_4", "worn", c.gp(58.14, 33.20), 333.0, "back yard: the patio table")
	c.put("prop_adirondack_white", "worn", c.gp(64.66, 35.20), 63.0, "back yard: a chair on the lawn")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(68.30, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(73.15, 9.05), Vector2(69.10, 9.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(79.25, 9.05), Vector2(83.30, 9.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(69.10, 9.05), Vector2(69.10, 50.00), "yard: the lot-line fence")
	c.privacy(Vector2(83.30, 9.05), Vector2(83.30, 50.00), "yard: the lot-line fence")
	c.privacy(Vector2(69.10, 50.00), Vector2(71.90, 50.00), "yard: the rear fence")
	c.privacy(Vector2(73.10, 50.00), Vector2(83.30, 50.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(72.50, c.yf(72.50, 50.00), 50.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([72.50, 53.00, 0.0, c.yf(72.50, 53.00)])
	c.oil(Vector2(72.50, 53.00), 0.0)
	c.put("prop_swing_set", "worn", c.gp(72.94, 31.55), 34.0, "back yard: the kids' swings")
	c.put("prop_patio_set_4", "worn", c.gp(79.46, 33.55), 124.0, "back yard: the patio table")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(81.45, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(86.10, 8.50), Vector2(83.90, 8.50), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(95.90, 8.50), Vector2(98.10, 8.50), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(83.90, 8.50), Vector2(83.90, 50.00), "yard: the lot-line fence")
	c.privacy(Vector2(98.10, 8.50), Vector2(98.10, 50.00), "yard: the lot-line fence")
	c.privacy(Vector2(83.90, 50.00), Vector2(94.10, 50.00), "yard: the rear fence")
	c.privacy(Vector2(95.30, 50.00), Vector2(98.10, 50.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(94.70, c.yf(94.70, 50.00), 50.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([94.70, 53.00, 0.0, c.yf(94.70, 53.00)])
	c.oil(Vector2(94.70, 53.00), 0.0)
	c.put("prop_picnic_table", "worn", c.gp(87.74, 31.00), 95.0, "back yard: a table in the yard")
	c.put("prop_swing_set", "worn", c.gp(94.26, 33.00), 185.0, "back yard: the kids' swings")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(99.20, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(102.65, 8.05), Vector2(98.70, 8.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(108.95, 8.05), Vector2(112.90, 8.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(98.70, 8.05), Vector2(98.70, 50.00), "yard: the lot-line fence")
	c.privacy(Vector2(112.90, 8.05), Vector2(112.90, 50.00), "yard: the lot-line fence")
	c.privacy(Vector2(98.70, 50.00), Vector2(101.50, 50.00), "yard: the rear fence")
	c.privacy(Vector2(102.70, 50.00), Vector2(112.90, 50.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(102.10, c.yf(102.10, 50.00), 50.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([102.10, 53.00, 0.0, c.yf(102.10, 53.00)])
	c.oil(Vector2(102.10, 53.00), 0.0)
	c.put("prop_clothesline", "worn", c.gp(102.54, 30.55), 156.0, "back yard: washing on the line")
	c.put("prop_picnic_table", "worn", c.gp(109.06, 32.55), 246.0, "back yard: a table in the yard")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(111.15, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(116.30, 8.25), Vector2(113.50, 8.25), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(124.90, 8.25), Vector2(127.70, 8.25), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(113.50, 8.25), Vector2(113.50, 50.00), "yard: the lot-line fence")
	c.privacy(Vector2(127.70, 8.25), Vector2(127.70, 50.00), "yard: the lot-line fence")
	c.privacy(Vector2(113.50, 50.00), Vector2(123.70, 50.00), "yard: the rear fence")
	c.privacy(Vector2(124.90, 50.00), Vector2(127.70, 50.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(124.30, c.yf(124.30, 50.00), 50.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([124.30, 53.00, 0.0, c.yf(124.30, 53.00)])
	c.oil(Vector2(124.30, 53.00), 0.0)
	c.put("prop_bbq_gas_cart", "worn", c.gp(117.34, 30.75), 217.0, "back yard: the gas grill")
	c.put("prop_clothesline", "worn", c.gp(123.86, 32.75), 307.0, "back yard: washing on the line")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(127.10, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(142.50, 11.60), Vector2(140.30, 11.60), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(150.83, 11.60), Vector2(153.03, 11.60), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(140.30, 11.60), Vector2(140.30, 50.00), "yard: the lot-line fence")
	c.privacy(Vector2(153.03, 11.60), Vector2(153.03, 50.00), "yard: the lot-line fence")
	c.privacy(Vector2(140.30, 50.00), Vector2(149.40, 50.00), "yard: the rear fence")
	c.privacy(Vector2(150.60, 50.00), Vector2(153.03, 50.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(150.00, c.yf(150.00, 50.00), 50.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([150.00, 53.00, 0.0, c.yf(150.00, 53.00)])
	c.oil(Vector2(150.00, 53.00), 0.0)
	c.put("prop_swing_set", "worn", c.gp(143.73, 34.10), 84.0, "back yard: the kids' swings")
	c.put("prop_patio_set_4", "worn", c.gp(149.60, 36.10), 174.0, "back yard: the patio table")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(153.62, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(155.83, 8.95), Vector2(153.63, 8.95), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(164.17, 8.95), Vector2(166.37, 8.95), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(153.63, 8.95), Vector2(153.63, 50.00), "yard: the lot-line fence")
	c.privacy(Vector2(166.37, 8.95), Vector2(166.37, 50.00), "yard: the lot-line fence")
	c.privacy(Vector2(153.63, 50.00), Vector2(156.07, 50.00), "yard: the rear fence")
	c.privacy(Vector2(157.27, 50.00), Vector2(166.37, 50.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(156.67, c.yf(156.67, 50.00), 50.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([156.67, 53.00, 0.0, c.yf(156.67, 53.00)])
	c.oil(Vector2(156.67, 53.00), 0.0)
	c.put("prop_picnic_table", "worn", c.gp(157.07, 31.45), 145.0, "back yard: a table in the yard")
	c.put("prop_swing_set", "worn", c.gp(162.93, 33.45), 235.0, "back yard: the kids' swings")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(167.50, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(169.38, 7.85), Vector2(166.97, 7.85), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(177.28, 7.85), Vector2(179.70, 7.85), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(166.97, 7.85), Vector2(166.97, 50.00), "yard: the lot-line fence")
	c.privacy(Vector2(179.70, 7.85), Vector2(179.70, 50.00), "yard: the lot-line fence")
	c.privacy(Vector2(166.97, 50.00), Vector2(176.07, 50.00), "yard: the rear fence")
	c.privacy(Vector2(177.27, 50.00), Vector2(179.70, 50.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(176.67, c.yf(176.67, 50.00), 50.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([176.67, 53.00, 0.0, c.yf(176.67, 53.00)])
	c.oil(Vector2(176.67, 53.00), 0.0)
	c.put("prop_clothesline", "worn", c.gp(170.40, 30.35), 206.0, "back yard: washing on the line")
	c.put("prop_picnic_table", "worn", c.gp(176.27, 32.35), 296.0, "back yard: a table in the yard")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(179.48, 2.40), 0.0, "front: a pot by the walk")
	c.alley_wear(0.0, 56.0, 182.0, 62.0, false)
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
