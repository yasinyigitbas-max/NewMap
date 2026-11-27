extends Node3D
## Stage 22: a hinged door, grey-box. This node stands at the foot of the hinge; the closed leaf lies along its own
## -X and it opens toward its own +Z (the side it is pulled from). The study: door opening "0.815 m wide, 2.03 m
## high"; "Door hardware sits 0.865 to 1.22 m above the floor". It has a bar across each face at 1.05 m (where the
## takes put the hand: they were made on a narrower door, and their hand comes down mid-leaf, not at its edge).
## A move turns it with `open_deg`; left alone it swings shut again by itself, like a door with a closer.

const WIDE := 0.815
const HIGH := 2.03
const THICK := 0.04
const BAR_HIGH := 1.05          # NOT in the study as one figure: inside its 0.865 to 1.22 m, where the takes' hands come
const SHUT_AFTER := 0.4         # NOT in the study, mine: seconds it stays as it was left before it begins to shut
const SHUT_RATE := 90.0         # NOT in the study, mine: degrees a second it swings shut

var open_deg := 0.0             # 0 = shut, 90 = square to its frame
var held := false               # a move is turning it (set each tick by the move)

var _pivot: Node3D
var _idle := 0.0


func _ready() -> void:
	add_to_group(&"tl_door")
	_pivot = Node3D.new()
	add_child(_pivot)
	var leaf := StaticBody3D.new()
	leaf.position = Vector3(-WIDE * 0.5, HIGH * 0.5, 0.0)
	var shape := BoxShape3D.new()
	shape.size = Vector3(WIDE - 0.01, HIGH - 0.01, THICK)
	var col := CollisionShape3D.new()
	col.shape = shape
	leaf.add_child(col)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.40, 0.28)
	var mesh := BoxMesh.new()
	mesh.size = shape.size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	leaf.add_child(mi)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.15, 0.15, 0.17)
	for side: float in [1.0, -1.0]:
		var bar := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(WIDE - 0.16, 0.04, 0.03)
		bar.mesh = bm
		bar.material_override = dark
		bar.position = Vector3(0.0, BAR_HIGH - HIGH * 0.5, side * (THICK * 0.5 + 0.015))
		leaf.add_child(bar)
	_pivot.add_child(leaf)


func _physics_process(dt: float) -> void:
	if held:
		_idle = 0.0
	else:
		_idle += dt
		if _idle > SHUT_AFTER and open_deg > 0.0:
			open_deg = maxf(open_deg - SHUT_RATE * dt, 0.0)
	held = false
	_pivot.rotation.y = deg_to_rad(open_deg)


## A point on the leaf's bar, `from_hinge` m from the hinge, on the face toward +Z (`front`) or -Z, in the world.
func bar_at(from_hinge: float, front: bool) -> Vector3:
	return _pivot.global_transform * Vector3(-from_hinge, BAR_HIGH, (THICK * 0.5 + 0.03) * (1.0 if front else -1.0))


## The way that face of the leaf looks, in the world.
func face(front: bool) -> Vector3:
	return (_pivot.global_transform.basis.z * (1.0 if front else -1.0)).normalized()
