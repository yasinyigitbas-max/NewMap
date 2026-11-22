extends SceneTree
## A table of clips as the new movement system measures them (mo_clip): length, loop, in place, facing at the start and
## end (deg), the hips' travel in the figure (m), the body's travel from the planted feet (in-place clips), the hips'
## height at the start and end, the feet down at the start and end.
##   godot --headless --path . -s res://tools/people/survey_mo_clips.gd -- ptrav/Cover_Idle ptrav/Stand_To_Cover_a ...
var player: Node
var n := 0
func _initialize() -> void:
	var g := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(20, 2, 20); cs.shape = sh; g.add_child(cs); g.position = Vector3(0, -1, 0); root.add_child(g)
	player = ClassDB.instantiate(&"CityPlayer"); root.add_child(player)
func _process(_d: float) -> bool:
	n += 1
	if n < 20: return false
	for c in OS.get_cmdline_user_args():
		var rows: Array = player.call(&"motor_dump", c)
		if rows.is_empty(): print("%-34s (none)" % c); continue
		var r0: Array = rows[0]; var r1: Array = rows[-1]
		var trav := Vector3()
		for i in rows.size() - 1: trav += (rows[i][6] as Vector3) / 30.0
		print("%-34s %5.2f s  face %6.1f -> %6.1f  hips %s -> %s  travel %s  yaw_end %6.1f  down %d%d -> %d%d" % [c, r1[0], rad_to_deg(r0[9]), rad_to_deg(r1[9]), str((r0[5] as Vector3).snapped(Vector3.ONE * 0.01)), str((r1[5] as Vector3).snapped(Vector3.ONE * 0.01)), str(trav.snapped(Vector3.ONE * 0.01)), rad_to_deg(r1[7]), int(r0[3]), int(r0[4]), int(r1[3]), int(r1[4])])
	return true
