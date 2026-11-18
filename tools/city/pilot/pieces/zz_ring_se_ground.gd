extends SceneTree
## PREVIEW ONLY (never in the game): grass round the whole of ring half SE (Ocean Blvd from the J Ave T to the waterfront
## W, both W transitions and W's land side at its pad 1.35, Glorietta Blvd from the 10th St T to the 6th St T, every
## stem following its stub's height, 11th St to W, the lattice junctions' surroundings), grid coordinates (layout row
## pos [0, 0, -8000]). See road_rg_SE.build_review_ground.
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
const SE := preload("res://tools/city/pilot/pieces/road_rg_SE.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var R := SE.prepare()
	var L: float = (R["path"] as RG.Path).length
	var nj: Dictionary = R["nodes"]["-800.0,288.7"]           # Ocean Blvd starts at the J Ave T (half NW's boundary piece)
	var tws: Dictionary = RG.w_plan("S")["tw"]
	var n10: Dictionary = R["nodes"]["626.5,0.0"]; var n6: Dictionary = R["nodes"]["657.3,-800.0"]
	var y := 1.35 + RG.KH - 0.04       # W's land side at its pad, 1 cm under the transitions' verges (no z-fight)
	SE.build_review_ground("zz_ring_se_ground", {
		"ring": [[float(nj["s"]) - float(nj["em"]), L + float(tws["sJ"])], [float(n10["s"]) - float(n10["em"]), float(n6["s"]) + float(n6["ep"])]],
		"stems": ["-800.0,288.7", "-600.0,302.0", "-400.0,315.3", "-200.0,328.0", "0.0,340.0", "250.0,345.0",
			"626.5,0.0", "647.0,-200.0", "652.0,-400.0", "654.7,-600.0", "657.3,-800.0"],
		"w": ["S", "N"], "b130": true,
		"rects": [[470.0, 140.0, 560.8, 190.8, y], [470.0, 209.2, 560.8, 260.0, y], [520.0, 100.0, 560.8, 140.0, y], [520.0, 260.0, 560.8, 300.0, y]],
		"boxes": [[-850.0, 150.0, 470.0, 420.0], [470.0, -40.0, 720.0, 420.0], [440.0, -850.0, 720.0, -40.0]]})
	quit()
