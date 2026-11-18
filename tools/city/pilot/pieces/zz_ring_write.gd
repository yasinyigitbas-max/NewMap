extends SceneTree
## Ring family tool (not a piece): writes the review layout map_dc/coronado/city_kit/review/ring.json (every built ring
## piece at its grid position + the review offset [0, 0, -8000], preview-only grounds, context pieces) and the
## integration table review/ring_sites.json (site -> piece, grid pos, yaw, y) from the "rg" meta each piece saved.
## Usage: godot --path PV -s res://tools/city/pilot/pieces/zz_ring_write.gd -- piece1 piece2 ...
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
const DIR := "res://map_dc/coronado/city_kit/pieces/"
const REV := "res://map_dc/coronado/city_kit/review/"
## locked pieces shown beside the ring pieces for context ONLY (review rows, never part of the ring family's output)
const CONTEXT := [{"piece": "j_res", "pos": [-800.0, 2.0, 200.0], "yaw": 0.0, "note": "context only: a residential crossroads where the J Ave stub starts (the resstd family builds the real one)"},
	{"piece": "j_ind", "pos": [-800.0, 2.0, -1400.0], "yaw": 0.0, "note": "context only: the locked industrial sample's junction (J Ave x 3rd St)"},
	{"piece": "s_ind", "pos": [-800.0, 2.0, -1400.0], "yaw": 180.0, "note": "context only: the sample's own J Ave leg toward 1st St (22-100 m); the ring stub b000 starts at its end"},
	{"piece": "j_apt", "pos": [570.0, 2.0, 200.0], "yaw": 90.0, "note": "context only: the waterfront sample W at its grid site (570, 200), yaw 90 (its layout rows turned by 90)"},
	{"piece": "s_wfd", "pos": [570.0, 2.0, 200.0], "yaw": 270.0, "note": "context only: W's 11th St leg (west)"},
	{"piece": "s_wfd", "pos": [570.0, 2.0, 200.0], "yaw": 180.0, "note": "context only: W's north leg (the ring), the transition s_rg_b136_w starts at its end"},
	{"piece": "s_wfd", "pos": [570.0, 2.0, 200.0], "yaw": 0.0, "note": "context only: W's south leg (the ring), the transition s_rg_b161_w ends at its end"},
	{"piece": "s_wf", "pos": [570.0, 2.0, 200.0], "yaw": 90.0, "note": "context only: W's pier plaza leg into Glorietta Bay"}]

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var rows: Array = []
	var sites: Array = []
	for p: String in OS.get_cmdline_user_args():
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
		if row.has("s"): row["s"] = [snappedf(float(row["s"][0]), 0.001), snappedf(float(row["s"][1]), 0.001)]
		sites.append(row)
	for c: Dictionary in CONTEXT:
		rows.append({"piece": c["piece"], "pos": [c["pos"][0], c["pos"][1], float(c["pos"][2]) + RG.REVIEW_OFS.z], "yaw": c["yaw"], "note": c["note"]})
	var gap := RG.bridge_gap()
	var out := {"note": "Ring family (road kit groups 2-5) review rows, 17 Nov: ring pieces in GRID coordinates (x = u, z = v) shifted by [0, 0, -8000]. Load with CITYKIT_LAYOUT_EXTRA=res://map_dc/coronado/city_kit/review/ring.json.", "instances": rows}
	var f := FileAccess.open(REV + "ring.json", FileAccess.WRITE); f.store_string(JSON.stringify(out, " ") + "\n"); f.close()
	var tab := {"note": "Ring family integration table (17 Nov, stage 1). pos = [u, y, v] in the GRID frame (x = u along 10th St ESE, z = v along Amber SSW, origin Amber x 10th; y = height); yaw in degrees (Godot: +z -> (sin yaw, cos yaw)). Boulevard pieces and T-junctions are authored in the grid frame about their anchor (yaw 0); stubs along +z from their lattice junction. Built by tools/city/pilot/pieces/road_rg.gd.",
		"bridge_gap": {"note": "45 m of ring left out for the hand-made bridge Y, centred on the bridge node (660, -1100): its two ends [u, y, v]", "ends": gap},
		"ferry_gap": {"note": "45 m of ring (1st St, block b145) left out for the hand-made ferry landing, centred where the ferry line leaves 1st St (350, -1600): its two ends [u, y, v]", "ends": RG.ferry_gap()},
		"sites": sites}
	f = FileAccess.open(REV + "ring_sites.json", FileAccess.WRITE); f.store_string(JSON.stringify(tab, " ") + "\n"); f.close()
	print("RING rows %d, sites %d, bridge gap %s" % [rows.size(), sites.size(), str(gap)])
	quit()
