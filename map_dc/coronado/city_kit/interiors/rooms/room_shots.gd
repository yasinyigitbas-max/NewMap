extends SceneTree
## Preview shots of kit rooms in their buildings (17 Nov, interiors session). Loads the city-kit layout, opens each
## room's doorway in its building (preview only: the door quad of the near mesh is dropped in memory, the locked piece
## files are not touched - the game will cut doors at bake time, PLAN.md section 3), places the room with the
## building's transform and shoots: from the street through the open door, and inside. Prints draws / primitives.
## godot --path <preview> --rendering-method mobile -s res://map_dc/coronado/city_kit/interiors/rooms/room_shots.gd -- --out=DIR
const K := preload("res://tools/city/pilot/kit_lib.gd")
const D := "res://map_dc/coronado/city_kit/interiors/"
## room scene, piece, building label, door region
## + two inside cameras per room in the building's model frame: [from, to] (back of the room, a corner)
const ROOMS := [["wf_cafe", "f_ne", "seaside_cafe", "O_shopdoor", [Vector3(-0.9, 1.7, -1.3), Vector3(0.8, 1.0, 5.5)], [Vector3(2.3, 2.0, 5.7), Vector3(-0.5, 0.9, -3.5)]],
	["wf_beach_shop", "f_nw", "surf_shop", "O_shopdoor", [Vector3(3.0, 1.8, -3.0), Vector3(-2.5, 1.0, 4.5)], [Vector3(-3.8, 2.0, 5.8), Vector3(2.0, 0.8, -3.0)]],
	["wf_marina_office", "f_se", "marina_office", "O_civic_door", [Vector3(5.5, 2.1, -3.0), Vector3(-3.0, 1.2, 3.5)], [Vector3(-5.8, 2.4, 3.8), Vector3(3.0, 1.2, -3.0)]],
	["wf_harbor_office", "f_ne", "civ_harbor_office", "O_civic_door", [Vector3(6.8, 2.2, -4.9), Vector3(-2.0, 1.2, 3.5)], [Vector3(-6.9, 2.4, 4.9), Vector3(3.0, 1.0, -3.0)]],
	["cv_library", "v_ne", "library", "O_civic_door", [Vector3(9.5, 2.3, -6.8), Vector3(-3.0, 1.2, 5.0)], [Vector3(-10.8, 2.4, 6.6), Vector3(4.0, 1.0, -4.0)]],
	["cv_city_hall", "v_ne", "city_hall", "O_civic_door", [Vector3(10.5, 2.2, -6.4), Vector3(-2.0, 1.2, 4.0)], [Vector3(-11.8, 2.4, 6.2), Vector3(3.0, 1.0, -3.0)]],
	["cv_rec_center", "v_nw", "rec_center", "O_civic_door", [Vector3(-10.5, 2.3, -5.8), Vector3(5.0, 1.0, 3.0)], [Vector3(10.8, 2.4, 5.6), Vector3(-4.0, 1.0, -3.0)]],
	["cv_police", "v_se", "police", "O_civic_door", [Vector3(9.8, 2.2, 5.6), Vector3(-3.0, 1.2, 1.5)], [Vector3(-9.8, 2.4, 0.0), Vector3(5.0, 1.0, -5.0)]],
	["ap_corner_market", "a_ne", "corner_market", "O_shopdoor", [Vector3(-5.0, 2.1, -6.0), Vector3(2.0, 1.0, 5.0)], [Vector3(5.0, 2.2, 5.6), Vector3(-3.0, 1.0, -4.0)], 1.08],
	["ap_laundromat", "a_nw", "laundromat", "O_shopdoor", [Vector3(1.0, 2.1, -5.0), Vector3(4.0, 1.0, 4.5)], [Vector3(5.1, 2.2, 4.9), Vector3(1.5, 1.0, -4.5)], 4.6,
		[["dryers", Vector3(1.6, 1.6, 4.2), Vector3(5.2, 0.7, -0.6)], ["washers", Vector3(4.3, 1.6, 4.2), Vector3(0.5, 0.7, -0.6)]]],
	["ap_corner_bar", "a_se", "corner_bar", "O_shopdoor", [Vector3(-3.5, 2.0, -3.0), Vector3(2.0, 1.0, 5.5)], [Vector3(3.6, 2.1, 5.8), Vector3(-2.0, 1.0, -2.5)]],
	["ap_corner_cafe", "a_sw", "corner_cafe", "O_shopdoor", [Vector3(0.6, 1.9, -3.0), Vector3(4.5, 1.0, 5.0)], [Vector3(5.2, 2.0, 5.9), Vector3(0.8, 1.0, -2.5)], 4.9]]
var out := "user://room_shots"
var only: PackedStringArray = []   # --only=room,room

func _init() -> void: _run.call_deferred()

func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
		if a.begins_with("--only="): only = a.trim_prefix("--only=").split(",")
	DirAccess.make_dir_recursive_absolute(out)
	var env := Environment.new()
	var sky := Sky.new(); var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = Color(0.32, 0.52, 0.82); psm.sky_horizon_color = Color(0.72, 0.8, 0.88)
	sky.sky_material = psm; env.background_mode = Environment.BG_SKY; env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.62, 0.64, 0.68); env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-48, -35, 0); sun.light_energy = 1.25; sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 120.0; root.add_child(sun)
	var world := Node3D.new(); world.name = "World"; root.add_child(world)
	var pieces := K.place_layout(world)
	var gp := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(4000, 4000); gp.mesh = pm
	var gm := StandardMaterial3D.new(); gm.albedo_color = Color(0.36, 0.42, 0.3); gp.material_override = gm; gp.position.y = -0.05
	world.add_child(gp)
	# water (as the city-kit preview draws it; the ground plane is cut round it)
	var wrects: Array = []
	for pc: Node in world.find_children("*", "Node3D", true, false):
		if not pc.has_meta(&"water"): continue
		var o := (pc as Node3D).global_position
		for e: Array in pc.get_meta(&"water"): wrects.append([o.x + float(e[0]), o.z + float(e[1]), o.x + float(e[2]), o.z + float(e[3]), o.y + float(e[4])])
	if not wrects.is_empty():
		var wm := StandardMaterial3D.new(); wm.albedo_color = Color(0.07, 0.24, 0.25); wm.roughness = 0.12
		var hb := Rect2(Vector2(wrects[0][0], wrects[0][1]), Vector2.ZERO)
		for r: Array in wrects:
			var wq := MeshInstance3D.new(); var qm := PlaneMesh.new(); qm.size = Vector2(float(r[2]) - float(r[0]), float(r[3]) - float(r[1])); wq.mesh = qm
			wq.position = Vector3((float(r[0]) + float(r[2])) * 0.5, float(r[4]), (float(r[1]) + float(r[3])) * 0.5); wq.material_override = wm; world.add_child(wq)
			hb = hb.expand(Vector2(r[0], r[1])).expand(Vector2(r[2], r[3]))
		var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var L := -2000.0; var Rr := 2000.0
		for q: Rect2 in [Rect2(L, L, Rr - L, hb.position.y - L), Rect2(L, hb.end.y, Rr - L, Rr - hb.end.y), Rect2(L, hb.position.y, hb.position.x - L, hb.size.y), Rect2(hb.end.x, hb.position.y, Rr - hb.end.x, hb.size.y)]:
			var p0 := Vector3(q.position.x, 0, q.position.y); var p1 := Vector3(q.end.x, 0, q.position.y); var p2 := Vector3(q.end.x, 0, q.end.y); var p3 := Vector3(q.position.x, 0, q.end.y)
			for v: Vector3 in [p0, p1, p2, p0, p2, p3]: st.set_normal(Vector3.UP); st.add_vertex(v)
		gp.mesh = st.commit(); gm.cull_mode = BaseMaterial3D.CULL_DISABLED
	var regs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/coronado_kit/textures/city_layout.json")).regions
	var rc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(D + "room_contracts.json")).models
	var cam := Camera3D.new(); cam.fov = 62.0; cam.near = 0.05; cam.far = 1500.0; root.add_child(cam)
	var shots: Array = []
	for rr: Array in ROOMS:
		if not only.is_empty() and not only.has(String(rr[0])): continue
		var bld: Node3D = null
		for n: Node3D in pieces:
			if String(n.get_meta(&"piece")) != String(rr[1]): continue
			var b := n.get_node_or_null("Buildings/" + String(rr[2])) as Node3D
			if b: bld = b
		if bld == null: print("RS no building ", rr); continue
		var model := String(bld.get_meta(&"kit")) if bld.has_meta(&"kit") else ""
		var door: Dictionary = _front_door(rc, model, String(rr[3]), float(rr[6]) if rr.size() > 6 else INF)
		_open_ground_floor(bld, regs, rc[model], room_meta(String(rr[0])))
		var room: Node3D = (load(D + "rooms/" + String(rr[0]) + ".scn") as PackedScene).instantiate()
		room.transform = bld.global_transform
		world.add_child(room)
		# cameras in the building's frame: street (through the door), at the door looking in, back corner looking out
		var xf := bld.global_transform
		var dx := float(door.along); var dz := float(door.plane); var fy := float(door.y0)
		var c: Dictionary = rc[model]; var fw: Array = c.footprint_wd
		var hw := float(fw[0]) * 0.5 - 0.6; var back := -float(fw[1]) * 0.5 + 0.9
		var views := [["street", Vector3(dx + 1.2, fy + 1.6, dz + 5.0), Vector3(dx, fy + 1.3, dz - 4.0)],
			["door", Vector3(dx, fy + 1.65, dz - 0.6), Vector3(dx * 0.4, fy + 1.0, back)],
			["back", rr[4][0], rr[4][1]], ["corner", rr[5][0], rr[5][1]],
			["front", Vector3(dx * 0.6 + 0.6, fy + 1.7, dz + 9.0), Vector3(dx * 0.6 + 0.6, fy + 1.4, dz - 3.0)],
			["doorclose", Vector3(dx + 1.6, fy + 1.6, dz + 2.2), Vector3(dx, fy + 1.2, dz)],
			["swing", Vector3(dx + 2.6, fy + 1.7, dz + 3.4), Vector3(dx, fy + 1.1, dz)],
			["swingout", Vector3(dx - 1.2, fy + 1.7, dz - 2.6), Vector3(dx + 0.3, fy + 1.1, dz + 1.0)]]
		for o: Dictionary in c.openings:
			if int(o.floor) == 0 and String(o.facade) == "front" and (String(o.region) == "O_storefront" or String(o.region) == "O_civic_win"):
				var e1 := float(o.along) + float(o.w) * 0.5
				views.append(["edge", Vector3(e1 + 1.4, float(o.y0) + 1.5, float(o.plane) + 1.8), Vector3(e1 - 0.2, float(o.y0) + 1.3, float(o.plane))])
				break
		if rr.size() > 7:
			for ev: Array in rr[7]: views.append(ev)
		for v: Array in views:
			cam.global_position = xf * (v[1] as Vector3); cam.look_at(xf * (v[2] as Vector3))
			# the doors: held shut for every view but "swing", where they stand 75 % open (the preview cannot walk)
			for lf: Node in room.find_children("DoorLeaf_*", "Node3D", false, false):
				if lf.get_script() != null:
					lf.set("amount", 0.0); lf.set("force_open", 0.75 if String(v[0]).begins_with("swing") else 0.0)
			for i in 40: await process_frame
			await RenderingServer.frame_post_draw
			var p := out.path_join("%s_%s.png" % [rr[0], v[0]])
			root.get_viewport().get_texture().get_image().save_png(p); shots.append(p)
			print("RS %s_%s draws=%d prims=%d" % [rr[0], v[0], RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])
		# the room's own cost
		var tris := 0; var draws := 0
		for gi: GeometryInstance3D in room.find_children("*", "GeometryInstance3D", true, false):
			var m: Mesh = (gi as MeshInstance3D).mesh if gi is MeshInstance3D else ((gi as MultiMeshInstance3D).multimesh.mesh if gi is MultiMeshInstance3D else null)
			var cnt := (gi as MultiMeshInstance3D).multimesh.instance_count if gi is MultiMeshInstance3D else 1
			if m == null: continue
			draws += m.get_surface_count()
			tris += (m.get_faces().size() / 3) * cnt
		print("RS_ROOM %s draws=%d tris=%d lights=%d" % [rr[0], draws, tris, room.get_node("Lights").get_child_count()])
	quit()

func _front_door(rc: Dictionary, model: String, region: String, along := INF) -> Dictionary:
	for o: Dictionary in (rc[model] as Dictionary).openings:
		if String(o.region) == region and String(o.facade) == "front" and int(o.floor) == 0 and (along == INF or absf(float(o.along) - along) < 0.1): return o
	return {}

## preview only: drop the near mesh's ground-floor door and window panels (triangles mapped into an opening region,
## inside that opening's rectangle) in memory; the room supplies frames, glass and reveals there. The game cuts the
## same openings at bake time (PLAN.md section 3); the locked piece files are not touched.
const OPEN := ["O_shopdoor", "O_civic_door", "O_storefront", "O_win_", "O_glass_plain", "O_civic_win", "O_small_"]
func room_meta(name: String) -> Array:
	var rn: Node = (load(D + "rooms/" + name + ".scn") as PackedScene).instantiate()
	var c: Array = rn.get_meta(&"cut", [])
	rn.free()
	return c

func _open_ground_floor(bld: Node3D, regs: Dictionary, contract: Dictionary, cut: Array = []) -> void:
	var near := bld.get_node_or_null("near") as MeshInstance3D
	if near == null: return
	var ops: Array = []
	for o: Dictionary in contract.openings:
		if int(o.floor) != 0: continue
		if not OPEN.any(func(p: String) -> bool: return String(o.region).begins_with(p)): continue
		if not regs.has(o.region): continue
		if not cut.is_empty() and not cut.any(func(c: Array) -> bool: return String(c[0]) == String(o.facade) and absf(float(c[1]) - float(o.along)) < 0.05): continue
		ops.append(o)
	var src: Mesh = near.mesh
	var am := ArrayMesh.new(); var dropped := 0
	for si in src.get_surface_count():
		var a := src.surface_get_arrays(si)
		var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]; var t: PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
		var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
		var keep := PackedInt32Array()
		for k in idx.size() / 3:
			var i0 := idx[k * 3]; var i1 := idx[k * 3 + 1]; var i2 := idx[k * 3 + 2]
			var cu := (t[i0] + t[i1] + t[i2]) / 3.0; cu.x = fposmod(cu.x, 1.0)
			var cp := near.transform * ((v[i0] + v[i1] + v[i2]) / 3.0)
			var drop := false
			for o: Dictionary in ops:
				var uv: Array = regs[o.region].uv
				if not (cu.x >= float(uv[0]) and cu.x <= float(uv[2]) and cu.y >= float(uv[1]) and cu.y <= float(uv[3])): continue
				var fr := String(o.facade) == "front" or String(o.facade) == "back"
				var along := cp.x if fr else cp.z; var pl := cp.z if fr else cp.x
				if absf(along - float(o.along)) <= float(o.w) * 0.5 + 0.05 and cp.y >= float(o.y0) - 0.05 and cp.y <= float(o.y1) + 0.05 and absf(pl - float(o.plane)) < 0.3: drop = true; break
			if drop: dropped += 1; continue
			keep.append(i0); keep.append(i1); keep.append(i2)
		a[Mesh.ARRAY_INDEX] = keep
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
		am.surface_set_material(si, src.surface_get_material(si))
	near.mesh = am
	print("RS opened %s: %d openings, %d triangles dropped" % [bld.name, ops.size(), dropped])
