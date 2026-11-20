extends SceneTree
## The people in the shops (Yasin, 20 Nov: "add npcs into shops, some customers and a cashier, add us and npcs giving money
## receiving things animations"), headless:
##   godot --headless --fixed-fps 60 --path . -s res://tests/people/test_shops.gd [-- --room=NAME]
## A room of interiors/room_people.json (the corner market) set down by a pavement on a flat floor, as if CityRooms had it
## awake (CityShops.open_room). 1) A cashier stands behind the counter (Counter_Idle_Loop). 2) Customers come in at the
## door, look at shelves, queue and pay: the four moves seen on the figures (Counter_Show, Counter_Give, Interact) and they
## leave. 3) The player at the counter buys: the same moves with him (CityPlayer.act).
var crowd: Node3D
var shops: Node
var player: CharacterBody3D
var cam: Camera3D
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var room := "ap_corner_market"
var spot := Vector3.ZERO
var clips := {}
var pclips := {}

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--room="): room = a.trim_prefix("--room=")
	if not ClassDB.class_exists(&"CityShops"):
		print("SHOPS ERROR the native module is not built"); print("RESULT FAIL"); quit(1); return
	crowd = ClassDB.instantiate(&"CityCrowd")
	crowd.set(&"max_people", 250); crowd.set(&"hour", 12.5); crowd.set(&"near_max", 18)
	root.add_child(crowd)
	shops = ClassDB.instantiate(&"CityShops")
	root.add_child(shops)
	cam = Camera3D.new(); cam.position = Vector3(0, 40, -620); cam.rotation_degrees = Vector3(-90, 0, 0); root.add_child(cam); cam.current = true

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("SHOPS   %s: %s" % ["ok" if ok else "FAIL", what])

func _info() -> Dictionary:
	var a: Array = shops.call(&"shops_info")
	return a[0] if a.size() > 0 else {}

func _physics_process(delta: float) -> bool:
	t += delta
	if step >= 1 and step < 9:
		var inf := _info()
		for nb: Dictionary in crowd.call(&"near_bodies"): clips[String(nb.clip)] = true
		if player: pclips[String(player.call(&"get_clip"))] = true
	match step:
		0:
			if t < 5.0: return false
			var pv: Dictionary = crowd.call(&"pavement_near", Vector3(0, 0, -620), 300.0)
			if not bool(pv.get("ok", false)): _check(false, "no pavement"); step = 9; return false
			spot = pv.at
			var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
			sh.size = Vector3(200, 2, 200); cs.shape = sh; fl.add_child(cs); fl.position = Vector3(spot.x, spot.y - 1.0, spot.z); root.add_child(fl)
			# the room's frame 9 m off the pavement's edge (its door comes out onto the pavement)
			var edge: Vector3 = pv.get("edge", Vector3(1, 0, 0))
			var back := -edge
			var basis := Basis(Vector3.UP, atan2(-back.x, -back.z))     # (the room's +Z, its front, faces the pavement)
			var xf := Transform3D(basis, spot + back * 7.0)
			player = ClassDB.instantiate(&"CityPlayer"); root.add_child(player)
			player.global_position = spot + Vector3(0, 0.1, 0)
			crowd.call(&"set_player", player)
			shops.call(&"set_world", crowd, player)
			_check(bool(shops.call(&"open_room", room, xf)), "the room %s opens as a shop (%s)" % [room, str((shops.call(&"stats") as Dictionary))])
			cam.global_position = xf.origin + Vector3(0, 9, 0); cam.look_at(xf.origin, Vector3(0, 0, -1))
			step = 1; t0 = t
		1:
			if t - t0 < 2.0: return false
			var inf := _info()
			var cb := {}
			for nb: Dictionary in crowd.call(&"near_bodies"): if int(nb.walker) == int(inf.get("cashier", -9)): cb = nb
			_check(int(inf.get("cashier", -1)) >= 0 and String(cb.get("clip", "")) == "ual/Counter_Idle_Loop", "a cashier behind the counter (%s)" % String(cb.get("clip", "no figure")))
			var at: Vector3 = crowd.call(&"walker_at", int(inf.cashier))
			_check(at.distance_to(inf.staff) < 0.6, "standing at the staff spot (%.2f m off)" % at.distance_to(inf.staff))
			step = 2; t0 = t
		2:      # customers: in, browse, queue, pay, out
			var st: Dictionary = shops.call(&"stats")
			if (int(st.sales) < 1 or int(st.customers_out) < 1) and t - t0 < 120.0: return false
			_check(int(st.customers_in) >= 1, "customers came in (%d)" % int(st.customers_in))
			_check(int(st.sales) >= 1, "a customer paid (%d sales in %.0f s)" % [int(st.sales), t - t0])
			_check(clips.has("ual/Idle_LookAround_Loop"), "a customer looked along a shelf")
			_check(clips.has("ual/Counter_Show") and clips.has("ual/Counter_Give") and clips.has("ual/Interact"), "the pay's moves were played (rung up, money and goods over, taken): %s" % str(clips.keys().filter(func(c): return String(c).begins_with("ual/Counter") or c == "ual/Interact")))
			_check(int(st.customers_out) >= 1, "and went out to the street (%d)" % int(st.customers_out))
			step = 3; t0 = t
		3:      # the player at the counter, when the cashier is free
			var inf := _info()
			if int(inf.paying) != -2:
				if t - t0 > 40.0: _check(false, "the cashier free within 40 s"); step = 9
				return false
			player.global_position = (inf.queue as Vector3) + Vector3(0, 0.1, 0)
			step = 4; t0 = t
		4:
			if t - t0 < 0.5: return false
			_check(bool(shops.call(&"can_buy")), "at the counter: the HUD would offer BUY")
			_check(bool(shops.call(&"buy")), "he buys")
			pclips.clear()
			step = 5; t0 = t
		5:
			if t - t0 < 7.0: return false
			_check(int(player.call(&"get_acts")) >= 3, "he stood, paid and took it (%d acts)" % int(player.call(&"get_acts")))
			_check(pclips.has("ual/Counter_Give") and pclips.has("ual/Interact"), "his figure handed the money over and took the goods (%s)" % str(pclips.keys()))
			_check(int((shops.call(&"stats") as Dictionary).buys) == 1, "one buy counted")
			var cs: Dictionary = crowd.call(&"stats")
			_check(int(cs.bad_numbers) == 0, "no bad number in the crowd")
			step = 9
		9:
			print("SHOPS   stats %s" % str(shops.call(&"stats")))
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
