extends Node3D
## PHONE TEST RIG for the baked city and its streamer (18 Nov). The project's main scene, so an Android export of this
## repo IS the test app. It drives a camera along routes through the city at set speeds, with the streamer live, and
## reports what a player would feel: frame times, slow frames and what the streamer was doing in them, late cells,
## draw calls, triangles, memory. No game code: it measures the MAP.
## Results: "RIG ..." lines in the log (adb logcat -s godot) and user://rig/summary_<n>.txt. tools/city/rig/phone_rig.sh
## builds, installs, runs and collects.
## Options: user args on the PC (after --), or the file user://rig_args.txt on the phone (the script writes it):
##   --plan=default|quick|speed|zones|stream   which list of drives (zones: teleports between the populated zones; stream: a loop through them at 108, 210, 280 km/h)      --scale=0.667  3D render scale; default: 720 lines high on any screen (Yasin 18 Nov: "default resolution 720p")
##   --drive=NAME/ROUTE/SPEED_KMH/SECONDS/NIGHT   a drive of your own, as often as you like, instead of a plan: no
##             rebuild needed for a new route. ROUTE is a route name or points x,z:x,z:... (NIGHT 0 or 1), e.g.
##             --drive=gritty/-740,-1000:-600,-1000:-600,-860/60/25/0
##   --car=NAME[/V]   DRIVE IT YOURSELF instead of a plan (19 Nov; C++ class CityCar, native/src/city_car.* + veh_dyn.*: the
##             physical car; this script only makes the node and tells the streamer where it is). NAME: stern_g, stern_e,
##             volt_s, volt_x, sakura, sakura_t, van, fiamma_r, fiamma_gt, taxi, bus_city, bus_mini; /V = the GTA 5 feel
##             (flatter, more grip), without it the GTA 4 feel (soft, leans, slides). W A S D or the arrows, Space =
##             handbrake, S reverses once it stands, a pad works too, Esc leaves. --at=x,z,yaw where it starts (yaw in
##             degrees, 0 = facing +z). With --traffic=N the traffic sees it and brakes for it
##   --quit    leave when the plan is done (default with a plan from the args file; by hand it loops)
##   --lead=2  --maxcells=30  --loading=2  --bodies=6  --coltris=1200  --colms=2     streamer settings to compare
##   --lights=20   real lamp lights at night (the engine's light grid; 8 on a stock engine)
##   --nowarm      skip the warm-up (to see what it saves)
##   --colrange=100  collision this near the player / the lead / a teleport's destination first, the rest in quiet frames (default); 0 = all alike
##   --colnobg     with a range: farther collision is NOT made in the background (the first try; it gave draw stalls)
##   --boost=4     collision budgets a frame times this while a teleport's destination is being prepared (1 = as before)
##   --nowarmnight skip drawing the night once in the warm-up (on by default since 19 Nov: it removes the first dusk's hitch)
##   --look=1|0|NAME  1 (default): the look pack's sky, distance haze, light colours and colour treatment
##             (tools/city/look/look.gd, docs/LOOK_SKY.md); 0: the old plain sky and light, to compare;
##             NAME a time of day of the look: morning, noon, day, golden, dusk, night, overcast (overrides the drives' night)
##   --cycle=120   with the look: a running day, the whole day in this many seconds (0 = off); --clock=7.0 its start hour.
##             Overrides the drives' night. Smooth: the sky and its maps step every 0.5 s, nothing jumps
##   --celestial=1|0  with the look: 1 (default) sun glare, a moon with its own light, stars rising with the dusk; 0 the sky before
##   --weather=NAME  with the look: mist, hazy, storm or rain over the time of day (tools/city/look/weather.gd)
##   --cars=0|1    with the look: DEMO, the preview cars parked on the cells' stalls (one draw a car); --carenv=1|0 they
##             reflect the look's sky (1, default) or nothing (0, as before)
##   --shadowtune=1|0  with the look: the sun shadow's end fades out (30-50 m), 2 blended splits, softness by time; 0 = before
##   --look=day_half | day_clear   two more days to choose from (queue 3); --look=day is the default day
##   --air=0|1     with the look: gulls over the waterfront, a plane now and then, smoke and steam in the industrial zone
##             (tools/city/look/air.gd, one draw); OFF by default until measured
##   --sea=1|0     with the look: 1 (default) the look's sea (C++ CitySea) instead of the green plane under the water
##   --bloom=0|1   with --look=1: 1 adds a soft glow round bright things (GTA 4 style); costs pixels, off by default
##   --glow=1|0    with the look: 1 (default) the look's lamp halos and pools (tools/city/look/glow.gdshader), 0 the bake's
##   --blobs=0|1   with the look: 1 soft tree shadows beyond the 50 m sun shadow (look job 4); OFF by default: it reads
##             each cell's meshes when the cell comes in (hitches; for pictures, not for phone drives)
##   --wet=0..1    with the look: the rain mood (global ck_wet); above 0 the cells' ground is drawn by the look's DEMO
##             copy of rt_ground with the wet snippet (tools/city/look/sky_reflect.gdshaderinc), default 0
##   --upscale=0|1 1: the 720p picture is scaled up by SGSR 1 (edge-aware, sharpens) instead of plain bilinear. Needs
##             Yasin's engine (coronado_c_sgsr1 / all*: patch c); a stock engine ignores it with a warning (bilinear)
##   --sharp=0.2   with --upscale=1: the engine's fsr_sharpness, 0 sharpest .. 2 softest (SGSR edge sharpness 2.1 .. 1.1)
##   --reflect=1|0 1 (default): surfaces reflect the sky (as before); 0: no sky reflection (one cube-map read less a
##             pixel; the cloud preview needs it: its software GPU draws the trees black with sky reflections on)
##   --shots=FOLDER   no drive: save pictures from set viewpoints, by day and at night, and leave
##             (tools/city/look/look_shots.gd; run with --look=1 and with --look=0 for before / after pairs)
##   --gpureserve=192   MB of graphics memory the warm-up takes and gives back (0 = off)
##   --loader=0|1|2   0 the streamer's own loader threads (default); 1 / 2 the engine's pool without / with sub-threads
##   --probe       time the physics and render servers' digestion each frame (shown in the slow lines)
##   --nocol       never attach the cells' collision; --hide  add the cells hidden: the two switches that tell what a
##                 slow frame is made of (attaching collision, or the first drawing of a new cell)
##   THE TIERS (19 Nov, docs/RUNTIME_BAKE.md "The tiers"; all off by default = as before):
##   --tiers       the tier hand-over: fades at 60 m and 220 m, an arriving cell's objects take over nearest first
##                 (OFF by default again, 20 Nov evening, Yasin: "you can turn off that fade feature which was dropping the
##                 performance": the snaps came from mid / far looking unlike the near, fixed at the source by the LOD match
##                 tiers, tools/city/lod/lod_bake.py; hard cuts at 60 m / 220 m)
##   --band=8      with --tiers: metres of overlap at each switch (0 = hard cuts)     --arrive=0.5  seconds of the sweep
##   --nofarground hide the far world's ground (the streets beyond the loaded cells)
##   --plan=census no drives: the drawing cost census (see _census below; --census=day|night|both --views=a,b --censussecs=2; the night is drawn once at start unless --nowarmnight)
##   TRAFFIC (19 Nov, docs/TRAFFIC_PEOPLE_PORT.md; all C++, native/: needs  bash native/build.sh  and city_kit/traffic/streets.bin):
##   --walk=1|BODY  WALK IT YOURSELF (20 Nov; C++ class CityPlayer): a person on foot at --at=x,z[,deg], the camera behind
##             him; W A S D, Shift runs, the mouse turns, Esc leaves. BODY = a figure's name (M2 by default). With
##             --people the crowd steps aside for him and he can run into people; with --quit he walks ahead for 12 s.
##             --walkcrowd=N: N people are set down round him (a measure of the animated bodies' cost; the frame times
##             of the walk are printed at its end).
##             --water=Y: the height of the sea's surface (0, the sea's own, if not given); where it is deeper than
##             his chest he swims.
##   --people=N    the walking crowd, at most N people round the camera (C++ class CityCrowd; 0 = none, the default);
##                 --hour=H the hour of the day they live by (12.5)
##   --traffic=N   moving cars, at most N (0 = no traffic at all, the default). How many there really are follows the
##                 streets: each kind of street carries so many cars a metre; --density=2 doubles that (1 = the busiest hour)
##   --parked=1|0  with --traffic: the parked cars on the cells' stalls (1, default) or none
##   --carshadows=1|0  the near cars cast sun shadows (1, default)      --carbodies=1|0  the pool of collision boxes
##   --plan=shots  no drives: pictures of a building at set distances and of a street, saved as JPG in
##                 user://rig/shots/ (phone_rig.sh shots NAME ... pulls them to review/tiers/NAME/)
const Lights := preload("res://tools/city/bake/city_lights.gd")
const Look := preload("res://tools/city/look/look.gd")
const LookShots := preload("res://tools/city/look/look_shots.gd")
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
	"seventh_pop": "-400,-600;500,-600;-400,-600",
	# a 3 km loop on streets through civic, centre, apartments (7th St) and back past the gritty edge (5th St): cells
	# arrive and leave all the way round, in populated ground
	"pop_loop": "-600,-600;500,-600;500,-1000;-600,-1000;-600,-600"}
## [name, route, speed m/s, seconds, night 0..1]
const PLANS := {
	"default": [["town_50kmh", "zigzag", 14.0, 60.0, 0.0], ["ring_108kmh", "ring", 30.0, 45.0, 0.0], ["cross_210kmh", "zigzag", 58.0, 35.0, 0.0],
		["ring_280kmh", "ring", 78.0, 35.0, 0.0], ["centre_night_50kmh", "centre", 14.0, 40.0, 1.0]],
	"quick": [["town_50kmh", "seventh", 14.0, 20.0, 0.0], ["cross_280kmh", "seventh", 78.0, 15.0, 0.0]],
	# far jumps on purpose: every teleport throws the loaded cells away and needs a whole new neighbourhood
	"zones": [["gritty_60kmh", "z_gritty", 16.7, 25.0, 0.0], ["centre_60kmh", "z_centre", 16.7, 25.0, 0.0], ["waterfront_60kmh", "z_waterfront", 16.7, 25.0, 0.0], ["industrial_60kmh", "z_industrial", 16.7, 25.0, 0.0], ["apartments_60kmh", "z_apartments", 16.7, 25.0, 0.0], ["pilot_60kmh", "z_pilot", 16.7, 25.0, 0.0], ["strip_60kmh", "z_strip", 16.7, 25.0, 0.0], ["civic_60kmh", "z_civic", 16.7, 25.0, 0.0], ["stadium_60kmh", "z_stadium", 16.7, 25.0, 0.0],
		["seventh_210kmh", "seventh_pop", 58.0, 20.0, 0.0], ["centre_night_60kmh", "z_centre", 16.7, 25.0, 1.0], ["gritty_night_60kmh", "z_gritty", 16.7, 25.0, 1.0]],
	"shots": [["shots", "seventh_pop", 1.0, 1.0, 0.0]],
	"census": [["census", "z_centre", 1.0, 1.0, 0.0]],      # (only its first point; see _census)      # (only its first point: where the app starts; see _shots)
	"stream": [["loop_108kmh", "pop_loop", 30.0, 60.0, 0.0], ["loop_210kmh", "pop_loop", 58.0, 55.0, 0.0], ["loop_280kmh", "pop_loop", 78.0, 40.0, 0.0]],
	"speed": [["ring_108kmh", "ring", 30.0, 60.0, 0.0], ["ring_210kmh", "ring", 58.0, 60.0, 0.0], ["ring_280kmh", "ring", 78.0, 60.0, 0.0], ["ring_360kmh", "ring", 100.0, 40.0, 0.0]]}

var st: Node3D
var lights: Node3D
var cam: Camera3D
var hud: Label
var sun: DirectionalLight3D
var env: Environment
var look: Node                  # the look pack (--look=1); null with --look=0
var traffic: Node            # the C++ traffic (--traffic=N); null without it
var _shot_place := -1          # --walkshot: the place the picture is of
var game: Node = null           # the game's shell (CityGame) when it started this world
var _shot_cam: Camera3D
var people: Node             # the C++ crowd (--people=N); null without it
var opt := {"car": "", "walk": "", "walkshot": "", "walkcrowd": 0, "water": 0.0, "at": "", "people": 0, "hour": 12.5, "traffic": 0, "parked": 1, "density": 1.0, "carshadows": 1, "carbodies": 1, "look": "1", "cycle": 0.0, "clock": 7.0, "celestial": 1, "sea": 1, "weather": "", "air": 0, "cars": 0, "carenv": 1, "shadowtune": 1, "bloom": 0, "upscale": 0, "sharp": 0.2, "glow": 1, "blobs": 0, "wet": 0.0, "reflect": 1, "shots": "", "plan": "default", "scale": 0.0, "quit": false, "lead": 2.0, "maxcells": 30, "loading": 2, "bodies": 6, "coltris": 1200, "colms": 2.0, "loader": 0, "gpureserve": 192, "lights": 20, "nowarm": false, "nocol": false, "hide": false, "probe": false, "tiers": false, "band": 8.0, "arrive": 0.5, "nofarground": false, "census": "both", "views": "", "censussecs": 2.0, "warmnight": true, "colrange": 100.0, "boost": 4.0, "rooms": 1, "maxfps": 0}
var out_lines: PackedStringArray = []
var own_drives: Array = []      # from --drive=...: used instead of the plan

func _say(s: String) -> void:
	print("RIG " + s); out_lines.append(s)

func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var from_file := false
	if FileAccess.file_exists("user://rig_args.txt"):
		args.append_array(FileAccess.get_file_as_string("user://rig_args.txt").replace("\n", " ").split(" ", false)); from_file = true
	# --game (Yasin, 20 Nov: "cant you just inject skipping the rig?"): the rig app opens the game's menu instead of a measuring
	# run (game/boot.tscn; the game then loads this scene as its world, with its own Game node at the root)
	if "--game" in args and get_tree().root.get_node_or_null(^"Game") == null:
		get_tree().change_scene_to_file.call_deferred("res://game/boot.tscn")
		return
	for a in args:
		if a == "--quit": opt.quit = true
		if a == "--nowarm": opt.nowarm = true
		if a == "--nocol": opt.nocol = true
		if a == "--probe": opt.probe = true
		if a == "--hide": opt.hide = true
		if a == "--tiers": opt.tiers = true
		if a == "--nofarground": opt.nofarground = true
		if a == "--warmnight": opt.warmnight = true
		if a == "--nowarmnight": opt.warmnight = false
		if a.begins_with("--drive="):
			var f := a.trim_prefix("--drive=").split("/")
			if f.size() == 5: own_drives.append([f[0], f[1], float(f[2]) / 3.6, float(f[3]), float(f[4])])
			else: push_warning("RIG: --drive needs NAME/ROUTE/SPEED_KMH/SECONDS/NIGHT, got: " + a)
		for k: String in ["car", "walk", "walkshot", "walkcrowd", "water", "at", "people", "hour", "traffic", "parked", "density", "carshadows", "carbodies", "plan", "scale", "lead", "maxcells", "loading", "bodies", "lights", "coltris", "loader", "gpureserve", "colms", "band", "arrive", "look", "cycle", "clock", "celestial", "sea", "weather", "air", "cars", "carenv", "shadowtune", "bloom", "glow", "blobs", "wet", "upscale", "sharp", "reflect", "shots", "census", "views", "censussecs", "colrange", "boost", "rooms", "maxfps"]:
			if a.begins_with("--%s=" % k):
				var v := a.trim_prefix("--%s=" % k)
				opt[k] = v if k in ["car", "walk", "walkshot", "at", "plan", "shots", "look", "weather", "census", "views"] else (float(v) if k in ["water", "density", "scale", "lead", "colms", "band", "arrive", "sharp", "wet", "cycle", "clock", "censussecs", "colrange", "boost"] else int(v))
	if from_file and not ("--loop" in args): opt.quit = true
	# STARTED BY THE GAME'S SHELL (C++ CityGame, game/boot.tscn: New game / Continue): on foot in the city with the people,
	# the traffic and the parked cars, where the shell says (the city centre for a new game, the saved place otherwise);
	# the shell places the player, his bicycle and a car itself once it has them (CityGame.set_world / set_player)
	game = get_tree().root.get_node_or_null(^"Game")
	if game and game.get_class() == "CityGame":
		# (Yasin, 20 Nov: "game just runs laps instead of showing the menu or releasing us into the world": a phone keeps the
		# last measuring run's user://rig_args.txt; started by the game, none of a measuring run's choices may apply)
		opt.plan = "default"; opt.shots = ""; opt.car = ""; own_drives.clear(); opt.census = "both"
		opt.walk = "1"; opt.people = 200; opt.traffic = 40; opt.parked = 1; opt.quit = false
		var ws: Vector3 = game.call(&"world_start")
		opt.at = "%f,%f" % [ws.x, ws.z]
	else: game = null
	Engine.max_fps = int(opt.maxfps)      # --maxfps=30: the frame-rate cap test (Yasin, 20 Nov: "if we lock the fps at 30 ..."); 0 = no cap
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if float(opt.scale) <= 0.0:      # no --scale given: 720p (1640x720 on the Redmi's 2460x1080)
		var ws := DisplayServer.window_get_size(); opt.scale = clampf(720.0 / maxf(1.0, float(mini(ws.x, ws.y))), 0.25, 1.0)
	var vp := get_viewport(); vp.scaling_3d_scale = float(opt.scale); vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	if int(opt.upscale) == 1:      # look job 2: the engine's FSR 1 mode, which Yasin's engine (patch c) runs as SGSR 1 in the Mobile renderer
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR; vp.fsr_sharpness = float(opt.sharp)
	if String(opt.look) != "0":      # the look pack: sky, haze, light colours, colour treatment
		look = Look.new(); look.bloom = int(opt.bloom) == 1; look.glow = int(opt.glow) == 1; look.blobs = int(opt.blobs) == 1; look.wet = float(opt.wet); look.cycle = float(opt.cycle); look.celestial = int(opt.celestial) == 1; look.sea = int(opt.sea) == 1; look.weather = String(opt.weather); look.air = int(opt.air) == 1; look.cars = int(opt.cars) == 1; look.car_env = int(opt.carenv) == 1; look.shadow_tune = int(opt.shadowtune) == 1; look.hour = float(opt.clock); add_child(look); env = look.env; sun = look.sun
		if String(opt.look) != "1": look.set_preset(String(opt.look))
	else:                       # the old plain setup, kept to compare against
		env = Environment.new()
		var sky := Sky.new(); sky.sky_material = ProceduralSkyMaterial.new(); env.background_mode = Environment.BG_SKY; env.sky = sky
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.62, 0.66, 0.72); env.ambient_light_energy = 0.75
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		var we := WorldEnvironment.new(); we.environment = env; add_child(we)
		sun = DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-48, -35, 0); sun.light_energy = 1.25
		sun.shadow_enabled = OS.get_environment("NOSHADOW") != "1"; sun.directional_shadow_max_distance = 50.0; add_child(sun)      # the game's sun shadow distance
	if int(opt.reflect) == 0: env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	# the backstop under everything (C++ CitySea.make_backstop: drawn last, so only what nothing else covers is shaded); under the look's
	# sea (at 0 m) 2 m down: 5 cm below it would flicker far away
	add_child(ClassDB.class_call_static(&"CitySea", &"make_backstop", 6000.0, -2.0 if (look and look.sea) else -0.05))
	st = ClassDB.instantiate(&"CityStream"); st.name = "City";      # the streamer is C++ (native/src/city_stream.*) since 20 Nov
	st.lead_seconds = float(opt.lead); st.max_cells = int(opt.maxcells); st.max_loading = int(opt.loading); st.bodies_per_frame = int(opt.bodies); st.body_tris_per_frame = int(opt.coltris); st.loader_mode = int(opt.loader); st.gpu_reserve_mb = int(opt.gpureserve); st.col_ms_per_frame = float(opt.colms); st.attach_bodies = not opt.nocol; st.show_cells = not opt.hide; st.probe = opt.probe
	st.col_range = float(opt.colrange); st.prepare_boost = float(opt.boost); st.col_background = not ("--colnobg" in args)
	st.tiers = opt.tiers; st.tier_band = float(opt.band); st.arrive_s = float(opt.arrive); st.far_ground = not opt.nofarground; st.rooms = int(opt.rooms) != 0; add_child(st)      # --rooms=0: no walk-in rooms (B14 A/B)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	RenderingServer.frame_pre_draw.connect(func() -> void: _t_pre = Time.get_ticks_usec())
	RenderingServer.frame_post_draw.connect(func() -> void: _t_post = Time.get_ticks_usec())
	lights = Lights.new(); lights.budget = int(opt.lights); lights.stream = st; add_child(lights)
	if look: look.attach_stream(st)      # look job 3: the look's lamp glow on every cell that comes in
	if int(opt.traffic) > 0:      # the traffic: one C++ node; this script sets its numbers and asks for a line at the end of a drive
		if ClassDB.class_exists(&"CityTraffic"):
			traffic = ClassDB.instantiate(&"CityTraffic")
			traffic.set(&"max_cars", int(opt.traffic)); traffic.set(&"parked", int(opt.parked) == 1); traffic.set(&"density", float(opt.density))
			traffic.set(&"shadows", int(opt.carshadows) == 1); traffic.set(&"bodies", int(opt.carbodies) == 1)
			traffic.call(&"attach", st); add_child(traffic)
		else: push_error("RIG ERROR --traffic needs the native module (bash native/build.sh): no traffic in this run")
	if int(opt.people) > 0:       # the people: one C++ node (CityCrowd); it follows the streamer's cells and is joined to the traffic
		if ClassDB.class_exists(&"CityCrowd"):
			people = ClassDB.instantiate(&"CityCrowd")
			people.set(&"max_people", int(opt.people)); people.set(&"hour", float(opt.hour))
			people.call(&"attach", st)
			if traffic: people.call(&"set_traffic", traffic)
			add_child(people)
		else: push_error("RIG ERROR --people needs the native module (bash native/build.sh): no people in this run")
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
var _t_phys := 0          # the first physics tick of the frame, the draw's start and end: marks for the slow-frame breakdown
var _t_phys_frame := -1
var _t_pre := 0
var _t_post := 0
var _g_at := Vector3.ZERO
var _g_y := 0.0
var _g_hit := false

func _physics_process(_dt: float) -> void:
	if _t_phys_frame != Engine.get_process_frames(): _t_phys_frame = Engine.get_process_frames(); _t_phys = Time.get_ticks_usec()
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(_g_at.x, 80, _g_at.z), Vector3(_g_at.x, -20, _g_at.z), 0xFFFFFFEF))      # (not the traffic's car bodies, layer 5: the camera drives THROUGH the cars, it must not climb over them)
	_g_hit = hit.has("position")
	if _g_hit: _g_y = float(hit.position.y)

func _ground(p: Vector3, last: float) -> float:
	_g_at = p
	return _g_y if _g_hit else last

func _night(v: float) -> void:
	st.set_night(v)
	if traffic: traffic.set(&"night", v)      # headlights and tail lights
	if look:
		look.set_night(v); st.set_night(look.lights())      # a preset or the running day decides the night itself
		return
	sun.light_energy = lerpf(1.25, 0.04, v); env.ambient_light_energy = lerpf(0.75, 0.22, v)
	(env.sky.sky_material as ProceduralSkyMaterial).sky_top_color = Color(0.32, 0.52, 0.82).lerp(Color(0.01, 0.015, 0.04), v)
	(env.sky.sky_material as ProceduralSkyMaterial).sky_horizon_color = Color(0.72, 0.8, 0.88).lerp(Color(0.05, 0.06, 0.1), v)

func _run() -> void:
	var R := RenderingServer
	_say("start engine=%s device=%s gpu=%s screen=%s scale=%.2f look=%s bloom=%d upscale=%d sharp=%.2f reflect=%d plan=%s lead=%.1f maxcells=%d loading=%d bodies=%d lights=%d loader=%d coltris=%d cells_baked=%d tiers=%s band=%.1f arrive=%.2f far_ground=%s tier_materials=%d" % [Engine.get_version_info().string, OS.get_model_name(), R.get_video_adapter_name(), str(DisplayServer.window_get_size()), float(opt.scale), String(opt.look), int(opt.bloom), int(opt.upscale), float(opt.sharp), int(opt.reflect), opt.plan, float(opt.lead), int(opt.maxcells), int(opt.loading), int(opt.bodies), int(opt.lights), int(opt.loader), int(opt.coltris), st.cells.size(), str(opt.tiers), float(opt.band), float(opt.arrive), str(not opt.nofarground), int(st.stats.get("tier_materials", 0))])
	# The native module (traffic and people in C++, docs/TRAFFIC_PEOPLE_PORT.md; built by native/build.sh, not in git).
	# Asked through ClassDB by name: this script must still load in a checkout that has not built it. No script fall-back.
	if ClassDB.class_exists(&"CityNative"):
		var nt: Dictionary = ClassDB.class_call_static(&"CityNative", &"self_test", 4, 2000000)
		_say("native %s | its own threads: %s (%d threads, %.1f ms; the device reports %d)" % [str(ClassDB.class_call_static(&"CityNative", &"version")), "ok" if nt.get("ok", false) else "FAILED", int(nt.get("threads", 0)), float(nt.get("ms", 0.0)), int(nt.get("hw", 0))])
	else:
		_say("native: the module is not in this build (native/build.sh makes it; nothing in this run needs it)")
	if st.cells.is_empty():
		_say("ERROR no baked city found (map_dc/coronado/city_kit/runtime). Run the bake before the export."); hud.text = "no baked city in this build"
		if opt.quit: await get_tree().create_timer(3.0).timeout; get_tree().quit()
		return
	if String(opt.shots) != "":      # pictures instead of a drive
		await LookShots.run(self, String(opt.shots), OS.get_cmdline_user_args())
		get_tree().quit(); return
	var plan: Array = PLANS.get(String(opt.plan), PLANS.default)
	if not own_drives.is_empty(): plan = own_drives; _say("own drives: %d" % plan.size())
	var first: Vector3 = _pts(plan[0][1])[0]
	var t0 := Time.get_ticks_msec()
	cam.global_position = first + Vector3(0, 8, 0); cam.look_at(cam.global_position + Vector3(0, 0, -50))
	st.update_focus(first, true)
	var t1 := Time.get_ticks_msec()
	if not opt.nowarm:
		st.warm_up(cam, 4); await st.warmed_up
	# THE NIGHT ONCE, behind the loading screen (on by default since 19 Nov; --nowarmnight to compare). The first dusk of
	# a session built the look's night shaders, loaded its night textures and the lights' shader versions in the middle
	# of a drive: 33 ms of GPU and a 41 ms frame at 720p, up to 120 ms at 1.5 x; the second dusk had none of it. Drawn
	# once here, the first dusk's worst frame was 19 ms (docs/DRAW_CENSUS.md "THE FIRST NIGHT", census_warmnight).
	if opt.warmnight and not opt.nowarm:
		var tw := Time.get_ticks_msec()
		_night(1.0); lights.update_lights(cam.global_position, 1.0)
		for i in 20: await get_tree().process_frame
		_night(0.0); lights.update_lights(cam.global_position, 0.0)
		for i in 10: await get_tree().process_frame
		_say("warmnight %d ms" % (Time.get_ticks_msec() - tw))
	for i in 10: await get_tree().process_frame
	_say("boot first_area_ms=%d warm_ms=%d (graphics memory reserve %d MB: %d ms) cells=%d static_mb=%.0f video_mb=%.0f" % [t1 - t0, Time.get_ticks_msec() - t1, int(opt.gpureserve), int(st.stats.get("reserve_ms", 0)), st.loaded_count(), Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, R.get_rendering_info(R.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0])
	if String(opt.car) != "" or String(opt.walk) != "":      # a car to drive, or a walk on foot, instead of a plan
		await _free_drive(first)
		get_tree().quit()
		return
	if String(opt.plan) == "census":
		await _census()
		await get_tree().create_timer(0.5).timeout
		get_tree().quit()
		return
	if String(opt.plan) == "shots":
		await _shots()
		await get_tree().create_timer(0.5).timeout
		get_tree().quit()
		return
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

## DRIVE IT YOURSELF (--car). All the driving is C++ (CityCar): this makes the node, sets it on the ground, and each frame
## tells the streamer where the car is and writes the speed on the screen.
func _free_drive(first: Vector3) -> void:
	var on_foot := String(opt.walk) != ""
	if not ClassDB.class_exists(&"CityPlayer" if on_foot else &"CityCar"):
		_say("ERROR --car / --walk need the native module (bash native/build.sh)"); return
	var names := ["stern_e", "volt_s", "stern_g", "volt_x", "sakura_t", "sakura", "van", "fiamma_r", "fiamma_gt", "taxi", "bus_city", "bus_mini"]
	var q := String(opt.car).split("/")
	var m := maxi(names.find(q[0]), 0) if names.has(q[0]) else 2
	var start := first; var yaw := 0.0
	if String(opt.at) != "":
		var f := String(opt.at).split_floats(","); start = Vector3(f[0], 0, f[1]); yaw = deg_to_rad(f[2]) if f.size() > 2 else 0.0
	# --walkshot=KIND/FILE (with --walk and --people): he is set down in front of the nearest place of that kind (6 a bench,
	# 2 the beach, 5 a bus stop, 10 a spot in the sea ...) near --at, two people are sent there, and after 16 s (the sea: 75 s)
	# one picture is saved
	if on_foot and String(opt.walkshot) != "" and people:
		var kind := int(String(opt.walkshot).get_slice("/", 0))
		_shot_place = int(people.call(&"place_near", start, kind, 4000.0 if kind in [2, 10] else 200.0))      # (the beach and the sea: the nearest, wherever)
		if _shot_place >= 0:
			var info: Dictionary = people.call(&"place_info", _shot_place)
			var pave: Vector3 = info.pavement; var at: Vector3 = info.at
			var d := Vector3(pave.x - at.x, 0, pave.z - at.z)
			d = d.normalized() if d.length() > 0.3 else Vector3(sin(float(info.yaw)), 0, cos(float(info.yaw)))
			start = Vector3(at.x, 0, at.z) + d * 4.5 + Vector3(-d.z, 0, d.x) * 1.5
			if kind == 10: start = Vector3(pave.x, 0, pave.z)      # (a spot in the sea: he stands on the pavement its beach is reached from)
			var look := (Vector3(at.x, 0, at.z) - start).normalized()
			yaw = atan2(-look.x, -look.z) - PI      # (his camera, behind him, looks at the place)
		else: _say("walkshot: no place of kind %d within 200 m" % kind)
	# (a point exactly on a cell's edge, every 200 m, has no ground a ray can find: the seam between two collision pieces)
	if absf(fposmod(start.x + 1.0, 200.0) - 1.0) < 1.0 or absf(fposmod(start.z + 1.0, 200.0) - 1.0) < 1.0: start += Vector3(1.7, 0, 1.7)
	# the start made ready as a drive's start is (its cells in, their collision made), then the ground under it found:
	# without that the car was set down before there was a street to stand on, and fell through the world
	st.prepare(start)
	while not st.is_ready(start):
		st.update_focus(st.focus, false); hud.text = "getting the start ready"
		await get_tree().process_frame
	st.release_prepared(); st.update_focus(start, false)
	cam.global_position = start + Vector3(0, 8, 0)
	_g_hit = false; _ground(start, 0.0)
	var tries := 0
	while not _g_hit and tries < 240:
		st.update_focus(start, false); _ground(start, 0.0); tries += 1
		await get_tree().physics_frame
	if not _g_hit:
		var nb := 0; var near := 0; var layers := {}
		for c: Node in st.find_children("*", "StaticBody3D", true, false):
			nb += 1; layers[(c as StaticBody3D).collision_layer] = true
			if (c as Node3D).global_position.distance_to(start) < 150.0: near += 1
		_say("ERROR --car: no ground with collision under (%.0f, %.0f): choose another place with --at=x,z | collision bodies in the world %d, within 150 m %d, their layers %s, cells in %d, physics process %s" % [start.x, start.z, nb, near, str(layers.keys()), st.loaded_count(), str(is_physics_processing())]); return
	if on_foot:
		await _free_walk(start, yaw); return
	if not (look and look.cars): RenderingServer.global_shader_parameter_add(&"refl_env", RenderingServer.GLOBAL_VAR_TYPE_VEC2, Vector2(1.0, 0.0))      # (the cars' paint shader needs it to exist)
	var car: Node3D = ClassDB.instantiate(&"CityCar")
	car.set(&"model", m); car.set(&"feel", 1 if (q.size() > 1 and q[1].to_upper() == "V") else 0)
	car.set(&"player", true); car.set(&"chase_camera", true); car.set(&"wheel_mask", 0xFFFFFFEF)
	var y_start := _ground(start, 0.0) + 0.15
	car.position = Vector3(start.x, y_start, start.z); car.rotation.y = yaw
	add_child(car)
	if DisplayServer.is_touchscreen_available(): _touch_guide()      # (the touch driving itself is CityCar's, C++)
	var s0: Dictionary = car.call(&"get_state")
	if traffic: traffic.call(&"set_player_car", car, 2.3, 1.0)
	if people: people.call(&"set_player_car", car, 2.3, 1.0)      # (people get out of its way, and are knocked over by it)
	_say("car %s (%s feel): %d kg, wheelbase %.2f m; W A S D / arrows, Space = handbrake, Esc leaves" % [names[m], "GTA 5" if int(car.get(&"feel")) == 1 else "GTA 4", int(s0.mass), float(s0.wheelbase)])
	var last := car.global_position
	var t_start := Time.get_ticks_msec()
	while not Input.is_key_pressed(KEY_ESCAPE):
		await get_tree().process_frame
		if opt.quit and Time.get_ticks_msec() - t_start > 12000: break      # (--quit: a 12 s try-out that leaves by itself)
		var p: Vector3 = car.global_position
		var dt := maxf(get_process_delta_time(), 0.001)
		st.update_focus(p, false, (p - last) / dt); last = p
		var s: Dictionary = car.call(&"get_state")
		if Engine.get_process_frames() % 6 == 0:
			hud.text = "%3d km/h   gear %s   %d rpm   side %.2f g   %s" % [absi(int(s.kmh)), "R" if int(s.gear) < 0 else str(int(s.gear)), int(s.rpm), absf(float(s.side_g)), "SLIDING" if float(s.slip_most) > 1.4 else ""]
	var s1: Dictionary = car.call(&"get_state")
	_say("car: %.0f m driven, hardest knock %.0f g, at the end %d wheels on the ground, %.2f m over the place it started, %d km/h" % [float(s1.metres), float(s1.hardest_knock_g), int(s1.wheels_on_ground), car.global_position.y - y_start, int(s1.kmh)])
	if traffic: _say("  traffic %s" % String(traffic.call(&"report")))
	if people: _say("  people %s | %s" % [String(people.call(&"report")), str(people.call(&"stats"))])

## Where to put the thumbs (20 Nov, Yasin: "Make the car drivable on touchscreen"): faint zones over the picture, the
## same split CityCar reads (native/src/city_car.cpp _input). Draws nothing that catches a touch.
func _touch_guide() -> void:
	var layer := CanvasLayer.new(); layer.layer = 5; add_child(layer)
	var zones := [["STEER  - slide left / right", Rect2(0.0, 0.62, 0.5, 0.38)], ["BRAKE / REVERSE", Rect2(0.5, 0.62, 0.25, 0.38)],
		["GAS", Rect2(0.75, 0.62, 0.25, 0.38)], ["HANDBRAKE", Rect2(0.8, 0.0, 0.2, 0.28)]]
	for z: Array in zones:
		var r: Rect2 = z[1]
		var box := ColorRect.new(); box.color = Color(1, 1, 1, 0.07); box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.anchor_left = r.position.x; box.anchor_top = r.position.y; box.anchor_right = r.end.x; box.anchor_bottom = r.end.y
		box.offset_left = 6; box.offset_top = 6; box.offset_right = -6; box.offset_bottom = -6
		var lb := Label.new(); lb.text = String(z[0]); lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lb.set_anchors_preset(Control.PRESET_FULL_RECT); lb.add_theme_font_size_override(&"font_size", 30)
		lb.add_theme_color_override(&"font_color", Color(1, 1, 1, 0.55))
		box.add_child(lb); layer.add_child(box)

## WALK IT YOURSELF (--walk). All the walking is C++ (CityPlayer); this makes the node, sets it on the ground, and each
## frame tells the streamer where he is.
func _free_walk(start: Vector3, yaw: float) -> void:
	var pl: Node3D = ClassDB.instantiate(&"CityPlayer")
	st.set_player(pl)      # B7: riding (the player hidden where he got in), the streamer follows the camera (CityStream::update_focus)
	if String(opt.walk).length() > 1: pl.set(&"body_id", String(opt.walk))
	pl.set(&"capture_mouse", not opt.quit)
	if float(opt.water) > -999.0: pl.set(&"water_y", float(opt.water))      # --water=Y: the sea's surface: deeper than his chest he swims
	var y_start := _ground(start, 0.0) + 0.05
	pl.position = Vector3(start.x, y_start, start.z); pl.rotation.y = yaw
	add_child(pl)
	if game:      # the shell sets him down (a new game: the pavement nearest the centre, with his bicycle and a car; or where he was saved)
		pl.set(&"capture_mouse", false)
		game.call(&"set_world", people, traffic)
		game.call(&"set_player", pl)
	if people: people.call(&"set_player", pl)
	if people and ClassDB.class_exists(&"CityTalk"):      # talking to people: one C++ node (E, or the Talk button)
		var talk: Node = ClassDB.instantiate(&"CityTalk")
		add_child(talk)
		talk.call(&"set_crowd", people); talk.call(&"set_player", pl)
		_say("talk: the phone's speech plugin is %s" % ("there (lines are said into the microphone)" if bool(talk.call(&"stats").speech_plugin) else "not there (lines are typed or skipped)"))
	# --walkcrowd=N (a measure): N people are set down within 6 m of him, so that the animated bodies are all in use
	for k in int(opt.walkcrowd):
		if people: people.call(&"place_walker", Vector3(start.x, y_start, start.z) + Vector3(cos(k * 2.4) * (2.0 + 0.35 * k), 0, sin(k * 2.4) * (2.0 + 0.35 * k)), 9000 + 53 * k)
	_say("on foot at (%.0f, %.0f): W A S D, Shift runs, the mouse turns, E speaks to somebody, Esc leaves" % [start.x, start.z])
	if opt.quit and _shot_place < 0: pl.call(&"set_move", Vector2(0, 1), false)      # (--quit: he walks ahead for 12 s and the run leaves by itself)
	var last := pl.global_position; var metres := 0.0; var lowest := 0.0; var highest := 0.0
	var t_start := Time.get_ticks_msec()
	var shot_sent := false
	var frame_ms := PackedFloat32Array()
	while not Input.is_key_pressed(KEY_ESCAPE):
		await get_tree().process_frame
		if Time.get_ticks_msec() - t_start > 2000: frame_ms.append(get_process_delta_time() * 1000.0)      # (after two seconds of settling)
		if _shot_place >= 0:      # (--walkshot: people are sent to the place once the crowd is there; the picture after 16 s)
			pl.call(&"set_move", Vector2.ZERO, false)
			var el := Time.get_ticks_msec() - t_start
			if not shot_sent and el > 3000:
				shot_sent = true
				var info: Dictionary = people.call(&"place_info", _shot_place)
				for k in 2:
					var w := int(people.call(&"place_walker", (info.pavement as Vector3) + Vector3(1.2 * k - 0.6, 0, 0.4 * k), 6100 + 41 * k))
					var pk := _shot_place if k == 0 else int(people.call(&"place_near", (info.at as Vector3) + Vector3(0.3, 0, 0.3), int(info.kind), 3.0))
					_say("walkshot: walker %d sent to place %d: %s" % [w, pk, str(people.call(&"set_goal", w, pk, 120.0, false))])
			var shot_ms := 75000 if int(String(opt.walkshot).get_slice("/", 0)) == 10 else 16000      # (to a spot in the sea it is a long walk)
			if el > shot_ms - 500 and _shot_cam == null:      # (the picture's own camera: beside him, so that he is not in the way)
				var info2: Dictionary = people.call(&"place_info", _shot_place)
				var at2: Vector3 = info2.at; var pv: Vector3 = info2.pavement
				var d2 := Vector3(pv.x - at2.x, 0, pv.z - at2.z)
				d2 = d2.normalized() if d2.length() > 0.3 else Vector3(sin(float(info2.yaw)), 0, cos(float(info2.yaw)))
				_shot_cam = Camera3D.new(); _shot_cam.fov = 55.0; add_child(_shot_cam)
				_shot_cam.look_at_from_position(at2 + d2 * 4.2 + Vector3(-d2.z, 0, d2.x) * -2.2 + Vector3(0, 1.9, 0), at2 + Vector3(0, 0.7, 0), Vector3.UP)
				_shot_cam.current = true
			if el > shot_ms:
				var file := String(opt.walkshot).get_slice("/", 1) if String(opt.walkshot).contains("/") else "walkshot.jpg"
				get_viewport().get_texture().get_image().save_jpg("res://OUT/" + file, 0.9)
				_say("walkshot saved to OUT/%s: %s" % [file, str(people.call(&"place_info", _shot_place))])
				break
		elif opt.quit and Time.get_ticks_msec() - t_start > 12000: break
		var p: Vector3 = pl.global_position
		var dt := maxf(get_process_delta_time(), 0.001)
		st.update_focus(p, false, (p - last) / dt)
		if pl.visible:      # (the walk's own numbers: on foot only)
			metres += Vector2(p.x - last.x, p.z - last.z).length()
			lowest = minf(lowest, p.y - y_start); highest = maxf(highest, p.y - y_start)
		last = p
		if Engine.get_process_frames() % 6 == 0: hud.text = "%.1f m/s" % float(pl.call(&"get_speed"))
	if frame_ms.size() > 20:
		frame_ms.sort()
		_say("on foot frames=%d | frame_ms med=%.1f p95=%.1f p99=%.1f worst=%.0f | near bodies now %d of %d" % [frame_ms.size(), frame_ms[frame_ms.size() / 2], frame_ms[int(frame_ms.size() * 0.95)], frame_ms[int(frame_ms.size() * 0.99)], frame_ms[frame_ms.size() - 1], int(people.call(&"stats").near_bodies) if people else 0, int(people.call(&"stats").near_pool) if people else 0])
	_say("on foot: %.0f m walked, between %.2f m under and %.2f m over the height he started at, at the end at (%.1f, %.1f)" % [metres, -lowest, highest, last.x, last.z])
	if people: _say("  people %s | %s" % [String(people.call(&"report")), str(people.call(&"stats"))])

## Where a frame's time went: with --probe the wait for the physics thread and for the render server to digest what the
## streamer handed over (-1 without it), the streamer's own main-thread part, draw preparation, drawing on the CPU and
## on the GPU. A slow frame is printed one frame late with both frames' readings.
func _parts() -> String:
	var R := RenderingServer; var vr := get_viewport().get_viewport_rid()
	return "physics_wait %.1f render_wait %.1f streamer %.2f setup %.1f draw_cpu %.1f gpu %.1f" % [float(st.stats.get("phys_wait_ms", -1.0)), float(st.stats.get("rs_wait_ms", -1.0)), float(st.stats.get("proc_ms", 0.0)), R.get_frame_setup_time_cpu(), R.viewport_get_measured_render_time_cpu(vr), R.viewport_get_measured_render_time_gpu(vr)]

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
	if traffic: traffic.call(&"report")      # (start its counters with the drive)
	if people: people.call(&"report")
	var dts := PackedFloat32Array(); var draws_sum := 0.0; var draws_max := 0; var tris_sum := 0.0; var tris_max := 0
	# (B28, 20 Nov) with a render thread every RenderingServer read waits for it: the counters are read every 30th frame
	var rs_every := 30 if int(ProjectSettings.get_setting("rendering/driver/threads/thread_model", 1)) == 2 else 1
	var rs_n := 0; var fi := 0
	var late220 := 0; var late60 := 0; var deepest := 0.0; var max_cells := 0; var slow := 0; var gy := 8.0
	var segi := 0; var along := 0.0; var t := 0.0; var t_prev := Time.get_ticks_usec(); var hud_t := 0.0; var prev := [S0["in"], S0.out, S0.bodies]
	var ready0: int = st.ready_ms.size() + st.ready_dropped; var slow_line := ""; var cause := {}; var cause45 := {}; var pw := PackedFloat32Array(); var gpu := PackedFloat32Array()
	st.stats["body_wait_ms_worst"] = 0; var units0 := int(st.stats.get("col_units", 0))
	var on_ground := false; _g_hit = false; _g_at = pts[0]
	while t < secs:
		var a0: Vector3 = pts[segi]; var a1: Vector3 = pts[segi + 1]; var sl := a0.distance_to(a1)
		var p := a0.lerp(a1, clampf(along / sl, 0.0, 1.0)); var dir := (a1 - a0).normalized()
		var g := _ground(p, gy)
		if _g_hit and not on_ground: gy = g; on_ground = true      # the first answer: stand on the road at once, do not glide down (or up) to it
		gy = lerpf(gy, g, 0.2)
		cam.global_position = Vector3(p.x, gy + 1.3, p.z); cam.look_at(cam.global_position + dir * 50.0)
		var t_f0 := Time.get_ticks_usec()
		st.update_focus(p, false, dir * sp)
		var t_f1 := Time.get_ticks_usec()
		var lit: float = look.lights() if look else float(seg[4])      # (the look's time of day may differ from the drive's)
		if lit > 0.05 and Engine.get_process_frames() % 15 == 0: lights.update_lights(cam.global_position, lit)
		await get_tree().process_frame
		var now := Time.get_ticks_usec(); var dt := (now - t_prev) / 1000000.0; t += dt; dts.append(dt * 1000.0)
		var sysd: Dictionary = st.perf_take() if st.has_method(&"perf_take") else {}      # the C++ systems' own frame times (perf_marks.h)
		var sys_top: Array = sysd.keys(); sys_top.sort_custom(func(a: String, b: String) -> bool: return float(sysd[a]) > float(sysd[b]))
		var sys_s := ", ".join(sys_top.slice(0, 3).map(func(k: String) -> String: return "%s %.1f" % [k, float(sysd[k])]))
		# where the frame that just ended spent its time, mark to mark (ms): this script | the streamer's update_focus |
		# other scripts up to the streamer | the streamer's frame work and probes | the rest of the scripts up to the
		# draw | the draw (materials, render server, drawing, presenting) | after the draw up to the first physics
		# tick (waiting for the physics thread) | physics callbacks up to the next frame's scripts
		var tp0 := int(st.stats.get("t_proc0", t_f1)); var tp1 := int(st.stats.get("t_proc1", tp0))
		var ph := _t_phys if _t_phys > _t_post and _t_phys <= now else now
		var marks := "rig %.1f focus %.1f | to_streamer %.1f streamer %.1f | to_draw %.1f draw %.1f | to_physics %.1f physics %.1f" % [(t_f0 - t_prev) / 1000.0, (t_f1 - t_f0) / 1000.0, (tp0 - t_f1) / 1000.0, (tp1 - tp0) / 1000.0, (_t_pre - tp1) / 1000.0, (_t_post - _t_pre) / 1000.0, (ph - _t_post) / 1000.0, (now - ph) / 1000.0]
		t_prev = now
		along += dt * sp
		while along >= (pts[segi] as Vector3).distance_to(pts[segi + 1]):
			along -= (pts[segi] as Vector3).distance_to(pts[segi + 1]); segi = (segi + 1) % (pts.size() - 1)
		fi += 1
		var dr := 0; var tr := 0
		if fi % rs_every == 0:
			dr = int(R.get_rendering_info(R.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)); tr = int(R.get_rendering_info(R.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
			gpu.append(R.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()))
			draws_sum += dr; tris_sum += tr; draws_max = maxi(draws_max, dr); tris_max = maxi(tris_max, tr); rs_n += 1
		max_cells = maxi(max_cells, st.loaded_count())
		var lc: Vector3 = st.late_cells(p)      # (cells not in within 60 m, within 220 m, the deepest reach into 220 m)
		late60 += int(lc.x); late220 += int(lc.y); deepest = maxf(deepest, lc.z)
		var S: Dictionary = st.stats
		if opt.probe: pw.append(float(S.get("phys_wait_ms", 0.0)))
		if slow_line != "":      # the slow frame of one frame ago, now with the engine's counters for it
			_say(slow_line + " | then: " + _parts()); slow_line = ""
		if dt > 0.0333:      # a frame a player would notice (over 33 ms since the zones run; 50 ms before): what was the streamer doing?
			var d_in := int(S["in"]) - int(prev[0]); var d_b := int(S.bodies) - int(prev[2]); var ld: Array = st.loading_keys()
			var why := "loading" if not ld.is_empty() else ("cell_in" if d_in > 0 else ("bodies" if d_b > 0 else "none"))
			cause[why] = int(cause.get(why, 0)) + 1
			if dt > 0.045: cause45[why] = int(cause45.get(why, 0)) + 1
			if slow < 25 and dt > 0.040:
				slow += 1
				slow_line = "slow %s %.0f ms at t=%.1f s pos=(%.0f, %.0f): cells in +%d out +%d, bodies +%d, loading %s | marks: %s | sys: %s | at: %s" % [name, dt * 1000.0, t, p.x, p.z, d_in, int(S.out) - int(prev[1]), d_b, str(ld), marks, sys_s, _parts()]
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
	for i in range(maxi(ready0 - st.ready_dropped, 0), st.ready_ms.size()): rs += st.ready_ms[i]; rw = maxf(rw, st.ready_ms[i])
	_say("drive %s speed=%.0f km/h secs=%.0f frames=%d fps=%.1f | frame_ms med=%.1f p95=%.1f p99=%.1f worst=%.0f | over16.7=%.1f%% over33=%d over50=%d over100=%d" % [name, sp * 3.6, t, n, n / t, sorted[n / 2], sorted[int(n * 0.95)], sorted[int(n * 0.99)], sorted[n - 1], 100.0 * o17 / n, o33, o50, o100])
	gpu.sort()      # the GPU's own time a frame (the phone is held at the 60 fps step by vsync, so the frame time hides small costs)
	_say("  map %s draws avg=%.0f max=%d | tris avg=%.0fk max=%dk | cells most=%d in=%d out=%d dropped=%d cap_hits=%d | gpu_ms med=%.2f p95=%.2f" % [name, draws_sum / maxi(rs_n, 1), draws_max, tris_sum / maxi(rs_n, 1) / 1000.0, tris_max / 1000, max_cells, int(S1["in"]) - int(S0["in"]), int(S1.out) - int(S0.out), int(S1.dropped) - int(S0.dropped), int(S1.capped) - int(S0.capped), gpu[gpu.size() / 2] if gpu.size() > 0 else -1.0, gpu[int(gpu.size() * 0.95)] if gpu.size() > 0 else -1.0])
	_say("  stream %s start_ready_ms=%d (worst frame meanwhile %.0f ms) | request_to_in ms mean=%.0f worst=%.0f | late frames: 220m=%d (deepest %.0f m) 60m=%d | main thread worst ms: cell add %.2f, body %.2f (%s), removal step %.2f | bodies late=%d" % [name, prep_ms, prep_worst, rs / maxf(1.0, st.ready_ms.size() + st.ready_dropped - ready0), rw, late220, deepest, late60, float(S1.add_ms_worst), float(S1.body_ms_worst), str(S1.get("body_worst_what", "")), float(S1.remove_ms_worst), int(S1.body_late) - int(S0.body_late)])
	_say("  slow %s frames over 33 ms by what the streamer was doing: %s | over 45 ms: %s" % [name, str(cause), str(cause45)])
	pw.sort()
	_say("  collision %s made=%d units, a body waited at most %d ms from coming into range | physics thread wait a frame (probe): median %.1f p99 %.1f worst %.1f ms" % [name, int(st.stats.get("col_units", 0)) - units0, int(st.stats.get("body_wait_ms_worst", 0)), pw[pw.size() / 2] if pw.size() > 0 else -1.0, pw[int(pw.size() * 0.99)] if pw.size() > 0 else -1.0, pw[pw.size() - 1] if pw.size() > 0 else -1.0])
	# for long runs: none of these may grow lap after lap (a leak, or work piling up)
	_say("  objects %s all=%d nodes=%d orphan_nodes=%d resources=%d | streamer: cells in=%d, bodies waiting=%d, nodes leaving=%d" % [name, int(Performance.get_monitor(Performance.OBJECT_COUNT)), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)), st.loaded_count(), st.pending_count(), st.leaving_count()])
	if traffic: _say("  traffic %s %s" % [name, String(traffic.call(&"report"))])
	if people: _say("  people %s %s | %s" % [name, String(people.call(&"report")), str(people.call(&"stats"))])
	_say("  mem %s static_mb=%.0f video_mb=%.0f tex_mb=%.0f buf_mb=%.0f" % [name, Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, R.get_rendering_info(R.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0, R.get_rendering_info(R.RENDERING_INFO_TEXTURE_MEM_USED) / 1048576.0, R.get_rendering_info(R.RENDERING_INFO_BUFFER_MEM_USED) / 1048576.0])

## --plan=shots (19 Nov, the tiers): pictures from the phone at set distances, to compare the tier settings. A building
## on 7th St at distances round the two switches (60 m, 220 m), and the street ahead (the far ground beyond the loaded
## cells). Each picture waits for the place to be ready and the arrival sweep to end. Saved as user://rig/shots/*.jpg
## (half the screen's size); phone_rig.sh shots NAME pulls them.
const SHOT_STREET := [Vector3(-400, 0, -600), Vector3(1, 0, 0)]      # a point on 7th St and its direction
const SHOT_TARGET := Vector3(60, 0, -625)                             # the building nearest this is the one looked at
const SHOT_DISTS := [40.0, 56.0, 60.0, 64.0, 80.0, 150.0, 212.0, 218.0, 222.0, 228.0, 260.0]
## [name, camera x, z, height above ground, look x, z, look height]
const SHOT_VIEWS := [["street_eye", -950.0, -600.0, 1.6, 600.0, -600.0, 1.0], ["street_high", -950.0, -600.0, 30.0, 0.0, -600.0, 0.0],
	["junction_north", 0.0, -560.0, 1.6, 0.0, 200.0, 1.0], ["hill_view", -600.0, -1000.0, 12.0, 400.0, -1000.0, 0.0], ["aerial", -950.0, -600.0, 120.0, 200.0, -600.0, 0.0]]

var _shot_last_y := 6.0
func _shot_ground(p: Vector3) -> float:
	_g_at = p; _g_hit = false
	for i in 30:      # the ray is cast in the physics step; the collision there may still be attaching
		await get_tree().physics_frame
		if _g_hit and i >= 3: break
	await get_tree().process_frame
	if not _g_hit: _say("shot: no ground under (%.0f, %.0f)" % [p.x, p.z])
	return _g_y if _g_hit else _shot_last_y

func _shot_ready(p: Vector3) -> void:
	st.prepare(p)
	var t0 := Time.get_ticks_msec()
	while (not st.is_ready(p) or st.busy()) and Time.get_ticks_msec() - t0 < 20000:
		st.update_focus(p, false); await get_tree().process_frame
	st.release_prepared(); st.update_focus(p, false)
	var t1 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t1 < int((float(opt.arrive) + 0.6) * 1000.0):
		st.update_focus(p, false); await get_tree().process_frame

func _shot_save(name: String) -> void:
	hud.visible = false
	for i in 3: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	hud.visible = true
	DirAccess.make_dir_recursive_absolute("user://rig/shots")
	img.resize(img.get_width() / 2, img.get_height() / 2, Image.INTERPOLATE_BILINEAR)
	var err := img.save_jpg("user://rig/shots/%s.jpg" % name, 0.88)
	var R := RenderingServer
	_say("shot %s pos=(%.1f, %.1f, %.1f) draws=%d tris=%dk saved=%s" % [name, cam.global_position.x, cam.global_position.y, cam.global_position.z, R.get_rendering_info(R.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), R.get_rendering_info(R.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME) / 1000, error_string(err)])

func _shots() -> void:
	var s0: Vector3 = SHOT_STREET[0]; var dir: Vector3 = SHOT_STREET[1]
	await _shot_ready(SHOT_TARGET)
	# the building: the one nearest SHOT_TARGET among the loaded cells (its node origin is where its tiers measure from)
	var best: Node3D = null; var bd := 1.0e9
	for k: String in st.cells:
		var cn: Node = st.cells[k].node
		if cn == null or st.cells[k].state != 4: continue
		var bn := cn.get_node_or_null("Buildings")
		if bn == null: continue
		for b: Node in bn.get_children():
			var d := Vector2((b as Node3D).global_position.x - SHOT_TARGET.x, (b as Node3D).global_position.z - SHOT_TARGET.z).length()
			if d < bd: bd = d; best = b
	if best == null: _say("ERROR shots: no building near %s" % str(SHOT_TARGET)); return
	var bp := best.global_position
	var lat := absf((bp - s0).dot(Vector3(-dir.z, 0, dir.x)))      # how far the building stands off the street line
	var along := (bp - s0).dot(dir)
	_say("shots building %s (%s) at (%.0f, %.0f), %.1f m off the street" % [best.name, str(best.get_meta(&"kit", "")), bp.x, bp.z, lat])
	for d: float in SHOT_DISTS:
		var a := sqrt(maxf(d * d - lat * lat, 0.0))      # so the distance to the building's pivot is d
		var p := s0 + dir * (along - a)
		await _shot_ready(p)
		var gy: float = await _shot_ground(p); _shot_last_y = gy
		cam.global_position = Vector3(p.x, gy + 1.6, p.z); cam.look_at(Vector3(bp.x, gy + 6.0, bp.z))
		st.update_focus(p, false)
		await _shot_save("bldg_%03dm" % int(d))
	for v: Array in SHOT_VIEWS:
		var p2 := Vector3(float(v[1]), 0, float(v[2]))
		await _shot_ready(p2)
		var gy2: float = await _shot_ground(p2)
		cam.global_position = Vector3(p2.x, gy2 + float(v[3]), p2.z); cam.look_at(Vector3(float(v[4]), gy2 + float(v[6]), float(v[5])))
		st.update_focus(p2, false)
		await _shot_save(String(v[0]))
	_say("plan_done shots")

## --plan=census (19 Nov; Yasin: "queue the drawing cost census"): where a frame's GPU time goes. The camera STANDS at a
## street-level viewpoint, waits until the place is ready and nothing loads, then goes through a list of states, each
## the baseline with ONE thing changed, a few seconds each, and prints per state the median and 95 % GPU time, the
## CPU draw time, draws and triangles. Baseline first and last at every viewpoint (heat drift). GPU time, not frame
## time: the frame sits on the vsync step. Nothing of this changes the defaults; every state is undone after it.
##   --census=day|night|both   --views=centre,gritty,...   --censussecs=2.0   (the night is drawn once at boot unless --nowarmnight)
## Results: "RIG census VIEW STATE ..." lines; docs/DRAW_CENSUS.md.
const CENSUS_VIEWS := [["centre", 0.0, -600.0, 1.0, 0.0], ["apartments", 250.0, -600.0, 1.0, 0.0], ["gritty", -600.0, -1000.0, 1.0, 0.0],
	["waterfront", 570.0, 200.0, -1.0, 0.0], ["industrial", -800.0, -1400.0, 1.0, 0.0], ["pilot", 0.0, 0.0, 0.0, 1.0], ["civic", -200.0, -600.0, 1.0, 0.0]]
const CENSUS_DAY := ["baseline", "hide_plants", "hide_props_near", "hide_props_mid", "hide_props_other", "hide_bldg_near", "hide_bldg_mid",
	"hide_ground", "hide_wear", "hide_far", "hide_far_ground", "hide_misc", "hide_rooms", "shadows_off", "shadow_map_2048", "shadow_map_1024",
	"fxaa_off", "scale_0.50", "scale_0.67", "scale_0.85", "scale_1.00", "cheap_bldg_mid", "cheap_bldg_all", "cheap_props_mid",
	"cheap_plants_mid", "plants_opaque", "look_parts_off", "look_contact_off", "look_windows_off", "look_glass_off", "look_detail_off",
	"look_signs_off", "look_propmaps_off", "look_between_off", "baseline", "sky_reflection_off", "baseline"]      # (the reflection last: switching it back on left the GPU slower until the next teleport, phone 19 Nov)
const CENSUS_NIGHT := ["baseline", "lights_0", "lights_1", "window_glow_off", "look_windows_off", "look_signs_off", "hide_glow", "baseline"]
## the look pack's parts that have a global switch (docs/LOOK_OVERVIEW.md); 1 = on (the default), 0 = off
const LOOK_PARTS := ["contact", "windows", "glass", "detail", "signs", "propmaps", "between"]
var _cz_undo: Array = []         # [callable] to undo the current state
var _cz_mat_cache := {}

func _census_temp() -> String:
	var f := FileAccess.open("/sys/class/power_supply/battery/temp", FileAccess.READ)
	return f.get_as_text().strip_edges() if f else "?"

## every loaded cell's (and the far world's) nodes of one kind
func _census_nodes(kind: String) -> Array:
	var out: Array = []
	if kind == "far" or kind == "far_ground":
		for ch: Node in st.far_world.get_children():
			if (String(ch.name) == "far_ground") == (kind == "far_ground"): out.append(ch)
		return out
	for k: String in st.cells:
		if st.cells[k].state != 4: continue
		var cn: Node = st.cells[k].node
		match kind:
			"ground":
				var g := cn.get_node_or_null("Ground")
				if g: out.append_array(g.get_children())
			"wear":
				if cn.get_node_or_null("wear"): out.append(cn.get_node("wear"))
			"glow":
				for nm in ["glow_halo", "glow_pool"]:
					if cn.get_node_or_null(nm): out.append(cn.get_node(nm))
			"rooms":      # B14: the awake walk-in rooms (C++ CityRooms puts each under its building as "room")
				var bn2 := cn.get_node_or_null("Buildings")
				if bn2:
					for b2: Node in bn2.get_children():
						if b2.get_node_or_null("room"): out.append(b2.get_node("room"))
			"misc":
				var m := cn.get_node_or_null("Misc")
				if m: out.append_array(m.get_children())
			"bldg_near", "bldg_mid":
				var bn := cn.get_node_or_null("Buildings")
				if bn:
					for b: Node in bn.get_children():
						var t := b.get_node_or_null("near" if kind == "bldg_near" else "mid")
						if t: out.append(t)
			"plants", "props_near", "props_mid", "props_other", "plants_mid":
				var pn := cn.get_node_or_null("Props")
				if pn == null: continue
				for g2: Node in pn.get_children():
					if _census_prop_kind(g2 as GeometryInstance3D) == kind or (kind == "plants" and _census_prop_kind(g2 as GeometryInstance3D) == "plants_mid"): out.append(g2)
	return out

func _census_prop_kind(g: GeometryInstance3D) -> String:
	var m := g.material_override as ShaderMaterial
	if m == null: return "props_other"
	var f: String = (st.baked_shader(m) as Shader).resource_path.get_file()
	var re: Variant = m.get_shader_parameter(&"range_end")      # (not stored when it is the shader default, 60)
	var mid := re != null and float(re) > 61.0
	if f.begins_with("rt_foliage"): return "plants_mid" if mid else "plants"
	if f.begins_with("rt_prop"): return "props_mid" if mid else "props_near"
	return "props_other"

func _census_hide(nodes: Array) -> void:
	for n: Node in nodes:
		var g := n as Node3D
		if g == null: continue
		var was := g.visible; g.visible = false
		_cz_undo.append(func() -> void: g.visible = was)

## the materials of a kind of prop batch, each once
func _census_prop_mats(kind: String) -> Array:
	var seen := {}
	for n: Node in _census_nodes(kind):
		var m := (n as GeometryInstance3D).material_override
		if m: seen[m] = true
	return seen.keys()

func _census_swap_shader(mats: Array, defines: Array) -> void:
	for m: ShaderMaterial in mats:
		var was := m.shader; m.shader = st.shader_variant(st.baked_shader(m), defines)
		_cz_undo.append(func() -> void: m.shader = was)

func _census_cheap_bldg(tiers: Array) -> void:
	for tname: String in tiers:
		for n: Node in _census_nodes("bldg_" + tname):
			var mi := n as MeshInstance3D; var was := mi.get_surface_override_material(0) as ShaderMaterial
			if was == null or not st.baked_shader(was).resource_path.ends_with("rt_bldg.gdshader"): continue
			if not _cz_mat_cache.has(was):
				var c := was.duplicate() as ShaderMaterial; c.shader = st.shader_variant(st.baked_shader(was), ["CK_CHEAP"]); _cz_mat_cache[was] = c
			mi.set_surface_override_material(0, _cz_mat_cache[was])
			_cz_undo.append(func() -> void: mi.set_surface_override_material(0, was))

func _census_apply(state: String) -> void:
	var R := RenderingServer
	if state.begins_with("hide_"):
		var kind := state.trim_prefix("hide_")
		_census_hide(_census_nodes(kind))
		if kind == "plants": _census_hide(_census_nodes("plants_mid"))
	elif state == "shadows_off":
		sun.shadow_enabled = false; _cz_undo.append(func() -> void: sun.shadow_enabled = true)
	elif state.begins_with("shadow_map_"):
		var sz := int(state.trim_prefix("shadow_map_")); var was := int(ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/size", 4096))
		R.directional_shadow_atlas_set_size(sz, true); _cz_undo.append(func() -> void: R.directional_shadow_atlas_set_size(was, true))
	elif state == "fxaa_off":
		var vp := get_viewport(); vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED; _cz_undo.append(func() -> void: vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA)
	elif state == "sky_reflection_off":
		var was2 := env.reflected_light_source; env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED; _cz_undo.append(func() -> void: env.reflected_light_source = was2)
	elif state.begins_with("scale_"):
		var vp2 := get_viewport(); vp2.scaling_3d_scale = float(state.trim_prefix("scale_")); _cz_undo.append(func() -> void: vp2.scaling_3d_scale = float(opt.scale))
	elif state == "cheap_bldg_mid": _census_cheap_bldg(["mid"])
	elif state == "cheap_bldg_all": _census_cheap_bldg(["near", "mid"])
	elif state == "cheap_props_mid": _census_swap_shader(_census_prop_mats("props_mid"), ["CK_CHEAP"])
	elif state == "cheap_plants_mid": _census_swap_shader(_census_prop_mats("plants_mid"), ["CK_CHEAP"])
	elif state == "plants_opaque":
		var cut: Array = []
		for m: Material in _census_prop_mats("plants") + _census_prop_mats("plants_mid"):
			if st.baked_shader(m as ShaderMaterial).resource_path.contains("_cut"): cut.append(m)
		_census_swap_shader(cut, ["CK_OPAQUE"])
	elif state == "lights_0" or state == "lights_1":
		var i := 0
		for l: Node in lights.get_children():
			if l is OmniLight3D:
				var ol := l as OmniLight3D; var was3 := ol.visible
				if i >= (1 if state == "lights_1" else 0): ol.visible = false
				_cz_undo.append(func() -> void: ol.visible = was3); i += 1
	elif state.begins_with("look_") and state.ends_with("_off"):
		var parts: Array = LOOK_PARTS if state == "look_parts_off" else [state.trim_prefix("look_").trim_suffix("_off")]
		for part: String in parts:
			var gname := StringName("ck_look_" + part)
			RenderingServer.global_shader_parameter_set(gname, 0.0)      # (back to 1 = on: the census runs with the look's parts at their default)
			_cz_undo.append(func() -> void: RenderingServer.global_shader_parameter_set(gname, 1.0))
	elif state == "window_glow_off":
		var mats := {}
		for tname in ["near", "mid"]:
			for n: Node in _census_nodes("bldg_" + tname):
				var m2 := (n as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial
				if m2 and m2.get_shader_parameter(&"has_emission") == true: mats[m2] = true
		for m3: ShaderMaterial in mats.keys():
			m3.set_shader_parameter(&"has_emission", false); _cz_undo.append(func() -> void: m3.set_shader_parameter(&"has_emission", true))

func _census_undo() -> void:
	for i in range(_cz_undo.size() - 1, -1, -1): (_cz_undo[i] as Callable).call()
	_cz_undo.clear()

func _census_frames(secs: float, p: Vector3) -> Dictionary:
	var R := RenderingServer; var vr := get_viewport().get_viewport_rid()
	var g := PackedFloat32Array(); var c := PackedFloat32Array(); var dr := 0; var tr := 0
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < int(secs * 1000.0):
		st.update_focus(p, false)
		await get_tree().process_frame
		g.append(R.viewport_get_measured_render_time_gpu(vr)); c.append(R.viewport_get_measured_render_time_cpu(vr))
		dr += int(R.get_rendering_info(R.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)); tr += int(R.get_rendering_info(R.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	var n := maxi(g.size(), 1); g.sort(); c.sort()
	return {"gpu": g[g.size() / 2] if g.size() else -1.0, "gpu95": g[int(g.size() * 0.95)] if g.size() else -1.0, "cpu": c[c.size() / 2] if c.size() else -1.0, "draws": dr / n, "tris": tr / n, "frames": g.size()}

func _census_state(view: String, state: String, p: Vector3, base: float, secs: float) -> float:
	_census_apply(state)
	for i in 2: await _census_frames(0.25, p)      # settle: the new state's first frames (a shader built for the first time) are not counted
	var r: Dictionary = await _census_frames(secs, p)
	_census_undo()
	var save := base - float(r.gpu) if base > 0.0 else 0.0
	_say("census %s %s gpu_ms med=%.2f p95=%.2f saves=%.2f | draw_cpu_ms med=%.2f | draws=%d tris=%dk frames=%d" % [view, state, float(r.gpu), float(r.gpu95), save, float(r.cpu), int(r.draws), int(r.tris) / 1000, int(r.frames)])
	return float(r.gpu)

## the first frames after day turns to night, three ways: everything as the rig does it, without the sky's colours
## (the sky's reflection is rendered again when they change), and the sky's colours alone
func _census_flip(view: String, how: String, p: Vector3) -> void:
	var R := RenderingServer; var vr := get_viewport().get_viewport_rid()
	if how == "full": _night(1.0); lights.update_lights(p, 1.0)      # as the drives do it (with the look: the look's night)
	else:      # the old plain sky only (--look=0): night without the sky's colours, or the sky's colours alone
		var sm := env.sky.sky_material as ProceduralSkyMaterial
		if how != "sky_only": st.set_night(1.0); sun.light_energy = 0.04; env.ambient_light_energy = 0.22; lights.update_lights(p, 1.0)
		if how != "no_sky": sm.sky_top_color = Color(0.01, 0.015, 0.04); sm.sky_horizon_color = Color(0.05, 0.06, 0.1)
	var gs: Array = []; var worst := 0.0; var t_prev := Time.get_ticks_usec(); var fw := 0.0
	for i in 45:
		await get_tree().process_frame
		var now := Time.get_ticks_usec(); fw = maxf(fw, (now - t_prev) / 1000.0); t_prev = now
		var gv := R.viewport_get_measured_render_time_gpu(vr); worst = maxf(worst, gv)
		if i < 12: gs.append("%.0f" % gv)
	_say("census %s flip_%s gpu_ms first frames %s | worst gpu %.1f, worst frame %.0f ms (45 frames)" % [view, how, " ".join(gs), worst, fw])
	_night(0.0); lights.update_lights(p, 0.0)
	for i2 in 40: await get_tree().process_frame

func _census() -> void:
	var which := String(opt.census); var secs := float(opt.censussecs)
	if look == null:      # the whole look off (--look=0): its shader parts off too, so the city draws as before the look
		for part: String in LOOK_PARTS: RenderingServer.global_shader_parameter_set(StringName("ck_look_" + part), 0.0)
	_say("census look=%s glow=%s reflect=%s" % [String(opt.look), str(opt.get("glow", "?")), str(opt.get("reflect", "?"))])
	var only: PackedStringArray = String(opt.views).split(",", false)
	for v: Array in CENSUS_VIEWS:
		if not only.is_empty() and not (String(v[0]) in only): continue
		var name := String(v[0]); var p := Vector3(float(v[1]), 0, float(v[2])); var dir := Vector3(float(v[3]), 0, float(v[4]))
		_night(0.0)
		await _shot_ready(p)
		var gy: float = await _shot_ground(p); _shot_last_y = gy
		cam.global_position = Vector3(p.x, gy + 1.6, p.z); cam.look_at(cam.global_position + dir * 50.0)
		await _shot_ready(p)
		_say("census %s view at (%.0f, %.0f) looking (%.0f, %.0f) battery_temp=%s cells=%d" % [name, p.x, p.z, dir.x, dir.z, _census_temp(), st.loaded_count()])
		if which != "night":
			var base := -1.0
			for s: String in CENSUS_DAY:
				var gv: float = await _census_state(name, s, p, base, secs)
				if s == "baseline" and base < 0.0: base = gv
		if which != "day":
			await _census_flip(name, "full", p)
			if look == null and env.sky.sky_material is ProceduralSkyMaterial:
				await _census_flip(name, "no_sky", p)
				await _census_flip(name, "sky_only", p)
			await _census_flip(name, "full", p)      # again: is it only the first time?
			_night(1.0); lights.update_lights(p, 1.0)
			for i in 60: await get_tree().process_frame
			var nbase := -1.0
			for s2: String in CENSUS_NIGHT:
				var gv2: float = await _census_state(name + "_night", s2, p, nbase, secs)
				if s2 == "baseline" and nbase < 0.0: nbase = gv2
			_night(0.0); lights.update_lights(p, 0.0)
		_say("census %s done battery_temp=%s" % [name, _census_temp()])
	_say("plan_done census")
