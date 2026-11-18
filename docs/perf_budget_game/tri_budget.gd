extends SceneTree
## black dc-test3.9: analytical per-group draw/tri budget (no per-group re-render). For each spot and 8 headings, every
## visible GeometryInstance3D whose AABB intersects the camera frustum, is inside its visibility range and matches the cull
## mask is counted: surfaces (~draws, x instances for MultiMesh), LOD0 triangles. Group = node path depth --depth (def 4).
## Lines "TB <spot> <group> n= draws= tris= shadow_tris=". --spots a,b filter.
var cache := {}
func _initialize() -> void: _run.call_deferred()
func _mesh_tris(m: Mesh) -> int:
	if m == null: return 0
	if cache.has(m): return cache[m]
	var t := 0
	if m is ArrayMesh or m is PrimitiveMesh:
		for s in m.get_surface_count():
			var a: Array = m.surface_get_arrays(s)
			var idx = a[Mesh.ARRAY_INDEX]; var v = a[Mesh.ARRAY_VERTEX]
			t += (idx.size() if idx != null and idx.size() > 0 else (v.size() if v != null else 0)) / 3
	cache[m] = t; return t
func _count(cam: Camera3D, geoms: Array, depth: int, acc: Dictionary) -> void:
	var planes := cam.get_frustum(); var cp := cam.global_position
	for g: GeometryInstance3D in geoms:
		if not is_instance_valid(g) or not g.is_visible_in_tree() or (g.layers & cam.cull_mask) == 0: continue
		var ab: AABB = g.global_transform * g.get_aabb()
		var out := false
		for pl: Plane in planes:
			var c := ab.get_center(); var e := ab.size * 0.5
			var r := absf(pl.normal.x) * e.x + absf(pl.normal.y) * e.y + absf(pl.normal.z) * e.z
			if pl.distance_to(c) > r: out = true; break
		if out: continue
		var d := ab.get_center().distance_to(cp)
		if g.visibility_range_end > 0.0 and d > g.visibility_range_end + g.visibility_range_end_margin: continue
		if g.visibility_range_begin > 0.0 and d < g.visibility_range_begin: continue
		var dr := 0; var tr := 0
		if g is MeshInstance3D and g.mesh:
			dr = g.mesh.get_surface_count(); tr = _mesh_tris(g.mesh)
		elif g is MultiMeshInstance3D and g.multimesh and g.multimesh.mesh:
			var n: int = g.multimesh.visible_instance_count if g.multimesh.visible_instance_count >= 0 else g.multimesh.instance_count
			dr = g.multimesh.mesh.get_surface_count(); tr = _mesh_tris(g.multimesh.mesh) * n
		else: continue
		var p := String(root.get_path_to(g)).split("/"); var k := "/".join(p.slice(0, mini(p.size() - 1, depth)))
		var a: Array = acc.get(k, [0, 0, 0, 0, {}])
		if not a[4].has(g): a[4][g] = true; a[0] += 1; a[1] += dr; a[2] += tr; a[3] += tr if g.cast_shadow else 0
		acc[k] = a
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var depth := int(args[args.find("--depth") + 1]) if "--depth" in args else 4
	var only: PackedStringArray = args[args.find("--spots") + 1].split(",") if "--spots" in args else PackedStringArray()
	create_timer(1500.0, true, false, true).timeout.connect(func() -> void: print("TB TIMEOUT"); quit(2))
	var sc: Node = load("res://test_coronado.tscn").instantiate(); root.add_child(sc)
	await process_frame
	var mm := root.get_node_or_null(^"MainMenu"); if mm and mm.is_open: mm.close()
	paused = false
	var pl: CharacterBody3D = sc.player
	var cam := Camera3D.new(); cam.fov = 70.0; cam.near = 0.1; cam.far = 2600.0; sc.add_child(cam); cam.current = true
	var hp := CoronadoHomeFlat.frame() * Vector3(0, 0, 0)
	var spots := [["hotel_del", -1730.0, 3720.0], ["residential_i_ave", -2095.0, 2380.0], ["downtown_orange_4th", -1286.0, 2347.0], ["downtown_orange_900", -1697.0, 3196.0], ["flat_ext", hp.x, hp.z]]
	for s in spots:
		if not only.is_empty() and not s[0] in only: continue
		var p := Vector3(s[1], CoronadoTerrain.height_at(s[1], s[2]), s[2])
		pl.global_position = p + Vector3(0, 0.3, 0)
		sc.world.update_streaming(Vector3(p.x, 0, p.z), true)
		for i in 90: await process_frame
		cam.global_position = p + Vector3(0, 1.7, 0)
		var geoms := root.find_children("*", "GeometryInstance3D", true, false)
		var acc := {}
		var tot := [0, 0]
		for h in 8:
			cam.rotation = Vector3(-0.05, h * TAU / 8.0, 0)
			await process_frame
			var R := RenderingServer
			tot[0] += R.get_rendering_info(R.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME); tot[1] += R.get_rendering_info(R.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
			_count(cam, geoms, depth, acc)
		var rows := []
		for k in acc: rows.append([acc[k][2] / 8, acc[k][1] / 8, acc[k][0], acc[k][3] / 8, k])
		rows.sort(); rows.reverse()
		print("TB %s RS_avg draws=%d prims=%d geoms=%d" % [s[0], tot[0] / 8, tot[1] / 8, geoms.size()])
		rows.sort_custom(func(x, y) -> bool: return x[1] > y[1])
		for r in rows.slice(0, 30): print("TB %s %s n=%d draws/head=%d tris/head=%d shadow_tris/head=%d" % [s[0], r[4], r[2], r[1], r[0], r[3]])
	quit(0)
