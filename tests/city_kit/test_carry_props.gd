extends SceneTree
## Carry props (page J): every baked carry scene loads, is light (under its kit budget), draws with the page-J kit prop
## material, has both grips, and its grips are where the hold says (one hand: on top on the handle; two hands: one on
## each side face). Room props still find the kit glbs (room_lib.indoor_file scans props/indoor/carry).
const C := preload("res://map_dc/coronado/city_kit/carry/carry_props.gd")
const ROOM_LIB := "res://map_dc/coronado/city_kit/interiors/rooms/room_lib.gd"
var fails := 0
func ok(c: bool, m: String) -> void:
	print(("PASS " if c else "FAIL ") + m); if not c: fails += 1
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var names := C.names()
	ok(names.size() >= 21, "carry index lists %d props" % names.size())
	var total := 0
	for n: String in names:
		var e: Dictionary = C.index()[n]
		var p := C.spawn(n)
		ok(p != null, "%s spawns" % n)
		if p == null: continue
		var mi := p.get_node_or_null("mesh") as MeshInstance3D
		ok(mi != null and mi.mesh != null and not mi.mesh.resource_path.contains(".glb"), "%s mesh embedded in its scene (kit glbs are not exported)" % n)
		var m := mi.material_override if mi else null
		ok(m != null and m.resource_path.ends_with("pw_props_j_color_clean_20.tres"), "%s page-J prop material" % n)
		var tris := int(p.get_meta(&"tris", 0)); total += tris
		ok(tris > 0 and tris <= int(e.get("budget", 600)), "%s %d tris within %d" % [n, tris, int(e.get("budget", 600))])
		var a: AABB = mi.mesh.get_aabb() if mi else AABB()
		var r := C.grip(p, "grip_r").origin; var l := C.grip(p, "grip_l").origin
		ok(p.has_node("grip_r") and p.has_node("grip_l"), "%s has grips" % n)
		if C.two_hands(n):
			ok(r.x > a.position.x + a.size.x * 0.8 and l.x < a.position.x + a.size.x * 0.2, "%s grips on the side faces" % n)
		else:
			ok(r.is_equal_approx(l) and r.y > a.position.y + a.size.y * 0.7, "%s grip on the handle up top" % n)
		ok(a.size.length() > 0.2 and a.size.length() < 1.2, "%s carry-sized (%.2f m)" % [n, a.size.length()])
		p.free()
	if FileAccess.file_exists(ROOM_LIB):
		ok(String(load(ROOM_LIB).indoor_file("prop_crate_wine")) != "", "room_lib finds carry glbs (props/indoor/carry)")
	print("carry props: %d, %d tris total" % [names.size(), total])
	print("RESULT ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(1 if fails else 0)
