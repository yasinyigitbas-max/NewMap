extends SceneTree
## Built-in interior pilot shots (22 Nov 2026): Crownado Savings (com_bank in n_hs_b2_amber) with the kit's new near,
## its filled room, glass, doors and the breakable window, in the real piece. Writes PNGs + shots.json (draws / tris
## with the interior on and off) to --out=DIR. Run with a renderer:
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --path . -s res://tools/city/rooms/builtin/shots_bank.gd -- --out=/workspace/share/shop_interiors/pilot
const BL := preload("res://tools/city/rooms/builtin/builtin_lib.gd")
const BS := preload("res://tools/city/rooms/builtin/break_state.gd")
const MODEL := "commercial/com_bank"
const KIT_MAT := "res://map_dc/coronado/city_kit/materials/bw_city_color_65.tres"
var out := "/workspace/share/shop_interiors/pilot"
var cam: Camera3D
var bank: Node3D
var room: Node3D
var info := {}

func _init() -> void: _run.call_deferred()

func _shot(nm: String, eye_l: Vector3, look_l: Vector3, fov := 62.0) -> void:
	cam.fov = fov
	cam.global_position = bank.global_transform * eye_l
	cam.look_at(bank.global_transform * look_l)
	for k in 8: await process_frame
	await RenderingServer.frame_post_draw
	var im := root.get_viewport().get_texture().get_image(); im.convert(Image.FORMAT_RGB8)
	im.save_png(out + "/" + nm + ".png")
	var d := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var t := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	info[nm] = {"draws": d, "prims": t}
	print("SHOT ", nm, " draws=", d, " prims=", t)

func _measure(nm: String, eye_l: Vector3, look_l: Vector3) -> Dictionary:
	cam.global_position = bank.global_transform * eye_l; cam.look_at(bank.global_transform * look_l)
	for k in 6: await process_frame
	await RenderingServer.frame_post_draw
	return {"draws": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), "prims": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)}

func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	create_timer(560.0).timeout.connect(func() -> void: print("SHOTS watchdog"); quit(2))
	BS.clear_all()
	var contract: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/interiors/room_contracts.json")).models[MODEL]
	var probs := BL.validate(MODEL, ["bank"], contract)
	print("VALIDATE ", probs.size(), " problems"); for p in probs: print("  ", p)
	# world
	var env := Environment.new(); env.background_mode = Environment.BG_SKY
	var sky := Sky.new(); var psm := ProceduralSkyMaterial.new(); sky.sky_material = psm; env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY; env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-42, -30, 0); sun.light_energy = 1.2; sun.shadow_enabled = true; root.add_child(sun)
	cam = Camera3D.new(); cam.far = 2000.0; root.add_child(cam); cam.current = true
	var piece: Node3D = (load("res://map_dc/coronado/city_kit/pieces/n_hs_b2_amber.scn") as PackedScene).instantiate()
	root.add_child(piece)
	bank = piece.find_child("bank", true, false) as Node3D
	var near := bank.get_node("near") as MeshInstance3D
	var old_near: Mesh = near.mesh
	near.mesh = BL.near_mesh(MODEL)
	# the kit's building material (bldg_wear, the source of the runtime rt_bldg one) - the glb's own material is
	# Godot's glTF StandardMaterial (the importer is broken on the box, so the near is read with GLTFDocument)
	near.material_override = load(KIT_MAT)
	near.visibility_range_end = 0.0      # (the shots measure the near at every distance; the far switch is the glass's own)
	for t in ["mid", "far"]: (bank.get_node(t) as Node3D).visible = false
	room = BL.fill(MODEL, "bank", "bi_hs_b2_amber_bank_0", "n_hs_b2_amber|bank")
	if room == null: print("ROOM fill failed"); quit(1); return
	bank.add_child(room)
	print("ROOM props: ", room.get_node("Props").get_child_count(), " types")
	var ptris := 0; var pinst := 0
	for mmi: MultiMeshInstance3D in room.get_node("Props").get_children():
		ptris += mmi.multimesh.mesh.get_faces().size() / 3 * mmi.multimesh.instance_count; pinst += mmi.multimesh.instance_count
	info["room"] = {"prop_types": room.get_node("Props").get_child_count(), "prop_instances": pinst, "prop_tris": ptris,
		"glass_tris": ((room.get_node("Glass") as MeshInstance3D).mesh.get_faces().size() / 3), "lights": room.get_node("Lights").get_child_count(), "validate": probs}
	print("ROOM ", info.room)
	var doors := room.get_node("Doors").get_children()
	var win := room.get_node("Windows").get_child(0)
	if OS.get_cmdline_user_args().has("--acne"):
		for g: Node in root.find_children("*", "GeometryInstance3D", true, false):
			var gi := g as GeometryInstance3D
			if not gi.is_visible_in_tree(): continue
			var o := gi.global_position - bank.global_position
			if Vector2(o.x, o.z).length() < 12.0: print("GEOM ", gi.get_path(), " ", gi.get_class(), " ", o, " ov=", gi.material_override)
		print("NEAR ov=", near.material_override)
		await _shot("x_acne_shadow_on", Vector3(0.3, 1.6, 5.6), Vector3(0.0, 1.2, -3.0), 75.0)
		sun.shadow_enabled = false
		await _shot("x_acne_shadow_off", Vector3(0.3, 1.6, 5.6), Vector3(0.0, 1.2, -3.0), 75.0)
		near.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; sun.shadow_enabled = true
		await _shot("x_acne_near_noshadowcast", Vector3(0.3, 1.6, 5.6), Vector3(0.0, 1.2, -3.0), 75.0)
		var m0: Material = near.material_override if near.material_override else near.mesh.surface_get_material(0)
		print("MAT ", m0, " ", m0.resource_path, " override=", near.material_override, " surf=", near.mesh.surface_get_material(0))
		if m0 is StandardMaterial3D:
			var s3 := m0 as StandardMaterial3D
			print("STD normal=", s3.normal_enabled, " tex=", s3.normal_texture, " ao=", s3.ao_enabled, " orm=", s3.orm_texture if "orm_texture" in s3 else null, " rough_tex=", s3.roughness_texture, " detail=", s3.detail_enabled, " uv1_tri=", s3.uv1_triplanar)
			quit(0); return
		var om: ShaderMaterial = m0.duplicate()
		om.set_shader_parameter("has_normal", false); near.material_override = om
		await _shot("x_wear_no_normal", Vector3(0.3, 1.6, 5.6), Vector3(0.0, 1.2, -3.0), 75.0)
		om.set_shader_parameter("has_normal", true); om.set_shader_parameter("has_orm", false)
		await _shot("x_wear_no_orm", Vector3(0.3, 1.6, 5.6), Vector3(0.0, 1.2, -3.0), 75.0)
		var sm := StandardMaterial3D.new(); sm.albedo_texture = load("res://assets/coronado_kit/textures/city_color.png"); sm.vertex_color_use_as_albedo = true
		near.material_override = sm
		await _shot("x_plain_material", Vector3(0.3, 1.6, 5.6), Vector3(0.0, 1.2, -3.0), 75.0)
		var ma := near.mesh.surface_get_arrays(0); var vv: PackedVector3Array = ma[0]; var nn: PackedVector3Array = ma[1]; var uu: PackedVector2Array = ma[4]; var ii: PackedInt32Array = ma[12]
		var cnt := 0
		for k in range(0, ii.size(), 3):
			var c := (vv[ii[k]] + vv[ii[k+1]] + vv[ii[k+2]]) / 3.0
			if c.y > 4.0 and c.y < 5.2 and absf(c.x) < 6.6 and absf(c.z) < 6.5:
				cnt += 1
				if cnt < 40: print("TOP ", c, " n=", nn[ii[k]], " uv=", uu[ii[k]], uu[ii[k+1]], uu[ii[k+2]])
		print("TOPCOUNT ", cnt)
		quit(0); return
	# --- street side, door closed (front +Z; the breakable window is at x 3.55)
	await _shot("01_street_5m", Vector3(1.6, 1.65, 12.0), Vector3(1.0, 1.5, 0.0))
	await _shot("02_street_15m", Vector3(4.0, 1.65, 22.0), Vector3(0.0, 2.0, 0.0))
	await _shot("03_street_15m_window_close", Vector3(3.2, 1.65, 21.5), Vector3(3.4, 1.8, 6.0), 30.0)
	await _shot("04_street_40m_fallback", Vector3(6.0, 1.65, 47.0), Vector3(0.0, 2.5, 0.0), 40.0)
	await _shot("05_street_5m_window_glancing", Vector3(-3.0, 1.65, 11.0), Vector3(4.0, 1.8, 6.8))
	# --- inside
	await _shot("06_inside_from_door", Vector3(0.3, 1.6, 5.6), Vector3(0.0, 1.2, -3.0), 75.0)
	await _shot("07_inside_teller_line", Vector3(-3.8, 1.6, 4.6), Vector3(1.0, 1.0, -2.5), 75.0)
	await _shot("08_inside_to_street", Vector3(1.5, 1.6, -1.0), Vector3(1.5, 1.5, 8.0), 75.0)
	await _shot("09_inside_desks", Vector3(2.0, 1.6, 2.0), Vector3(-6.0, 1.0, 2.0), 75.0)
	await _shot("10_inside_staff_side", Vector3(-4.6, 1.7, -3.4), Vector3(3.0, 1.0, -5.0), 75.0)
	# facing checks (Yasin 22 Nov 02:44: "PCs face the wrong way"): from above and from each user's seat
	await _shot("20_desk_from_above", Vector3(-4.6, 3.0, 0.85), Vector3(-5.8, 0.6, 0.85), 60.0)
	await _shot("21_desk_officer_seat_view", Vector3(-6.25, 1.2, 0.85), Vector3(-4.2, 0.85, 0.85), 70.0)
	await _shot("22_desk_customer_seat_view", Vector3(-4.4, 1.2, 0.85), Vector3(-6.3, 0.85, 0.85), 70.0)
	await _shot("23_back_office_desk_seat_view", Vector3(4.6, 1.2, -6.1), Vector3(4.6, 0.85, -4.0), 70.0)
	await _shot("24_teller_staff_view", Vector3(0.61, 1.3, -3.1), Vector3(0.61, 1.1, 0.5), 70.0)
	await _shot("25_hall_view_of_tellers", Vector3(0.0, 1.6, 2.5), Vector3(0.0, 1.2, -3.0), 70.0)
	# --- doors
	for d in doors: d.call("open", bank.global_transform * Vector3(0, 1.6, 10.0)); d.set("force_open", 1.0)
	await _shot("11_door_open_street", Vector3(0.0, 1.65, 10.5), Vector3(0.0, 1.3, 0.0))
	await _shot("12_door_open_inside", Vector3(0.0, 1.6, 2.0), Vector3(0.0, 1.3, 8.0), 70.0)
	for d in doors: d.set("force_open", 0.0)
	await _shot("13_door_closed_street", Vector3(0.0, 1.65, 10.5), Vector3(0.0, 1.3, 0.0))
	# --- the window: intact, cracked, broken (shards in the air), broken settled
	await _shot("14_window_intact", Vector3(3.6, 1.65, 9.5), Vector3(3.55, 2.0, 6.8), 50.0)
	win.call("crack", (win as Node3D).to_global(Vector3(0.5, 1.6, 0)))
	await _shot("15_window_cracked", Vector3(3.6, 1.65, 9.5), Vector3(3.55, 2.0, 6.8), 50.0)
	win.call("break_window", (win as Node3D).to_global(Vector3(0.5, 1.6, 0)))
	cam.global_position = bank.global_transform * Vector3(3.6, 1.65, 9.5); cam.look_at(bank.global_transform * Vector3(3.55, 2.0, 6.8))
	for k in 3: await process_frame
	await RenderingServer.frame_post_draw
	var im := root.get_viewport().get_texture().get_image(); im.convert(Image.FORMAT_RGB8); im.save_png(out + "/16_window_breaking_shards.png")
	for k in 70: await process_frame
	await _shot("17_window_broken", Vector3(3.6, 1.65, 9.5), Vector3(3.55, 2.0, 6.8), 50.0)
	# --- the door broken
	for d in doors: d.call("break_door")
	await _shot("18_door_broken_street", Vector3(0.0, 1.65, 10.5), Vector3(0.0, 1.3, 0.0))
	await _shot("19_door_broken_inside", Vector3(1.2, 1.6, 2.0), Vector3(0.0, 1.0, 7.0), 70.0)
	info["break_state"] = BS.states.duplicate()
	# --- cost: the interior's draws and primitives seen from the street (5 m, 15 m) with the room on / off
	var cost := {}
	for dist: Array in [["5m", Vector3(1.6, 1.65, 12.0)], ["15m", Vector3(4.0, 1.65, 22.0)], ["inside", Vector3(0.3, 1.6, 5.6)]]:
		var look := Vector3(0.0, 1.5, 0.0) if String(dist[0]) != "inside" else Vector3(0.0, 1.2, -3.0)
		room.visible = true; var on := await _measure(dist[0], dist[1], look)
		room.visible = false; var off := await _measure(dist[0], dist[1], look)
		near.mesh = old_near; var closed := await _measure(dist[0], dist[1], look)
		near.mesh = BL.near_mesh(MODEL)
		cost[dist[0]] = {"with_interior": on, "room_hidden": off, "old_closed_near_no_room": closed}
		room.visible = true
	info["cost"] = cost
	print("COST ", cost)
	var f := FileAccess.open(out + "/shots.json", FileAccess.WRITE); f.store_string(JSON.stringify(info, " ")); f.close()
	BS.clear_all()
	quit(0)
