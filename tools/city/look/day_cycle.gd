extends RefCounted
## LOOK JOB 2.1 (18 Nov): the running day. The look's presets (look.gd PRESETS) as keyframes of a 24-hour clock, and
## everything between them blended, so nothing changes in one step: sky, clouds, haze, light colours and strength,
## the sun's path, the moon taking over at night, how far the city's night is on (windows, lamp glow, real lamps).
## look.gd `cycle` (rig --cycle=SECONDS for a whole day) moves the clock; `set_hour(h)` jumps to an hour.
## The sun climbs from the east (azimuth -105) through south to the west (95) and goes on round under the horizon,
## so the azimuths below run on without a wrap.

## [hour, preset, sun elevation, sun azimuth]
const KEYS := [
	[0.0, "night", -32.0, 180.0],
	[4.6, "night", -14.0, 225.0],
	[6.0, "dusk", 1.0, 250.0],        # dawn: the dusk colours, the sun in the east
	[7.4, "morning", 14.0, 255.0],
	[12.5, "noon", 64.0, 325.0],
	[16.0, "day", 40.0, 380.0],
	[18.4, "golden", 11.0, 440.0],
	[19.5, "dusk", 3.0, 455.0],
	[20.6, "night", -10.0, 485.0],
	[24.0, "night", -32.0, 540.0]]

static func at(hour: float, presets: Dictionary) -> Dictionary:
	var h := fposmod(hour, 24.0)
	var i := 0
	while i < KEYS.size() - 2 and h >= float(KEYS[i + 1][0]): i += 1
	var a: Array = KEYS[i]; var b: Array = KEYS[i + 1]
	var f := clampf((h - float(a[0])) / (float(b[0]) - float(a[0])), 0.0, 1.0)
	f = f * f * (3.0 - 2.0 * f)      # ease in and out of each keyframe: no kink in the light
	var ta: Dictionary = presets[a[1]]; var tb: Dictionary = presets[b[1]]
	var t := {}
	for k: String in ta:
		var va: Variant = ta[k]; var vb: Variant = tb.get(k, va)
		if va is Color: t[k] = (va as Color).lerp(vb as Color, f)
		elif va is float or va is int: t[k] = lerpf(float(va), float(vb), f)
		else: t[k] = va
	t["elev"] = lerpf(float(a[2]), float(b[2]), f)
	t["azim"] = fposmod(lerpf(float(a[3]), float(b[3]), f) + 180.0, 360.0) - 180.0
	t["hour"] = h
	return t
