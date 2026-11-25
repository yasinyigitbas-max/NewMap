extends SceneTree
## Turn Mixamo's rigged player (assets_src/character/player_v4_mixamo.fbx, not in git) into the scene the lab uses
## (traversal/character/player_v4.scn: skeleton, mesh, material and texture in one file).
## Run:  godot --headless --path traversal_lab -s res://tools/build_character.gd

const SRC := "res://assets_src/character/player_v4_mixamo.fbx"
const OUT := "res://traversal/character/player_v4.scn"


func _initialize() -> void:
	var root_node: Node = (load(SRC) as PackedScene).instantiate()
	_strip(root_node)
	_retexture(root_node)
	_own(root_node, root_node)
	_report(root_node, 0)
	var ps := PackedScene.new()
	ps.pack(root_node)
	print("saved ", OUT, " -> ", ResourceSaver.save(ps, OUT, ResourceSaver.FLAG_COMPRESS))
	quit(0)


## Point the material at the texture kept next to the scene, so the scene does not depend on assets_src.
func _retexture(n: Node) -> void:
	if n is MeshInstance3D:
		var mi: MeshInstance3D = n
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = load("res://traversal/character/player_v4_basecolor.jpg")
		mat.roughness = 0.85
		# own copies of the mesh and skin, so they are stored inside the scene and not as links into assets_src
		mi.mesh = mi.mesh.duplicate(true)
		if mi.skin:
			mi.skin = mi.skin.duplicate(true)
		for i in mi.mesh.get_surface_count():
			mi.mesh.surface_set_material(i, mat)
	for c in n.get_children():
		_retexture(c)


func _strip(n: Node) -> void:
	for c in n.get_children():
		if c is AnimationPlayer:
			n.remove_child(c)
			c.free()
		else:
			_strip(c)


func _own(n: Node, owner: Node) -> void:
	for c in n.get_children():
		c.owner = owner
		_own(c, owner)


func _report(n: Node, d: int) -> void:
	var x := ""
	if n is Skeleton3D:
		x = " bones=%d" % (n as Skeleton3D).get_bone_count()
	if n is MeshInstance3D:
		var mi: MeshInstance3D = n
		var mat := mi.mesh.surface_get_material(0) as BaseMaterial3D
		x = " aabb=%s surfaces=%d texture=%s" % [str(mi.get_aabb()), mi.mesh.get_surface_count(), str(mat.albedo_texture.get_size()) if mat and mat.albedo_texture else "NONE"]
	print("  ".repeat(d), n.name, " [", n.get_class(), "]", x)
	for c in n.get_children():
		_report(c, d + 1)
