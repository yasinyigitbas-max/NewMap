extends SceneTree
## Side by side film of the walking and running clips (the Animator, 20 Nov; Yasin: "can you show me rocket box and
## other side by side"). Panels, each its own little world: a figure walking over a checkered floor (1 m squares, so a
## sliding foot shows), the camera going along with it. The pose is set from the film's own clock, not the engine's:
## frame k shows every clip at k / FPS seconds times its speed scale.
##   godot --path . --rendering-method mobile --resolution 320x180 -s res://tests/people/gait_film.gd -- --out=OUT/gait_film
## Writes <out>/p<panel>_<frame>.png; tools/people/gait_film.py lays them out with their titles into one film.
const FPS := 25.0
const FRAMES := 100
const W := 360
const H := 440
## [title, clip, clip speed scale, ground speed m/s]
const PANELS := [
	["Quaternius walk, as the game plays it now (x1.74)", "ual/Walk_Loop", 1.74, 1.6],
	["Quaternius walk, its own speed", "ual/Walk_Loop", 1.0, 0.92],
	["Rocketbox walk, its own speed", "walk", 1.0, 1.01],
	["Quaternius sprint, as the game plays it now (x1.48)", "ual/Sprint_Loop", 1.48, 4.6],
	["Quaternius jog, its own speed", "ual/Jog_Fwd_Loop", 1.0, 2.4],
	["Rocketbox run, its own speed", "run", 1.0, 2.88],
]
var out := "OUT/gait_film"
var body := "M1"
var figs: Array = []
var cams: Array = []
var vps: Array = []
var n := 0
const WARM := 12

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
		if a.begins_with("--body="): body = a.trim_prefix("--body=")
	if not ClassDB.class_exists(&"CityPed"): print("FILM ERROR no native module"); quit(1); return
	DirAccess.make_dir_recursive_absolute(out)
	var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
	img.set_pixel(0, 0, Color(0.52, 0.53, 0.55)); img.set_pixel(1, 1, Color(0.52, 0.53, 0.55))
	img.set_pixel(1, 0, Color(0.40, 0.41, 0.43)); img.set_pixel(0, 1, Color(0.40, 0.41, 0.43))
	var tex := ImageTexture.create_from_image(img)
	for k in PANELS.size():
		var vp := SubViewport.new(); vp.size = Vector2i(W, H); vp.own_world_3d = true
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS; vp.msaa_3d = Viewport.MSAA_4X
		root.add_child(vp)
		var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 35, 0); sun.shadow_enabled = true; vp.add_child(sun)
		var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.7, 0.78, 0.88)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.75, 0.76, 0.8); env.ambient_light_energy = 0.8; we.environment = env; vp.add_child(we)
		var fl := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(80, 8); fl.mesh = pm; fl.position = Vector3(30, 0, 0)
		var fm := StandardMaterial3D.new(); fm.albedo_texture = tex; fm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		fm.uv1_scale = Vector3(40, 4, 1); fl.material_override = fm; vp.add_child(fl)
		var p: Node3D = ClassDB.instantiate(&"CityPed")
		p.set(&"body_id", body); p.set(&"clip", String(PANELS[k][1]))
		p.rotation.y = PI / 2.0   # (walking along +x)
		vp.add_child(p)
		var cam := Camera3D.new(); cam.fov = 32.0; vp.add_child(cam); cam.current = true
		figs.append(p); cams.append(cam); vps.append(vp)
	_pose(0)

func _pose(k: int) -> void:
	var t := float(k) / FPS
	for i in PANELS.size():
		var p: Node3D = figs[i]
		var clip := String(PANELS[i][1])
		p.position = Vector3(float(PANELS[i][3]) * t, 0, 0)
		var a: AnimationPlayer = p.find_children("*", "AnimationPlayer", true, false)[0] if p.find_children("*", "AnimationPlayer", true, false).size() > 0 else null
		var len := 1.0
		if a and a.has_animation(clip): len = a.get_animation(clip).length
		p.set(&"clip_at", fmod(t * float(PANELS[i][2]), len))
		var c: Camera3D = cams[i]
		c.look_at_from_position(p.position + Vector3(1.2, 1.25, 5.2), p.position + Vector3(0.3, 0.9, 0))

func _process(_delta: float) -> bool:
	n += 1
	if n <= WARM: _pose(0); return false
	var k := n - WARM - 1   # (this frame shows the pose set last call)
	for i in vps.size():
		(vps[i] as SubViewport).get_texture().get_image().save_png("%s/p%d_%03d.png" % [out, i, k])
	if k + 1 >= FRAMES:
		print("FILM %d panels x %d frames saved: %s" % [vps.size(), FRAMES, out])
		quit(0)
		return true
	_pose(k + 1)
	return false
