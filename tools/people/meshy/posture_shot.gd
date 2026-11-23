extends SceneTree
## Side by side, same clip, same frame: the Rocketbox hero (the clip's own body) and a converted Meshy model, seen from
## the side. To judge whether a posture comes from the clip or from the conversion (Yasin 23 Nov: "he is leaning back").
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1200x700 -s res://tools/people/meshy/posture_shot.gd -- MODEL.glb OUT_DIR lib:clip:time ...

const LIBS := {"pidle": "idle", "pwalk": "walk", "prun": "run", "ptrav": "trav", "pact": "act"}


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var model_path: String = a[0]
	var out: String = a[1]
	DirAccess.make_dir_recursive_absolute(out)
	var shots: Array = a.slice(2)
	var hero: Node3D = load("res://characters/rocketbox/hero_male.scn").instantiate()
	root.add_child(hero)
	hero.position = Vector3(0, 0, -0.6)
	var hap: AnimationPlayer = hero.find_children("*", "AnimationPlayer", true, false)[0] if hero.find_children("*", "AnimationPlayer", true, false).size() > 0 else null
	if hap == null:
		hap = AnimationPlayer.new(); hero.add_child(hap)
	var doc := GLTFDocument.new(); var st := GLTFState.new()
	doc.append_from_file(model_path, st)
	var m: Node3D = doc.generate_scene(st)
	root.add_child(m)
	m.position = Vector3(0, 0, 0.6)
	var map: AnimationPlayer = m.find_children("*", "AnimationPlayer", true, false)[0]
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-45, -60, 0); root.add_child(sun)
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.85, 0.88, 0.9)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	root.add_child(env)
	var cam := Camera3D.new(); cam.projection = Camera3D.PROJECTION_ORTHOGONAL; cam.size = 2.4
	cam.position = Vector3(5, 1.0, 0); cam.rotation_degrees = Vector3(0, 90, 0)
	root.add_child(cam); cam.current = true
	for sp in shots:
		var p: PackedStringArray = String(sp).split(":")
		var lib: AnimationLibrary = load("res://characters/rocketbox/clips_player_%s_male.res" % LIBS[p[0]])
		if not hap.has_animation_library(p[0]): hap.add_animation_library(p[0], lib)
		hap.root_node = hap.get_path_to(hero)
		hap.play(p[0] + "/" + p[1]); hap.seek(float(p[2]), true); hap.pause()
		map.play(p[1]); map.seek(float(p[2]), true); map.pause()
		for i in 6: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/%s_%s.png" % [out, p[1], p[2]])
		print("SHOT ", p[1], " ", p[2])
	quit()
