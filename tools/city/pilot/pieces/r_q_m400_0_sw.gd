extends SceneTree
## Piece r_q_m400_0_sw (residential growth, 18-19 Nov): the SW quadrant of junction (-400, 0), design V4.
## Hill: pad 6.0 m; the block rises +6.0 m along u, -4.0 m along v (twist -4.0) - the quadrant follows it.
## Built by rv_lib.gd (every rule and its reason is there). Run once; never when locked.
const RV := preload("res://tools/city/pilot/pieces/rv_lib.gd")
const D := preload("res://tools/city/pilot/pieces/rv_designs.gd")
const SITE := {"j": [-400.0, 0.0], "sx": -1.0, "sz": 1.0, "p0": 6.0, "pu": 12.0, "pv": 2.0, "puv": 4.0, "Lu": 200.0, "Lv": 200.0, "pu_line": 9.2, "pv_line": 9.2, "apron_u": true, "apron_v": true}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RV.new().build("r_q_m400_0_sw", SITE, D.get_design("V4"))
	quit()
