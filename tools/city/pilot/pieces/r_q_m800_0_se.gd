extends SceneTree
## Piece r_q_m800_0_se (residential growth, pilot area, 18 Nov): the SE quadrant of junction (-800, 0), design V2.
## Hill: pad 8.0 m; the block rises +4.0 m along u, -6.0 m along v (twist -2.0) - the quadrant follows it.
## Built by rv_lib.gd (every rule and its reason is there). Run once; never when locked.
const RV := preload("res://tools/city/pilot/pieces/rv_lib.gd")
const D := preload("res://tools/city/pilot/pieces/rv_designs.gd")
const SITE := {"j": [-800.0, 0.0], "sx": 1.0, "sz": 1.0, "p0": 8.0, "pu": 12.0, "pv": 2.0, "puv": 4.0}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RV.new().build("r_q_m800_0_se", SITE, D.get_design("V2"))
	quit()
