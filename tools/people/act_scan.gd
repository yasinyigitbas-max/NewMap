extends "res://tools/people/make_player_traversal.gd"
## (tool) the action takes as the converter fitted them: length, loop, travel, the hands and hips (figure frame, m)
func _initialize() -> void:
	var scene: Node = (load(DIR + "hero_male.scn") as PackedScene).instantiate()
	sk = scene.find_children("*", "Skeleton3D", true, false)[0]
	skel_x = Transform3D()
	var nd: Node = sk
	while nd != scene: skel_x = (nd as Node3D).transform * skel_x; nd = nd.get_parent()
	rest_g.clear()
	for b in sk.get_bone_count():
		var par := sk.get_bone_parent(b)
		rest_g.append(sk.get_bone_rest(b) if par < 0 else rest_g[par] * sk.get_bone_rest(b))
	var lib: AnimationLibrary = load("res://tools/people/player_act_sources/clips_mxact_male.res")
	var lh := sk.find_bone("Bip01_L_Hand"); var rh := sk.find_bone("Bip01_R_Hand"); var pel := sk.find_bone("Bip01_Pelvis"); var lf := sk.find_bone("Bip01_L_Foot")
	for n in lib.get_animation_list():
		var a := lib.get_animation(n)
		var s := ""
		for f in 5:
			var t := a.length * f / 4.0
			var g := _globals(_locals(a, t))
			var L: Vector3 = skel_x * g[lh].origin; var R: Vector3 = skel_x * g[rh].origin; var P: Vector3 = skel_x * g[pel].origin; var F: Vector3 = skel_x * g[lf].origin
			s += " | L %.2f,%.2f,%.2f R %.2f,%.2f,%.2f P %.2f,%.2f,%.2f F %.2f" % [L.x, L.y, L.z, R.x, R.y, R.z, P.x, P.y, P.z, F.y]
		print("SCAN %-26s %.2fs %s travel %s%s" % [n, a.length, "loop" if a.loop_mode else "once", a.get_meta("travel", Vector3()), s])
	for p in ["bag_paper_kraft", "box_moving", "briefcase_leather", "crate_wine", "box_long", "box_stack"]:
		var c: Node3D = (load("res://map_dc/coronado/city_kit/carry/scenes/%s.scn" % p) as PackedScene).instantiate()
		print("PROP %s grip_r %s grip_l %s" % [p, (c.get_node("grip_r") as Node3D).position, (c.get_node("grip_l") as Node3D).position])
		for m in c.get_meta_list(): print("   ", m, " = ", c.get_meta(m))
	quit(0)
