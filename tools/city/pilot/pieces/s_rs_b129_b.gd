extends SceneTree
## Piece s_rs_b129_b (resstd road kit, 17 Nov): Block b129 (11th St, (0.0, 200.0) -> (250.0, 200.0), 250 m), the leg
## from end B at (250, 200) [resstd junction, pad 6.0]: 11th St from the residential junction toward the high street:
## residential, carrying the high street's double yellow (no centre line ends mid-block). Height: the block rises -2.0
## m from this end to the other (max grade 1.5 %). Joint: meets the leg from the other end at the seam (125.0 m).
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 20.0, "z1": 125.0, "start": "j", "prof": [[20.0, 226.5, -2.0]], "alleys": [[54.0, 60.0]], "zones": [[20.0, 125.0, "resc", ""]], "bus": false}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b129_b", SPEC)
	quit()
