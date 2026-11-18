extends SceneTree
## Piece s_rs_b098_fill (resstd road kit, 17 Nov): 7th St between the civic sample (its s_civ leg ends at u -100) and
## the centre sample (s_cc_10th ends at u -56): the street enters the city centre here, so the kerb builds out over 12
## m (no parking in the centre) and the sidewalk widens to the centre's 6.4 m; flat (both pads 6.0)
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 100.0, "z1": 144.0, "start": "seam", "prof": [], "alleys": [], "zones": [[100.0, 112.0, "taper", "std", "cc"], [112.0, 144.0, "cc", "civ"]]}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b098_fill", SPEC)
	quit()
