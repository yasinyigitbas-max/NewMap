extends SceneTree
## A try-out of where a held thing sits in his hand, on takes of the library: [take, share of the take, prop, how].
const SET := [["Walking_With_Shopping_Bag", 0.3, "briefcase_leather", "hang"], ["Walking_With_Shopping_Bag", 0.7, "bag_plastic_thankyou", "hang"],
		["Jogging_With_Box", 0.3, "box_moving", "box"], ["Pistol_Idle", 0.5, "pistol_service", "gun"],
		["Rifle_Standing_Idle", 0.5, "rifle", "gun"], ["Walking_While_Aiming_Rifle", 0.3, "rifle", "gun"]]
var palm_sign := 1.0
func _initialize() -> void:
	_run.call_deferred()
func J(sk: Skeleton3D, n: String) -> Vector3:
	return sk.global_transform * sk.get_bone_global_pose(sk.find_bone("mixamorig_" + n)).origin
func hand(sk: Skeleton3D, side: String) -> Dictionary:
	var w := J(sk, side + "Hand"); var k := J(sk, side + "HandMiddle1"); var i := J(sk, side + "HandIndex1"); var p := J(sk, side + "HandPinky1")
	var along := (k - w).normalized()
	var across := (i - p).normalized()
	across = (across - along * across.dot(along)).normalized()
	var n := along.cross(across) * (1.0 if side == "Right" else -1.0) * palm_sign      # out of the palm
	return {"w": w, "k": k, "along": along, "across": across, "n": n, "palm": w.lerp(k, 0.75) + n * 0.03}
func _run() -> void:
	var out := "."; 
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg.begins_with("--palm="): palm_sign = float(arg.trim_prefix("--palm="))
	var world := Node3D.new(); root.add_child(world)
	var env := WorldEnvironment.new(); env.environment = Environment.new(); env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.6, 0.68); env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE; env.environment.ambient_light_energy = 0.8; world.add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 30, 0); world.add_child(sun)
	var floor_m := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(30, 30); floor_m.mesh = pm; world.add_child(floor_m)
	var lib: AnimationLibrary = load("res://traversal/character/library.res")
	var men: Array = []
	for i in SET.size():
		var m: Node3D = (load("res://traversal/character/player_v4_rooted.scn") as PackedScene).instantiate()
		world.add_child(m); m.position = Vector3(i * 1.25 - 3.1, 0, 0)
		var ap := AnimationPlayer.new(); m.add_child(ap); ap.add_animation_library("", lib)
		ap.play(SET[i][0]); ap.seek(lib.get_animation(SET[i][0]).length * float(SET[i][1]), true); ap.pause()
		var prop: Node3D = (load("res://traversal/props/%s.scn" % SET[i][2]) as PackedScene).instantiate()
		world.add_child(prop)
		men.append([m, prop])
	var cam := Camera3D.new(); world.add_child(cam); cam.fov = 30.0; cam.make_current()
	root.size = Vector2i(2000, 620)
	for view: Array in [["front", 0.0], ["side", -1.3], ["threeq", 0.7]]:
		for i in SET.size():
			(men[i][0] as Node3D).rotation.y = float(view[1])
		for k in 3: await process_frame
		for i in SET.size():
			var m: Node3D = men[i][0]; var prop: Node3D = men[i][1]
			var sk: Skeleton3D = m.get_node("Skeleton3D")
			var r := hand(sk, "Right"); var l := hand(sk, "Left")
			var gr: Vector3 = (prop.get_node("grip_r") as Node3D).position
			var yaw := Basis(Vector3.UP, m.rotation.y)
			match String(SET[i][3]):
				"hang":
					# (side-on: its broad side along the way he walks)
					var side_on := yaw * Basis(Vector3.UP, PI * 0.5)
					prop.global_transform = Transform3D(side_on, (r["palm"] as Vector3) - side_on * gr)
				"box":
					var gl: Vector3 = (prop.get_node("grip_l") as Node3D).position
					prop.global_transform = Transform3D(yaw, ((r["palm"] as Vector3) + (l["palm"] as Vector3)) * 0.5 - yaw * ((gr + gl) * 0.5))
				"gun":
					var z: Vector3 = r["along"]; var y: Vector3 = r["across"]
					if prop.has_node("grip_l") and String(SET[i][2]) != "pistol_service":
						# a long gun lies between his two hands: its own line from grip to grip laid on the line from palm to palm
						var own: Vector3 = ((prop.get_node("grip_l") as Node3D).position - gr).normalized()
						var b0 := Basis(y.cross(z).normalized(), y, z).orthonormalized()
						var want: Vector3 = ((l["palm"] as Vector3) - (r["palm"] as Vector3)).normalized()
						var have: Vector3 = b0 * own
						var turn := Quaternion(have, want)
						z = turn * z; y = turn * y
					var b := Basis(y.cross(z).normalized(), y, z).orthonormalized()
					prop.global_transform = Transform3D(b, (r["palm"] as Vector3) - b * gr)
		cam.position = Vector3(0.0, 1.25, 12.0); cam.look_at(Vector3(0, 1.0, 0))
		for k in 3: await process_frame
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("%s/hold_%s.png" % [out, view[0]])
	quit()
