extends SceneTree
# Prints the body's skeleton: name, parent, global rest position. Tool only.
func _init():
	var path = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "res://body/player_v3.glb"
	var scn = load(path).instantiate()
	var sk: Skeleton3D = scn.find_children("*", "Skeleton3D", true, false)[0]
	print("skeleton ", sk.name, " bones ", sk.get_bone_count(), " node xf ", sk.transform)
	for i in sk.get_bone_count():
		var g = sk.get_bone_global_rest(i)
		var p = sk.get_bone_parent(i)
		print("%d %s parent=%s pos=(%.3f %.3f %.3f) y=(%.2f %.2f %.2f) z=(%.2f %.2f %.2f)" % [i, sk.get_bone_name(i), sk.get_bone_name(p) if p >= 0 else "-", g.origin.x, g.origin.y, g.origin.z, g.basis.y.x, g.basis.y.y, g.basis.y.z, g.basis.z.x, g.basis.z.y, g.basis.z.z])
	var aabb := AABB()
	for m in scn.find_children("*", "MeshInstance3D", true, false):
		print("mesh ", m.name, " aabb ", m.get_aabb(), " skin ", m.skin != null)
	quit()
