extends SceneTree
## Each clip's pace as the movement system measures it (the planted feet's travel, m/s) and its mean hips height:
##   godot --headless --path . -s res://tools/people/clip_pace.gd -- prun/jog_a ms/S2_Run_Forward ...
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
		if rows.is_empty(): print("PACE %s missing" % c); continue
		var s := Vector3(); var hy := 0.0
		for r in rows: s += r[6]; hy += r[5].y
		print("PACE %-28s %.2f m/s  hips %.2f" % [c, (s / rows.size()).length(), hy / rows.size()])
	quit(); return true
