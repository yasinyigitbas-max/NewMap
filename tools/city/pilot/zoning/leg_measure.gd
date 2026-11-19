extends SceneTree
## Measures, for every lattice junction leg of the assembled city, the street piece's real cross-section as BUILT
## (19 Nov, residential roll-out: quadrants beside other street sections). For each leg row of city_grid_layout.json
## (s_* pieces placed at a junction, local +z along the leg): the property line (the outer edge of its walk, from the
## piece's own ground mesh, as the largest |x| of the ground between z 30 and 95 on each side) and whether it has an
## alley apron at 54-60 m (a paved strip through the parkway there). Writes zoning/legs_measured.json, read by
## res_zone.py. Read-only on the pieces. Real renderer not needed:
##   CITYKIT_LAYOUT_ONLY=1 CITYKIT_LAYOUT_EXTRA=res://map_dc/coronado/city_kit/city_grid_layout.json godot --headless --path . -s res://tools/city/pilot/zoning/leg_measure.gd
const K := preload("res://tools/city/pilot/kit_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var rows: Array = (JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/city_grid_layout.json")) as Dictionary).instances
	var out: Array = []
	var cache := {}
	for r: Dictionary in rows:
		var pc := String(r.piece)
		if not pc.begins_with("s_"): continue
		var p: Array = r.pos
		if absf(fmod(absf(float(p[2])), 200.0)) > 0.5: continue        # leg rows sit at a lattice junction (v multiple of 200)
		if not cache.has(pc):
			var path := "res://map_dc/coronado/city_kit/pieces/%s.scn" % pc
			if not ResourceLoader.exists(path): continue
			var n: Node = (load(path) as PackedScene).instantiate()
			var info := {"prop": [0.0, 0.0], "apron": [false, false]}
			for gm: MeshInstance3D in n.find_children("ground", "MeshInstance3D", true, false):
				var m := gm.mesh as ArrayMesh
				for si in m.get_surface_count():
					var mat := m.surface_get_name(si)
					var vv: PackedVector3Array = m.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]
					for v: Vector3 in vv:
						var q := gm.transform * v
						if q.z < 30.0 or q.z > 95.0: continue
						var side := 1 if q.x > 0.0 else 0
						if absf(q.x) < 25.0: info.prop[side] = maxf(float(info.prop[side]), absf(q.x))
						if mat == "concrete" and q.z > 54.5 and q.z < 59.5 and absf(q.x) > 6.0 and absf(q.x) < 7.0: info.apron[side] = true
			n.free()
			cache[pc] = info
		var yaw := float(r.get("yaw", 0.0))
		var fwd := Vector2(sin(deg_to_rad(yaw)), cos(deg_to_rad(yaw)))     # local +z in the grid frame
		var c: Dictionary = cache[pc]
		out.append({"piece": pc, "u": float(p[0]), "v": float(p[2]), "dir": [snappedf(fwd.x, 0.001), snappedf(fwd.y, 0.001)],
			"prop_left": snappedf(float(c.prop[0]), 0.01), "prop_right": snappedf(float(c.prop[1]), 0.01), "apron_left": c.apron[0], "apron_right": c.apron[1]})
	var fo := FileAccess.open("res://map_dc/coronado/city_kit/zoning/legs_measured.json", FileAccess.WRITE)
	fo.store_string(JSON.stringify({"_doc": "leg_measure.gd: the street legs as built (property line per side = outer edge of the walk, m from the centre line; apron = paved alley mouth at 54-60 m). left = local -x, right = local +x of the piece (local +z along the leg).", "legs": out}, " ")); fo.close()
	print("LEGS %d" % out.size())
	quit()
