extends SceneTree
## Piece r_q_m400_200_ne (residential growth, pilot area, 18 Nov): the NE quadrant of junction (-400, 200), design V3.
## Hill: pad 2.0 m; the block rises +0.0 m along u, +4.0 m along v (twist -2.0) - the quadrant follows it.
## Built by rv_lib.gd (every rule and its reason is there). Run once; never when locked.
const RV := preload("res://tools/city/pilot/pieces/rv_lib.gd")
const D := preload("res://tools/city/pilot/pieces/rv_designs.gd")
const SITE := {"j": [-400.0, 200.0], "sx": 1.0, "sz": -1.0, "p0": 2.0, "pu": 2.0, "pv": 6.0, "puv": 4.0}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RV.new().build("r_q_m400_200_ne", SITE, D.get_design("V3"))
	quit()
