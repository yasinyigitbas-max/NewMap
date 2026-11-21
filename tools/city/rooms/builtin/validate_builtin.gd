## Built-in interiors validator (22 Nov 2026 pilot). Every kit model with a <model>_interior.scn, for every shop kind the
## assignments give it (interiors/assignment_*.json), must pass BuiltinLib.validate: interior shell (floor, ceiling, four
## walls), slot markers inside the floor with a furniture set for each kind (no fallback), door leaves covering every
## entrance, a pane in every cut window, <= 12 collision boxes, none across the entrance. Exit 1 on any problem.
##   godot --headless --path . -s res://tools/city/rooms/builtin/validate_builtin.gd [-- --negative]
## --negative: also proves the validator fails (a kind with no set, a model with no interior) - exit 1 if it does not.
extends SceneTree
const BL := preload("res://tools/city/rooms/builtin/builtin_lib.gd")
const DIR := "res://map_dc/coronado/city_kit/interiors/"

func _init() -> void:
	var kinds := {}      # model -> [kinds]
	for f in DirAccess.get_files_at(DIR):
		if not (f.begins_with("assignment_") and f.ends_with(".json")): continue
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIR + f))
		var rows: Array = (d as Dictionary).get("rooms", []) if d is Dictionary else (d if d is Array else [])
		for r: Variant in rows:
			if not (r is Dictionary) or String(r.get("model", "")) == "" or String(r.get("kind", "")) == "": continue
			var m := String(r.model)
			if not BL.has_builtin(m): continue
			if not kinds.has(m): kinds[m] = []
			if not (kinds[m] as Array).has(String(r.kind)): (kinds[m] as Array).append(String(r.kind))
	var contracts := {}
	for f in DirAccess.get_files_at(DIR):
		if f.begins_with("room_contracts") and f.ends_with(".json"):
			var c: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIR + f))
			if c is Dictionary: contracts.merge((c as Dictionary).get("models", {}), false)
	var bad := 0
	for m: String in kinds:
		var p := BL.validate(m, kinds[m], contracts.get(m, {}))
		print("BUILTIN %s kinds=%s: %s" % [m, str(kinds[m]), "PASS" if p.is_empty() else "FAIL"])
		for q: String in p: print("  ", q)
		bad += p.size()
	if OS.get_cmdline_user_args().has("--negative"):
		var n1 := BL.validate("commercial/com_bank", ["florist_nonexistent"], contracts.get("commercial/com_bank", {}))
		var n2 := BL.validate("commercial/com_cafe_seaside", ["cafe"], contracts.get("commercial/com_cafe_seaside", {}))
		print("NEGATIVE unknown kind -> %d problems: %s" % [n1.size(), str(n1)])
		print("NEGATIVE no interior -> %d problems: %s" % [n2.size(), str(n2)])
		# a desk turned round (screen and keyboard away from its chair) must fail the facing rules
		var it: Node3D = (load(BL.interior_path("commercial/com_bank")) as PackedScene).instantiate()
		(it.get_node(^"Slots/desk_1") as Node3D).rotation.y += PI
		var n3 := BL.facing_problems("commercial/com_bank", it.get_node(^"Slots"), (it.get_meta(&"floors") as Array)[0], "bank")
		it.free()
		print("NEGATIVE desk turned round -> %d problems: %s" % [n3.size(), str(n3)])
		if n1.is_empty() or n2.is_empty() or n3.is_empty(): print("NEGATIVE FAIL: the validator let a bad model through"); bad += 1
	print("BUILTIN_RESULT %s (%d models, %d problems)" % ["PASS" if bad == 0 else "FAIL", kinds.size(), bad])
	quit(1 if bad > 0 else 0)
