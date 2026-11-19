extends SceneTree
## Superchecker, the hand-placed trees (19 Nov 2026). docs/TREE_PLAN.md: "New pieces t_<area> in world coordinates,
## one per area ...: every tree a line with its place, species, size and the reason it is there."
## This builds ONE such piece from ONE list (map_dc/coronado/city_kit/zoning/trees/<area>.json). It decides nothing:
## it places exactly the list's lines, each tree where its line says, through kit_lib's own prop builder (the same
## batches, detail tiers, materials and trunk colliders every other piece has). Trees are grouped by 64 m square
## under their own node so that no batch spreads further than a near tier may (the stadium's lesson of 17 Nov).
##   godot --path . --rendering-method mobile --resolution 320x180 -s res://tools/city/super/sc_trees.gd -- \
##       --list=res://map_dc/coronado/city_kit/zoning/trees/<area>.json --out=res://OUT/super/work/t_<area>.scn
## Real renderer (MultiMesh data is empty under --headless).
const K := preload("res://tools/city/pilot/kit_lib.gd")

func _init() -> void: _run.call_deferred()

func _own(n: Node, owner: Node) -> void:
	for c in n.get_children():
		c.owner = owner; _own(c, owner)

func _run() -> void:
	var list := ""; var out := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--list="): list = a.trim_prefix("--list=")
		elif a.begins_with("--out="): out = a.trim_prefix("--out=")
	var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(list))
	if not (j is Dictionary) or not (j as Dictionary).has("trees") or out == "": print("SC-TREES needs --list= (a tree list) and --out="); quit(2); return
	var top := Node3D.new(); top.name = out.get_file().get_basename()
	top.set_meta(&"trees_from", list.get_file())
	var cells := {}
	var n := 0
	for t: Dictionary in j["trees"]:
		var at: Array = t["at"]
		var p := Vector3(float(at[0]), float(at[1]), float(at[2]))
		var key := Vector2i(floori(p.x / 64.0), floori(p.z / 64.0))
		if not cells.has(key): cells[key] = K.Props.new()
		(cells[key] as K.Props).add(String(t["base"]), String(t.get("cond", "normal")), p, float(t.get("yaw", 0.0)), true, float(t.get("scale", 1.0)))
		n += 1
	for key: Vector2i in cells:
		var cn := Node3D.new(); cn.name = "cell_%d_%d" % [key.x, key.y]; top.add_child(cn)
		(cells[key] as K.Props).build(cn, K)
	_own(top, top)
	var ps := PackedScene.new(); ps.pack(top)
	var err := ResourceSaver.save(ps, out, ResourceSaver.FLAG_COMPRESS)
	print("SC-TREES %s: %d trees in %d squares, saved (%s)" % [out, n, cells.size(), error_string(err)])
	top.free()
	quit(0 if err == OK else 1)
