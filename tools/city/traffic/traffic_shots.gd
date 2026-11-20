extends SceneTree
## Pictures of the traffic and the parked cars on the PC, from set viewpoints (a check tool, not the game):
##   godot --path . --rendering-method mobile --resolution 1280x720 -s res://tools/city/traffic/traffic_shots.gd -- --out=OUT/shots [--night] [--cars=60] [--density=1.0] [--view=name] [--noparked] [--at=name,x,h,z,lx,lh,lz,sec]
## It builds what the test app builds (the streamer, the look, the C++ traffic node), stands at each viewpoint for a
## few seconds so the traffic settles, and saves a PNG. Needs the bake, streets.bin and the native module.
const STREAM_CLASS := &"CityStream"      # the streamer is C++ since 20 Nov (native/src/city_stream.*)
const Look := preload("res://tools/city/look/look.gd")
## name, camera x, height above the street, z, look at x, height, z, seconds to wait
const VIEWS := [
	["residential_kerb_parking", -797.0, 1.6, -1090.0, -800.0, 0.8, -1020.0, 6.0],
	["residential_stop_junction", -812.0, 4.0, -1030.0, -800.0, 0.5, -1000.0, 14.0],
	["arterial_signal_3rd_st", -630.0, 5.0, -1392.0, -600.0, 0.5, -1400.0, 16.0],
	["arterial_from_the_kerb", -560.0, 1.6, -1390.0, -500.0, 1.0, -1397.0, 10.0],
	["amber_centre", 6.0, 1.7, -690.0, 4.0, 1.0, -600.0, 12.0],
	["amber_high_street_parking", 8.0, 1.6, -150.0, 9.0, 0.8, -60.0, 8.0],
	["strip_car_park", 470.0, 6.0, -1240.0, 440.0, 0.5, -1180.0, 6.0],
	["city_from_above", -40.0, 60.0, -700.0, 0.0, 0.0, -600.0, 12.0]]

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var views: Array = VIEWS
	var out := "OUT/shots"; var night := false; var cars := 60; var density := 1.0; var only := ""; var parked := true
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
		if a == "--night": night = true
		if a.begins_with("--cars="): cars = int(a.trim_prefix("--cars="))
		if a.begins_with("--density="): density = float(a.trim_prefix("--density="))
		if a.begins_with("--view="): only = a.trim_prefix("--view=")
		if a == "--noparked": parked = false
		if a.begins_with("--at="):      # one more viewpoint: --at=name,x,height,z,look x,look height,look z,seconds
			var q := a.trim_prefix("--at=").split(","); var row: Array = [q[0]]
			for i in range(1, 8): row.append(float(q[i]))
			views = [row]
	if not ClassDB.class_exists(&"CityTraffic"):
		print("SHOTS ERROR the native module is not built"); quit(1); return
	var world := Node3D.new(); root.add_child(world)
	var look: Node = Look.new(); world.add_child(look)
	var gp := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(6000, 6000); gp.mesh = pm
	var gm := StandardMaterial3D.new(); gm.albedo_color = Color(0.36, 0.42, 0.3); gp.material_override = gm; gp.position.y = -2.0; world.add_child(gp)
	var st: Node3D = ClassDB.instantiate(STREAM_CLASS); world.add_child(st)
	if look.has_method(&"attach_stream"): look.attach_stream(st)
	var cam := Camera3D.new(); cam.fov = 74.0; cam.near = 0.08; cam.far = 900.0; world.add_child(cam); cam.current = true
	var tr: Node = ClassDB.instantiate(&"CityTraffic")
	tr.set(&"max_cars", cars); tr.set(&"density", density); tr.set(&"parked", parked)
	tr.call(&"attach", st); world.add_child(tr)
	st.set_night(1.0 if night else 0.0); look.set_night(1.0 if night else 0.0); tr.set(&"night", 1.0 if night else 0.0)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + out))
	for v: Array in views:
		if only != "" and String(v[0]) != only: continue
		var p := Vector3(float(v[1]), 0, float(v[3]))
		st.update_focus(p, true)
		# the street's height there: the baked ground's collision is in after a few physics frames
		var gy := 4.0
		for i in 20:
			await physics_frame
			var hit := world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x, 80, p.z), Vector3(p.x, -20, p.z), 0xFFFFFFEF))
			if hit.has("position"): gy = float(hit.position.y)
		cam.global_position = Vector3(p.x, gy + float(v[2]), p.z)
		cam.look_at(Vector3(float(v[4]), gy + float(v[5]), float(v[6])))
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < int(float(v[7]) * 1000.0):
			st.update_focus(p, false); await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		img.save_png("res://%s/%s%s.png" % [out, String(v[0]), "_night" if night else ""])
		var R := RenderingServer
		print("SHOTS %s: draws %d, triangles %dk | %s" % [String(v[0]), R.get_rendering_info(R.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), R.get_rendering_info(R.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME) / 1000, String(tr.call(&"report"))])
	print("SHOTS done")
	quit()
