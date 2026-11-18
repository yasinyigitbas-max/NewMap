extends SceneTree
## Piece r_q_m600_m200_se (residential growth, 18-19 Nov): the SE quadrant of junction (-600, -200), design V4.
## Hill: pad 6.0 m; the block rises +0.0 m along u, +6.0 m along v (twist -6.0) - the quadrant follows it.
## Built by rv_lib.gd (every rule and its reason is there). Run once; never when locked.
## Corner shop: r_shop_cafe (cafe), its room is in interiors/assignment_res.json.
const RV := preload("res://tools/city/pilot/pieces/rv_lib.gd")
const D := preload("res://tools/city/pilot/pieces/rv_designs.gd")
const SITE := {"j": [-600.0, -200.0], "sx": 1.0, "sz": 1.0, "p0": 6.0, "pu": 6.0, "pv": 12.0, "puv": 6.0, "Lu": 200.0, "Lv": 200.0, "pu_line": 9.2, "pv_line": 9.2, "apron_u": true, "apron_v": true, "shop": ["commercial/com_shallow_cafe", "r_shop_cafe", "cafe"]}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RV.new().build("r_q_m600_m200_se", SITE, D.get_design("V4"))
	quit()
