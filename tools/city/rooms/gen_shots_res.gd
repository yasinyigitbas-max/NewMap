extends SceneTree
## (residential zone copy, 18 Nov: reads interiors/assignment_res.json; the shared gen_shots.gd is not changed)
## Pictures of the generated shop rooms in their buildings (18 Nov). Loads the city-kit layout (raw locked pieces), opens
## each room's doors and windows in its building's near mesh IN MEMORY (the same cut as interiors/rooms/room_shots.gd;
## the game cuts at bake time, the piece files are never touched), places the rooms and shoots:
##   <id>_street.png   the shop front from across the pavement      <id>_in.png   inside, from the door
##   street_<n>.png    --streets=name:x,y,z:tx,ty,tz;...  wider street views with every room of the area open
##   --merged          the merged rooms (runtime/rooms, tools/city/rooms/room_merge.gd) instead of the built ones
##   --night           evening light (sun down, the rooms' own lights on)
##   xvfb-run -a godot --path . --rendering-method mobile --rendering-driver vulkan --resolution 1640x720 \
##       -s res://tools/city/rooms/gen_shots.gd -- --out=DIR --pieces=b_nw,b_ne [--night] [--streets=...] [--noroom]
const K := preload("res://tools/city/pilot/kit_lib.gd")
const D := "res://map_dc/coronado/city_kit/interiors/"
const OPEN := ["O_shopdoor", "O_civic_door", "O_storefront", "O_win_", "O_glass_plain", "O_civic_win", "O_small_"]

func _init() -> void: _run.call_deferred()

func _v(s: String) -> Vector3:
	var f := s.split_floats(","); return Vector3(f[0], f[1], f[2])

func _run() -> void:
	var rdir := D + "rooms/"
	var out := "user://gen_shots"; var pieces_only := PackedStringArray(); var night := false; var streets: Array = []; var noroom := false; var each := true
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
		if a.begins_with("--pieces="): pieces_only = a.trim_prefix("--pieces=").split(",", false)
		if a == "--night": night = true
		if a == "--noroom": noroom = true
		if a == "--streets-only": each = false
		if a == "--merged": rdir = "res://map_dc/coronado/city_kit/runtime/rooms/"
		if a.begins_with("--streets="):
			for c in a.trim_prefix("--streets=").split(";", false):
				var p := c.split(":"); streets.append([p[0], _v(p[1]), _v(p[2])])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var env := Environment.new(); var sky := Sky.new(); var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = Color(0.32, 0.52, 0.82).lerp(Color(0.02, 0.03, 0.07), 1.0 if night else 0.0)
	psm.sky_horizon_color = Color(0.72, 0.8, 0.88).lerp(Color(0.1, 0.1, 0.16), 1.0 if night else 0.0)
	sky.sky_material = psm; env.background_mode = Environment.BG_SKY; env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.62, 0.64, 0.68) if not night else Color(0.25, 0.28, 0.4)
	env.ambient_light_energy = 0.55 if not night else 0.25
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED      # cloud GPU: leaves draw black otherwise
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	if night: env.glow_enabled = true; env.glow_intensity = 0.5
	var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-48, -35, 0); sun.light_energy = 1.25 if not night else 0.03
	sun.shadow_enabled = OS.get_environment("NOSHADOW") != "1"; sun.directional_shadow_max_distance = 120.0; root.add_child(sun)
	var world := Node3D.new(); world.name = "World"; root.add_child(world)
	var pieces: Array = K.place_layout(world)
	var gp := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(4000, 4000); gp.mesh = pm
	var gm := StandardMaterial3D.new(); gm.albedo_color = Color(0.36, 0.42, 0.3); gp.material_override = gm; gp.position.y = -0.05; world.add_child(gp)
	var regs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/coronado_kit/textures/city_layout.json")).regions
	var rc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(D + "room_contracts.json")).models
	var asg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(D + "assignment_res.json"))
	var cam := Camera3D.new(); cam.fov = 62.0; cam.near = 0.05; cam.far = 1500.0; root.add_child(cam)
	# every room of the chosen pieces: cut its openings, place it
	var cuts := {}      # building node -> Array of [facade, along]
	var rooms: Array = []
	for e: Dictionary in asg.rooms:
		if not pieces_only.is_empty() and not pieces_only.has(String(e.piece)): continue
		var scn := String(e.built) if String(e.built) != "" else "g_" + String(e.id)
		var path := rdir + scn + ".scn"
		if not ResourceLoader.exists(path): continue
		var bld: Node3D = null
		for n: Node3D in pieces:
			if String(n.get_meta(&"piece")) != String(e.piece): continue
			var b := n.get_node_or_null("Buildings/" + String(e.label)) as Node3D
			if b: bld = b
		if bld == null: print("GS no building ", e.id); continue
		var room: Node3D = (load(path) as PackedScene).instantiate()
		if not cuts.has(bld): cuts[bld] = []
		(cuts[bld] as Array).append_array(room.get_meta(&"cut", []))
		room.transform = bld.global_transform
		if not noroom: world.add_child(room)
		rooms.append([e, bld, room])
	if not noroom:
		for b: Node3D in cuts: _open(b, regs, rc[String(b.get_meta(&"kit"))], cuts[b])
	for i in 30: await process_frame
	var tag := "_night" if night else ""
	for s: Array in streets:
		cam.global_position = s[1]; cam.look_at(s[2])
		await _shot(out.path_join("%s%s%s.png" % [s[0], tag, "_closed" if noroom else ""]))
	if each:
		for rr: Array in rooms:
			var e: Dictionary = rr[0]; var bld: Node3D = rr[1]
			var c: Dictionary = rc[String(e.model)]
			var dx := float(e.door_along); var fz := float(c.floors[0].box_max[2]); var fy := float(c.floors[0].y)
			var xf := bld.global_transform
			var mid := (float(e.bay[0]) + float(e.bay[1])) * 0.5
			for v: Array in [["street", Vector3(mid + 1.5, fy + 1.65, fz + 6.5), Vector3(mid, fy + 1.3, fz - 3.0)], ["in", Vector3(dx, fy + 1.65, fz - 0.9), Vector3(mid, fy + 1.1, fz - 8.0)]]:
				if night and String(v[0]) == "in": continue
				cam.global_position = xf * (v[1] as Vector3); cam.look_at(xf * (v[2] as Vector3))
				await _shot(out.path_join("%s_%s%s.png" % [String(e.id), v[0], tag]))
	print("GS_DONE rooms=%d" % rooms.size())
	quit()

func _shot(p: String) -> void:
	for i in 25: await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(p)
	print("GS %s draws=%d" % [p.get_file(), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])

## the room's openings dropped from the building's near mesh, in memory (as interiors/rooms/room_shots.gd)
func _open(bld: Node3D, regs: Dictionary, contract: Dictionary, cut: Array) -> void:
	var near := bld.get_node_or_null("near") as MeshInstance3D
	if near == null: return
	var ops: Array = []
	for o: Dictionary in contract.openings:
		if int(o.floor) != 0: continue
		if not OPEN.any(func(p: String) -> bool: return String(o.region).begins_with(p)): continue
		if not regs.has(o.region): continue
		if not cut.any(func(cc: Array) -> bool: return String(cc[0]) == String(o.facade) and absf(float(cc[1]) - float(o.along)) < 0.05): continue
		ops.append(o)
	var src: Mesh = near.mesh
	var am := ArrayMesh.new()
	for si in src.get_surface_count():
		var a := src.surface_get_arrays(si)
		var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]; var t: PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
		var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
		var keepi := PackedInt32Array()
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
			if drop: continue
			keepi.append(i0); keepi.append(i1); keepi.append(i2)
		a[Mesh.ARRAY_INDEX] = keepi
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
		am.surface_set_material(si, src.surface_get_material(si))
	near.mesh = am
