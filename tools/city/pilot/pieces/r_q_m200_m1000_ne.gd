extends SceneTree
## Piece r_q_m200_m1000_ne (residential growth, 18-19 Nov): the NE quadrant of junction (-200, -1000), design V1.
## Hill: pad 8.0 m; the block rises +4.0 m along u, +2.0 m along v (twist +0.0) - the quadrant follows it.
## Built by rv_lib.gd (every rule and its reason is there). Run once; never when locked.
const RV := preload("res://tools/city/pilot/pieces/rv_lib.gd")
const D := preload("res://tools/city/pilot/pieces/rv_designs.gd")
const SITE := {"j": [-200.0, -1000.0], "sx": 1.0, "sz": -1.0, "p0": 8.0, "pu": 12.0, "pv": 10.0, "puv": 14.0, "Lu": 200.0, "Lv": 200.0}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RV.new().build("r_q_m200_m1000_ne", SITE, D.get_design("V1"))
	quit()
