extends SceneTree
## Piece s_rs_b128_a (resstd road kit, 17 Nov): Block b128 (11th St, (-200.0, 200.0) -> (0.0, 200.0), 200 m), the leg
## from end A at (-200, 200) [resstd junction, pad 2.0]: 11th St from the residential junction toward the high street:
## residential, carrying the high street's double yellow (no centre line ends mid-block). Height: the block rises +2.0
## m from this end to the other (max grade 1.9 %). Joint: meets the leg from the other end at the seam (100.0 m).
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 20.0, "z1": 100.0, "start": "j", "prof": [[20.0, 176.5, 2.0]], "alleys": [[54.0, 60.0]], "zones": [[20.0, 100.0, "resc", ""]], "bus": false}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b128_a", SPEC)
	quit()
