extends SceneTree
## Piece s_rs_b120_a (resstd road kit, 17 Nov): Block b120 (10th St, (-200.0, 0.0) -> (0.0, 0.0), 200 m), the leg from
## end A at (-200, 0) [resstd junction, pad 4.0]: 10th St west from C Ave to the pilot: residential with the pilot's
## double yellow, then 16 m before the pilot's s_10th_w ends (u -56) the parkway gives way to the downtown walk and
## the property line eases from 9.2 to the building line 9.7. Height: flat. Joint: meets the locked None at 144 m.
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 20.0, "z1": 144.0, "start": "j", "prof": [], "alleys": [[54.0, 60.0]], "zones": [[20.0, 128.0, "resc", ""], [128.0, 140.0, "taper", "resc", "hs"], [140.0, 144.0, "hs", ""]], "bus": false}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b120_a", SPEC)
	quit()
