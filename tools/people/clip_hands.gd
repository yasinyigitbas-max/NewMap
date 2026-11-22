extends SceneTree
## A clip's feet, hips and hands every 0.1 s, with the hands' speed (for fitting hand contacts, e.g. a ledge's corner):
##   godot --headless --path . -s res://tools/people/clip_hands.gd -- mx/Ledge_Drop
var player: Node
var n := 0
func _initialize() -> void:
	var g := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(20, 2, 20); cs.shape = sh; g.add_child(cs); g.position = Vector3(0, -1, 0); root.add_child(g)
	player = ClassDB.instantiate(&"CityPlayer"); root.add_child(player)
func _process(_d: float) -> bool:
	n += 1
	if n < 20: return false
	var rows: Array = player.call(&"motor_dump", OS.get_cmdline_user_args()[0])
	for i in range(0, rows.size(), 3):
		var r = rows[i]
		print("H %.2f feet L%s R%s %d%d hips %s handL %s handR %s vL %.2f vR %.2f" % [r[0], str(r[1].snapped(Vector3.ONE*0.01)), str(r[2].snapped(Vector3.ONE*0.01)), int(r[3]), int(r[4]), str(r[5].snapped(Vector3.ONE*0.01)), str(r[10].snapped(Vector3.ONE*0.01)), str(r[11].snapped(Vector3.ONE*0.01)), r[12], r[13]])
	quit(); return true
