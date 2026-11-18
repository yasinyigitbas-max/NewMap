extends SceneTree
## Piece r_q_500_m200_sw (residential growth, 18-19 Nov): the SW quadrant of junction (500, -200), design V3.
## Hill: pad 8.0 m; the block rises +4.0 m along u, -4.0 m along v (twist +2.0) - the quadrant follows it.
## Built by rv_lib.gd (every rule and its reason is there). Run once; never when locked.
const RV := preload("res://tools/city/pilot/pieces/rv_lib.gd")
const D := preload("res://tools/city/pilot/pieces/rv_designs.gd")
const SITE := {"j": [500.0, -200.0], "sx": -1.0, "sz": 1.0, "p0": 8.0, "pu": 12.0, "pv": 4.0, "puv": 10.0, "Lu": 250.0, "Lv": 200.0}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RV.new().build("r_q_500_m200_sw", SITE, D.get_design("V3"))
	quit()
