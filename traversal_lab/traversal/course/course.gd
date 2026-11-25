extends Node3D
## Stage 0: the measured grey-box test course. Every obstacle is built at an exact, labelled size.
## Stations stand side by side along X; each is approached by walking toward -Z from its start point.
## `stations` lists them for the readout, the teleport keys and the tests.

const LANE := 4.0                      # metres between station centres
const GROUND_SIZE := Vector3(280.0, 1.0, 120.0)

var stations: Array[Dictionary] = []   # {id, kind, label, start, top, size, pos, ...}
var _x := 0.0
var _grey := StandardMaterial3D.new()
var _dark := StandardMaterial3D.new()


func _ready() -> void:
	_grey.albedo_color = Color(0.62, 0.64, 0.66)
	_dark.albedo_color = Color(0.36, 0.38, 0.42)
	_ground()
	for h: float in [0.10, 0.15, 0.20]:
		_platform("kerb", h, 4.0)
	for i in 11:
		_platform("step", 0.10 + 0.05 * i, 3.0)
	_stairs(0.18, 0.28, 10)
	_stairs(0.25, 0.26, 8)
	for deg: float in [5.0, 10.0, 19.0, 30.0, 45.0, 60.0]:
		_ramp(deg)
	for h: float in [0.50, 0.62, 0.80, 1.00, 1.10, 1.40, 1.80, 2.20, 2.30, 2.46, 2.60, 3.00]:
		_wall(h, 0.20)
	for h: float in [0.50, 0.62, 0.80, 1.00, 1.10, 1.40, 1.80, 2.20, 2.30, 2.46, 2.60, 3.00]:
		_wall(h, 2.50)
	for w: float in [0.5, 1.0, 1.5, 2.0]:
		_gap(w)
	for w: float in [0.25, 0.10, 0.05]:
		_beam(w)
	for w: float in [0.4, 0.5, 0.6, 0.8]:
		_passage(w)
	for c: float in [1.9, 1.7, 1.5, 1.2]:
		_overhang(c)
	_floor_pieces()
	_floor_one_mesh()


# ---------------------------------------------------------------- building blocks

func _box(center: Vector3, size: Vector3, mat: Material = null, rot_x_deg := 0.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = center
	body.rotation_degrees.x = rot_x_deg
	var shape := BoxShape3D.new()
	shape.size = size
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat if mat else _grey
	body.add_child(mi)
	add_child(body)
	return body


func _label(text: String, at: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = at
	l.pixel_size = 0.004
	l.font_size = 64
	l.outline_size = 12
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = false
	add_child(l)
	return l


func _station(kind: String, label: String, extra: Dictionary = {}) -> Dictionary:
	var s := {"id": "%s_%02d" % [kind, stations.size()], "kind": kind, "label": label,
			"start": Vector3(_x, 0.0, 0.0), "x": _x}
	s.merge(extra)
	stations.append(s)
	_label(label, Vector3(_x, float(extra.get("label_y", 2.2)), -2.0))
	_x += LANE
	return s


func _ground() -> void:
	_box(Vector3(GROUND_SIZE.x * 0.5 - 10.0, -0.5, -GROUND_SIZE.z * 0.5 + 20.0), GROUND_SIZE, _dark)


# ---------------------------------------------------------------- stations

func _platform(kind: String, h: float, depth: float) -> void:
	var x := _x
	_box(Vector3(x, h * 0.5, -3.0 - depth * 0.5), Vector3(3.0, h, depth))
	_station(kind, "%s %.2f m" % [kind, h], {"top": h, "edge_z": -3.0, "depth": depth,
			"probe": Vector3(x, 0.0, -3.0 - depth * 0.5)})


func _stairs(riser: float, tread: float, steps: int) -> void:
	var x := _x
	for i in steps:
		var h := riser * (i + 1)
		_box(Vector3(x, h * 0.5, -3.0 - tread * (i + 0.5)), Vector3(2.4, h, tread))
	var top := riser * steps
	var end_z := -3.0 - tread * steps
	_box(Vector3(x, top * 0.5, end_z - 1.5), Vector3(2.4, top, 3.0))
	_station("stairs", "stairs %.2f / %.2f m x %d" % [riser, tread, steps], {"top": top, "riser": riser,
			"tread": tread, "steps": steps, "edge_z": -3.0, "label_y": top + 2.0,
			"probe": Vector3(x, 0.0, end_z - 1.5)})


func _ramp(deg: float) -> void:
	var x := _x
	var rise := 1.5
	var run := rise / tan(deg_to_rad(deg))
	var length := sqrt(rise * rise + run * run)
	var thick := 0.3
	# the ramp surface runs from (z = -3, y = 0) up to (z = -3 - run, y = rise)
	var mid := Vector3(x, rise * 0.5, -3.0 - run * 0.5)
	var normal := Vector3(0.0, cos(deg_to_rad(deg)), sin(deg_to_rad(deg)))
	_box(mid - normal * thick * 0.5, Vector3(2.4, thick, length), null, deg)
	_box(Vector3(x, rise * 0.5, -3.0 - run - 1.5), Vector3(2.4, rise, 3.0))
	_station("ramp", "ramp %d deg" % int(deg), {"top": rise, "deg": deg, "run": run, "edge_z": -3.0,
			"label_y": rise + 2.0, "probe": Vector3(x, 0.0, -3.0 - run - 1.5),
			"mid": Vector3(x, 0.0, -3.0 - run * 0.5)})


func _wall(h: float, depth: float) -> void:
	var x := _x
	_box(Vector3(x, h * 0.5, -3.0 - depth * 0.5), Vector3(3.0, h, depth))
	var kind := "wall_thin" if depth < 1.0 else "wall_deep"
	_station(kind, "%s %.2f m" % ["thin wall" if depth < 1.0 else "deep wall", h], {"top": h,
			"depth": depth, "edge_z": -3.0, "label_y": maxf(h + 0.8, 2.2),
			"probe": Vector3(x, 0.0, -3.0 - depth * 0.5)})


func _gap(w: float) -> void:
	var x := _x
	var deck := 1.0
	# a 10 degree ramp up to deck A, the gap, then deck B
	var run := deck / tan(deg_to_rad(10.0))
	var length := sqrt(deck * deck + run * run)
	var n := Vector3(0.0, cos(deg_to_rad(10.0)), sin(deg_to_rad(10.0)))
	_box(Vector3(x, deck * 0.5, -3.0 - run * 0.5) - n * 0.15, Vector3(2.4, 0.3, length), null, 10.0)
	var a_start := -3.0 - run
	_box(Vector3(x, deck * 0.5, a_start - 2.0), Vector3(2.4, deck, 4.0))
	var b_start := a_start - 4.0 - w
	_box(Vector3(x, deck * 0.5, b_start - 2.0), Vector3(2.4, deck, 4.0))
	_station("gap", "gap %.1f m" % w, {"top": deck, "gap": w, "edge_z": a_start - 4.0, "label_y": 3.2,
			"probe": Vector3(x, 0.0, b_start - 2.0), "probe_a": Vector3(x, 0.0, a_start - 2.0)})


func _beam(w: float) -> void:
	var x := _x
	var h := 0.5
	_box(Vector3(x, 0.125, -3.5), Vector3(1.2, 0.25, 1.0))
	_box(Vector3(x, 0.25, -4.5), Vector3(1.2, 0.5, 1.0))
	_box(Vector3(x, h - 0.05, -8.0), Vector3(w, 0.1, 6.0))
	_box(Vector3(x, 0.25, -11.5), Vector3(1.2, 0.5, 1.0))
	_station("beam", "beam %.2f m wide" % w, {"top": h, "width": w, "edge_z": -5.0,
			"probe": Vector3(x, 0.0, -8.0)})


func _passage(w: float) -> void:
	var x := _x
	var side := 1.0
	_box(Vector3(x - w * 0.5 - side * 0.5, 1.25, -5.0), Vector3(side, 2.5, 3.0))
	_box(Vector3(x + w * 0.5 + side * 0.5, 1.25, -5.0), Vector3(side, 2.5, 3.0))
	_station("passage", "passage %.1f m wide" % w, {"top": 0.0, "width": w, "edge_z": -3.5, "label_y": 3.0,
			"probe": Vector3(x, 0.0, -5.0)})


func _overhang(clear: float) -> void:
	var x := _x
	_box(Vector3(x - 1.4, clear * 0.5, -5.0), Vector3(0.2, clear, 3.0))
	_box(Vector3(x + 1.4, clear * 0.5, -5.0), Vector3(0.2, clear, 3.0))
	_box(Vector3(x, clear + 0.1, -5.0), Vector3(3.0, 0.2, 3.0))
	_station("overhang", "overhang %.1f m clear" % clear, {"top": 0.0, "clear": clear, "edge_z": -3.5,
			"label_y": clear + 1.0, "probe": Vector3(x, 0.0, -5.0)})


func _floor_pieces() -> void:
	var x := _x
	for iz in 12:
		for ix in 3:
			_box(Vector3(x - 1.0 + ix * 1.0, 0.05, -3.5 - iz * 1.0), Vector3(1.0, 0.1, 1.0))
	_station("floor_pieces", "floor: 36 separate pieces", {"top": 0.1, "edge_z": -3.0,
			"probe": Vector3(x, 0.0, -9.0)})


func _floor_one_mesh() -> void:
	var x := _x
	var body := StaticBody3D.new()
	var faces := PackedVector3Array()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in 12:
		for ix in 3:
			var a := Vector3(x - 1.5 + ix, 0.1, -3.0 - iz)
			var b := a + Vector3(1.0, 0.0, 0.0)
			var c := a + Vector3(1.0, 0.0, -1.0)
			var d := a + Vector3(0.0, 0.0, -1.0)
			for v: Vector3 in [a, c, b, a, d, c]:
				faces.append(v)
				st.set_normal(Vector3.UP)
				st.add_vertex(v)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _grey
	body.add_child(mi)
	add_child(body)
	# a low kerb all round so the pad can be walked onto like the pieces one
	_box(Vector3(x, 0.05, -2.95), Vector3(3.0, 0.1, 0.1))
	_station("floor_mesh", "floor: one triangle mesh", {"top": 0.1, "edge_z": -3.0,
			"probe": Vector3(x, 0.0, -9.0)})
