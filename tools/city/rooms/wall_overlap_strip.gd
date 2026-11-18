extends SceneTree
## Wall-mounted props that overlap each other (Yasin 18 Nov: "there are wall props overlapping each other"): in every
## strip room (interiors/rooms/g_strip_*.scn) and every strip growth piece (pieces/m_gr_*.scn), each prop that hangs on
## a wall (manifest mount "wall", or lifted more than 1.0 m) is tested against every other wall prop: same wall plane
## (facing within 20 deg, 0.3 m apart) and their spans along the wall and in height overlap. Prints WALL lines + a count.
##   xvfb-run -a godot --path . --rendering-method mobile --rendering-driver vulkan -s res://tools/city/rooms/wall_overlap_strip.gd
const K := preload("res://tools/city/pilot/kit_lib.gd")
var man := {}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	for f in DirAccess.get_files_at("res://assets/coronado_kit/props/"):
		if f.begins_with("manifest_") and f.ends_with(".json"):
			var v: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/coronado_kit/props/" + f))
			var items: Array = v if v is Array else (v as Dictionary).values()
			for e in items:
				if e is Dictionary and (e as Dictionary).has("file_base"): man[String(e.file_base)] = e
	var files: Array = []
	for f in DirAccess.get_files_at("res://map_dc/coronado/city_kit/interiors/rooms/"):
		if f.begins_with("g_strip_") and f.ends_with(".scn"): files.append("res://map_dc/coronado/city_kit/interiors/rooms/" + f)
	for f in DirAccess.get_files_at("res://map_dc/coronado/city_kit/pieces/"):
		if f.begins_with("m_gr_") and f.ends_with(".scn"): files.append("res://map_dc/coronado/city_kit/pieces/" + f)
	var total := 0
	for path: String in files:
		var n: Node3D = (load(path) as PackedScene).instantiate(); root.add_child(n)
		var items: Array = []     # [base, Transform3D (scene frame), w, h]
		var grounds: Array = []   # tall ground props: [base, Transform3D, w, d, h]
		for mmi: MultiMeshInstance3D in n.find_children("*", "MultiMeshInstance3D", true, false):
			var nm := String(mmi.name)
			var base := nm
			for suf in ["_near", "_mid", "_far"]:
				if nm.ends_with(suf): base = nm.trim_suffix(suf); base = base.substr(0, base.rfind("_"))
			if nm.ends_with("_mid") or nm.ends_with("_far"): continue
			if not base.begins_with("prop_") and not base.begins_with("plant_"): base = "prop_" + base
			var e: Dictionary = man.get(base, {})
			if e.is_empty(): continue
			var xf := _rel(mmi, n)
			for i in mmi.multimesh.instance_count:
				var t: Transform3D = xf * mmi.multimesh.get_instance_transform(i)
				var lift := t.origin.y - _floor_y(n, path)
				if String(e.get("mount", "ground")) != "wall" and not (lift > 1.0 and base in ["prop_poster_case", "prop_gallery_frame", "prop_menu_board", "prop_pegboard_wall"]):
					if float(e.get("height", 0.0)) > 1.2: grounds.append([base, t, float(e.get("footprint_w", 0.5)), float(e.get("footprint_d", 0.5)), float(e.get("height", 1.0))])
					continue
				items.append([base, t, float(e.get("footprint_w", 0.5)), float(e.get("height", 0.5))])
		var bad := 0
		if OS.get_environment("WALLDEBUG") == "1": print("WALLDBG %s %d wall props: %s" % [path.get_file(), items.size(), ", ".join(items.map(func(it: Array) -> String: return "%s@%.1f,%.1f,%.1f" % [it[0], (it[1] as Transform3D).origin.x, (it[1] as Transform3D).origin.y, (it[1] as Transform3D).origin.z]))])
		for a in items.size():
			for b in range(a + 1, items.size()):
				var A: Array = items[a]; var Bb: Array = items[b]
				var ta: Transform3D = A[1]; var tb: Transform3D = Bb[1]
				var fa := ta.basis.z.normalized(); var fb := tb.basis.z.normalized()
				if fa.dot(fb) < 0.94: continue
				var d := tb.origin - ta.origin
				if absf(d.dot(fa)) > 0.3: continue
				var side := Vector3(fa.z, 0, -fa.x)
				if absf(d.dot(side)) >= (float(A[2]) + float(Bb[2])) * 0.5 - 0.02: continue
				var ya0 := ta.origin.y; var yb0 := tb.origin.y
				if ya0 + float(A[3]) <= yb0 + 0.02 or yb0 + float(Bb[3]) <= ya0 + 0.02: continue
				print("WALL %s: %s at (%.2f, %.2f, %.2f) overlaps %s at (%.2f, %.2f, %.2f)" % [path.get_file(), A[0], ta.origin.x, ta.origin.y, ta.origin.z, Bb[0], tb.origin.x, tb.origin.y, tb.origin.z])
				bad += 1
		# a wall prop and a tall ground prop pushed against the same wall (a poster behind a fridge, a frame through a shelf)
		for A2: Array in items:
			var ta2: Transform3D = A2[1]; var fa2 := ta2.basis.z.normalized(); var side2 := Vector3(fa2.z, 0, -fa2.x)
			for G2: Array in grounds:
				var tg: Transform3D = G2[1]
				var d2 := tg.origin - ta2.origin
				var out := d2.dot(fa2)                  # how far in front of the wall prop's face the ground prop's centre is
				var gx := absf(tg.basis.x.normalized().dot(side2))
				var half_along := (float(G2[2]) * gx + float(G2[3]) * (1.0 - gx)) * 0.5
				var half_out := (float(G2[3]) * gx + float(G2[2]) * (1.0 - gx)) * 0.5
				if out < -0.1 or out - half_out > 0.15: continue
				if absf(d2.dot(side2)) >= float(A2[2]) * 0.5 + half_along - 0.02: continue
				if tg.origin.y + float(G2[4]) <= ta2.origin.y + 0.02: continue
				print("WALL %s: %s at (%.2f, %.2f, %.2f) is covered by %s at (%.2f, %.2f)" % [path.get_file(), A2[0], ta2.origin.x, ta2.origin.y, ta2.origin.z, G2[0], tg.origin.x, tg.origin.z])
				bad += 1
		total += bad
		n.queue_free()
	print("WALL_DONE %d overlaps" % total)
	quit()

func _rel(nd: Node3D, top: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY; var c: Node = nd
	while c != top and c is Node3D:
		t = (c as Node3D).transform * t; c = c.get_parent()
	return t

func _floor_y(n: Node3D, path: String) -> float:
	return float(n.get_meta(&"floor_y", 0.0)) if path.contains("/rooms/") else 0.0
