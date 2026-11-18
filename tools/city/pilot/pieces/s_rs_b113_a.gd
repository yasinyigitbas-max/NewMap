extends SceneTree
## Piece s_rs_b113_a (resstd road kit, 17 Nov): Block b113 (9th St, (0.0, -200.0) -> (250.0, -200.0), 250 m), the leg
## from end A at (0, -200) [amber junction, pad 6.0]: 9th St off Amber on the high street: like the pilot's 10th St,
## the downtown section (4 m walk to the building line 9.7, wells, marked stalls) runs from the Amber tile (23.5) to
## the alley at 44-50, then the street is residential with the pilot's double yellow carried on to the next junction.
## Height: the block rises +6.0 m from this end to the other (max grade 4.4 %). Joint: meets the leg from the other
## end at the seam (125.0 m).
## Built by road_resstd.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
const SPEC := {"z0": 23.5, "z1": 125.0, "start": "amber", "prof": [[23.5, 230.0, 6.0]], "alleys": [[44.0, 50.0]], "zones": [[23.5, 51.0, "hs", ""], [51.0, 125.0, "resc", ""]], "bus": false}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_rs_b113_a", SPEC)
	quit()
