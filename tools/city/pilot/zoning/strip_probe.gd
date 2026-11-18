extends SceneTree
## What the streets round the strip's growth blocks offer at their frontages (claude/grow-strip, 18 Nov): along every
## frontage line of the commercial strip zone, the ground surface found in the street pieces just inside the property
## line (concrete = a driveway apron or a corner walk, grass = parkway), so lot driveways line up with the aprons the
## road kit already built; and the street furniture within 4 m of the property line (lamps, hydrants, bus stops, trees)
## so nothing of a lot lands next to them by accident. Read-only. Prints PROBE lines (grid u, v).
##   xvfb-run -a godot --path . --rendering-method mobile --rendering-driver vulkan -s res://tools/city/pilot/zoning/strip_probe.gd
const LAYOUT := "res://map_dc/coronado/city_kit/city_grid_layout.json"
# frontage lines: name, a (u, v), b (u, v), the offset toward the street (du, dv) at which the parkway is sampled
const LINES := [
	["5th St east N side", Vector2(508.7, -1014.3), Vector2(645.7, -1014.3), Vector2(0, 3.0)],
	["5th St west N side", Vector2(400.0, -1009.2), Vector2(491.3, -1009.2), Vector2(0, 1.5)],
	["Adela S leg E side", Vector2(508.7, -1100.0), Vector2(508.7, -1014.3), Vector2(-1.5, 0)],
	["Adela S leg W side", Vector2(491.3, -1100.0), Vector2(491.3, -1009.2), Vector2(1.5, 0)],
	["ring W side S of 4th", Vector2(645.7, -1185.7), Vector2(645.7, -1014.3), Vector2(3.0, 0)],
	["ring W side N of 4th", Vector2(645.7, -1385.7), Vector2(645.7, -1214.3), Vector2(3.0, 0)],
	["4th St E S side", Vector2(600.0, -1185.7), Vector2(645.7, -1185.7), Vector2(0, -3.0)],
	["4th St E N side", Vector2(600.0, -1214.3), Vector2(645.7, -1214.3), Vector2(0, 3.0)],
	["3rd St S side", Vector2(400.0, -1385.7), Vector2(645.7, -1385.7), Vector2(0, -3.0)],
	["Adela N leg E side", Vector2(508.7, -1385.7), Vector2(508.7, -1300.0), Vector2(-1.5, 0)],
	["Adela N leg W side", Vector2(491.3, -1385.7), Vector2(491.3, -1300.0), Vector2(1.5, 0)],
]

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT)).instances
	var tris := {}        # surface name -> Array of [a, b, c] (world)
	var furn: Array = []
	for r: Dictionary in rows:
		var p: Array = r.pos
		if float(p[0]) < 300.0 or float(p[0]) > 760.0 or float(p[2]) < -1500.0 or float(p[2]) > -900.0: continue
		var nm := String(r.piece)
		if not (nm.begins_with("s_") or nm.begins_with("j_")): continue
		var n: Node3D = (load("res://map_dc/coronado/city_kit/pieces/%s.scn" % nm) as PackedScene).instantiate()
		n.position = Vector3(float(p[0]), float(p[1]), float(p[2])); n.rotation_degrees.y = float(r.yaw)
		root.add_child(n)
		for gm: MeshInstance3D in n.find_children("ground", "MeshInstance3D", true, false):
			var xf := gm.global_transform
			var m := gm.mesh as ArrayMesh
			for si in m.get_surface_count():
				var sn := m.surface_get_name(si)
				var arr := m.surface_get_arrays(si)
				var vv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]; var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
				if not tris.has(sn): tris[sn] = []
				for k in range(0, ix.size(), 3):
					tris[sn].append([xf * vv[ix[k]], xf * vv[ix[k + 1]], xf * vv[ix[k + 2]]])
		for mmi: MultiMeshInstance3D in n.find_children("*_near", "MultiMeshInstance3D", true, false):
			var base := String(mmi.name).trim_suffix("_near"); base = base.substr(0, base.rfind("_"))
			for i in mmi.multimesh.instance_count:
				var t := mmi.global_transform * mmi.multimesh.get_instance_transform(i)
				furn.append([base, t.origin, nm])
	for ln: Array in LINES:
		var a: Vector2 = ln[1]; var b: Vector2 = ln[2]; var off: Vector2 = ln[3]
		var Ln := a.distance_to(b); var runs: Array = []; var cur := ""; var s0 := 0.0
		var s := 0.0
		while s <= Ln:
			var q := a.lerp(b, s / Ln) + off
			var m := _surf(tris, q)
			if m != cur:
				if cur != "": runs.append("%s %.1f-%.1f" % [cur, s0, s - 0.5])
				cur = m; s0 = s
			s += 0.5
		runs.append("%s %.1f-%.1f" % [cur, s0, Ln])
		print("PROBE %s (%.1f,%.1f)->(%.1f,%.1f): %s" % [ln[0], a.x, a.y, b.x, b.y, ", ".join(runs)])
		for f: Array in furn:
			var o: Vector3 = f[1]
			var p2 := Vector2(o.x, o.z)
			var t := clampf((p2 - a).dot(b - a) / (Ln * Ln), 0.0, 1.0)
			var d := p2.distance_to(a.lerp(b, t))
			if d < 4.0 and not String(f[0]).begins_with("prop_manhole") and not String(f[0]).contains("storm_drain") and not String(f[0]).contains("wheel"):
				print("PROBE   furn %s at s %.1f, %.1f m off (%s)" % [f[0], t * Ln, d, f[2]])
	quit()

func _surf(tris: Dictionary, q: Vector2) -> String:
	for sn: String in tris:
		for tr: Array in tris[sn]:
			var a: Vector3 = tr[0]; var b: Vector3 = tr[1]; var c: Vector3 = tr[2]
			if absf((b - a).cross(c - a).normalized().y) < 0.5: continue
			if Geometry2D.point_is_inside_triangle(q, Vector2(a.x, a.z), Vector2(b.x, b.z), Vector2(c.x, c.z)): return sn
	return "none"
