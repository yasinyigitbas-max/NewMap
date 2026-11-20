extends SceneTree
## A cafe's people (Yasin, 20 Nov: "add sitting cafe npcs too, all of them should be interactible like normal npcs, then
## cashiers should have a hook to open purchase screen when its implemented"), headless:
##   godot --headless --fixed-fps 60 --path . -s res://tests/people/test_shop_life.gd
## The corner cafe (13 seats) by a pavement as if awake (CityShops.open_room). 1) People sit at its seats with sitting clips,
## on the floor's height. 2) A sitter and the cashier are talked to (CityTalk.begin): they agree, the cashier turns to the
## player and plays the talking clip, the sitter stays seated; after the talk the cashier goes back to his till's clip.
## 3) The purchase screen on: BUY sends purchase_requested (the shop, its item and price) and the cashier waits; the screen
## completes it: the pay's moves with the player.
var crowd: Node3D
var shops: Node
var talk: Node
var player: CharacterBody3D
var cam: Camera3D
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var xf := Transform3D.IDENTITY
var requests := []
var pclips := {}
var sitter := -1
var cashier := -1

func _initialize() -> void:
	if not ClassDB.class_exists(&"CityShops"):
		print("SHOPLIFE ERROR the native module is not built"); print("RESULT FAIL"); quit(1); return
	crowd = ClassDB.instantiate(&"CityCrowd")
	crowd.set(&"max_people", 200); crowd.set(&"hour", 12.5); crowd.set(&"near_max", 18)
	root.add_child(crowd)
	shops = ClassDB.instantiate(&"CityShops")
	root.add_child(shops)
	shops.connect(&"purchase_requested", func(d: Dictionary): requests.append(d))
	cam = Camera3D.new(); cam.position = Vector3(0, 40, -620); cam.rotation_degrees = Vector3(-90, 0, 0); root.add_child(cam); cam.current = true

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("SHOPLIFE %s: %s" % ["ok" if ok else "FAIL", what])

func _info() -> Dictionary:
	var a: Array = shops.call(&"shops_info")
	return a[0] if a.size() > 0 else {}

func _body(w: int) -> Dictionary:
	for nb: Dictionary in crowd.call(&"near_bodies"): if int(nb.walker) == w: return nb
	return {}

func _physics_process(delta: float) -> bool:
	t += delta
	if player: pclips[String(player.call(&"get_clip"))] = true
	match step:
		0:
			if t < 5.0: return false
			var pv: Dictionary = crowd.call(&"pavement_near", Vector3(0, 0, -620), 300.0)
			var spot: Vector3 = pv.at
			var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
			sh.size = Vector3(200, 2, 200); cs.shape = sh; fl.add_child(cs); fl.position = Vector3(spot.x, spot.y - 1.0, spot.z); root.add_child(fl)
			var back: Vector3 = -(pv.get("edge", Vector3(1, 0, 0)) as Vector3)
			xf = Transform3D(Basis(Vector3.UP, atan2(-back.x, -back.z)), spot + back * 7.0)
			player = ClassDB.instantiate(&"CityPlayer"); root.add_child(player)
			player.global_position = spot + Vector3(0, 0.1, 0)
			crowd.call(&"set_player", player)
			shops.call(&"set_world", crowd, player)
			talk = ClassDB.instantiate(&"CityTalk"); root.add_child(talk)
			talk.call(&"set_crowd", crowd); talk.call(&"set_player", player)
			_check(bool(shops.call(&"open_room", "ap_corner_cafe", xf)), "the corner cafe opens")
			cam.global_position = xf.origin + Vector3(0, 9, 0); cam.look_at(xf.origin, Vector3(0, 0, -1))
			step = 1; t0 = t
		1:      # people seated
			if t - t0 < 2.5: return false
			var inf := _info()
			cashier = int(inf.cashier)
			var sitters: Array = inf.sitters
			_check(int(inf.seats) >= 10 and sitters.size() >= 1, "people sit at its %d seats: %d sitting" % [int(inf.seats), sitters.size()])
			var seated_clip := 0
			for s: Dictionary in sitters:
				var nb := _body(int(s.walker))
				if not nb.is_empty() and String(nb.clip).begins_with("ual/Sitting"): seated_clip += 1
				if sitter < 0: sitter = int(s.walker)
			_check(seated_clip >= 1, "with sitting clips (%d of %d with a near figure)" % [seated_clip, sitters.size()])
			var sat: Vector3 = crowd.call(&"walker_at", sitter)
			_check(absf(sat.y - (xf.origin.y + 0.02)) < 0.05, "on the floor's height, not the seat's (%.2f m off)" % (sat.y - xf.origin.y - 0.02))
			# 2) talking: to the sitter (he agrees; stays seated)
			player.global_position = sat + (xf.basis.z * 1.2) + Vector3(0, 0.1, 0)
			talk.call(&"set_force", 0.0, 1.0, 1.0, 1.0, "T5")
			var r: String = talk.call(&"begin", sitter)
			_check(r == "talk" and int(talk.call(&"get_active")) == sitter, "a sitter can be talked to (%s)" % r)
			step = 2; t0 = t
		2:
			if t - t0 < 1.5: return false
			var nb := _body(sitter)
			_check(not nb.is_empty() and String(nb.clip).begins_with("ual/Sitting"), "he stays seated while he talks (%s)" % String(nb.get("clip", "-")))
			talk.call(&"end", "done")
			# ... and to the cashier, from the queue spot
			var inf := _info()
			player.global_position = (inf.queue as Vector3) + Vector3(0, 0.1, 0)
			var r: String = talk.call(&"begin", cashier)
			_check(r == "talk", "the cashier can be talked to (%s)" % r)
			step = 3; t0 = t
		3:
			if t - t0 < 1.5: return false
			var nb := _body(cashier)
			_check(String(nb.get("clip", "")) == "ual/Idle_Talking_Loop", "he turns to the player and talks (%s)" % String(nb.get("clip", "-")))
			talk.call(&"end", "done")
			step = 4; t0 = t
		4:
			if t - t0 < 1.0: return false
			var nb := _body(cashier)
			_check(String(nb.get("clip", "")) == "ual/Counter_Idle_Loop" or String(nb.get("clip", "")).begins_with("ual/Counter"), "after the talk he is back at his till (%s)" % String(nb.get("clip", "-")))
			# 3) the purchase screen
			shops.set(&"purchase_screen", true)
			var inf := _info()
			if int(inf.paying) != -2: return false      # (a customer paying: wait)
			player.global_position = (inf.queue as Vector3) + Vector3(0, 0.1, 0)
			step = 5; t0 = t
		5:
			if t - t0 < 0.5: return false
			_check(bool(shops.call(&"buy")), "BUY with the purchase screen on")
			_check(requests.size() == 1 and String(requests[0].kind) == "cafe" and int(requests[0].price) > 0, "purchase_requested sent: %s" % str(requests))
			_check(int(_info().paying) == -3, "the cashier waits for the screen")
			step = 6; t0 = t
		6:
			if t - t0 < 2.0: return false
			_check(int(_info().paying) == -3, "still waiting 2 s later (nothing sold before the screen answers)")
			pclips.clear()
			_check(bool(shops.call(&"complete_purchase", "a flat white", "bir flat white", 5)), "the screen completes it")
			step = 7; t0 = t
		7:
			if t - t0 < 6.5: return false
			_check(pclips.has("ual/Counter_Give") and pclips.has("ual/Interact"), "the pay's moves with the player (%s)" % str(pclips.keys()))
			_check(int(_info().paying) != -1 and int((shops.call(&"stats") as Dictionary).sales) >= 1, "his purchase is over (the cashier free, or on with the next customer)")
			var st: Dictionary = shops.call(&"stats")
			print("SHOPLIFE stats %s" % str(st))
			_check(int((crowd.call(&"stats") as Dictionary).bad_numbers) == 0, "no bad number in the crowd")
			step = 9
		9:
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
