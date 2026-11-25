extends SceneTree
# Tool: builds course.tscn (the shared obstacle course from the brief + survey findings) and main.tscn (course, player,
# camera, light). Run: godot --headless -s tools/build_course.gd
# Layout: the player starts at the origin facing +Z. Lanes run along +Z, spaced along X.

var croot: Node3D
var mats := {}

func mat(c: Color) -> StandardMaterial3D:
	var k = c.to_html()
	if not mats.has(k):
		var m = StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.85
		mats[k] = m
	return mats[k]

func box(name: String, size: Vector3, pos: Vector3, col := Color(0.62, 0.6, 0.56), rot := Vector3.ZERO, parent: Node3D = null) -> StaticBody3D:
	var b = StaticBody3D.new()
	b.name = name
	b.position = pos
	b.rotation = rot
	var cs = CollisionShape3D.new()
	var sh = BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat(col)
	b.add_child(cs)
	b.add_child(mi)
	(parent if parent else croot).add_child(b)
	return b

func cyl(name: String, r: float, h: float, pos: Vector3, rot: Vector3, col: Color) -> void:
	var b = StaticBody3D.new()
	b.name = name
	b.position = pos
	b.rotation = rot
	var cs = CollisionShape3D.new()
	var sh = CylinderShape3D.new()
	sh.radius = r
	sh.height = h
	cs.shape = sh
	var mi = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	mi.mesh = cm
	mi.material_override = mat(col)
	b.add_child(cs)
	b.add_child(mi)
	croot.add_child(b)

func label(text: String, pos: Vector3) -> void:
	var l = Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = 48
	l.pixel_size = 0.004
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(1, 1, 0.85)
	l.outline_size = 8
	croot.add_child(l)

# a block of height h standing on the ground, front face at z
func block(name: String, h: float, x: float, z: float, w := 2.0, depth := 2.0, col := Color(0.55, 0.57, 0.6)) -> void:
	box(name, Vector3(w, h, depth), Vector3(x, h * 0.5, z + depth * 0.5), col)

func stairs(name: String, x: float, z: float, riser: float, tread: float, n: int, w := 1.6, landing := 2.0, down := true) -> float:
	var col = Color(0.7, 0.68, 0.64)
	for i in n:
		var h = riser * (i + 1)
		box("%s_up%d" % [name, i], Vector3(w, h, tread), Vector3(x, h * 0.5, z + tread * (i + 0.5)), col)
	var top = riser * n
	var zl = z + tread * n
	box("%s_landing" % name, Vector3(w, top, landing), Vector3(x, top * 0.5, zl + landing * 0.5), col.darkened(0.1))
	var zd = zl + landing
	if down:
		for i in n:
			var h = riser * (n - i - 1)
			if h <= 0.001:
				continue
			box("%s_dn%d" % [name, i], Vector3(w, h, tread), Vector3(x, h * 0.5, zd + tread * (i + 0.5)), col)
		zd += tread * n
	return zd

func ramp(name: String, deg: float, x: float, z: float, run := 6.0, w := 2.0, sideways := false) -> void:
	# a wedge made of a rotated slab, then a top and a way down
	var a = deg_to_rad(deg)
	var rise = run * tan(a)
	var length = run / cos(a)
	var t = 0.3
	var b = box(name, Vector3(w, t, length), Vector3(x, rise * 0.5 - t * 0.5 / cos(a), z + run * 0.5), Color(0.6, 0.62, 0.58), Vector3(-a, 0, 0))
	box(name + "_top", Vector3(w, rise, 2.0), Vector3(x, rise * 0.5, z + run + 1.0), Color(0.6, 0.62, 0.58))

func fence(name: String, h: float, x: float, z: float, w := 3.0, thick := 0.05) -> void:
	var col = Color(0.2, 0.22, 0.25)
	box(name + "_rail", Vector3(w, 0.05, thick), Vector3(x, h - 0.025, z), col)
	var posts = int(w / 1.0) + 1
	for i in posts:
		box("%s_post%d" % [name, i], Vector3(0.05, h, 0.05), Vector3(x - w * 0.5 + i * w / (posts - 1), h * 0.5, z), col)
	for i in int(w / 0.12):
		box("%s_bar%d" % [name, i], Vector3(0.02, h - 0.1, 0.02), Vector3(x - w * 0.5 + 0.06 + i * 0.12, (h - 0.1) * 0.5 + 0.05, z), col)

func _init():
	croot = Node3D.new()
	croot.name = "Course"
	# ground
	box("Ground", Vector3(260, 1, 260), Vector3(0, -0.5, 60), Color(0.36, 0.4, 0.34))
	# a grid of lines for scale (every 1 m along the start straight)
	for i in range(0, 40, 2):
		box("mark%d" % i, Vector3(3.0, 0.002, 0.04), Vector3(0, 0.001, i), Color(0.85, 0.85, 0.8))
	label("START: open ground (walk, run, start, stop, turn)", Vector3(0, 2.4, 3))

	# lane A (x = 8): kerbs 10, 12, 15, 16 cm and single steps 20, 24 cm (pavement slabs 3 m deep)
	var x = 8.0
	var z = 4.0
	label("kerbs 10 12 15 16 cm, steps 20 24 cm", Vector3(x, 2.4, z - 1))
	for h in [0.10, 0.12, 0.15, 0.16, 0.20, 0.24]:
		box("kerb_%d" % int(h * 100), Vector3(3, h, 3), Vector3(x, h * 0.5, z + 1.5), Color(0.72, 0.72, 0.7))
		label("%d cm" % int(round(h * 100)), Vector3(x + 1.8, h + 0.3, z + 0.2))
		z += 6.0

	# lane B (x = 14): stairs 17/28, 8 up, landing, 8 down; then a steep flight 19/25; then the city's 16.7/30 stoop
	x = 14.0
	label("stairs 17/28 x8, steep 19/25 x8, stoop 3x16.7 to porch", Vector3(x, 2.6, 2))
	z = stairs("stair17", x, 4.0, 0.17, 0.28, 8)
	z = stairs("stair19", x, z + 4.0, 0.19, 0.25, 8)
	stairs("stoop", x, z + 4.0, 0.167, 0.30, 3, 1.6, 3.0, false)

	# lane C (x = 20): ramps 5, 10, 15, 25 deg
	x = 20.0
	z = 4.0
	label("ramps 5 10 15 25 deg", Vector3(x, 2.4, 2))
	for d in [5.0, 10.0, 15.0, 25.0]:
		ramp("ramp%d" % int(d), d, x, z)
		label("%d deg" % int(d), Vector3(x + 1.6, 1.0, z + 1))
		z += 12.0
	# a 10 deg cross-slope, walked across sideways (lane runs along z, slope rises along x)
	label("cross-slope 10 deg (walk along it)", Vector3(26, 2.4, 2))
	var a = deg_to_rad(10.0)
	box("cross10", Vector3(4.0 / cos(a), 0.3, 16), Vector3(26, 2.0 * tan(a) - 0.15, 12), Color(0.58, 0.6, 0.55), Vector3(0, 0, a))

	# lane D (x = -8): blocks 0.3 ... 3.2 m, deep enough to stand on
	x = -8.0
	z = 4.0
	label("blocks 0.3 0.5 0.8 1.0 1.2 1.5 1.8 2.2 2.6 3.2 m", Vector3(x, 3.8, 2))
	for h in [0.3, 0.5, 0.8, 1.0, 1.2, 1.5, 1.8, 2.2, 2.6, 3.2]:
		block("block_%d" % int(h * 100), h, x, z, 2.4, 2.4)
		label("%.1f m" % h, Vector3(x + 1.6, h + 0.3, z))
		z += 5.0

	# lane E (x = -14): fences 0.9, 1.1, 1.3 m (+ the city's 1.26 wrought iron and 1.84 privacy fence), bench, planter
	x = -14.0
	z = 4.0
	label("fences 0.9 1.1 1.3 (city: 1.26, 1.84), bench 0.45, planter 0.6", Vector3(x, 2.6, 2))
	for h in [0.9, 1.1, 1.26, 1.3, 1.84]:
		fence("fence_%d" % int(h * 100), h, x, z)
		label("%.2f m" % h, Vector3(x + 1.8, h + 0.3, z))
		z += 5.0
	# bench: seat 0.45 m (city 0.46-0.48), back 0.9 m
	box("bench_seat", Vector3(1.8, 0.06, 0.45), Vector3(x, 0.42, z + 0.25), Color(0.45, 0.3, 0.18))
	box("bench_legs", Vector3(1.6, 0.39, 0.35), Vector3(x, 0.195, z + 0.25), Color(0.2, 0.2, 0.2))
	box("bench_back", Vector3(1.8, 0.4, 0.05), Vector3(x, 0.7, z + 0.47), Color(0.45, 0.3, 0.18))
	label("bench 0.45", Vector3(x + 1.6, 1.0, z))
	z += 5.0
	box("planter", Vector3(1.5, 0.6, 1.5), Vector3(x, 0.3, z + 0.75), Color(0.5, 0.45, 0.4))
	label("planter 0.6", Vector3(x + 1.6, 1.0, z))

	# lane F (x = -20): a car (bonnet 0.85, roof 1.45) and a van (roof 1.9)
	x = -20.0
	label("car (bonnet 0.85, roof 1.45), van (roof 1.9)", Vector3(x, 2.8, 2))
	var cc = Color(0.55, 0.12, 0.1)
	box("car_body", Vector3(1.8, 0.6, 4.4), Vector3(x, 0.25 + 0.3, 8.2), cc)
	box("car_cabin", Vector3(1.6, 0.6, 2.2), Vector3(x, 0.85 + 0.3, 8.0), cc.lightened(0.2))
	box("van", Vector3(2.0, 1.6, 5.2), Vector3(x, 0.3 + 0.8, 16.6), Color(0.85, 0.85, 0.88))
	box("van_wheels", Vector3(1.9, 0.3, 4.6), Vector3(x, 0.15, 16.6), Color(0.1, 0.1, 0.1))
	box("car_wheels", Vector3(1.7, 0.25, 3.8), Vector3(x, 0.125, 8.2), Color(0.1, 0.1, 0.1))

	# lane G (x = 34): ledges with drops 0.3 0.6 1.0 1.5 2.2 3.0 4.0 m (a 4 m deck reached by stairs, steps down)
	x = 34.0
	label("drops 0.3 0.6 1.0 1.5 2.2 3.0 4.0 m (deck 4 m, stairs up)", Vector3(x, 5.6, 2))
	stairs("deckstair", x, 4.0, 0.17, 0.28, 23, 1.6, 0.1, false)
	var zd = 4.0 + 0.28 * 23
	box("deck", Vector3(14, 3.91, 6), Vector3(x + 6.2, 3.91 * 0.5, zd + 3), Color(0.5, 0.5, 0.55))
	var ledge_x = x + 1.0
	var hz = zd + 6.0
	for d in [0.3, 0.6, 1.0, 1.5, 2.2, 3.0, 4.0]:
		var top = 3.91 - d
		if top > 0.01:
			box("drop_%d" % int(d * 100), Vector3(1.8, top, 3), Vector3(ledge_x, top * 0.5, hz + 1.5), Color(0.45, 0.47, 0.52))
		label("drop %.1f" % d, Vector3(ledge_x, 4.4, hz - 0.2))
		ledge_x += 2.0

	# lane H (x = -28): wall tops 60, 30, 20 cm wide, a 10 cm pipe (1 m up, reached by a 1 m block)
	x = -28.0
	label("wall tops 60 30 20 cm, pipe 10 cm (1 m high)", Vector3(x, 2.6, 2))
	block("walltop_start", 1.0, x, 3.0, 2.0, 1.0)
	var wx = [x - 0.9, x - 0.3, x + 0.3, x + 0.9]
	box("walltop_60", Vector3(0.6, 1.0, 10), Vector3(x - 1.6, 0.5, 9.0), Color(0.75, 0.7, 0.62))
	box("walltop_30", Vector3(0.3, 1.0, 10), Vector3(x - 0.4, 0.5, 9.0), Color(0.75, 0.7, 0.62))
	box("walltop_20", Vector3(0.2, 1.0, 10), Vector3(x + 0.5, 0.5, 9.0), Color(0.75, 0.7, 0.62))
	cyl("pipe_10", 0.05, 10, Vector3(x + 1.4, 0.95, 9.0), Vector3(PI * 0.5, 0, 0), Color(0.4, 0.4, 0.42))

	# lane I (x = -36): a 1.25 m low ceiling, cover walls 1.0 and 2.0 m with outside corners, a 0.6 m gap
	x = -36.0
	label("low ceiling 1.25, cover 1.0 / 2.0 m, gap 0.6", Vector3(x, 2.8, 2))
	box("ceiling_l", Vector3(0.3, 1.25, 4), Vector3(x - 1.2, 0.625, 6), Color(0.5, 0.5, 0.5))
	box("ceiling_r", Vector3(0.3, 1.25, 4), Vector3(x + 1.2, 0.625, 6), Color(0.5, 0.5, 0.5))
	box("ceiling", Vector3(2.7, 0.2, 4), Vector3(x, 1.35, 6), Color(0.5, 0.5, 0.5))
	box("cover_1m", Vector3(4, 1.0, 0.4), Vector3(x, 0.5, 12), Color(0.6, 0.55, 0.5))
	box("cover_2m", Vector3(4, 2.0, 0.4), Vector3(x, 1.0, 16), Color(0.6, 0.55, 0.5))
	box("gap_l", Vector3(3, 2.4, 0.4), Vector3(x - 1.8, 1.2, 21), Color(0.65, 0.6, 0.55))
	box("gap_r", Vector3(3, 2.4, 0.4), Vector3(x + 1.8, 1.2, 21), Color(0.65, 0.6, 0.55))

	# lane J (x = 44): a push door and a pull door (frames only for now; the doors themselves come in step 7)
	x = 44.0
	label("doors: push (z 6), pull (z 12) - step 7", Vector3(x, 2.8, 2))
	for dz in [6.0, 12.0]:
		box("doorwall_l_%d" % int(dz), Vector3(2.0, 2.4, 0.2), Vector3(x - 1.45, 1.2, dz), Color(0.7, 0.66, 0.6))
		box("doorwall_r_%d" % int(dz), Vector3(2.0, 2.4, 0.2), Vector3(x + 1.45, 1.2, dz), Color(0.7, 0.66, 0.6))
		box("doorhead_%d" % int(dz), Vector3(0.9, 0.3, 0.2), Vector3(x, 2.25, dz), Color(0.7, 0.66, 0.6))

	# WORLD_CONTRACT.md 4: a breakable bin stand-in (layer 3), a window and a door (layer 4), debris (layer 7)
	x = 2.5
	label("contract: bin (layer 3), debris (layer 7) on the path", Vector3(x, 2.2, 20))
	var bin = box("bin_breakable", Vector3(0.5, 1.03, 0.5), Vector3(x, 0.515, 22), Color(0.15, 0.35, 0.18))
	bin.collision_layer = 4
	bin.collision_mask = 1 | 4 | 16
	var deb = box("debris_slab", Vector3(0.6, 0.12, 0.5), Vector3(0, 0.06, 30), Color(0.3, 0.3, 0.3))
	deb.collision_layer = 64
	deb.collision_mask = 1 | 4 | 16
	x = 44.0
	for dz in [6.0, 12.0]:
		var leaf = box("door_leaf_%d" % int(dz), Vector3(0.9, 2.1, 0.05), Vector3(x, 1.05, dz), Color(0.45, 0.3, 0.2))
		leaf.collision_layer = 8
	box("window_wall_l", Vector3(2.0, 2.4, 0.2), Vector3(x - 1.45, 1.2, 18), Color(0.7, 0.66, 0.6))
	box("window_wall_r", Vector3(2.0, 2.4, 0.2), Vector3(x + 1.45, 1.2, 18), Color(0.7, 0.66, 0.6))
	box("window_sill", Vector3(0.9, 0.9, 0.2), Vector3(x, 0.45, 18), Color(0.7, 0.66, 0.6))
	box("window_head", Vector3(0.9, 0.3, 0.2), Vector3(x, 2.25, 18), Color(0.7, 0.66, 0.6))
	var pane = box("window_pane", Vector3(0.9, 1.05, 0.02), Vector3(x, 1.425, 18), Color(0.6, 0.8, 0.9, 1.0))
	pane.collision_layer = 8
	label("window (layer 4), sill 0.9 m", Vector3(x, 2.8, 17))

	# the real street (survey section 16): city-kit piece s_apt (15 cm kerbs, bench, bin), a porch house, a park bench
	var street = Node3D.new()
	street.name = "RealStreet"
	street.position = Vector3(-60, 0, -20)
	croot.add_child(street)
	var piece = load("res://map_dc/coronado/city_kit/pieces/s_apt.scn").instantiate()
	street.add_child(piece)
	var kit = "res://assets/coronado_kit/"
	var house = load(kit + "buildings/houses/ranch_porch/house_ranch_porch_near.glb").instantiate()
	house.position = Vector3(-15.0, 0.15, 40.0)
	house.rotation.y = PI * 0.5
	street.add_child(house)
	var hcol = col_body(kit + "buildings/houses/ranch_porch/house_ranch_porch_col.glb", "house_col")
	hcol.position = house.position
	hcol.rotation = house.rotation
	street.add_child(hcol)
	var bench = load(kit + "props/park/prop_park_bench_clean_near.glb").instantiate()
	bench.position = Vector3(-7.5, 0.15, 30.0)
	street.add_child(bench)
	var bcol = col_body(kit + "props/park/prop_park_bench_col.glb", "bench_col")
	bcol.position = bench.position
	street.add_child(bcol)
	label("REAL STREET: city kit s_apt (kerb 15 cm), porch house, bench", Vector3(-60, 3.0, -16))

	for c in croot.get_children():
		set_owner_rec(c, croot)
	var ps = PackedScene.new()
	ps.pack(croot)
	ResourceSaver.save(ps, "res://course.tscn")
	build_main()
	quit()

# collision from a kit *_col.glb: its shapes copied into one StaticBody3D (layer 1), without the helper mesh
func col_body(path: String, nm: String) -> StaticBody3D:
	var inst = load(path).instantiate()
	var b = StaticBody3D.new()
	b.name = nm
	for cs in inst.find_children("*", "CollisionShape3D", true, false):
		var n = CollisionShape3D.new()
		n.shape = cs.shape
		n.transform = inst.global_transform.affine_inverse() * cs.global_transform if cs.is_inside_tree() else cs.transform
		var p = cs.get_parent()
		while p != null and p != inst:
			n.transform = p.transform * n.transform
			p = p.get_parent()
		b.add_child(n)
	inst.free()
	return b

func set_owner_rec(n: Node, o: Node) -> void:
	n.owner = o
	if n.scene_file_path != "":
		return # an instanced piece stays a reference to its file
	for c in n.get_children():
		set_owner_rec(c, o)

func build_main() -> void:
	var m = Node3D.new()
	m.name = "Main"
	var course = load("res://course.tscn").instantiate()
	m.add_child(course)
	course.owner = m
	var env = WorldEnvironment.new()
	var e = Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	m.add_child(env)
	env.owner = m
	var sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation = Vector3(deg_to_rad(-50), deg_to_rad(-35), 0)
	sun.shadow_enabled = true
	m.add_child(sun)
	sun.owner = m
	var p = ClassDB.instantiate("LabPlayer")
	p.name = "Player"
	m.add_child(p)
	p.owner = m
	var cs = CollisionShape3D.new()
	cs.name = "Capsule"
	var cap = CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.5
	cs.shape = cap
	cs.position = Vector3(0, 0.25 + 0.75, 0)
	p.add_child(cs)
	cs.owner = m
	var body = load("res://body/player_v3.glb").instantiate()
	body.name = "Body"
	p.add_child(body)
	body.owner = m
	var sk = body.get_node("Armature/GeneralSkeleton")
	var poser = ClassDB.instantiate("LabPoser")
	poser.name = "LabPoser"
	sk.add_child(poser)
	poser.owner = m
	var cam = ClassDB.instantiate("LabCamera")
	cam.name = "CameraRig"
	m.add_child(cam)
	cam.owner = m
	cam.set("target_path", NodePath("../Player"))
	p.set("camera_path", NodePath("../CameraRig"))
	var ps = PackedScene.new()
	ps.pack(m)
	ResourceSaver.save(ps, "res://main.tscn")
	print("built course.tscn and main.tscn")
