extends SceneTree
## Piece n_w_e4 (WEST FILL, the south-west edge by the beach road): u -391..-209, v 209..302, 182 x 93 m; flat at 2.0.
## SITE: a street north (aprons x 44..51.5, 130..137.5), the ring road south (the beach beyond it).
## PLANNER: beach-side houses facing the north street; on the east end the SURF SHACK (surf shop) and the BEACH BEAN café
## facing the street with bikes, boards and tables; a back lane, the sound wall to the ring road.
## Layout row (-391.0, 0, 209.0): local x = u - (-391.0), z = v - (209.0), heights absolute. Built by the west fill (University
## session, 20 Nov; review/fill_west/PLAN.md). Ground: the land 8 cm over it, eased over 8 m to the measured height of
## whatever borders each side; buildings on level pads at the highest ground under them (plinth faces downhill).
const L := preload("res://tools/city/pilot/pieces/w_fill_lib.gd")
## site u -391.0..-209.0 v 209.0..302.0 (182.0 x 93.0 m); neighbours N {np.str_('j_rs_4r_d'): 6, np.str_('s_rs_b127_a'): 40, np.str_('s_rs_b127_b'): 40, np.str_('j_rs_1l3r_b'): 6} S {np.str_('j_rg_se_w400_s315'): 7, '-': 85} W {np.str_('j_rs_4r_d'): 6, np.str_('s_rg_se_b027'): 34, np.str_('j_rg_se_w400_s315'): 7} E {np.str_('j_rs_1l3r_b'): 6, np.str_('s_rg_se_b035'): 41}
const LAND := {"x0": -9.0, "z0": -9.0, "step": 4.0, "nx": 51, "nz": 29, "h": [1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.10,2.11,2.13,2.09,2.10,2.08,2.10,2.10,2.11,2.10,2.11,2.13,2.09,2.10,2.08,2.10,2.10,2.11,2.10,2.11,2.13,2.11,2.10,2.08,2.10,2.09,2.11,2.10,2.11,2.10,2.11,2.10,2.08,2.10,2.08,2.10,2.09,2.11,2.10,2.11,2.12,2.08,2.10,2.10,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.08,2.10,2.11,2.10,2.11,2.10,2.11,2.10,2.10,2.08,2.10,2.11,2.10,2.11,2.10,2.11,2.10,2.12,2.08,2.10,2.11,2.10,2.11,2.09,2.11,2.10,2.12,2.08,2.10,2.11,2.09,2.11,2.09,2.11,2.09,2.11,2.10,2.09,2.11,2.09,2.11,2.09,2.11,2.10,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.12,2.11,2.12,2.11,2.10,2.08,2.10,2.09,2.10,2.12,2.11,2.12,2.11,2.10,2.08,2.10,2.09,2.10,2.12,2.11,2.12,2.11,2.12,2.08,2.10,2.08,2.10,2.12,2.10,2.12,2.10,2.12,2.08,2.10,2.08,2.10,2.12,2.10,2.12,2.10,2.12,2.10,2.10,2.10,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.11,2.09,2.11,2.09,2.11,2.09,2.11,2.13,2.11,2.11,2.09,2.11,2.09,2.11,2.09,2.11,2.13,2.11,2.13,2.09,2.11,2.09,2.11,2.09,2.11,2.12,2.11,2.13,2.09,2.10,2.09,2.10,2.09,2.10,2.12,2.11,2.12,2.11,2.10,2.08,2.10,2.08,2.10,2.10,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.11,2.10,2.11,2.10,2.12,2.11,2.09,2.11,2.10,2.11,2.10,2.12,2.10,2.12,2.11,2.09,2.11,2.10,2.11,2.10,2.12,2.10,2.12,2.13,2.09,2.11,2.09,2.11,2.10,2.11,2.10,2.11,2.13,2.09,2.11,2.09,2.11,2.09,2.11,2.09,2.11,2.12,2.11,2.10,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.12,2.08,2.10,2.11,2.10,2.12,2.10,2.12,2.10,2.12,2.08,2.10,2.12,2.10,2.12,2.10,2.12,2.11,2.12,2.11,2.10,2.12,2.10,2.12,2.10,2.12,2.10,2.12,2.10,2.10,2.11,2.10,2.11,2.10,2.12,2.10,2.12,2.10,2.12,2.11,2.09,2.11,2.09,2.10,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.10,2.12,2.10,2.12,2.11,2.12,2.09,2.10,2.09,2.11,2.12,2.11,2.12,2.11,2.13,2.09,2.10,2.09,2.11,2.12,2.11,2.12,2.11,2.13,2.11,2.10,2.09,2.10,2.12,2.11,2.12,2.11,2.12,2.11,2.12,2.08,2.10,2.12,2.10,2.12,2.10,2.11,2.09,2.10,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.10,2.12,2.09,2.10,2.09,2.11,2.09,2.11,2.13,2.11,2.13,2.09,2.11,2.09,2.11,2.10,2.11,2.13,2.11,2.13,2.12,2.11,2.09,2.11,2.09,2.11,2.13,2.11,2.13,2.11,2.11,2.09,2.11,2.09,2.11,2.12,2.11,2.12,2.11,2.12,2.08,2.10,2.08,2.10,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.09,2.11,2.09,2.11,2.10,2.12,2.13,2.09,2.11,2.10,2.11,2.10,2.12,2.10,2.12,2.14,2.10,2.11,2.10,2.12,2.10,2.12,2.10,2.12,2.14,2.12,2.11,2.10,2.11,2.10,2.11,2.10,2.12,2.13,2.12,2.13,2.09,2.11,2.09,2.11,2.09,2.11,2.12,2.10,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.09,2.11,2.10,2.10,2.11,2.10,2.12,2.10,2.12,2.10,2.12,2.11,2.10,2.12,2.10,2.12,2.10,2.12,2.11,2.12,2.11,2.12,2.12,2.10,2.12,2.10,2.12,2.10,2.12,2.11,2.12,2.11,2.10,2.12,2.10,2.12,2.10,2.12,2.10,2.12,2.13,2.09,2.11,2.10,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.08,2.10,2.12,2.10,2.12,2.11,2.12,2.11,2.10,2.09,2.11,2.12,2.11,2.13,2.11,2.13,2.11,2.13,2.09,2.11,2.12,2.11,2.13,2.11,2.13,2.11,2.13,2.09,2.10,2.12,2.11,2.12,2.11,2.12,2.11,2.12,2.11,2.10,2.12,2.10,2.12,2.10,2.12,2.10,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.12,2.11,2.13,2.11,2.10,2.09,2.11,2.09,2.11,2.13,2.11,2.13,2.12,2.11,2.09,2.11,2.09,2.11,2.13,2.11,2.13,2.12,2.13,2.09,2.11,2.09,2.11,2.13,2.11,2.13,2.11,2.13,2.09,2.11,2.09,2.11,2.12,2.11,2.12,2.11,2.12,2.11,2.10,2.10,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.11,2.09,2.11,2.09,2.11,2.10,2.12,2.13,2.12,2.11,2.10,2.11,2.10,2.12,2.10,2.12,2.14,2.12,2.14,2.10,2.11,2.10,2.12,2.10,2.12,2.13,2.12,2.14,2.09,2.11,2.10,2.11,2.10,2.11,2.13,2.11,2.13,2.11,2.11,2.09,2.10,2.09,2.10,2.10,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.12,2.10,2.12,2.10,2.12,2.11,2.10,2.12,2.10,2.12,2.10,2.12,2.10,2.12,2.12,2.10,2.12,2.10,2.12,2.10,2.12,2.11,2.12,2.14,2.10,2.12,2.10,2.12,2.10,2.12,2.10,2.12,2.14,2.10,2.11,2.10,2.11,2.10,2.11,2.09,2.11,2.13,2.11,2.10,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.12,2.08,2.10,2.12,2.10,2.12,2.10,2.12,2.11,2.13,2.08,2.10,2.12,2.11,2.12,2.11,2.13,2.11,2.13,2.11,2.10,2.12,2.10,2.12,2.11,2.12,2.11,2.13,2.11,2.10,2.12,2.10,2.12,2.10,2.12,2.10,2.12,2.10,2.12,2.11,2.09,2.11,2.09,2.10,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.10,2.12,2.11,2.12,2.11,2.13,2.09,2.10,2.09,2.11,2.13,2.11,2.13,2.11,2.13,2.09,2.11,2.09,2.11,2.13,2.11,2.13,2.11,2.13,2.11,2.11,2.09,2.11,2.13,2.11,2.13,2.11,2.13,2.11,2.13,2.09,2.10,2.12,2.10,2.12,2.10,2.12,2.09,2.10,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.10,2.13,2.09,2.11,2.09,2.11,2.09,2.11,2.13,2.11,2.13,2.09,2.11,2.09,2.11,2.10,2.11,2.13,2.12,2.13,2.12,2.11,2.09,2.11,2.09,2.11,2.13,2.11,2.13,2.12,2.11,2.09,2.11,2.09,2.11,2.13,2.11,2.13,2.11,2.13,2.08,2.10,2.08,2.10,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.09,2.11,2.09,2.11,2.10,2.12,2.13,2.09,2.11,2.10,2.11,2.10,2.12,2.10,2.12,2.10,2.10,2.11,2.10,2.11,2.10,2.12,2.10,2.12,2.10,2.12,2.11,2.10,2.11,2.10,2.12,2.10,2.12,2.10,2.12,2.13,2.09,2.11,2.09,2.11,2.09,2.11,2.09,2.10,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.09,2.11,2.10,2.09,2.08,2.10,2.12,2.10,2.12,2.10,2.12,2.10,2.10,2.08,2.10,2.12,2.10,2.12,2.10,2.12,2.10,2.12,2.08,2.10,2.12,2.10,2.12,2.10,2.12,2.10,2.12,2.08,2.10,2.11,2.10,2.12,2.10,2.12,2.10,2.12,2.10,2.09,2.11,2.10,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.08,2.10,2.08,2.10,2.12,2.10,2.12,2.11,2.10,2.08,2.10,2.08,2.10,2.12,2.11,2.13,2.11,2.13,2.08,2.10,2.08,2.10,2.12,2.10,2.12,2.11,2.13,2.08,2.10,2.08,2.10,2.12,2.10,2.12,2.10,2.12,2.10,2.10,2.08,2.10,2.12,2.10,2.12,2.10,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.09,2.11,2.12,2.11,2.10,2.09,2.10,2.09,2.10,2.09,2.11,2.13,2.11,2.10,2.09,2.11,2.09,2.11,2.09,2.11,2.12,2.11,2.13,2.09,2.10,2.09,2.11,2.09,2.11,2.13,2.11,2.13,2.08,2.10,2.08,2.10,2.09,2.10,2.12,2.11,2.13,2.11,2.11,2.10,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.09,2.11,2.10,2.12,2.09,2.11,2.13,2.09,2.10,2.09,2.10,2.09,2.11,2.09,2.11,2.13,2.09,2.11,2.09,2.11,2.09,2.11,2.09,2.11,2.13,2.11,2.10,2.09,2.11,2.09,2.11,2.10,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.09,2.12,2.10,2.12,2.09,2.09,2.10,2.09,2.10,2.09,2.11,2.10,2.12,2.09,2.11,2.10,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,2.10,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,1.95,2.10,2.10,2.10,1.95,1.95,1.95,1.95]}
const EDGE_N := [[0.0,2.15],[2.0,2.15],[4.0,2.15],[6.0,2.15],[8.0,2.15],[10.0,2.15],[12.0,2.15],[14.0,2.15],[16.0,2.15],[18.0,2.15],[20.0,2.15],[22.0,2.15],[24.0,2.15],[26.0,2.15],[28.0,2.15],[30.0,2.15],[32.0,2.15],[34.0,2.15],[36.0,2.15],[38.0,2.15],[40.0,2.15],[42.0,2.15],[44.0,2.15],[46.0,2.15],[48.0,2.15],[50.0,2.15],[52.0,2.15],[54.0,2.15],[56.0,2.15],[58.0,2.15],[60.0,2.15],[62.0,2.15],[64.0,2.15],[66.0,2.15],[68.0,2.15],[70.0,2.15],[72.0,2.15],[74.0,2.15],[76.0,2.15],[78.0,2.15],[80.0,2.15],[82.0,2.15],[84.0,2.15],[86.0,2.15],[88.0,2.15],[90.0,2.15],[92.0,2.15],[94.0,2.15],[96.0,2.15],[98.0,2.15],[100.0,2.15],[102.0,2.15],[104.0,2.15],[106.0,2.15],[108.0,2.15],[110.0,2.15],[112.0,2.15],[114.0,2.15],[116.0,2.15],[118.0,2.15],[120.0,2.15],[122.0,2.15],[124.0,2.15],[126.0,2.15],[128.0,2.15],[130.0,2.15],[132.0,2.15],[134.0,2.15],[136.0,2.15],[138.0,2.15],[140.0,2.15],[142.0,2.15],[144.0,2.15],[146.0,2.15],[148.0,2.15],[150.0,2.15],[152.0,2.15],[154.0,2.15],[156.0,2.15],[158.0,2.15],[160.0,2.15],[162.0,2.15],[164.0,2.15],[166.0,2.15],[168.0,2.15],[170.0,2.15],[172.0,2.15],[174.0,2.15],[176.0,2.15],[178.0,2.15],[180.0,2.15],[182.0,2.15]]
const EDGE_S := [[0.0,2.15],[2.0,2.15],[4.0,2.15],[6.0,2.15],[8.0,2.15],[10.0,2.15],[12.0,2.15],[14.0,2.006],[16.0,2.006],[18.0,2.006],[20.0,2.006],[22.0,2.006],[24.0,2.006],[26.0,2.006],[28.0,2.006],[30.0,2.006],[32.0,2.006],[34.0,2.006],[36.0,2.03],[38.0,2.077],[40.0,2.1],[42.0,2.1],[44.0,2.1],[46.0,2.1],[48.0,2.1],[50.0,2.1],[52.0,2.099],[54.0,2.097],[56.0,2.098],[58.0,2.101],[60.0,2.102],[62.0,2.101],[64.0,2.102],[66.0,2.104],[68.0,2.104],[70.0,2.1],[72.0,2.099],[74.0,2.103],[76.0,2.106],[78.0,2.109],[80.0,2.107],[82.0,2.099],[84.0,2.097],[86.0,2.1],[88.0,2.1],[90.0,2.097],[92.0,2.097],[94.0,2.1],[96.0,2.1],[98.0,2.098],[100.0,2.099],[102.0,2.103],[104.0,2.103],[106.0,2.099],[108.0,2.099],[110.0,2.103],[112.0,2.106],[114.0,2.109],[116.0,2.105],[118.0,2.095],[120.0,2.096],[122.0,2.108],[124.0,2.11],[126.0,2.104],[128.0,2.104],[130.0,2.111],[132.0,2.109],[134.0,2.098],[136.0,2.093],[138.0,2.095],[140.0,2.096],[142.0,2.097],[144.0,2.097],[146.0,2.096],[148.0,2.1],[150.0,2.108],[152.0,2.108],[154.0,2.101],[156.0,2.1],[158.0,2.104],[160.0,2.104],[162.0,2.099],[164.0,2.101],[166.0,2.109],[168.0,2.108],[170.0,2.098],[172.0,2.098],[174.0,2.108],[176.0,2.11],[178.0,2.103],[180.0,2.063],[182.0,1.988]]
const EDGE_W := [[0.0,2.15],[2.0,2.15],[4.0,2.15],[6.0,2.15],[8.0,2.15],[10.0,2.15],[12.0,2.15],[14.0,2.15],[16.0,2.15],[18.0,2.15],[20.0,2.15],[22.0,2.15],[24.0,2.15],[26.0,2.15],[28.0,2.15],[30.0,2.15],[32.0,2.15],[34.0,2.15],[36.0,2.15],[38.0,2.15],[40.0,2.15],[42.0,2.15],[44.0,2.15],[46.0,2.15],[48.0,2.15],[50.0,2.15],[52.0,2.15],[54.0,2.15],[56.0,2.15],[58.0,2.15],[60.0,2.15],[62.0,2.15],[64.0,2.15],[66.0,2.15],[68.0,2.15],[70.0,2.15],[72.0,2.15],[74.0,2.15],[76.0,2.15],[78.0,2.15],[80.0,2.15],[82.0,2.15],[84.0,2.15],[86.0,2.15],[88.0,2.15],[90.0,2.15],[92.0,2.15]]
const EDGE_E := [[0.0,2.15],[2.0,2.15],[4.0,2.15],[6.0,2.15],[8.0,2.15],[10.0,2.15],[12.0,2.15],[14.0,2.15],[16.0,2.15],[18.0,2.15],[20.0,2.15],[22.0,2.15],[24.0,2.15],[26.0,2.15],[28.0,2.15],[30.0,2.15],[32.0,2.15],[34.0,2.15],[36.0,2.15],[38.0,2.15],[40.0,2.15],[42.0,2.15],[44.0,2.15],[46.0,2.15],[48.0,2.15],[50.0,2.15],[52.0,2.15],[54.0,2.15],[56.0,2.15],[58.0,2.15],[60.0,2.15],[62.0,2.15],[64.0,2.15],[66.0,2.15],[68.0,2.15],[70.0,2.15],[72.0,2.15],[74.0,2.15],[76.0,2.15],[78.0,2.15],[80.0,2.15],[82.0,2.15],[84.0,2.15],[86.0,2.15],[88.0,2.15],[90.0,2.15],[92.0,2.15]]

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var c := L.new("n_w_e4", 4.15)
	var W := 182.00; var D := 93.00
	var land := func(x: float, z: float) -> float: return L.land_at(LAND, x, z) + 0.08
	var base := L.edged(land, W, D, EDGE_N, EDGE_S, EDGE_W, EDGE_E, 8.0)
	var SITES := [["commercial/com_surf_shop", Vector2(150.00, 3.00), "n", "surf_shack"],
		["commercial/com_cafe_seaside", Vector2(166.00, 3.00), "n", "beach_bean"],
		["houses/beach_teal", Vector2(8.67, 3.00), "n", "r0_0"],
		["houses/beach_white", Vector2(22.00, 3.00), "n", "r0_1"],
		["houses/spanish_small", Vector2(35.33, 3.00), "n", "r0_2"],
		["houses/beach_blue", Vector2(61.40, 3.00), "n", "r1_0"],
		["houses/ranch_peach", Vector2(76.20, 3.00), "n", "r1_1"],
		["houses/beach_large", Vector2(91.00, 3.00), "n", "r1_2"],
		["houses/spanish_pink", Vector2(105.80, 3.00), "n", "r1_3"],
		["houses/cape_white", Vector2(120.60, 3.00), "n", "r1_4"]]
	var pads: Array = []
	for st: Array in SITES:
		var r0: Array = L.bld_rect(String(st[0]), st[1], String(st[2]))
		pads.append([maxf(0.0, float(r0[0]) - 0.3), maxf(0.0, float(r0[1]) - 0.3), minf(W, float(r0[2]) + 0.3), minf(D, float(r0[3]) + 0.3)])
	var gl := L.grid_lots(0.0, 0.0, W, D, pads, base)
	c.terrain(gl.lots)
	c.skirt_depth = 0.5
	c.paint("asphalt", 0.00, 66.00, 182.00, 72.00)                # the back lane
	c.paint("asphalt", 44.00, 0.00, 52.00, 66.00)                # lane from the north apron
	c.paint("asphalt", 130.00, 0.00, 138.00, 66.00)                # lane from the north apron
	c.paint("concrete", 140.00, 0.00, 182.00, 3.00)                # the shops' frontage
	c.paint("concrete", 172.00, 3.00, 182.00, 30.00)                # the café terrace
	c.paint("concrete", 9.40, 60.40, 14.60, 66.00)                # r0 0: the parking pad off the lane
	c.paint("concrete", 16.07, 60.40, 21.27, 66.00)                # r0 1: the parking pad off the lane
	c.paint("concrete", 36.07, 60.40, 41.27, 66.00)                # r0 2: the parking pad off the lane
	c.paint("concrete", 62.50, 60.40, 67.70, 66.00)                # r1 0: the parking pad off the lane
	c.paint("concrete", 69.90, 60.40, 75.10, 66.00)                # r1 1: the parking pad off the lane
	c.paint("concrete", 92.10, 60.40, 97.30, 66.00)                # r1 2: the parking pad off the lane
	c.paint("concrete", 99.50, 60.40, 104.70, 66.00)                # r1 3: the parking pad off the lane
	c.paint("concrete", 121.70, 60.40, 126.90, 66.00)                # r1 4: the parking pad off the lane
	c.paint("grass", 0.0, 0.0, W, D)
	c.build_floor(L.rect_edges(0.0, 0.0, W, D))
	if c.stage == "ground": c.finish(); quit(); return
	var B := {}
	for k in SITES.size():
		c.y0 = float(gl.pads[k][4])
		B[String(SITES[k][3])] = c.bld(String(SITES[k][0]), SITES[k][1], String(SITES[k][2]), false, String(SITES[k][3]), 0.70)

	c.privacy(Vector2(5.12, 8.55), Vector2(2.30, 8.55), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(12.22, 8.55), Vector2(15.03, 8.55), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(2.30, 8.55), Vector2(2.30, 60.00), "yard: the lot-line fence")
	c.privacy(Vector2(15.03, 8.55), Vector2(15.03, 60.00), "yard: the lot-line fence")
	c.privacy(Vector2(2.30, 60.00), Vector2(11.40, 60.00), "yard: the rear fence")
	c.privacy(Vector2(12.60, 60.00), Vector2(15.03, 60.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(12.00, c.yf(12.00, 60.00), 60.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([12.00, 63.00, 0.0, c.yf(12.00, 63.00)])
	c.oil(Vector2(12.00, 63.00), 0.0)
	c.put("prop_adirondack_white", "worn", c.gp(5.73, 36.05), 222.0, "back yard: a chair on the lawn")
	c.put("prop_adirondack_wood", "worn", c.gp(11.60, 38.05), 312.0, "back yard: a chair on the lawn facing the sun")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(14.42, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(18.95, 9.05), Vector2(15.63, 9.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(25.05, 9.05), Vector2(28.37, 9.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(15.63, 9.05), Vector2(15.63, 60.00), "yard: the lot-line fence")
	c.privacy(Vector2(28.37, 9.05), Vector2(28.37, 60.00), "yard: the lot-line fence")
	c.privacy(Vector2(15.63, 60.00), Vector2(18.07, 60.00), "yard: the rear fence")
	c.privacy(Vector2(19.27, 60.00), Vector2(28.37, 60.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(18.67, c.yf(18.67, 60.00), 60.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([18.67, 63.00, 0.0, c.yf(18.67, 63.00)])
	c.oil(Vector2(18.67, 63.00), 0.0)
	c.put("prop_patio_set_4", "worn", c.gp(19.07, 36.55), 283.0, "back yard: the patio table")
	c.put("prop_adirondack_white", "worn", c.gp(24.93, 38.55), 13.0, "back yard: a chair on the lawn")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(27.25, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(32.18, 8.05), Vector2(28.97, 8.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(38.48, 8.05), Vector2(41.70, 8.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(28.97, 8.05), Vector2(28.97, 60.00), "yard: the lot-line fence")
	c.privacy(Vector2(41.70, 8.05), Vector2(41.70, 60.00), "yard: the lot-line fence")
	c.privacy(Vector2(28.97, 60.00), Vector2(38.07, 60.00), "yard: the rear fence")
	c.privacy(Vector2(39.27, 60.00), Vector2(41.70, 60.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(38.67, c.yf(38.67, 60.00), 60.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([38.67, 63.00, 0.0, c.yf(38.67, 63.00)])
	c.oil(Vector2(38.67, 63.00), 0.0)
	c.put("prop_swing_set", "worn", c.gp(32.40, 35.55), 344.0, "back yard: the kids' swings")
	c.put("prop_patio_set_4", "worn", c.gp(38.27, 37.55), 74.0, "back yard: the patio table")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(40.68, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(58.10, 9.05), Vector2(54.30, 9.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(64.70, 9.05), Vector2(68.50, 9.05), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(54.30, 9.05), Vector2(54.30, 60.00), "yard: the lot-line fence")
	c.privacy(Vector2(68.50, 9.05), Vector2(68.50, 60.00), "yard: the lot-line fence")
	c.privacy(Vector2(54.30, 60.00), Vector2(64.50, 60.00), "yard: the rear fence")
	c.privacy(Vector2(65.70, 60.00), Vector2(68.50, 60.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(65.10, c.yf(65.10, 60.00), 60.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([65.10, 63.00, 0.0, c.yf(65.10, 63.00)])
	c.oil(Vector2(65.10, 63.00), 0.0)
	c.put("prop_patio_set_4", "worn", c.gp(58.14, 36.55), 333.0, "back yard: the patio table")
	c.put("prop_adirondack_white", "worn", c.gp(64.66, 38.55), 63.0, "back yard: a chair on the lawn")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(66.90, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(71.40, 8.50), Vector2(69.10, 8.50), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(81.00, 8.50), Vector2(83.30, 8.50), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(69.10, 8.50), Vector2(69.10, 60.00), "yard: the lot-line fence")
	c.privacy(Vector2(83.30, 8.50), Vector2(83.30, 60.00), "yard: the lot-line fence")
	c.privacy(Vector2(69.10, 60.00), Vector2(71.90, 60.00), "yard: the rear fence")
	c.privacy(Vector2(73.10, 60.00), Vector2(83.30, 60.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(72.50, c.yf(72.50, 60.00), 60.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([72.50, 63.00, 0.0, c.yf(72.50, 63.00)])
	c.oil(Vector2(72.50, 63.00), 0.0)
	c.put("prop_swing_set", "worn", c.gp(72.94, 36.00), 34.0, "back yard: the kids' swings")
	c.put("prop_patio_set_4", "worn", c.gp(79.46, 38.00), 124.0, "back yard: the patio table")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(83.20, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(86.25, 11.60), Vector2(83.90, 11.60), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(95.75, 11.60), Vector2(98.10, 11.60), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(83.90, 11.60), Vector2(83.90, 60.00), "yard: the lot-line fence")
	c.privacy(Vector2(98.10, 11.60), Vector2(98.10, 60.00), "yard: the lot-line fence")
	c.privacy(Vector2(83.90, 60.00), Vector2(94.10, 60.00), "yard: the rear fence")
	c.privacy(Vector2(95.30, 60.00), Vector2(98.10, 60.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(94.70, c.yf(94.70, 60.00), 60.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([94.70, 63.00, 0.0, c.yf(94.70, 63.00)])
	c.oil(Vector2(94.70, 63.00), 0.0)
	c.put("prop_picnic_table", "worn", c.gp(87.74, 39.10), 95.0, "back yard: a table in the yard")
	c.put("prop_swing_set", "worn", c.gp(94.26, 41.10), 185.0, "back yard: the kids' swings")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(97.95, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(100.90, 8.90), Vector2(98.70, 8.90), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(110.70, 8.90), Vector2(112.90, 8.90), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(98.70, 8.90), Vector2(98.70, 60.00), "yard: the lot-line fence")
	c.privacy(Vector2(112.90, 8.90), Vector2(112.90, 60.00), "yard: the lot-line fence")
	c.privacy(Vector2(98.70, 60.00), Vector2(101.50, 60.00), "yard: the rear fence")
	c.privacy(Vector2(102.70, 60.00), Vector2(112.90, 60.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(102.10, c.yf(102.10, 60.00), 60.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([102.10, 63.00, 0.0, c.yf(102.10, 63.00)])
	c.oil(Vector2(102.10, 63.00), 0.0)
	c.put("prop_clothesline", "worn", c.gp(102.54, 36.40), 156.0, "back yard: washing on the line")
	c.put("prop_picnic_table", "worn", c.gp(109.06, 38.40), 246.0, "back yard: a table in the yard")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(113.55, 2.40), 0.0, "front: a pot by the walk")
	c.privacy(Vector2(116.40, 7.85), Vector2(113.50, 7.85), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(124.80, 7.85), Vector2(127.70, 7.85), "yard: the side fence from the house wall to the lot line")
	c.privacy(Vector2(113.50, 7.85), Vector2(113.50, 60.00), "yard: the lot-line fence")
	c.privacy(Vector2(127.70, 7.85), Vector2(127.70, 60.00), "yard: the lot-line fence")
	c.privacy(Vector2(113.50, 60.00), Vector2(123.70, 60.00), "yard: the rear fence")
	c.privacy(Vector2(124.90, 60.00), Vector2(127.70, 60.00), "yard: the rear fence")
	c.put("fence_gate_privacy", "worn", Vector3(124.30, c.yf(124.30, 60.00), 60.00), 0.0, "yard: the gate to the parking pad", false)
	c.stalls.append([124.30, 63.00, 0.0, c.yf(124.30, 63.00)])
	c.oil(Vector2(124.30, 63.00), 0.0)
	c.put("prop_bbq_gas_cart", "worn", c.gp(117.34, 35.35), 217.0, "back yard: the gas grill")
	c.put("prop_clothesline", "worn", c.gp(123.86, 37.35), 307.0, "back yard: washing on the line")
	c.put("prop_usps_collection_box" if false else "plant_potted_succulent", "normal", c.gp(127.00, 2.40), 0.0, "front: a pot by the walk")
	c.alley_wear(0.0, 66.0, 182.0, 72.0, false)
	c.tyre(Vector2(48.0, 3.0), 0.0, 6.0, 0.45)
	c.tyre(Vector2(134.0, 3.0), 0.0, 6.0, 0.45)
	c.put("prop_kayak_rack", "worn", c.gp(143.00, 1.60), 0.0, "Surf Shack: boards and kayaks on the rack outside")
	c.put("prop_bike_rack", "worn", c.gp(158.20, 1.60), 0.0, "the shops: bikes")
	c.put("prop_menu_board", "worn", c.gp(171.00, 1.40), 0.0, "Beach Bean: the menu")
	c.put("prop_cafe_table", "worn", c.gp(175.00, 8.00), 0.0, "Beach Bean: a table on its terrace")
	c.put("prop_cafe_table", "worn", c.gp(179.00, 8.00), 0.0, "Beach Bean: a table on its terrace")
	c.put("prop_cafe_table", "worn", c.gp(175.00, 14.00), 0.0, "Beach Bean: a table on its terrace")
	c.put("prop_cafe_table", "worn", c.gp(179.00, 14.00), 0.0, "Beach Bean: a table on its terrace")
	c.put("prop_cafe_table", "worn", c.gp(175.00, 20.00), 0.0, "Beach Bean: a table on its terrace")
	c.put("prop_beach_shower", "worn", c.gp(178.00, 28.00), 0.0, "Beach Bean: a rinse shower for people off the beach")
	for k2: String in B:
		var r: Dictionary = B[k2]
		if not String(r.folder).begins_with("houses/"): c.services(r, 2.0, 1 if not String(r.folder).begins_with("apartments/") else 2, String(r.folder).begins_with("apartments/"))
		for dr: Array in r.doors:
			var q: Vector3 = dr[1]; var o: Vector3 = dr[2]
			c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.6, 1.4, 0.40)
	c.finish()
	quit()
