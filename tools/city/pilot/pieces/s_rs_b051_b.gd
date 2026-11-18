extends SceneTree
## Piece s_rs_b051_b (resstd road kit, 17 Nov): Block b051 (B Ave, (250.0, -600.0) -> (250.0, -400.0), 200 m), the leg
## from end B at (250, -400) [resstd junction, pad 8.0]: B Ave, a std collector (apt dress). Height: the block rises
## -2.0 m from this end to the other (max grade 3.8 %). Joint: meets the locked s_apt at 100 m.
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 20.0, "z1": 100.0, "start": "j", "prof": [[20.0, 100.0, -2.0]], "alleys": [[54.0, 60.0]], "zones": [[20.0, 100.0, "std", "apt"]], "bus": true}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b051_b", SPEC)
	quit()
