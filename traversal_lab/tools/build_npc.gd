extends SceneTree
## An NPC made on Meshy, put on the player's skeleton standard, so that the player's clips play on it as they are.
## Yasin, 27 Nov: "i got a meshy account, can we make the new models from there so they will be a standard?"
##
## Meshy's rig (skeleton_template "mixamo", include_fingers) has the player's bone names, but its bones are turned
## differently at rest and its arms rest lower than a T-pose, and (the study) "In Godot 4 a bone's pose includes its
## rest position, so clips can be shared only between skeletons whose bone names and rest poses both match". So:
## 1. his arms, legs and fingers are turned, joint by joint, until each bone lies along the line the player's bone
##    lies along at rest, and the mesh is carried along by its own skin weights (the pose is baked into the mesh);
## 2. a new skeleton is made: the player's bones, each turned at rest exactly as the player's is, each at the NPC's
##    own joint. The mesh is bound to it.
## His bone lengths stay his own. Writes traversal/npc/<name>.scn and <name>_basecolor.jpg.
## Run:  godot --headless --path traversal_lab -s res://tools/build_npc.gd -- --name=npc_01
##       (twice the first time, with `--import` between: the first run only writes the texture)

const PLAYER := "res://traversal/character/player_v4_rooted.scn"
const TEX_SIZE := 1024          # NOT in the study, mine: the NPC's texture, pixels a side (the player's is 2048)
# the bones laid along the player's own: [bone, the child it points at]
const LIMBS := [["Arm", "ForeArm"], ["ForeArm", "Hand"], ["Hand", "HandMiddle1"], ["UpLeg", "Leg"], ["Leg", "Foot"]]
const FINGERS := ["Thumb", "Index", "Middle", "Ring", "Pinky"]


func _initialize() -> void:
	var name := "npc_01"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--name="):
			name = arg.trim_prefix("--name=")
	var src := ProjectSettings.globalize_path("res://").path_join("../assets/people/meshy/%s/rigged_meshy_mixamo.glb" % name).simplify_path()
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	if doc.append_from_file(src, st) != OK:
		print("cannot read ", src)
		quit(1)
		return
	var scene := doc.generate_scene(st)
	root.add_child(scene)
	var b := _skel(scene)
	var mi := _mesh(scene)
	var a := _skel((load(PLAYER) as PackedScene).instantiate())
	# the texture, kept next to the scene
	var jpg := "res://traversal/npc/%s_basecolor.jpg" % name
	if not FileAccess.file_exists(jpg):
		var mat0 := mi.mesh.surface_get_material(0) as BaseMaterial3D
		var img := mat0.albedo_texture.get_image()
		if img.is_compressed():
			img.decompress()
		img.resize(TEX_SIZE, TEX_SIZE, Image.INTERPOLATE_LANCZOS)
		img.convert(Image.FORMAT_RGB8)
		print("texture written: ", img.save_jpg(jpg, 0.9), "  run --import, then this tool again")
		quit(0)
		return

	# ---- 1. the pose: each limb bone laid along the player's
	var pairs := {}             # NPC bone -> the child it points at
	for side: String in ["Left", "Right"]:
		for l: Array in LIMBS:
			pairs["mixamorig_%s%s" % [side, l[0]]] = "mixamorig_%s%s" % [side, l[1]]
		for f: String in FINGERS:
			for k in 3:
				pairs["mixamorig_%sHand%s%d" % [side, f, k + 1]] = "mixamorig_%sHand%s%d" % [side, f, k + 2]
	var nb := b.get_bone_count()
	var at := []                # each NPC joint at rest
	for i in nb:
		at.append(b.get_bone_global_rest(i).origin)
	var turn := []              # how far each bone's part of him is turned
	var put := []               # where each joint is afterwards
	turn.resize(nb)
	put.resize(nb)
	var most_deg := 0.0
	for i in nb:                # (a parent always comes before its children)
		var p := b.get_bone_parent(i)
		var q := Basis.IDENTITY if p < 0 else (turn[p] as Basis)
		put[i] = (at[i] as Vector3) if p < 0 else (put[p] as Vector3) + q * ((at[i] as Vector3) - (at[p] as Vector3))
		var n := b.get_bone_name(i)
		if pairs.has(n) and b.find_bone(pairs[n]) >= 0 and a.find_bone(n) >= 0 and a.find_bone(pairs[n]) >= 0:
			var now := (q * ((at[b.find_bone(pairs[n])] as Vector3) - (at[i] as Vector3))).normalized()
			var want := (a.get_bone_global_rest(a.find_bone(pairs[n])).origin - a.get_bone_global_rest(a.find_bone(n)).origin).normalized()
			var axis := now.cross(want)
			if axis.length() > 0.00001:
				q = Basis(axis.normalized(), now.angle_to(want)) * q
				most_deg = maxf(most_deg, rad_to_deg(now.angle_to(want)))
		turn[i] = q
	print("the furthest a bone was turned to lie along the player's: %.1f degrees" % most_deg)

	# ---- 2. the new skeleton: the player's bones and rest turns, the NPC's joints
	var sk := Skeleton3D.new()
	sk.name = "Skeleton3D"
	var na := a.get_bone_count()
	var g := []
	g.resize(na)
	for i in na:
		sk.add_bone(a.get_bone_name(i))
	for i in na:
		sk.set_bone_parent(i, a.get_bone_parent(i))
	var order := []             # parents first
	var todo := range(na)
	while not todo.is_empty():
		var left := []
		for i: int in todo:
			if a.get_bone_parent(i) < 0 or order.has(a.get_bone_parent(i)):
				order.append(i)
			else:
				left.append(i)
		todo = left
	for i: int in order:
		var ga := a.get_bone_global_rest(i)
		var j := b.find_bone(a.get_bone_name(i))
		var p := a.get_bone_parent(i)
		var where := Vector3.ZERO
		if j >= 0:
			where = put[j]
		elif p >= 0 and a.get_bone_name(i) != "Root":
			where = (g[p] as Transform3D).origin + (ga.origin - a.get_bone_global_rest(p).origin)
		g[i] = Transform3D(ga.basis.orthonormalized(), where)
		var local: Transform3D = g[i] if p < 0 else (g[p] as Transform3D).affine_inverse() * (g[i] as Transform3D)
		sk.set_bone_rest(i, local)
	sk.reset_bone_poses()

	# ---- the mesh, carried along by its own weights, and bound to the new skeleton
	var skin := mi.skin
	var to_new := []            # the old skin's bind -> [the old bone, the new bone]
	for k in skin.get_bind_count():
		var ob := skin.get_bind_bone(k)
		if ob < 0:
			ob = b.find_bone(skin.get_bind_name(k))
		var up := ob
		while up >= 0 and sk.find_bone(b.get_bone_name(up)) < 0:
			up = b.get_bone_parent(up)      # (a bone the player has not got: its parent takes its share)
		to_new.append([ob, sk.find_bone(b.get_bone_name(up))])
	var mesh := ArrayMesh.new()
	var tris := 0
	for s in mi.mesh.get_surface_count():
		var arr := mi.mesh.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var nrm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var tan: PackedFloat32Array = arr[Mesh.ARRAY_TANGENT] if arr[Mesh.ARRAY_TANGENT] != null else PackedFloat32Array()
		var bones: PackedInt32Array = arr[Mesh.ARRAY_BONES]
		var wts: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
		var per := bones.size() / v.size()
		var bones2 := PackedInt32Array()
		bones2.resize(bones.size())
		for vi in v.size():
			var pos := Vector3.ZERO
			var rot := Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO)
			var sum := 0.0
			for k in per:
				var w := wts[vi * per + k]
				var pair: Array = to_new[bones[vi * per + k]]
				bones2[vi * per + k] = int(pair[1]) if w > 0.0 else 0
				if w <= 0.0:
					continue
				var ob2 := int(pair[0])
				var q2: Basis = turn[ob2]
				pos += ((put[ob2] as Vector3) + q2 * (v[vi] - (at[ob2] as Vector3))) * w
				rot.x += q2.x * w
				rot.y += q2.y * w
				rot.z += q2.z * w
				sum += w
			v[vi] = pos / sum
			if nrm.size() == v.size():
				nrm[vi] = (rot * nrm[vi]).normalized()
			if tan.size() == v.size() * 4:
				var t := (rot * Vector3(tan[vi * 4], tan[vi * 4 + 1], tan[vi * 4 + 2])).normalized()
				tan[vi * 4] = t.x
				tan[vi * 4 + 1] = t.y
				tan[vi * 4 + 2] = t.z
		arr[Mesh.ARRAY_VERTEX] = v
		arr[Mesh.ARRAY_NORMAL] = nrm
		if tan.size() > 0:
			arr[Mesh.ARRAY_TANGENT] = tan
		arr[Mesh.ARRAY_BONES] = bones2
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if per == 8 else 0)
		tris += (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = load(jpg)
		mat.roughness = 0.85
		mesh.surface_set_material(s, mat)
	var skin2 := Skin.new()
	for i in na:
		skin2.add_bind(i, (g[i] as Transform3D).affine_inverse())
	var model := Node3D.new()
	model.name = name
	model.add_child(sk)
	var out_mi := MeshInstance3D.new()
	out_mi.name = name
	out_mi.mesh = mesh
	out_mi.skin = skin2
	sk.add_child(out_mi)
	out_mi.skeleton = NodePath("..")
	sk.owner = model
	out_mi.owner = model
	var ps := PackedScene.new()
	ps.pack(model)
	var out := "res://traversal/npc/%s.scn" % name
	var err := ResourceSaver.save(ps, out, ResourceSaver.FLAG_COMPRESS)
	# what he measures, against the player
	var rep := ""
	for pair: Array in [["hips", "Hips", ""], ["hip joint", "LeftUpLeg", ""], ["thigh", "LeftUpLeg", "LeftLeg"], ["shin", "LeftLeg", "LeftFoot"], ["ankle", "LeftFoot", ""], ["upper arm", "LeftArm", "LeftForeArm"], ["forearm", "LeftForeArm", "LeftHand"], ["head top", "HeadTop_End", ""]]:
		var i1 := sk.find_bone("mixamorig_" + String(pair[1]))
		var x := (g[i1] as Transform3D).origin.y
		var y := a.get_bone_global_rest(i1).origin.y
		if String(pair[2]) != "":
			var i2 := sk.find_bone("mixamorig_" + String(pair[2]))
			x = (g[i1] as Transform3D).origin.distance_to((g[i2] as Transform3D).origin)
			y = a.get_bone_global_rest(i1).origin.distance_to(a.get_bone_global_rest(i2).origin)
		rep += "  %s %.3f (player %.3f)" % [pair[0], x, y]
	print("%s: %d triangles, %d bones; saved: %d" % [out, tris, na, err])
	print(rep)
	quit(0 if err == OK else 1)


func _skel(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var s := _skel(c)
		if s:
			return s
	return null


func _mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D:
		return n
	for c in n.get_children():
		var s := _mesh(c)
		if s:
			return s
	return null
