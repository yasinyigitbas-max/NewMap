extends SceneTree
## Ring family half NW tool (not a piece): writes the review layout map_dc/coronado/city_kit/review/ring_nw.json (every
## built NW ring piece at its grid position + the review offset [0, 0, -8000], preview-only grounds, context pieces) and
## the integration table review/ring_nw_sites.json (site -> piece, grid pos, yaw, y) from the "rg" meta each piece saved.
## Usage: godot --path PV -s res://tools/city/pilot/pieces/zz_ring_nw_write.gd -- piece1 piece2 ...
## The list includes the core stage's pieces that serve NW sites (j_rg_w800_n1600, ...): ring_nw.json is the whole
## half, so do not load it together with the core's ring.json (those rows would be doubled).
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
const NW := preload("res://tools/city/pilot/pieces/road_rg_NW.gd")
const DIR := "res://map_dc/coronado/city_kit/pieces/"
const REV := "res://map_dc/coronado/city_kit/review/"
## pieces shown beside the NW ring pieces for context ONLY (review rows; their families build / own them). Positions are
## the grid sites at their pads (resstd / art / amber tables, the samples' snapped positions in streets.py SNAP).
const CONTEXT := [
	{"piece": "j_ind", "pos": [-800.0, 2.0, -1400.0], "yaw": 0.0, "note": "context: the locked industrial sample I's junction (J Ave x 3rd St)"},
	{"piece": "s_ind", "pos": [-800.0, 2.0, -1400.0], "yaw": 180.0, "note": "context: I's J Ave leg to 100 m; the core's stub s_rg_b000 starts at its end"},
	{"piece": "s_ind", "pos": [-800.0, 2.0, -1400.0], "yaw": -90.0, "note": "context: I's 3rd St (truck street) leg west to 100 m; s_rg_nw_b064 starts at its end"},
	{"piece": "j_strip", "pos": [500.0, 4.0, -1200.0], "yaw": 0.0, "note": "context: the locked strip sample M's junction (Adela x 4th St)"},
	{"piece": "s_strip_art", "pos": [500.0, 4.0, -1200.0], "yaw": 0.0, "note": "context: M's 4th St arterial leg east to 100 m; s_rg_nw_b079 continues it"},
	{"piece": "j_ar_g3", "pos": [-600.0, 2.0, -1400.0], "yaw": 0.0, "note": "context (art family): G Ave x 3rd St; stub b010 starts at its north tile edge 26"},
	{"piece": "j_ar_e3", "pos": [-400.0, 2.0, -1400.0], "yaw": 0.0, "note": "context (art family): E Ave x 3rd St; stub b018 at 26"},
	{"piece": "j_ar_c3", "pos": [-200.0, 4.0, -1400.0], "yaw": 0.0, "note": "context (art family): C Ave x 3rd St; stub b028 at 26"},
	{"piece": "j_am_3rd", "pos": [0.0, 8.0, -1400.0], "yaw": 0.0, "note": "context (amber family): Amber x 3rd St; stub b036 at 22.5"},
	{"piece": "j_ar_b3", "pos": [250.0, 2.0, -1400.0], "yaw": 0.0, "note": "context (art family): B Ave x 3rd St; stub b046 at 26"},
	{"piece": "j_ar_ad3", "pos": [500.0, 2.0, -1400.0], "yaw": 0.0, "note": "context (art family): Adela x 3rd St; stubs b056 (north, 26) and b071 (east, 22)"},
	{"piece": "j_ar_ad5", "pos": [500.0, 4.0, -1000.0], "yaw": 0.0, "note": "context (art family): Adela x 5th St; the core's stub s_rg_b087 (east, 22)"},
	{"piece": "j_ar_j4", "pos": [-800.0, 2.0, -1200.0], "yaw": 0.0, "note": "context (art family): J Ave x 4th St; stub b072 (west, 22)"},
	{"piece": "j_rs_3l1r_a", "pos": [-800.0, 4.0, -1000.0], "yaw": 90.0, "note": "context (resstd family): J Ave x 5th St; stub b080 (west, 20)"},
	{"piece": "j_rs_3l1r_a", "pos": [-800.0, 6.0, -800.0], "yaw": -90.0, "note": "context (resstd family): J Ave x 6th St; stub b088 (west, 20)"},
	{"piece": "j_rs_t_lll_a", "pos": [-800.0, 6.0, -600.0], "yaw": -90.0, "note": "context (resstd family): J Ave x 7th St; stub b096 (west, 20)"},
	{"piece": "j_rs_3l1r_b", "pos": [-800.0, 4.0, -400.0], "yaw": 90.0, "note": "context (resstd family): J Ave x 8th St; stub b102 (west, 20)"},
	{"piece": "j_res", "pos": [-800.0, 4.0, -200.0], "yaw": 90.0, "note": "context (resstd family, locked j_res): J Ave x 9th St; stub b108 (west, 20)"},
	{"piece": "j_res", "pos": [-800.0, 8.0, 0.0], "yaw": 0.0, "note": "context (resstd family, locked j_res): J Ave x 10th St; stub b116 (west, 20)"},
	{"piece": "j_rs_2l2r_adj_a", "pos": [500.0, 6.0, -800.0], "yaw": 180.0, "note": "context (resstd family): Adela x 6th St, where the SE half's stub b095 to the boundary T starts"}]
## the core's preview ground round the west end (b158 part 2, the 11th St T, b159, the J Ave T): ours stop at b158 part 1
const CORE_GROUND := ["zz_ring_ground_w"]

func _init() -> void: _run.call_deferred()

func _run() -> void:
	NW.prepare()
	var rows: Array = []
	var sites: Array = []
	var args: Array = Array(OS.get_cmdline_user_args())
	args.append_array(CORE_GROUND)
	for p: String in args:
		var ps: PackedScene = load(DIR + p + ".scn")
		var n := ps.instantiate()
		if p.begins_with("zz_ring_"):
			rows.append({"piece": p, "pos": [0, 0, RG.REVIEW_OFS.z], "yaw": 0, "note": "PREVIEW ONLY ground (grid coordinates); never in the game"})
			n.free(); continue
		var m: Dictionary = n.get_meta(&"rg", {})
		n.free()
		if m.is_empty():
			push_error("no rg meta on " + p); continue
		var pos: Array = m["pos"]
		# full precision: neighbouring pieces were authored about these exact anchors (rounding would open cracks)
		rows.append({"piece": p, "pos": [float(pos[0]), float(pos[1]), float(pos[2]) + RG.REVIEW_OFS.z], "yaw": float(m["yaw"])})
		var row := m.duplicate(true)
		row["piece"] = p
		row["pos"] = [float(pos[0]), float(pos[1]), float(pos[2])]
		row["built_by"] = "core stage (road_rg.gd)" if not p.contains("_nw_") else "half NW (road_rg_NW.gd over road_rg.gd)"
		if row.has("s"): row["s"] = [snappedf(float(row["s"][0]), 0.001), snappedf(float(row["s"][1]), 0.001)]
		sites.append(row)
	for c: Dictionary in CONTEXT:
		rows.append({"piece": c["piece"], "pos": [c["pos"][0], c["pos"][1], float(c["pos"][2]) + RG.REVIEW_OFS.z], "yaw": c["yaw"], "note": c["note"]})
	var out := {"note": "Ring family half NW (road kit groups 2-5, stage 2) review rows, 17 Nov: ring pieces in GRID coordinates (x = u, z = v) shifted by [0, 0, -8000], with the core stage's NW pieces, preview-only grounds and context pieces of the neighbouring families. Load ALONE with CITYKIT_LAYOUT_EXTRA=res://map_dc/coronado/city_kit/review/ring_nw.json (not together with ring.json: the core's NW pieces are in both).", "instances": rows}
	var f := FileAccess.open(REV + "ring_nw.json", FileAccess.WRITE); f.store_string(JSON.stringify(out, " ") + "\n"); f.close()
	var tab := {"note": "Ring family half NW integration table (17 Nov, stage 2 site builder). pos = [u, y, v] in the GRID frame (x = u along 10th St ESE, z = v along Amber SSW, origin Amber x 10th; y = height); yaw in degrees (Godot: +z -> (sin yaw, cos yaw)). Boulevard pieces and T-junctions are authored in the grid frame about their anchor (yaw 0); stubs along +z from their lattice junction. Includes the core stage's pieces that serve NW sites (built_by). Built by tools/city/pilot/pieces/road_rg_NW.gd over road_rg.gd.",
		"half": "NW: ring sites with v < -900 or u < -900, plus the boundary nodes nearest the dividing line on each side of it: the 6th St T (657.3, -800) with block b141 (east) and the J Ave T (-800, 288.7) with block b159 (west, core-built). Half SE meets this half at the 6th St T's south tile edge (b140) and at the J Ave T's east tile edge (b131).",
		"overrides": {"0.0,-1600.0": "stem 'hs' (Amber divided avenue, signals) instead of sites.json 'res': the amber family built Amber north of 3rd St as the divided avenue (j_am_3rd north mouth measured: kerb 11.5, walk 16); Amber crossings are signalised",
			"-950.9,-1400.0": "stem 'ind' (truck street, stop control) instead of 'couplet': the locked industrial sample's 3rd St leg is a truck street to 100 m; only 25 m remain to the ring",
			"b036": "stub built with road_amber.build_leg ('res' avenue section) from j_am_3rd's north tile edge 22.5",
			"b010 b018 b028 b046 b056": "stubs start at 26.0 (the art family's junction tile edge, measured), not the library's 20 / 22",
			"b079": "continues s_strip_art (M) from 100 with M's paint phases, then the approach to the ring T",
			"bus": "the bus-stop spacing rule was re-run after the two overrides: stops now at the Amber T (signals), E Ave, J Ave (1st St) instead of C Ave and G Ave; nodes outside NW unchanged"},
		"bridge_gap": {"note": "45 m of ring left out for the hand-made bridge Y, centred on the bridge node (660, -1100): its two ends [u, y, v]", "ends": RG.bridge_gap()},
		"ferry_gap": {"note": "45 m of ring (1st St, block b145) left out for the hand-made ferry landing, centred where the ferry line leaves 1st St (350, -1600): its two ends [u, y, v]", "ends": RG.ferry_gap()},
		"not_served": [{"site": "node 660.0,-1100.0", "why": "the bridge node: the bridge Y is a hand-made hero junction (45 m ring gap left)"},
			{"site": "node 1320.0,-940.0", "why": "the bridge end (hero piece)"},
			{"site": "b160", "why": "the bridge ramp (hero piece)"},
			{"site": "ferry landing on b145", "why": "hand-made hero piece (45 m ring gap left between s_rg_nw_b145_2 and _3)"}],
		"sites": sites}
	f = FileAccess.open(REV + "ring_nw_sites.json", FileAccess.WRITE); f.store_string(JSON.stringify(tab, " ") + "\n"); f.close()
	print("RING_NW rows %d, sites %d" % [rows.size(), sites.size()])
	quit()
