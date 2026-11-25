extends SceneTree
func _init():
	for p in OS.get_cmdline_user_args():
		var s = load(p)
		if s == null:
			print("FAIL ", p); continue
		var n = s.instantiate()
		var cnt = {}
		for c in n.find_children("*", "", true, false):
			cnt[c.get_class()] = cnt.get(c.get_class(), 0) + 1
		print(p, " ", cnt)
		var ab := AABB()
		var first = true
		for m in n.find_children("*", "MeshInstance3D", true, false):
			var b = m.global_transform * m.get_aabb() if m.is_inside_tree() else m.transform * m.get_aabb()
			ab = b if first else ab.merge(b)
			first = false
		print("   aabb ", ab)
	quit()
