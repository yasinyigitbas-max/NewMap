extends SceneTree
## A film of the new movement system (docs/ANIMATION_PLAN.md; Yasin, 23 Nov: "when can i see it?"): walk, run, stop,
## turn back; a vault; a climb; a ramp; stairs; crouch into cover and along it; a box carried. Side view, 30 fps.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 960x540 --fixed-fps 30 -s res://tests/people/motor_film.gd -- --out=DIR [--only=name]
## Writes DIR/<segment>/f_00000.png ...; ffmpeg makes the film.
var out := "OUT/motor_film"
var only := ""
var loops_kept := PackedStringArray(); var run_speed := 0.0   # (tuning: the walk / run loops kept, the run's pace)
var player: CharacterBody3D
var cam: Camera3D
var seg := -1; var t := 0.0; var t_prev := 0.0; var n := 0
var cam_side := Vector3(3.6, 1.25, -0.5)
var close := false
var body_path := ""
var body_done := false
var look := Vector3()
# [name, length s]: each on its own lane (x = index * 10), built by _build
const SEGS := [
	["idle", 30.0], ["walk_stop", 8.0], ["run_stop", 8.0], ["walk_to_run_to_walk", 10.0], ["turns_on_the_spot", 9.0],
	["walk_turn_back", 8.0], ["run_turn_back", 8.0], ["jump_standing", 5.0], ["jump_walking", 6.0], ["jump_running", 6.0], ["tired_after_jumps", 26.0], ["crouch", 10.0],
	["vault_walking", 6.0], ["vault_running", 6.0], ["climb_1m", 6.0], ["climb_1m_running", 6.0], ["climb_1_4m", 8.0], ["climb_1_75m", 8.0], ["climb_2m", 11.0], ["climb_1_8m_running", 7.0],
	["step_off_0_35m", 6.0], ["walk_off_1m", 8.0], ["walk_off_1_8m", 8.0], ["drop_off_3_5m", 8.0], ["drop_off_8m", 11.0], ["run_off_2m", 7.0],
	["cover_tall", 16.0], ["cover_low", 16.0],
	["phone_text", 16.0], ["phone_call", 20.0], ["sit_phone", 26.0], ["carry_box", 12.0], ["carry_briefcase", 9.0], ["carry_shopping_bag", 7.0],
	["ramp_15deg_walk", 10.0], ["ramp_15deg_run", 7.0], ["ramp_25deg_walk", 11.0], ["stairs_walk", 10.0], ["stairs_run", 7.0], ["kerbs", 9.0],
]
var wall := Color(0.78, 0.70, 0.60)

func _lane(i: int) -> float: return i * 10.0
func _start_y(i: int) -> float:
	match SEGS[i][0]:
		"step_off_0_35m": return 0.35
		"walk_off_1m": return 1.0
		"walk_off_1_8m": return 1.8
		"drop_off_3_5m": return 3.5
		"drop_off_8m": return 8.0
		"run_off_2m": return 2.0
	return 0.0

func _build(i: int) -> void:
	var x := _lane(i)
	match SEGS[i][0]:
		"vault_walking", "vault_running": _box(Vector3(3, 1.0, 0.12), Vector3(x, 0.5, 3.06), null, Vector3.ONE, wall)
		"climb_1m", "climb_1m_running": _box(Vector3(3, 1.0, 2.0), Vector3(x, 0.5, 4.0), null, Vector3.ONE, wall)
		"climb_1_4m": _box(Vector3(3, 1.4, 2.0), Vector3(x, 0.7, 4.0), null, Vector3.ONE, wall)
		"climb_1_75m": _box(Vector3(3, 1.75, 2.0), Vector3(x, 0.875, 4.0), null, Vector3.ONE, wall)
		"climb_2m": _box(Vector3(3, 2.0, 2.0), Vector3(x, 1.0, 4.0), null, Vector3.ONE, wall)
		"step_off_0_35m", "walk_off_1m", "walk_off_1_8m", "drop_off_3_5m", "drop_off_8m", "run_off_2m":   # (a ledge he starts on, the ground below)
			var hh := _start_y(i)
			_box(Vector3(4, hh, 5.0), Vector3(x, hh * 0.5, -1.5), null, Vector3.ONE, wall)
		"climb_1_8m_running": _box(Vector3(3, 1.8, 2.0), Vector3(x, 0.9, 7.0), null, Vector3.ONE, wall)
		"sit_phone": _box(Vector3(1.6, 0.45, 0.45), Vector3(x, 0.225, 3.05), null, Vector3.ONE, wall)
		"cover_tall": _box(Vector3(6, 2.4, 0.3), Vector3(x, 1.2, 3.15), null, Vector3.ONE, wall)
		"cover_low": _box(Vector3(6, 1.0, 0.3), Vector3(x, 0.5, 3.15), null, Vector3.ONE, wall)
		"ramp_15deg_walk", "ramp_15deg_run": _ramp(x, 15.0, wall)
		"ramp_25deg_walk": _ramp(x, 25.0, wall)
		"stairs_walk", "stairs_run": _stairs(x, 0.17, wall)
		"kerbs":
			_box(Vector3(3, 0.15, 3.0), Vector3(x, 0.075, 3.5), null, Vector3.ONE, wall)
			_box(Vector3(3, 0.15, 3.0), Vector3(x, 0.075, 9.0), null, Vector3.ONE, wall)

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
		elif a.begins_with("--only="): only = a.trim_prefix("--only=")
		elif a.begins_with("--loops="): loops_kept = PackedStringArray(a.trim_prefix("--loops=").split(";"))
		elif a.begins_with("--run-speed="): run_speed = float(a.trim_prefix("--run-speed="))
		elif a == "--close": close = true
		elif a.begins_with("--body="): body_path = a.trim_prefix("--body=")   # (a new body drawn in his pose: tools/people/pose_follow.gd)   # (the camera at his chest, 1.1 m off: hands, the phone)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 50, 0); sun.shadow_enabled = true; root.add_child(sun)
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.70, 0.78, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.78, 0.79, 0.83); env.ambient_light_energy = 0.7; we.environment = env; root.add_child(we)
	var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
	img.set_pixel(0, 0, Color(0.55, 0.56, 0.58)); img.set_pixel(1, 1, Color(0.55, 0.56, 0.58))
	img.set_pixel(1, 0, Color(0.44, 0.45, 0.47)); img.set_pixel(0, 1, Color(0.44, 0.45, 0.47))
	var tex := ImageTexture.create_from_image(img)
	_box(Vector3(SEGS.size() * 10.0 + 40, 2, 80), Vector3(SEGS.size() * 5.0, -1, 15), tex, Vector3(SEGS.size() * 10.0 + 40, 80, 1))
	for i in SEGS.size(): _build(i)
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0, 0.05, 0); root.add_child(player)
	cam = Camera3D.new(); cam.fov = 42.0; root.add_child(cam); cam.current = true

func _box(size: Vector3, at: Vector3, tex: Texture2D, uv: Vector3, col := Color(0.6, 0.6, 0.6)) -> void:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = size; cs.shape = sh; b.add_child(cs)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = size; mi.mesh = bm
	var m := StandardMaterial3D.new()
	if tex: m.albedo_texture = tex; m.uv1_scale = uv; m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	else: m.albedo_color = col
	mi.material_override = m; b.add_child(mi)
	b.position = at; root.add_child(b)

func _ramp(x: float, ang: float, col: Color) -> void:
	var L := 5.0; var h := L * tan(deg_to_rad(ang)); var top := 2.0
	var pts := PackedVector3Array()
	for xx in [x - 1.5, x + 1.5]:
		for p in [Vector3(xx, 0, 2.0), Vector3(xx, h, 2.0 + L), Vector3(xx, h, 2.0 + L + top), Vector3(xx, 0, 2.0 + 2 * L + top)]: pts.append(p)
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := ConvexPolygonShape3D.new(); sh.points = pts; cs.shape = sh; b.add_child(cs)
	var mi := MeshInstance3D.new(); mi.mesh = sh.get_debug_mesh()
	var am := ArrayMesh.new(); var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var q := [[Vector3(x - 1.5, 0, 2.0), Vector3(x + 1.5, 0, 2.0), Vector3(x + 1.5, h, 2.0 + L), Vector3(x - 1.5, h, 2.0 + L)],
		[Vector3(x - 1.5, h, 2.0 + L), Vector3(x + 1.5, h, 2.0 + L), Vector3(x + 1.5, h, 2.0 + L + top), Vector3(x - 1.5, h, 2.0 + L + top)],
		[Vector3(x - 1.5, h, 2.0 + L + top), Vector3(x + 1.5, h, 2.0 + L + top), Vector3(x + 1.5, 0, 2.0 + 2 * L + top), Vector3(x - 1.5, 0, 2.0 + 2 * L + top)]]
	for f in q:
		for i in [0, 2, 1, 0, 3, 2]: st.add_vertex(f[i])
	st.generate_normals(); st.commit(am)
	mi.mesh = am
	var m := StandardMaterial3D.new(); m.albedo_color = col; m.cull_mode = BaseMaterial3D.CULL_DISABLED; mi.material_override = m
	b.add_child(mi); root.add_child(b)

func _stairs(x: float, rise: float, col: Color) -> void:
	var tread := 0.28; var n := 8
	for i in n: _box(Vector3(3.0, rise * (i + 1), tread), Vector3(x, rise * (i + 1) * 0.5, 2.0 + tread * (i + 0.5)), null, Vector3.ONE, col)
	var top := rise * n
	_box(Vector3(3.0, top, 1.5), Vector3(x, top * 0.5, 2.0 + tread * n + 0.75), null, Vector3.ONE, col)
	for i in n:
		var hh := rise * (n - i)
		_box(Vector3(3.0, hh, tread), Vector3(x, hh * 0.5, 2.0 + tread * n + 1.5 + tread * (i + 0.5)), null, Vector3.ONE, col)

func _next() -> void:
	seg += 1
	while seg < SEGS.size() and only != "" and not Array(only.split(",")).any(func(o): return (SEGS[seg][0] as String).contains(o)): seg += 1
	if seg >= SEGS.size(): quit(0); return
	player.global_position = Vector3(_lane(seg), _start_y(seg) + 0.05, -2.5 if _start_y(seg) > 0.0 else -0.5); player.velocity = Vector3.ZERO
	player.call(&"set_move", Vector2.ZERO, false); player.call(&"set_crouch", false); player.call(&"set_carry", 0)
	if not loops_kept.is_empty(): player.call(&"motor_keep_loops", loops_kept)
	if run_speed > 0.0: player.call(&"set_run_speed", run_speed)
	t = 0.0; t_prev = 0.0; n = 0
	DirAccess.make_dir_recursive_absolute("%s/%02d_%s" % [out, seg, SEGS[seg][0]])
	look = player.global_position + Vector3(0, 0.9, 0)
	print("FILM %s" % SEGS[seg][0])

func _at(w: float) -> bool: return t_prev < w and t >= w
func x_of() -> float: return _lane(seg)
func mv(v: Vector2, run := false) -> void: player.call(&"set_move", v, run)

func _act() -> void:
	var name: String = SEGS[seg][0]
	match name:
		"idle": pass   # (standing: the idles, a fidget every 8-18 s)
		"walk_stop":
			if _at(0.8): mv(Vector2(0, 1))
			if _at(4.0): mv(Vector2.ZERO)
		"run_stop":
			if _at(0.8): mv(Vector2(0, 1), true)
			if _at(4.0): mv(Vector2.ZERO)
		"walk_to_run_to_walk":
			if _at(0.8): mv(Vector2(0, 1))
			if _at(3.0): mv(Vector2(0, 1), true)
			if _at(5.5): mv(Vector2(0, 1))
			if _at(8.0): mv(Vector2.ZERO)
		"turns_on_the_spot":
			if _at(0.8): mv(Vector2(1, 0))
			if _at(1.3): mv(Vector2.ZERO)
			if _at(3.5): mv(Vector2(0, -1))
			if _at(4.0): mv(Vector2.ZERO)
			if _at(6.0): mv(Vector2(-1, 0))
			if _at(6.5): mv(Vector2.ZERO)
		"walk_turn_back":
			if _at(0.8): mv(Vector2(0, 1))
			if _at(3.5): mv(Vector2(0, -1))
			if _at(6.0): mv(Vector2.ZERO)
		"run_turn_back":
			if _at(0.8): mv(Vector2(0, 1), true)
			if _at(3.2): mv(Vector2(0, -1), true)
			if _at(5.5): mv(Vector2.ZERO)
		"jump_standing":
			if _at(1.0): player.call(&"jump")
		"jump_walking":
			if _at(0.6): mv(Vector2(0, 1))
			if _at(2.2): player.call(&"jump")
			if _at(4.5): mv(Vector2.ZERO)
		"jump_running":
			if _at(0.6): mv(Vector2(0, 1), true)
			if _at(2.2): player.call(&"jump")
			if _at(4.0): mv(Vector2.ZERO)
		"phone_text":   # (the phone open: texting standing, walking with it, put away)
			if _at(0.8): player.call(&"set_phone_use", 1)
			if _at(6.0): mv(Vector2(0, 1))
			if _at(11.0): mv(Vector2.ZERO)
			if _at(13.0): player.call(&"set_phone_use", 0)
		"phone_call":   # (a call: standing, walking - run asked, a walk it stays - then hung up)
			if _at(0.8): player.call(&"set_phone_use", 2)
			if _at(8.0): mv(Vector2(0, 1), true)
			if _at(14.0): mv(Vector2.ZERO)
			if _at(16.0): player.call(&"set_phone_use", 0)
		"sit_phone":   # (to the bench, sat, the phone out while sitting, away, up)
			if _at(0.8): player.call(&"sit_at", Vector3(x_of(), 0.45, 3.0), PI)
			if _at(9.0): player.call(&"set_phone_use", 1)
			if _at(19.0): player.call(&"set_phone_use", 0)
			if _at(23.0): player.call(&"stand_up")
		"tired_after_jumps":   # (five jumps back to back: out of stamina - the tired idle, then rested, the idle again)
			for k in 5: if _at(0.8 + k * 3.0): player.call(&"jump")
		"crouch":
			if _at(0.8): player.call(&"set_crouch", true)
			if _at(2.5): mv(Vector2(0, 1))
			if _at(5.0): mv(Vector2(1, 0))
			if _at(6.5): mv(Vector2.ZERO)
			if _at(8.0): player.call(&"set_crouch", false)
		"cover_tall", "cover_low":
			if _at(0.8): player.call(&"set_crouch", true)
			if _at(2.0): mv(Vector2(0, 1))
			if _at(5.0): mv(Vector2(1, 0))
			if _at(8.5): mv(Vector2(-1, 0))
			if _at(12.0): mv(Vector2.ZERO)
			if _at(13.5): player.call(&"set_crouch", false)
		"carry_box":
			if _at(0.6): player.call(&"set_carry", 1)
			if _at(1.6): mv(Vector2(0, 1))
			if _at(4.5): mv(Vector2.ZERO)
			if _at(6.0): mv(Vector2(0, 1), true)
			if _at(8.5): mv(Vector2.ZERO)
			if _at(10.5): player.call(&"set_carry", 0)
		"carry_briefcase", "carry_shopping_bag":
			if _at(0.6): player.call(&"set_carry", 2 if name == "carry_briefcase" else 3)
			if _at(2.0): mv(Vector2(0, 1))
			if _at(5.0): mv(Vector2.ZERO)
			if _at(SEGS[seg][1] - 1.5): player.call(&"set_carry", 0)
		_:   # (vaults, climbs, ramps, stairs, kerbs: walked or run at it)
			var run := name.contains("run")
			if _at(0.8): mv(Vector2(0, 1), run)
			if name.begins_with("ramp") or name.begins_with("stairs") or name == "kerbs" or name.contains("off_"):
				if _at(SEGS[seg][1] - 1.5): mv(Vector2.ZERO)

var started := false
func _process(delta: float) -> bool:
	if not player or not player.is_inside_tree(): return false
	if not started:
		started = true; _next(); return false
	if body_path != "" and not body_done:
		var sks := player.find_children("*", "Skeleton3D", true, false)
		if not sks.is_empty():
			body_done = true
			var src: Skeleton3D = sks[0]
			for m in src.find_children("*", "MeshInstance3D", true, false): m.visible = false   # (the old body hidden; the phone is the player's, kept)
			var scn: Node3D = (load(body_path) as PackedScene).instantiate(); root.add_child(scn)
			var dsk: Skeleton3D = scn.find_children("*", "Skeleton3D", true, false)[0]
			var pf: Node3D = load("res://tools/people/pose_follow.gd").new(); root.add_child(pf)
			pf.call(&"setup", src, dsk)
	if seg >= SEGS.size(): return true
	t_prev = t; t += delta
	_act()
	# the camera beside him, following softly
	var p := player.global_position + Vector3(0, 1.25 if close else 0.9, 0)
	look = look.lerp(p, 0.12)
	cam.global_position = look + (Vector3(-1.3, 0.1, 1.0) if close else cam_side)
	cam.look_at(look, Vector3.UP)
	cam.current = true   # (the player makes his own camera current: this one is the film's)
	if t > 0.3:
		cam.get_viewport().get_texture().get_image().save_png("%s/%02d_%s/f_%05d.png" % [out, seg, SEGS[seg][0], n]); n += 1
	if t >= SEGS[seg][1]: _next()
	return false
