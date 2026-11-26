extends SceneTree
## The study, Part 2 (the Mixamo pipeline): "add a root bone that takes ground-plane travel and turning from the hips,
## leave the hips' vertical movement in the hips", and "The humanoid profile expects a bone named `Root` above the
## hips at the world origin". The study does it in Blender; here the bone is added to the scene the lab already has
## (traversal/character/player_v4.scn, Mixamo's rig of player_v4), which gives the same skeleton with no Blender step.
## Writes traversal/character/player_v4_rooted.scn.
## Run:  godot --headless --path traversal_lab -s res://tools/build_rig.gd

const SRC := "res://traversal/character/player_v4.scn"
const OUT := "res://traversal/character/player_v4_rooted.scn"


func _initialize() -> void:
	var model: Node = (load(SRC) as PackedScene).instantiate()
	var sk := _find(model)
	var hips := sk.find_bone("mixamorig_Hips")
	if sk.find_bone("Root") < 0:
		sk.add_bone("Root")
	var root_i := sk.find_bone("Root")
	sk.set_bone_rest(root_i, Transform3D.IDENTITY)
	sk.set_bone_parent(hips, root_i)
	sk.reset_bone_poses()
	_own(model, model)
	var ps := PackedScene.new()
	ps.pack(model)
	var err := ResourceSaver.save(ps, OUT, ResourceSaver.FLAG_COMPRESS)
	print("%s: %d bones, Root is bone %d, the hips' parent is bone %d, hips stand at %s; saved: %d" % [OUT, sk.get_bone_count(), root_i, sk.get_bone_parent(hips), sk.get_bone_global_rest(hips).origin, err])
	quit(0 if err == OK else 1)


func _find(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var s := _find(c)
		if s:
			return s
	return null


func _own(n: Node, owner: Node) -> void:
	for c in n.get_children():
		c.owner = owner
		_own(c, owner)
