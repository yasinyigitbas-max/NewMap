extends SceneTree
## Piece s_rs_b100_b (resstd road kit, 17 Nov): Block b100 (7th St, (250.0, -600.0) -> (500.0, -600.0), 250 m), the
## leg from end B at (500, -600) [resstd junction, pad 6.0]: 7th St, a std collector (apt dress). Height: flat. Joint:
## meets the locked s_apt at 150 m.
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 20.0, "z1": 150.0, "start": "j", "prof": [], "alleys": [[54.0, 60.0]], "zones": [[20.0, 150.0, "std", "apt"]], "bus": true}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b100_b", SPEC)
	quit()
