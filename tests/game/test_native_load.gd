extends SceneTree
## The native module loads and its classes can be made (20 Nov: a Godot type built as a C++ static made the library
## fail at load, Windows error 1114, and would have left the phone with no traffic, people, player or menu).
##   godot --headless --path . -s res://tests/game/test_native_load.gd
func _initialize() -> void:
	var fails := 0
	for c in ["CityGame", "CityCrowd", "CityTraffic", "CityPlayer", "CityCar", "CityTalk", "FootSteps", "CityAmbience", "EngineSound"]:
		var ok := ClassDB.class_exists(c) and ClassDB.can_instantiate(c)
		var o: Object = ClassDB.instantiate(c) if ok else null
		if o == null: fails += 1
		print("NATIVE %s: %s" % [c, "ok" if o else "FAIL"])
		if o is Node: (o as Node).free()
		elif o and not (o is RefCounted): o.free()
	var k: int = ClassDB.class_call_static(&"FootSteps", &"class_at", 0.0, 0.0) if ClassDB.class_exists("FootSteps") else -1
	print("NATIVE FootSteps.class_at(0, 0) = %d" % k)
	print("RESULT %s" % ("PASS" if fails == 0 else "FAIL"))
	quit(1 if fails else 0)
