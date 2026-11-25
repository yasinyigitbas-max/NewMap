extends SceneTree
# Tool: per-frame trace of the motor's targets for one scenario. godot --headless --fixed-fps 60 -s tests/trace.gd -- walk 120 180
var player
func _initialize():
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	player = m.get_node("Player")
	go.call_deferred()
func go():
	var a = OS.get_cmdline_user_args()
	var sc = a[0] if a.size() > 0 else "walk"
	var f0 = int(a[1]) if a.size() > 1 else 120
	var f1 = int(a[2]) if a.size() > 2 else 180
	var start = Vector3(0, 0, -2)
	if a.size() > 3:
		var tp = a[3].split(",")
		start = Vector3(float(tp[0]), float(tp[1]), float(tp[2]))
	player.teleport(start, 0.0)
	for i in f1:
		var st = Vector2(0, 1)
		if sc == "circle" and i >= 120:
			var ang = (i - 120) / 60.0 * 1.2
			st = Vector2(sin(ang), cos(ang))
		if sc == "analog":
			st = Vector2.ZERO if i < 30 else Vector2(0, 0.4 + 0.3 * sin((i - 30) / 60.0 * 1.5))
		if sc.ends_with("stop") and i >= 240:
			st = Vector2.ZERO
		player.set_scripted_input(st, sc == "run" or sc == "circle" or sc == "runstop", true)
		await physics_frame
		if i >= f0:
			var m = player.get_metrics()
			print("%3d sp %.2f act %s ph %.2f L%s%d R%s%d hips %.3f %.3f | pos %.2f %.2f | aL z %.2f y %.3f | aR z %.2f y %.3f | lean %.0f | L hip %.0f knee %.0f ank %.0f | R hip %.0f knee %.0f ank %.0f" % [i, m.speed, m.active, m.phase,
				"P" if m.planted_l else "-", m.contact_l, "P" if m.planted_r else "-", m.contact_r, m.hips_rel.y, Vector2(m.hips_rel.x, m.hips_rel.z).length(), m.pos.y, m.pos.z,
				m.ankle_l.z, m.ankle_l.y, m.ankle_r.z, m.ankle_r.y, m.lean_deg, m.joints.x, m.joints.y, m.joints.z, m.joints_r.x, m.joints_r.y, m.joints_r.z])
	quit()
