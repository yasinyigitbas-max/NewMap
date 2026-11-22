extends SceneTree
## Prints a clip as the new movement system measures it (mo_clip): per 1/30 s the feet, their down flags, the hips,
## the travel read from the planted feet (root_v), the converter's yaw / vz, the facing.
##   godot --headless --path . -s res://tools/people/dump_mo_clip.gd -- pwalk/stop_b [from to]
var player: Node
var n := 0
func _initialize() -> void:
	var g := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(20, 2, 20); cs.shape = sh; g.add_child(cs); g.position = Vector3(0, -1, 0); root.add_child(g)
	player = ClassDB.instantiate(&"CityPlayer"); root.add_child(player)
func _process(_d: float) -> bool:
	n += 1
	if n < 20: return false
	var a := OS.get_cmdline_user_args()
	var rows: Array = player.call(&"motor_dump", a[0])
	var t0 := float(a[1]) if a.size() > 1 else 0.0
	var t1 := float(a[2]) if a.size() > 2 else 99.0
	print("t | footL | footR | dL dR | hips | root_v | yaw | vz | face")
	for r in rows:
		if r[0] < t0 - 1e-4 or r[0] > t1 + 1e-4: continue
		print("%.3f L %s R %s %d%d hips %s rv %s yaw %.3f vz %.2f face %.3f" % [r[0], str(r[1].snapped(Vector3.ONE * 0.001)), str(r[2].snapped(Vector3.ONE * 0.001)), int(r[3]), int(r[4]), str(r[5].snapped(Vector3.ONE * 0.001)), str(r[6].snapped(Vector3.ONE * 0.01)), r[7], r[8].z, r[9]])
	return true
