extends SceneTree
## A picture sheet of clips on our own figure (the Animator, 21 Nov; for finding out what each Mixamo download is and
## whether it fits): each row one clip, five columns its pose at 0, 1/4, 1/2, 3/4 and the end, its name on the left.
## A clip that moves its hips (not "in place") is shown where it moved them, from its column's spot.
##   godot --path . --rendering-method mobile --resolution 1600x1000 -s res://tests/people/clip_sheet.gd -- --clips=mx/Walking,mx/Waving --out=OUT/sheet.png [--body=M1]
## or --lib=mx --from=0 --count=6 (the library's clips in order, 6 from the 0th)
var out := "OUT/clip_sheet.png"
var clips := PackedStringArray()
var body := "M1"
var lib := ""
var from := 0
var count := 6
var n := 0
var COLS := 5
const DX := 2.4
const DY := 2.6

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
		elif a.begins_with("--clips="): clips = a.trim_prefix("--clips=").split(",")
		elif a.begins_with("--body="): body = a.trim_prefix("--body=")
		elif a.begins_with("--lib="): lib = a.trim_prefix("--lib=")
		elif a.begins_with("--from="): from = int(a.trim_prefix("--from="))
		elif a.begins_with("--count="): count = int(a.trim_prefix("--count="))
		elif a.begins_with("--cols="): COLS = int(a.trim_prefix("--cols="))
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-45, 30, 0); root.add_child(sun)
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.82, 0.85, 0.9)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.75, 0.76, 0.8); env.ambient_light_energy = 0.9; we.environment = env; root.add_child(we)
	if lib != "":   # (the clip names from a throwaway figure)
		var p0: Node3D = ClassDB.instantiate(&"CityPed"); p0.set(&"body_id", body); root.add_child(p0)
		var ap: AnimationPlayer = p0.find_children("*", "AnimationPlayer", true, false)[0]
		var names := Array(ap.get_animation_library(StringName(lib)).get_animation_list()); names.sort()
		clips = PackedStringArray()
		for i in range(from, mini(from + count, names.size())): clips.append(lib + "/" + String(names[i]))
		p0.queue_free()
	for r in clips.size():
		var y := -r * DY
		var lb := Label3D.new(); lb.text = clips[r].get_file() if clips[r].contains("/") else clips[r]; lb.text = clips[r].split("/")[-1]
		lb.font_size = 64; lb.pixel_size = 0.004; lb.modulate = Color(0.1, 0.1, 0.15); lb.outline_size = 0
		lb.position = Vector3(-1.6, y + 1.0, 0); lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; root.add_child(lb)
		for c in COLS:
			var p: Node3D = ClassDB.instantiate(&"CityPed")
			p.set(&"body_id", body); p.set(&"clip", String(clips[r]))
			p.position = Vector3(c * DX, y, 0); p.rotation.y = 0.5
			root.add_child(p)
			p.set_meta("u", float(c) / float(COLS - 1))
	var cam := Camera3D.new(); cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = maxf(clips.size() * DY + 0.6, 6.0)
	cam.position = Vector3((COLS - 1) * DX * 0.5 - 0.8, -(clips.size() - 1) * DY * 0.5 + 0.9, 20); root.add_child(cam); cam.current = true

func _process(_d: float) -> bool:
	n += 1
	for p in root.get_children():
		if p.get_class() != "CityPed": continue
		var ap: Array = p.find_children("*", "AnimationPlayer", true, false)
		if ap.is_empty(): continue
		var a: AnimationPlayer = ap[0]
		var c := String(p.get(&"clip"))
		if not a.has_animation(c): continue
		p.set(&"clip_at", float(p.get_meta("u", 0.0)) * a.get_animation(c).length * 0.999)
	if n < 8: return false
	root.get_texture().get_image().save_png(out)
	print("SHEET %d clips: %s" % [clips.size(), out])
	quit(0); return true
