extends SceneTree
## PREVIEW ONLY (never in the game): grass round the ring review cluster at the waterfront W (Ocean Blvd's last piece,
## both W transitions, W's own locked street pieces placed for context, the 10th St T on the curve), grid coordinates
## (layout row pos [0, 0, -8000]). See road_rg.build_review_ground.
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var R := RG.ring()
	var pl: Array = RG.block_plan("b161")
	var s0: float = pl[pl.size() - 1]["s0"]; var s1: float = pl[pl.size() - 1]["s1"]
	var y := 2.0 + RG.KH - 0.03
	# W's surroundings west of its north / south legs and its 11th St leg (the bay lies east: left open for the water)
	RG.build_review_ground("zz_ring_ground_wt", {"ring": [s0, s1], "w": ["S", "N"],
		"rects": [[470.0, 140.0, 560.8, 190.8, y], [470.0, 209.2, 560.8, 260.0, y], [520.0, 100.0, 560.8, 140.0, y], [520.0, 260.0, 560.8, 300.0, y]],
		"box": [430.0, -60.0, 589.0, 380.0]})
	quit()
