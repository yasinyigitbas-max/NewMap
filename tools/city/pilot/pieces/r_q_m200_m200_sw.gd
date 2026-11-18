extends SceneTree
## Piece r_q_m200_m200_sw (residential growth, 18-19 Nov): the SW quadrant of junction (-200, -200), design V4.
## Hill: pad 6.0 m; the block rises +0.0 m along u, -2.0 m along v (twist +2.0) - the quadrant follows it.
## Built by rv_lib.gd (every rule and its reason is there). Run once; never when locked.
const RV := preload("res://tools/city/pilot/pieces/rv_lib.gd")
const D := preload("res://tools/city/pilot/pieces/rv_designs.gd")
const SITE := {"j": [-200.0, -200.0], "sx": -1.0, "sz": 1.0, "p0": 6.0, "pu": 6.0, "pv": 4.0, "puv": 6.0, "Lu": 200.0, "Lv": 200.0, "pu_line": 9.2, "pv_line": 9.2, "apron_u": true, "apron_v": true}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RV.new().build("r_q_m200_m200_sw", SITE, D.get_design("V4"))
	quit()
