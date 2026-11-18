extends SceneTree
## Piece r_q_250_m1400_se (residential growth, 18-19 Nov): the SE quadrant of junction (250, -1400), design V2.
## Hill: pad 2.0 m; the block rises +0.0 m along u, +6.0 m along v (twist -4.0) - the quadrant follows it.
## Built by rv_lib.gd (every rule and its reason is there). Run once; never when locked.
const RV := preload("res://tools/city/pilot/pieces/rv_lib.gd")
const D := preload("res://tools/city/pilot/pieces/rv_designs.gd")
const SITE := {"j": [250.0, -1400.0], "sx": 1.0, "sz": 1.0, "p0": 2.0, "pu": 2.0, "pv": 8.0, "puv": 4.0, "Lu": 250.0, "Lv": 200.0, "pu_line": 9.2, "pv_line": 14.3, "apron_u": true, "apron_v": false}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RV.new().build("r_q_250_m1400_se", SITE, D.get_design("V2"))
	quit()
