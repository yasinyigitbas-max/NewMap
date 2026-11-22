extends SceneTree
## Built-in interiors rollout validator: every bay of interiors/builtin/bays.json for every kind it furnishes, over
## every template x mirror x decor set (BuiltinLib.validate_bay), + the composed near (one surface) and its tri count.
## Exit 1 on any problem. Writes interiors/builtin/validate_bays.json (per bay: problems, near tris).
##   godot --headless --path . -s res://tools/city/rooms/builtin/validate_bays.gd -- [--models=a,b]
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
		if model == "commercial/com_bank":
			var pp := BL.validate(model, ["bank"], contracts.get(model, {}))
			out[model] = {"problems": pp}; nprob += pp.size()
			for p0: String in pp: print("PROB ", p0)
			continue
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
	var f := FileAccess.open(IB + "validate_bays.json", FileAccess.WRITE); f.store_string(JSON.stringify(out, " ")); f.close()
	print("VALIDATE_BAYS %d bays, %d problems" % [nb, nprob])
	quit(1 if nprob > 0 else 0)
