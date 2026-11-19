extends SceneTree
## Car damage on the new cars (C++: CityCar; the old game's car_damage.gd; Yasin: "apply the damage to the new cars too"),
## in a window so the picture shows the dents on the new textures:
##   godot --path . --rendering-method mobile --resolution 960x540 -s res://tests/traffic/test_car_damage.gd
## A flat floor and a concrete wall. Each of four new models drives into the wall at about 50 km/h. Each must: use the
## new car textures (map_mode 2), be dented where it hit (the front), lose health and engine power, play a crash sound
## by severity; the hardest smokes. A light knock (8 km/h) gives a shallow dent only. repair() undoes it. One picture of
## the dented cars: OUT/car_damage.png.
var cars: Array = []
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var cam: Camera3D
const MODELS := [3, 0, 5, 6]   # volt_x, stern_e, sakura, van
const LANE := 6.0

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("DAMAGE  %s: %s" % ["ok" if ok else "FAIL", what])

func _box(size: Vector3, at: Vector3, col: Color) -> void:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = size; cs.shape = sh; b.add_child(cs)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = size; mi.mesh = bm
	var m := StandardMaterial3D.new(); m.albedo_color = col; mi.material_override = m; b.add_child(mi)
	b.position = at; root.add_child(b)

func _initialize() -> void:
	RenderingServer.global_shader_parameter_add(&"refl_env", RenderingServer.GLOBAL_VAR_TYPE_VEC2, Vector2(1.0, 0.0))
	_box(Vector3(200, 2, 200), Vector3(0, -1, 0), Color(0.35, 0.35, 0.37))
	_box(Vector3(40, 3, 1.0), Vector3(0, 1.5, 30.5), Color(0.6, 0.58, 0.55))   # the wall, across the cars' way
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-45, 150, 0); sun.shadow_enabled = true; root.add_child(sun)
	var env := WorldEnvironment.new(); env.environment = Environment.new(); env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.7, 0.88); env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(0.6, 0.6, 0.62)
	root.add_child(env)
	cam = Camera3D.new(); root.add_child(cam); cam.current = true
	cam.look_at_from_position(Vector3(14, 4.0, 18), Vector3(0, 0.8, 27), Vector3.UP)
	for i in MODELS.size():
		var c: RigidBody3D = ClassDB.instantiate(&"CityCar")
		c.set(&"model", MODELS[i]); c.set(&"paint", [Color(0.8, 0.1, 0.08), Color(0.9, 0.9, 0.92), Color(0.1, 0.2, 0.6), Color(0.2, 0.22, 0.24)][i])
		c.position = Vector3((i - 1.5) * LANE, 0.05, 0.0)
		root.add_child(c)
		cars.append(c)

func _physics_process(delta: float) -> bool:
	t += delta
	match step:
		0:
			if t < 0.8: return false
			for c in cars:
				var d: Dictionary = c.call(&"get_damage")
				_check(int(d.map_mode) == 2, "model %d uses the new car textures (map_mode %d)" % [int(c.get(&"model")), int(d.map_mode)])
				c.call(&"set_controls", 1.0, 0.0, 0.0, 0.0, false)
			step = 1; t0 = t
		1:      # full throttle to ~50 km/h, then coast into the wall
			var all_hit := true
			for c in cars:
				var v := (c as RigidBody3D).linear_velocity.length()
				if v > 13.5: c.call(&"set_controls", 0.0, 0.0, 0.0, 0.0, false)
				if int((c.call(&"get_damage") as Dictionary).hits) == 0: all_hit = false
			if not all_hit and t - t0 < 15.0: return false
			step = 2; t0 = t
		2:
			if t - t0 < 1.5: return false
			for c in cars:
				var d: Dictionary = c.call(&"get_damage")
				print("DAMAGE    model %d: %d hits, %d dents, deepest %.3f m, health %.2f, torque %.0f of %.0f, smoke %s, sound %s" % [int(c.get(&"model")), int(d.hits), int(d.dents), float(d.deepest), float(d.health), float(d.torque), float(d.base_torque), str(d.smoke), String(d.last_sound)])
				_check(int(d.dents) >= 1 and float(d.deepest) > 0.08, "model %d is dented (%.2f m deep)" % [int(c.get(&"model")), float(d.deepest)])
				_check(float(d.health) < 0.9 and (float(d.health) >= 0.6 or float(d.torque) < float(d.base_torque)), "model %d lost health (%.2f; the engine weakens below 0.6, as the old game)" % [int(c.get(&"model")), float(d.health)])
				_check(String(d.last_sound).begins_with("car_crash"), "model %d: a crash sound (%s)" % [int(c.get(&"model")), String(d.last_sound)])
			step = 3; t0 = t
		3:
			if t - t0 < 0.3:
				var mid: Vector3 = ((cars[0] as Node3D).global_position + (cars[1] as Node3D).global_position) * 0.5
				cam.look_at_from_position(Vector3(mid.x + 1.5, 1.7, 29.4), mid + Vector3(0, 0.5, 0), Vector3.UP)   # (between the wall and the fronts)
				return false
			var im := root.get_texture().get_image()
			if im: im.save_png("res://OUT/car_damage.png")
			# a light knock on a fresh car: shallow
			var c: Node = cars[0]
			c.call(&"repair")
			var d0: Dictionary = c.call(&"get_damage")
			_check(int(d0.dents) == 0 and float(d0.health) > 0.999, "repair() undoes it")
			c.call(&"hit", (c as Node3D).global_basis.z * -2.6)
			var d1: Dictionary = c.call(&"get_damage")
			_check(int(d1.dents) == 1 and float(d1.deepest) < 0.03 and float(d1.health) > 0.98 and String(d1.last_sound).begins_with("car_bump"), "a light knock: one shallow dent (%.3f m), a bump sound (%s)" % [float(d1.deepest), String(d1.last_sound)])
			# a heavy one: smoke
			for k in 3: c.call(&"hit", (c as Node3D).global_basis.z * -14.0)
			var d2: Dictionary = c.call(&"get_damage")
			_check(bool(d2.smoke) and float(d2.health) < 0.5 and float(d2.torque) < float(d2.base_torque), "heavy hits: the bonnet smokes and the engine is weaker (health %.2f, torque %.0f of %.0f)" % [float(d2.health), float(d2.torque), float(d2.base_torque)])
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
