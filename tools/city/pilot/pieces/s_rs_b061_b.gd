extends SceneTree
## Piece s_rs_b061_b (resstd road kit, 17 Nov): Block b061 (Adela Ave, (500.0, -600.0) -> (500.0, -400.0), 200 m), the
## leg from end B at (500, -400) [resstd junction, pad 6.0]: Adela Ave, a std collector (apt dress). Height: flat.
## Joint: meets the leg from the other end at the seam (100.0 m).
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 20.0, "z1": 100.0, "start": "j", "prof": [], "alleys": [[54.0, 60.0]], "zones": [[20.0, 100.0, "std", "apt"]], "bus": true}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b061_b", SPEC)
	quit()
