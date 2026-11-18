extends Node3D
## PHONE TEST RIG for the baked city and its streamer (18 Nov). The project's main scene, so an Android export of this
## repo IS the test app. It drives a camera along routes through the city at set speeds, with the streamer live, and
## reports what a player would feel: frame times, slow frames and what the streamer was doing in them, late cells,
## draw calls, triangles, memory. No game code: it measures the MAP.
## Results: "RIG ..." lines in the log (adb logcat -s godot) and user://rig/summary_<n>.txt. tools/city/rig/phone_rig.sh
## builds, installs, runs and collects.
## Options: user args on the PC (after --), or the file user://rig_args.txt on the phone (the script writes it):
##   --plan=default|quick|speed|zones   which list of drives (zones: teleports between the populated zones)      --scale=0.667  3D render scale; default: 720 lines high on any screen (Yasin 18 Nov: "default resolution 720p")
##   --drive=NAME/ROUTE/SPEED_KMH/SECONDS/NIGHT   a drive of your own, as often as you like, instead of a plan: no
##             rebuild needed for a new route. ROUTE is a route name or points x,z:x,z:... (NIGHT 0 or 1), e.g.
##             --drive=gritty/-740,-1000:-600,-1000:-600,-860/60/25/0
##   --quit    leave when the plan is done (default with a plan from the args file; by hand it loops)
##   --lead=2  --maxcells=30  --loading=2  --bodies=2      streamer settings to compare
##   --lights=20   real lamp lights at night (the engine's light grid; 8 on a stock engine)
##   --nowarm      skip the warm-up (to see what it saves)
const Stream := preload("res://tools/city/bake/city_stream.gd")
const Lights := preload("res://tools/city/bake/city_lights.gd")
const ROUTES := {"zigzag": "-900,-1400;500,-1400;500,-1000;-900,-1000;-900,-600;500,-600;500,-200;-900,-200",
	"ring": "-950,-1550;600,-1550;600,150;-950,150;-950,-1550", "amber": "0,-1580;0,180", "seventh": "-950,-600;600,-600",
	"centre": "-380,-600;460,-600;460,-640;-380,-640;-380,-600",
	# The populated zones (Yasin 18 Nov: "the test was mostly in empty ground ... make it teleport between gritty, city
	# center, waterfront etc"). Each zone's sample junction (city_grid_layout.json "sample X"), driven along its own
	# streets (zoning/grading.json): in on one arm, through the junction, out and back on the others. Closed loops.
	"z_gritty": "-740,-1000;-600,-1000;-600,-860;-600,-1000;-460,-1000;-600,-1000;-600,-1140;-600,-1000;-740,-1000",
	"z_centre": "-140,-600;0,-600;0,-460;0,-600;140,-600;0,-600;0,-740;0,-600;-140,-600",
	"z_waterfront": "430,200;570,200;608,65;570,200;430,200",
	"z_industrial": "-940,-1400;-800,-1400;-800,-1260;-800,-1400;-660,-1400;-800,-1400;-800,-1540;-800,-1400;-940,-1400",
	"z_apartments": "110,-600;250,-600;250,-460;250,-600;390,-600;250,-600;250,-740;250,-600;110,-600",
	"z_pilot": "-140,0;0,0;0,140;0,0;140,0;0,0;0,-140;0,0;-140,0",
	"z_strip": "360,-1200;500,-1200;500,-1060;500,-1200;640,-1200;500,-1200;500,-1340;500,-1200;360,-1200",
	"z_civic": "-340,-600;-200,-600;-200,-740;-200,-600;-60,-600;-200,-600;-340,-600",
	"z_stadium": "-400,-560;-400,-200;-200,-200;-400,-200;-400,-560",
	"seventh_pop": "-400,-600;500,-600;-400,-600"}
## [name, route, speed m/s, seconds, night 0..1]
const PLANS := {
	"default": [["town_50kmh", "zigzag", 14.0, 60.0, 0.0], ["ring_108kmh", "ring", 30.0, 45.0, 0.0], ["cross_210kmh", "zigzag", 58.0, 35.0, 0.0],
		["ring_280kmh", "ring", 78.0, 35.0, 0.0], ["centre_night_50kmh", "centre", 14.0, 40.0, 1.0]],
	"quick": [["town_50kmh", "seventh", 14.0, 20.0, 0.0], ["cross_280kmh", "seventh", 78.0, 15.0, 0.0]],
	# far jumps on purpose: every teleport throws the loaded cells away and needs a whole new neighbourhood
	"zones": [["gritty_60kmh", "z_gritty", 16.7, 25.0, 0.0], ["centre_60kmh", "z_centre", 16.7, 25.0, 0.0], ["waterfront_60kmh", "z_waterfront", 16.7, 25.0, 0.0], ["industrial_60kmh", "z_industrial", 16.7, 25.0, 0.0], ["apartments_60kmh", "z_apartments", 16.7, 25.0, 0.0], ["pilot_60kmh", "z_pilot", 16.7, 25.0, 0.0], ["strip_60kmh", "z_strip", 16.7, 25.0, 0.0], ["civic_60kmh", "z_civic", 16.7, 25.0, 0.0], ["stadium_60kmh", "z_stadium", 16.7, 25.0, 0.0],
		["seventh_210kmh", "seventh_pop", 58.0, 20.0, 0.0], ["centre_night_60kmh", "z_centre", 16.7, 25.0, 1.0], ["gritty_night_60kmh", "z_gritty", 16.7, 25.0, 1.0]],
	"speed": [["ring_108kmh", "ring", 30.0, 60.0, 0.0], ["ring_210kmh", "ring", 58.0, 60.0, 0.0], ["ring_280kmh", "ring", 78.0, 60.0, 0.0], ["ring_360kmh", "ring", 100.0, 40.0, 0.0]]}

var st: Node3D
var lights: Node3D
var cam: Camera3D
var hud: Label
var sun: DirectionalLight3D
var env: Environment
var opt := {"plan": "default", "scale": 0.0, "quit": false, "lead": 2.0, "maxcells": 30, "loading": 2, "bodies": 2, "lights": 20, "nowarm": false}
var out_lines: PackedStringArray = []
var own_drives: Array = []      # from --drive=...: used instead of the plan

func _say(s: String) -> void:
	print("RIG " + s); out_lines.append(s)

func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var from_file := false
	if FileAccess.file_exists("user://rig_args.txt"):
		args.append_array(FileAccess.get_file_as_string("user://rig_args.txt").replace("\n", " ").split(" ", false)); from_file = true
	for a in args:
		if a == "--quit": opt.quit = true
		if a == "--nowarm": opt.nowarm = true
		if a.begins_with("--drive="):
			var f := a.trim_prefix("--drive=").split("/")
			if f.size() == 5: own_drives.append([f[0], f[1], float(f[2]) / 3.6, float(f[3]), float(f[4])])
			else: push_warning("RIG: --drive needs NAME/ROUTE/SPEED_KMH/SECONDS/NIGHT, got: " + a)
		for k: String in ["plan", "scale", "lead", "maxcells", "loading", "bodies", "lights"]:
			if a.begins_with("--%s=" % k):
				var v := a.trim_prefix("--%s=" % k)
				opt[k] = v if k == "plan" else (float(v) if k in ["scale", "lead"] else int(v))
	if from_file and not ("--loop" in args): opt.quit = true
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if float(opt.scale) <= 0.0:      # no --scale given: 720p (1640x720 on the Redmi's 2460x1080)
		var ws := DisplayServer.window_get_size(); opt.scale = clampf(720.0 / maxf(1.0, float(mini(ws.x, ws.y))), 0.25, 1.0)
	var vp := get_viewport(); vp.scaling_3d_scale = float(opt.scale); vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	env = Environment.new()
	var sky := Sky.new(); sky.sky_material = ProceduralSkyMaterial.new(); env.background_mode = Environment.BG_SKY; env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.62, 0.66, 0.72); env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	sun = DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-48, -35, 0); sun.light_energy = 1.25
	sun.shadow_enabled = true; sun.directional_shadow_max_distance = 50.0; add_child(sun)      # the game's sun shadow distance
	var gp := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(6000, 6000); gp.mesh = pm
	var gm := StandardMaterial3D.new(); gm.albedo_color = Color(0.36, 0.42, 0.3); gm.roughness = 1.0; gp.material_override = gm; gp.position.y = -0.05; add_child(gp)
	st = Stream.new(); st.name = "City"; st.lead_seconds = float(opt.lead); st.max_cells = int(opt.maxcells); st.max_loading = int(opt.loading); st.bodies_per_frame = int(opt.bodies); add_child(st)
	lights = Lights.new(); lights.budget = int(opt.lights); lights.stream = st; add_child(lights)
	cam = Camera3D.new(); cam.fov = 74.0; cam.near = 0.08; cam.far = 900.0; add_child(cam); cam.current = true      # the game's driving camera
	var layer := CanvasLayer.new(); add_child(layer)
	hud = Label.new(); hud.position = Vector2(24, 24); hud.add_theme_font_size_override("font_size", 26); hud.add_theme_color_override("font_outline_color", Color.BLACK); hud.add_theme_constant_override("outline_size", 8); layer.add_child(hud)
	_run.call_deferred()

func _pts(route: String) -> Array:
	var out: Array = []
	for q in String(ROUTES.get(route, route)).replace(":", ";").split(";", false):
		var f := q.split_floats(","); out.append(Vector3(f[0], 0, f[1]))
	return out

## Ground height under p. The ray is cast in _physics_process and read here one physics tick later: on the phone the
## physics runs on its own thread (Jolt) and the space may only be asked from the physics step. Asked from a normal
## frame it fails every frame (first phone run, 18 Nov: 5,000 errors and the camera sunk into the road).
var _g_at := Vector3.ZERO
var _g_y := 0.0
var _g_hit := false

func _physics_process(_dt: float) -> void:
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(_g_at.x, 80, _g_at.z), Vector3(_g_at.x, -20, _g_at.z)))
	_g_hit = hit.has("position")
	if _g_hit: _g_y = float(hit.position.y)

func _ground(p: Vector3, last: float) -> float:
	_g_at = p
	return _g_y if _g_hit else last

func _night(v: float) -> void:
	st.set_night(v)
	sun.light_energy = lerpf(1.25, 0.04, v); env.ambient_light_energy = lerpf(0.75, 0.22, v)
	(env.sky.sky_material as ProceduralSkyMaterial).sky_top_color = Color(0.32, 0.52, 0.82).lerp(Color(0.01, 0.015, 0.04), v)
	(env.sky.sky_material as ProceduralSkyMaterial).sky_horizon_color = Color(0.72, 0.8, 0.88).lerp(Color(0.05, 0.06, 0.1), v)

func _run() -> void:
	var R := RenderingServer
	_say("start engine=%s device=%s gpu=%s screen=%s scale=%.2f plan=%s lead=%.1f maxcells=%d loading=%d bodies=%d lights=%d cells_baked=%d" % [Engine.get_version_info().string, OS.get_model_name(), R.get_video_adapter_name(), str(DisplayServer.window_get_size()), float(opt.scale), opt.plan, float(opt.lead), int(opt.maxcells), int(opt.loading), int(opt.bodies), int(opt.lights), st.cells.size()])
	if st.cells.is_empty():
		_say("ERROR no baked city found (map_dc/coronado/city_kit/runtime). Run the bake before the export."); hud.text = "no baked city in this build"
		if opt.quit: await get_tree().create_timer(3.0).timeout; get_tree().quit()
		return
	var plan: Array = PLANS.get(String(opt.plan), PLANS.default)
	if not own_drives.is_empty(): plan = own_drives; _say("own drives: %d" % plan.size())
	var first: Vector3 = _pts(plan[0][1])[0]
	var t0 := Time.get_ticks_msec()
	cam.global_position = first + Vector3(0, 8, 0); cam.look_at(cam.global_position + Vector3(0, 0, -50))
	st.update_focus(first, true)
	var t1 := Time.get_ticks_msec()
	if not opt.nowarm: await st.warm_up(cam, 4)
	for i in 10: await get_tree().process_frame
	_say("boot first_area_ms=%d warm_ms=%d cells=%d static_mb=%.0f video_mb=%.0f" % [t1 - t0, Time.get_ticks_msec() - t1, st.loaded_count(), Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, R.get_rendering_info(R.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0])
	var lap := 0
	while true:
		for seg: Array in plan: await _drive(seg)
		lap += 1
		_say("plan_done lap=%d" % lap)
		DirAccess.make_dir_recursive_absolute("user://rig")
		var f := FileAccess.open("user://rig/summary_%d.txt" % lap, FileAccess.WRITE)
		if f: f.store_string("\n".join(out_lines)); f.close()
		if opt.quit: break
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()

func _drive(seg: Array) -> void:
	var R := RenderingServer
	var name := String(seg[0]); var pts := _pts(seg[1]); var sp := float(seg[2]); var secs := float(seg[3])
	_night(float(seg[4]))
	# get the start ready before going there (what a respawn or a mission start would do), and time it
	var tp := Time.get_ticks_msec()
	st.prepare(pts[0])
	var prep_worst := 0.0; var tq := Time.get_ticks_usec()      # the frames while the new place loads (the player still sees the old one)
	while not st.is_ready(pts[0]):
		st.update_focus(st.focus, false); hud.text = "%s: getting the start ready" % name
		await get_tree().process_frame
		var nq := Time.get_ticks_usec(); prep_worst = maxf(prep_worst, (nq - tq) / 1000.0); tq = nq
	st.release_prepared()
	var prep_ms := Time.get_ticks_msec() - tp
	var S0: Dictionary = st.stats.duplicate()
	var dts := PackedFloat32Array(); var draws_sum := 0.0; var draws_max := 0; var tris_sum := 0.0; var tris_max := 0
	var late220 := 0; var late60 := 0; var deepest := 0.0; var max_cells := 0; var slow := 0; var gy := 8.0
	var segi := 0; var along := 0.0; var t := 0.0; var t_prev := Time.get_ticks_usec(); var hud_t := 0.0; var prev := [S0["in"], S0.out, S0.bodies]
	var ready0: int = st.ready_ms.size()
	var on_ground := false; _g_hit = false; _g_at = pts[0]
	while t < secs:
		var a0: Vector3 = pts[segi]; var a1: Vector3 = pts[segi + 1]; var sl := a0.distance_to(a1)
		var p := a0.lerp(a1, clampf(along / sl, 0.0, 1.0)); var dir := (a1 - a0).normalized()
		var g := _ground(p, gy)
		if _g_hit and not on_ground: gy = g; on_ground = true      # the first answer: stand on the road at once, do not glide down (or up) to it
		gy = lerpf(gy, g, 0.2)
		cam.global_position = Vector3(p.x, gy + 1.3, p.z); cam.look_at(cam.global_position + dir * 50.0)
		st.update_focus(p, false, dir * sp)
		if float(seg[4]) > 0.05 and Engine.get_process_frames() % 15 == 0: lights.update_lights(cam.global_position, float(seg[4]))
		await get_tree().process_frame
		var now := Time.get_ticks_usec(); var dt := (now - t_prev) / 1000000.0; t_prev = now; t += dt; dts.append(dt * 1000.0)
		along += dt * sp
		while along >= (pts[segi] as Vector3).distance_to(pts[segi + 1]):
			along -= (pts[segi] as Vector3).distance_to(pts[segi + 1]); segi = (segi + 1) % (pts.size() - 1)
		var dr := int(R.get_rendering_info(R.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)); var tr := int(R.get_rendering_info(R.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
		draws_sum += dr; tris_sum += tr; draws_max = maxi(draws_max, dr); tris_max = maxi(tris_max, tr); max_cells = maxi(max_cells, st.loaded_count())
		for k: String in st.cells:
			if st.cells[k].state != st.IN:
				var dd: float = st._dist(k, p)
				if dd < 60.0: late60 += 1
				if dd < 220.0: late220 += 1; deepest = maxf(deepest, 220.0 - dd)
		var S: Dictionary = st.stats
		if dt > 0.0333 and slow < 15:      # a frame a player would notice (over 33 ms since the zones run; 50 ms before): what was the streamer doing?
			slow += 1
			_say("slow %s %.0f ms at t=%.1f s pos=(%.0f, %.0f): cells in +%d out +%d, bodies +%d, loading %s" % [name, dt * 1000.0, t, p.x, p.z, int(S["in"]) - int(prev[0]), int(S.out) - int(prev[1]), int(S.bodies) - int(prev[2]), str(st.loading_keys())])
		prev = [S["in"], S.out, S.bodies]
		hud_t += dt
		if hud_t > 0.25:
			hud_t = 0.0
			hud.text = "%s  %.0f km/h  %.0f s left\n%.0f fps  %.1f ms\ndraws %d  tris %dk  cells %d" % [name, sp * 3.6, secs - t, 1.0 / maxf(dt, 0.0001), dt * 1000.0, dr, tr / 1000, st.loaded_count()]
	var n := dts.size(); var sorted := dts.duplicate(); sorted.sort()
	var o17 := 0; var o33 := 0; var o50 := 0; var o100 := 0
	for d: float in dts:
		if d > 16.7: o17 += 1
		if d > 33.3: o33 += 1
		if d > 50.0: o50 += 1
		if d > 100.0: o100 += 1
	var S1: Dictionary = st.stats; var rs := 0.0; var rw := 0.0
	for i in range(ready0, st.ready_ms.size()): rs += st.ready_ms[i]; rw = maxf(rw, st.ready_ms[i])
	_say("drive %s speed=%.0f km/h secs=%.0f frames=%d fps=%.1f | frame_ms med=%.1f p95=%.1f p99=%.1f worst=%.0f | over16.7=%.1f%% over33=%d over50=%d over100=%d" % [name, sp * 3.6, t, n, n / t, sorted[n / 2], sorted[int(n * 0.95)], sorted[int(n * 0.99)], sorted[n - 1], 100.0 * o17 / n, o33, o50, o100])
	_say("  map %s draws avg=%.0f max=%d | tris avg=%.0fk max=%dk | cells most=%d in=%d out=%d dropped=%d cap_hits=%d" % [name, draws_sum / n, draws_max, tris_sum / n / 1000.0, tris_max / 1000, max_cells, int(S1["in"]) - int(S0["in"]), int(S1.out) - int(S0.out), int(S1.dropped) - int(S0.dropped), int(S1.capped) - int(S0.capped)])
	_say("  stream %s start_ready_ms=%d (worst frame meanwhile %.0f ms) | request_to_in ms mean=%.0f worst=%.0f | late frames: 220m=%d (deepest %.0f m) 60m=%d | main thread worst ms: cell add %.2f, body %.2f, removal step %.2f | bodies late=%d" % [name, prep_ms, prep_worst, rs / maxf(1.0, st.ready_ms.size() - ready0), rw, late220, deepest, late60, float(S1.add_ms_worst), float(S1.body_ms_worst), float(S1.remove_ms_worst), int(S1.body_late) - int(S0.body_late)])
	_say("  mem %s static_mb=%.0f video_mb=%.0f tex_mb=%.0f buf_mb=%.0f" % [name, Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, R.get_rendering_info(R.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0, R.get_rendering_info(R.RENDERING_INFO_TEXTURE_MEM_USED) / 1048576.0, R.get_rendering_info(R.RENDERING_INFO_BUFFER_MEM_USED) / 1048576.0])
