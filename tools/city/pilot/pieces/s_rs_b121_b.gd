extends SceneTree
## Piece s_rs_b121_b (resstd road kit, 17 Nov): Block b121 (10th St, (0.0, 0.0) -> (250.0, 0.0), 250 m), the leg from
## end B at (250, 0) [resstd junction, pad 10.0]: 10th St from B Ave west to the pilot's hill street (s_10th_e ends at
## x 150 at +5.9 m): the pilot's double yellow, and past the alley the parkway widens over 6 m to the pilot's 2 m
## (sidewalk 1.5 m) so the two meet exactly. Height: the block rises -6.0 m from this end to the other (max grade 8.0
## %). Joint: meets the locked None at 100 m.
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 20.0, "z1": 100.0, "start": "j", "prof": [[100.0, 210.0, -5.9], [20.0, 100.0, -0.1]], "alleys": [[54.0, 60.0]], "zones": [[20.0, 61.0, "resc", ""], [61.0, 67.0, "taper", "resc", "pres"], [67.0, 100.0, "pres", ""]], "bus": false}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b121_b", SPEC)
	quit()
