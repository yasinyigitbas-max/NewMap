extends SceneTree
## Piece s_am_fill_cc (amber road kit, 17 Nov): FILLER, cc section, flat, z 97.5-100. The centre's's Amber legs end at
## 97.5 (measured); this 2.5 m piece takes each to the lattice mid-point where our leg from the next junction
## starts. Placed at the sample's junction, yaw 0 (south leg) and 180 (north leg): its section and the continued
## rhythms (median palm at 98, the departure lane's dash 98.5-101.5, a heritage lamp each side at 99) are the same at both ends.
## Built by road_amber.gd build_leg. Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_amber.gd")
const SPEC := {"sec": "cc", "z0": 97.5, "z1": 100.0, "lines": {"app": [], "dep": [[98.5, 100.0]]}, "prof": [], "nose": false, "palms": [98.0], "arrows": ["", ""], "age": "mid", "lamps": [[99.0, 1.0], [99.0, -1.0]]}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_am_fill_cc", SPEC)
	quit()
