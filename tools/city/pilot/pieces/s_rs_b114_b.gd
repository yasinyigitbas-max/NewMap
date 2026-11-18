extends SceneTree
## Piece s_rs_b114_b (resstd road kit, 17 Nov): Block b114 (9th St, (250.0, -200.0) -> (500.0, -200.0), 250 m), the
## leg from end B at (500, -200) [resstd junction, pad 8.0]: 9th St, a residential street (mixed street trees, no
## centre line). Height: the block rises +4.0 m from this end to the other (max grade 2.9 %). Joint: meets the leg
## from the other end at the seam (125.0 m).
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 20.0, "z1": 125.0, "start": "j", "prof": [[20.0, 230.0, 4.0]], "alleys": [[54.0, 60.0]], "zones": [[20.0, 125.0, "res", ""]], "bus": false}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b114_b", SPEC)
	quit()
