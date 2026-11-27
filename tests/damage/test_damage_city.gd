extends SceneTree
## Damage option B, stage A, in the BAKED city (25 Nov 2026). Needs the bake (map_dc/coronado/city_kit/runtime): run it
## on the PC, not in the cloud.
##   godot --path . --rendering-method mobile --resolution 960x540 -s res://tests/damage/test_damage_city.gd [-- --shots=DIR]
## It loads the city round the start, wakes the nearest built-in shop room (breakable windows), and from the street:
##  - shoots one pane five times through its middle: holes 1, 2 (intact, holed), cracked at the third (hp <= 15), broken at
##    the fifth; the pane's shader gets the holes; the saved state keeps them; obstacle_changed fires once;
##  - shoots the building's wall beside it (a mark; the surface from the kit), the pavement and the road in front (the
##    ground map: ground_surface after a new bake, else concrete), and prints every surface it met;
##  - prints the damage node's state (one draw for the marks).
var st: Node3D
var cam: Camera3D
var step := -1
var t := 0.0
var fails := 0
var bld: Node3D
var win: Node3D
var changed := 0
var shots_dir := ""

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("DMGC  %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="): shots_dir = a.trim_prefix("--shots=")
	var w := Node3D.new(); w.name = "World"; root.add_child(w)
	var env := WorldEnvironment.new(); env.environment = Environment.new(); w.add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 30, 0); w.add_child(sun)
	cam = Camera3D.new(); w.add_child(cam); cam.current = true
	cam.global_position = Vector3(-12, 300, -606)
	st = ClassDB.instantiate(&"CityStream"); st.name = "City"; w.add_child(st)

func _dmg() -> Node: return st.get_node_or_null(^"Damage")
func _rooms() -> Node: return st.get_node_or_null(^"Rooms")

func _shot(nm: String) -> void:
	if shots_dir == "": return
	DirAccess.make_dir_recursive_absolute(shots_dir)
	var img := root.get_texture().get_image()
	if img: img.save_png(shots_dir.path_join(nm + ".png"))

func _process(dt: float) -> bool:
	t += dt
	match step:
		-1:
			st.update_focus(Vector3(-12, 0, -606), true)
			step = 0; return false
		0:
			_check(_dmg() != null, "CityStream made its Damage child")
			if _dmg() == null or _rooms() == null: return _end()
			_dmg().connect(&"obstacle_changed", func(_b: AABB) -> void: changed += 1)
			var best := 1.0e9
			for k: String in st.cells:
				var cn: Node = st.cells[k].node
				if cn == null or cn.get_node_or_null(^"Buildings") == null: continue
				for b: Node in cn.get_node(^"Buildings").get_children():
					if not b.has_meta(&"rooms"): continue
					if not String(((b.get_meta(&"rooms") as Array)[0] as Dictionary).scn).get_file().begins_with("bi_"): continue
					var d := (b as Node3D).global_position.distance_to(Vector3(-12, 0, -606))
					if d < best: best = d; bld = b
			_check(bld != null, "a built-in shop near the start (%s)" % (str(bld.name) if bld else "none"))
			if bld == null: return _end()
			var c: Vector3 = bld.global_transform * (((bld.get_meta(&"rooms") as Array)[0] as Dictionary).centre as Vector3)
			cam.global_position = c + bld.global_transform.basis.z * 14.0 + Vector3(0, 1.7, 0); cam.look_at(c)
			step = 1; t = 0.0
		1:
			var rn := bld.get_node_or_null(^"room")
			if rn == null and t < 10.0: return false
			if rn == null: _check(false, "the room woke"); return _end()
			if t < 0.5: return false
			for n: Node in rn.find_children("Window_*", "Node3D", true, false):
				if n.get_node_or_null(^"pane") != null: win = n; break
			_check(win != null, "the room has a breakable window")
			if win == null: return _end()
			var sz: Vector2 = win.get_meta(&"size", Vector2(1, 1))
			var mid: Vector3 = win.global_transform * Vector3(sz.x * 0.5, sz.y * 0.5, 0)
			var nrm := (win.global_transform.basis * Vector3(0, 0, 1)).normalized()
			# from the street side (the side away from the room's centre)
			var c2: Vector3 = bld.global_transform * (((bld.get_meta(&"rooms") as Array)[0] as Dictionary).centre as Vector3)
			if (mid - c2).dot(nrm) < 0.0: nrm = -nrm
			cam.global_position = mid + nrm * 4.0; cam.look_at(mid)
			var states := []
			for i in 5:
				var off := Vector3(0, (i - 2) * 0.12 * sz.y, 0) + win.global_transform.basis.x.normalized() * ((i % 2) - 0.5) * 0.25 * sz.x
				var r: Dictionary = _dmg().call(&"shoot", mid + nrm * 4.0 + off, -nrm, 10.0, 10.0, null)
				var bs: Dictionary = (_rooms().call(&"get_breakables") as Dictionary).get(String(r.get("target_id", "")), {})
				states.append([String(r.get("surface", "")), String(r.get("state", "")), String(bs.get("state", "")), (bs.get("holes", []) as Array).size() / 2])
				if i == 1: _shot("city_pane_two_holes")
				if i == 2: _shot("city_pane_cracked")
			print("DMGC  five shots at %s: %s" % [win.name, str(states)])
			_check(states[0][0] == "glass", "the pane reads glass")
			_check(states[0][2] == "intact" and states[0][3] == 1 and states[1][3] == 2, "two shots: intact, two holes")
			_check(states[2][2] == "cracked", "the third cracks it")
			_check(states[4][2] == "broken", "the fifth breaks it")
			_check(changed == 1, "obstacle_changed fired once (%d)" % changed)
			# the wall beside it, the pavement and the road in front
			var wall_at: Vector3 = mid + win.global_transform.basis.x.normalized() * (sz.x * 0.5 + 0.6)
			var rw: Dictionary = _dmg().call(&"shoot", wall_at + nrm * 4.0, -nrm, 10.0, 10.0, null)
			print("DMGC  the wall beside: %s (kit %s)" % [str(rw), str(bld.get_meta(&"kit", ""))])
			_check(String(rw.get("surface", "")) in ["brick", "stucco", "stone", "concrete", "wood", "metal"] and String(rw.get("state", "")) == "marked", "the wall takes a mark")
			for d in [2.0, 6.0, 9.0]:
				var g: Dictionary = _dmg().call(&"shoot", mid + nrm * d + Vector3(0, 3, 0), Vector3(0, -1, 0), 10.0, 10.0, null)
				print("DMGC  the ground %.0f m out: %s" % [d, str(g)])
			var s: Dictionary = _dmg().call(&"get_state")
			print("DMGC  state %s" % str(s))
			_check(int(s.mark_draws) == 1, "the marks: one draw")
			step = 2; t = 0.0
		2:
			if t < 0.2: return false
			_shot("city_after")
			return _end()
	return false

func _end() -> bool:
	print("DMGC  RESULT %s (%d failed)" % ["PASS" if fails == 0 else "FAIL", fails])
	quit(1 if fails > 0 else 0)
	return true
