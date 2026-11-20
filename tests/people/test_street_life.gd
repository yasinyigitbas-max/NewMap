extends SceneTree
## The street reacts (Yasin, 20 Nov, his GTA IV list: "others come to help the victim", "crouch or hands up when a gun is
## aimed at them", "i want all of them"), headless:
##   godot --headless --fixed-fps 60 --path . -s res://tests/people/test_street_life.gd
## The real streets over a flat floor; a test "car" (a node this script moves). 1) It hits somebody who cannot jump at
## 43 km/h: he goes down and STAYS down; passers-by come to him, one kneels; treated (as a medic will), he gets up and the
## helpers go. 2) A gun (none in the game yet: the hook the weapons will call) is aimed along a pavement: the people in
## the line put their hands up or crouch, and run once it is off them. 3) A shot: the street's alarm. 4) An actor in
## uniform: a police body.
var crowd: Node3D
var car: Node3D
var t := 0.0
var step := 0
var t0 := 0.0
var fails := 0
var spot := Vector3.ZERO
var dir := Vector3.FORWARD
var held := -1
var from := Vector3.ZERO
var speed := 0.0
var was_body := false
var got_up := false
var knelt_seen := false
var aimed: Array = []
var cop := -1

func _initialize() -> void:
	if not ClassDB.class_exists(&"CityCrowd"):
		print("STREET ERROR the native module is not built"); print("RESULT FAIL"); quit(1); return
	crowd = ClassDB.instantiate(&"CityCrowd")
	crowd.set(&"max_people", 400); crowd.set(&"hour", 12.5); crowd.set(&"near_max", 18)
	root.add_child(crowd)
	var cam := Camera3D.new(); cam.position = Vector3(0, 40, -620); cam.rotation_degrees = Vector3(-90, 0, 0); root.add_child(cam); cam.current = true

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("STREET   %s: %s" % ["ok" if ok else "FAIL", what])

func _person(id: int) -> Dictionary:
	for p: Dictionary in crowd.call(&"people_near", spot, 400.0):
		if int(p.id) == id: return p
	return {}

func _body(id: int) -> Dictionary:
	for nb: Dictionary in crowd.call(&"near_bodies"):
		if int(nb.walker) == id: return nb
	return {}

func _physics_process(delta: float) -> bool:
	if crowd == null: return true
	t += delta
	if car != null and speed > 0.0: car.global_position += dir * speed * delta
	match step:
		0:
			if t < 6.0: return false
			# the busiest pavement near the centre: the walker with the most people within 25 m
			var best := -1
			for p: Dictionary in crowd.call(&"people_near", Vector3(0, 0, -620), 220.0):
				if int(p.mode) != 0 or int(p.state) != 0 or int(p.party) != 0: continue
				var n: int = crowd.call(&"people_near", p.at, 25.0).size()
				if n > best: best = n; spot = p.at; dir = Vector3(sin(float(p.yaw)), 0, cos(float(p.yaw)))
			if spot == Vector3.ZERO: _check(false, "no walker on a pavement near the centre"); step = 9; return false
			print("STREET   the spot: %s, %d people within 25 m" % [str(spot), best])
			var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
			sh.size = Vector3(800, 2, 800); cs.shape = sh; fl.add_child(cs); fl.position = Vector3(spot.x, spot.y - 1.0, spot.z); root.add_child(fl)
			var cam: Camera3D = root.get_viewport().get_camera_3d()
			cam.look_at_from_position(spot + Vector3(-dir.z, 0, dir.x) * 6.0 + Vector3(0, 3, 0), spot, Vector3.UP)
			car = Node3D.new(); root.add_child(car)
			crowd.call(&"set_player_car", car, 2.3, 1.0)
			car.global_position = spot - dir * 30.0
			held = int(crowd.call(&"place_walker", spot, 8181))
			step = 1; t0 = t
		1:
			if t - t0 < 1.2: return false
			var p := _person(held)
			crowd.call(&"hold", held, true, float(p.yaw))
			from = p.at
			dir = ((p.at as Vector3) - car.global_position); dir.y = 0; dir = dir.normalized()
			car.rotation.y = atan2(dir.x, dir.z)
			speed = 12.0      # 43 km/h, straight at him
			step = 2; t0 = t
		2:
			var nb := _body(held)
			if not nb.is_empty() and int(nb.figure_mode) == 1: was_body = true
			if speed > 0.0 and car.global_position.distance_to(from) > 25.0 and car.global_position.dot(dir) > from.dot(dir): speed = 0.0; car.global_position += dir * 300.0      # (the car has gone)
			var st: Dictionary = crowd.call(&"stats")
			if int(st.helpers_knelt) > 0: knelt_seen = true
			if t - t0 < 20.0: return false
			_check(was_body, "the car reaches him: his balancing body has him")
			_check(bool(crowd.call(&"is_down", held)), "a hard knock (43 km/h): he is still down 20 s later, waiting for help (figure mode %d)" % (int(nb.get("figure_mode", -1))))
			_check(int(st.helpers_sent) >= 1, "passers-by come to him: %d sent" % int(st.helpers_sent))
			_check(knelt_seen, "one kneels by him (%d knelt)" % int(st.helpers_knelt))
			var kneel_clip := false
			for b: Dictionary in crowd.call(&"near_bodies"):
				if String(b.clip) == "ual/Fixing_Kneeling" or String(b.clip) == "ual/Idle_TalkingPhone_Loop": kneel_clip = true
			_check(kneel_clip, "a helper's figure plays the kneeling or phone clip")
			crowd.call(&"treat", held)      # (as the medic will)
			step = 3; t0 = t
		3:
			var nb := _body(held)
			if not nb.is_empty() and int(nb.figure_mode) != 1: got_up = true
			var st: Dictionary = crowd.call(&"stats")
			if (not got_up or int(st.actors) > 0) and t - t0 < 25.0: return false
			_check(got_up, "treated, he gets up (%.0f s)" % (t - t0))
			_check(int(st.actors) == 0, "and the helpers go on their way (%d actors left)" % int(st.actors))
			# 2) a gun aimed along the pavement from 10 m behind the nearest walker
			var target := {}
			for p: Dictionary in crowd.call(&"people_near", spot, 40.0):
				if int(p.mode) == 0 and int(p.id) != held: target = p; break
			if target.is_empty(): _check(false, "nobody to aim at"); step = 9; return false
			var tdir := Vector3(sin(float(target.yaw)), 0, cos(float(target.yaw)))
			from = (target.at as Vector3) - tdir * 10.0
			crowd.call(&"gun_aimed", from, tdir, 3.0)
			aimed = [int(target.id)]
			step = 4; t0 = t
		4:
			if t - t0 < 1.0: return false
			var st: Dictionary = crowd.call(&"stats")
			var w: int = aimed[0]
			_check(int(st.cowering) >= 1 and int(crowd.call(&"actor_role", w)) == 7, "a gun aimed at him: he cowers (%d in the line cower)" % int(st.cowering))
			var nb := _body(w)
			if not nb.is_empty(): _check(String(nb.clip) in ["ual/Surprise", "ual/Crouch_Idle_Loop"], "his figure: hands up or a crouch (%s)" % String(nb.clip))
			step = 5; t0 = t
		5:
			if t - t0 < 4.0: return false
			_check(not bool(crowd.call(&"is_actor", aimed[0])), "the aim off him (3 s): he is let go and runs")
			crowd.call(&"gunshot", spot, false)
			var st: Dictionary = crowd.call(&"stats")
			_check(int(st.alarms_shot) == 1 and int(st.fled) > 0, "a shot: the street's alarm (%d ran so far)" % int(st.fled))
			var inc: Array = crowd.call(&"take_incidents")
			var kinds := {}
			for e: Dictionary in inc: kinds[int(e.kind)] = true
			_check(kinds.has(2) and kinds.has(5), "the law hears of it: incidents %s (2 the car, 5 the shot)" % str(kinds.keys()))
			# 4) a policeman placed by the game, in uniform, in view
			cop = int(crowd.call(&"actor_place", spot + Vector3(1.5, 0, 0), 2, 0.0, 3))
			step = 6; t0 = t
		6:
			if t - t0 < 1.5: return false
			var nb := _body(cop)
			if nb.is_empty():
				var ws := []
				for b: Dictionary in crowd.call(&"near_bodies"): ws.append("%d@%.1f" % [int(b.walker), (b.at as Vector3).distance_to(spot)])
				print("STREET   (the cop %d at %.1f m; the near bodies: %s)" % [cop, (crowd.call(&"walker_at", cop) as Vector3).distance_to(spot), " ".join(ws)])
			_check(cop >= 0 and not nb.is_empty() and String(nb.body_id) in ["M4", "F4"], "an actor in police uniform (body %s)" % String(nb.get("body_id", "-")))
			crowd.call(&"actor_go", cop, spot + Vector3(1.5, 0, 8.0), 4.5, 0.5)
			step = 7; t0 = t
		7:
			if not bool(crowd.call(&"actor_arrived", cop)) and t - t0 < 6.0: return false
			var at: Vector3 = crowd.call(&"walker_at", cop)
			_check(bool(crowd.call(&"actor_arrived", cop)) and at.distance_to(spot + Vector3(1.5, 0, 8.0)) < 0.9, "he runs 8 m where he is sent (%.1f s, %.2f m off)" % [t - t0, at.distance_to(spot + Vector3(1.5, 0, 8.0))])
			crowd.call(&"actor_release", cop)
			_check(not bool(crowd.call(&"walker_alive", cop)), "let go, the placed actor is taken away")
			var st: Dictionary = crowd.call(&"stats")
			_check(int(st.bad_numbers) == 0, "no bad number")
			step = 9
		9:
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
