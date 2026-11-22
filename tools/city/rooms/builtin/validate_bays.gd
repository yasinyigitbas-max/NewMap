extends SceneTree
## Built-in interiors rollout validator: every bay of interiors/builtin/bays.json for every kind it furnishes, over
## every template x mirror x decor set (BuiltinLib.validate_bay), + the composed near (one surface) and its tri count.
## Exit 1 on any problem. Writes interiors/builtin/validate_bays.json (per bay: problems, near tris).
##   godot --headless --path . -s res://tools/city/rooms/builtin/validate_bays.gd -- [--models=a,b] [--negative]
## --negative: also proves it fails (an unknown kind on a bay, a model with no bay scene, the old 17-barber-chair room
## over its repeat caps): exit 1 if it does not.
const BL := preload("res://tools/city/rooms/builtin/builtin_lib.gd")
const IB := "res://map_dc/coronado/city_kit/interiors/builtin/"
func _init() -> void: _go.call_deferred()
func _go() -> void:
	var bays: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(IB + "bays.json")).models
	var contracts: Dictionary = BL.all_contracts()
	var only: Array = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--models="): only = a.trim_prefix("--models=").split(",")
	var out := {}; var nprob := 0; var nb := 0
	for model: String in bays:
		var t0 := Time.get_ticks_msec()
		if not only.is_empty() and not only.has(model): continue
		var used: Array = []
		for b: Dictionary in bays[model].bays:
			nb += 1
			var probs := BL.validate_bay(model, int(b.i), b.kinds, contracts.get(model, {}))
			used.append(int(b.i))
			out["%s|%d" % [model, int(b.i)]] = {"problems": probs, "kinds": b.kinds}
			nprob += probs.size()
			for p: String in probs: print("PROB ", p)
		if not BL.has_bays(model): continue
		var m := BL.compose_near(model, used)
		if m.get_surface_count() != 1: nprob += 1; print("PROB %s: composed near has %d surfaces" % [model, m.get_surface_count()])
		out[model + "|near"] = {"ext_tris": m.get_meta(&"ext_tris"), "all_bays_tris": m.get_meta(&"tris")}
		print("TIME %s %d ms" % [model, Time.get_ticks_msec() - t0])
	if OS.get_cmdline_user_args().has("--negative"):      # (22 Nov: was validate_builtin.gd --negative, now retired)
		var m1: String = bays.keys()[0]
		var n1 := BL.validate_bay(m1, int(bays[m1].bays[0].i), ["florist_nonexistent"], contracts.get(m1, {}))
		var bare := ""
		for cm: String in contracts:
			if not bays.has(cm) and not BL.has_bays(cm): bare = cm; break
		var n2 := BL.validate_bay(bare, 0, ["cafe"], contracts.get(bare, {})) if bare != "" else []
		print("NEGATIVE unknown kind on %s -> %d problems: %s" % [m1, n1.size(), str(n1.slice(0, 3))])
		print("NEGATIVE no interior (%s) -> %d problems: %s" % [bare, n2.size(), str(n2)])
		# the barber room laid out before the repeat caps (17 barber chairs): the repeat-cap rule must report it
		var fx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/city/rooms/builtin/fixtures/old_barber_twr_office_B.json"))
		var hold := Node3D.new()
		for q: Array in fx.slots:
			var mk := Marker3D.new(); mk.name = String(q[0]); mk.position = Vector3(float(q[3]), 0, float(q[4]))
			mk.set_meta(&"slot_type", String(q[1])); mk.set_meta(&"variant", int(q[2])); hold.add_child(mk)
		var n3 := BL.repeat_problems("old %s barber/B" % fx.model, String(fx.kind), hold, BL.sets().get(String(fx.kind), {}))
		hold.free()
		print("NEGATIVE old barber room (17 chairs) -> %d problems: %s" % [n3.size(), str(n3)])
		if n1.is_empty() or n2.is_empty() or n3.is_empty(): print("NEGATIVE FAIL: the validator let a bad model through"); nprob += 1
	DirAccess.remove_absolute(IB + "validate_bays.json")      # (delete, then write: the checkouts share files by hard link)
	var f := FileAccess.open(IB + "validate_bays.json", FileAccess.WRITE); f.store_string(JSON.stringify(out, " ")); f.close()
	print("VALIDATE_BAYS %d bays, %d problems" % [nb, nprob])
	quit(1 if nprob > 0 else 0)
