extends SceneTree
## Piece s_rs_b023_b (resstd road kit, 17 Nov): Block b023 (E Ave, (-400.0, -600.0) -> (-400.0, -400.0), 200 m), the
## leg from end B at (-400, -400) [resstd junction, pad 6.0]: E Ave, a std collector (civ dress); E Ave is the civic
## band's palm avenue: queen palms, planted in one go. Height: flat. Joint: meets the leg from the other end at the
## seam (100.0 m).
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 20.0, "z1": 100.0, "start": "j", "prof": [], "alleys": [[54.0, 60.0]], "zones": [[20.0, 100.0, "std", "civ"]], "bus": true, "trees": ["palm_queen_a", "palm_queen_b"]}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b023_b", SPEC)
	quit()
