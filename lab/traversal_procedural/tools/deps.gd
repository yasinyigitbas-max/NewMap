extends SceneTree
# Tool: prints the res:// dependencies of the given resources (header only, nothing is loaded).
func _init():
	for p in OS.get_cmdline_user_args():
		for d in ResourceLoader.get_dependencies(p):
			print("DEP ", d.get_slice("::", 2) if d.contains("::") else d)
	quit()
