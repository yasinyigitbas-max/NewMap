extends RefCounted
## Pictures from set viewpoints for a before / after pair (rig option --shots=FOLDER). The rig stands at each view
## by day and at night and saves <view>_<day|night>_<before|after>.jpg: "after" with --look=1, "before" with --look=0.
## Run it twice, once each (docs/LOOK_SKY.md has the commands). Pictures are 1640 x 720 (the phone's 720p picture).
##   --views=name:x,z:yaw[:pitch];...   views of your own instead of the list (yaw 0 looks north (-Z), 90 east (+X))
##   --times=day | night                only one of the two
##   --hold=40                          frames to wait before a picture is taken
## [name, x, z, yaw, pitch]: street level, eye 1.6 m over the road.
const VIEWS := [
	["centre", 0.0, -560.0, 0.0, 4.0],            # Amber Ave, looking north through the junction with 7th St (0, -600)
	["apartments", 215.0, -600.0, 90.0, 5.0],     # 7th St, looking east through the apartments junction (250, -600)
	["gritty", -600.0, -960.0, 0.0, 3.0],         # the gritty edge, looking north through its junction (-600, -1000)
	["waterfront", 535.0, 200.0, 75.0, 2.0]]      # the waterfront (570, 200)
const SIZE := Vector2i(1640, 720)

static func run(rig: Node, folder: String, args: PackedStringArray) -> void:
	var views: Array = VIEWS; var times: Array = [0.0, 1.0]; var hold := 40
	for a in args:
		if a.begins_with("--views="):
			views = []
			for q in a.trim_prefix("--views=").split(";", false):
				var f := q.split(":"); var xz := f[1].split_floats(",")
				views.append([f[0], xz[0], xz[1], float(f[2]) if f.size() > 2 else 0.0, float(f[3]) if f.size() > 3 else 3.0])
		if a == "--times=day": times = [0.0]
		if a == "--times=night": times = [1.0]
		if a.begins_with("--hold="): hold = int(a.trim_prefix("--hold="))
	var dir := ProjectSettings.globalize_path(folder) if folder.begins_with("res://") or folder.begins_with("user://") else folder
	DirAccess.make_dir_recursive_absolute(dir)
	var tag := "after" if int(rig.opt.look) == 1 else "before"
	var tree := rig.get_tree(); var vp := rig.get_viewport()
	rig.hud.visible = false
	for night: float in times:
		rig._night(night)
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
			if night > 0.05: rig.lights.update_lights(rig.cam.global_position, night)
			for i in hold: await tree.process_frame
			await RenderingServer.frame_post_draw
			var img := vp.get_texture().get_image()
			if img.get_size() != SIZE: img.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
			img.convert(Image.FORMAT_RGB8)
			var path := dir.path_join("%s_%s_%s.jpg" % [v[0], "night" if night > 0.5 else "day", tag])
			img.save_jpg(path, 0.9)
			rig._say("shot %s look=%d ground=%.1f draws=%d window=%s" % [path.get_file(), int(rig.opt.look), gy, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), str(vp.get_texture().get_size())])
	rig._say("shots_done %s" % dir)
