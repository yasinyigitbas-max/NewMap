## Prop facing check (22 Nov 2026, Yasin: "the PCs face the wrong way"): renders every prop of a furniture set ALONE,
## seen from its local +Z side (3/4 from above), with a red arrow on the floor along +Z. The kit convention
## (assets/coronado_kit/tools/indoor/i_check.py: Blender -Y front -> glTF +Z): a prop's FRONT - screen, keyboard,
## drawer fronts, seat front, sign face - faces +Z, i.e. toward the person using or reading it. So every picture here
## must show the prop's front. A slot marker's +Z (its yaw) is the same axis: it points from the prop to its user.
##   xvfb-run godot --rendering-driver opengl3 --path . -s res://tools/city/rooms/builtin/prop_facing_sheet.gd -- --set=bank --out=DIR
extends SceneTree
const BL := preload("res://tools/city/rooms/builtin/builtin_lib.gd")
const R := preload("res://map_dc/coronado/city_kit/interiors/rooms/room_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var set_name := "bank"; var out := "/workspace/shop_int/facing_sheet"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--set="): set_name = a.trim_prefix("--set=")
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	create_timer(300.0).timeout.connect(func() -> void: print("FACING watchdog"); quit(2))
	var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.55, 0.6, 0.65)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.8, 0.8, 0.8); env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 20, 0); root.add_child(sun)
	var cam := Camera3D.new(); root.add_child(cam); cam.current = true; cam.fov = 45.0
	var arrow := MeshInstance3D.new(); var am := BoxMesh.new(); am.size = Vector3(0.06, 0.01, 1.0); arrow.mesh = am
	var sm := StandardMaterial3D.new(); sm.albedo_color = Color(0.9, 0.1, 0.1); sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; arrow.material_override = sm
	root.add_child(arrow)
	var names := {}
	var st: Dictionary = BL.sets()[set_name]
	for k: String in st:
		if k.begins_with("_") or k == "required": continue
		for v: String in st[k]: names[v] = true
	var res := {}
	for nm: String in names:
		var f := R.indoor_file(nm) if R.indoor_file(nm) != "" else R.indoor_file("prop_" + nm)
		if f == "": print("FACING no file ", nm); continue
		var inst: Node = BL.glb_scene(f)
		var src := K._first_mesh(inst)
		var mi := MeshInstance3D.new(); mi.mesh = src.mesh; root.add_child(mi)
		var ab := mi.get_aabb(); var c := ab.get_center(); var r := maxf(ab.size.length() * 0.5, 0.3)
		arrow.position = Vector3(c.x, 0.005, ab.end.z + 0.5)
		cam.position = c + Vector3(r * 0.9, r * 1.1, r * 2.6); cam.look_at(c)
		for i in 6: await process_frame
		await RenderingServer.frame_post_draw
		var im := root.get_viewport().get_texture().get_image(); im.convert(Image.FORMAT_RGB8); im.save_png(out + "/" + nm + ".png")
		res[nm] = {"file": f, "aabb_min": [ab.position.x, ab.position.y, ab.position.z], "aabb_max": [ab.end.x, ab.end.y, ab.end.z]}
		mi.queue_free(); inst.free()
		print("FACING ", nm)
	var fo := FileAccess.open(out + "/facing.json", FileAccess.WRITE); fo.store_string(JSON.stringify(res, " ")); fo.close()
	quit(0)
