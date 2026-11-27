extends Node3D
const Door := preload("res://traversal/course/door.gd")
const Car := preload("res://traversal/course/car.gd")
## Stage 0: the measured grey-box test course. Every obstacle is built at an exact, labelled size.
## Stations stand side by side along X; each is approached by walking toward -Z from its start point.
## `stations` lists them for the readout, the teleport keys and the tests.

const LANE := 4.0                      # metres between station centres
const GROUND_SIZE := Vector3(280.0, 1.0, 120.0)

var stations: Array[Dictionary] = []   # {id, kind, label, start, top, size, pos, ...}
# Stations added after the course was first measured: reached with the station keys like the others, but kept apart,
# so that the count of `stations`, and with it the path of stage 1's seeded random walk, stays what it was.
var extras: Array[Dictionary] = []
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
	# Stage 7 ("a wall with no headroom above it is reported as blocked"): added last, so no other station moves
	_wall_under_roof(1.00, 0.60)
	# Stage 17, the sidle (Yasin, 27 Nov: "yes add wall ledge station, how else am i supposed o test?"): behind the
	# start line of the last lane (z from 5 to 15), so that no other station moves and the free ground beyond the
	# last lane, where the tests build their own things, stays where it is. It is listed in `extras`, not `stations`:
	# as a 65th station it changed the path of stage 1's random walk, which then met two things that were there
	# before (see reports/TRAVERSAL JOB BOARD.md).
	_ledges(0.20, 0.12)
	# Stage 22, a door (the study's opening: 0.815 m wide, 2.03 m high), also behind the start line and in `extras`
	_door(236.0, 10.0)
	# Sitting (Yasin, 27 Nov): a bench and a desk with a stool, also behind the start line and in `extras`
	_seats(226.0, 10.0)
	# Stage 23, a car (a van: see car.gd), pointing toward -X, its driver's door toward +Z; also in `extras`
	_car(215.0, 9.0)


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


## A deep wall with a roof slab `clear` above its top: nobody fits on it.
func _wall_under_roof(h: float, clear: float) -> void:
	var x := _x
	_box(Vector3(x, h * 0.5, -3.0 - 1.25), Vector3(3.0, h, 2.5))
	_box(Vector3(x, h + clear + 0.1, -3.0 - 1.25), Vector3(3.0, 0.2, 2.5))
	_station("wall_roofed", "deep wall %.2f m, roof %.2f m above it" % [h, clear], {"top": h, "depth": 2.5, "clear": clear,
			"edge_z": -3.0, "label_y": h + clear + 1.0, "probe": Vector3(x, 0.0, -4.25)})


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


## A wall with a ledge 0.5 m up along each face (`w_a` m wide on its +X face, `w_b` on its -X face), a platform at
## each end of each ledge and a step up to the near one. Approached from z = 15.6, walking toward -Z.
func _ledges(w_a: float, w_b: float) -> void:
	var x := _x - LANE
	var h := 0.5
	_box(Vector3(x, 1.5, 10.0), Vector3(1.0, 3.0, 10.0))
	for side in 2:
		var way := 1.0 if side == 0 else -1.0
		var w := w_a if side == 0 else w_b
		var face := x + way * 0.5
		_box(Vector3(face + way * 0.6, 0.125, 14.0), Vector3(1.2, 0.25, 1.0))
		_box(Vector3(face + way * 0.6, h * 0.5, 12.5), Vector3(1.2, h, 2.0))
		_box(Vector3(face + way * w * 0.5, h - 0.05, 9.5), Vector3(w, 0.1, 4.0))
		_box(Vector3(face + way * 0.6, h * 0.5, 6.5), Vector3(1.2, h, 2.0))
	var s := {"id": "ledge_%02d" % (stations.size() + extras.size()), "kind": "ledge", "label": "wall ledges %.2f and %.2f m (walk toward the wall end, then along it)" % [w_a, w_b],
			"start": Vector3(x + 0.9, 0.0, 15.6), "x": x, "top": h, "widths": [w_a, w_b],
			"probe": Vector3(x + 0.5 + w_a * 0.5, 0.0, 9.5)}
	extras.append(s)
	_label("wall ledges: %.2f m (this side), %.2f m (far side)" % [w_a, w_b], Vector3(x + 1.1, 1.8, 14.8))


## A wall along X at z = `z` with one hinged door in it (door.gd): pulled from the +Z side, pushed from the -Z side.
## The wall is 3.2 m high: one he could climb (to 3.0 m) would be climbed where he walks at it beside the door.
func _door(x: float, z: float) -> void:
	var wide := float(Door.WIDE)
	var high := float(Door.HIGH)
	var wall_h := 3.2
	var hinge_x := x + wide * 0.5
	_box(Vector3(hinge_x + 1.5, wall_h * 0.5, z), Vector3(3.0, wall_h, 0.2))
	_box(Vector3(hinge_x - wide - 1.5, wall_h * 0.5, z), Vector3(3.0, wall_h, 0.2))
	_box(Vector3(x, high + (wall_h - high) * 0.5, z), Vector3(wide, wall_h - high, 0.2))
	var door: Node3D = Door.new()
	door.position = Vector3(hinge_x, 0.0, z)
	add_child(door)
	var s := {"id": "door_%02d" % (stations.size() + extras.size()), "kind": "door", "label": "door %.3f x %.2f m: pull from this side, push from the far side" % [wide, high],
			"start": Vector3(hinge_x - 0.35, 0.0, z + 3.0), "x": x, "top": 0.0, "hinge": Vector3(hinge_x, 0.0, z), "door": door,
			"probe": Vector3(x, 0.0, z + 2.0)}
	extras.append(s)
	_label("door: pull from this side, push from the far side", Vector3(x, 2.6, z + 0.5))


## A seat: a point on the ground under where his hips are when seated, and the way he faces there. `desk`: a seat
## at a desk: he sits down onto it facing `side`, and turns on it to face the desk.
func _seat(at: Vector3, facing: Vector3, desk := false, side := Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.position = at
	n.basis = Basis.looking_at(-facing, Vector3.UP)        # its own +Z is the way he faces
	n.add_to_group(&"tl_seat")
	n.set_meta(&"desk", desk)
	n.set_meta(&"side", side)
	add_child(n)
	return n


## A bench (two places) facing +Z, and to its left a stool at a desk. The study: "Bench seat | 0.43 to 0.485 m",
## "Tables and counters | 0.71 to 0.965 m". Approached from z + 3.
func _seats(x: float, z: float) -> void:
	var seat_h := 0.45
	# the bench: its seat from 0.20 m behind his hips to 0.18 m in front, a back behind it
	_box(Vector3(x + 1.2, seat_h * 0.5, z - 0.01), Vector3(1.5, seat_h, 0.38))
	_box(Vector3(x + 1.2, 0.50, z - 0.26), Vector3(1.5, 1.0, 0.06))
	var places := []
	for off: float in [-0.38, 0.38]:
		places.append(_seat(Vector3(x + 1.2 + off, 0.0, z), Vector3(0.0, 0.0, 1.0)))
	# the stool and the desk: the desk's top at 0.72 m, its near edge 0.30 m in front of his hips; he faces -Z at it
	_box(Vector3(x - 1.4, seat_h * 0.5, z), Vector3(0.38, seat_h, 0.38))
	_box(Vector3(x - 1.4, 0.70, z - 0.62), Vector3(1.3, 0.04, 0.64))
	for sx: float in [-0.63, 0.63]:
		_box(Vector3(x - 1.4 + sx, 0.34, z - 0.62), Vector3(0.04, 0.68, 0.60))
	# (a slab for a keyboard, where his hands come down)
	_box(Vector3(x - 1.4, 0.725, z - 0.42), Vector3(0.44, 0.01, 0.14), _dark)
	places.append(_seat(Vector3(x - 1.4, 0.0, z), Vector3(0.0, 0.0, -1.0), true, Vector3(1.0, 0.0, 0.0)))
	var s := {"id": "seats_%02d" % (stations.size() + extras.size()), "kind": "seats", "label": "bench %.2f m, and a stool at a desk: E to sit and to get up; T text, G call" % seat_h,
			"start": Vector3(x + 1.2, 0.0, z + 2.5), "x": x, "top": 0.0, "seats": places, "seat_high": seat_h,
			"probe": Vector3(x, 0.0, z + 2.0)}
	extras.append(s)
	_label("bench and desk: E to sit and to get up; T text, G call", Vector3(x, 2.2, z - 0.4))


## A car (car.gd) with the driver's hips over (`x`, `z`), pointing toward -X: its driver's door is on its +Z side.
func _car(x: float, z: float) -> void:
	var car: Node3D = Car.new()
	car.position = Vector3(x, 0.0, z)
	car.rotation.y = PI * 0.5           # its own -Z (the way it points) toward the world's -X
	add_child(car)
	var s := {"id": "car_%02d" % (stations.size() + extras.size()), "kind": "car", "label": "car: E by the driver's door to get in, E to get out",
			"start": Vector3(x, 0.0, z + 3.2), "x": x, "top": 0.0, "car": car, "probe": Vector3(x, 0.0, z + 3.0)}
	extras.append(s)
	_label("car: E by the driver's door to get in, E to get out", Vector3(x, 2.6, z + 1.0))


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
