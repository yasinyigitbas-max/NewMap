extends SceneTree
## Piece s_rs_b004_a (resstd road kit, 17 Nov): Block b004 (J Ave, (-800.0, -800.0) -> (-800.0, -600.0), 200 m), the
## leg from end A at (-800, -800) [resstd junction, pad 6.0]: J Ave, a std collector (civ dress); the campus edge
## streets carry the native torrey pine. Height: flat. Joint: meets the leg from the other end at the seam (100.0 m).
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 20.0, "z1": 100.0, "start": "j", "prof": [], "alleys": [[54.0, 60.0]], "zones": [[20.0, 100.0, "std", "civ"]], "bus": true, "trees": ["tree_torrey_pine_a", "tree_torrey_pine_b"]}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b004_a", SPEC)
	quit()
