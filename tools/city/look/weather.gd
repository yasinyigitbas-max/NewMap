extends RefCounted
## LOOK QUEUE 2, JOB 4: weather moods, laid over any time of day (a preset, the day / night pair or the running day).
## look.gd `weather` (rig --weather=NAME). Each mood only changes numbers of the look's table, so it costs nothing
## per pixel beyond the look itself; rain also turns on the wet ground (look --wet, two reads a ground pixel).
##   mist    morning mist: thick, pale, the sun weak through it; with the running day it burns off from 8:00 to 10:30
##   hazy    a hot hazy afternoon: thick yellow-white haze, the sky washed out, a hard warm sun, few clouds
##   storm   dark overcast before rain: a low slate lid, dim flat light, the city's lights half on in the gloom
##   rain    light rain: a grey veil (denser haze), a lid of cloud, the ground wet
const NAMES := ["mist", "hazy", "storm", "rain"]

static func _lum(c: Color) -> float: return c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722

## a colour towards `target`, at the brightness the time of day has (so a mood does not light the night up)
static func _toward(c: Color, target: Color, k: float) -> Color:
	var s := _lum(c) / maxf(_lum(target), 0.001)
	return c.lerp(target * s, k)

## a colour towards `target` at the target's OWN brightness by day (a storm is darker than a fair sky), at the time
## of day's brightness at night (so it never lights the night up)
static func _dark(c: Color, target: Color, k: float, day: float) -> Color:
	return c.lerp(target.lerp(target * (_lum(c) / maxf(_lum(target), 0.001)), 1.0 - day), k)

static func apply(t: Dictionary, name: String, hour := -1.0) -> Dictionary:
	if not (name in NAMES): return t
	var o := t.duplicate()
	var day := 1.0 - clampf(float(t.get("lights", 0.0)), 0.0, 1.0)
	match name:
		"mist":
			var m := 1.0 if hour < 0.0 else 1.0 - smoothstep(8.0, 10.5, hour)      # burns off in the running day
			o.fog_density = float(t.fog_density) * lerpf(1.0, 4.5, m)
			o.haze = _toward(t.haze, Color(0.86, 0.87, 0.88), 0.7 * m)
			o.middle = _toward(t.middle, Color(0.78, 0.80, 0.83), 0.5 * m)
			o.sun_energy = float(t.sun_energy) * lerpf(1.0, 0.55, m)
			o.ambient_energy = float(t.ambient_energy) * lerpf(1.0, 1.15, m)
			o.fog_sun_scatter = lerpf(float(t.fog_sun_scatter), 0.7, m * day)
			o.cloud_cover = lerpf(float(t.cloud_cover), 0.2, m)
		"hazy":
			o.fog_density = float(t.fog_density) * 1.9
			o.haze = _toward(t.haze, Color(0.93, 0.86, 0.70), 0.65 * day)
			o.middle = (t.middle as Color).lerp(o.haze, 0.45 * day); o.zenith = (t.zenith as Color).lerp(t.middle, 0.4 * day)
			o.sun_energy = float(t.sun_energy) * lerpf(1.0, 1.12, day); o.sun_color = (t.sun_color as Color).lerp(Color(1.0, 0.86, 0.64), 0.5 * day)
			o.ambient_color = _toward(t.ambient_color, Color(0.72, 0.68, 0.60), 0.4 * day)
			o.cloud_cover = float(t.cloud_cover) * 0.5; o.fog_sun_scatter = float(t.fog_sun_scatter) * 1.6
		"storm", "rain":
			var rain := name == "rain"
			o.cloud_cover = 0.9 if rain else 0.97; o.cloud_alpha = 1.0; o.cloud_scale = 0.14
			o.cloud_lit = _dark(t.cloud_lit, Color(0.50, 0.52, 0.56) if rain else Color(0.40, 0.42, 0.46), 0.9, day); o.cloud_dark = _dark(t.cloud_dark, Color(0.18, 0.20, 0.23), 0.9, day)
			o.zenith = _dark(t.zenith, Color(0.30, 0.33, 0.37), 0.9, day); o.middle = _dark(t.middle, Color(0.40, 0.42, 0.45), 0.9, day)
			o.haze = _dark(t.haze, Color(0.56, 0.58, 0.59) if rain else Color(0.48, 0.50, 0.52), 0.85, day)
			o.sun_energy = float(t.sun_energy) * (0.3 if rain else 0.22); o.sun_halo = 0.0; o.sun_disc = 0.0
			o.ambient_color = _toward(t.ambient_color, Color(0.56, 0.60, 0.66), 0.7); o.ambient_energy = float(t.ambient_energy) * (0.85 if rain else 0.75)
			o.fog_density = float(t.fog_density) * (2.4 if rain else 1.5); o.fog_sun_scatter = 0.05
			o.lights = maxf(float(t.get("lights", 0.0)), 0.22 if rain else 0.3)      # the gloom: some windows and lamps on
			o.stars = 0.0
	return o
