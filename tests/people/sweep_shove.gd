extends SceneTree
## How people take a shove (C++: CityPed, ped_body; Yasin, 20 Nov: "people are very unlikely to fall and step countless
## times to balance themselves"), in a window:
##   godot --path . --rendering-method mobile --resolution 960x540 --fixed-fps 60 -s res://tests/people/sweep_shove.gd
## One person after another, each shoved in the chest from behind, harder each time (30 to 240 N s). For each: the steps
## it took, whether it fell. Checks (a person, not a tumbler): a light shove (30-60) is taken in 0-2 steps and standing;
## nobody takes more than 4 steps; from 150 N s on everyone goes down.
const SHOVES := [30.0, 45.0, 60.0, 90.0, 120.0, 150.0, 190.0, 240.0]
var ped: Node3D
var cam: Camera3D
var t := 0.0
var t0 := 0.0
var k := -1
var steps_most := 0
var fails := 0
var rows := []

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("SHOVE   %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
	sh.size = Vector3(400, 2, 400); cs.shape = sh; b.add_child(cs); b.position = Vector3(0, -1, 0)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = sh.size; mi.mesh = bm; b.add_child(mi); root.add_child(b)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 35, 0); root.add_child(sun)
	cam = Camera3D.new(); root.add_child(cam)
	_next()

func _next() -> void:
	k += 1
	if ped: ped.queue_free()
	if k >= SHOVES.size(): return
	ped = ClassDB.instantiate(&"CityPed"); ped.set(&"body_id", "M1"); ped.position = Vector3(k * 6.0, 0, 0); root.add_child(ped)
	t0 = t; steps_most = 0

func _physics_process(delta: float) -> bool:
	t += delta
	if k >= SHOVES.size():
		var light_ok := true; var most := 0; var hard_ok := true
		for r: Array in rows:
			most = maxi(most, int(r[1]))
			if float(r[0]) <= 60.0 and (int(r[1]) > 2 or bool(r[2])): light_ok = false
			if float(r[0]) >= 150.0 and not bool(r[2]): hard_ok = false
		_check(light_ok, "light shoves (30-60 N s) taken in 0-2 steps, standing")
		_check(most <= 4, "nobody took more than 4 steps (most %d)" % most)
		_check(hard_ok, "from 150 N s on, everyone went down")
		print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
		quit(1 if fails else 0); return true
	cam.current = true
	cam.look_at_from_position(ped.global_position + Vector3(4.5, 2.0, 2.5), ped.global_position + Vector3(0, 0.9, 1.0), Vector3.UP)
	var s: Dictionary = ped.call(&"get_state")
	steps_most = maxi(steps_most, int(s.steps))
	if t - t0 < 1.0: return false
	if not ped.has_meta(&"pushed"):
		ped.set_meta(&"pushed", true); t0 = t
		ped.call(&"push", Vector3(0, 0, SHOVES[k]), ped.global_position + Vector3(0, 1.3, 0))
		return false
	if t - t0 > 5.0 or (int(s.falls) > 0 and t - t0 > 1.5) or (int(s.mode) == 0 and t - t0 > 1.5):
		rows.append([SHOVES[k], steps_most, int(s.falls) > 0])
		print("SHOVE   %3.0f N s: %d steps, %s" % [SHOVES[k], steps_most, "FELL" if int(s.falls) > 0 else "stayed up"])
		_next()
	return false
