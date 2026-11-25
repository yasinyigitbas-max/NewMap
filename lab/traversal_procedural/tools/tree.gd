extends SceneTree
func _init():
	var scn = load("res://body/player_v3.glb").instantiate()
	for n in scn.find_children("*", "", true, false):
		print(scn.get_path_to(n), "  ", n.get_class(), "  ", n.transform.basis.get_scale() if n is Node3D else "")
	quit()
