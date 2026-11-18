extends Node3D
# N different spatial shaders (each one = a full set of Mobile scene shader variants with specialization constants)
# on a grid of boxes under a shadowed sun and two omni lights. After FRAMES frames: saves user://shot.png, prints the
# process memory (VmRSS, RssAnon from /proc) and quits. Run the same binary source with and without a patch:
# the picture must be identical, the memory lower.
const N := 24
var FRAMES := 150   # env SM_FRAMES=<n>: quit earlier, while pipelines are still compiling (exit test)
var frame := 0

func _ready() -> void:
	if OS.get_environment("SM_FRAMES") != "": FRAMES = int(OS.get_environment("SM_FRAMES"))
	var cam := Camera3D.new()
	cam.position = Vector3(0, 9, 13)
	cam.rotation_degrees = Vector3(-35, 0, 0)
	add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.shadow_enabled = true
	add_child(sun)
	for k in 2:
		var o := OmniLight3D.new()
		o.position = Vector3(-6 + 12 * k, 2, 2)
		o.light_color = Color(1, 0.6, 0.3) if k == 0 else Color(0.3, 0.6, 1)
		o.omni_range = 9.0
		add_child(o)
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	floor_mi.mesh = pm
	add_child(floor_mi)
	var box := BoxMesh.new()
	for i in N:
		var sh := Shader.new()
		var r := 0.2 + 0.8 * float(i % 7) / 6.0
		var g := 0.2 + 0.8 * float(i % 5) / 4.0
		var b := 0.2 + 0.8 * float(i % 3) / 2.0
		var extra := ""
		if i % 4 == 1: extra = "\tROUGHNESS = 0.3; METALLIC = 0.8;\n"
		elif i % 4 == 2: extra = "\tEMISSION = vec3(%f) * 0.2;\n" % b
		elif i % 4 == 3: extra = "\tALPHA = 0.7;\n"
		sh.code = "shader_type spatial;\nvoid fragment() {\n\tALBEDO = vec3(%f, %f, %f) * (0.75 + 0.25 * sin(UV.x * %d.0));\n%s}\n" % [r, g, b, 3 + i, extra]
		var m := ShaderMaterial.new()
		m.shader = sh
		var mi := MeshInstance3D.new()
		mi.mesh = box
		mi.material_override = m
		mi.position = Vector3(-5.25 + (i % 8) * 1.5, 0.5, -4 + (i / 8) * 1.6)
		mi.scale = Vector3(0.8, 0.8 + 0.1 * (i % 5), 0.8)
		add_child(mi)

func _proc(key: String) -> int:
	var f := FileAccess.open("/proc/self/status", FileAccess.READ)
	if f == null: return -1
	for k in 200:   # /proc files report size 0: read line by line
		var line := f.get_line()
		if line.begins_with(key): return int(line.split(":")[1].strip_edges().split(" ")[0])
		if line == "" and f.eof_reached(): break
	return -1

func _process(_dt: float) -> void:
	frame += 1
	if frame == FRAMES:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://shot.png")
		print("shader_mem: N=%d VmRSS_kb=%d RssAnon_kb=%d VmHWM_kb=%d static_kb=%d" % [N, _proc("VmRSS"), _proc("RssAnon"), _proc("VmHWM"), OS.get_static_memory_usage() / 1024])
		print("shader_mem: done")
		get_tree().quit()
