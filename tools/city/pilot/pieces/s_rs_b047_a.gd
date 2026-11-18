extends SceneTree
## Piece s_rs_b047_a (resstd road kit, 17 Nov): Block b047 (B Ave, (250.0, -1400.0) -> (250.0, -1200.0), 200 m), the
## leg from end A at (250, -1400) [art junction, pad 2.0]: B Ave, a residential street (mixed street trees, no centre
## line). Height: the block rises +6.0 m from this end to the other (max grade 6.1 %). Joint: meets the leg from the
## other end at the seam (100.0 m).
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 26.0, "z1": 100.0, "start": "art", "prof": [[26.0, 174.0, 6.0]], "alleys": [[54.0, 60.0]], "zones": [[26.0, 100.0, "res", ""]], "bus": false}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b047_a", SPEC)
	quit()
