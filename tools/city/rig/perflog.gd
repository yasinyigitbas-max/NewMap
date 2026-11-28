extends Node
## The cost of a real play session (28 Nov, Yasin: "cant you just inject that to the build? phone is still hooked"):
## every 10 s one line in the log (adb logcat -s godot:I | grep "RIG perf"): the frames (mean, median, 95th percentile,
## worst, over 33 / 50 ms), the engine's process and physics time, the GPU (read on one frame in 30: each read makes the
## render thread catch up), draw calls, triangles, the camera's place, and the 14 costliest systems (the native timers,
## perf_marks.h, through CityStream.perf_take). Nothing in the game changes.
## On when the file user://perflog_on exists (rig.gd adds this node on the root); a phone's file is made with
##   adb shell "run-as com.yasin.citykit.rig touch files/perflog_on"
const WINDOW := 10.0

var t := 0.0
var ft: PackedFloat32Array = []
var proc := 0.0
var phys := 0.0
var gpu := 0.0
var draws := 0.0
var tris := 0.0
var sys := {}
var st: Node
var measured := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("RIG perf log on: a line every %.0f s" % WINDOW)

func _process(delta: float) -> void:
	if not measured and get_viewport():
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true); measured = true
	if st == null or not is_instance_valid(st):
		st = null
		for n in get_tree().root.find_children("*", "CityStream", true, false): st = n
	t += delta
	ft.append(delta * 1000.0)
	proc += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	if ft.size() % 30 == 1:
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()) * 30.0
	draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	tris += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	if st and st.has_method(&"perf_take"):
		var d: Dictionary = st.call(&"perf_take")
		for k in d: sys[k] = float(sys.get(k, 0.0)) + float(d[k])
	if t < WINDOW: return
	var n := ft.size()
	var s := ft.duplicate(); s.sort()
	var sum := 0.0
	var o33 := 0; var o50 := 0
	for v in ft:
		sum += v
		if v > 33.4: o33 += 1
		if v > 50.0: o50 += 1
	var f := float(n)
	var top: Array = sys.keys(); top.sort_custom(func(a, b) -> bool: return float(sys[a]) > float(sys[b]))
	var parts: PackedStringArray = []
	for k in top.slice(0, 14): parts.append("%s %.2f" % [k, float(sys[k]) / f])
	var cam := get_viewport().get_camera_3d() if get_viewport() else null
	var at := cam.global_position if cam else Vector3()
	print("RIG perf %d frames (%.0f fps): mean %.1f, median %.1f, p95 %.1f, worst %.0f ms, over 33 ms %d, over 50 ms %d | process %.1f, physics %.1f, gpu %.1f ms | draw calls %.0f, triangles %.0fk | at (%.0f, %.0f) | systems: %s" % [n, f / t, sum / f, s[n / 2], s[mini(n - 1, int(n * 0.95))], s[n - 1], o33, o50, proc / f, phys / f, gpu / f, draws / f, tris / f / 1000.0, at.x, at.z, ", ".join(parts)])
	t = 0.0; ft = []; proc = 0.0; phys = 0.0; gpu = 0.0; draws = 0.0; tris = 0.0; sys = {}
