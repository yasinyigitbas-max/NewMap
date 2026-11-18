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
##  - BLOOM: only with --bloom=1 (off by default): a blur chain at 1/4 .. 1/16 size plus one read per pixel. Measure
##    it on the phone before it is kept (Yasin 18 Nov: "does the bloom cost that much?").
##  - NOT used, on purpose: SSAO, SSR, volumetric fog, depth of field.
## Nothing here touches a piece, the bake or a shader of the city (city_kit/shaders): only the Environment and the sun.

const SKY_SHADER_PATH := "res://tools/city/look/sky.gdshader"
const NOISE_PATH := "res://tools/city/look/sky_noise.png"

## Day and night. `set_night(v)` blends the two (v 0..1), so a dusk in between works too.
## The target (Yasin 18 Nov): "a gta 4 like look": smoggy air, a pale washed sky, warm yellow-brown light, soft
## contrast, colours held back; nights of orange street light under a sky that glows brown-orange over the city.
const DAY := {
	"zenith": Color(0.33, 0.48, 0.68), "middle": Color(0.57, 0.65, 0.74), "haze": Color(0.80, 0.78, 0.71),      # smog: yellow-grey, not blue
	"sun_color": Color(1.0, 0.87, 0.66), "sun_energy": 1.55,                  # warm amber sun ...
	"ambient_color": Color(0.60, 0.64, 0.69), "ambient_energy": 0.8,          # ... grey-blue shade
	"fog_density": 0.0017, "fog_sun_scatter": 0.25,
	"cloud_lit": Color(0.96, 0.93, 0.86), "cloud_dark": Color(0.60, 0.61, 0.62), "cloud_cover": 0.5, "cloud_alpha": 0.85, "cloud_scale": 0.2,
	"sun_halo": 0.7, "sun_disc": 6.0, "disc_cos": 0.9993, "stars": 0.0}
const NIGHT := {
	"zenith": Color(0.018, 0.018, 0.026), "middle": Color(0.06, 0.047, 0.042), "haze": Color(0.21, 0.135, 0.075),      # the city's light in the smog
	"sun_color": Color(0.60, 0.66, 0.85), "sun_energy": 0.16,                 # the same light is the moon
	"ambient_color": Color(0.44, 0.38, 0.34), "ambient_energy": 0.6,          # dark brown-grey, still readable
	"fog_density": 0.0021, "fog_sun_scatter": 0.15,
	"cloud_lit": Color(0.24, 0.16, 0.10), "cloud_dark": Color(0.09, 0.07, 0.06), "cloud_cover": 0.5, "cloud_alpha": 0.8, "cloud_scale": 0.2,      # lit from below by the city
	"sun_halo": 0.3, "sun_disc": 1.4, "disc_cos": 0.99975, "stars": 0.35}     # few stars through the smog

## TIMES OF DAY (job 1): whole presets of the same look, chosen with `--look=NAME` (rig) or `set_preset(NAME)`.
## Each is a full table like DAY plus: "elev" / "azim" sun height and direction in degrees, "lights" 0..1 how far the
## city's night is on (windows, lamp halos, real lamp lights: the streamer's ck_night). Cost: the same as the look
## itself (only numbers change); a preset change redraws the sky's reflection map once.
static var PRESETS := {
	"morning": {      # low sun from the east through a cool morning mist
		"elev": 16.0, "azim": -105.0, "lights": 0.0,
		"zenith": Color(0.34, 0.50, 0.72), "middle": Color(0.64, 0.71, 0.80), "haze": Color(0.80, 0.82, 0.84),
		"sun_color": Color(1.0, 0.85, 0.70), "sun_energy": 1.25, "ambient_color": Color(0.58, 0.64, 0.74), "ambient_energy": 0.75,
		"fog_density": 0.0028, "fog_sun_scatter": 0.45,
		"cloud_lit": Color(1.0, 0.93, 0.86), "cloud_dark": Color(0.62, 0.65, 0.70), "cloud_cover": 0.36, "cloud_alpha": 0.8, "cloud_scale": 0.2,
		"sun_halo": 0.8, "sun_disc": 6.0, "disc_cos": 0.9993, "stars": 0.0},
	"noon": {         # high, white-hot sun, short shadows, the smog flat and bright
		"elev": 64.0, "azim": -35.0, "lights": 0.0,
		"zenith": Color(0.30, 0.46, 0.70), "middle": Color(0.56, 0.65, 0.76), "haze": Color(0.83, 0.81, 0.75),
		"sun_color": Color(1.0, 0.95, 0.86), "sun_energy": 1.65, "ambient_color": Color(0.62, 0.66, 0.72), "ambient_energy": 0.8,
		"fog_density": 0.0015, "fog_sun_scatter": 0.2,
		"cloud_lit": Color(1.0, 0.98, 0.94), "cloud_dark": Color(0.64, 0.66, 0.68), "cloud_cover": 0.42, "cloud_alpha": 0.85, "cloud_scale": 0.2,
		"sun_halo": 0.6, "sun_disc": 6.0, "disc_cos": 0.9993, "stars": 0.0},
	"day": DAY.merged({"elev": 40.0, "azim": -35.0, "lights": 0.0}),
	"golden": {       # late afternoon: low orange sun from the west, long shadows, amber haze
		"elev": 11.0, "azim": 80.0, "lights": 0.0,
		"zenith": Color(0.30, 0.42, 0.62), "middle": Color(0.70, 0.63, 0.58), "haze": Color(0.90, 0.71, 0.50),
		"sun_color": Color(1.0, 0.68, 0.40), "sun_energy": 1.45, "ambient_color": Color(0.50, 0.52, 0.62), "ambient_energy": 0.66,
		"fog_density": 0.0019, "fog_sun_scatter": 0.55,
		"cloud_lit": Color(1.0, 0.80, 0.58), "cloud_dark": Color(0.52, 0.46, 0.48), "cloud_cover": 0.46, "cloud_alpha": 0.85, "cloud_scale": 0.2,
		"sun_halo": 1.0, "sun_disc": 5.0, "disc_cos": 0.9992, "stars": 0.0},
	"dusk": {         # the sun just down: pink-orange west, blue east, windows and lamps coming on
		"elev": 3.0, "azim": 95.0, "lights": 0.65,
		"zenith": Color(0.09, 0.12, 0.24), "middle": Color(0.40, 0.31, 0.38), "haze": Color(0.62, 0.42, 0.36),
		"sun_color": Color(1.0, 0.50, 0.32), "sun_energy": 0.38, "ambient_color": Color(0.42, 0.42, 0.55), "ambient_energy": 0.55,
		"fog_density": 0.002, "fog_sun_scatter": 0.9,
		"cloud_lit": Color(0.95, 0.55, 0.42), "cloud_dark": Color(0.30, 0.24, 0.30), "cloud_cover": 0.46, "cloud_alpha": 0.85, "cloud_scale": 0.2,
		"sun_halo": 1.2, "sun_disc": 0.0, "disc_cos": 0.9993, "stars": 0.08},
	"night": NIGHT.merged({"elev": 40.0, "azim": -35.0, "lights": 1.0}),
	"overcast": {     # a grey lid: soft light from everywhere, no sun to speak of, thick haze
		"elev": 50.0, "azim": -35.0, "lights": 0.0,
		"zenith": Color(0.55, 0.57, 0.60), "middle": Color(0.64, 0.66, 0.68), "haze": Color(0.70, 0.71, 0.70),
		"sun_color": Color(0.92, 0.93, 0.95), "sun_energy": 0.32, "ambient_color": Color(0.70, 0.71, 0.73), "ambient_energy": 1.12,
		"fog_density": 0.0026, "fog_sun_scatter": 0.05,
		"cloud_lit": Color(0.78, 0.78, 0.79), "cloud_dark": Color(0.50, 0.51, 0.53), "cloud_cover": 0.93, "cloud_alpha": 1.0, "cloud_scale": 0.2,
		"sun_halo": 0.1, "sun_disc": 0.0, "disc_cos": 0.9993, "stars": 0.0}}

@export var sun_angles := Vector3(-40, -35, 0)      ## the old rig: -48 (higher); lower = longer shadows, more light on walls
@export var cloud_speed := Vector2(0.0008, 0.0003)  ## texture units a second; 0 = still
@export var shadow_distance := 50.0                 ## the game's sun shadow distance (unchanged)
@export var bloom := false                          ## glow round bright things (GTA 4 has it). COSTS PIXELS: off by default, see docs/LOOK_SKY.md
@export_range(0.0, 1.0) var grade := 1.0           ## strength of the colour grade (the lookup table); 0 = none

var env: Environment
var sun: DirectionalLight3D
var sky_mat: ShaderMaterial
var night := 0.0
var preset := ""                ## a time of day from PRESETS ("" = day / night by set_night)
var _drift := Vector2.ZERO
static var _drift_added := false

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
	if grade > 0.0: env.adjustment_color_correction = make_grade_lut(grade)
	if bloom:      # a blur chain of the picture at 1/2 .. 1/16 size, then one more read per pixel in the last pass
		env.glow_enabled = true; env.glow_normalized = true
		for i in 7: env.set_glow_level(i, 0.0)
		env.set_glow_level(1, 0.5); env.set_glow_level(2, 0.8); env.set_glow_level(3, 0.6)      # mid-size soft glow; no level 0 (half-size is the dearest)
		env.glow_intensity = 0.7; env.glow_strength = 1.0; env.glow_bloom = 0.04; env.glow_hdr_threshold = 0.9; env.glow_hdr_scale = 2.0
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	sun = DirectionalLight3D.new(); sun.rotation_degrees = sun_angles
	sun.shadow_enabled = OS.get_environment("NOSHADOW") != "1"; sun.directional_shadow_max_distance = shadow_distance; add_child(sun)
	set_night(night)

func _process(dt: float) -> void:
	if cloud_speed == Vector2.ZERO: return
	_drift = (_drift + cloud_speed * dt).posmod(1.0)
	RenderingServer.global_shader_parameter_set(&"ck_sky_drift", _drift)

## The colour grade as a 16 x 16 x 16 lookup table, built here (a few ms, once): the engine reads it once per pixel in
## its last pass. What it does, in this order: holds colours back (saturation 0.72), cool-green shadows and warm
## yellow highlights, the whole picture a little warmer, a soft S-curve, and blacks lifted to a smoggy dark grey.
static func grade_color(c: Color, k: float) -> Color:
	var l := c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
	var v := Vector3(c.r, c.g, c.b)
	v = Vector3(l, l, l).lerp(v, 0.72)
	var sh := (1.0 - l) * (1.0 - l); var hi := l * l
	v += Vector3(-0.012, 0.004, 0.012) * sh
	v *= Vector3(1.0, 1.0, 1.0) + Vector3(0.05, 0.03, -0.08) * hi
	v *= Vector3(1.03, 1.01, 0.93)
	var s := Vector3(smoothstep(0.0, 1.0, v.x), smoothstep(0.0, 1.0, v.y), smoothstep(0.0, 1.0, v.z))
	v = v.lerp(s, 0.22)
	v = Vector3(0.022, 0.02, 0.016) + v * 0.965
	v = Vector3(c.r, c.g, c.b).lerp(v, k)
	return Color(clampf(v.x, 0.0, 1.0), clampf(v.y, 0.0, 1.0), clampf(v.z, 0.0, 1.0))

static func make_grade_lut(k: float, n := 16) -> ImageTexture3D:
	var slices: Array[Image] = []
	for b in n:
		var img := Image.create(n, n, false, Image.FORMAT_RGB8)
		for g in n:
			for r in n:
				img.set_pixel(r, g, grade_color(Color(r / float(n - 1), g / float(n - 1), b / float(n - 1)), k))
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
	if preset != "": set_preset(preset); return
	night = clampf(v, 0.0, 1.0)
	var t := {}
	for k: String in DAY: t[k] = _mix(k, night)
	t["elev"] = -sun_angles.x; t["azim"] = sun_angles.y
	_apply(t)

## a time of day (PRESETS), or "" to go back to set_night
func set_preset(name: String) -> void:
	preset = name if PRESETS.has(name) else ""
	if preset == "": set_night(night); return
	night = float(PRESETS[preset].lights)
	_apply(PRESETS[preset])

## how far the city's night is on for the current setting (the streamer's ck_night)
func lights() -> float:
	return float(PRESETS[preset].lights) if preset != "" else night

func _apply(t: Dictionary) -> void:
	sun.rotation_degrees = Vector3(-float(t.elev), float(t.azim), 0.0)
	var haze: Color = t.haze
	sun.light_color = t.sun_color; sun.light_energy = t.sun_energy
	env.ambient_light_color = t.ambient_color; env.ambient_light_energy = t.ambient_energy
	env.fog_light_color = haze; env.fog_light_energy = 1.0
	env.fog_density = t.fog_density; env.fog_sun_scatter = t.fog_sun_scatter
	for k: String in ["zenith", "middle", "haze", "cloud_lit", "cloud_dark", "cloud_cover", "cloud_alpha", "cloud_scale", "sun_halo", "sun_disc", "disc_cos", "stars"]:
		sky_mat.set_shader_parameter(k, t[k])
	sky_mat.set_shader_parameter(&"sun_col", sun.light_color)
	sky_mat.set_shader_parameter(&"sun_dir", Basis.from_euler(sun.rotation).z)      # towards the light (its +Z)
	sky_mat.set_shader_parameter(&"sun_scatter", sun.light_energy * env.fog_sun_scatter)      # the fog's own sun glow, so sky and fog agree
