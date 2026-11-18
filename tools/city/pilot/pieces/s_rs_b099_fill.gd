extends SceneTree
## Piece s_rs_b099_fill (resstd road kit, 17 Nov): 7th St between the centre sample (s_cc_10th ends at u 56) and the
## apartment sample (s_apt from B Ave ends at u 150): the centre section continues to the apartment band, then the
## kerb steps back over 12 m to give the apartments their parking lane and parkway; flat
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 56.0, "z1": 150.0, "start": "seam", "prof": [], "alleys": [], "zones": [[56.0, 136.0, "cc", "apt"], [136.0, 148.0, "taper", "cc", "std"], [148.0, 150.0, "std", "apt"]]}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b099_fill", SPEC)
	quit()
