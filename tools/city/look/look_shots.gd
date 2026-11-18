extends RefCounted
## Pictures from set viewpoints for a before / after pair (rig option --shots=FOLDER). The rig stands at each view
## by day and at night and saves <view>_<day|night>_<before|after>.jpg: "after" with --look=1, "before" with --look=0.
## Run it twice, once each (docs/LOOK_SKY.md has the commands). Pictures are 1640 x 720 (the phone's 720p picture).
## With a time of day (--look=golden) or a list (--presets=morning,noon,golden,dusk,night,overcast) it saves
## <view>_<preset>.jpg instead, every preset at each view (the cells are loaded once per view).
##   --views=name:x,z:yaw[:pitch];...   views of your own instead of the list (yaw 0 looks north (-Z), 90 east (+X))
##   --times=day | night                only one of the two
##   --hold=40                          frames to wait before a picture is taken
##   --fullsize                         keep the window's size (e.g. 2460 x 1080 to judge the upscaler) instead of 1640 x 720
## With --upscale=1 the file names end in _sgsr, with --glow=0 (and the look) in _glow0.
## [name, x, z, yaw, pitch]: street level, eye 1.6 m over the road.
const VIEWS := [
	["centre", -6.0, -560.0, 0.0, 4.0],           # Amber Ave (west lane; the median has palms), looking north through 7th St (0, -600)
	["apartments", 215.0, -600.0, 90.0, 5.0],     # 7th St, looking east through the apartments junction (250, -600)
	["gritty", -600.0, -960.0, 0.0, 3.0],         # the gritty edge, looking north through its junction (-600, -1000)
	["waterfront", 535.0, 200.0, 75.0, 2.0]]      # the waterfront (570, 200)
const SIZE := Vector2i(1640, 720)

static func run(rig: Node, folder: String, args: PackedStringArray) -> void:
	var views: Array = VIEWS; var times: Array = [0.0, 1.0]; var hold := 40; var presets: Array = []; var full := "--fullsize" in args
	for a in args:
		if a.begins_with("--views="):
			views = []
			for q in a.trim_prefix("--views=").split(";", false):
				var f := q.split(":"); var xz := f[1].split_floats(",")
				views.append([f[0], xz[0], xz[1], float(f[2]) if f.size() > 2 else 0.0, float(f[3]) if f.size() > 3 else 3.0])
		if a == "--times=day": times = [0.0]
		if a == "--times=night": times = [1.0]
		if a.begins_with("--hold="): hold = int(a.trim_prefix("--hold="))
		if a.begins_with("--presets="): presets = Array(a.trim_prefix("--presets=").split(",", false))
	var lk := String(rig.opt.look)
	if presets.is_empty() and not (lk in ["0", "1"]): presets = [lk]
	if not presets.is_empty() and rig.look == null: rig._say("ERROR --presets needs the look (--look=1)"); return
	var dir := ProjectSettings.globalize_path(folder) if folder.begins_with("res://") or folder.begins_with("user://") else folder
	DirAccess.make_dir_recursive_absolute(dir)
	var tag := ("after_bloom" if int(rig.opt.bloom) == 1 else "after") if lk != "0" else "before"
	var conds: Array = []      # [file name part, preset or "", night]
	if presets.is_empty():
		for n: float in times: conds.append(["%s_%s" % ["night" if n > 0.5 else "day", tag], "", n])
	else:
		for pr: String in presets: conds.append([pr + ("_bloom" if int(rig.opt.bloom) == 1 else ""), pr, 0.0])
	var tree := rig.get_tree(); var vp := rig.get_viewport()
	rig.hud.visible = false
	for v: Array in views:
		var p := Vector3(float(v[1]), 0.0, float(v[2]))
		rig.st.update_focus(p, true)                       # the whole neighbourhood at once
		rig._g_hit = false; rig._g_at = p
		var gy := 0.0
		for i in 600:                                      # until the road can be stood on (collision arrives in steps)
			rig.st.update_focus(p, false)
			await tree.physics_frame
			await tree.process_frame
			if rig.st.is_ready(p) and rig._g_hit: gy = rig._g_y; break
		for i in 4: await tree.physics_frame
		if rig._g_hit: gy = rig._g_y
		var yaw := deg_to_rad(float(v[3])); var pitch := deg_to_rad(float(v[4]))
		var fwd := Vector3(sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))
		rig.cam.global_position = Vector3(p.x, gy + 1.6, p.z); rig.cam.look_at(rig.cam.global_position + fwd * 50.0)
		for c: Array in conds:
			if String(c[1]) != "": rig.look.set_preset(String(c[1]))
			rig._night(float(c[2]))
			var lit: float = rig.look.lights() if rig.look else float(c[2])
			rig.lights.update_lights(rig.cam.global_position, lit)
			for i in hold: await tree.process_frame
			await RenderingServer.frame_post_draw
			var img := vp.get_texture().get_image()
			if not full and img.get_size() != SIZE: img.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
			img.convert(Image.FORMAT_RGB8)
			var path := dir.path_join("%s_%s%s%s.jpg" % [v[0], c[0], "_sgsr" if int(rig.opt.upscale) == 1 else "", "_glow0" if int(rig.opt.glow) == 0 and lk != "0" else ""])
			img.save_jpg(path, 0.9)
			rig._say("shot %s look=%s ground=%.1f draws=%d" % [path.get_file(), lk, gy, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
	rig._say("shots_done %s" % dir)
