extends SceneTree
## The crowd in the game with a player on foot (C++ classes CityCrowd, CityPed, CityPlayer), headless:
##   godot --headless --fixed-fps 60 --path . -s res://tests/people/test_crowd_game.gd
## The real streets and places over a flat test floor. It checks what the console test cannot: the nearest people get
## animated bodies; a person the player runs into is handed to his physical body (staggers or falls) and walks on
## afterwards; the player cannot walk through a person who stands (the capsules); umbrellas come out in rain; a fright
## makes people duck and run; the game hears the events. This script only sets things up and reads counts.
var crowd: Node3D
var player: Node3D
var t := 0.0
var phase := 0
var t0 := 0.0
var fails := 0
var spot := Vector3.ZERO
var dir := Vector3.FORWARD
var target := -1
var was_body := false
var back := false
var events := 0
var stander := -1
var gap_least := 99.0

func _initialize() -> void:
	if not ClassDB.class_exists(&"CityCrowd") or not ClassDB.class_exists(&"CityPlayer"):
		print("GAME ERROR the native module is not built: run  bash native/build.sh"); print("RESULT FAIL"); quit(1); return
	crowd = ClassDB.instantiate(&"CityCrowd")
	crowd.set(&"max_people", 400); crowd.set(&"hour", 12.5)
	root.add_child(crowd)
	crowd.connect(&"crowd_event", func(_ty: int, _id: int, _aux: int, _f: float) -> void: events += 1)
	var cam := Camera3D.new(); cam.position = Vector3(0, 40, -620); cam.rotation_degrees = Vector3(-90, 0, 0); root.add_child(cam); cam.current = true

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("GAME   %s: %s" % ["ok" if ok else "FAIL", what])

func _person(id: int) -> Dictionary:
	for p: Dictionary in crowd.call(&"people_near", spot, 400.0):
		if int(p.id) == id: return p
	return {}

func _physics_process(delta: float) -> bool:
	if crowd == null: return true
	t += delta
	match phase:
		0:      # let the crowd fill; then the player is set down behind a lone walker on a pavement
			if t < 8.0: return false
			var ppl: Array = crowd.call(&"people_near", Vector3(0, 0, -620), 200.0)
			for p: Dictionary in ppl:
				if int(p.mode) == 0 and int(p.state) == 0 and int(p.party) == 0 and float(p.speed) > 0.9:
					target = int(p.id); spot = p.at; dir = Vector3(sin(float(p.yaw)), 0, cos(float(p.yaw))); break
			if target < 0: _check(false, "no lone walker within 200 m of the centre (%d people)" % ppl.size()); phase = 9; return false
			var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
			sh.size = Vector3(800, 2, 800); cs.shape = sh; fl.add_child(cs); fl.position = Vector3(spot.x, spot.y - 1.0, spot.z); root.add_child(fl)
			player = ClassDB.instantiate(&"CityPlayer")
			player.position = spot - dir * 7.0 + Vector3(0, 0.05, 0)
			root.add_child(player)
			crowd.call(&"set_player", player)
			print("GAME %d people within 200 m of the centre; the player is set 7 m behind walker %d at (%.1f, %.1f)" % [ppl.size(), target, spot.x, spot.z])
			phase = 1; t0 = t
		1:      # a second for the nearest people to get their bodies; then he runs at the walker
			if t - t0 < 1.5: return false
			var st: Dictionary = crowd.call(&"stats")
			_check(int(st.near_bodies) >= 3, "the nearest people have animated bodies (%d of %d in the pool; %d people in all)" % [int(st.near_bodies), int(st.near_pool), int(st.people)])
			phase = 2; t0 = t
		2:
			var p := _person(target)
			if p.is_empty(): _check(false, "the walker he ran at is gone"); phase = 4; t0 = t; return false
			var to: Vector3 = (p.at as Vector3) - player.global_position; to.y = 0
			if not was_body:
				# (seen from the camera behind him: straight at the walker)
				var cam: Camera3D = root.get_viewport().get_camera_3d()
				var f := -cam.global_basis.z; f.y = 0; f = f.normalized()
				var r := Vector3(-f.z, 0, f.x)
				var d := to.normalized()
				player.call(&"set_move", Vector2(d.dot(r), d.dot(f)), true)
			if int(p.mode) == 7:
				if not was_body: print("GAME   (walker %d is in his physical body %.1f s after the player set off, the player at %.1f m/s)" % [target, t - t0, float(player.call(&"get_speed"))])
				was_body = true; player.call(&"set_move", Vector2.ZERO, false)
			elif was_body and (int(p.mode) == 0 or int(p.mode) == 3): back = true
			if back or t - t0 > 25.0:
				_check(was_body, "a person the player runs into is handed to his physical body")
				_check(back, "and walks on afterwards (%.1f s after the player set off)" % (t - t0))
				phase = 3; t0 = t
		3:      # a person who stands: the player cannot walk through him
			if stander < 0:
				var pp: Vector3 = player.global_position
				var cam: Camera3D = root.get_viewport().get_camera_3d()
				var f := -cam.global_basis.z; f.y = 0; f = f.normalized()
				stander = int(crowd.call(&"place_walker", pp + f * 3.0, 4242))
				crowd.call(&"stay", stander, 60.0)
				player.call(&"set_move", Vector2(0, 0.6), false)      # ahead at a slow walk (no shove at that pace)
				t0 = t
				return false
			var s := _person(stander)
			if not s.is_empty():
				var gap := Vector2((s.at as Vector3).x - player.global_position.x, (s.at as Vector3).z - player.global_position.z).length()
				gap_least = minf(gap_least, gap)
			if t - t0 < 7.0: return false
			player.call(&"set_move", Vector2.ZERO, false)
			_check(not s.is_empty() and gap_least > 0.45 and gap_least < 1.2, "the player walks up to a person who stands and is stopped by him: nearest %.2f m centre to centre, the player's speed then %.2f m/s" % [gap_least, float(player.call(&"get_speed"))])
			crowd.call(&"remove_walker", stander)
			phase = 4; t0 = t
		4:      # rain: umbrellas
			crowd.set(&"rain", 1.0)
			if t - t0 < 2.0: return false
			var st: Dictionary = crowd.call(&"stats")
			_check(int(st.umbrellas) > 0, "it rains: %d of %d people carry an umbrella" % [int(st.umbrellas), int(st.people)])
			crowd.set(&"rain", 0.0)
			phase = 5; t0 = t
		5:      # a fright where the player stands
			var before: Dictionary = crowd.call(&"stats")
			crowd.call(&"scare", player.global_position, 35.0, 6.0)
			var after: Dictionary = crowd.call(&"stats")
			_check(int(after.fled) + int(after.ducked) > int(before.fled) + int(before.ducked), "a fright at the player: %d duck, %d run" % [int(after.ducked) - int(before.ducked), int(after.fled) - int(before.fled)])
			phase = 6; t0 = t
		6:
			if t - t0 < 4.0: return false
			var st: Dictionary = crowd.call(&"stats")
			_check(int(st.inside_each_other) == 0 and int(st.bad_numbers) == 0, "nobody inside anybody, no bad number at the end")
			_check(events > 20, "the game heard %d events (the signal crowd_event)" % events)
			print("GAME %s" % String(crowd.call(&"report")))
			phase = 9
		9:
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
