extends SceneTree
## Piece s_rs_b032_a (resstd road kit, 17 Nov): Block b032 (C Ave, (-200.0, -800.0) -> (-200.0, -600.0), 200 m), the
## leg from end A at (-200, -800) [resstd junction, pad 6.0]: C Ave, a std collector (civ dress); C Ave keeps the
## civic sample's magnolias. Height: flat. Joint: meets the locked s_civ at 100 m.
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 20.0, "z1": 100.0, "start": "j", "prof": [], "alleys": [[54.0, 60.0]], "zones": [[20.0, 100.0, "std", "civ"]], "bus": true, "trees": ["tree_magnolia_a", "tree_magnolia_b"]}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b032_a", SPEC)
	quit()
