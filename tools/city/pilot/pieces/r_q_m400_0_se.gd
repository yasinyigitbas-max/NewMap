extends SceneTree
## Piece r_q_m400_0_se (residential growth, 18-19 Nov): the SE quadrant of junction (-400, 0), design V1.
## Hill: pad 6.0 m; the block rises -2.0 m along u, -4.0 m along v (twist +2.0) - the quadrant follows it.
## Built by rv_lib.gd (every rule and its reason is there). Run once; never when locked.
## Corner shop: r_shop_books (books), its room is in interiors/assignment_res.json.
const RV := preload("res://tools/city/pilot/pieces/rv_lib.gd")
const D := preload("res://tools/city/pilot/pieces/rv_designs.gd")
const SITE := {"j": [-400.0, 0.0], "sx": 1.0, "sz": 1.0, "p0": 6.0, "pu": 4.0, "pv": 2.0, "puv": 2.0, "Lu": 200.0, "Lv": 200.0, "shop": ["commercial/com_shallow_books", "r_shop_books", "books"]}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RV.new().build("r_q_m400_0_se", SITE, D.get_design("V1"))
	quit()
