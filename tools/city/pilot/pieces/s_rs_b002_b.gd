extends SceneTree
## Piece s_rs_b002_b (resstd road kit, 17 Nov): Block b002 (J Ave, (-800.0, -1200.0) -> (-800.0, -1000.0), 200 m), the
## leg from end B at (-800, -1000) [resstd junction, pad 4.0]: J Ave, a std collector (grt dress). Height: the block
## rises -2.0 m from this end to the other (max grade 1.9 %). Joint: meets the leg from the other end at the seam
## (100.0 m).
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 20.0, "z1": 100.0, "start": "j", "prof": [[20.0, 174.0, -2.0]], "alleys": [[54.0, 60.0]], "zones": [[20.0, 100.0, "std", "grt"]], "bus": true}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b002_b", SPEC)
	quit()
