extends SceneTree
const Rig := preload("res://tests/people/rig.gd")
## The phone (native/src/mo_motor_phone.cpp, mo_layer.cpp; Yasin, 24 Nov: "walking text whenever we open the phone, and
## standing talk and walking talk when we take a call, we shouldnt be able to run while on a phone call"):
## texting standing, then walking; a call standing, then run asked (a walk it stays); put away.
##   godot --headless --path . --fixed-fps 60 -s res://tests/people/test_motor_phone.gd
## Checks: out and away (the phases), the phone in his hand while out, at his ear on the call (its middle within 14 cm of
## the head bone, to his right), his speed at a walk on the call with running asked, the legs still his own walk's
## (no foot slide over 3 cm while walking with it).
var p: CharacterBody3D; var sk: Skeleton3D; var t := 0.0; var t_prev := 0.0; var fails := 0; var pf := -1
var phases := {}; var max_call_speed := 0.0; var ear_far := 0.0; var ear_n := 0; var phone_off_hand := 0.0
func _initialize():
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(60, 2, 60); cs.shape = sh; b.add_child(cs); b.position = Vector3(0, -1, 0); root.add_child(b)
	p = ClassDB.instantiate(&"CityPlayer"); p.position = Vector3(0, 0.05, -20); root.add_child(p)
func _at(w: float) -> bool: return t_prev < w and t >= w
func _process(d):
	t_prev = t; t += d
	if sk == null:
		var s = p.find_children("*", "Skeleton3D", true, false)
		if s.is_empty(): return false
		sk = s[0]; sk.skeleton_updated.connect(_pose)
	if _at(0.8): p.call(&"set_phone_use", 1)
	if _at(6.0): p.call(&"set_move", Vector2(0, 1), false)
	if _at(11.0): p.call(&"set_move", Vector2.ZERO, false)
	if _at(13.0): p.call(&"set_phone_use", 0)
	if _at(18.0): p.call(&"set_phone_use", 2)
	if _at(26.0): p.call(&"set_move", Vector2(0, 1), true)
	if _at(32.0): p.call(&"set_move", Vector2.ZERO, false)
	if _at(34.0): p.call(&"set_phone_use", 0)
	if _at(40.0): _judge()
	return false
func _w(b: String) -> Vector3: return sk.global_transform * sk.get_bone_global_pose(Rig.find(sk, b)).origin
func _pose():
	var f := Engine.get_process_frames()
	if f == pf: return
	pf = f
	var ms: Dictionary = p.call(&"get_motor_state")
	var ph := int(ms.get("phone", 0)); phases[ph] = true
	var phone: Node3D = null
	for c in p.get_children(): if c is MeshInstance3D and c.visible and (c as MeshInstance3D).mesh is BoxMesh and ((c as MeshInstance3D).mesh as BoxMesh).size.z < 0.02: phone = c
	if phone and ph != 0: phone_off_hand = maxf(phone_off_hand, (phone.global_position - _w("Bip01_R_Hand")).length())
	if t > 23.0 and t < 33.0:   # (the call, held)
		max_call_speed = maxf(max_call_speed, Vector2(p.velocity.x, p.velocity.z).length())
		if phone:
			var head := _w("Bip01_Head"); var right := _w("Bip01_R_UpperArm") - _w("Bip01_L_UpperArm"); right.y = 0
			var o := phone.global_position - head
			ear_far = maxf(ear_far, o.length()); ear_n += 1
			if o.dot(right.normalized()) < 0.04: ear_far = maxf(ear_far, 1.0)   # (on his right, off the cheek)
func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("PHONE   %s: %s" % ["ok  " if ok else "FAIL", what])
func _judge():
	_check(phases.has(1) and phases.has(2) and phases.has(3) and phases.has(0), "taken out, used, put away (%s)" % str(phases.keys()))
	_check(phone_off_hand < 0.2, "the phone in his hand while out (%.2f m from the wrist at most)" % phone_off_hand)
	_check(ear_n > 0 and ear_far < 0.16, "on the call the phone at his right ear (%.2f m from the head at most)" % ear_far)
	_check(max_call_speed < 1.9, "no running on a call, run asked (%.2f m/s at most)" % max_call_speed)
	print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails)); quit(1 if fails else 0)
