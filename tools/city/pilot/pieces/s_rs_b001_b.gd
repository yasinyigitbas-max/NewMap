extends SceneTree
## Piece s_rs_b001_b (resstd road kit, 17 Nov): Block b001 (J Ave, (-800.0, -1400.0) -> (-800.0, -1200.0), 200 m), the
## leg from end B at (-800, -1200) [art junction, pad 2.0]: J Ave from 4th St north to the industrial sample:
## residential at the junction, then the kerb steps out over 12 m to the truck street (s_ind: kerb 6.7, shoulder edge
## line, double yellow) whose leg it meets at 100 m; the centre and edge lines start where the truck street does (the
## road class changes there), never mid-air. Height: flat. Joint: meets the locked s_ind at 100 m.
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 26.0, "z1": 100.0, "start": "art", "prof": [], "alleys": [[54.0, 60.0]], "zones": [[26.0, 61.0, "res", ""], [61.0, 73.0, "taper", "res", "ind"], [73.0, 100.0, "ind", ""]], "bus": false}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b001_b", SPEC)
	quit()
