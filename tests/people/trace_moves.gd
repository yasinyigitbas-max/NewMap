extends SceneTree
## Frame by frame through a step, a climb or a vault (C++: CityPlayer.get_frame_log), to find jitter (Yasin: "stepup jitter is
## still there, find whats causing it check how the animations are lined up and inspect frame by frame"):
##   godot --path . --rendering-method mobile --resolution 960x540 --fixed-fps 60 -s res://tests/people/trace_moves.gd -- --h=0.2 [--d=3]
## He walks into the thing (h high, d deep); every physics frame from 0.4 s before the move to 1.2 s after it: the
## node, where the figure was drawn, its hips (as the clip and placement have them), the clip, the move's progress; and
## the hips' step from the frame before, the biggest steps and back-steps flagged.
var player: CharacterBody3D
var cam: Camera3D
var t := 0.0
var frames := []
var h := 0.2
var d := 3.0

func _box(size: Vector3, at: Vector3) -> void:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = size; cs.shape = sh; b.add_child(cs)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = size; mi.mesh = bm; b.add_child(mi)
	b.position = at; root.add_child(b)

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--h="): h = float(a.trim_prefix("--h="))
		if a.begins_with("--d="): d = float(a.trim_prefix("--d="))
	_box(Vector3(30, 2, 30), Vector3(0, -1, 0))
	_box(Vector3(3, h, d), Vector3(0, h * 0.5, 3.0 + d * 0.5))
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 35, 0); root.add_child(sun)
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0, 0.05, 0); root.add_child(player)
	cam = Camera3D.new(); root.add_child(cam)

func _physics_process(delta: float) -> bool:
	t += delta
	if cam: cam.current = true; cam.look_at_from_position(player.global_position + Vector3(3.5, 1.6, 0.5), player.global_position + Vector3(0, 0.8, 0.5), Vector3.UP)
	if t > 0.5 and t < 0.6: player.call(&"set_move", Vector2(0, 1), false)
	if t > 0.5: frames.append(player.call(&"get_frame_log"))
	if t < 6.0: return false
	# the window round the move
	var first := -1; var last := -1
	for i in frames.size(): if int(frames[i].climb) != 0: (first if first >= 0 else 0); if int(frames[i].climb) != 0 and first < 0: first = i
	for i in frames.size(): if int(frames[i].climb) != 0: last = i
	if first < 0: print("TRACE no move happened"); quit(); return true
	var a := maxi(first - 24, 1); var b := mini(last + 72, frames.size() - 1)
	var worst := 0.0; var back := 0
	for i in range(a, b + 1):
		var f: Dictionary = frames[i]; var p: Dictionary = frames[i - 1]
		var dp: Vector3 = (f.pelvis as Vector3) - (p.pelvis as Vector3)
		var dn: Vector3 = (f.node as Vector3) - (p.node as Vector3)
		var flag := ""
		if dp.z < -0.004: flag += " BACK"; back += 1
		if absf(dp.y) > 0.03 or absf(dp.z) > 0.06: flag += " JUMP"
		worst = maxf(worst, absf(dp.y) + absf(dp.z))
		print("F%03d %-18s u %5.2f settle %4.2f | node y %.3f z %.3f (dz %+.3f) | fig y %.3f z %.3f | hips y %.3f z %.3f (dy %+.3f dz %+.3f)%s" % [i, String(f.clip).trim_prefix("ual/"), float(f.u), float(f.settle), (f.node as Vector3).y, (f.node as Vector3).z, dn.z, (f.fig_at as Vector3).y, (f.fig_at as Vector3).z, (f.pelvis as Vector3).y, (f.pelvis as Vector3).z, dp.y, dp.z, flag])
	print("TRACE frames %d-%d: the hips' biggest step %.3f m, %d frames going backwards" % [a, b, worst, back])
	quit()
	return true
