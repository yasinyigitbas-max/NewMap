## Builds the clip cache (user://clip_cache/clips.bin) from downloaded Mixamo files: retarget, measure, mark.
## A tool (GDScript); the C++ runtime only reads the cache. DECISIONS 0.3, 1.x, 2.x.
extends RefCounted

const CB := preload("res://tools/clip_build.gd")
const SET := preload("res://tools/clip_set.gd")
const VERSION := 3

var log_lines: PackedStringArray = []

func _resolve(raw_dir: String, src: String) -> String:
	if not src.begins_with("zip:"): return raw_dir.path_join(src)
	var rest := src.substr(4)
	var zip_name := rest.get_slice("/", 0)
	var inner := rest.substr(zip_name.length() + 1)
	var out_dir := raw_dir.path_join("_unzipped")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var out := out_dir.path_join(inner.get_file())
	if FileAccess.file_exists(out): return out
	var z := ZIPReader.new()
	if z.open(raw_dir.path_join(zip_name)) != OK: return ""
	for f in z.get_files():
		if f.get_file() == inner.get_file():
			var fa := FileAccess.open(out, FileAccess.WRITE)
			fa.store_buffer(z.read_file(f)); fa.close()
			break
	z.close()
	return out if FileAccess.file_exists(out) else ""

static func _first_lift(c: Dictionary) -> int:
	for f in c.frames:
		if c.contact_l[f] == 0 or c.contact_r[f] == 0: return f
	return 0

static func _all_strikes(c: Dictionary) -> Array:
	var s := []
	for f in c.strikes_l: s.append([f, 0])
	for f in c.strikes_r: s.append([f, 1])
	s.sort_custom(func(a, b): return a[0] < b[0])
	return s

static func _root_dist(c: Dictionary, a: int, b: int) -> float:
	var r: PackedFloat32Array = c.root
	var d := 0.0
	for f in range(a + 1, b + 1):
		d += Vector2(r[f * 3] - r[(f - 1) * 3], r[f * 3 + 1] - r[(f - 1) * 3 + 1]).length()
	return d

func _mark(c: Dictionary, kind: String) -> void:
	var nf: int = c.frames
	var fps: float = c.fps
	var strikes := _all_strikes(c)
	match kind:
		"loop", "idle":
			c["cycle_a"] = 0.0; c["cycle_b"] = float(nf - 1)
			c["cycle_time"] = (nf - 1) / fps
			c["cycle_dist"] = _root_dist(c, 0, nf - 1)
			c["phase_f0"] = float(c.strikes_l[0]) if c.strikes_l.size() > 0 else 0.0
		"start":
			var lift := _first_lift(c)
			c["move_a"] = float(max(lift - 6, 0))   # weight shift ~0.2 s before the first foot lifts (study 2.3/1)
			# hand over to the loop at the first strike where the start has (nearly) reached its walking speed, so the
			# loop takes over without a jump in speed (study 4.2: leave a clip at a matching pose)
			var after := strikes.filter(func(s): return s[0] > lift)
			var vmax := 0.0
			var vs := {}
			for sk in after:
				var f0: int = max(sk[0] - 4, 1)
				var v: float = _root_dist(c, f0, sk[0]) / ((sk[0] - f0) / fps)
				vs[sk[0]] = v; vmax = max(vmax, v)
			var ex = after[after.size() - 1] if after.size() > 0 else [nf - 1, 0]
			for sk in after:
				if vs[sk[0]] >= 0.85 * vmax and sk != after[0]: ex = sk; break
			c["exit_f"] = float(ex[0]); c["exit_phase"] = 0.0 if ex[1] == 0 else 0.5
		"stop", "pivot":
			if strikes.size() > 0:
				c["entry_f"] = float(strikes[0][0]); c["entry_foot"] = strikes[0][1]
			if kind == "pivot" and strikes.size() > 1:
				var ex = strikes[strikes.size() - 1]
				c["exit_f"] = float(ex[0]); c["exit_phase"] = 0.0 if ex[1] == 0 else 0.5
			var r: PackedFloat32Array = c.root
			var still := nf - 1
			for f in range(nf - 1, 0, -1):
				var v := Vector2(r[f * 3] - r[(f - 1) * 3], r[f * 3 + 1] - r[(f - 1) * 3 + 1]).length() * fps
				if v > 0.08: still = f; break
			c["still_f"] = float(still)
		"turn":
			c["entry_f"] = 0.0

## Builds everything; returns OK or an error code. progress(msg: String) is called per clip.
func build(raw_dir: String, out_path: String, progress := Callable()) -> int:
	var cb := CB.new()
	cb.setup_body(load("res://body/player_v3.glb"))
	var clips := {}
	for spec in SET.CLIPS:
		var path := _resolve(raw_dir, spec.src)
		if path == "" or not FileAccess.file_exists(path):
			log_lines.append("missing " + spec.src); continue
		for m in ([false, true] if spec.get("mirror", false) else [false]):
			var name: String = spec.name + ("_M" if m else "")
			if progress.is_valid(): progress.call(name)
			var c := cb.build_clip(path, {"name": name, "mirror": m, "loop": spec.get("loop", false)})
			if c.is_empty():
				log_lines.append("failed " + name); continue
			c["kind"] = spec.kind
			_mark(c, spec.kind)
			clips[name] = c
	log_lines.append_array(cb.log_lines)
	DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f == null: return ERR_CANT_CREATE
	f.store_var({"version": VERSION, "bones": cb.bones, "clips": clips, "leg_k": cb.leg_k})
	f.close()
	return OK if clips.size() > 0 else ERR_FILE_NOT_FOUND

static func describe(c: Dictionary) -> String:
	var keys := ["kind", "speed", "dist", "turn", "cycle_time", "cycle_dist", "phase_f0", "move_a", "exit_f", "exit_phase", "entry_f", "entry_foot", "still_f"]
	var s := "%-18s n=%3d" % [c.name, c.frames]
	for k in keys:
		if c.has(k): s += " %s=%s" % [k, str(snappedf(float(c[k]), 0.01)) if typeof(c[k]) != TYPE_STRING else c[k]]
	return s
