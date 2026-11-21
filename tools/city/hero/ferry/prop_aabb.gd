extends SceneTree
## Print each kit prop's near-model bounds (ferry landing work, 21 Nov): --p=prop_a,prop_b
const K := preload("res://tools/city/pilot/kit_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--p="): continue
		for p: String in a.trim_prefix("--p=").split(","):
			var conds: Array = K.manifest(p).get("conds", ["clean"])
			var f := K.prop_file(p, String(conds[0]), "near")
			var inst: Node = (load(f) as PackedScene).instantiate()
			var mi: MeshInstance3D = K._first_mesh(inst)
			var bb: AABB = mi.transform * mi.mesh.get_aabb()
			print("AABB %s pos %s end %s" % [p, str(bb.position.snapped(Vector3.ONE * 0.01)), str(bb.end.snapped(Vector3.ONE * 0.01))])
			inst.free()
	quit()
