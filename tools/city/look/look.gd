extends Node
## LOOK PACK, sky half (18 Nov; Yasin: "we need a visible jump"). Sky, distance haze, light colours and the colour
## treatment for the baked city. The rig adds this node with --look=1 (the default) and builds its old plain setup
## with --look=0, so the same drive can be run with and without. Read docs/LOOK_SKY.md.
##
## Made for a phone that is limited by PIXELS (docs/RUNTIME_BAKE.md "The phone test"). What each part adds per pixel:
##  - SKY (sky.gdshader): takes the place of the old sky in the same pass, only on pixels no building covers:
##    2 reads of one 256 x 256 texture by day, 3 at night. No extra pass.
##  - HAZE (the engine's plain distance fog): one exp() and one blend per pixel of every surface, no texture read.
##    `fog_aerial_perspective` stays 0 (it would read the sky cube map per pixel) and there is no height fog and no
##    volumetric fog. The fog colour is the sky's horizon colour, so the far city fades into the sky.
##  - WARM SUN, COOL SHADE: only the colours of the sun and of the ambient light. Nothing per pixel.
##  - TONEMAP + GRADE: in the last pass, which runs anyway (it scales the 720p picture up and smooths edges): the
##    tonemap curve, then ONE read of a 16 x 16 x 16 colour table (12 KB, built at start) per screen pixel.
##  - LAMP GLOW (glow.gdshader, look job 3): the same quads as before, a few more arithmetic steps, no texture read;
##    halos 1.8 x wider (small quads), pools 0.85 x (the big overlapping ones: fewer pixels than before).
##  - BLOB SHADOWS (blob_shadows.gd + blob.gdshader, look job 4, OFF by default): one draw a cell, only beyond ~40 m,
##    a multiply blend of small far quads, no texture read.
##  - SKY MAP (look job 5): the sky drawn into a 128 x 64 panorama when the time of day changes (8,192 pixels, once),
##    global ck_sky_map for glass and wet ground (sky_reflect.gdshaderinc): one read on those pixels only. --wet DEMO
##    swaps the ground's shader for rt_ground + the snippet: one more read (puddles) + one (sky map) per ground pixel.
##  - SEA (C++ CitySea + sea.gdshader, queue 2 job 3): one draw (~33k triangles) in the place of the green plane; unshaded;
##    per water pixel 3 texture reads (two ripple reads + the sky map) and ~40 arithmetic steps.
##  - AIR (air.gd + air.gdshader, queue 2 job 5, OFF by default): one draw of small alpha quads moved by the shader.
##  - BLOOM: only with --bloom=1 (off by default): a blur chain at 1/4 .. 1/16 size plus one read per pixel. Measure
##    it on the phone before it is kept (Yasin 18 Nov: "does the bloom cost that much?").
##  - NOT used, on purpose: SSAO, SSR, volumetric fog, depth of field.
## Nothing here touches a piece, the bake or a shader of the city (city_kit/shaders): only the Environment and the sun.

const SKY_SHADER_PATH := "res://tools/city/look/sky.gdshader"
const NOISE_PATH := "res://tools/city/look/sky_noise.png"
const Blobs := preload("res://tools/city/look/blob_shadows.gd")
const DayCycle := preload("res://tools/city/look/day_cycle.gd")
const Weather := preload("res://tools/city/look/weather.gd")
const Air := preload("res://tools/city/look/air.gd")
## the moon: where the night's light comes from (the same direction the night used before the running day)
const MOON_ELEV := 40.0
const MOON_AZIM := -35.0

## Day and night. `set_night(v)` blends the two (v 0..1), so a dusk in between works too.
## The target (Yasin 18 Nov): "a gta 4 like look": smoggy air, a pale washed sky, warm yellow-brown light, soft
## contrast, colours held back; nights of orange street light under a sky that glows brown-orange over the city.
const DAY := {
	"zenith": Color(0.33, 0.48, 0.68), "middle": Color(0.57, 0.65, 0.74), "haze": Color(0.80, 0.78, 0.71),      # smog: yellow-grey, not blue
	"sun_color": Color(1.0, 0.87, 0.66), "sun_energy": 1.55,                  # warm amber sun ...
	"ambient_color": Color(0.60, 0.64, 0.69), "ambient_energy": 0.8,          # ... grey-blue shade
	"fog_density": 0.0017, "fog_sun_scatter": 0.25,
	# queue 3 (Yasin: "i go for gta4 look", the palette stays): the clouds readable from the street, the sky NOT bluer:
	# they reach lower (cloud_low 0.2 -> 0.1), crisper edges (0.24 -> 0.18), brighter tops and greyer undersides
	"cloud_lit": Color(1.0, 0.96, 0.89), "cloud_dark": Color(0.54, 0.55, 0.57), "cloud_cover": 0.5, "cloud_alpha": 0.9, "cloud_scale": 0.2, "cloud_low": 0.1, "cloud_soft": 0.18,
	"sun_halo": 0.7, "sun_disc": 6.0, "disc_cos": 0.9993, "stars": 0.0}
const NIGHT := {
	"zenith": Color(0.018, 0.018, 0.026), "middle": Color(0.06, 0.047, 0.042), "haze": Color(0.21, 0.135, 0.075),      # the city's light in the smog
	"sun_color": Color(0.60, 0.66, 0.85), "sun_energy": 0.16,                 # the same light is the moon
	"ambient_color": Color(0.44, 0.38, 0.34), "ambient_energy": 0.6,          # dark brown-grey, still readable
	"fog_density": 0.0021, "fog_sun_scatter": 0.15,
	"cloud_lit": Color(0.24, 0.16, 0.10), "cloud_dark": Color(0.09, 0.07, 0.06), "cloud_cover": 0.5, "cloud_alpha": 0.8, "cloud_scale": 0.2, "cloud_low": 0.2, "cloud_soft": 0.24,      # lit from below by the city
	"sun_halo": 0.3, "sun_disc": 1.4, "disc_cos": 0.99975, "stars": 0.35}     # few stars through the smog

## TIMES OF DAY (job 1): whole presets of the same look, chosen with `--look=NAME` (rig) or `set_preset(NAME)`.
## Each is a full table like DAY plus: "elev" / "azim" sun height and direction in degrees, "lights" 0..1 how far the
## city's night is on (windows, lamp halos, real lamp lights: the streamer's ck_night). Cost: the same as the look
## itself (only numbers change); a preset change redraws the sky's reflection map once.
static var PRESETS := {
	"morning": {      # low sun from the east, a light morning haze (queue 3: half the old mist, warm sun / cool shade)
		"elev": 16.0, "azim": 105.0, "lights": 0.0, "moon": 0.0, "grade": "gta",
		"zenith": Color(0.30, 0.48, 0.74), "middle": Color(0.62, 0.70, 0.80), "haze": Color(0.84, 0.84, 0.82),
		"sun_color": Color(1.0, 0.82, 0.62), "sun_energy": 1.45, "ambient_color": Color(0.52, 0.60, 0.76), "ambient_energy": 0.7,
		"fog_density": 0.0016, "fog_sun_scatter": 0.45,
		"cloud_lit": Color(1.0, 0.93, 0.86), "cloud_dark": Color(0.60, 0.64, 0.72), "cloud_cover": 0.36, "cloud_alpha": 0.85, "cloud_scale": 0.2, "cloud_low": 0.1, "cloud_soft": 0.2,
		"sun_halo": 0.8, "sun_disc": 6.0, "disc_cos": 0.9993, "stars": 0.0},
	"noon": {         # high, white-hot sun, short shadows, the smog flat and bright
		"elev": 64.0, "azim": -35.0, "lights": 0.0, "moon": 0.0,
		"zenith": Color(0.30, 0.46, 0.70), "middle": Color(0.56, 0.65, 0.76), "haze": Color(0.83, 0.81, 0.75),
		"sun_color": Color(1.0, 0.95, 0.86), "sun_energy": 1.65, "ambient_color": Color(0.62, 0.66, 0.72), "ambient_energy": 0.8,
		"fog_density": 0.0015, "fog_sun_scatter": 0.2,
		"cloud_lit": Color(1.0, 0.98, 0.94), "cloud_dark": Color(0.64, 0.66, 0.68), "cloud_cover": 0.42, "cloud_alpha": 0.85, "cloud_scale": 0.2,
		"sun_halo": 0.6, "sun_disc": 6.0, "disc_cos": 0.9993, "stars": 0.0},
	"day": DAY.merged({"elev": 40.0, "azim": -35.0, "lights": 0.0, "moon": 0.0}),
	# queue 3, job 2: two more days for Yasin to choose from (the default stays "day", the GTA 4 palette he asked for)
	"day_half": {     # half the haze and half the held-back colour
		"elev": 40.0, "azim": -35.0, "lights": 0.0, "moon": 0.0, "grade": "half",
		"zenith": Color(0.26, 0.45, 0.73), "middle": Color(0.52, 0.66, 0.82), "haze": Color(0.77, 0.80, 0.80),
		"sun_color": Color(1.0, 0.90, 0.74), "sun_energy": 1.55, "ambient_color": Color(0.58, 0.64, 0.73), "ambient_energy": 0.8,
		"fog_density": 0.00085, "fog_sun_scatter": 0.2,
		"cloud_lit": Color(0.99, 0.97, 0.93), "cloud_dark": Color(0.62, 0.65, 0.70), "cloud_cover": 0.46, "cloud_alpha": 0.9, "cloud_scale": 0.2, "cloud_low": 0.1, "cloud_soft": 0.2,
		"sun_halo": 0.7, "sun_disc": 6.0, "disc_cos": 0.9993, "stars": 0.0},
	"day_clear": {    # a clear Coronado day: blue sky, haze only low at the horizon, the city's own colours kept
		"elev": 40.0, "azim": -35.0, "lights": 0.0, "moon": 0.0, "grade": "clear",
		"zenith": Color(0.20, 0.42, 0.78), "middle": Color(0.48, 0.66, 0.88), "haze": Color(0.74, 0.81, 0.88),
		"sun_color": Color(1.0, 0.95, 0.86), "sun_energy": 1.6, "ambient_color": Color(0.55, 0.63, 0.78), "ambient_energy": 0.8,
		"fog_density": 0.0007, "fog_sun_scatter": 0.15,
		"cloud_lit": Color(1.0, 1.0, 1.0), "cloud_dark": Color(0.68, 0.72, 0.80), "cloud_cover": 0.42, "cloud_alpha": 0.95, "cloud_scale": 0.2, "cloud_low": 0.06, "cloud_soft": 0.16,
		"sun_halo": 0.6, "sun_disc": 7.0, "disc_cos": 0.9993, "stars": 0.0},
	"golden": {       # late afternoon (queue 3: golden, not brown): a low strong orange sun along the streets, long
		# shadows, warm walls against blue shade; the haze thinner and lighter so it does not turn into a brown fog
		"elev": 12.0, "azim": -80.0, "lights": 0.0, "moon": 0.0, "grade": "gta",
		"zenith": Color(0.26, 0.42, 0.68), "middle": Color(0.74, 0.66, 0.58), "haze": Color(0.95, 0.78, 0.56),
		"sun_color": Color(1.0, 0.64, 0.34), "sun_energy": 1.85, "ambient_color": Color(0.56, 0.55, 0.64), "ambient_energy": 0.92,
		"fog_density": 0.0011, "fog_sun_scatter": 0.5,
		"cloud_lit": Color(1.0, 0.78, 0.52), "cloud_dark": Color(0.45, 0.42, 0.48), "cloud_cover": 0.44, "cloud_alpha": 0.9, "cloud_scale": 0.2, "cloud_low": 0.1, "cloud_soft": 0.2,
		"sun_halo": 1.0, "sun_disc": 5.0, "disc_cos": 0.9992, "stars": 0.0},
	"dusk": {         # the sun just down: pink-orange west, blue east, windows and lamps coming on
		"elev": 3.0, "azim": -95.0, "lights": 0.65, "moon": 0.0,
		"zenith": Color(0.09, 0.12, 0.24), "middle": Color(0.40, 0.31, 0.38), "haze": Color(0.62, 0.42, 0.36),
		"sun_color": Color(1.0, 0.50, 0.32), "sun_energy": 0.38, "ambient_color": Color(0.42, 0.42, 0.55), "ambient_energy": 0.55,
		"fog_density": 0.002, "fog_sun_scatter": 0.9,
		"cloud_lit": Color(0.95, 0.55, 0.42), "cloud_dark": Color(0.30, 0.24, 0.30), "cloud_cover": 0.46, "cloud_alpha": 0.85, "cloud_scale": 0.2,
		"sun_halo": 1.2, "sun_disc": 0.0, "disc_cos": 0.9993, "stars": 0.08},
	"night": NIGHT.merged({"elev": -30.0, "azim": 180.0, "lights": 1.0, "moon": 1.0}),
	"overcast": {     # a grey lid: soft light from everywhere, no sun to speak of, thick haze
		"elev": 50.0, "azim": -35.0, "lights": 0.0, "moon": 0.0,
		"zenith": Color(0.55, 0.57, 0.60), "middle": Color(0.64, 0.66, 0.68), "haze": Color(0.70, 0.71, 0.70),
		"sun_color": Color(0.92, 0.93, 0.95), "sun_energy": 0.32, "ambient_color": Color(0.70, 0.71, 0.73), "ambient_energy": 1.12,
		"fog_density": 0.0026, "fog_sun_scatter": 0.05,
		"cloud_lit": Color(0.78, 0.78, 0.79), "cloud_dark": Color(0.50, 0.51, 0.53), "cloud_cover": 0.93, "cloud_alpha": 1.0, "cloud_scale": 0.2,
		"sun_halo": 0.1, "sun_disc": 0.0, "disc_cos": 0.9993, "stars": 0.0}}

@export var sun_angles := Vector3(-40, -35, 0)      ## the old rig: -48 (higher); lower = longer shadows, more light on walls
@export var cloud_speed := Vector2(0.0008, 0.0003)  ## texture units a second; 0 = still
@export var shadow_distance := 50.0                 ## the game's sun shadow distance (unchanged)
@export var bloom := false                          ## glow round bright things (GTA 4 has it). COSTS PIXELS: off by default, see docs/LOOK_SKY.md
@export var glow := true                            ## lamp halos and pools drawn by tools/city/look/glow.gdshader (look job 3); false = the bake's
@export var blobs := false                          ## soft tree shadows beyond the sun shadow (look job 4). Reads each cell's meshes: off for phone drives
@export_range(0.0, 1.0) var wet := 0.0             ## look job 5: 0 dry .. 1 after rain (global ck_wet; the ground demo below)
@export var shadow_tune := true                     ## queue 3 job 5: the sun shadow's end fades out, 2 blended splits, softness by time of day
@export var cars := false                           ## look queue 2 job 6 DEMO: the preview cars parked on the cells' stalls (one draw a car)
@export var car_env := true                         ## the cars reflect the look's sky (car_env.gdshader); false = as before (nothing)
@export var air := false                            ## look queue 2 job 5: gulls, a plane, smoke (air.gd, one draw); off until measured
@export var weather := ""                           ## look queue 2 job 4: mist, hazy, storm, rain (weather.gd) over the time of day
@export var sea := true                             ## look queue 2 job 3: the sea in the place of the green plane (sea.gd)
@export var celestial := true                       ## look queue 2 job 2: sun glare, the moon, new stars; false = the sky as before
@export var cycle := 0.0                            ## look job 2.1: seconds for a whole day (0 = no running day)
@export var hour := 7.0                             ## the clock of the running day
@export var cycle_step := 0.5                       ## seconds between two updates of the sky (and its reflection maps)
@export_range(0.0, 1.0) var grade := 1.0           ## strength of the colour grade (the lookup table); 0 = none

var env: Environment
var sun: DirectionalLight3D
var sky_mat: ShaderMaterial
var night := 0.0
var preset := ""                ## a time of day from PRESETS ("" = day / night by set_night)
var _drift := Vector2.ZERO
var _stream: Node
var _cycle_t := 0.0
var _map_ms := [0.0, 0.0]       # worst GPU / CPU ms of one sky-map redraw seen (running day)
var _map_seen := 0
var _step_ms := 0.0
static var _drift_added := false
static var _map_added := false
var sky_map: SubViewport        # look job 5: the sky as a 128 x 64 panorama for reflections (global ck_sky_map)
var _map_mat: ShaderMaterial
var car_map: SubViewport        # queue 2 job 6: the sky map in the car shader's layout (env_pano)
static var _refl_added := false
var _luts := {}

func _ready() -> void:
	# the clouds' drift is a global shader value: add it before the sky shader is loaded (it will not compile without)
	if not _drift_added:
		RenderingServer.global_shader_parameter_add(&"ck_sky_drift", RenderingServer.GLOBAL_VAR_TYPE_VEC2, Vector2.ZERO); _drift_added = true
	sky_mat = ShaderMaterial.new(); sky_mat.shader = load(SKY_SHADER_PATH)
	sky_mat.set_shader_parameter(&"noise_tex", load(NOISE_PATH))
	var sky := Sky.new(); sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_128      # the reflection map (ambient is a plain colour): small, so a redraw at a time-of-day change is cheap
	env = Environment.new()
	env.background_mode = Environment.BG_SKY; env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR      # (sky ambient would cost a cube map read per pixel)
	env.fog_enabled = true; env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_aerial_perspective = 0.0; env.fog_sky_affect = 0.0; env.fog_height_density = 0.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; env.tonemap_exposure = 1.05; env.tonemap_white = 6.0
	env.adjustment_enabled = true; env.adjustment_brightness = 1.0; env.adjustment_contrast = 1.0; env.adjustment_saturation = 1.0
	if grade > 0.0:
		for gs: String in GRADES: _luts[gs] = make_grade_lut(grade, 16, gs)      # three small tables, built once (~10 ms each)
		env.adjustment_color_correction = _luts.gta
	if bloom:      # a blur chain of the picture at 1/2 .. 1/16 size, then one more read per pixel in the last pass
		env.glow_enabled = true; env.glow_normalized = true
		for i in 7: env.set_glow_level(i, 0.0)
		env.set_glow_level(1, 0.5); env.set_glow_level(2, 0.8); env.set_glow_level(3, 0.6)      # mid-size soft glow; no level 0 (half-size is the dearest)
		env.glow_intensity = 0.7; env.glow_strength = 1.0; env.glow_bloom = 0.04; env.glow_hdr_threshold = 0.9; env.glow_hdr_scale = 2.0
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	# look job 5: the small sky map. Drawn only when the time of day changes (UPDATE_ONCE in _apply).
	sky_map = SubViewport.new(); sky_map.size = Vector2i(128, 64); sky_map.use_hdr_2d = true; sky_map.transparent_bg = false
	sky_map.render_target_update_mode = SubViewport.UPDATE_ONCE; sky_map.disable_3d = true
	var rect := ColorRect.new(); rect.size = Vector2(128, 64)
	_map_mat = ShaderMaterial.new(); _map_mat.shader = load("res://tools/city/look/sky_map.gdshader"); _map_mat.set_shader_parameter(&"noise_tex", load(NOISE_PATH))
	rect.material = _map_mat; sky_map.add_child(rect); add_child(sky_map)
	if not _map_added:      # (in the game: project.godot [shader_globals], see sky_reflect.gdshaderinc)
		RenderingServer.global_shader_parameter_add(&"ck_sky_map", RenderingServer.GLOBAL_VAR_TYPE_SAMPLER2D, sky_map.get_texture())
		RenderingServer.global_shader_parameter_add(&"ck_wet", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, wet); _map_added = true
	else: RenderingServer.global_shader_parameter_set(&"ck_sky_map", sky_map.get_texture())
	if sea:      # one draw, built once; C++ CitySea (native/src/city_sea.*), drawn after the city (20 Nov: 13 ms at the waterfront)
		var sea_mi: Node = ClassDB.instantiate(&"CitySea"); sea_mi.call(&"build"); add_child(sea_mi)
	if air: add_child(Air.build())      # one draw, nothing per frame
	if cars:      # the game's car shader needs its global refl_env (x daylight, y cloud) before it is loaded
		if not _refl_added and not RenderingServer.global_shader_parameter_get_list().has(&"refl_env"):      # (the game: project.godot [shader_globals], 21 Nov)
			RenderingServer.global_shader_parameter_add(&"refl_env", RenderingServer.GLOBAL_VAR_TYPE_VEC2, Vector2(1.0, 0.0)); _refl_added = true
		car_map = SubViewport.new(); car_map.size = Vector2i(128, 128); car_map.use_hdr_2d = true; car_map.disable_3d = true
		car_map.render_target_update_mode = SubViewport.UPDATE_ONCE
		var cr := ColorRect.new(); cr.size = Vector2(128, 128); var cm := ShaderMaterial.new(); cm.shader = load("res://tools/city/look/car_env.gdshader")
		cr.material = cm; car_map.add_child(cr); add_child(car_map)
	sun = DirectionalLight3D.new(); sun.rotation_degrees = sun_angles
	sun.shadow_enabled = OS.get_environment("NOSHADOW") != "1"; sun.directional_shadow_max_distance = shadow_distance; add_child(sun)
	if shadow_tune:      # the 50 m stay; what changes is how the shadow ends
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS      # (the engine's default is 4 splits: two shadow passes less)
		sun.directional_shadow_split_1 = 0.25                                           # near split to 12.5 m: sharp under the car, softer beyond
		sun.directional_shadow_blend_splits = true                                      # no line where the two splits meet
		sun.directional_shadow_fade_start = 0.6                                         # the shadow fades out over its last 20 m (30 -> 50 m)
	if weather == "rain" and wet <= 0.0: wet = 0.65      # rain wets the ground (before the cells come in: attach_stream)
	if cycle > 0.0:
		sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL      # the reflection map is redrawn over several frames, not in one
		RenderingServer.viewport_set_measure_render_time(sky_map.get_viewport_rid(), true)
		set_hour(hour)
	else: set_night(night)

## LOOK JOB 3: the lamps' glow. Each cell's glow_halo / glow_pool node gets the look's glow material when the cell
## comes in (two shared materials, nothing per frame; the bake's energy per kind is kept).
var _glow_mats := {}
func attach_stream(st: Node) -> void:
	_stream = st
	if not glow and not blobs and wet <= 0.0 and not cars: return
	st.cell_in.connect(func(k: String) -> void: _restyle(st.cells[k].node))
	for k: String in st.cells:
		if st.cells[k].state == st.IN: _restyle(st.cells[k].node)

func _restyle(cell: Node) -> void:
	if cell == null: return
	if blobs and cell.get_node_or_null("look_blobs") == null:
		var b := Blobs.build(cell)
		if b: cell.add_child(b)
	if wet > 0.0: _wet_ground(cell)
	if cars and cell.get_node_or_null("look_cars") == null: _park(cell)
	# the fill's lagoons (21 Nov, tools/city/fill): their still water is drawn with the live sea material (the look's
	# light and sky), not the copy saved in the piece
	if sea:
		for w: Node in cell.find_children("*pond_*", "GeometryInstance3D", true, false):
			(w as GeometryInstance3D).material_override = ClassDB.class_call_static(&"CitySea", &"get_sea_material")
	if not glow: return
	for nm: String in ["glow_halo", "glow_pool"]:
		var g := cell.get_node_or_null(nm) as GeometryInstance3D
		if g == null: continue
		if not _glow_mats.has(nm):
			var old := g.material_override as ShaderMaterial
			var m := ShaderMaterial.new(); m.shader = load("res://tools/city/look/glow.gdshader")
			m.set_shader_parameter(&"billboard", nm == "glow_halo")
			m.set_shader_parameter(&"energy", old.get_shader_parameter(&"energy") if old else (1.6 if nm == "glow_halo" else 0.22))
			_glow_mats[nm] = m
		g.material_override = _glow_mats[nm]

## DEMO (look job 5, --wet above 0): each cell's ground drawn by demo_wet_ground.gdshader (rt_ground + the wet snippet)
var _wet_mat: ShaderMaterial
func _wet_ground(cell: Node) -> void:
	for g: Node in cell.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D; var sm := gi.material_override as ShaderMaterial
		if sm == null or sm.shader == null or not sm.shader.resource_path.ends_with("rt_ground.gdshader"): continue
		if _wet_mat == null:
			_wet_mat = ShaderMaterial.new(); _wet_mat.shader = load("res://tools/city/look/demo_wet_ground.gdshader")
			_wet_mat.set_shader_parameter(&"ground_arr", sm.get_shader_parameter(&"ground_arr")); _wet_mat.set_shader_parameter(&"puddle_tex", load(NOISE_PATH))
			_wet_mat.set_shader_parameter(&"debug", OS.get_environment("LOOK_DEBUG_WET") == "1")
		gi.material_override = _wet_mat

## DEMO (queue 2 job 6, --cars=1): the preview cars (vehicles/, read-only) on 3 in 4 of a cell's stalls, painted by
## the game's car shader with the look's sky as its env_pano. One draw a car: for pictures, not for phone drives.
const CAR_IDS := ["volt_s", "volt_x", "stern_e", "stern_g", "sakura", "sakura_t", "van"]
const CAR_COLS := [Color(0.92, 0.92, 0.92), Color(0.08, 0.08, 0.09), Color(0.6, 0.62, 0.65), Color(0.32, 0.33, 0.35), Color(0.55, 0.1, 0.1), Color(0.2, 0.28, 0.45), Color(0.43, 0.5, 0.38), Color(0.7, 0.62, 0.48)]
var _car_mats := {}
func _park(cell: Node) -> void:
	var stalls: Array = cell.get_meta(&"stalls", [])
	if stalls.is_empty(): return
	var holder := Node3D.new(); holder.name = "look_cars"; holder.top_level = true; cell.add_child(holder)
	var rr := RandomNumberGenerator.new(); rr.seed = hash(String(cell.name))
	for s: Array in stalls:
		if rr.randf() > 0.75: continue
		var id: String = CAR_IDS[rr.randi() % CAR_IDS.size()]; var ci := rr.randi() % CAR_COLS.size()
		if not _car_mats.has(ci):
			var m := ShaderMaterial.new(); m.shader = load("res://vehicles/car_paint.gdshader")
			m.set_shader_parameter(&"atlas", load("res://vehicles/models/Textures/car_atlas_1024.png")); m.set_shader_parameter(&"paint", CAR_COLS[ci])
			if car_env and car_map: m.set_shader_parameter(&"env_pano", car_map.get_texture())
			_car_mats[ci] = m
		var mi := MeshInstance3D.new(); mi.mesh = load("res://vehicles/models/lod/%s_q.res" % id); mi.material_override = _car_mats[ci]
		mi.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(float(s[3]) + (180.0 if rr.randf() < 0.2 else 0.0))), Vector3(float(s[0]), float(s[1]) + 0.02, float(s[2])))
		holder.add_child(mi)

func _process(dt: float) -> void:
	if cycle > 0.0:      # the running day: the clock moves every frame, the look follows every `cycle_step` seconds
		hour = fposmod(hour + 24.0 * dt / cycle, 24.0); _cycle_t += dt
		if _map_seen > 0 and _map_seen < 39:      # the redraw asked for in the last step: what did it cost?
			var rid := sky_map.get_viewport_rid()
			_map_ms[0] = maxf(_map_ms[0], RenderingServer.viewport_get_measured_render_time_gpu(rid)); _map_ms[1] = maxf(_map_ms[1], RenderingServer.viewport_get_measured_render_time_cpu(rid))
			if _map_seen == 38 and _cycle_t + dt >= cycle_step: print("RIG look running day: sky_map redraw worst gpu_ms=%.3f cpu_ms=%.3f (128 x 64), one step on the main thread worst %.3f ms (every %.1f s)" % [_map_ms[0], _map_ms[1], _step_ms, cycle_step])
		if _cycle_t >= cycle_step:
			var t0 := Time.get_ticks_usec()
			_cycle_t = 0.0; set_hour(hour); _map_seen += 1
			_step_ms = maxf(_step_ms, (Time.get_ticks_usec() - t0) / 1000.0)
	if cloud_speed == Vector2.ZERO: return
	_drift = (_drift + cloud_speed * dt).posmod(1.0)
	RenderingServer.global_shader_parameter_set(&"ck_sky_drift", _drift)

## The colour grade as a 16 x 16 x 16 lookup table, built here (a few ms, once): the engine reads it once per pixel in
## its last pass. What it does, in this order: holds colours back (saturation 0.72), cool-green shadows and warm
## yellow highlights, the whole picture a little warmer, a soft S-curve, and blacks lifted to a smoggy dark grey.
## the three grades (queue 3): "gta" the GTA 4 grade above (the default), "half" half the held-back colour, half the
## warm tint and half the lifted blacks, "clear" the city's own colours with only a gentle S-curve
const GRADES := {"gta": [0.72, 1.0, 0.22, 1.0], "half": [0.86, 0.5, 0.2, 0.5], "clear": [1.0, 0.0, 0.15, 0.0]}      # [saturation, tint, S-curve, lift]
static func grade_color(c: Color, k: float, style := "gta") -> Color:
	var g: Array = GRADES.get(style, GRADES.gta)
	var l := c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
	var v := Vector3(c.r, c.g, c.b)
	v = Vector3(l, l, l).lerp(v, float(g[0]))
	var sh := (1.0 - l) * (1.0 - l); var hi := l * l
	v += Vector3(-0.012, 0.004, 0.012) * sh * float(g[1])
	v *= Vector3(1.0, 1.0, 1.0) + Vector3(0.05, 0.03, -0.08) * hi * float(g[1])
	v *= Vector3(1.0, 1.0, 1.0).lerp(Vector3(1.03, 1.01, 0.93), float(g[1]))
	var s := Vector3(smoothstep(0.0, 1.0, v.x), smoothstep(0.0, 1.0, v.y), smoothstep(0.0, 1.0, v.z))
	v = v.lerp(s, float(g[2]))
	v = Vector3(0.022, 0.02, 0.016) * float(g[3]) + v * (1.0 - 0.035 * float(g[3]))
	v = Vector3(c.r, c.g, c.b).lerp(v, k)
	return Color(clampf(v.x, 0.0, 1.0), clampf(v.y, 0.0, 1.0), clampf(v.z, 0.0, 1.0))

static func make_grade_lut(k: float, n := 16, style := "gta") -> ImageTexture3D:
	var slices: Array[Image] = []
	for b in n:
		var img := Image.create(n, n, false, Image.FORMAT_RGB8)
		for g in n:
			for r in n:
				img.set_pixel(r, g, grade_color(Color(r / float(n - 1), g / float(n - 1), b / float(n - 1)), k, style))
		slices.append(img)
	var t := ImageTexture3D.new(); t.create(Image.FORMAT_RGB8, n, n, n, false, slices)
	return t

static func _mix(key: String, v: float) -> Variant:
	var a: Variant = DAY[key]; var b: Variant = NIGHT[key]
	if a is Color: return (a as Color).lerp(b as Color, v)
	return lerpf(float(a), float(b), v)

## 0 day .. 1 night. Call it when the time of day changes, not every frame: a change of the sky makes the engine
## redraw the sky's reflection cube map once. With a preset chosen, the preset wins (v is ignored).
func set_night(v: float) -> void:
	if cycle > 0.0: return      # the running day sets the time itself
	if preset != "": set_preset(preset); return
	night = clampf(v, 0.0, 1.0)
	var t := {}
	for k: String in DAY: t[k] = _mix(k, night)
	t["elev"] = -sun_angles.x; t["azim"] = sun_angles.y; t["lights"] = night; t["moon"] = 0.0      # (day / night by one number: the light stays where it was)
	_apply(t)

## the running day (and pictures of it): the look at an hour of the clock, 0..24
func set_hour(h: float) -> void:
	hour = fposmod(h, 24.0)
	_apply(DayCycle.at(hour, PRESETS))
	if _stream: _stream.set_night(night)

## a time of day (PRESETS), or "" to go back to set_night
func set_preset(name: String) -> void:
	preset = name if PRESETS.has(name) else ""
	if preset == "": set_night(night); return
	_apply(PRESETS[preset])

## how far the city's night is on for the current setting (the streamer's ck_night)
func lights() -> float:
	return night      # (_apply keeps it: the time of day's, raised by a gloomy weather)

## towards the sun (or moon). Azimuth: 90 = east (+X), 0 = south (+Z), -90 = west (-X): the sun's day runs from
## about +105 (morning) through 0 (noon) to -95 (dusk). (Before 18 Nov evening morning and golden were swapped.)
static func _dir(elev: float, azim: float) -> Vector3:
	return Basis.from_euler(Vector3(deg_to_rad(-elev), deg_to_rad(azim), 0.0)).z

func _apply(t0: Dictionary) -> void:
	var t := Weather.apply(t0, weather, hour if cycle > 0.0 or t0.has("hour") else -1.0)
	night = float(t.get("lights", night))
	# the light: the sun by day, the moon by night (blended by "moon", so the light never jumps)
	var sun_v := _dir(float(t.elev), float(t.azim)); var moon_v := _dir(MOON_ELEV, MOON_AZIM)
	var mo := clampf(float(t.get("moon", 0.0)), 0.0, 1.0)
	var light_v := (sun_v * (1.0 - mo) + moon_v * mo).normalized()
	if light_v.y < 0.03: light_v = Vector3(light_v.x, 0.03, light_v.z).normalized()      # never from under the ground
	sun.basis = Basis.looking_at(-light_v, Vector3.UP)
	var haze: Color = t.haze
	sun.light_color = t.sun_color; sun.light_energy = t.sun_energy
	if shadow_tune:      # a low sun's shadows are longer and softer; a weak sun (overcast, storm) throws faint ones
		sun.shadow_blur = lerpf(1.8, 1.0, clampf(float(t.elev) / 45.0, 0.0, 1.0))
		sun.shadow_opacity = clampf(0.3 + float(t.sun_energy) * 0.5, 0.3, 1.0)
	if cycle > 0.0 and not _luts.is_empty(): env.adjustment_color_correction = _luts.gta      # the running day: one table (switching would be a step)
	elif t.has("grade") and _luts.has(String(t.grade)): env.adjustment_color_correction = _luts[String(t.grade)]
	elif not _luts.is_empty(): env.adjustment_color_correction = _luts.gta
	env.ambient_light_color = t.ambient_color; env.ambient_light_energy = t.ambient_energy
	env.fog_light_color = haze; env.fog_light_energy = 1.0
	env.fog_density = t.fog_density; env.fog_sun_scatter = t.fog_sun_scatter
	for m: ShaderMaterial in [sky_mat, _map_mat]:      # the sky and its small map for reflections: the same numbers
		for k: String in ["zenith", "middle", "haze", "cloud_lit", "cloud_dark", "cloud_cover", "cloud_alpha", "cloud_scale", "sun_halo", "sun_disc", "disc_cos", "stars"]:
			m.set_shader_parameter(k, t[k])
		m.set_shader_parameter(&"cloud_low", float(t.get("cloud_low", 0.2))); m.set_shader_parameter(&"cloud_soft", float(t.get("cloud_soft", 0.24)))
		m.set_shader_parameter(&"sun_col", sun.light_color)
		m.set_shader_parameter(&"sun_dir", sun_v if celestial else (sun_v if mo < 0.5 else light_v))      # (before job 2 the night's disc was the light's)
		m.set_shader_parameter(&"moon_dir", moon_v)
		m.set_shader_parameter(&"moon_amount", clampf(maxf(mo, float(t.get("lights", 0.0)) * 0.5), 0.0, 1.0) if celestial else 0.0)      # up with the dusk
		m.set_shader_parameter(&"sun_glare", 0.35 if celestial else 0.0); m.set_shader_parameter(&"new_stars", celestial)
		m.set_shader_parameter(&"sun_scatter", sun.light_energy * env.fog_sun_scatter)      # the fog's own sun glow, so sky and fog agree
	sky_map.render_target_update_mode = SubViewport.UPDATE_ONCE
	if car_map: car_map.render_target_update_mode = SubViewport.UPDATE_ONCE
	var gl := Vector3(env.ambient_light_color.r, env.ambient_light_color.g, env.ambient_light_color.b) * env.ambient_light_energy + Vector3(sun.light_color.r, sun.light_color.g, sun.light_color.b) * sun.light_energy * maxf(light_v.y, 0.0) * 0.6
	_map_mat.set_shader_parameter(&"ground_col", gl * 0.11)      # asphalt-dark street under the horizon of the sky map
	# the building session's glass (claude/look-buildings, rt_bldg.gdshader) reflects a two-colour sky: keep it this sky
	if ProjectSettings.has_setting("shader_globals/ck_look_sky_top"):
		RenderingServer.global_shader_parameter_set(&"ck_look_sky_top", t.zenith.lerp(t.middle, 0.4))
		RenderingServer.global_shader_parameter_set(&"ck_look_sky_horizon", t.haze)
	RenderingServer.global_shader_parameter_set(&"ck_wet", wet)
	var sm: ShaderMaterial = ClassDB.class_call_static(&"CitySea", &"get_sea_material")      # the sea's own light (it is unshaded): ambient + the sun on a flat surface
	sm.set_shader_parameter(&"light", Vector3(env.ambient_light_color.r, env.ambient_light_color.g, env.ambient_light_color.b) * env.ambient_light_energy + Vector3(sun.light_color.r, sun.light_color.g, sun.light_color.b) * sun.light_energy * maxf(light_v.y, 0.0) * 0.55)
	sm.set_shader_parameter(&"sun_dir", sun_v if mo < 0.5 else moon_v)
	sm.set_shader_parameter(&"sun_light", Vector3(sun.light_color.r, sun.light_color.g, sun.light_color.b) * sun.light_energy)
	Air.material().set_shader_parameter(&"light", sm.get_shader_parameter(&"light"))
	var sk: ShaderMaterial = ClassDB.class_call_static(&"CitySkyline", &"get_skyline_material")      # the skyline ring (20 Nov): painted in the day haze, tinted to this hour's haze, lit windows by night
	sk.set_shader_parameter(&"tint", Vector3(haze.r / 0.80, haze.g / 0.78, haze.b / 0.71))
	sk.set_shader_parameter(&"haze_col", haze); sk.set_shader_parameter(&"haze_more", clampf((float(t.fog_density) - 0.001) / 0.004, 0.0, 0.5))
	sk.set_shader_parameter(&"lights", clampf(float(t.get("lights", night)), 0.0, 1.0))
	var bm := Blobs.material()      # the blob shadows follow the sun: where it stands, how strong (none at night)
	bm.set_shader_parameter(&"sun_dir", light_v)
	bm.set_shader_parameter(&"strength", 0.5 * clampf(sun.light_energy / 1.55, 0.0, 1.0) * (1.0 - float(t.get("lights", night))))
	bm.set_shader_parameter(&"haze", env.fog_density)
