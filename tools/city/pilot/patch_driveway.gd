extends SceneTree
## Cut ONE driveway (a curb cut) into ONE saved street piece, without re-running its script (19 Nov, Yasin: "make the
## drive way, make sure the road is bit identical to before other than your addition", "make triple sure your changes
## dont effect any other road"). Pattern of split_props.gd: load the .scn, change only what is named, check that
## everything else is identical, refuse to save otherwise.
##
## The cut spans whole existing panels of the parkway (no triangle is split): the parkway's triangles lying between u0
## and u1 (world, the piece's layout transform) are taken out of the grass surface; their place is taken by new concrete
## triangles sloping from the walk's height at the walk edge down to the road's height at the kerb line (vertices
## appended to the concrete surface; the existing vertices are not touched); the kerb face's triangles in front of them
## are taken out of the curb surface; two curb returns (vertical triangles) close the cut's sides. The walk, the road,
## every other surface, the props, the wear decals: unchanged (checked below, array by array). The ground's collision is
## rebuilt from the new mesh (it is derived from it).
##   godot --headless --path . -s res://tools/city/pilot/patch_driveway.gd -- <piece> <u0> <u1> <v_walk> <v_kerb> [--save]
## (u0, u1: the cut's sides, exactly on existing panel lines; v_walk: the walk / parkway line; v_kerb: the kerb line)
const PIECES := "res://map_dc/coronado/city_kit/pieces/"
const LAYOUT := "res://map_dc/coronado/city_kit/city_grid_layout.json"
const EPS := 0.02

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var piece := String(a[0]); var u0 := float(a[1]); var u1 := float(a[2]); var vw := float(a[3]); var vk := float(a[4])
	var save := a.has("--save")
	var path := PIECES + piece + ".scn"
	var root: Node3D = (load(path) as PackedScene).instantiate()
	var lay: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
	var lxf := Transform3D()
	var found := 0
	for r: Dictionary in lay.instances:
		if r.piece == piece:
			lxf = Transform3D(Basis(Vector3.UP, deg_to_rad(float(r.yaw))), Vector3(r.pos[0], r.pos[1], r.pos[2])); found += 1
	if found != 1: print("PATCH refused: %s is in the layout %d times" % [piece, found]); quit(); return
	var gm: MeshInstance3D = root.get_node("ground")
	var xf := lxf * gm.transform; var ixf := xf.affine_inverse()
	var old: ArrayMesh = gm.mesh
	var names: Array = []
	for i in old.get_surface_count(): names.append(old.surface_get_material(i).resource_path.get_file())
	var si_grass := names.find("g_grass.tres"); var si_curb := names.find("g_curb.tres"); var si_conc := names.find("g_concrete.tres")
	var inside := func(p: Vector3) -> bool: return p.x > u0 - EPS and p.x < u1 + EPS and p.z > minf(vw, vk) - EPS and p.z < maxf(vw, vk) + EPS
	var arrs: Array = []
	for i in old.get_surface_count(): arrs.append(old.surface_get_arrays(i))
	# ---- take out the parkway's and the kerb face's triangles inside the cut
	var removed := {"grass": 0, "curb": 0}
	var walk_y := NAN; var road_y := NAN
	for si: int in [si_grass, si_curb]:
		var v: PackedVector3Array = arrs[si][Mesh.ARRAY_VERTEX]; var idx: PackedInt32Array = arrs[si][Mesh.ARRAY_INDEX]
		var keep := PackedInt32Array()
		for t in range(0, idx.size(), 3):
			var p0 := xf * v[idx[t]]; var p1 := xf * v[idx[t + 1]]; var p2 := xf * v[idx[t + 2]]
			if inside.call(p0) and inside.call(p1) and inside.call(p2):
				removed["grass" if si == si_grass else "curb"] += 1
				for p: Vector3 in [p0, p1, p2]:
					if si == si_grass: walk_y = p.y
					elif is_nan(road_y) or p.y < road_y: road_y = p.y
				continue
			keep.append_array([idx[t], idx[t + 1], idx[t + 2]])
		arrs[si][Mesh.ARRAY_INDEX] = keep
	print("PATCH removed grass tris %d, kerb face tris %d; walk %.3f road %.3f" % [removed.grass, removed.curb, walk_y, road_y])
	if removed.grass == 0 or removed.curb == 0: print("PATCH refused: nothing found in the cut"); quit(); return
	# ---- the apron (concrete) and the two returns (curb): new vertices appended, uv / tangent as the surface maps them
	var A := [Vector3(u0, walk_y, vw), Vector3(u1, walk_y, vw), Vector3(u1, road_y, vk), Vector3(u0, road_y, vk)]
	var up := Vector3.UP; var into0 := Vector3(1, 0, 0); var into1 := Vector3(-1, 0, 0)
	_append(arrs[si_conc], [[A[0], A[1], A[2], up], [A[0], A[2], A[3], up]], xf, ixf)
	_append(arrs[si_curb], [[Vector3(u0, walk_y, vw), Vector3(u0, walk_y, vk), Vector3(u0, road_y, vk), into0], [Vector3(u1, walk_y, vw), Vector3(u1, road_y, vk), Vector3(u1, walk_y, vk), into1]], xf, ixf)
	var nm := ArrayMesh.new()
	for i in old.get_surface_count():
		nm.add_surface_from_arrays(old.surface_get_primitive_type(i), arrs[i], [], {}, old.surface_get_format(i) & ~Mesh.ARRAY_FORMAT_VERTEX & ~Mesh.ARRAY_FORMAT_NORMAL & ~Mesh.ARRAY_FORMAT_TANGENT & ~Mesh.ARRAY_FORMAT_TEX_UV & ~Mesh.ARRAY_FORMAT_INDEX)
		nm.surface_set_material(i, old.surface_get_material(i))
	# ---- PROOF: every surface's vertices identical up to the old count; every old triangle outside the cut still there
	var bad := 0
	for i in old.get_surface_count():
		var oa := old.surface_get_arrays(i); var na := nm.surface_get_arrays(i)
		for k: int in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TANGENT, Mesh.ARRAY_TEX_UV]:
			if oa[k] == null: continue
			var o: Variant = oa[k]; var n: Variant = na[k]
			var ocount: int = (o as Array).size() if o is Array else o.size()
			var same := true
			for j in ocount:
				if o[j] != n[j]: same = false; break
			if not same: print("PATCH diff: surface %s array %d changed in its old part" % [names[i], k]); bad += 1
		var oi: PackedInt32Array = oa[Mesh.ARRAY_INDEX]; var ni: PackedInt32Array = na[Mesh.ARRAY_INDEX]
		var ov: PackedVector3Array = oa[Mesh.ARRAY_VERTEX]
		var nset := {}
		for t in range(0, ni.size(), 3): nset["%d,%d,%d" % [ni[t], ni[t + 1], ni[t + 2]]] = true
		for t in range(0, oi.size(), 3):
			var p0 := xf * ov[oi[t]]; var p1 := xf * ov[oi[t + 1]]; var p2 := xf * ov[oi[t + 2]]
			var cut: bool = (i == si_grass or i == si_curb) and inside.call(p0) and inside.call(p1) and inside.call(p2)
			if not cut and not nset.has("%d,%d,%d" % [oi[t], oi[t + 1], oi[t + 2]]): bad += 1
		if i != si_grass and i != si_curb and i != si_conc and oi != ni: print("PATCH diff: surface %s indices changed" % names[i]); bad += 1
	if bad > 0: print("PATCH refused: %d differences outside the cut" % bad); quit(); return
	# every node other than the ground and its collision: compared with the saved file, property by property
	var ref: Node3D = (load(path) as PackedScene).instantiate()
	gm.mesh = nm
	var col: StaticBody3D = root.get_node("ground_col")
	(col.get_child(0) as CollisionShape3D).shape = nm.create_trimesh_shape()
	var others := 0
	for c: Node in root.find_children("*", "", true, false):
		var rp := root.get_path_to(c)
		if String(rp).begins_with("ground"): continue
		var rc := ref.get_node_or_null(rp)
		if rc == null: print("PATCH diff: node %s missing" % rp); bad += 1; continue
		others += 1
		if c is MultiMeshInstance3D:
			if (c as MultiMeshInstance3D).multimesh.buffer != (rc as MultiMeshInstance3D).multimesh.buffer: print("PATCH diff: %s" % rp); bad += 1
		if c is MeshInstance3D:
			var m1: Mesh = c.mesh; var m2: Mesh = rc.mesh
			for i in m1.get_surface_count():
				if m1.surface_get_arrays(i) != m2.surface_get_arrays(i): print("PATCH diff: %s" % rp); bad += 1
		if c is Node3D and (c as Node3D).transform != (rc as Node3D).transform: print("PATCH diff: %s moved" % rp); bad += 1
	if bad > 0: print("PATCH refused: %d differences in other nodes" % bad); quit(); return
	print("PATCH ok: %d other nodes identical; ground: only the cut changed (+2 apron tris, +2 returns)" % others)
	if not save: print("PATCH dry run (add --save to write)"); quit(); return
	for c: Node in root.find_children("*", "", true, false): c.owner = root
	var ps := PackedScene.new(); ps.pack(root)
	var err := ResourceSaver.save(ps, path)
	print("PATCH saved %s: %s" % [path, error_string(err)])
	quit()

## append triangles (world points) to a surface: vertices in the mesh's frame, normal from the triangle, uv and tangent
## by the surface's own mapping (an affine fit of uv on world x / z from its existing vertices), indices at the end
func _append(arr: Array, tris: Array, xf: Transform3D, ixf: Transform3D) -> void:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]; var nrm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]; var tg: PackedFloat32Array = arr[Mesh.ARRAY_TANGENT] if arr[Mesh.ARRAY_TANGENT] != null else PackedFloat32Array()
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	# uv = a*x + b*z + c (per component), fitted on three existing non-collinear vertices
	var fit := _uv_fit(v, uv, xf)
	# the surface's own winding: the sign of the cross product's y on its up-facing triangles (as stored), in world
	var sref := 1.0
	for t0 in range(0, idx.size(), 3):
		var c0 := ((xf * v[idx[t0 + 1]]) - (xf * v[idx[t0]])).cross((xf * v[idx[t0 + 2]]) - (xf * v[idx[t0]]))
		var nn := (xf.basis * nrm[idx[t0]]).normalized()
		if c0.length() > 1e-4 and absf(nn.y) > 0.5:
			sref = signf(c0.dot(nn)); break
	for t: Array in tris:
		var D: Vector3 = t[3]
		var pts: Array = [t[0], t[1], t[2]]
		var c := ((pts[1] as Vector3) - (pts[0] as Vector3)).cross((pts[2] as Vector3) - (pts[0] as Vector3))
		if signf(c.dot(D)) != sref: pts = [t[0], t[2], t[1]]
		var n := c.normalized() if c.dot(D) > 0.0 else -c.normalized()
		var nl := (ixf.basis * n).normalized()
		var base := v.size()
		for p: Vector3 in pts:
			v.append(ixf * p); nrm.append(nl)
			uv.append(Vector2(fit[0] * p.x + fit[1] * p.z + fit[2], fit[3] * p.x + fit[4] * p.z + fit[5]) if absf(n.y) > 0.3 else Vector2(p.x + p.z, p.y))
			if tg.size() > 0: tg.append_array([tg[0], tg[1], tg[2], tg[3]])
		# the winding the surface uses: face up (or out of the cut for the returns), as the existing triangles
		idx.append_array([base, base + 1, base + 2])
	arr[Mesh.ARRAY_VERTEX] = v; arr[Mesh.ARRAY_NORMAL] = nrm; arr[Mesh.ARRAY_TEX_UV] = uv; arr[Mesh.ARRAY_INDEX] = idx
	if tg.size() > 0: arr[Mesh.ARRAY_TANGENT] = tg

func _uv_fit(v: PackedVector3Array, uv: PackedVector2Array, xf: Transform3D) -> Array:
	var p0 := xf * v[0]; var q0 := uv[0]
	for i in range(1, v.size()):
		for j in range(i + 1, mini(v.size(), i + 40)):
			var p1 := xf * v[i]; var p2 := xf * v[j]
			var d := (p1.x - p0.x) * (p2.z - p0.z) - (p2.x - p0.x) * (p1.z - p0.z)
			if absf(d) < 0.5: continue
			var q1 := uv[i]; var q2 := uv[j]
			var r := []
			for c in 2:
				var a1 := q1[c] - q0[c]; var a2 := q2[c] - q0[c]
				var ax := (a1 * (p2.z - p0.z) - a2 * (p1.z - p0.z)) / d
				var az := (a2 * (p1.x - p0.x) - a1 * (p2.x - p0.x)) / d
				r.append_array([ax, az, q0[c] - ax * p0.x - az * p0.z])
			return [r[0], r[1], r[2], r[3], r[4], r[5]]
	return [1.0, 0.0, 0.0, 0.0, 1.0, 0.0]
