extends Node
## AUTOPLAY (28 Nov night): the GAME played by itself on the phone, for a test with no hands on it (the Redmi refuses
## adb taps). Started by the rig app with `--autoplay` (rig.gd; phone_rig.sh run NAME --autoplay): it goes to the game's
## menu (game/boot.tscn), presses New game, and then, printing RIG lines the phone run collects:
##   1. walks ahead 25 s (the W key, as a PC player walks): frame times; people seen as new bodies; old figures seen
##      (a CityPed whose mesh is drawn: must be 0); the far crowd's drawn count (must be 0)
##   2. gets into the start car, drives ahead 20 s: his body's distance from the car as drawn (must stay under 2 m);
##      the streamer's focus distance from the car (must stay near it); frame times while driving
##   3. out again; a traffic car near him taken twice in a row (the second must give nothing: one car per hijack)
## then "RIG plan_done" and the app quits. Every check prints AUTO ok / AUTO FAIL.
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var game: Node
var pl: Node3D
var car: Node3D
var body: Node3D
var st: Node
var crowd: Node
var trf: Node
# frame times per phase
var ph := ""
var ph_frames := 0
var ph_over33 := 0
var ph_over50 := 0
var ph_worst := 0.0
var ph_sum := 0.0
# people
var old_most := 0
var old_where := ""
var new_most := 0
var far_most := 0
var next_sample := 0.0
# driving
var drive_worst := 0.0
var drive_out := 0
var drive_frames := 0
var focus_worst := 0.0
var start_pos := Vector3()

func _say(s: String) -> void:
	print("RIG auto " + s)

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	_say("%s: %s" % ["ok" if ok else "FAIL", what])

func _key(k: Key, down: bool) -> void:
	var e := InputEventKey.new(); e.keycode = k; e.physical_keycode = k; e.pressed = down
	Input.parse_input_event(e)

func _phase(name: String) -> void:
	if ph != "" and ph_frames > 0:
		_say("frames %s: %d frames, mean %.1f ms, worst %.0f ms, over 33 ms %d, over 50 ms %d" % [ph, ph_frames, ph_sum / ph_frames, ph_worst, ph_over33, ph_over50])
	ph = name; ph_frames = 0; ph_over33 = 0; ph_over50 = 0; ph_worst = 0.0; ph_sum = 0.0

func _people() -> void:
	far_most = maxi(far_most, int((crowd.call(&"stats") as Dictionary).get("drawn", 0))) if crowd else far_most
	var old := 0
	var scene := get_tree().current_scene
	for p in scene.find_children("*", "CityPed", true, false):
		var n := p as Node3D
		if not n.is_visible_in_tree(): continue
		for m in n.find_children("*", "MeshInstance3D", true, false):
			if (m as Node3D).is_visible_in_tree():
				old += 1
				if old_where == "": old_where = "%s %.0f m from him" % [str(n.name), n.global_position.distance_to(pl.global_position)]
				break
	old_most = maxi(old_most, old)
	var nb := 0
	for b in scene.find_children("*", "TravBody", true, false):
		if (b as Node3D).is_visible_in_tree() and b != body: nb += 1
	new_most = maxi(new_most, nb)

func _drawn() -> void:      # just before the frame is drawn: his body against the car, as seen
	if car == null or body == null or not body.visible: return
	drive_frames += 1
	var d := body.global_position.distance_to(car.global_position)
	drive_worst = maxf(drive_worst, d)
	if d > 2.0: drive_out += 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_say("start: to the game's menu, New game")

func _process(delta: float) -> void:
	t += delta
	if ph != "":
		var ms := delta * 1000.0
		ph_frames += 1; ph_sum += ms; ph_worst = maxf(ph_worst, ms)
		if ms > 33.4: ph_over33 += 1
		if ms > 50.0: ph_over50 += 1
	match step:
		0:
			game = get_tree().root.find_child("Game", true, false)
			if game == null or t < 3.0: return
			game.call(&"press", "menu.new_game"); step = 1; t0 = t
		1:
			if (game.call(&"get_start_info") as Dictionary).is_empty() and t - t0 < 240.0: return
			var scene := get_tree().current_scene
			for c in scene.get_children():
				if c.get_class() == "CityPlayer": pl = c
			for n in scene.find_children("*", "CityStream", true, false): st = n
			for n in scene.find_children("*", "CityCrowd", true, false): crowd = n
			for n in scene.find_children("*", "CityTraffic", true, false): trf = n
			car = scene.get_node_or_null(^"StartCar")
			_check(pl != null and car != null and st != null, "the new game: player, start car, streamer (%.0f s from New game)" % (t - t0))
			if pl == null or car == null or st == null: _end(); return
			body = pl.call(&"get_traversal_body") if pl.has_method(&"get_traversal_body") else null
			_check(body != null, "he is the new character (traversal body)")
			_phase("settle"); step = 2; t0 = t
		2:
			if t - t0 < 8.0: return
			_phase("walk"); _key(KEY_W, true); step = 3; t0 = t
		3:
			if t >= next_sample: _people(); next_sample = t + 0.5
			if t - t0 < 25.0: return
			_key(KEY_W, false)
			_check(old_most == 0, "no old figure seen while walking (most %d at once%s)" % [old_most, (", first: " + old_where) if old_where != "" else ""])
			_check(far_most == 0, "the far crowd draws nobody (most %d)" % far_most)
			_check(new_most > 0, "new people seen near him (most %d at once)" % new_most)
			_phase("to_car"); step = 4; t0 = t
		4:
			if t - t0 < 2.0: return
			# (the car may be far behind after the walk: he walks back to it, as a player would)
			_check(bool(car.call(&"enter", pl)), "he goes to get into the start car (%.0f m away)" % car.global_position.distance_to(pl.global_position)); step = 5; t0 = t
		5:
			if not bool(car.call(&"is_seated")) and t - t0 < 40.0: return
			_check(bool(car.call(&"is_seated")), "seated in the car (%.0f s)" % (t - t0))
			start_pos = car.global_position
			RenderingServer.frame_pre_draw.connect(_drawn)
			_phase("drive"); _key(KEY_W, true); step = 6; t0 = t
		6:
			if st: focus_worst = maxf(focus_worst, (st.call(&"get_focus") as Vector3).distance_to(car.global_position))
			if t - t0 < 20.0: return
			_key(KEY_W, false); _key(KEY_S, true)
			RenderingServer.frame_pre_draw.disconnect(_drawn)
			_check(car.global_position.distance_to(start_pos) > 30.0, "the car drove (%.0f m)" % car.global_position.distance_to(start_pos))
			_check(drive_frames > 0 and drive_out == 0, "his body stayed in the car as drawn: %d of %d frames over 2 m, worst %.1f m" % [drive_out, drive_frames, drive_worst])
			_check(focus_worst < 80.0, "the city streams round the car (focus at most %.0f m from it)" % focus_worst)
			_phase("stop"); step = 7; t0 = t
		7:
			if absf(float((car.call(&"get_state") as Dictionary).get("kmh", 0.0))) > 2.0 and t - t0 < 10.0: return
			_key(KEY_S, false); car.call(&"leave"); step = 8; t0 = t
		8:
			if bool(pl.call(&"is_frozen")) and t - t0 < 20.0: return
			_check(not bool(pl.call(&"is_frozen")), "out of the car, on foot")
			_phase("hijack"); step = 9; t0 = t
		9:      # a traffic car near him, taken twice in a row: the second take must give nothing
			if trf == null: _say("no traffic: hijack not tried"); _end(); return
			var id := int(trf.call(&"car_to_take", pl.global_position, 60.0, 40.0))
			if id < 0:
				if t - t0 < 30.0: return
				_say("no traffic car within 60 m in 30 s: hijack not tried"); _end(); return
			var a: Object = trf.call(&"take_car", id, false)
			var b: Object = trf.call(&"take_car", id, false)
			_check(a != null, "a traffic car is taken (row %d)" % id)
			_check(b == null, "taking the same car again gives nothing (one car per hijack)")
			_end(); return

func _end() -> void:
	_phase("")
	_say("RESULT %s (%d failed)" % ["PASS" if fails == 0 else "FAIL", fails])
	print("RIG plan_done")
	step = 99
	get_tree().quit()
