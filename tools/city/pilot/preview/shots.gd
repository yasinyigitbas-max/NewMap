extends SceneTree
const K := preload("res://tools/city/pilot/kit_lib.gd")
## Pilot preview: loads every piece in map_dc/coronado/city_kit/pieces/, adds sun + sky, and saves shots.
## Usage: godot --path <preview project> -s res://tools/city/pilot/preview/shots.gd -- --out=DIR --cams=name:x,y,z:tx,ty,tz;...
var out := "user://shots"
var cams: Array = []

func _init() -> void: _run.call_deferred()

func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
		if a.begins_with("--cams="):
			for c in a.trim_prefix("--cams=").split(";", false):
				var p := c.split(":")
				cams.append([p[0], _v(p[1]), _v(p[2])])
	DirAccess.make_dir_recursive_absolute(out)
	var env := Environment.new()
	var sky := Sky.new(); var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = Color(0.32, 0.52, 0.82); psm.sky_horizon_color = Color(0.72, 0.8, 0.88)
	psm.ground_horizon_color = Color(0.6, 0.62, 0.6); psm.ground_bottom_color = Color(0.3, 0.32, 0.3)
	sky.sky_material = psm
	env.background_mode = Environment.BG_SKY; env.sky = sky
	# plain colour ambient: sky-based ambient renders alpha-cut double-sided foliage black on lavapipe (preview only)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.62, 0.66, 0.72); env.ambient_light_energy = 0.75
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-48, -35, 0); sun.light_energy = 1.25
	sun.shadow_enabled = OS.get_environment("NOSHADOW") != "1"; sun.directional_shadow_max_distance = 220.0; root.add_child(sun)
	var world := Node3D.new(); world.name = "World"; root.add_child(world)
	var n := K.place_layout(world).size()
	# a plain ground plane under everything (the game terrain stands in here)
	var gp := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(4000, 4000); gp.mesh = pm   # covers every sample site (the stadium reaches z 710: it floated past a 1200 m plane)
	var gm := StandardMaterial3D.new(); gm.albedo_color = Color(0.36, 0.42, 0.3); gm.roughness = 1.0; gp.material_override = gm
	gp.position.y = -0.05; world.add_child(gp)
	if OS.get_environment("NONORMAL") == "1":
		for mmi: MultiMeshInstance3D in world.find_children("*", "MultiMeshInstance3D", true, false):
			var mesh: Mesh = mmi.multimesh.mesh
			for si in mesh.get_surface_count():
				var mt := mesh.surface_get_material(si)
				if mt is BaseMaterial3D and (mt as BaseMaterial3D).transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
					var d: BaseMaterial3D = mt.duplicate(); d.normal_enabled = false; mmi.material_override = d
	# preview only: cars on the parking stalls a piece records (meta "stalls"); the game's parked-car layer does this
	if OS.get_environment("CARS") != "0": _cars(world)
	# preview only: floating name tags (LABELS = a json file of [text, x, y, z]) to show Yasin what is where
	var lab := OS.get_environment("LABELS")
	if lab != "" and FileAccess.file_exists(lab):
		for e: Array in JSON.parse_string(FileAccess.get_file_as_string(lab)):
			var l3 := Label3D.new(); l3.text = String(e[0])
			l3.position = Vector3(float(e[1]), float(e[2]), float(e[3]))
			l3.billboard = BaseMaterial3D.BILLBOARD_ENABLED; l3.no_depth_test = true; l3.fixed_size = true
			l3.pixel_size = 0.0012; l3.font_size = 30; l3.outline_size = 10
			l3.modulate = Color(1, 0.95, 0.3); l3.outline_modulate = Color(0, 0, 0)
			world.add_child(l3)
	var hide := OS.get_environment("HIDE")
	if hide != "":
		for mmi: MultiMeshInstance3D in world.find_children("*", "MultiMeshInstance3D", true, false):
			for h in hide.split(","):
				if String(mmi.name).ends_with("_" + h): mmi.visible = false
	# preview only: water. Pieces record their bay as meta "water" [x0, z0, x1, z1, y] (piece-local; the game draws its own
	# sea). Draw it, and cut the ground plane round it (the plane at -0.05 would cover water 1.5 m below the walk).
	var wrects: Array = []
	# preview only: TERRAIN=<json> (u0, v0, step, nx, ny + heights .f32 + sea .u8 beside it, from zoning/terrain_grid.npz)
	# replaces the flat plane with the city kit's terrain and a sea plane at 0 (the game draws its own terrain + sea)
	var tj := OS.get_environment("TERRAIN")
	if tj != "":
		gp.queue_free(); _terrain(world, tj)
	for pc: Node in world.find_children("*", "Node3D", true, false):
		if tj != "": break
		if not pc.has_meta(&"water"): continue
		var o := (pc as Node3D).global_position
		for e: Array in pc.get_meta(&"water"): wrects.append([o.x + float(e[0]), o.z + float(e[1]), o.x + float(e[2]), o.z + float(e[3]), o.y + float(e[4])])
	if not wrects.is_empty():
		var wm := StandardMaterial3D.new(); wm.albedo_color = Color(0.07, 0.24, 0.25); wm.roughness = 0.12; wm.metallic = 0.1
		var nt := NoiseTexture2D.new(); nt.seamless = true; nt.as_normal_map = true; nt.bump_strength = 3.0; nt.width = 256; nt.height = 256
		var fn := FastNoiseLite.new(); fn.frequency = 0.04; nt.noise = fn
		wm.normal_enabled = true; wm.normal_texture = nt; wm.uv1_scale = Vector3(0.08, 0.08, 0.08); wm.uv1_triplanar = true
		var hb := Rect2(Vector2(wrects[0][0], wrects[0][1]), Vector2.ZERO)
		for r: Array in wrects:
			var wq := MeshInstance3D.new(); var qm := PlaneMesh.new(); qm.size = Vector2(float(r[2]) - float(r[0]), float(r[3]) - float(r[1])); wq.mesh = qm
			wq.position = Vector3((float(r[0]) + float(r[2])) * 0.5, float(r[4]), (float(r[1]) + float(r[3])) * 0.5); wq.material_override = wm
			world.add_child(wq)
			hb = hb.expand(Vector2(r[0], r[1])).expand(Vector2(r[2], r[3]))
		# ground plane = four rectangles round the hole
		var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var L := -2000.0; var Rr := 2000.0
		for q: Rect2 in [Rect2(L, L, Rr - L, hb.position.y - L), Rect2(L, hb.end.y, Rr - L, Rr - hb.end.y), Rect2(L, hb.position.y, hb.position.x - L, hb.size.y), Rect2(hb.end.x, hb.position.y, Rr - hb.end.x, hb.size.y)]:
			var p0 := Vector3(q.position.x, 0, q.position.y); var p1 := Vector3(q.end.x, 0, q.position.y); var p2 := Vector3(q.end.x, 0, q.end.y); var p3 := Vector3(q.position.x, 0, q.end.y)
			for v: Vector3 in [p0, p1, p2, p0, p2, p3]: st.set_normal(Vector3.UP); st.add_vertex(v)
		gp.mesh = st.commit()
		(gp.material_override as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
		# the harbour bed under the shallows (seen through nothing: water is opaque) - not needed
	print("SHOTS pieces=%d" % n)
	var cam := Camera3D.new(); cam.fov = 60.0; cam.far = 2000.0; root.add_child(cam)
	# preview only: TOPVIEW=<metres across> = straight-down orthographic plan of everything loaded. Distance tiers are
	# switched off: the near version of every model shows, the mid / far versions hide, nothing is distance-culled.
	var topv := OS.get_environment("TOPVIEW")
	if topv != "":
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL; cam.size = float(topv); cam.far = 4000.0
		for gi: GeometryInstance3D in world.find_children("*", "GeometryInstance3D", true, false):
			if gi is Label3D: continue
			if gi.visibility_range_begin > 0.0: gi.visible = false
			else: gi.visibility_range_end = 0.0
	for c: Array in cams:
		cam.global_position = c[1]; cam.look_at(c[2])
		for i in 90: await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_viewport().get_texture().get_image()
		img.save_png(out.path_join("%s.png" % c[0]))
		print("SHOT %s draws=%d prims=%d" % [c[0], RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])
	quit()

func _v(s: String) -> Vector3:
	var f := s.split_floats(",")
	return Vector3(f[0], f[1], f[2])

## parked cars on ~3 in 4 recorded stalls (quarter meshes of the game's parked models, painted with the car shader)
func _cars(world: Node3D) -> void:
	var ids := ["volt_s", "volt_x", "stern_e", "stern_g", "sakura", "sakura_t", "van"]
	var cols := [Color(0.92, 0.92, 0.92), Color(0.08, 0.08, 0.09), Color(0.6, 0.62, 0.65), Color(0.32, 0.33, 0.35), Color(0.55, 0.1, 0.1), Color(0.2, 0.28, 0.45), Color(0.43, 0.5, 0.38), Color(0.7, 0.62, 0.48)]
	var shader: Shader = load("res://vehicles/car_paint.gdshader")
	var atlas: Texture2D = load("res://vehicles/models/Textures/car_atlas_1024.png")
	var n := 0
	for node: Node in world.get_children():
		if not node.has_meta(&"stalls"): continue
		var rr := RandomNumberGenerator.new(); rr.seed = hash(String(node.name))
		for s: Array in node.get_meta(&"stalls"):
			if rr.randf() > 0.75: continue
			var id: String = ids[rr.randi() % ids.size()]
			var m: Mesh = load("res://vehicles/models/lod/%s_q.res" % id)
			var mat := ShaderMaterial.new(); mat.shader = shader
			mat.set_shader_parameter("atlas", atlas); mat.set_shader_parameter("paint", cols[rr.randi() % cols.size()])
			var mi := MeshInstance3D.new(); mi.mesh = m; mi.material_override = mat
			var yaw := deg_to_rad(float(s[2]) + (180.0 if rr.randf() < 0.2 else 0.0))
			var lt := Transform3D(Basis(Vector3.UP, yaw), Vector3(float(s[0]), 0.15, float(s[1])))
			if s.size() >= 5:      # sloped street (road_lib): [x, z, yaw, y, grade along z] - the car sits on the slope
				var f := Vector3(sin(yaw), 0.0, cos(yaw)); f.y = float(s[4]) * f.z; f = f.normalized()
				var xa := Vector3.UP.cross(f).normalized(); var ya := f.cross(xa)
				lt = Transform3D(Basis(xa, ya, f), Vector3(float(s[0]), float(s[3]) + 0.15, float(s[1])))
			mi.transform = (node as Node3D).transform * lt
			world.add_child(mi); n += 1
	print("SHOTS cars=%d" % n)

func _terrain(world: Node3D, tj: String) -> void:
	var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(tj))
	var nx := int(m.nx); var ny := int(m.ny); var st := float(m.step); var u0 := float(m.u0); var v0 := float(m.v0)
	var H := FileAccess.get_file_as_bytes(tj.get_basename() + ".f32").to_float32_array()
	var verts := PackedVector3Array(); var cols := PackedColorArray(); var nrm := PackedVector3Array()
	verts.resize(nx * ny); cols.resize(nx * ny); nrm.resize(nx * ny)
	for j in ny:
		for i in nx:
			var k := j * nx + i; var h := H[k]
			verts[k] = Vector3(u0 + i * st, h, v0 + j * st)
			var hx := H[j * nx + mini(i + 1, nx - 1)] - H[j * nx + maxi(i - 1, 0)]
			var hz := H[mini(j + 1, ny - 1) * nx + i] - H[maxi(j - 1, 0) * nx + i]
			nrm[k] = Vector3(-hx, 2.0 * st, -hz).normalized()
			var n := sin(i * 0.37 + j * 0.11) * 0.5 + sin(i * 0.05 - j * 0.09) * 0.5
			var grass := Color(0.36, 0.42, 0.28).lerp(Color(0.45, 0.46, 0.30), 0.5 + 0.4 * n)
			var sand := Color(0.76, 0.70, 0.55)
			cols[k] = grass.lerp(sand, clampf((1.1 - h) / 0.6, 0.0, 1.0)) if h > -0.3 else Color(0.55, 0.52, 0.42)
	var idx := PackedInt32Array()
	for j in ny - 1:
		for i in nx - 1:
			var a := j * nx + i
			idx.append_array([a, a + 1, a + nx, a + 1, a + nx + 1, a + nx])
	var arr := []; arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts; arr[Mesh.ARRAY_COLOR] = cols; arr[Mesh.ARRAY_NORMAL] = nrm; arr[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new(); am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	# vertex colour + thin 1 m contour lines (thicker every 5 m) so the review shots show the heights
	var sh := Shader.new()
	sh.code = "shader_type spatial; render_mode cull_disabled; varying float wy; void vertex(){ wy = (MODEL_MATRIX * vec4(VERTEX,1.0)).y; } void fragment(){ float f = abs(fract(wy + 0.5) - 0.5); float w = fwidth(wy); float l = 1.0 - smoothstep(0.0, w * 1.2, f); float f5 = abs(fract(wy / 5.0 + 0.5) - 0.5) * 5.0; float l5 = 1.0 - smoothstep(0.0, w * 2.0, f5); vec3 c = pow(COLOR.rgb, vec3(2.2)) * (1.0 - 0.35 * max(l * step(0.05, wy), l5 * step(0.05, wy) * 1.6)); ALBEDO = c; ROUGHNESS = 1.0; }"
	var mat := ShaderMaterial.new(); mat.shader = sh
	var mi := MeshInstance3D.new(); mi.mesh = am; mi.material_override = mat; world.add_child(mi)
	var wm := StandardMaterial3D.new(); wm.albedo_color = Color(0.07, 0.24, 0.27); wm.roughness = 0.15; wm.metallic = 0.1
	var sea := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(6000, 6000); sea.mesh = pm
	sea.material_override = wm; sea.position = Vector3(0, 0.0, 0); world.add_child(sea)
	print("SHOTS terrain %dx%d" % [nx, ny])
