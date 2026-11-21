extends Node3D
## A hinged door leaf of a kit building with a built-in interior (22 Nov, Yasin: "openable doors", "breakable").
## Drop-in with the rooms' leaves: the node is named DoorLeaf_<s0 cm>_<i> and carries the same metas (mid, out_dir,
## open_sign, hinge_axis, swing) that CityRooms reads, so the C++ door swing keeps working on it.
## The node's origin is the hinge; the leaf turns about Y. Children: "leaf" (intact mesh), "leaf_broken" (hidden),
## "body" (AnimatableBody3D with the leaf's box: it turns with the leaf, so collision follows the swing).
## Hooks for the player / NPC systems:
##   interact(actor_pos)  - toggles: opens away from the actor, or closes
##   open(actor_pos) / close()
##   damage(amount, from_pos) - hp; at 0 the door breaks
##   break_door(from_pos) - off its hinge, splintered, collision opened (state persists: break_state.gd)
## auto_open = true: also opens by proximity (the rooms' old behaviour, for the preview without the C++ CityRooms).
signal opened
signal closed
signal broken(at: Vector3)
const BS := preload("res://tools/city/rooms/builtin/break_state.gd")
@export var max_angle := 95.0
@export var speed := 3.6            ## open fraction per second
@export var max_hp := 60.0
@export var auto_open := false
@export var trigger := 3.0
var force_open := -1.0              ## preview shots: hold at this fraction
var amount := 0.0
var want := 0.0
var hp := 60.0
var state := "closed"               ## closed | open | broken
var _dir := 1.0

func bid() -> String: return String(get_meta(&"bid", name))

func _ready() -> void:
	hp = max_hp
	var st := BS.get_state(bid())
	if not st.is_empty():
		hp = float(st.get("hp", max_hp))
		if String(st.get("state", "")) == "broken": _apply_broken()

func _out_world() -> Vector3:
	return (get_parent() as Node3D).global_transform.basis * (get_meta(&"out_dir", Vector3.BACK) as Vector3)

func _mid_world() -> Vector3:
	return (get_parent() as Node3D).to_global(position + (get_meta(&"mid", Vector3.ZERO) as Vector3))

func interact(actor_pos: Vector3) -> void:
	if state == "broken": return
	if want > 0.5: close()
	else: open(actor_pos)

func open(actor_pos: Vector3) -> void:
	if state == "broken": return
	if amount <= 0.001: _dir = -1.0 if (actor_pos - _mid_world()).dot(_out_world()) > 0.0 else 1.0
	want = 1.0; state = "open"; opened.emit()

func close() -> void:
	if state == "broken": return
	want = 0.0; state = "closed"; closed.emit()

func damage(amt: float, from_pos := Vector3.INF) -> void:
	if state == "broken": return
	hp = maxf(0.0, hp - amt)
	BS.set_state(bid(), {"state": state, "hp": hp})
	if hp <= 0.0: break_door(from_pos)

func break_door(from_pos := Vector3.INF) -> void:
	if state == "broken": return
	_apply_broken()
	BS.set_state(bid(), {"state": "broken", "hp": 0.0})
	broken.emit(_mid_world() if from_pos == Vector3.INF else from_pos)

func _apply_broken() -> void:
	state = "broken"; amount = 0.0; want = 0.0; rotation.y = 0.0
	var l := get_node_or_null(^"leaf") as Node3D
	var b := get_node_or_null(^"leaf_broken") as Node3D
	if l: l.visible = false
	if b: b.visible = true
	var body := get_node_or_null(^"body") as CollisionObject3D
	if body:      # collision opened: the doorway is free
		for c in body.get_children():
			if c is CollisionShape3D: (c as CollisionShape3D).set_deferred(&"disabled", true)

func _process(dt: float) -> void:
	if state == "broken": return
	if force_open >= 0.0:
		amount = force_open
	else:
		if auto_open:
			var cam := get_viewport().get_camera_3d()
			if cam:
				var near := cam.global_position.distance_to(_mid_world()) < trigger
				if near and want < 0.5: open(cam.global_position)
				elif not near and want > 0.5: close()
		amount = move_toward(amount, want, speed * dt)
	var e := amount * amount * (3.0 - 2.0 * amount)
	rotation.y = deg_to_rad(max_angle * e) * float(get_meta(&"open_sign", 1.0)) * _dir
