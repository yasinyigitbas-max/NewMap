extends SceneTree
## His body (player v3, standard skeleton) playing the standard-skeleton clips DIRECTLY - an AnimationPlayer on his own
## skeleton, no copy layer, no corrections. Pictures: each clip at 4 moments, from the side and the front.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 640x720 -s res://tools/people/humanoid/film_body.gd -- --out=DIR [--clips=a,b]
const BODY := "res://assets/people/humanoid/player_v3.glb"
const CLIPS := "res://assets/people/humanoid/clips/"
var out := "user://film_body"
var body: Node3D; var sk: Skeleton3D; var ap: AnimationPlayer; var cam: Camera3D
var jobs := []   # [clip, t, view]
var video := false   # --video: every frame at 30 a second, a three-quarter view (frames to join with ffmpeg)
var n := 0; var j := -1

func _initialize() -> void:
	var want := []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		if a.begins_with("--clips="): want = a.substr(8).split(",")
		if a == "--video": video = true
	DirAccess.make_dir_recursive_absolute(out)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-45, 35, 0); sun.shadow_enabled = true; root.add_child(sun)
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.72, 0.78, 0.86)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.8, 0.8, 0.85); env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; we.environment = env; root.add_child(we)
	var gm := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(60, 60); gm.mesh = pm
	var m := StandardMaterial3D.new(); m.albedo_color = Color(0.5, 0.52, 0.55); gm.material_override = m; root.add_child(gm)
	body = (load(BODY) as PackedScene).instantiate(); root.add_child(body)
	sk = body.find_children("*", "Skeleton3D", true, false)[0]
	ap = AnimationPlayer.new(); body.add_child(ap)   # root_node ".." = the body scene, which owns %GeneralSkeleton
	var lib := AnimationLibrary.new()
	for f in DirAccess.get_files_at(CLIPS):
		if not (f.ends_with(".fbx") or f.ends_with(".glb")): continue
		var nm := f.get_basename()
		if not want.is_empty() and not want.has(nm): continue
		var c: Node = (load(CLIPS + f) as PackedScene).instantiate()
		var cap: AnimationPlayer = c.find_children("*", "AnimationPlayer", true, false)[0]
		lib.add_animation(nm, cap.get_animation(cap.get_animation_list()[0]))
		c.free()
	ap.add_animation_library("", lib)
	cam = Camera3D.new(); cam.fov = 30; root.add_child(cam)
	var order: Array = want if not want.is_empty() else Array(lib.get_animation_list())
	if video:
		var k := 0
		for nm in order:
			var L := lib.get_animation(nm).length
			var reps := maxi(1, int(ceil(4.0 / L)))
			for i in int(L * reps * 30.0): jobs.append([nm, fmod(i / 30.0, L), "video", k]); k += 1
		return
	for nm in order:
		var L := lib.get_animation(nm).length
		for k in 4:
			for v in ["side", "front"]: jobs.append([nm, L * k / 4.0, v])

func _process(_d: float) -> bool:
	n += 1
	if n < 3: return false
	if n % 3 == 0:
		if j >= 0:
			var J = jobs[j]
			var f := "%s/%05d.png" % [out, J[3]] if video else "%s/%s_%d_%s.png" % [out, J[0], int(J[1] * 1000), J[2]]
			root.get_viewport().get_texture().get_image().save_png(f)
		j += 1
		if j >= jobs.size(): return true
		var J = jobs[j]
		ap.play(J[0]); ap.seek(J[1], true); ap.pause()
		var hips := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Hips")).origin
		var at := Vector3(hips.x, 0.9, hips.z)
		var off: Vector3 = {"side": Vector3(4.2, 0.1, 0), "front": Vector3(0, 0.1, 4.2), "video": Vector3(3.0, 0.4, 3.0)}[J[2]]
		cam.position = at + off * 1.6
		cam.look_at(at)
	return false
