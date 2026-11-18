extends SceneTree
## Piece r_q_m600_200_nw (residential growth, 18-19 Nov): the NW quadrant of junction (-600, 200), design V1.
## Hill: pad 4.0 m; the block rises -2.0 m along u, +8.0 m along v (twist -2.0) - the quadrant follows it.
## Built by rv_lib.gd (every rule and its reason is there). Run once; never when locked.
const RV := preload("res://tools/city/pilot/pieces/rv_lib.gd")
const D := preload("res://tools/city/pilot/pieces/rv_designs.gd")
const SITE := {"j": [-600.0, 200.0], "sx": -1.0, "sz": -1.0, "p0": 4.0, "pu": 2.0, "pv": 12.0, "puv": 8.0, "Lu": 200.0, "Lv": 200.0}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RV.new().build("r_q_m600_200_nw", SITE, D.get_design("V1"))
	quit()
