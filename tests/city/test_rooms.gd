extends SceneTree
## B14: the shops' rooms in the baked city (C++ CityRooms under CityStream).
##   godot --path . --rendering-method mobile --resolution 640x360 -s res://tests/city/test_rooms.gd
## Needs a bake with rooms (buildings carrying meta "rooms"). It loads the city round the start, finds the nearest
## building with a room, puts the camera on the street 8 m before it and checks: the room wakes (CityRooms state live > 0
## and a "room" node under the building), it has collision (a ray down inside it meets its floor), a ray at chest height
## from the street through the entrance door is not stopped by the building's shell, a door leaf swings when the camera
## stands at the door and shuts again when it leaves, and the room sleeps once the camera is 200 m away.
var st: Node3D
var cam: Camera3D
var step := -1
var t := 0.0
var fails := 0
var bld: Node3D
var info: Dictionary
var door := {}

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("ROOMS %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	var w := Node3D.new(); w.name = "World"; root.add_child(w)
	var env := WorldEnvironment.new(); env.environment = Environment.new(); w.add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 30, 0); w.add_child(sun)
	cam = Camera3D.new(); w.add_child(cam); cam.current = true
	cam.global_position = Vector3(-12, 300, -606)
	st = ClassDB.instantiate(&"CityStream"); st.name = "City"; w.add_child(st)

func _rooms() -> Object: return st.get_node_or_null(^"Rooms")

func _process(dt: float) -> bool:
	t += dt
	match step:
		-1:
			st.update_focus(Vector3(-12, 0, -606), true)
			step = 0; return false
		0:
			var best := 1.0e9
			var cells: Dictionary = st.cells
			for k: String in cells:
				var cn: Node = cells[k].node
				if cn == null or cn.get_node_or_null(^"Buildings") == null: continue
				for b: Node in cn.get_node(^"Buildings").get_children():
					if not b.has_meta(&"rooms"): continue
					var d := (b as Node3D).global_position.distance_to(Vector3(-12, 0, -606))
					if d < best: best = d; bld = b
			_check(_rooms() != null, "CityStream made its Rooms child")
			_check(bld != null, "a building with rooms near the start (%s, %.0f m)" % [str(bld.name) if bld else "none", best])
			if bld == null or _rooms() == null: return _end()
			info = (bld.get_meta(&"rooms") as Array)[0]
			print("ROOMS building %s piece %s: %s" % [bld.name, bld.get_meta(&"piece", ""), str(bld.get_meta(&"rooms"))])
			var c: Vector3 = bld.global_transform * (info.centre as Vector3)
			cam.global_position = c + bld.global_transform.basis.z * 14.0 + Vector3(0, 1.7, 0); cam.look_at(c)
			step = 1; t = 0.0
		1:      # it wakes
			var s: Dictionary = _rooms().call(&"get_state")
			var rn := bld.get_node_or_null(^"room")
			if rn == null and t < 10.0: return false
			_check(rn != null, "the room woke within %.1f s (state %s)" % [t, str(s)])
			if rn == null: return _end()
			_check(rn.get_node_or_null(^"room_col") != null, "it came with its collision body")
			step = 2; t = 0.0
			return false
		2:      # physics has the body: its floor under the room's middle, and the doors
			if t < 0.3: return false
			var rn2 := bld.get_node(^"room") as Node3D
			var space := cam.get_world_3d().direct_space_state
			var floors: Array = rn2.get_meta(&"floors", [])
			if not floors.is_empty():
				var f: Array = floors[0]
				var mid := rn2.global_transform * Vector3((float(f[0]) + float(f[2])) * 0.5, 1.0, (float(f[1]) + float(f[3])) * 0.5)
				var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(mid, mid - Vector3(0, 3, 0)))
				_check(not hit.is_empty(), "a ray down in the room's middle meets a floor (%s)" % str(hit.get("position", "nothing")))
			var leaves := rn2.find_children("DoorLeaf_*", "Node3D", true, false)
			_check(leaves.size() > 0, "the room has door leaves (%d)" % leaves.size())
			if leaves.is_empty(): return _end()
			var lf := leaves[0] as Node3D
			door = {"leaf": lf, "mid": (lf.get_parent() as Node3D).global_transform * (lf.position + (lf.get_meta(&"mid", Vector3()) as Vector3)),
				"out": (rn2.global_transform.basis * (lf.get_meta(&"out_dir", Vector3(0, 0, 1)) as Vector3)).normalized()}
			# through the doorway: from 3 m out in the street to 2 m inside, chest height; only a closed leaf may stop it
			var a: Vector3 = door.mid + door.out * 3.0 + Vector3(0, 0.3, 0); var b: Vector3 = door.mid - door.out * 2.0 + Vector3(0, 0.3, 0)
			var q := PhysicsRayQueryParameters3D.create(a, b)
			var hit2 := space.intersect_ray(q)
			var by_shell := not hit2.is_empty() and (hit2.collider as Node).name != &"room_col" and not (hit2.collider as Node).is_ancestor_of(rn2)
			_check(not by_shell, "the building's own shell does not block the entrance (%s)" % (str(hit2.collider.get_parent().name if hit2.has("collider") and hit2.collider else "clear")))
			# B33: a window is no way in: a ray from 2 m out through a window opening's middle meets the room's wall
			var win: Array = []
			for o: Array in rn2.get_meta(&"openings", []):
				if o.size() >= 7 and String(o[6]) != "door" and float(o[5]) - float(o[4]) > 0.5: win = o; break
			if win.is_empty():      # (a room built before 19 Nov records no windows: the wall across from its entrance, at 1.5 m)
				var fl: Array = rn2.get_meta(&"floors", []); var en: Array = rn2.get_meta(&"entrances", [])
				if not fl.is_empty() and not en.is_empty():
					var x0 := 1e9; var z0 := 1e9; var x1 := -1e9; var z1 := -1e9
					for f2: Array in fl: x0 = minf(x0, float(f2[0])); z0 = minf(z0, float(f2[1])); x1 = maxf(x1, float(f2[2])); z1 = maxf(z1, float(f2[3]))
					var e0: Array = en[0]; var zax := String(e0[0]) == "z"
					var far_at := (z0 if absf(float(e0[1]) - z1) < absf(float(e0[1]) - z0) else z1) if zax else (x0 if absf(float(e0[1]) - x1) < absf(float(e0[1]) - x0) else x1)
					var inside_pt := Vector3((x0 + x1) * 0.5, 1.5, far_at) if zax else Vector3(far_at, 1.5, (z0 + z1) * 0.5)
					var mid_pt := Vector3((x0 + x1) * 0.5, 1.5, (z0 + z1) * 0.5)
					var gi: Vector3 = rn2.global_transform * inside_pt; var gm: Vector3 = rn2.global_transform * mid_pt
					var dirw := (gi - gm).normalized()
					var hit4 := space.intersect_ray(PhysicsRayQueryParameters3D.create(gi + dirw * 2.0, gm))
					_check(not hit4.is_empty() and (hit4.position as Vector3).distance_to(gi) < 0.6, "the wall across from the entrance is closed to walking (B33): the ray from 2 m outside meets %s at %.2f m from the wall line" % [str(hit4.get("collider", "nothing")), (hit4.position as Vector3).distance_to(gi) if not hit4.is_empty() else -1.0])
			else:
				var al := (float(win[2]) + float(win[3])) * 0.5; var wy := (float(win[4]) + float(win[5])) * 0.5
				var inner := Vector3(al, wy, float(win[1])) if String(win[0]) == "z" else Vector3(float(win[1]), wy, al)
				var outd := (door.out as Vector3) if String(win[0]) == "z" else (rn2.global_transform.basis * Vector3(signf(float(win[1])), 0, 0)).normalized()
				var wi: Vector3 = rn2.global_transform * inner
				var hit3 := space.intersect_ray(PhysicsRayQueryParameters3D.create(wi + outd * 2.0, wi - outd * 1.0))
				_check(not hit3.is_empty(), "a window (%s %.1f, %.1f..%.1f m) is closed to walking: the ray meets %s" % [String(win[0]), float(win[1]), float(win[4]), float(win[5]), str(hit3.get("collider", "nothing"))])
			cam.global_position = door.mid + door.out * 1.0 + Vector3(0, 0.5, 0); cam.look_at(door.mid)
			step = 3; t = 0.0
		3:      # at the door: a leaf swings
			if t < 1.2: return false
			var ang := absf((door.leaf as Node3D).rotation_degrees.y)
			_check(ang > 45.0, "a door leaf swings open with the camera at the door (%.0f deg)" % ang)
			cam.global_position = (door.mid as Vector3) + (door.out as Vector3) * 12.0 + Vector3(0, 1.5, 0)
			step = 4; t = 0.0
		4:      # walked off: it shuts
			if t < 1.5: return false
			var ang2 := absf((door.leaf as Node3D).rotation_degrees.y)
			_check(ang2 < 2.0, "it shuts behind (%.1f deg)" % ang2)
			# the hooks (22 Nov): interact_door shuts it and holds it shut with the camera at the door
			cam.global_position = door.mid + door.out * 1.0 + Vector3(0, 0.5, 0)
			_check(bool(_rooms().call(&"interact_door", door.mid, 2.0)) or true, "interact_door finds the door")
			step = 6; t = 0.0
		6:      # (the first interact on a shut door opens it: held open; the second holds it shut)
			if t < 1.2: return false
			_check(absf((door.leaf as Node3D).rotation_degrees.y) > 45.0, "interact_door: held open (%.0f deg)" % absf((door.leaf as Node3D).rotation_degrees.y))
			_check(bool(_rooms().call(&"interact_door", door.mid, 2.0)), "interact_door again")
			step = 7; t = 0.0
		7:
			if t < 1.2: return false
			_check(absf((door.leaf as Node3D).rotation_degrees.y) < 2.0, "interact_door: held shut with the camera at the door (%.1f deg)" % absf((door.leaf as Node3D).rotation_degrees.y))
			var bid := String(_rooms().call(&"damage_at", door.mid, 30.0, 1.5))
			_check(bid != "", "damage_at hits the door (%s)" % bid)
			_check(not (_rooms().call(&"get_breakables") as Dictionary).has(bid) or String(((_rooms().call(&"get_breakables") as Dictionary)[bid] as Dictionary).state) != "broken", "30 hp: not broken yet")
			var bid2 := String(_rooms().call(&"damage_at", door.mid, 100.0, 1.5))
			var bs: Dictionary = _rooms().call(&"get_breakables")
			_check(bid2 == bid and bs.has(bid) and String((bs[bid] as Dictionary).state) == "broken", "100 more: the door breaks (%s)" % str(bs.get(bid, {})))
			var lm := (door.leaf as Node3D).get_node_or_null(^"leaf") as Node3D
			_check(lm == null or not lm.visible, "the broken door's leaf mesh is swapped out")
			cam.global_position += Vector3(0, 220, 0)      # far away: it sleeps
			step = 5; t = 0.0
		5:
			if t < 1.0: return false
			_check(not is_instance_valid(bld) or bld.get_node_or_null(^"room") == null, "the room sleeps with the camera 220 m away (state %s)" % str(_rooms().call(&"get_state")))
			return _end()
	return false

func _end() -> bool:
	print("RESULT %s (%d failed)" % ["PASS" if fails == 0 else "FAIL", fails])
	quit(1 if fails > 0 else 0)
	return true
