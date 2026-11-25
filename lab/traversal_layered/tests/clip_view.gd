## Test tool: plays one clip from a clip cache on player_v3 (raw clip + its root motion, no locomotion layers) and
## saves a strip of screenshots. Needs a display (xvfb-run) and opengl3.
##   godot --path . --rendering-driver opengl3 -s tests/clip_view.gd -- <cache.bin> <clip> <out.png> [side|front|back] [frames]
extends SceneTree
var sk: Skeleton3D; var body: Node3D; var cam: Camera3D
var clip: Dictionary; var B: int; var f := 0; var shots := []; var times := []
var out := ""; var view := "side"; var nshots := 8
func _init():
	var a := OS.get_cmdline_user_args()
	var fa := FileAccess.open(a[0], FileAccess.READ)
	var d: Dictionary = fa.get_var()
	clip = d.clips[a[1]]; out = a[2]
	if a.size() > 3: view = a[3]
	if a.size() > 4: nshots = int(a[4])
	B = clip.bones
	var world := Node3D.new(); root.add_child(world)
	world.add_child(load("res://scenes/course.tscn").instantiate())
	body = load("res://body/player_v3.glb").instantiate(); world.add_child(body)
	body.position = Vector3(-60, 0, 60)
	sk = body.get_node("Armature/Skeleton3D")
	cam = Camera3D.new(); world.add_child(cam); cam.current = true; cam.fov = 50
	var nf: int = clip.frames
	for i in nshots: times.append(int(round(float(i) * (nf - 1) / max(nshots - 1, 1))))
	process_frame.connect(_tick)
func _tick():
	if f >= clip.frames:
		_save(); quit(); return
	var rot: PackedFloat32Array = clip.rot; var hips: PackedFloat32Array = clip.hips; var rt: PackedFloat32Array = clip.root
	for i in B:
		var o: int = (f * B + i) * 4
		sk.set_bone_pose_rotation(i, Quaternion(rot[o], rot[o + 1], rot[o + 2], rot[o + 3]))
	sk.set_bone_pose_position(0, Vector3(hips[f * 3], hips[f * 3 + 1], hips[f * 3 + 2]))
	body.position = Vector3(-60 + rt[f * 3], 0, 60 + rt[f * 3 + 1])
	body.rotation = Vector3(0, rt[f * 3 + 2], 0)
	var c := body.position + Vector3(0, 0.95, 0)
	var off := Vector3(3.2, 0.3, 0) if view == "side" else (Vector3(0, 0.3, 3.2) if view == "front" else Vector3(0, 0.6, -3.2))
	cam.look_at_from_position(c + off, c)
	if f in times:
		await RenderingServer.frame_post_draw
		shots.append(root.get_texture().get_image())
	f += 1
func _save():
	if shots.is_empty(): return
	var w: int = 360; var h: int = 480
	var strip := Image.create(w * shots.size(), h, false, Image.FORMAT_RGB8)
	for i in shots.size():
		var im: Image = shots[i]
		im.convert(Image.FORMAT_RGB8)
		var cw := int(im.get_width() * 0.36); var x0 := (im.get_width() - cw) / 2
		var crop := im.get_region(Rect2i(x0, 0, cw, im.get_height()))
		crop.resize(w, h)
		strip.blit_rect(crop, Rect2i(0, 0, w, h), Vector2i(i * w, 0))
	strip.save_png(out)
