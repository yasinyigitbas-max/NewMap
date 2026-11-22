extends SceneTree
## Where the people of a room stand (Yasin, 20 Nov: "add npcs into shops, some customers and a cashier"), tool time:
##   godot --headless --path . -s res://tools/city/rooms/room_people.gd
## Reads every room the interiors sessions made (map_dc/coronado/city_kit/interiors/rooms/*.scn) and writes
## traffic/room_people.json: per room, in the room's (= its building's) own frame,
##   staff   [x, z, yaw]   behind the till or counter, facing the customers
##   queue   [x, z, yaw]   in front of it, facing the staff (where a customer pays: the player too)
##   browse  [[x, z, yaw]] in front of shelves, fridges, racks, facing them (up to 6, spread out)
##   door_in [x, z], door_out [x, z]   just inside and just outside its first entrance
##   seats   [[x, z, yaw]] chairs and waiting benches (a bench: two seats), where a sitter's feet are, facing as the
##           seat faces (chairs face their +Z: the interiors skill), 8 cm forward of the seat's middle as the crowd's benches
## The till's and counter's sides are the kit's (the interiors skill, checked by rendering every prop from four sides):
## the STAFF side is +Z for cash_register, checkout_counter, laundry_counter, espresso_machine; the CUSTOMER side is +Z for
## shop_counter, bar_counter, pastry_case and the shelves. Every spot must lie on the room's floor (meta "floors"), 0.3 m
## from its edge. A room with no till or counter is left out.
const ROOMS := "res://map_dc/coronado/city_kit/interiors/rooms/"
const OUT := "res://map_dc/coronado/city_kit/traffic/room_people.json"      # (beside the crowd's other data: the phone export packs it)
const SERVICE := [["cash_register", 1], ["checkout_counter", 1], ["shop_counter", -1], ["bar_counter", -1], ["laundry_counter", 1], ["pastry_case", -1]]
const SEATS := ["cafe_chair", "side_chair", "waiting_bench", "booth_bench", "shoe_bench", "theatre_seat"]   # (seat height ~0.45 m: no bar stools, no barber chairs)
const BROWSE := ["shelf", "fridge", "freezer", "rack", "spinner", "produce_stand", "display", "case", "cabinet", "ice_chest", "bookcase"]

func _initialize() -> void:
	var out := {}
	var n_rooms := 0
	var n_left := 0
	var why := {}
	# (22 Nov, INDOORS rollout) --builtin=<dir>: also the bake's built-in rooms (<runtime>/rooms/bi_*.scn), named as the
	# bake names them; the hand-made rooms of buildings that now carry their interior are left out (not placed any more)
	var bdir := ""
	for a in OS.get_cmdline_user_args(): if a.begins_with("--builtin="): bdir = a.trim_prefix("--builtin=").trim_suffix("/") + "/"
	var files: Array = []
	for f in DirAccess.get_files_at(ROOMS): files.append(ROOMS + f)
	if bdir != "":
		for f in DirAccess.get_files_at(bdir): if f.begins_with("bi_"): files.append(bdir + f)
	for fp: String in files:
		var f := fp.get_file()
		if not f.ends_with(".scn"): continue
		n_rooms += 1
		var ps: PackedScene = load(fp)
		if ps == null: continue
		var r: Node = ps.instantiate()
		var res := _room(r)
		if res.has("why"):
			n_left += 1; why[res.why] = int(why.get(res.why, 0)) + 1
		else:
			out[f.get_basename()] = res
		r.free()
	var fa := FileAccess.open(OUT, FileAccess.WRITE)
	fa.store_string(JSON.stringify({"rooms": out}, "\t"))
	fa.close()
	print("ROOMPEOPLE %d rooms read, %d with people's places, %d left out %s -> %s" % [n_rooms, out.size(), n_left, str(why), OUT])
	quit()

func _on_floor(floors: Array, x: float, z: float) -> bool:
	for fr in floors:
		if x >= float(fr[0]) + 0.3 and x <= float(fr[2]) - 0.3 and z >= float(fr[1]) + 0.3 and z <= float(fr[3]) - 0.3: return true
	return false

func _instances(props: Node, key: String) -> Array:
	var out := []
	var xf: Dictionary = props.get_parent().get_meta(&"props_xf", {})      # (a built-in room with its props merged, 22 Nov)
	for nm: String in xf:
		if not nm.trim_prefix("prop_").contains(key): continue
		for t: Transform3D in xf[nm]: out.append({"name": nm, "t": t})
	for c in props.get_children():
		if not (c is MultiMeshInstance3D) or c.multimesh == null: continue
		if not String(c.name).trim_prefix("prop_").contains(key): continue
		var mm: MultiMesh = c.multimesh
		for k in mm.instance_count: out.append({"name": String(c.name), "t": c.transform * mm.get_instance_transform(k)})
	return out

func _room(r: Node) -> Dictionary:
	var floors: Array = r.get_meta("floors", [])
	var ents: Array = r.get_meta("entrances", [])
	var props: Node = r.get_node_or_null("Props")
	if floors.is_empty() or props == null: return {"why": "no floor or props"}
	if ents.is_empty(): return {"why": "no entrance"}
	var res := {}
	var shop: Dictionary = r.get_meta("shop", {})
	# (a hand-made room has no shop meta: its name says it, last word: ap_corner_cafe a cafe, cv_city_hall a hall)
	var nm_parts := String(r.name).split("_")
	res["kind"] = String(shop.get("kind", nm_parts[nm_parts.size() - 1] if String(r.name).begins_with("ap_") or String(r.name).begins_with("cv_") else ""))
	res["name"] = String(shop.get("name", ""))
	# the service point: the first kind of till or counter found, the first of them that leaves both spots on the floor
	for sv in SERVICE:
		for inst in _instances(props, String(sv[0])):
			var t: Transform3D = inst.t
			var fz := t.basis.z.normalized(); fz.y = 0.0; fz = fz.normalized()
			var staff_dir: Vector3 = fz * float(sv[1])      # (towards the staff)
			var o := t.origin
			var st := o + staff_dir * 0.72
			var qu := o - staff_dir * 1.0
			if not (_on_floor(floors, st.x, st.z) and _on_floor(floors, qu.x, qu.z)): continue
			res["staff"] = [st.x, st.z, atan2(-staff_dir.x, -staff_dir.z)]
			res["queue"] = [qu.x, qu.z, atan2(staff_dir.x, staff_dir.z)]
			res["service"] = String(sv[0])
			break
		if res.has("staff"): break
	if not res.has("staff"): return {"why": "no till or counter with room on both sides"}
	# the browse spots: before shelves and fridges, not on the queue, spread out
	var cand := []
	for key in BROWSE:
		for inst in _instances(props, key):
			var t: Transform3D = inst.t
			var fz := t.basis.z.normalized(); fz.y = 0.0
			if fz.length() < 0.1: continue
			fz = fz.normalized()
			var p := t.origin + fz * 0.85
			if not _on_floor(floors, p.x, p.z): continue
			if Vector2(p.x - float(res.queue[0]), p.z - float(res.queue[1])).length() < 1.4: continue
			if Vector2(p.x - float(res.staff[0]), p.z - float(res.staff[1])).length() < 1.2: continue
			cand.append([p.x, p.z, atan2(-fz.x, -fz.z)])
	var picked := []
	while picked.size() < 6 and not cand.is_empty():
		var best := 0
		var bd := -1.0
		for k in cand.size():
			var d := 1e9
			for q in picked: d = minf(d, Vector2(float(cand[k][0]) - float(q[0]), float(cand[k][1]) - float(q[1])).length())
			if picked.is_empty(): d = Vector2(float(cand[k][0]) - float(res.queue[0]), float(cand[k][1]) - float(res.queue[1])).length()
			if d > bd: bd = d; best = k
		if picked.size() > 0 and bd < 1.2: break
		picked.append(cand[best]); cand.remove_at(best)
	res["browse"] = picked
	# the seats
	var seats := []
	for key in SEATS:
		for inst in _instances(props, key):
			var t: Transform3D = inst.t
			var fz := t.basis.z; fz.y = 0.0
			if fz.length() < 0.1: continue
			fz = fz.normalized()
			var along := Vector3(fz.z, 0.0, -fz.x)
			var offs := [-0.42, 0.42] if String(key).contains("bench") else [0.0]
			for o in offs:
				var p := t.origin + along * float(o) + fz * 0.08
				if not _on_floor(floors, p.x, p.z): continue
				if Vector2(p.x - float(res.queue[0]), p.z - float(res.queue[1])).length() < 1.0: continue
				seats.append([p.x, p.z, atan2(fz.x, fz.z)])
				if seats.size() >= 10: break
	res["seats"] = seats
	# the first entrance: just inside and just outside its middle
	var e: Array = ents[0]
	var mid := (float(e[2]) + float(e[3])) * 0.5
	var wall := float(e[1])
	var sgn := 1.0 if wall > 0.0 else -1.0
	if String(e[0]) == "z":
		res["door_in"] = [mid, wall - sgn * 0.9]; res["door_out"] = [mid, wall + sgn * 1.4]
	else:
		res["door_in"] = [wall - sgn * 0.9, mid]; res["door_out"] = [wall + sgn * 1.4, mid]
	return res
