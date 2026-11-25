## Tool: builds scenes/course.tscn, the shared obstacle course (LAB_BRIEF "Obstacle course"), plus the world-contract
## items (breakable bin, window, doors). Layers per WORLD_CONTRACT: world 1, breakables 3 (bit 4), openings 4 (bit 8).
##   godot --headless --path . -s tools/build_course.gd
extends SceneTree

const L_WORLD := 1
const L_BREAKABLE := 4
const L_OPENING := 8

var croot: Node3D
var mats := {}

func mat(name: String, col: Color) -> StandardMaterial3D:
	if mats.has(name): return mats[name]
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.albedo_texture = load("res://course/grid.png")
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(1, 1, 1)
	m.roughness = 0.85
	mats[name] = m
	return m

func box(name: String, size: Vector3, pos: Vector3, m: Material, layer := L_WORLD, rot := Basis.IDENTITY, parent: Node = null) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.name = name
	b.collision_layer = layer
	b.collision_mask = 0
	b.transform = Transform3D(rot, pos)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new(); sh.size = size
	cs.shape = sh
	b.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size
	mi.mesh = bm
	mi.material_override = m
	b.add_child(mi)
	(parent if parent else croot).add_child(b)
	return b

func label(text: String, pos: Vector3) -> void:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.pixel_size = 0.006
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(1, 1, 0.85)
	l.outline_size = 8
	croot.add_child(l)

## A flight of stairs going up along +Z from start (bottom front edge centre).
func stairs(name: String, start: Vector3, riser: float, tread: float, count: int, width: float, m: Material) -> Vector3:
	for i in count:
		var h := riser * (i + 1)
		box("%s_%d" % [name, i], Vector3(width, h, tread), start + Vector3(0, h * 0.5, tread * (i + 0.5)), m)
	return start + Vector3(0, riser * count, tread * count)

func ramp(name: String, start: Vector3, angle_deg: float, rise: float, width: float, m: Material, along_x := false) -> void:
	var a := deg_to_rad(angle_deg)
	var length := rise / sin(a)
	var thick := 0.3
	var rot := Basis(Vector3(1, 0, 0), -a)
	var centre := start + Vector3(0, rise * 0.5 - thick * 0.5 * cos(a), cos(a) * length * 0.5)
	if along_x:
		rot = Basis(Vector3(0, 0, 1), a)
		centre = start + Vector3(cos(a) * length * 0.5, rise * 0.5 - thick * 0.5 * cos(a), 0)
		box(name, Vector3(length, thick, width), centre, m, L_WORLD, rot)
	else:
		box(name, Vector3(width, thick, length), centre, m, L_WORLD, rot)

func _init():
	_make_grid()
	croot = Node3D.new(); croot.name = "Course"
	var grey := mat("ground", Color(0.55, 0.56, 0.58))
	var con := mat("concrete", Color(0.75, 0.73, 0.68))
	var brick := mat("brick", Color(0.62, 0.36, 0.28))
	var metal := mat("metal", Color(0.35, 0.38, 0.42))
	var wood := mat("wood", Color(0.55, 0.42, 0.28))
	var car := mat("car", Color(0.2, 0.32, 0.55))
	var van := mat("van", Color(0.85, 0.85, 0.82))
	var green := mat("planter", Color(0.35, 0.45, 0.3))

	box("Ground", Vector3(400, 1, 400), Vector3(0, -0.5, 0), grey)

	# Row A (z 14..): kerbs and single steps (study 2.8, 3.1)
	var x := -26.0
	for h in [0.10, 0.12, 0.15, 0.16, 0.20, 0.24]:
		box("Kerb_%d" % int(h * 100), Vector3(4, h, 6), Vector3(x, h * 0.5, 17), con)
		label("%s %d cm" % ["kerb" if h < 0.18 else "step", int(round(h * 100))], Vector3(x, h + 0.5, 13.6))
		x += 6.0
	# stairs: 17/28 x 8 up to a landing and down again; steep 19/25 (study 2.7)
	var top := stairs("Stair17", Vector3(12, 0, 14), 0.17, 0.28, 8, 2.0, con)
	box("Stair17_landing", Vector3(2, top.y, 2), Vector3(12, top.y * 0.5, top.z + 1), con)
	for i in 8:
		var h := 0.17 * (8 - i)
		box("Stair17_down_%d" % i, Vector3(2, h, 0.28), Vector3(12, h * 0.5, top.z + 2 + 0.28 * (i + 0.5)), con)
	label("stairs 17/28", Vector3(12, 0.6, 13.4))
	var top2 := stairs("Stair19", Vector3(17, 0, 14), 0.19, 0.25, 8, 2.0, con)
	box("Stair19_landing", Vector3(2, top2.y, 2), Vector3(17, top2.y * 0.5, top2.z + 1), con)
	label("steep 19/25", Vector3(17, 0.6, 13.4))

	# Row B (z 26..): ramps 5, 10, 15, 25 deg to 1 m, and one walked across sideways (study 2.6)
	x = -26.0
	for a in [5.0, 10.0, 15.0, 25.0]:
		ramp("Ramp_%d" % int(a), Vector3(x, 0, 26), a, 1.0, 3.0, con)
		label("ramp %d deg" % int(a), Vector3(x, 0.6, 25.4))
		x += 5.0
	ramp("Ramp_side_10", Vector3(-6, 0, 30), 10.0, 1.0, 4.0, con, true)
	label("ramp 10 deg, across", Vector3(-2, 0.6, 27.4))

	# Row C (z -14): blocks 0.3 .. 3.2 m high, 2 m deep (study 3.1)
	x = -27.0
	for h in [0.3, 0.5, 0.8, 1.0, 1.2, 1.5, 1.8, 2.2, 2.6, 3.2]:
		box("Block_%d" % int(round(h * 100)), Vector3(2, h, 2), Vector3(x, h * 0.5, -14), brick)
		label("block %.1f m" % h, Vector3(x, h + 0.4, -12.6))
		x += 4.0

	# Row D (z -24): fences and railings, car, van, bench, planter (study 3.2, 3.9)
	x = -27.0
	for h in [0.9, 1.1, 1.3]:
		box("Fence_%d" % int(round(h * 100)), Vector3(3, h, 0.05), Vector3(x, h * 0.5, -24), metal)
		label("fence %.1f m" % h, Vector3(x, h + 0.4, -23.4))
		x += 5.0
	# car: body to bonnet 0.85, cabin to roof 1.45 (study 3.9)
	box("Car_body", Vector3(1.8, 0.85, 4.4), Vector3(-10, 0.425, -24), car)
	box("Car_cabin", Vector3(1.6, 0.6, 2.2), Vector3(-10, 1.15, -24.3), car)
	label("car 0.85 / 1.45", Vector3(-10, 1.9, -21.4))
	box("Van", Vector3(2.0, 1.9, 5.2), Vector3(-5, 0.95, -24), van)
	label("van 1.9", Vector3(-5, 2.3, -21))
	box("Bench_seat", Vector3(1.8, 0.45, 0.45), Vector3(0, 0.225, -24), wood)
	box("Bench_back", Vector3(1.8, 0.45, 0.06), Vector3(0, 0.675, -24.2), wood)
	label("bench 0.45", Vector3(0, 1.2, -23.2))
	box("Planter", Vector3(1.2, 0.6, 1.2), Vector3(4, 0.3, -24), green)
	label("planter 0.6", Vector3(4, 1.0, -23))

	# Row E (z -36): ledges with drops 0.3 .. 4.0 m, each with stairs behind (study 3.3)
	x = -27.0
	for h in [0.3, 0.6, 1.0, 1.5, 2.2, 3.0, 4.0]:
		box("Ledge_%d" % int(round(h * 100)), Vector3(3, h, 3), Vector3(x, h * 0.5, -36), con)
		var n := int(ceil(h / 0.17))
		var r: float = h / n
		for i in n:
			var hh: float = r * (i + 1)
			box("Ledge_%d_st_%d" % [int(round(h * 100)), i], Vector3(1.2, hh, 0.28), Vector3(x, hh * 0.5, -37.5 - 0.28 * (n - i - 0.5)), con)
		label("drop %.1f m" % h, Vector3(x, h + 0.4, -34.2))
		x += 5.5

	# Row F (z -50): wall tops 60 / 30 / 20 cm, a 10 cm pipe, all 1.0 m high, 10 m long, steps to get up (study 3.5)
	x = -26.0
	for w in [0.6, 0.3, 0.2]:
		box("WallTop_%d" % int(round(w * 100)), Vector3(w, 1.0, 10), Vector3(x, 0.5, -56), brick)
		stairs("WallTop_%d_st" % int(round(w * 100)), Vector3(x + 1.2, 0, -62.0), 0.2, 0.3, 5, 1.0, con)
		label("wall top %d cm" % int(round(w * 100)), Vector3(x, 1.5, -50.5))
		x += 5.0
	var pipe := StaticBody3D.new(); pipe.name = "Pipe_10"; pipe.collision_layer = L_WORLD; pipe.collision_mask = 0
	pipe.transform = Transform3D(Basis(Vector3(1, 0, 0), PI * 0.5), Vector3(x, 1.0, -56))
	var pcs := CollisionShape3D.new(); var cyl := CylinderShape3D.new(); cyl.radius = 0.05; cyl.height = 10; pcs.shape = cyl
	pipe.add_child(pcs)
	var pmi := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.05; cm.bottom_radius = 0.05; cm.height = 10
	pmi.mesh = cm; pmi.material_override = metal; pipe.add_child(pmi)
	croot.add_child(pipe)
	box("Pipe_support_a", Vector3(0.1, 0.95, 0.1), Vector3(x, 0.475, -51.2), metal)
	box("Pipe_support_b", Vector3(0.1, 0.95, 0.1), Vector3(x, 0.475, -60.8), metal)
	label("pipe 10 cm", Vector3(x, 1.5, -50.5))

	# Row G (x +30 side): low ceiling 1.25 m, cover walls 1.0 / 2.0 with outside corners, a 0.6 m gap (study 3.6, 3.7)
	box("Ceiling_post_a", Vector3(0.3, 1.25, 0.3), Vector3(30, 0.625, -10), con)
	box("Ceiling_post_b", Vector3(0.3, 1.25, 0.3), Vector3(34, 0.625, -10), con)
	box("Ceiling_post_c", Vector3(0.3, 1.25, 0.3), Vector3(30, 0.625, -6), con)
	box("Ceiling_post_d", Vector3(0.3, 1.25, 0.3), Vector3(34, 0.625, -6), con)
	box("Ceiling_slab", Vector3(4.4, 0.2, 4.4), Vector3(32, 1.35, -8), con)
	label("ceiling 1.25 m", Vector3(32, 1.9, -5.4))
	box("Cover_low_a", Vector3(4, 1.0, 0.3), Vector3(32, 0.5, 2), brick)
	box("Cover_low_b", Vector3(0.3, 1.0, 3), Vector3(34.15, 0.5, 3.35), brick)
	label("cover 1.0 m", Vector3(32, 1.4, 1.2))
	box("Cover_high_a", Vector3(4, 2.0, 0.3), Vector3(32, 1.0, 10), brick)
	box("Cover_high_b", Vector3(0.3, 2.0, 3), Vector3(34.15, 1.0, 11.35), brick)
	label("cover 2.0 m", Vector3(32, 2.4, 9.2))
	box("Gap_a", Vector3(3, 1.0, 3), Vector3(30.2, 0.5, 20), con)
	box("Gap_b", Vector3(3, 1.0, 3), Vector3(33.8, 0.5, 20), con)
	stairs("Gap_st", Vector3(30.2, 0, 16.0), 0.2, 0.3, 5, 1.2, con)
	label("gap 0.6 m", Vector3(32, 1.5, 18.2))

	# Contract items (WORLD_CONTRACT 4): doors (push, pull) and a window in a wall, all layer 4; a breakable bin, layer 3
	var wall := brick
	for side in [["Push", 40.0], ["Pull", 46.0]]:
		var zx: float = side[1]
		box("DoorWall_%s_l" % side[0], Vector3(0.2, 2.4, 2.0), Vector3(zx, 1.2, -1.45), wall)
		box("DoorWall_%s_r" % side[0], Vector3(0.2, 2.4, 2.0), Vector3(zx, 1.2, 1.45), wall)
		box("DoorWall_%s_top" % side[0], Vector3(0.2, 0.3, 0.9), Vector3(zx, 2.25, 0), wall)
		var d := box("Door_%s" % side[0], Vector3(0.05, 2.1, 0.88), Vector3(zx, 1.05, 0), wood, L_OPENING)
		d.set_meta("door", side[0].to_lower())
		label("%s door" % side[0].to_lower(), Vector3(zx - 0.8, 2.4, 0))
	box("WindowWall_low", Vector3(0.2, 0.9, 1.2), Vector3(52, 0.45, 0), wall)
	box("WindowWall_top", Vector3(0.2, 0.4, 1.2), Vector3(52, 2.2, 0), wall)
	box("WindowWall_l", Vector3(0.2, 2.4, 2.0), Vector3(52, 1.2, -1.6), wall)
	box("WindowWall_r", Vector3(0.2, 2.4, 2.0), Vector3(52, 1.2, 1.6), wall)
	var glass := StandardMaterial3D.new(); glass.albedo_color = Color(0.6, 0.8, 0.9, 0.35)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var win := box("Window", Vector3(0.03, 1.1, 1.2), Vector3(52, 1.45, 0), glass, L_OPENING)
	win.set_meta("window", true)
	label("window (sill 0.9)", Vector3(51.2, 2.6, 0))
	var bin := box("Bin_breakable", Vector3(0.6, 1.1, 0.6), Vector3(40, 0.55, 8), metal, L_BREAKABLE)
	bin.set_meta("breakable", true)
	label("bin (breakable)", Vector3(40, 1.6, 8))

	# light and sky
	var sun := DirectionalLight3D.new(); sun.name = "Sun"
	sun.transform = Transform3D(Basis.from_euler(Vector3(deg_to_rad(-50), deg_to_rad(35), 0)), Vector3(0, 10, 0))
	sun.shadow_enabled = true
	croot.add_child(sun)
	var env := WorldEnvironment.new(); env.name = "Env"
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new(); sky.sky_material = ProceduralSkyMaterial.new(); e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	croot.add_child(env)

	_own(croot, croot)
	var ps := PackedScene.new()
	var err := ps.pack(croot)
	err = ResourceSaver.save(ps, "res://scenes/course.tscn") if err == OK else err
	print("course saved: ", err)
	quit()

func _own(n: Node, owner: Node) -> void:
	for c in n.get_children():
		c.owner = owner
		_own(c, owner)

func _make_grid() -> void:
	if FileAccess.file_exists("res://course/grid.png"): return
	var img := Image.create(256, 256, false, Image.FORMAT_RGB8)
	for y in 256:
		for x in 256:
			var line := (x % 128) < 3 or (y % 128) < 3
			var fine := (x % 32) < 1 or (y % 32) < 1
			var v := 0.62 if line else (0.82 if fine else 0.9)
			img.set_pixel(x, y, Color(v, v, v))
	img.save_png("res://course/grid.png")
