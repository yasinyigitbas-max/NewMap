extends Node3D
## THE OBSTACLE COURSE (Yasin, 23 Nov: "put it into your obstacle course and give me a playable file, i wanna test it").
## Every move the movement system knows, side by side in lanes, played with the keyboard / a gamepad. The player IS the
## Meshy character (player v3): the movement system drives his own skeleton (Godot's standard humanoid; body_id
## "hero_v3", tools/people/humanoid) - his feet, hands and hips are what the foot locks, grips and IK place.
## Run in the editor (F6 on obstacle_course.tscn) or the exported build (export preset "Obstacle course").

const BODY := "hero_v3"   # (CityPed: assets/people/humanoid/player_v3.glb, clips characters/hero_v3/)
const HELP := """W A S D  walk      Shift  run      Space  jump      C  crouch
Q  cover (at a wall)      E  sit / stand (at the bench)
1  texting      2  phone call      3  phone away
Mouse / arrow keys  look      R  back to the start      B  his body / the old figure
Esc  free the mouse (click to take it back)      H  hide this help"""

var player: Node3D
var hud: Label
var his_body := true
var benches := []   # [seat top centre, yaw he faces sitting]
var sitting := false
var keys := {}
var start := Vector3(0, 0.05, -6)

func _ready() -> void:
	_world()
	var lane := 0
	for L in [
		["Stairs 17 cm", "stairs", 0.17], ["Stairs 12 cm", "stairs", 0.12], ["Ramp 15 deg", "ramp", 15.0], ["Ramp 25 deg", "ramp", 25.0],
		["Kerbs 15 cm", "kerbs", 0.15], ["Vault: rail 1 m", "rail", 1.0], ["Climb 1 m", "wall", 1.0], ["Climb 1.4 m", "wall", 1.4],
		["Climb 1.75 m", "wall", 1.75], ["Climb 2 m", "wall", 2.0], ["Cover: tall wall (Q)", "cover", 2.4], ["Cover: low wall (Q)", "cover", 1.0],
		["Bench (E)", "bench", 0.45], ["Step off 0.35 m", "ledge", 0.35], ["Step off 0.6 m", "ledge", 0.6], ["Walk off 1 m", "ledge", 1.0],
		["Walk off 1.8 m", "ledge", 1.8], ["Drop 3.5 m", "ledge", 3.5]]:
		_station(lane, L[0], L[1], L[2]); lane += 1
	_spawn(start)
	var cl := CanvasLayer.new(); add_child(cl)
	hud = Label.new(); hud.position = Vector2(16, 12); hud.add_theme_font_size_override(&"font_size", 18)
	hud.add_theme_color_override(&"font_color", Color.WHITE); hud.add_theme_color_override(&"font_outline_color", Color.BLACK)
	hud.add_theme_constant_override(&"outline_size", 6)
	cl.add_child(hud)

# ---- the world -------------------------------------------------------------------------------------------------------
func _world() -> void:
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 40, 0); sun.shadow_enabled = true; add_child(sun)
	var env := Environment.new(); env.background_mode = Environment.BG_SKY
	var sky := Sky.new(); sky.sky_material = ProceduralSkyMaterial.new(); env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY; env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
	img.set_pixel(0, 0, Color(0.55, 0.56, 0.58)); img.set_pixel(1, 1, Color(0.55, 0.56, 0.58))
	img.set_pixel(1, 0, Color(0.44, 0.45, 0.47)); img.set_pixel(0, 1, Color(0.44, 0.45, 0.47))
	var tex := ImageTexture.create_from_image(img)
	_box(Vector3(200, 2, 120), Vector3(60, -1, 10), Color.WHITE, tex, Vector3(200, 120, 1))

func _x(lane: int) -> float: return lane * 7.0

func _station(lane: int, name: String, kind: String, v: float) -> void:
	var x := _x(lane)
	var c := Color(0.78, 0.70, 0.60)
	match kind:
		"stairs": _stairs(x, v, c)
		"ramp": _ramp(x, v, c)
		"kerbs":
			_box(Vector3(3, v, 3.0), Vector3(x, v * 0.5, 3.5), c)
			_box(Vector3(3, v, 3.0), Vector3(x, v * 0.5, 9.0), c)
		"rail": _box(Vector3(3, v, 0.12), Vector3(x, v * 0.5, 3.06), c)
		"wall": _box(Vector3(3, v, 2.0), Vector3(x, v * 0.5, 4.0), c)
		"cover": _box(Vector3(6, v, 0.3), Vector3(x, v * 0.5, 3.15), c)
		"bench":
			_box(Vector3(1.6, v, 0.45), Vector3(x, v * 0.5, 3.05), Color(0.45, 0.32, 0.22))
			benches.append([Vector3(x, v, 3.0), PI])
		"ledge":
			# a platform reached by a ramp behind it; its edge faces the start line, the ground below
			var top := v
			_box(Vector3(4, top, 3.0), Vector3(x, top * 0.5, 2.5), c)
			var L := maxf(top / tan(deg_to_rad(18.0)), 1.0)
			_wedge(x, top, 4.0, 4.0 + L, c)
	var lb := Label3D.new(); lb.text = name; lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED; lb.font_size = 64
	lb.outline_size = 12; lb.position = Vector3(x, 3.0, 0.5); add_child(lb)

func _box(size: Vector3, at: Vector3, col: Color, tex: Texture2D = null, uv := Vector3.ONE) -> void:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = size; cs.shape = sh; b.add_child(cs)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = size; mi.mesh = bm
	var m := StandardMaterial3D.new(); m.albedo_color = col
	if tex: m.albedo_texture = tex; m.uv1_scale = uv; m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mi.material_override = m; b.add_child(mi)
	b.position = at; add_child(b)

func _poly(_pts: PackedVector3Array, faces: Array, col: Color) -> void:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in faces:
		for i in [0, 2, 1, 0, 3, 2]: st.add_vertex(f[i])
	st.generate_normals()
	var mesh := st.commit()
	# (collision from the walked surfaces themselves: a convex hull of the ledge's wedge crashed the engine's hull
	# builder - "Index 0 out of bounds" on a worker thread)
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := ConcavePolygonShape3D.new()
	sh.set_faces(mesh.get_faces()); sh.backface_collision = true; cs.shape = sh; b.add_child(cs)
	var mi := MeshInstance3D.new(); mi.mesh = mesh
	var m := StandardMaterial3D.new(); m.albedo_color = col; m.cull_mode = BaseMaterial3D.CULL_DISABLED; mi.material_override = m
	b.add_child(mi); add_child(b)

func _ramp(x: float, ang: float, col: Color) -> void:
	var L := 5.0; var h := L * tan(deg_to_rad(ang)); var top := 2.0
	var a := Vector3(x - 1.5, 0, 2.0); var w := Vector3(3, 0, 0)
	var p1 := Vector3(x - 1.5, h, 2.0 + L); var p2 := Vector3(x - 1.5, h, 2.0 + L + top); var p3 := Vector3(x - 1.5, 0, 2.0 + 2 * L + top)
	var pts := PackedVector3Array([a, a + w, p1, p1 + w, p2, p2 + w, p3, p3 + w])
	_poly(pts, [[a, a + w, p1 + w, p1], [p1, p1 + w, p2 + w, p2], [p2, p2 + w, p3 + w, p3]], col)

# (the way up behind a ledge: from its back edge at z0 down to the ground at z1)
func _wedge(x: float, h: float, z0: float, z1: float, col: Color) -> void:
	var a := Vector3(x - 2, h, z0); var w := Vector3(4, 0, 0); var g := Vector3(x - 2, 0, z1); var g0 := Vector3(x - 2, 0, z0)
	_poly(PackedVector3Array([a, a + w, g, g + w, g0, g0 + w]), [[a, a + w, g + w, g]], col)

func _stairs(x: float, rise: float, col: Color) -> void:
	var tread := 0.28; var n := 8
	for i in n: _box(Vector3(3.0, rise * (i + 1), tread), Vector3(x, rise * (i + 1) * 0.5, 2.0 + tread * (i + 0.5)), col)
	var top := rise * n
	_box(Vector3(3.0, top, 1.5), Vector3(x, top * 0.5, 2.0 + tread * n + 0.75), col)
	for i in n:
		var hh := rise * (n - i)
		_box(Vector3(3.0, hh, tread), Vector3(x, hh * 0.5, 2.0 + tread * n + 1.5 + tread * (i + 0.5)), col)

# ---- the body --------------------------------------------------------------------------------------------------------
func _spawn(at: Vector3) -> void:
	var yaw := 0.0
	if player: yaw = player.rotation.y; player.queue_free()
	player = ClassDB.instantiate(&"CityPlayer")
	player.set(&"body_id", BODY if his_body else "M2")
	player.position = at; player.rotation.y = yaw
	add_child(player)
	player.set(&"capture_mouse", true)

# ---- input and the HUD -----------------------------------------------------------------------------------------------
func _pressed(k: Key) -> bool:
	var now := Input.is_key_pressed(k)
	var was: bool = keys.get(k, false); keys[k] = now
	return now and not was

func _process(_dt: float) -> void:
	if _pressed(KEY_ESCAPE): Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _pressed(KEY_Q): player.call(&"request_cover")
	if _pressed(KEY_1): player.call(&"set_phone_use", 1)
	if _pressed(KEY_2): player.call(&"set_phone_use", 2)
	if _pressed(KEY_3): player.call(&"set_phone_use", 0)
	if _pressed(KEY_R):
		if sitting: player.call(&"stand_up"); sitting = false
		player.call(&"set_phone_use", 0)
		player.global_position = start
	if _pressed(KEY_B): his_body = not his_body; sitting = false; _spawn(player.global_position)
	if _pressed(KEY_H): hud.visible = not hud.visible
	if _pressed(KEY_E):
		if sitting: player.call(&"stand_up"); sitting = false
		else:
			for b in benches:
				if (Vector3(b[0].x, 0, b[0].z) - Vector3(player.global_position.x, 0, player.global_position.z)).length() < 3.0:
					player.call(&"sit_at", b[0], b[1]); sitting = true
	var ms: Dictionary = player.call(&"get_motor_state")
	hud.text = HELP + "\n\n%s   %s%s" % [ms.get("state", ""), String(ms.get("clip", "")).get_file(), "   (tired)" if ms.get("tired", false) else ""]
