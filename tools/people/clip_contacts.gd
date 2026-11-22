extends SceneTree
## A loop's foot contacts as the movement system reads them: the share of frames with no foot down (a walk should have
## none), and how far a foot marked down slides (cm per contact). For choosing takes the feet can be pinned on.
##   godot --headless --path . -s res://tools/people/clip_contacts.gd -- pwalk/walk_mx3 ms/S3_Walk_Standard ...
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
		if rows.is_empty(): print("CONTACT %s missing" % c); continue
		var none := 0; var slide := 0.0; var nc := 0
		for s in 2:
			var start := Vector3(); var on := false
			for r in rows:
				var down: bool = r[3 + s]; var p: Vector3 = r[1 + s]
				if down and not on: start = p; on = true
				elif down and on: slide = maxf(slide, Vector2(p.x - start.x, p.z - start.z).length())
				elif not down and on: on = false; nc += 1
		for r in rows: if not r[3] and not r[4]: none += 1
		print("CONTACT %-28s no foot down %3d %%  slide %.1f cm  contacts %d" % [c, 100 * none / rows.size(), slide * 100, nc])
	quit(); return true
