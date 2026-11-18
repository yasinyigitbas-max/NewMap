extends SceneTree
## Piece r_q_0_m1000_se (residential growth, 18-19 Nov): the SE quadrant of junction (0, -1000), design V3.
## Hill: pad 12.0 m; the block rises -6.0 m along u, -6.0 m along v (twist +6.0) - the quadrant follows it.
## Built by rv_lib.gd (every rule and its reason is there). Run once; never when locked.
const RV := preload("res://tools/city/pilot/pieces/rv_lib.gd")
const D := preload("res://tools/city/pilot/pieces/rv_designs.gd")
const SITE := {"j": [0.0, -1000.0], "sx": 1.0, "sz": 1.0, "p0": 12.0, "pu": 6.0, "pv": 6.0, "puv": 6.0, "Lu": 250.0, "Lv": 200.0}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RV.new().build("r_q_0_m1000_se", SITE, D.get_design("V3"))
	quit()
