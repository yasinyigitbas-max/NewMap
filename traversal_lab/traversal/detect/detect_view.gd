extends Node3D
## Stage 7: the debug drawing of the detection record (the study: "a debug drawing of its record (edge line, top
## height, depth, landing point, fit box)"). Green = usable, red = blocked or no room, yellow = measurements.
## It measures ten times a second, for the eye only; the game is to measure when a move is asked for.

const Detector := preload("res://traversal/detect/detector.gd")
const EVERY := 6                # ticks between measurements here

var body: CharacterBody3D
var record: Dictionary = {"kind": "none"}
var detector: RefCounted
var _mesh := ImmediateMesh.new()
var _mat := StandardMaterial3D.new()
var _text := Label.new()
var _tick := 0


func _ready() -> void:
	top_level = true
	detector = Detector.new()
	detector.set(&"body", body)
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.vertex_color_use_as_albedo = true
	_mat.no_depth_test = true
	var mi := MeshInstance3D.new()
	mi.mesh = _mesh
	mi.material_override = _mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	var layer := CanvasLayer.new()
	add_child(layer)
	_text.position = Vector2(12, 470)
	_text.add_theme_font_size_override(&"font_size", 18)
	_text.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_text.add_theme_constant_override(&"outline_size", 6)
	layer.add_child(_text)


func _physics_process(_dt: float) -> void:
	_tick += 1
	if body == null or _tick % EVERY != 0:
		return
	record = detector.call(&"measure", -body.global_transform.basis.z)
	_text.text = "detect  %s   (%d queries)" % [Detector.words(record), int(record.get("queries", 0))]
	_draw()


func _line(a: Vector3, b: Vector3, c: Color) -> void:
	_mesh.surface_set_color(c)
	_mesh.surface_add_vertex(a)
	_mesh.surface_set_color(c)
	_mesh.surface_add_vertex(b)


func _box(feet: Vector3, half: float, tall: float, c: Color) -> void:
	var p := [Vector3(-half, 0, -half), Vector3(half, 0, -half), Vector3(half, 0, half), Vector3(-half, 0, half)]
	for i in 4:
		_line(feet + p[i], feet + p[(i + 1) % 4], c)
		_line(feet + p[i] + Vector3.UP * tall, feet + p[(i + 1) % 4] + Vector3.UP * tall, c)
		_line(feet + p[i], feet + p[i] + Vector3.UP * tall, c)


func _draw() -> void:
	_mesh.clear_surfaces()
	var kind := String(record.get("kind", "none"))
	if kind == "none":
		return
	var good := Color(0.2, 1.0, 0.3)
	var bad := Color(1.0, 0.25, 0.2)
	var note := Color(1.0, 0.9, 0.2)
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var edge: Vector3 = record["edge"]
	var n: Vector3 = record["normal"]
	var side := n.cross(Vector3.UP).normalized()
	var rad := float(body.get(&"RADIUS"))
	var tall := float(body.get(&"HEIGHT"))
	if kind == "obstacle":
		var usable := not bool(record.get("blocked", false)) and not bool(record.get("too_high", false))
		var c := good if usable else bad
		# the edge line, and the top height as a post from his ground up to it
		_line(edge - side * 0.6, edge + side * 0.6, c)
		_line(Vector3(edge.x, float(record["ground"]), edge.z), edge, note)
		if record["top"] != INF:
			# the depth, and the far edge
			var far: Vector3 = record["far_edge"]
			_line(edge, far, note)
			_line(far - side * 0.3, far + side * 0.3, note)
			# the fit box on top
			if not bool(record["thin"]):
				_box(record["stand_at"], rad, tall if bool(record["stand_room"]) else float(body.get(&"CROUCH_HEIGHT")), good if bool(record["stand_room"]) else (note if bool(record["crouch_room"]) else bad))
	else:
		_line(edge - side * 0.6, edge + side * 0.6, note)
		if record.has("far_edge"):
			var far: Vector3 = record["far_edge"]
			_line(edge, far, note)
			_line(far - side * 0.6, far + side * 0.6, good)
	# the landing point: a cross on the ground and the fit box over it
	if record.has("land_at"):
		var l: Vector3 = record["land_at"]
		var c := good if bool(record.get("landing_ok", false)) else bad
		_line(l - Vector3(0.2, 0, 0), l + Vector3(0.2, 0, 0), c)
		_line(l - Vector3(0, 0, 0.2), l + Vector3(0, 0, 0.2), c)
		_box(l, rad, tall, c)
	_mesh.surface_end()
