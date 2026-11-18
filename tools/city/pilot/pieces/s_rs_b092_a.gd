extends SceneTree
## Piece s_rs_b092_a (resstd road kit, 17 Nov): Block b092 (6th St, (-200.0, -800.0) -> (0.0, -800.0), 200 m), the leg
## from end A at (-200, -800) [resstd junction, pad 6.0]: 6th St from the civic junction toward the city centre: a std
## street with its bus stop to the alley (54-60), then the kerb builds out over 12 m and the sidewalk widens into the
## centre section. Height: flat. Joint: meets the leg from the other end at the seam (100.0 m).
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 20.0, "z1": 100.0, "start": "j", "prof": [], "alleys": [[54.0, 60.0]], "zones": [[20.0, 61.0, "std", "civ"], [61.0, 73.0, "taper", "std", "cc"], [73.0, 100.0, "cc", "civ"]], "bus": true, "trees": ["tree_jacaranda_a", "tree_jacaranda_b"]}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b092_a", SPEC)
	quit()
