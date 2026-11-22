extends Node3D
## A breakable shop window of a kit building with a built-in interior (22 Nov, Yasin: "windows should be breakable";
## physics is dropped, so no rigid bodies: state swaps). intact -> cracked -> broken.
##  - "pane": the glass (builtin_glass.gdshader); cracked = the shader's instance "crack" star round the hit point
##  - broken: the pane hidden, "remnant" shown (jagged teeth of glass left in the frame), a one-shot CPUParticles3D shard
##    burst ("shards": 24 small quads, 0.9 s, phone-cheap: CPU, no collision, one draw while it lives)
##  - glass_cracked / glass_broken signals carry the world position: the sound hook (a glass sound plays there; if
##    `sound` is set an AudioStreamPlayer3D child plays it directly)
##  - "body": a StaticBody3D box that blocks the opening while intact or cracked and is disabled when broken
## Hooks: damage(amount, at_world), crack(at_world), break_window(at_world). State persists (break_state.gd).
signal glass_cracked(at: Vector3)
signal glass_broken(at: Vector3)
const BS := preload("res://tools/city/rooms/builtin/break_state.gd")
@export var max_hp := 30.0
@export var crack_hp := 18.0        ## at or under this: cracked
@export var sound: AudioStream
var hp := 30.0
var state := "intact"               ## intact | cracked | broken
var crack_uv := Vector2(0.5, 0.5)

func bid() -> String: return String(get_meta(&"bid", name))

func _ready() -> void:
	hp = max_hp
	var st := BS.get_state(bid())
	if not st.is_empty():
		hp = float(st.get("hp", max_hp)); var cu: Array = st.get("uv", [0.5, 0.5]); crack_uv = Vector2(float(cu[0]), float(cu[1]))
		match String(st.get("state", "intact")):
			"cracked": _apply_cracked()
			"broken": _apply_broken(false)

## world point -> the pane's 0..1 (meta "size": pane width, height; the node's origin is the pane's bottom-left corner,
## local +X along the pane, +Y up)
func _uv_of(at: Vector3) -> Vector2:
	if at == Vector3.INF: return Vector2(0.5, 0.55)
	var l := to_local(at); var sz: Vector2 = get_meta(&"size", Vector2(1, 1))
	return Vector2(clampf(l.x / sz.x, 0.05, 0.95), clampf(1.0 - l.y / sz.y, 0.05, 0.95))

func damage(amt: float, at := Vector3.INF) -> void:
	if state == "broken": return
	hp = maxf(0.0, hp - amt)
	if hp <= 0.0: break_window(at)
	elif hp <= crack_hp and state == "intact": crack(at)
	else: _save()

func crack(at := Vector3.INF) -> void:
	if state != "intact": return
	crack_uv = _uv_of(at); hp = minf(hp, crack_hp)
	_apply_cracked(); _save()
	glass_cracked.emit(_world_at(at)); _play()

func break_window(at := Vector3.INF) -> void:
	if state == "broken": return
	if state == "intact": crack_uv = _uv_of(at)
	hp = 0.0; _apply_broken(true); _save()
	glass_broken.emit(_world_at(at)); _play()

func _world_at(at: Vector3) -> Vector3:
	if at != Vector3.INF: return at
	var sz: Vector2 = get_meta(&"size", Vector2(1, 1))
	return to_global(Vector3(sz.x * 0.5, sz.y * 0.5, 0))

func _save() -> void: BS.set_state(bid(), {"state": state, "hp": hp, "uv": [crack_uv.x, crack_uv.y]})

func _apply_cracked() -> void:
	state = "cracked"
	var p := get_node_or_null(^"pane") as GeometryInstance3D
	if p: p.set_instance_shader_parameter(&"crack", 1.0); p.set_instance_shader_parameter(&"crack_at", crack_uv)

func _apply_broken(burst: bool) -> void:
	state = "broken"
	var p := get_node_or_null(^"pane") as Node3D
	if p: p.visible = false
	var r := get_node_or_null(^"remnant") as Node3D
	if r: r.visible = true
	var body := get_node_or_null(^"body") as CollisionObject3D
	if body:
		for c in body.get_children():
			if c is CollisionShape3D: (c as CollisionShape3D).set_deferred(&"disabled", true)
	var s := get_node_or_null(^"shards") as CPUParticles3D
	if s and burst:
		var sz: Vector2 = get_meta(&"size", Vector2(1, 1))
		s.position = Vector3(crack_uv.x * sz.x, (1.0 - crack_uv.y) * sz.y, 0)
		s.restart(); s.emitting = true

func _play() -> void:
	if sound == null: return
	var a := get_node_or_null(^"sound") as AudioStreamPlayer3D
	if a == null: a = AudioStreamPlayer3D.new(); a.name = "sound"; add_child(a)
	a.stream = sound; a.play()
