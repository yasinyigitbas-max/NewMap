extends SceneTree
## Talking to the people (C++ class CityTalk with CityCrowd and CityPlayer), headless:
##   godot --headless --fixed-fps 60 --path . -s res://tests/people/test_talk.gd
## The real streets, places and talk data over a flat floor. It goes through a whole talk the way a player would: the
## Talk target, the greeting, three lines, saying a line wrong and right, the answers (a place, the clock, a mission),
## goodbye, "Hi again", three misses, a refusal and the grudge, walking away, a group's own conversation, the voices.
## This script only sets things up, presses what a player would press, and reads the results.
var crowd: Node3D
var player: Node3D
var talk: Node
var t := 0.0
var step := 0
var t0 := 0.0
var fails := 0
var who := -1
var who2 := -1
var spot := Vector3.ZERO
var outcomes: Array = []
var lines: Array = []

func _initialize() -> void:
	for c: StringName in [&"CityCrowd", &"CityPlayer", &"CityTalk"]:
		if not ClassDB.class_exists(c):
			print("TALK ERROR the native module is not built: run  bash native/build.sh"); print("RESULT FAIL"); quit(1); return
	crowd = ClassDB.instantiate(&"CityCrowd")
	crowd.set(&"max_people", 300); crowd.set(&"hour", 14.25)
	root.add_child(crowd)
	var cam := Camera3D.new(); cam.position = Vector3(0, 40, -620); cam.rotation_degrees = Vector3(-90, 0, 0); root.add_child(cam); cam.current = true

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("TALK   %s: %s" % ["ok" if ok else "FAIL", what])

func _person(id: int) -> Dictionary:
	for p: Dictionary in crowd.call(&"people_near", spot, 400.0):
		if int(p.id) == id: return p
	return {}

func _st() -> Dictionary: return talk.call(&"stats")
func _opts() -> Array: return talk.call(&"get_options")
func _kind(k: String) -> int:
	var o := _opts()
	for i in o.size():
		if String(o[i].kind) == k or String(o[i].id) == k: return i
	return -1
func _show() -> String:
	var s := PackedStringArray()
	for o: Dictionary in _opts(): s.append("[%s] %s" % [o.kind, o.en])
	return " | ".join(s)

func _physics_process(delta: float) -> bool:
	if crowd == null: return true
	t += delta
	match step:
		0:      # the crowd fills; a floor, the player, somebody who stands, the talk
			if t < 6.0: return false
			var ppl: Array = crowd.call(&"people_near", Vector3(0, 0, -620), 200.0)
			for p: Dictionary in ppl:
				if int(p.mode) == 0 and int(p.state) == 0 and int(p.party) == 0: spot = p.at; break
			if spot == Vector3.ZERO: _check(false, "nobody on a pavement within 200 m of the centre"); step = 99; return false
			var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
			sh.size = Vector3(800, 2, 800); cs.shape = sh; fl.add_child(cs); fl.position = Vector3(spot.x, spot.y - 1.0, spot.z); root.add_child(fl)
			who = int(crowd.call(&"place_walker", spot, 4242)); crowd.call(&"stay", who, 600.0)
			player = ClassDB.instantiate(&"CityPlayer")
			root.add_child(player)
			crowd.call(&"set_player", player)
			talk = ClassDB.instantiate(&"CityTalk")
			root.add_child(talk)
			talk.call(&"set_crowd", crowd); talk.call(&"set_player", player)
			talk.connect(&"ended", func(_id: int, o: String) -> void: outcomes.append(o))
			talk.connect(&"npc_line", func(en: String, _tr: String) -> void: lines.append(en))
			step = 1; t0 = t
		1:
			if t - t0 < 0.5: return false
			var p := _person(who)
			player.global_position = (p.at as Vector3) + Vector3(1.4, 0.05, 0)
			step = 2; t0 = t
		2:      # the Talk target, the greeting, three lines
			if t - t0 < 0.5: return false
			_check(int(_st().target) == who, "somebody within 2 m is the one the Talk button speaks to (walker %d, target %d)" % [who, int(_st().target)])
			talk.call(&"set_force", 0.0, 1.0, 1.0, 1.0, "T5")      # he agrees, never cuts it short, never refuses, always knows
			var r: String = talk.call(&"talk_to_nearest")
			var p := _person(who)
			_check(r == "talk" and int(talk.call(&"get_active")) == who, "he agrees to talk (%s) and greets: \"%s\"" % [r, lines.back() if lines.size() else ""])
			var want: float = atan2(player.global_position.x - (p.at as Vector3).x, player.global_position.z - (p.at as Vector3).z)
			_check(_opts().size() == 3 and _kind("place") == 0 and _kind("hint") == 1 and _kind("topic") == 2, "three lines to choose from: %s" % _show())
			step = 3; t0 = t
		3:      # he has turned to the player; a line said wrong, then right: the answer names the place and the way
			if t - t0 < 1.0: return false
			var p := _person(who)
			var want: float = atan2(player.global_position.x - (p.at as Vector3).x, player.global_position.z - (p.at as Vector3).z)
			_check(absf(angle_difference(float(p.yaw), want)) < 0.5, "he stands turned to the player (%.0f degrees off)" % rad_to_deg(absf(angle_difference(float(p.yaw), want))))
			var line: String = _opts()[0].en
			talk.call(&"choose", 0)
			_check(bool(_st().saying), "a line is tapped: it must be said (\"%s\")" % line)
			talk.call(&"say_typed", "banana sandwich")
			_check(bool(_st().saying) and int(_st().tries) == 1, "said wrong once: still to be said, 2 tries left")
			talk.call(&"say_typed", line.to_upper().replace("?", " ").replace("'", "’"))
			_check(not bool(_st().saying) and lines.back().begins_with("Yes"), "said right (capitals, no question mark): he answers \"%s\"" % lines.back())
			_check(_opts().size() == 4 and _kind("T7") == 3, "the next lines, with a goodbye: %s" % _show())
			step = 4
		4:      # the clock (skipped instead of said), then a mission
			talk.call(&"choose", _kind("T5")); talk.call(&"say_typed", "")
			_check(lines.back() == "It's quarter past 2.", "what time is it (the crowd's hour is 14:15), the line skipped: \"%s\"" % lines.back())
			talk.call(&"set_mission", "Buy a coffee.", "Bir kahve al.", player.global_position + Vector3(0, 0, -320))
			talk.call(&"set_force", 0.0, 1.0, 1.0, 1.0, "T6")
			talk.call(&"choose", _kind("hint")); talk.call(&"say_typed", "")
			var hint_line: String = lines.back()
			var mi := _kind("mission")
			_check(mi >= 0 and String(_opts()[mi].en) == "I need to buy a coffee. Can you help me?", "a hint answered (\"%s\"); now the mission is one of the lines: %s" % [hint_line, _show()])
			talk.call(&"choose", mi); talk.call(&"say_typed", "can you help me")
			_check(lines.back().begins_with("Sure! Go ") and lines.back().contains("4 minutes"), "the mission 320 m away: \"%s\"" % lines.back())
			talk.call(&"choose", _kind("T6")); talk.call(&"say_typed", "what are you doing")
			_check(lines.back().begins_with("I'm "), "what are you doing: \"%s\"" % lines.back())
			talk.call(&"choose", _kind("T7")); talk.call(&"say_typed", "Bye!")
			_check(outcomes.back() == "bye" and not bool(talk.call(&"is_active")), "goodbye: \"%s\", the talk is over (%s)" % [lines.back(), outcomes.back()])
			step = 5; t0 = t
		5:      # he remembers; three misses; then the grudge
			if t - t0 < 0.5: return false
			var r: String = talk.call(&"begin", who)
			_check(r == "hi_again" and lines.back() == "Hi again!", "spoken to again at once: \"%s\"" % lines.back())
			talk.call(&"choose", 0)
			for i in 3: talk.call(&"say_typed", "purple monkey")
			_check(outcomes.back() == "missed" and lines.back().begins_with("Sorry, I don't understand"), "three misses: \"%s\" (%s)" % [lines.back(), outcomes.back()])
			# somebody else who refuses bears a grudge
			who2 = int(crowd.call(&"place_walker", spot + Vector3(0, 0, 3.0), 9191)); crowd.call(&"stay", who2, 600.0)
			talk.call(&"set_force", 0.99, 1.0, 1.0, 1.0, "")
			var r1: String = talk.call(&"begin", who2); var l1: String = lines.back()
			talk.call(&"set_force", 0.0, 1.0, 1.0, 1.0, "")
			var r2: String = talk.call(&"begin", who2)
			_check(r1 == "reject" and r2 == "busy", "a refusal (\"%s\"), and asked again he will not (\"%s\")" % [l1, lines.back()])
			talk.call(&"set_memory", {})
			var r3: String = talk.call(&"begin", who2)
			_check(r3 == "talk", "with nothing remembered he talks (%s)" % r3)
			player.global_position += Vector3(9.0, 0, 0)
			step = 6; t0 = t
		6:      # walking away ends it; a group's own conversation gets its words
			if t - t0 < 0.5: return false
			_check(outcomes.back() == "walked" and not bool(talk.call(&"is_active")), "the player walks 9 m away: \"%s\" (%s)" % [lines.back(), outcomes.back()])
			var p2 := _person(who2)
			_check(not p2.is_empty() and int(p2.mode) != 6, "and the one he left is let go (mode %d)" % int(p2.get("mode", -1)))
			var g0 := int(_st().group_lines)
			for p: Dictionary in crowd.call(&"people_near", spot, 400.0):
				if int(p.party) != 0:
					talk.call(&"_on_crowd_event", 11, int(p.id), (2 * 16 + 1) * 64 + 0, 0.0)
					talk.call(&"_on_crowd_event", 11, int(p.id), (2 * 16 + 1) * 64 + 1, 0.0)
					break
			var s := _st()
			_check(int(s.group_lines) == g0 + 2, "a group's conversation gets its words (%d lines)" % (int(s.group_lines) - g0))
			# (directions and times are captions only: their recordings were dropped, Yasin 20 Nov; the rest is voiced)
			_check(int(s.voiced) >= 8 and int(s.silent) <= 5 and int(s.remembered) >= 1, "%d lines spoken with a recorded voice, %d as a caption only (directions / times); %d talks, %d people remember him" % [int(s.voiced), int(s.silent), int(s.talks), int(s.remembered)])
			# THE CAST: each person one of eight voices, the same every time; the street's shouts in that voice
			var v1 := String(talk.call(&"get_voice_of", who))
			_check(v1.length() == 2 and "mf".contains(v1[0]) and "1234".contains(v1[1]) and v1 == String(talk.call(&"get_voice_of", who)), "he speaks with one voice of the cast (%s)" % v1)
			var voices := {}
			for p: Dictionary in crowd.call(&"people_near", spot, 400.0): voices[String(talk.call(&"get_voice_of", int(p.id)))] = true
			_check(voices.size() >= 5, "the people near by speak with %d different voices" % voices.size())
			var b0 := int(_st().get("barks", 0))
			var shouted := bool(talk.call(&"test_bark", who, "scared")) and bool(talk.call(&"test_bark", who, "greet"))
			_check(shouted and int(_st().barks) == b0 + 2, "he shouts in his voice (a scared one and a greeting: %d)" % (int(_st().barks) - b0))
			print("TALK every line he heard: %s" % " / ".join(PackedStringArray(lines)))
			step = 99
		99:
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
