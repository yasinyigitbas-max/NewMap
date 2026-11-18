extends SceneTree
## Piece s_rs_b093_b (resstd road kit, 17 Nov): Block b093 (6th St, (0.0, -800.0) -> (250.0, -800.0), 250 m), the leg
## from end B at (250, -800) [resstd junction, pad 6.0]: 6th St from the apartment junction toward the city centre: a
## std street with its bus stop to the alley (54-60), then the kerb builds out over 12 m and the sidewalk widens into
## the centre section. Height: flat. Joint: meets the leg from the other end at the seam (125.0 m).
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 20.0, "z1": 125.0, "start": "j", "prof": [], "alleys": [[54.0, 60.0]], "zones": [[20.0, 61.0, "std", "apt"], [61.0, 73.0, "taper", "std", "cc"], [73.0, 125.0, "cc", "apt"]], "bus": true}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b093_b", SPEC)
	quit()
