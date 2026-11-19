extends SceneTree
## Outdoor checks from Yasin's corrections (19 Nov, residential growth review; Yasin: "upgrade the checker with my
## corrections"). Works like validate.gd (one line per problem, then "LIFE n problems", exit 1 on any) and runs on the
## assembled layout. What it catches, each in his words:
##   pole      "utility poles are on asphalt": a utility pole standing on an asphalt / road-paint surface of any piece
##             (alleys and lots included; the validator's "street" rule only looks at street pieces)
##   path      "there is a trash bin in the middle of the way": a ground item standing on a narrow paved path (concrete
##             or paving with planting / lawn on both sides across it) in a block piece; street pieces are left to the
##             validator (their furniture zones are paved on purpose)
##   glass     "prop in the glass": a wall-mounted item (meter, mailbox, light, hose reel, dish, vine ...) hung over a window
##             or a door of its building, from the measured openings (interiors/room_contracts.json and
##             room_contracts_res.json; buildings with no measured model are skipped and counted). A window air
##             conditioner is the one item that belongs in a window.
##   fence     "this metal fence doesnt lead to anywhere" / "fences dont enclosure their back yard and dont touch their
##             back walls": a fence end that meets nothing - no other fence or gate within 0.35 m, no building wall
##             within 0.6 m, and no fence end facing it across an opening (a gate gap, a path or a drive: 0.8-6.5 m
##             away, on the same line)
## Not checked here (judgement, see the pictures): "parks are too empty" - the bark / play surfaces get a density
##   line per piece instead (play items per 100 m2 of play surface), printed as LIFE_INFO, not counted as problems.
## Options (after --): --only=PREFIX[,PREFIX]  check only pieces whose name starts with one of them (e.g. r_q_)
## Run (real renderer: MultiMesh data), repo root:
##   CITYKIT_LAYOUT_ONLY=1 CITYKIT_LAYOUT_EXTRA=res://map_dc/coronado/city_kit/city_grid_layout.json \
##   xvfb-run -a godot --path . --rendering-method mobile --rendering-driver vulkan -s res://tools/city/pilot/check_life.gd -- --only=r_q_
const K := preload("res://tools/city/pilot/kit_lib.gd")
const HARD := ["asphalt", "white", "yellow"]
const PAVED := ["concrete", "paving", "plaza"]
const SOFT := ["grass", "mulch", "gravel", "sand"]
var problems := 0
var tris := {}        # 4 m cell -> Array of [a, b, c (Vector2), material, piece]

func _init() -> void: _run.call_deferred()

func _report(kind: String, msg: String) -> void:
	problems += 1
	print("LIFE %-6s %s" % [kind, msg])

func _key(p: Vector2) -> Vector2i: return Vector2i(floori(p.x / 4.0), floori(p.y / 4.0))

## the ground material under a point (the highest surface hit), "" if none
func _mat(p: Vector2) -> String:
	var best := ""; var by := -INF
	for t: Array in tris.get(_key(p), []):
		if Geometry2D.point_is_inside_triangle(p, t[0], t[1], t[2]) and float(t[4]) > by: by = float(t[4]); best = String(t[3])
	return best

func _run() -> void:
	var only := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="): only = a.trim_prefix("--only=").split(",", false)
	var world := Node3D.new(); root.add_child(world)
	var nodes := K.place_layout(world)
	var props: Array = []      # [piece, base, pos Vector2, yaw, y over piece]
	var bldx: Array = []       # [Transform3D, folder, w, d] every building, for the glass rule
	var rcm := {}
	for f: String in ["room_contracts.json", "room_contracts_res.json"]:
		var pth := "res://map_dc/coronado/city_kit/interiors/" + f
		if FileAccess.file_exists(pth): rcm.merge(JSON.parse_string(FileAccess.get_file_as_string(pth)).models)
	var walls: Array = []      # building footprints [center, half, ang]
	for n: Node3D in nodes:
		var pname := String(n.get_meta(&"piece", n.name))
		for gm: MeshInstance3D in n.find_children("ground", "MeshInstance3D", true, false):
			var m := gm.mesh as ArrayMesh
			if m == null: continue
			var xf := gm.global_transform
			for si in m.get_surface_count():
				var mat := m.surface_get_name(si)
				var arr := m.surface_get_arrays(si)
				var vv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var ii: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
				var cnt := ii.size() if ii.size() > 0 else vv.size()
				for k in range(0, cnt, 3):
					var A := xf * vv[ii[k] if ii.size() > 0 else k]; var B := xf * vv[ii[k + 1] if ii.size() > 0 else k + 1]; var C := xf * vv[ii[k + 2] if ii.size() > 0 else k + 2]
					var a2 := Vector2(A.x, A.z); var b2 := Vector2(B.x, B.z); var c2 := Vector2(C.x, C.z)
					if absf((b2 - a2).cross(c2 - a2)) < 1e-4: continue      # walls, kerb faces
					var lo := Vector2(minf(a2.x, minf(b2.x, c2.x)), minf(a2.y, minf(b2.y, c2.y))); var hi := Vector2(maxf(a2.x, maxf(b2.x, c2.x)), maxf(a2.y, maxf(b2.y, c2.y)))
					for gx in range(floori(lo.x / 4.0), floori(hi.x / 4.0) + 1):
						for gz in range(floori(lo.y / 4.0), floori(hi.y / 4.0) + 1):
							var kk := Vector2i(gx, gz)
							if not tris.has(kk): tris[kk] = []
							(tris[kk] as Array).append([a2, b2, c2, mat, (A.y + B.y + C.y) / 3.0, pname])
		var bn := n.get_node_or_null("Buildings")
		if bn:
			for b: Node3D in bn.get_children():
				var st := K.building_stats(String(b.get_meta(&"kit", "")))
				if st.is_empty(): continue
				var gb := b.global_transform.basis
				walls.append([Vector2(b.global_position.x, b.global_position.z), Vector2(float(st.footprint_wd[0]), float(st.footprint_wd[1])) * 0.5, atan2(gb.z.x, gb.z.z)])
				bldx.append([b.global_transform, String(b.get_meta(&"kit", "")), float(st.footprint_wd[0]), float(st.footprint_wd[1]), pname])
		if not only.is_empty():
			var hit := false
			for pre: String in only:
				if pname.begins_with(pre): hit = true
			if not hit: continue
		for mmi: MultiMeshInstance3D in n.find_children("*_near", "MultiMeshInstance3D", true, false):
			var nm := String(mmi.name).trim_suffix("_near")
			var base := nm.substr(0, nm.rfind("_"))
			var mm := mmi.multimesh
			for i in mm.instance_count:
				var t := mmi.global_transform * mm.get_instance_transform(i)
				props.append([pname, base, Vector2(t.origin.x, t.origin.z), atan2(t.basis.x.z, t.basis.x.x), t.origin.y - n.global_position.y, t])
	print("LIFE loaded %d props, %d buildings" % [props.size(), walls.size()])
	# ---- pole on asphalt
	for p: Array in props:
		if not String(p[1]).begins_with("prop_utility_pole"): continue
		var m := _mat(p[2])
		if m in HARD: _report("pole", "%s %s at (%.1f, %.1f) stands on %s" % [p[0], p[1], (p[2] as Vector2).x, (p[2] as Vector2).y, m])
	# ---- wall item over a window or door ("prop in the glass")
	var nomodel := {}
	var bgrid := {}
	for i2 in bldx.size():
		var kb := _key(Vector2((bldx[i2][0] as Transform3D).origin.x, (bldx[i2][0] as Transform3D).origin.z))
		for gx3 in range(kb.x - 3, kb.x + 4):
			for gz3 in range(kb.y - 3, kb.y + 4):
				var kk3 := Vector2i(gx3, gz3)
				if not bgrid.has(kk3): bgrid[kk3] = []
				(bgrid[kk3] as Array).append(i2)
	for p: Array in props:
		var base3 := String(p[1])
		var e4 := K.manifest(base3)
		if String(e4.get("mount", "ground")) != "wall" or base3 == "prop_ac_window": continue
		var t5: Transform3D = p[5]
		for i3: int in bgrid.get(_key(p[2]), []):
			var bb: Array = bldx[i3]
			var lp3: Vector3 = (bb[0] as Transform3D).affine_inverse() * t5.origin
			var w3 := float(bb[2]); var d3 := float(bb[3])
			var fac := ""; var al := 0.0
			if absf(lp3.x) <= w3 * 0.5 + 0.1 and absf(absf(lp3.z) - d3 * 0.5) < 0.35: fac = "front" if lp3.z > 0.0 else "back"; al = lp3.x
			elif absf(lp3.z) <= d3 * 0.5 + 0.1 and absf(absf(lp3.x) - w3 * 0.5) < 0.35: fac = "right" if lp3.x > 0.0 else "left"; al = lp3.z
			if fac == "": continue
			if not rcm.has(String(bb[1])): nomodel[String(bb[1])] = true; break
			var hw3 := float(e4.get("footprint_w", 0.4)) * 0.5; var y0 := lp3.y; var y1 := lp3.y + float(e4.get("height", 0.4))
			for o: Dictionary in rcm[String(bb[1])].get("openings", []):
				if String(o.facade) != fac: continue
				if al - hw3 < float(o.along) + float(o.w) * 0.5 - 0.03 and al + hw3 > float(o.along) - float(o.w) * 0.5 + 0.03 and y0 < float(o.y1) - 0.03 and y1 > float(o.y0) + 0.03:
					_report("glass", "%s %s at (%.1f, %.1f) hangs over a %s of %s" % [p[0], base3, (p[2] as Vector2).x, (p[2] as Vector2).y, String(o.region).trim_prefix("O_"), bb[1]]); break
			break
	if not nomodel.is_empty(): print("LIFE_INFO glass: %d building models have no measured openings (not checked)" % nomodel.size())
	# ---- item in a narrow path (block pieces only)
	for p: Array in props:
		var pn := String(p[0]); var base := String(p[1])
		if pn.begins_with("j_") or pn.begins_with("s_"): continue
		if base.begins_with("fence_") or base.begins_with("tree_") or base.begins_with("palm_") or base.begins_with("prop_utility_pole") or base.begins_with("prop_lamp") or base.begins_with("prop_shade_sail"): continue
		var e := K.manifest(base)
		if String(e.get("mount", "ground")) != "ground" or float(p[4]) > 1.2: continue
		var c: Vector2 = p[2]
		if not (_mat(c) in PAVED): continue
		for ax: Vector2 in [Vector2(1, 0), Vector2(0, 1)]:
			var side_a := _mat(c + ax * 1.1); var side_b := _mat(c - ax * 1.1)
			var along_a := _mat(c + Vector2(ax.y, ax.x) * 1.5); var along_b := _mat(c - Vector2(ax.y, ax.x) * 1.5)
			if side_a in SOFT and side_b in SOFT and along_a in PAVED and along_b in PAVED:
				_report("path", "%s %s at (%.1f, %.1f) stands in a narrow path" % [pn, base, c.x, c.y]); break
	# ---- fence ends that meet nothing
	var ends: Array = []        # [pos, dir (unit, pointing out of the panel), piece, base]
	for p: Array in props:
		var base2 := String(p[1])
		if not base2.begins_with("fence_") or base2.contains("_post") or base2 == "fence_temp_fence_panel" or base2 == "fence_temp_fence_panel_screen": continue
		var e2 := K.manifest(base2)
		var hl := 0.5 * float(e2.get("footprint_w", 2.0))
		var t2: Transform3D = p[5]
		hl *= Vector2(t2.basis.x.x, t2.basis.x.z).length()      # a shortened panel (scaled along its length)
		var xd := Vector2(t2.basis.x.x, t2.basis.x.z).normalized()
		ends.append([(p[2] as Vector2) + xd * hl, xd, p[0], base2]); ends.append([(p[2] as Vector2) - xd * hl, -xd, p[0], base2])
	var grid := {}
	for i in ends.size():
		var k3 := _key(ends[i][0])
		if not grid.has(k3): grid[k3] = []
		(grid[k3] as Array).append(i)
	var nf := 0
	for i in ends.size():
		var e3: Array = ends[i]
		if only.size() > 0:
			var hit2 := false
			for pre2: String in only:
				if String(e3[2]).begins_with(pre2): hit2 = true
			if not hit2: continue
		var p0: Vector2 = e3[0]; var d0: Vector2 = e3[1]
		var ok := false
		var k0 := _key(p0)
		for gx2 in range(k0.x - 2, k0.x + 3):
			for gz2 in range(k0.y - 2, k0.y + 3):
				for j: int in grid.get(Vector2i(gx2, gz2), []):
					if j == i or (j ^ 1) == i: continue      # the panel's own other end
					var q: Vector2 = ends[j][0]
					var dd := q - p0
					# joined: the end touches another panel's line anywhere (a corner, a T where a return meets a
					# lot-line fence mid-panel, overlapping panels of a shortened run)
					var q2: Vector2 = ends[j ^ 1][0]
					var t4 := clampf((p0 - q).dot(q2 - q) / maxf((q2 - q).length_squared(), 1e-6), 0.0, 1.0)
					if p0.distance_to(q.lerp(q2, t4)) < 0.35: ok = true; break
					# an opening: the other end lies ahead on the same line, facing back
					if dd.length() < 6.5 and dd.length() > 0.5 and dd.normalized().dot(d0) > 0.97 and (ends[j][1] as Vector2).dot(d0) < -0.97: ok = true; break
				if ok: break
			if ok: break
		if not ok:
			for w: Array in walls:
				var lp := (p0 - (w[0] as Vector2)).rotated(float(w[2]))
				if absf(lp.x) < float((w[1] as Vector2).x) + 0.6 and absf(lp.y) < float((w[1] as Vector2).y) + 0.6: ok = true; break
		if not ok:
			nf += 1
			_report("fence", "%s %s end at (%.1f, %.1f) leads nowhere" % [e3[2], e3[3], p0.x, p0.y])
	# ---- information: how full the play areas are (bark surfaces)
	var play := {}
	for p2: Array in props:
		if String(p2[1]) in ["prop_play_structure", "prop_swing_set", "prop_slide"]: play[p2[0]] = int(play.get(p2[0], 0)) + 1
	for pc: String in play:
		print("LIFE_INFO %s play items %d" % [pc, play[pc]])
	print("LIFE %d problems" % problems)
	quit(1 if problems else 0)
