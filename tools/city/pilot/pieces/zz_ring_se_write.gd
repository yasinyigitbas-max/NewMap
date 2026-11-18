extends SceneTree
## Ring family half SE tool (not a piece): writes the review layout map_dc/coronado/city_kit/review/ring_se.json (every
## built SE ring piece at its grid position + the review offset [0, 0, -8000], the preview-only ground, context pieces)
## and the integration table review/ring_se_sites.json (site -> piece, grid pos, yaw, y) from the "rg" meta each piece
## saved. Usage: godot --path PV -s res://tools/city/pilot/pieces/zz_ring_se_write.gd -- piece1 piece2 ...
## The list includes the core stage's pieces that serve SE sites (s_rg_b131_1, ...): ring_se.json is the whole half,
## so do not load it together with the core's ring.json (those rows would be doubled).
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
const SE := preload("res://tools/city/pilot/pieces/road_rg_SE.gd")
const DIR := "res://map_dc/coronado/city_kit/pieces/"
const REV := "res://map_dc/coronado/city_kit/review/"
## pieces shown beside the SE ring pieces for context ONLY (review rows; their families / half NW build and own them).
## Positions: the grid sites at their pads (resstd / amber tables; W at its pad 1.35, ROADKIT_SPEC 6).
const CONTEXT := [
	{"piece": "j_res", "pos": [-800.0, 2.0, 200.0], "yaw": -90.0, "note": "context (resstd family, locked j_res): J Ave x 11th St; the core's stub s_rg_b009 starts at its south tile edge 20"},
	{"piece": "j_rs_4r_c", "pos": [-600.0, 4.0, 200.0], "yaw": 0.0, "note": "context (resstd family): G Ave x 11th St; stub b017 at 20"},
	{"piece": "j_rs_4r_d", "pos": [-400.0, 2.0, 200.0], "yaw": 180.0, "note": "context (resstd family): E Ave x 11th St; stub b027 at 20"},
	{"piece": "j_rs_1l3r_b", "pos": [-200.0, 2.0, 200.0], "yaw": -90.0, "note": "context (resstd family): C Ave x 11th St; stub b035 at 20"},
	{"piece": "j_am_11th", "pos": [0.0, 4.0, 200.0], "yaw": 0.0, "note": "context (amber family): Amber x 11th St; the core's stub s_rg_b045 at 17.5"},
	{"piece": "j_rs_2l2r_opp_a", "pos": [250.0, 6.0, 200.0], "yaw": -90.0, "note": "context (resstd family): B Ave x 11th St; stubs b055 (south, 20) and b130 (east, 20)"},
	{"piece": "j_rs_2l2r_adj_a", "pos": [500.0, 6.0, -800.0], "yaw": 180.0, "note": "context (resstd family): Adela x 6th St; stub b095 (east, 20)"},
	{"piece": "j_rs_3l1r_d", "pos": [500.0, 6.0, -600.0], "yaw": 180.0, "note": "context (resstd family): Adela x 7th St; stub b101 (east, 20)"},
	{"piece": "j_rs_2l2r_adj_a", "pos": [500.0, 6.0, -400.0], "yaw": 90.0, "note": "context (resstd family): Adela x 8th St; stub b107 (east, 20)"},
	{"piece": "j_rs_4r_e", "pos": [500.0, 8.0, -200.0], "yaw": 0.0, "note": "context (resstd family): Adela x 9th St; stub b115 (east, 20)"},
	{"piece": "j_rs_t_rrr_a", "pos": [500.0, 4.0, 0.0], "yaw": 180.0, "note": "context (resstd family): Adela x 10th St; stub b123 (east, 20)"},
	{"piece": "j_apt", "pos": [570.0, 1.35, 200.0], "yaw": 90.0, "note": "context: the waterfront sample W at its grid site (570, 200), yaw 90, pad 1.35"},
	{"piece": "s_wfd", "pos": [570.0, 1.35, 200.0], "yaw": 270.0, "note": "context: W's 11th St leg (west) to 100 m; s_rg_se_b130 ends at its end"},
	{"piece": "s_wfd", "pos": [570.0, 1.35, 200.0], "yaw": 180.0, "note": "context: W's north leg (the ring); the core's transition s_rg_b136_w starts at its end"},
	{"piece": "s_wfd", "pos": [570.0, 1.35, 200.0], "yaw": 0.0, "note": "context: W's south leg (the ring); the core's transition s_rg_b161_w ends at its end"},
	{"piece": "s_wf", "pos": [570.0, 1.35, 200.0], "yaw": 90.0, "note": "context: W's pier plaza leg into Glorietta Bay"}]
## ring pieces of the neighbouring half shown at the two boundaries (context: their rg meta gives the position)
const CONTEXT_RG := {"j_rg_w800_s289": "context (half NW boundary T, core-built): Ocean Blvd x J Ave; s_rg_b131_1 starts at its east tile edge",
	"j_rg_nw_e657_n800": "context (half NW boundary T): Glorietta Blvd x 6th St; s_rg_se_b140_2 ends at its south tile edge, s_rg_se_b095 at its stem"}
const GROUND := ["zz_ring_se_ground"]

func _init() -> void: _run.call_deferred()

func _row(p: String) -> Dictionary:
	if not ResourceLoader.exists(DIR + p + ".scn"): return {}
	var ps: PackedScene = load(DIR + p + ".scn")
	var n := ps.instantiate()
	var m: Dictionary = n.get_meta(&"rg", {})
	n.free()
	return m

func _run() -> void:
	SE.prepare()
	var rows: Array = []
	var sites: Array = []
	var args: Array = Array(OS.get_cmdline_user_args())
	args.append_array(GROUND)
	for p: String in args:
		if p.begins_with("zz_ring_"):
			rows.append({"piece": p, "pos": [0, 0, RG.REVIEW_OFS.z], "yaw": 0, "note": "PREVIEW ONLY ground (grid coordinates); never in the game"})
			continue
		var m := _row(p)
		if m.is_empty():
			push_error("no rg meta on " + p); continue
		var pos: Array = m["pos"]
		# full precision: neighbouring pieces were authored about these exact anchors (rounding would open cracks)
		rows.append({"piece": p, "pos": [float(pos[0]), float(pos[1]), float(pos[2]) + RG.REVIEW_OFS.z], "yaw": float(m["yaw"])})
		var row := m.duplicate(true)
		row["piece"] = p
		row["pos"] = [float(pos[0]), float(pos[1]), float(pos[2])]
		row["built_by"] = "half SE (road_rg_SE.gd over road_rg.gd)" if p.contains("_se_") else "core stage (road_rg.gd)"
		if row.has("s"): row["s"] = [snappedf(float(row["s"][0]), 0.001), snappedf(float(row["s"][1]), 0.001)]
		sites.append(row)
	for c: Dictionary in CONTEXT:
		rows.append({"piece": c["piece"], "pos": [c["pos"][0], c["pos"][1], float(c["pos"][2]) + RG.REVIEW_OFS.z], "yaw": c["yaw"], "note": c["note"]})
	for p: String in CONTEXT_RG:
		var m2 := _row(p)
		if m2.is_empty():
			push_warning("context piece missing: " + p); continue
		var q: Array = m2["pos"]
		rows.append({"piece": p, "pos": [float(q[0]), float(q[1]), float(q[2]) + RG.REVIEW_OFS.z], "yaw": float(m2["yaw"]), "note": CONTEXT_RG[p]})
	var out := {"note": "Ring family half SE (road kit groups 2-5, stage 2) review rows, 17 Nov: ring pieces in GRID coordinates (x = u, z = v) shifted by [0, 0, -8000], with the core stage's SE pieces, the preview-only ground and context pieces of the neighbouring families and of half NW at the two boundaries. Load ALONE with CITYKIT_LAYOUT_EXTRA=res://map_dc/coronado/city_kit/review/ring_se.json (not together with ring.json or ring_nw.json: the core's pieces and the boundary T's would be doubled).", "instances": rows}
	var f := FileAccess.open(REV + "ring_se.json", FileAccess.WRITE); f.store_string(JSON.stringify(out, " ") + "\n"); f.close()
	var tab := {"note": "Ring family half SE integration table (17 Nov, stage 2 site builder). pos = [u, y, v] in the GRID frame (x = u along 10th St ESE, z = v along Amber SSW, origin Amber x 10th; y = height); yaw in degrees (Godot: +z -> (sin yaw, cos yaw)). Boulevard pieces and T-junctions are authored in the grid frame about their anchor (yaw 0); stubs along +z from their lattice junction. Includes the core stage's pieces that serve SE sites (built_by). Built by tools/city/pilot/pieces/road_rg_SE.gd over road_rg.gd.",
		"half": "SE: every ring-owned site not in half NW (NW = v < -900 or u < -900, plus the ring node nearest the dividing line on each side: the J Ave T (-800, 288.7) and the 6th St T (657.3, -800)). This half meets NW at the J Ave T's east tile edge (s_rg_b131_1, core-built) and at the 6th St T's south tile edge (s_rg_se_b140_2); the stub b095 (6th St) to that T is SE.",
		"overrides": {"250.0,345.0": "bus stops both ways at B Ave x Ocean Blvd (the library's look-back rule left 667 m without a stop between Amber's signals and W; Yasin's approved rule: stops never more than ~330 m apart). b135 and b161 are laid out with it; b161 part 2 is therefore rebuilt here (s_rg_se_b161_2) and the core's example s_rg_b161_2 is superseded (its file is untouched, it is not in this table)",
			"b130": "11th St, B Ave -> W: the library's stub plan has no far T (W is a locked sample), built by road_rg_SE._build_b130: std section from j_rs_2l2r_opp_a's east tile edge 20 to W's west leg end (s_wfd, 100 m from W: z 220), the whole -4.65 m rise (6.0 -> W's pad 1.35, ROADKIT_SPEC 6) on one smoothstep, max 3.5 %, the eastbound far-side bus stop after B Ave",
			"stub starts": "measured 20.0 on every resstd junction (res section) and 17.5 on j_am_11th (hs): the library's SEC z0, no change"},
		"superseded": SE.CORE_SUPERSEDED,
		"not_served": [],
		"sites": sites}
	f = FileAccess.open(REV + "ring_se_sites.json", FileAccess.WRITE); f.store_string(JSON.stringify(tab, " ") + "\n"); f.close()
	print("RING_SE rows %d, sites %d" % [rows.size(), sites.size()])
	quit()
