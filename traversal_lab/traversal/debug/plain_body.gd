extends CharacterBody3D
## Stage 0 only: a plain stand-in body, so the course, the readout and the replay tool can be tried.
## It is NOT the movement system. Stage 1 replaces it.

const WALK := 1.6
const RUN := 4.5
const GRAVITY := 9.8

var tape: Node


func _ready() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.25
	shape.height = 1.8
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = 0.9
	add_child(col)
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.25
	mesh.height = 1.8
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position.y = 0.9
	add_child(mi)
	var nose := MeshInstance3D.new()
	var nm := BoxMesh.new()
	nm.size = Vector3(0.08, 0.08, 0.3)
	nose.mesh = nm
	nose.position = Vector3(0, 1.6, -0.3)
	add_child(nose)


func _physics_process(dt: float) -> void:
	var s: Dictionary = tape.call(&"sample") if tape else {}
	var dir := Vector3(float(s.get("mx", 0.0)), 0.0, float(s.get("mz", 0.0))).rotated(Vector3.UP, float(s.get("yaw", 0.0)))
	var speed := RUN if bool(s.get("run", false)) else WALK
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	velocity.y = -0.1 if is_on_floor() else velocity.y - GRAVITY * dt
	if dir.length() > 0.1:
		rotation.y = atan2(-dir.x, -dir.z)
	move_and_slide()


func get_readout() -> Dictionary:
	return {"state": "on ground" if is_on_floor() else "in air", "speed": Vector2(velocity.x, velocity.z).length(),
			"height": global_position.y, "note": "plain stand-in body (Stage 0)"}
