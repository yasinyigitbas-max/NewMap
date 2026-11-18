extends SceneTree
## Piece s_rs_b109_a (resstd road kit, 17 Nov): Block b109 (9th St, (-800.0, -200.0) -> (-600.0, -200.0), 200 m), the
## leg from end A at (-800, -200) [resstd junction, pad 4.0]: 9th St, a residential street (mixed street trees, no
## centre line). Height: the block rises +2.0 m from this end to the other (max grade 1.9 %). Joint: meets the leg
## from the other end at the seam (100.0 m).
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 20.0, "z1": 100.0, "start": "j", "prof": [[20.0, 180.0, 2.0]], "alleys": [[54.0, 60.0]], "zones": [[20.0, 100.0, "res", ""]], "bus": false}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b109_a", SPEC)
	quit()
