extends SceneTree
## Look at kit models alone (ferry landing work, 21 Nov): --out=DIR --b=folder[,folder] views from 4 sides + 3/4.
const K := preload("res://tools/city/pilot/kit_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var out := "/tmp/ml"; var folders: Array = []; var props: Array = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
		elif a.begins_with("--b="): folders = a.trim_prefix("--b=").split(",")
		elif a.begins_with("--p="): props = a.trim_prefix("--p=").split(",")
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(1200, 800)
	var w := Node3D.new(); root.add_child(w)
	var env := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.62, 0.75, 0.88)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.75, 0.78, 0.82); e.ambient_light_energy = 0.9
	env.environment = e; w.add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 35, 0); sun.light_energy = 1.1; w.add_child(sun)
	var gm := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(200, 200); gm.mesh = pm
	var gmat := StandardMaterial3D.new(); gmat.albedo_color = Color(0.55, 0.55, 0.52); gm.material_override = gmat; w.add_child(gm)
	var x := 0.0
	var items: Array = []
	for f: String in folders:
		var st := K.building_stats(f)
		var bb: Array = (st.near as Dictionary).bbox
		var wd := float(bb[1][0]) - float(bb[0][0])
		x += wd * 0.5
		K.building(w, f, Vector3(x, 0, 0), 0.0, f.get_file())
		items.append([f.get_file(), x, bb])
		x += wd * 0.5 + 6.0
	for p: String in props:
		var pp := K.Props.new()
		pp.add(p, "worn", Vector3(x + 4.0, 0, 0), 0.0)
		pp.build(w, K)
		items.append([p, x + 4.0, [[-4, 0, -6], [4, 4, 6]]])
		x += 12.0
	var cam := Camera3D.new(); cam.fov = 50; root.add_child(cam)
	for it: Array in items:
		var cx: float = it[1]; var bb: Array = it[2]
		var c := Vector3(cx, float(bb[1][1]) * 0.4, (float(bb[0][2]) + float(bb[1][2])) * 0.5)
		var r := maxf(float(bb[1][0]) - float(bb[0][0]), float(bb[1][2]) - float(bb[0][2])) * 1.1 + 4.0
		var views := {"front": Vector3(0, 0.35, 1), "back": Vector3(0, 0.35, -1), "left": Vector3(-1, 0.35, 0), "q34": Vector3(0.8, 0.6, 0.8), "top": Vector3(0.01, 1, 0.01)}
		for vn: String in views:
			cam.position = c + (views[vn] as Vector3).normalized() * r
			cam.look_at(c, Vector3.UP)
			for f2 in 6: await process_frame
			root.get_texture().get_image().save_jpg(out.path_join("%s_%s.jpg" % [it[0], vn]), 0.88)
	quit()
