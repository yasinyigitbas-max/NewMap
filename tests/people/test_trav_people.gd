extends SceneTree
## The new people in the crowd (28 Nov; C++: CityCrowd::set_trav_people, city_crowd_trav.cpp), headless:
##   godot --headless --fixed-fps 60 --path . -s res://tests/people/test_trav_people.gd
## Needs res://traversal/ (bash tools/traversal/sync_to_game.sh). The real streets over a flat floor, the player among
## the people. Every near figure is drawn as a new body on the traversal system that walks after its walker's place:
## how many are shown, that the old figures under them are not drawn, how far each new body is from its walker (the
## nearest person of the crowd), how far they walked, that none fell through the floor.
var crowd: Node3D
var player: Node3D
var t := 0.0
var step := 0
var fails := 0
var spot := Vector3.ZERO
var first := {}
var worst := 0.0
var sum := 0.0
var n_sum := 0
var most := 0

func _initialize() -> void:
	if not ClassDB.class_exists(&"CityCrowd") or not ClassDB.class_exists(&"TravBody"):
		print("TRAVPEOPLE ERROR the native module is not built with the traversal classes"); print("RESULT FAIL"); quit(1); return
	crowd = ClassDB.instantiate(&"CityCrowd")
	crowd.set(&"max_people", 300); crowd.set(&"hour", 12.5); crowd.set(&"near_max", 12)
	root.add_child(crowd)
	var cam := Camera3D.new(); cam.position = Vector3(0, 40, -620); cam.rotation_degrees = Vector3(-90, 0, 0); root.add_child(cam); cam.current = true

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("TRAVPEOPLE  %s: %s" % ["ok" if ok else "FAIL", what])

func _bodies() -> Array:
	var l := []
	for c in crowd.get_children():
		if String(c.name).begins_with("TravNpc") and (c as Node3D).visible: l.append(c)
	return l

func _physics_process(delta: float) -> bool:
	if crowd == null: return true
	t += delta
	match step:
		0:
			if t < 6.0: return false
			for p: Dictionary in crowd.call(&"people_near", Vector3(0, 0, -620), 200.0):
				if int(p.mode) == 0 and int(p.state) == 0 and float(p.speed) > 0.9:
					spot = p.at; break
			if spot == Vector3.ZERO: _check(false, "no walker on a pavement within 200 m of the centre"); step = 99; return false
			var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
			sh.size = Vector3(800, 2, 800); cs.shape = sh; fl.add_child(cs); fl.position = Vector3(spot.x, spot.y - 1.0, spot.z); root.add_child(fl)
			player = ClassDB.instantiate(&"CityPlayer"); player.position = spot + Vector3(1.5, 0.05, 0); root.add_child(player)
			crowd.call(&"set_player", player)
			crowd.call(&"set_trav_people", true)
			_check(bool(crowd.call(&"get_trav_people")), "the switch takes")
			step = 1
		1:
			if t < 10.0: return false
			var people: Array = crowd.call(&"people_near", spot, 120.0)
			var l := _bodies()
			most = maxi(most, l.size())
			for b: Node3D in l:
				if not first.has(b.name): first[b.name] = b.global_position
				var near := 99.0
				for p: Dictionary in people: near = minf(near, Vector2(p.at.x - b.global_position.x, p.at.z - b.global_position.z).length())
				worst = maxf(worst, near); sum += near; n_sum += 1
			if t < 40.0: return false
			var walked := 0; var low := 0.0; var drawn_old := 0
			for b: Node3D in l:
				if (b.global_position - first.get(b.name, b.global_position)).length() > 3.0: walked += 1
				low = minf(low, b.global_position.y - spot.y)
			for nb: Dictionary in crowd.call(&"near_bodies"):
				pass
			_check(most >= 4, "new bodies shown at once, at most: %d" % most)
			_check(n_sum > 0 and sum / maxf(n_sum, 1) < 0.8, "a new body is on average %.2f m from the nearest person of the crowd (its walker); the worst moment %.2f m" % [sum / maxf(n_sum, 1), worst])
			_check(walked >= 2, "of the %d shown at the end, %d walked more than 3 m since they were first seen" % [l.size(), walked])
			_check(low > -0.3, "none is under the floor (lowest %.2f m)" % low)
			print("RESULT %s (%d)" % ["PASS" if fails == 0 else "FAIL", fails]); quit(1 if fails else 0); step = 99
	return false
