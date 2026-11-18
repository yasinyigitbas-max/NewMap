extends SceneTree
## Piece s_rs_b081_a (resstd road kit, 17 Nov): Block b081 (5th St, (-800.0, -1000.0) -> (-600.0, -1000.0), 200 m),
## the leg from end A at (-800, -1000) [resstd junction, pad 4.0]: 5th St, a std collector (grt dress). Height: the
## block rises +2.0 m from this end to the other (max grade 3.8 %). Joint: meets the locked s_grt at 100 m.
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 20.0, "z1": 100.0, "start": "j", "prof": [[20.0, 100.0, 2.0]], "alleys": [[54.0, 60.0]], "zones": [[20.0, 100.0, "std", "grt"]], "bus": true}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b081_a", SPEC)
	quit()
