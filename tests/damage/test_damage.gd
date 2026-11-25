extends SceneTree
## Damage option B, stage A (25 Nov 2026): CityDamage on a small made-up street - no baked city needed.
##   godot --path . --rendering-method mobile --resolution 960x540 -s res://tests/damage/test_damage.gd [-- --shots=DIR]
## A brick building's wall, a stucco one, the ground (a trimesh, as the bake's), a pole (a thin hull, no table), a bench
## (a hull with the bake's per-shape table "surf"), a tree trunk (table), a car (layer 5) and a person (layer 6).
## Checks: surface_at for each; hit() / strike() / shoot() results; marks pooled in one MultiMesh (capped at 256, the
## oldest fading, one draw); particles come and go (one draw); the sea; the contract's constants. With --shots=DIR it
## saves pictures of the marks (needs a renderer: not --headless).
var dmg: Node3D
var cam: Camera3D
var frame := 0
var fails := 0
var shots_dir := ""
var changed := 0
var ground_body: StaticBody3D
var car: RigidBody3D
var person: CharacterBody3D

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("DMG   %s: %s" % ["ok" if ok else "FAIL", what])

func _box_body(parent: Node, nm: String, size: Vector3, at: Vector3, layer := 1) -> StaticBody3D:
	var b := StaticBody3D.new(); b.name = nm; b.collision_layer = layer; b.collision_mask = 0
	var cs := CollisionShape3D.new(); var bx := BoxShape3D.new(); bx.size = size; cs.shape = bx; b.add_child(cs)
	parent.add_child(b); b.global_position = at
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = size; mi.mesh = bm; b.add_child(mi)
	return b

func _hull(size: Vector3) -> ConvexPolygonShape3D:
	var c := ConvexPolygonShape3D.new(); var pts := PackedVector3Array()
	for q in 8: pts.append(Vector3((q & 1) * size.x - size.x * 0.5, ((q >> 1) & 1) * size.y, ((q >> 2) & 1) * size.z - size.z * 0.5))
	c.points = pts
	return c

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="): shots_dir = a.trim_prefix("--shots=")
	var w := Node3D.new(); w.name = "World"; root.add_child(w)
	var env := WorldEnvironment.new(); env.environment = Environment.new(); env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.7, 0.9); env.environment.ambient_light_color = Color(0.6, 0.6, 0.65); env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	w.add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 30, 0); w.add_child(sun)
	cam = Camera3D.new(); w.add_child(cam); cam.current = true; cam.position = Vector3(0, 1.6, 4.0); cam.look_at(Vector3(0, 1.4, -5))
	# the buildings: a brick one and a stucco one, as the bake makes them ("col" under a node with the kit's meta)
	var bn := Node3D.new(); bn.name = "Buildings"; w.add_child(bn)
	var b1 := Node3D.new(); b1.name = "p12__urb_brick_row_3"; b1.set_meta(&"kit", "res://assets/coronado_kit/buildings/urban/urb_brick_row.tscn"); bn.add_child(b1)
	var wall1 := _box_body(b1, "col", Vector3(8, 6, 1), Vector3(-2, 3, -5.5))
	var wm := StandardMaterial3D.new(); wm.albedo_color = Color(0.62, 0.36, 0.28); (wall1.get_child(1) as MeshInstance3D).material_override = wm
	var b2 := Node3D.new(); b2.name = "p12__apt_stucco3_cream_1"; b2.set_meta(&"kit", "res://assets/coronado_kit/buildings/apartments/apt_stucco3_cream.tscn"); bn.add_child(b2)
	var wall2 := _box_body(b2, "col", Vector3(6, 6, 1), Vector3(7, 3, -5.5))
	var wm2 := StandardMaterial3D.new(); wm2.albedo_color = Color(0.9, 0.86, 0.76); (wall2.get_child(1) as MeshInstance3D).material_override = wm2
	# the ground: a trimesh in a "col_0" body (the bake's ground)
	ground_body = StaticBody3D.new(); ground_body.name = "col_0"; w.add_child(ground_body)
	var gs := ConcavePolygonShape3D.new()
	gs.set_faces(PackedVector3Array([Vector3(-40, 0, -40), Vector3(40, 0, -40), Vector3(40, 0, 40), Vector3(-40, 0, -40), Vector3(40, 0, 40), Vector3(-40, 0, 40)]))
	var gcs := CollisionShape3D.new(); gcs.shape = gs; ground_body.add_child(gcs)
	var gmi := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(80, 80); gmi.mesh = pm; ground_body.add_child(gmi)
	var gmat := StandardMaterial3D.new(); gmat.albedo_color = Color(0.45, 0.45, 0.46); gmi.material_override = gmat
	# props in one "col_1" body: a pole (no table), a bench and a tree trunk (the bake's table "surf", by shape)
	var pb := StaticBody3D.new(); pb.name = "col_1"; w.add_child(pb)
	for spec in [[Vector3(0.12, 3.0, 0.12), Vector3(2.5, 0, -2)], [Vector3(1.8, 0.5, 0.5), Vector3(-2.5, 0, -2)], [Vector3(0.45, 4.0, 0.45), Vector3(5, 0, -2)]]:
		var cs := CollisionShape3D.new(); cs.shape = _hull(spec[0]); cs.position = spec[1]; pb.add_child(cs)
		var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = spec[0]; mi.mesh = bm; mi.position = spec[1] + Vector3(0, spec[0].y * 0.5, 0); pb.add_child(mi)
	pb.set_meta(&"surf", ["", "street_furniture bench_wood_slats", "tree_oak_big trunk"])
	# a car (layer 5) and a person (layer 6)
	car = RigidBody3D.new(); car.name = "TestCar"; car.collision_layer = 16; car.freeze = true; w.add_child(car)
	var ccs := CollisionShape3D.new(); var cb := BoxShape3D.new(); cb.size = Vector3(1.8, 1.45, 4.4); ccs.shape = cb; ccs.position = Vector3(0, 0.725, 0); car.add_child(ccs)
	car.global_position = Vector3(-8, 0, 0)
	person = CharacterBody3D.new(); person.name = "TestPerson"; person.collision_layer = 32; w.add_child(person)
	var pcs := CollisionShape3D.new(); var cap := CapsuleShape3D.new(); cap.radius = 0.3; cap.height = 1.8; pcs.shape = cap; pcs.position = Vector3(0, 0.9, 0); person.add_child(pcs)
	person.global_position = Vector3(10, 0, 0)
	dmg = ClassDB.instantiate(&"CityDamage"); dmg.name = "Damage"; w.add_child(dmg)
	dmg.connect(&"obstacle_changed", func(_b: AABB) -> void: changed += 1)

func _ray(from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to, 1 | 4 | 8 | 16 | 32 | 64)
	return cam.get_world_3d().direct_space_state.intersect_ray(q)

func _surf(from: Vector3, to: Vector3) -> String:
	return String(dmg.call(&"surface_at", _ray(from, to)))

func _shot(nm: String) -> void:
	if shots_dir == "": return
	DirAccess.make_dir_recursive_absolute(shots_dir)
	var img := root.get_texture().get_image()
	if img: img.save_png(shots_dir.path_join(nm + ".png")); print("DMG   picture %s" % shots_dir.path_join(nm + ".png"))

func _process(_dt: float) -> bool:
	frame += 1
	if frame == 3: _surfaces()
	elif frame == 4: _hits()
	elif frame == 6: _shot("01_holes_brick_stucco")
	elif frame == 7: _pool()
	elif frame == 10: _shot("02_full_pool")
	elif frame == 200: _parts_gone()
	elif frame > 201:
		print("DMG   state %s" % str(dmg.call(&"get_state")))
		print("DMG   RESULT %s (%d failed)" % ["PASS" if fails == 0 else "FAIL", fails])
		quit(1 if fails else 0)
		return true
	return false

func _surfaces() -> void:
	_check(ClassDB.class_exists(&"CityDamage"), "the module has CityDamage")
	_check(int(dmg.get(&"BULLET")) == 0 and int(dmg.get(&"CAR")) == 4 and int(dmg.get(&"FALL")) == 5, "the contract's kinds: BULLET 0 .. CAR 4, FALL 5")
	_check(_surf(Vector3(-2, 1.5, 0), Vector3(-2, 1.5, -10)) == "brick", "a brick building's wall reads brick (%s)" % _surf(Vector3(-2, 1.5, 0), Vector3(-2, 1.5, -10)))
	_check(_surf(Vector3(7, 1.5, 0), Vector3(7, 1.5, -10)) == "stucco", "a stucco building's wall reads stucco")
	_check(_surf(Vector3(1, 3, 1), Vector3(1, -1, 1)) == "concrete", "the ground with no map reads concrete (old bake: the footsteps' hard class)")
	_check(_surf(Vector3(2.5, 1.5, 0), Vector3(2.5, 1.5, -4)) == "metal", "a thin tall hull with no table reads metal (a pole)")
	_check(_surf(Vector3(-2.5, 0.3, 0), Vector3(-2.5, 0.3, -4)) == "wood", "a bench by the bake's table reads wood")
	_check(_surf(Vector3(5, 1.5, 0), Vector3(5, 1.5, -4)) == "bark", "a tree trunk by the table reads bark")
	_check(_surf(Vector3(-8, 0.6, 5), Vector3(-8, 0.6, -5)) == "car_body", "a car's side low down reads car_body")
	_check(_surf(Vector3(-8, 1.2, 5), Vector3(-8, 1.2, -5)) == "car_glass", "a car's side at 1.2 m reads car_glass")
	_check(_surf(Vector3(10, 1.2, 5), Vector3(10, 1.2, -5)) == "flesh", "a person reads flesh")
	_check(String(dmg.call(&"surface_at", {})) == "", "an empty hit reads nothing")
	for words in [["hydrant_red", "metal"], ["bench_park", "wood"], ["palm_queen", "bark"], ["cone_traffic", "plastic"], ["hedge_box", "foliage"], ["urb_brick_corner", "brick"], ["umbrella_cafe", "fabric"]]:
		var s := int(ClassDB.class_call_static(&"CityDamage", &"surface_from_words", words[0], -1))
		_check(s >= 0 and ["concrete", "brick", "stucco", "asphalt", "stone", "wood", "metal", "glass", "plastic", "fabric", "bark", "foliage"][s] == words[1], "'%s' is %s" % words)

func _hits() -> void:
	var r: Dictionary = dmg.call(&"shoot", Vector3(-2, 1.6, 3), Vector3(0, 0, -1), 50.0, 10.0, null)
	_check(String(r.get("surface", "")) == "brick" and String(r.get("state", "")) == "marked", "a bullet into the brick wall: brick, marked (%s)" % str(r))
	_check((dmg.call(&"marks_near", Vector3(-2, 1.6, -5), 0.5) as Array).size() == 1, "one mark where it went in")
	for i in 6: dmg.call(&"shoot", Vector3(-3.5 + i * 0.5, 1.2 + (i % 3) * 0.35, 3), Vector3(0, 0, -1), 50.0, 10.0, null)
	for i in 6: dmg.call(&"shoot", Vector3(5.5 + i * 0.5, 1.2 + (i % 3) * 0.35, 3), Vector3(0, 0, -1), 50.0, 10.0, null)
	r = dmg.call(&"strike", Vector3(1.0, 1.3, -3.6), Vector3(1.0, 1.3, -4.9), 0.1, 10.0, 1, null)      # a punch at the brick wall
	_check(String(r.get("surface", "")) == "brick" and (dmg.call(&"marks_near", Vector3(1.0, 1.3, -5), 0.5) as Array).size() == 1, "a punch's sweep finds the wall and leaves a scuff (%s)" % str(r))
	r = dmg.call(&"strike", Vector3(1.0, 1.3, 0.0), Vector3(1.0, 1.3, -1.0), 0.1, 10.0, 2, null)      # a kick at the air
	_check(r.is_empty(), "a kick at nothing touches nothing")
	r = dmg.call(&"hit", Vector3(2.5, 0.6, -1.94), Vector3(0, 0, 1), Vector3(0, 0, -1), 12.0, 4, car)      # a car into the pole
	_check(String(r.get("surface", "")) == "metal", "a car into the pole: metal (%s)" % str(r))
	r = dmg.call(&"hit", Vector3(5, 0.7, -1.77), Vector3(0, 0, 1), Vector3(0, 0, -1), 10.0, 4, car)      # a car into the big tree
	_check(String(r.get("surface", "")) == "bark" and (dmg.call(&"marks_near", Vector3(5, 0.7, -1.77), 0.3) as Array).size() == 1, "a car into a tree: bark, a scar on the trunk")
	r = dmg.call(&"shoot", Vector3(10, 1.2, 5), Vector3(0, 0, -1), 50.0, 10.0, null)
	_check(String(r.get("surface", "")) == "flesh" and (dmg.call(&"marks_near", Vector3(10, 1.2, 0), 1.0) as Array).is_empty(), "a bullet into a person: flesh, no mark on him")
	r = dmg.call(&"shoot", Vector3(-8, 0.6, 5), Vector3(0, 0, -1), 50.0, 10.0, null)
	_check(String(r.get("surface", "")) == "car_body" and (dmg.call(&"marks_near", Vector3(-8, 0.6, 2.2), 1.0) as Array).is_empty(), "a bullet into a car: car_body, no mark floating on it")
	r = dmg.call(&"shoot", Vector3(100, 5, 0), Vector3(0.3, -1, 0).normalized(), 50.0, 10.0, null)
	_check(String(r.get("surface", "")) == "water", "a bullet into the sea (no ground under y = 0): water (%s)" % str(r))
	var st: Dictionary = dmg.call(&"get_state")
	_check(int(st.particles) > 0 and int(st.particle_draws) == 1, "particles fly, one draw (%d)" % int(st.particles))
	_check(int(st.mark_draws) == 1, "the marks: one draw")
	_check(int(st.sounds) > 5, "impact sounds played (%d)" % int(st.sounds))
	cam.position = Vector3(2.5, 1.7, 1.0); cam.look_at(Vector3(2.5, 1.5, -5))

func _pool() -> void:
	var before: int = int((dmg.call(&"get_state") as Dictionary).marks_total)
	for i in 300: dmg.call(&"shoot", Vector3(-5.5 + (i % 30) * 0.25, 0.4 + (i / 30) * 0.45, 3), Vector3(0, 0, -1), 50.0, 10.0, null)
	var st: Dictionary = dmg.call(&"get_state")
	_check(int(st.marks) == 256, "the pool holds 256 marks (%d)" % int(st.marks))
	_check(int(st.marks_total) == before + 300, "every shot made one (%d)" % (int(st.marks_total) - before))
	var all: Array = dmg.call(&"marks_near", Vector3(0, 2, -5), 50.0)
	var faded := 0; var full := 0
	for m: Dictionary in all:
		if float(m.alpha) < 0.99: faded += 1
		else: full += 1
	_check(faded == 32 and full == 224, "the oldest 32 fade, the rest are whole (%d fading, %d whole)" % [faded, full])
	_check(float((all[0] as Dictionary).alpha) < float((all[31] as Dictionary).alpha), "the oldest is the faintest")
	_check(int(st.mark_draws) == 1, "still one draw for 256 marks")
	cam.position = Vector3(-1.5, 2.2, 3.0); cam.look_at(Vector3(-1.5, 2.0, -5))

func _parts_gone() -> void:
	var st: Dictionary = dmg.call(&"get_state")
	_check(int(st.particles) == 0 and int(st.particle_draws) == 0, "three seconds on: no particle left, no particle draw")
