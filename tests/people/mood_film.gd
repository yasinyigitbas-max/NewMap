extends SceneTree
## The player's movements in motion (the Animator, 20 Nov): one player on a checkered floor (1 m), given the stick:
## stand, walk, turn right while walking, run, stop, turn round, walk, stop. A camera goes along with him.
## (It filmed two moods side by side until Yasin: "just make one normal mode, lets drop the angry entirely".)
##   godot --path . --rendering-method mobile --resolution 320x180 --fixed-fps 50 -s res://tests/people/mood_film.gd -- --out=OUT/mood_film
## Writes <out>/p<panel>_<frame>.png (every other physics frame: 25 fps); tools/people/gait_film.py --mood lays them out.
const W := 440
const H := 360
const TOUR := [
	[1.0, Vector2.ZERO, false],
	[3.0, Vector2(0, 1), false],
	[2.5, Vector2(1, 0), false],
	[3.0, Vector2(1, 0), true],
	[1.6, Vector2.ZERO, false],
	[3.0, Vector2(-1, 0), false],
	[1.6, Vector2.ZERO, false],
]
var out := "OUT/mood_film"
var players: Array = []
var cams: Array = []
var vps: Array = []
var look: Array = []
var n := 0
var shot := 0
var seg := -1
var seg_t := 0.0
const WARM := 30

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
	if not ClassDB.class_exists(&"CityPlayer"): print("FILM ERROR no native module"); quit(1); return
	DirAccess.make_dir_recursive_absolute(out)
	var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
	img.set_pixel(0, 0, Color(0.52, 0.53, 0.55)); img.set_pixel(1, 1, Color(0.52, 0.53, 0.55))
	img.set_pixel(1, 0, Color(0.40, 0.41, 0.43)); img.set_pixel(0, 1, Color(0.40, 0.41, 0.43))
	var tex := ImageTexture.create_from_image(img)
	for k in 1:
		var vp := SubViewport.new(); vp.size = Vector2i(W, H); vp.own_world_3d = true
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS; vp.msaa_3d = Viewport.MSAA_4X
		root.add_child(vp)
		var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 35, 0); sun.shadow_enabled = true; vp.add_child(sun)
		var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.7, 0.78, 0.88)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.75, 0.76, 0.8); env.ambient_light_energy = 0.8; we.environment = env; vp.add_child(we)
		var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(200, 2, 200); cs.shape = sh; b.add_child(cs)
		b.position = Vector3(0, -1, 0); vp.add_child(b)
		var fl := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(200, 200); fl.mesh = pm
		var fm := StandardMaterial3D.new(); fm.albedo_texture = tex; fm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		fm.uv1_scale = Vector3(100, 100, 1); fl.material_override = fm; vp.add_child(fl)
		var p: CharacterBody3D = ClassDB.instantiate(&"CityPlayer"); p.position = Vector3(0, 0.05, 0); vp.add_child(p)
		var cam := Camera3D.new(); cam.fov = 40.0; vp.add_child(cam)
		players.append(p); cams.append(cam); vps.append(vp); look.append(Vector3(0, 0.9, 0))

func _physics_process(delta: float) -> bool:
	n += 1
	for i in players.size():
		var p: CharacterBody3D = players[i]
		var c: Camera3D = cams[i]
		c.current = true
		look[i] = (look[i] as Vector3).lerp(p.global_position + Vector3(0, 0.9, 0), minf(delta * 3.0, 1.0))
		c.look_at_from_position(look[i] + Vector3(-3.2, 0.9, 3.6), look[i], Vector3.UP)
	if n < WARM: return false
	seg_t += delta
	if seg < 0 or seg_t >= float(TOUR[seg][0]):
		seg += 1; seg_t = 0.0
		if seg >= TOUR.size():
			print("FILM %d panel(s) x %d frames saved: %s" % [players.size(), shot, out]); quit(0); return true
		for p in players: p.call(&"set_move", TOUR[seg][1], TOUR[seg][2])
	if n % 2 == 0:
		for i in vps.size(): (vps[i] as SubViewport).get_texture().get_image().save_png("%s/p%d_%03d.png" % [out, i, shot])
		shot += 1
	return false
