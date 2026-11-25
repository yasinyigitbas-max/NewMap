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
	player.teleport(Vector3(0, 0, -2), 0.0)
	for i in f1:
		player.set_scripted_input(Vector2(0, 1), sc == "run", true)
		await physics_frame
		if i >= f0:
			var m = player.get_metrics()
			print("%3d ph %.2f L%s%d R%s%d hips %.3f %.3f | aL z %.2f y %.3f | aR z %.2f y %.3f | L hip %.0f knee %.0f ank %.0f | R hip %.0f knee %.0f ank %.0f" % [i, m.phase,
				"P" if m.planted_l else "-", m.contact_l, "P" if m.planted_r else "-", m.contact_r, m.hips_rel.y, m.hips_rel.z,
				m.ankle_l.z, m.ankle_l.y, m.ankle_r.z, m.ankle_r.y, m.joints.x, m.joints.y, m.joints.z, m.joints_r.x, m.joints_r.y, m.joints_r.z])
	quit()
