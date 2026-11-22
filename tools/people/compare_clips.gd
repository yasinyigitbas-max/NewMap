extends SceneTree
## How alike two clips are, as the movement system measures them (feet and hips, the feet about the hips, over the clip's
## length in 20 steps): about 0 the same take (a copy or a retarget of the same Mixamo clip), over ~0.08 a different
## performance. For choosing the movement sets' clips (Yasin, 24 Nov: "there should be alternatives for every animation").
##   godot --headless --path . -s res://tools/people/compare_clips.gd -- a1,b1 a2,b2 ...
var player: Node
var n := 0
func _initialize() -> void:
	var g := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(20, 2, 20); cs.shape = sh; g.add_child(cs); g.position = Vector3(0, -1, 0); root.add_child(g)
	player = ClassDB.instantiate(&"CityPlayer"); root.add_child(player)

func _feat(rows: Array, u: float) -> PackedFloat32Array:
	var r = rows[clampi(int(round(u * (rows.size() - 1))), 0, rows.size() - 1)]
	var h: Vector3 = r[5]; var l: Vector3 = r[1] - h; var rr: Vector3 = r[2] - h
	# (mirror-free: the two feet sorted by x so a take started on the other foot still compares)
	if l.x < rr.x: var tmp := l; l = rr; rr = tmp
	# (the hands about the hips too: Mixamo's variants of one take - its arm-space slider - share the legs, not the arms)
	var hl: Vector3 = r[10] - h; var hr: Vector3 = r[11] - h
	if hl.x < hr.x: var t2 := hl; hl = hr; hr = t2
	return PackedFloat32Array([h.y, l.x, l.y, l.z, rr.x, rr.y, rr.z, hl.x, hl.y, hl.z, hr.x, hr.y, hr.z])

func _process(_d: float) -> bool:
	n += 1
	if n < 20: return false
	for pair in OS.get_cmdline_user_args():
		var ab: PackedStringArray = pair.split(",")
		var A: Array = player.call(&"motor_dump", ab[0]); var B: Array = player.call(&"motor_dump", ab[1])
		if A.is_empty() or B.is_empty(): print("CMP %-40s %-40s missing" % [ab[0], ab[1]]); continue
		var best := 1e9
		for shift in 20:   # (a loop may start at another moment of its cycle)
			var d := 0.0
			for k in 20:
				var fa := _feat(A, k / 19.0); var fb := _feat(B, fmod(k + shift, 20.0) / 19.0)
				for i in fa.size(): d += absf(fa[i] - fb[i])
			best = minf(best, d / (20.0 * 13.0))
		print("CMP %-40s %-40s %.3f  (%.2f s / %.2f s)" % [ab[0], ab[1], best, A[-1][0], B[-1][0]])
	quit(0)
	return true
