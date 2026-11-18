extends SceneTree
## Piece r_q_m800_200_ne (residential growth, 18-19 Nov): the NE quadrant of junction (-800, 200), design V3.
## Hill: pad 2.0 m; the block rises +2.0 m along u, +6.0 m along v (twist +2.0) - the quadrant follows it.
## Built by rv_lib.gd (every rule and its reason is there). Run once; never when locked.
## Corner shop: r_shop_surf (sport), its room is in interiors/assignment_res.json.
const RV := preload("res://tools/city/pilot/pieces/rv_lib.gd")
const D := preload("res://tools/city/pilot/pieces/rv_designs.gd")
const SITE := {"j": [-800.0, 200.0], "sx": 1.0, "sz": -1.0, "p0": 2.0, "pu": 4.0, "pv": 8.0, "puv": 12.0, "Lu": 200.0, "Lv": 200.0, "pu_line": 9.2, "pv_line": 9.2, "apron_u": true, "apron_v": true, "shop": ["commercial/com_surf_shop", "r_shop_surf", "sport"]}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RV.new().build("r_q_m800_200_ne", SITE, D.get_design("V3"))
	quit()
