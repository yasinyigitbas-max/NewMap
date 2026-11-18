extends SceneTree
## The residential zone's shop table (18 Nov, zone growth): every corner shop of the pilot area's quadrant pieces
## (review/grow_res_blocks.json rows with a "shop") -> map_dc/coronado/city_kit/interiors/assignment_res.json, in the
## same shape as assignment_all.json (id, piece, label, model, grid-frame pos / yaw of the building, door, bay, kind,
## name, sign style, built room). The rooms themselves: interiors/rooms/rooms_res.gd. Read-only on the pieces.
##   godot --headless --path . -s res://tools/city/rooms/assign_res.gd
const TAB := "res://map_dc/coronado/city_kit/review/grow_res_blocks.json"
const RC := "res://map_dc/coronado/city_kit/interiors/room_contracts.json"
## per shop label: room, name, sign style, why this shop here
const SHOPS := {
	"r_shop_books": ["g_res_books", "Hillside Books", "cream", "a used bookshop on the corner of 10th and E Ave: the walk from the houses up the hill passes it, and it has been there longer than most of the owners"],
	"r_shop_cafe": ["g_res_cafe", "Ridge Coffee", "green", "the regulars' cafe at 9th and G Ave, at the top of Country Club Ridge: dog walkers and the morning commute down the hill stop here"],
	"r_shop_surf": ["g_res_surf", "Ocean Blvd Surf", "teal", "surf shop and ding repair at 11th and J Ave, one block from Ocean Blvd and the beach: boards walk down to the water from here"],
}

func _init() -> void:
	var rc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RC)).models
	var tab: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TAB))
	var rooms: Array = []
	for row: Dictionary in tab.rows:
		var label := String(row.get("shop", ""))
		if label == "": continue
		var piece := String(row.piece)
		var sc: Node3D = (load("res://map_dc/coronado/city_kit/pieces/%s.scn" % piece) as PackedScene).instantiate()
		var b := sc.get_node_or_null("Buildings/" + label) as Node3D
		if b == null: print("ASSIGN_RES no building %s in %s" % [label, piece]); sc.free(); continue
		var p: Array = row.pos
		var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(float(row.yaw))), Vector3(float(p[0]), float(p[1]), float(p[2]))) * b.transform
		var model := String(b.get_meta(&"kit"))
		var c: Dictionary = rc[model]
		var door := {}
		for o: Dictionary in c.openings:
			if int(o.floor) == 0 and String(o.facade) == "front" and (String(o.region) in ["O_shopdoor", "O_apt_door"]): door = o; break
		var fl: Dictionary = c.floors[0]
		var s: Array = SHOPS[label]
		var signs: Array = []
		for sg: Dictionary in c.signs: signs.append({"facade": sg.facade, "along": sg.along, "w": sg.w})
		rooms.append({"id": "res_" + label.trim_prefix("r_shop_"), "piece": piece, "label": label, "model": model,
			"pos": [xf.origin.x, xf.origin.y, xf.origin.z], "yaw": rad_to_deg(xf.basis.get_euler().y),
			"door_index": 0, "door_along": float(door.along), "door_w": float(door.w), "bay": [float(fl.box_min[0]), float(fl.box_max[0])],
			"kind": row.get("kind", ""), "name": s[1], "style": s[2], "why": s[3], "source": "res_grow", "built": s[0], "signs": signs})
		sc.free()
	var kinds := {"r_shop_books": "books", "r_shop_cafe": "cafe", "r_shop_surf": "sport"}
	for e: Dictionary in rooms: e.kind = kinds[e.label]
	var fo := FileAccess.open("res://map_dc/coronado/city_kit/interiors/assignment_res.json", FileAccess.WRITE)
	fo.store_string(JSON.stringify({"_doc": "the residential zone's walk-in shops (tools/city/rooms/assign_res.gd from review/grow_res_blocks.json; rooms: interiors/rooms/rooms_res.gd). Same shape as assignment_all.json.", "count": rooms.size(), "rooms": rooms}, " "))
	fo.close()
	print("ASSIGN_RES rooms=%d" % rooms.size())
	quit()
