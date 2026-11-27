extends Node3D
## Stage 23: a car to get into and out of, grey-box. This node stands on the ground under the driver's hips; its own
## -Z is the way the car points, its own -X is the car's left (the driver's door).
## The study: "`Entering Car` (5.47 s) walks 1.9 m, turns 97 degrees and sits with the hips at 0.88 m and the feet on
## a floor 0.29 m up. That is a tall seat, more van or truck than saloon". So this is a van, built round the take:
## the floor, the seat, the wheel and the door stand where the take's feet, hips and hands come (measured on his body
## in the lab: hips 0.84 m up, feet on a floor 0.28 m up, the door's skin 0.84 m to the left of his hips, its hinge
## 0.83 m ahead of them, hands on the wheel 0.33 m ahead and 1.13 m up). NOT in the study: every size below.

const FLOOR := 0.28
const SEAT := 0.74              # the seat's top: his hip joints sit 0.10 m over it
const SKIN := 0.84              # the door's outer face, left of his hips (m)
const HINGE := 0.83             # the door's hinge, ahead of his hips (m)
const DOOR_LONG := 0.85
const WIDE := 2.0
const ROOF := 1.25              # its sides stand this high and it has no roof: a grey box he can be seen sitting in
const SHUT_RATE := 120.0        # degrees a second the door swings shut if it is left open

var door_deg := 0.0             # 0 = shut, 90 = straight out from the side
var held := false

var _pivot: Node3D
var _grey := StandardMaterial3D.new()
var _dark := StandardMaterial3D.new()


func _box(parent: Node3D, center: Vector3, size: Vector3, mat: Material) -> void:
	var b := StaticBody3D.new()
	b.position = center
	var shape := BoxShape3D.new()
	shape.size = size
	var col := CollisionShape3D.new()
	col.shape = shape
	b.add_child(col)
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	b.add_child(mi)
	parent.add_child(b)


func _ready() -> void:
	add_to_group(&"tl_car")
	_grey.albedo_color = Color(0.32, 0.42, 0.55)
	_dark.albedo_color = Color(0.12, 0.12, 0.14)
	var front := -1.9               # the nose, ahead of his hips (own -Z)
	var back := 2.9
	var left := -SKIN
	var right := left + WIDE
	var mid_x := (left + right) * 0.5
	var mid_z := (front + back) * 0.5
	var long := back - front
	_box(self, Vector3(mid_x, FLOOR - 0.04, mid_z), Vector3(WIDE, 0.08, long), _grey)             # floor
	_box(self, Vector3(right - 0.03, (FLOOR + ROOF) * 0.5, mid_z), Vector3(0.06, ROOF - FLOOR, long), _grey)     # right side
	_box(self, Vector3(mid_x, (FLOOR + ROOF) * 0.5, back - 0.03), Vector3(WIDE, ROOF - FLOOR, 0.06), _grey)      # back
	_box(self, Vector3(mid_x, (FLOOR + 1.0) * 0.5, front + 0.5), Vector3(WIDE, 1.0 - FLOOR, 1.0), _grey)          # bonnet and dash
	# the left side: ahead of the door's hinge, and behind the door
	var door_back := -HINGE + DOOR_LONG
	_box(self, Vector3(left + 0.03, (FLOOR + 1.0) * 0.5, (front + 1.0 - HINGE) * 0.5), Vector3(0.06, 1.0 - FLOOR, -HINGE - front - 1.0), _grey)
	_box(self, Vector3(left + 0.03, (FLOOR + ROOF) * 0.5, (door_back + back) * 0.5), Vector3(0.06, ROOF - FLOOR, back - door_back), _grey)
	# the seat, its back, the wheel
	_box(self, Vector3(0.0, (FLOOR + SEAT) * 0.5, 0.02), Vector3(0.50, SEAT - FLOOR, 0.46), _dark)
	_box(self, Vector3(0.0, SEAT + 0.30, 0.30), Vector3(0.50, 0.60, 0.08), _dark)
	_box(self, Vector3(0.0, 1.10, -0.42), Vector3(0.36, 0.30, 0.04), _dark)
	for wz: float in [front + 0.8, back - 0.8]:
		for wx: float in [left + 0.12, right - 0.12]:
			_box(self, Vector3(wx, 0.33, wz), Vector3(0.22, 0.66, 0.66), _dark)
	# the door: hinged at its front, swinging out to the left
	_pivot = Node3D.new()
	_pivot.position = Vector3(left, 0.0, -HINGE)
	add_child(_pivot)
	_box(_pivot, Vector3(0.0, (FLOOR + 1.25) * 0.5, DOOR_LONG * 0.5), Vector3(0.05, 1.25 - FLOOR, DOOR_LONG - 0.02), _grey)
	_box(_pivot, Vector3(-0.04, 1.02, DOOR_LONG - 0.12), Vector3(0.03, 0.03, 0.14), _dark)      # its handle


func _physics_process(dt: float) -> void:
	if not held and door_deg > 0.0:
		door_deg = maxf(door_deg - SHUT_RATE * dt, 0.0)
	held = false
	# (the leaf lies along own +Z from the hinge when shut; opening, its free end goes out to own -X)
	_pivot.rotation.y = -deg_to_rad(door_deg)
