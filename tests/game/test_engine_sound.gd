extends SceneTree
## Recorded engine loops (21 Nov): the files load, the class mapping matches engine_start, idle/low/high equal-power
## blends by rpm, and a sharp throttle-on counts as a rev-up blip.
##   godot --headless --fixed-fps 60 --path . -s res://tests/game/test_engine_sound.gd
var fails := 0
var es: Node3D
var step := 0

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("ENGINE  %s: %s" % ["ok" if ok else "FAIL", what])

func _end() -> bool:
	print("RESULT %s" % ("PASS" if fails == 0 else "FAIL"))
	quit(1 if fails else 0)
	return true

func _initialize() -> void:
	_check(ClassDB.class_exists("EngineSound") and ClassDB.can_instantiate("EngineSound"), "EngineSound is a native class")
	_check(ClassDB.class_exists("CityCar"), "CityCar is a native class")
	var classes := ["compact", "v6", "v8", "diesel", "ev"]
	for cls in classes:
		for layer in ["engine_idle_", "engine_rev_low_", "engine_rev_high_", "engine_rev_up_"]:
			var n := 0
			for i in 8:
				var path := "res://audio/sfx/car/%s%s_%d.ogg" % [layer, cls, i]
				if FileAccess.file_exists(path):
					n += 1
				else:
					break
			_check(n >= 2, "%s%s has %d takes" % [layer, cls, n])
	# mapping: sakura compact, taxi/stern_g v6, fiamma v8, van/sakura_t/bus diesel, volt/stern_e ev
	var car: Object = ClassDB.instantiate(&"CityCar")
	var map := {5: "compact", 2: "v6", 9: "v6", 7: "v8", 8: "v8", 6: "diesel", 4: "diesel", 1: "ev", 3: "ev", 0: "ev"}
	if car and car.has_method("engine_class_for"):
		for m in map:
			var got: String = str(car.call("engine_class_for", m))
			_check(got == map[m], "engine_class_for(%d) = %s (want %s)" % [m, got, map[m]])
	else:
		_check(false, "CityCar.engine_class_for is bound")
	if car is Node: (car as Node).free()

	es = ClassDB.instantiate(&"EngineSound")
	root.add_child(es)
	var idle: PackedFloat32Array = es.call("blend_gains", 800.0, 0.0)
	var mid: PackedFloat32Array = es.call("blend_gains", 3000.0, 0.0)
	var high: PackedFloat32Array = es.call("blend_gains", 6500.0, 1.0)
	_check(idle.size() == 3 and idle[0] > 0.9 and idle[0] > idle[1] and idle[0] > idle[2], "idle (800 rpm) is the idle layer (gains %s)" % str(idle))
	_check(mid.size() == 3 and mid[1] > mid[0] and mid[1] > mid[2], "cruise (3000 rpm) is the low layer (gains %s)" % str(mid))
	_check(high.size() == 3 and high[2] > 0.9 and high[2] > high[1] and high[2] > high[0], "redline is the high layer (gains %s)" % str(high))
	var edge: PackedFloat32Array = es.call("blend_gains", 800.0 + 0.30 * (6500.0 - 800.0), 0.0)
	var pwr := edge[0] * edge[0] + edge[1] * edge[1] + edge[2] * edge[2]
	_check(abs(pwr - 1.0) < 0.05, "equal-power at the idle/low split (sum of squares %.3f)" % pwr)

func _process(_delta: float) -> bool:
	# playback needs the node inside the tree (elsfx::loop no-ops otherwise)
	if step == 0:
		es.call("set_sample_class", "compact")
		es.call("debug_drive", 800.0, 0.0, 1.0)
		_check(bool(es.call("is_using_samples")), "compact loops loaded (class %s)" % str(es.call("get_sample_class")))
		var g: PackedFloat32Array = es.call("get_layer_gains")
		_check(g.size() == 3 and g[0] > g[1] and g[0] > g[2], "debug_drive at idle: idle layer up (gains %s)" % str(g))
		_check(int(es.call("get_layer_voices")) >= 1, "at least one loop voice at idle (%d)" % int(es.call("get_layer_voices")))
		var idle_n: Node = es.get_node_or_null("EngIdle")
		_check(idle_n != null and idle_n is AudioStreamPlayer3D and (idle_n as AudioStreamPlayer3D).playing, "EngIdle is playing")
		if idle_n is AudioStreamPlayer3D:
			_check((idle_n as AudioStreamPlayer3D).attenuation_model == AudioStreamPlayer3D.ATTENUATION_DISABLED, "player layers have no distance fall-off")
			var bus := (idle_n as AudioStreamPlayer3D).bus
			_check(bus == "SFX" or bus == "Master", "loop is on the SFX bus (or Master if SFX is missing): %s" % bus)

		es.call("debug_drive", 3000.0, 0.0, 1.0)
		g = es.call("get_layer_gains")
		_check(g[1] > g[0] and g[1] > g[2], "debug_drive at 3000 rpm: low layer up (gains %s)" % str(g))
		_check(es.get_node_or_null("EngLow") != null, "EngLow node exists at cruise")
		es.call("debug_drive", 6500.0, 1.0, 1.0)
		g = es.call("get_layer_gains")
		_check(g[2] > g[0] and g[2] > g[1], "debug_drive at redline: high layer up (gains %s)" % str(g))

		# expire the redline blip's cooldown, then a sharp throttle-on
		es.call("debug_drive", 2000.0, 0.0, 2.0)
		var b0: int = int(es.call("get_blip_count"))
		es.call("debug_drive", 2000.0, 0.8, 0.05)
		_check(int(es.call("get_blip_count")) == b0 + 1, "sharp throttle-on plays engine_rev_up (blips %d -> %d)" % [b0, int(es.call("get_blip_count"))])
		return _end()
	return false
