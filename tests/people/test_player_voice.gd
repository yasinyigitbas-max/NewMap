extends SceneTree
## The player's voice and sounds (Yasin, 20 Nov: "make sure players sounds have variety, same grunt shouldnt play
## everytime ... at least 4 varieties"; "record player sounds in two genders"; "make it c plus plus"):
##   godot --headless --path . -s res://tests/people/test_player_voice.gd
## A flat floor and the player (CityPlayer). Checks: every vocal kind has 4+ takes for both genders and never plays the
## same take twice running; the set follows his body's gender; a jump, a drop from 3 m (hard landing) and a punch are
## voiced by the C++ hooks; the landing takes of the ground play.
var player: CharacterBody3D
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var c0 := 0
const KINDS := ["jump", "climb", "land", "hurt", "pain", "death", "breath", "punch", "throw"]

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("VOICE   %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(200, 2, 200); cs.shape = sh; b.add_child(cs)
	b.position = Vector3(0, -1, 0); root.add_child(b)
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0, 0.05, 0); root.add_child(player)

func _voice() -> AudioStreamPlayer3D:
	var v := player.get_node_or_null(^"Voice")
	return v as AudioStreamPlayer3D

func _sets(g: String) -> void:
	player.call(&"set_body_id", "F1" if g == "f" else "M2")
	_check(String(player.call(&"get_vocal_gender")) == g, "the body %s speaks with the %s set" % [player.call(&"get_body_id"), g])
	for k: String in KINDS:
		var n := 0
		while FileAccess.file_exists("res://audio/player/%s/%s_%02d.ogg" % [g, k, n + 1]) or ResourceLoader.exists("res://audio/player/%s/%s_%02d.ogg" % [g, k, n + 1]): n += 1
		var seen := {}; var repeats := 0; var last := ""; var played := 0
		for i in 12:
			if player.call(&"vocal", k):
				played += 1
				var p := _voice().stream.resource_path if _voice().stream.resource_path != "" else str(_voice().stream.get_instance_id())
				if p == last: repeats += 1
				last = p; seen[p] = true
				if i == 0 and p.begins_with("res://"): _check(p.contains("/%s/" % g), "%s %s from the %s set (%s)" % [g, k, g, p.get_file()])
		_check(n >= 4 and played == 12 and repeats == 0 and seen.size() >= min(n, 4), "%s %s: %d takes, 12 played, %d different, %d the same twice running" % [g, k, n, seen.size(), repeats])

func _process(_d: float) -> bool:
	t += _d
	match step:
		0:
			if t < 1.0: return false
			_sets("m"); _sets("f")
			player.call(&"set_body_id", "M2")
			c0 = int(player.call(&"get_vocal_count"))
			step = 1; t0 = t
		1:   # four jumps (each voiced 4 times in 5)
			if fmod(t - t0, 1.2) < _d: player.call(&"jump")
			if t - t0 >= 4.9:
				_check(int(player.call(&"get_vocal_count")) > c0, "jumping: %d jump efforts" % (int(player.call(&"get_vocal_count")) - c0))
				c0 = int(player.call(&"get_vocal_count"))
				player.global_position = Vector3(0, 3.2, 0); player.velocity = Vector3.ZERO
				step = 2; t0 = t
		2:
			if t - t0 >= 2.0:
				_check(int(player.call(&"get_vocal_count")) > c0, "a drop from 3 m: a hard landing voiced (%d)" % (int(player.call(&"get_vocal_count")) - c0))
				c0 = int(player.call(&"get_vocal_count"))
				player.call(&"punch")
				step = 3; t0 = t
		3:
			if t - t0 >= 0.5:
				_check(int(player.call(&"get_vocal_count")) >= c0, "a punch (voiced 85 in 100): %d" % (int(player.call(&"get_vocal_count")) - c0))
				print("RESULT %s (%d failed)" % ["PASS" if fails == 0 else "FAIL", fails])
				quit(1 if fails > 0 else 0); return true
	return false
