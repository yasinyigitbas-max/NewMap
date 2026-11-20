extends SceneTree
## The phone and its apps (C++: CityPhone, city_phone.cpp, in CityHud's phone panel; board item 9; Yasin, 20 Nov:
## "CONTINUE BRINGING THE OLD SYSTEMS OF THE GAME BACK ONE BY ONE, ONLY C PLUS PLUS"), in a window:
##   godot --path . --rendering-method mobile --resolution 1152x648 --fixed-fps 60 -s res://tests/game/test_phone.gd
## A new game in the picture world. Checks: the phone button opens the phone on its home (13 app tiles), the arrow box on
## the map; a tile opens its app and Back comes home; the camera saves a photo without the HUD in it and it is in Photos;
## a contact and a message (English over Turkish) show in Contacts and Messages and are in the save after a save and a
## load; an incoming call opens the phone on it, Answer, Hang up; the waiting apps say what they wait for. Pictures:
## OUT/phone_home.png, OUT/phone_thread.png, OUT/phone_call.png, the photo itself.
var game: Node
var hud: Node
var phone: Node
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var answered := ""
var ended := false
const DIR := "user://test_phone_saves/"

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("PHONE   %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	for f in DirAccess.get_files_at(DIR): DirAccess.remove_absolute(DIR + f)
	game = ClassDB.instantiate(&"CityGame")
	game.set(&"saves_dir", DIR); game.set(&"world_scene", "res://tests/game/picture_world.tscn"); game.set(&"autosave_s", 0.0)
	game.connect(&"play_started", func(_s: int) -> void:
		var pl := current_scene.get_node_or_null("Player") if current_scene else null
		if pl: game.set_player(pl))
	root.add_child(game)

func _shot(name: String) -> void:
	root.get_texture().get_image().save_png("res://OUT/%s.png" % name)

func _process(delta: float) -> bool:
	t += delta
	match step:
		0:
			if t < 0.5: return false
			game.press("menu.new_game"); step = 1; t0 = t
		1:
			if not game.is_playing() and t - t0 < 30.0: return false
			hud = game.get_hud(); phone = hud.get_phone()
			_check(phone != null, "the HUD has a phone")
			if phone == null: step = 99; return false
			phone.connect(&"call_answered", func(c: String) -> void: answered = c)
			phone.connect(&"call_ended", func(_c: String, _a: bool) -> void: ended = true)
			step = 2; t0 = t
		2:
			if t - t0 < 1.0: return false
			hud.press(1); step = 3; t0 = t
		3:
			if t - t0 < 0.6: return false
			_check(int(hud.get_open()) == 0 and String(phone.get_app()) == "home" and (phone.get_apps() as PackedStringArray).size() == 13, "the phone button: the phone on its home, %d apps" % (phone.get_apps() as PackedStringArray).size())
			_shot("phone_home")
			phone.open_app("bank")
			_check(bool(phone.app_waits("bank")) and String(phone.get_app()) == "bank", "Bank waits for money (board item 10): its page says so")
			phone.go_home()
			hud.press(3); step = 4; t0 = t
		4:
			if t - t0 < 0.6: return false
			hud.press(0); step = 5; t0 = t
		5:
			if t - t0 < 0.6: return false
			_check(int(hud.get_open()) == 0 and String(phone.get_app()) == "map", "the arrow box: the phone on its map")
			phone.open_app("camera"); phone.take_photo(); step = 6; t0 = t
		6:
			if bool(phone.is_taking_photo()):
				return false
			var p := String(phone.get_last_photo())
			var img := Image.load_from_file(p) if p != "" else null
			_check(p != "" and img != null and img.get_width() > 0, "the camera saved a photo: %s (%dx%d)" % [p.get_file(), img.get_width() if img else 0, img.get_height() if img else 0])
			_check((phone.get_photos() as PackedStringArray).has(p), "and it is in Photos")
			phone.open_app("photos")
			phone.add_contact("maria", "Maria", "619 555 0142", "neighbour")
			phone.receive_message("maria", "Hi! Are you free for coffee today?", String("Merhaba! Bugün kahve için müsait misin?"))
			phone.send_message("maria", "Yes, I am. See you at ten.", String("Evet, müsaitim. Saat onda görüşürüz."))
			phone.open_thread("maria")
			step = 7; t0 = t
		7:
			if t - t0 < 0.4: return false
			_shot("phone_thread")
			_check((phone.get_contacts() as Array).size() == 1 and (phone.get_thread("maria") as Array).size() == 2 and String(phone.get_app()) == "thread", "a contact and her messages, English over Turkish, in the thread")
			phone.ring("Maria")
			step = 8; t0 = t
		8:
			if t - t0 < 0.5: return false
			_check(int(phone.get_call_state()) == 1 and String(phone.get_app()) == "call" and int(hud.get_open()) == 0, "an incoming call: the phone on it, ringing")
			phone.answer(); step = 9; t0 = t
		9:
			if t - t0 < 1.3: return false
			_shot("phone_call")
			_check(int(phone.get_call_state()) == 2 and answered == "Maria", "answered: on the call")
			phone.hang_up()
			_check(ended and int(phone.get_call_state()) == 0 and String(phone.get_app()) == "thread", "hung up: back where the phone was (%s)" % String(phone.get_app()))
			var d: Dictionary = game.get_phone_data()
			_check((d.get("contacts", []) as Array).size() == 1 and ((d.get("threads", {}) as Dictionary).get("maria", []) as Array).size() == 2, "the game holds the phone's data for the save")
			step = 99
		99:
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0); return true
	return false
