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
##  - TONEMAP + GRADE: in the pass that already scales the 720p picture up and smooths its edges; a different
##    curve and a contrast / saturation step, arithmetic only. No colour-correction texture.
##  - NOT used, on purpose: glow / bloom, SSAO, SSR, volumetric fog, depth of field.
## Nothing here touches a piece, the bake or a shader of the city (city_kit/shaders): only the Environment and the sun.

const SKY_SHADER_PATH := "res://tools/city/look/sky.gdshader"
const NOISE_PATH := "res://tools/city/look/sky_noise.png"

## Day and night. `set_night(v)` blends the two (v 0..1), so a dusk in between works too.
const DAY := {
	"zenith": Color(0.15, 0.36, 0.75), "middle": Color(0.40, 0.62, 0.90), "haze": Color(0.78, 0.84, 0.89),
	"sun_color": Color(1.0, 0.93, 0.80), "sun_energy": 1.45,                  # warm sun ...
	"ambient_color": Color(0.52, 0.64, 0.88), "ambient_energy": 0.85,         # ... cool shade (the sky's own blue)
	"fog_density": 0.0013, "fog_sun_scatter": 0.22,
	"cloud_lit": Color(1.0, 0.98, 0.95), "cloud_dark": Color(0.60, 0.66, 0.77), "cloud_cover": 0.42, "cloud_alpha": 0.92,
	"sun_halo": 0.6, "sun_disc": 8.0, "disc_cos": 0.9994, "stars": 0.0}
const NIGHT := {
	"zenith": Color(0.012, 0.02, 0.05), "middle": Color(0.03, 0.045, 0.09), "haze": Color(0.085, 0.085, 0.11),      # the horizon holds a little of the city's light
	"sun_color": Color(0.62, 0.72, 1.0), "sun_energy": 0.22,                  # the same light is the moon
	"ambient_color": Color(0.30, 0.38, 0.62), "ambient_energy": 0.42,         # dark, blue, still readable
	"fog_density": 0.0018, "fog_sun_scatter": 0.3,
	"cloud_lit": Color(0.10, 0.11, 0.15), "cloud_dark": Color(0.04, 0.045, 0.065), "cloud_cover": 0.42, "cloud_alpha": 0.85,
	"sun_halo": 0.5, "sun_disc": 1.6, "disc_cos": 0.99975, "stars": 1.2}

@export var sun_angles := Vector3(-40, -35, 0)      ## the old rig: -48 (higher); lower = longer shadows, more light on walls
@export var cloud_speed := Vector2(0.0008, 0.0003)  ## texture units a second; 0 = still
@export var shadow_distance := 50.0                 ## the game's sun shadow distance (unchanged)

var env: Environment
var sun: DirectionalLight3D
var sky_mat: ShaderMaterial
var night := 0.0
var _drift := Vector2.ZERO

func _ready() -> void:
	# the clouds' drift is a global shader value: add it before the sky shader is loaded (it will not compile without)
	if not (&"ck_sky_drift" in RenderingServer.global_shader_parameter_get_list()):
		RenderingServer.global_shader_parameter_add(&"ck_sky_drift", RenderingServer.GLOBAL_VAR_TYPE_VEC2, Vector2.ZERO)
	sky_mat = ShaderMaterial.new(); sky_mat.shader = load(SKY_SHADER_PATH)
	sky_mat.set_shader_parameter(&"noise_tex", load(NOISE_PATH))
	var sky := Sky.new(); sky.sky_material = sky_mat
	env = Environment.new()
	env.background_mode = Environment.BG_SKY; env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR      # (sky ambient would cost a cube map read per pixel)
	env.fog_enabled = true; env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_aerial_perspective = 0.0; env.fog_sky_affect = 0.0; env.fog_height_density = 0.0
	env.tonemap_mode = Environment.TONE_MAPPER_ACES; env.tonemap_exposure = 1.0; env.tonemap_white = 6.0
	env.adjustment_enabled = true; env.adjustment_brightness = 1.0; env.adjustment_contrast = 1.06; env.adjustment_saturation = 1.1
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	sun = DirectionalLight3D.new(); sun.rotation_degrees = sun_angles
	sun.shadow_enabled = true; sun.directional_shadow_max_distance = shadow_distance; add_child(sun)
	set_night(night)

func _process(dt: float) -> void:
	if cloud_speed == Vector2.ZERO: return
	_drift = (_drift + cloud_speed * dt).posmod(1.0)
	RenderingServer.global_shader_parameter_set(&"ck_sky_drift", _drift)

static func _mix(key: String, v: float) -> Variant:
	var a: Variant = DAY[key]; var b: Variant = NIGHT[key]
	if a is Color: return (a as Color).lerp(b as Color, v)
	return lerpf(float(a), float(b), v)

## 0 day .. 1 night. Call it when the time of day changes, not every frame: a change of the sky makes the engine
## redraw the sky's reflection cube map once.
func set_night(v: float) -> void:
	night = clampf(v, 0.0, 1.0)
	var haze: Color = _mix("haze", night)
	sun.light_color = _mix("sun_color", night); sun.light_energy = _mix("sun_energy", night)
	env.ambient_light_color = _mix("ambient_color", night); env.ambient_light_energy = _mix("ambient_energy", night)
	env.fog_light_color = haze; env.fog_light_energy = 1.0
	env.fog_density = _mix("fog_density", night); env.fog_sun_scatter = _mix("fog_sun_scatter", night)
	for k: String in ["zenith", "middle", "haze", "cloud_lit", "cloud_dark", "cloud_cover", "cloud_alpha", "sun_halo", "sun_disc", "disc_cos", "stars"]:
		sky_mat.set_shader_parameter(k, _mix(k, night))
	sky_mat.set_shader_parameter(&"sun_col", sun.light_color)
	sky_mat.set_shader_parameter(&"sun_dir", sun.global_transform.basis.z if sun.is_inside_tree() else Basis.from_euler(sun_angles * PI / 180.0).z)
	sky_mat.set_shader_parameter(&"sun_scatter", sun.light_energy * env.fog_sun_scatter)      # the fog's own sun glow, so sky and fog agree
