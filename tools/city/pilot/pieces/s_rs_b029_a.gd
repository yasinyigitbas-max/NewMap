extends SceneTree
## Piece s_rs_b029_a (resstd road kit, 17 Nov): Block b029 (C Ave, (-200.0, -1400.0) -> (-200.0, -1200.0), 200 m), the
## leg from end A at (-200, -1400) [art junction, pad 4.0]: C Ave, a std collector (apt dress). Height: the block
## rises +6.0 m from this end to the other (max grade 6.1 %). Joint: meets the leg from the other end at the seam
## (100.0 m).
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 26.0, "z1": 100.0, "start": "art", "prof": [[26.0, 174.0, 6.0]], "alleys": [[54.0, 60.0]], "zones": [[26.0, 100.0, "std", "apt"]], "bus": true}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b029_a", SPEC)
	quit()
