extends SceneTree
## Piece j_rs_t_lll_b (resstd road kit, 17 Nov): T where a superblock (university campus, stadium) closes the street:
## all-way stop on three lined legs, the closed side is a straight kerb, parkway and walk with ramps where the two
## crosswalks land, a lamp opposite the stem lights the T's head. Canonical legs N/E/S/W = -LLL ('L' lined, 'r'
## residential, '-' closed). Sites: (-400, -600), (-400, -400).
## Built by road_resstd.gd junction (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.junction("j_rs_t_lll_b", "-LLL")
	quit()
