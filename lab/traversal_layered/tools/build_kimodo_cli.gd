## Builds the v2 clip cache from the Kimodo set (tools/kimodo_set.gd): retarget, cut, sole-point floor and contacts,
## build-time foot lock, loop seam, marks. Writes <out.bin> (never committed).
##   godot --headless --path . -s tools/build_kimodo_cli.gd -- <out.bin> [kimodo_dir]
extends SceneTree
const CB := preload("res://tools/clip_build.gd")
const KS := preload("res://tools/kimodo_set.gd")
const CC := preload("res://tools/clip_cache.gd")
const SOL := preload("res://tools/clip_soles.gd")

## loops: spread the end-to-start difference over the cycle so the last frame equals the first (no seam pop)
static func seam_fix(c: Dictionary) -> void:
	var n: int = c.bones; var nf: int = c.frames
	var rot: PackedFloat32Array = c.rot
	for i in n:
		var o0 := i * 4; var o1 := ((nf - 1) * n + i) * 4
		var q0 := Quaternion(rot[o0], rot[o0 + 1], rot[o0 + 2], rot[o0 + 3])
		var q1 := Quaternion(rot[o1], rot[o1 + 1], rot[o1 + 2], rot[o1 + 3])
		if q0.dot(q1) < 0: q1 = -q1
		var d := (q0 * q1.inverse()).normalized()
		for f in nf:
			var o := (f * n + i) * 4
			var q := Quaternion(rot[o], rot[o + 1], rot[o + 2], rot[o + 3])
			q = (Quaternion.IDENTITY.slerp(d, float(f) / (nf - 1)) * q).normalized()
			rot[o] = q.x; rot[o + 1] = q.y; rot[o + 2] = q.z; rot[o + 3] = q.w
	c.rot = rot
	var h: PackedFloat32Array = c.hips
	var dy := h[1] - h[(nf - 1) * 3 + 1]; var dx := h[0] - h[(nf - 1) * 3]; var dz := h[2] - h[(nf - 1) * 3 + 2]
	for f in nf:
		var k := float(f) / (nf - 1)
		h[f * 3] += dx * k; h[f * 3 + 1] += dy * k; h[f * 3 + 2] += dz * k
	c.hips = h

func _initialize():
	var a := OS.get_cmdline_user_args()
	var out: String = a[0]
	var dir: String = a[1] if a.size() > 1 else KS.KIMODO_DIR
	var cb := CB.new()
	cb.setup_body(load("res://body/player_v3.glb"))
	var sol := SOL.new()
	sol.setup(root)
	await process_frame
	var cc := CC.new()
	var clips := {}
	for spec in KS.CLIPS:
		var path: String = dir.path_join(spec.src)
		if not FileAccess.file_exists(path): print("MISSING ", path); continue
		for m in ([false, true] if spec.get("mirror", false) else [false]):
			var name: String = spec.name + ("_M" if m else "")
			var sp: Dictionary = spec.duplicate()
			sp["name"] = name; sp["mirror"] = m
			var c := cb.build_clip(path, sp)
			if c.is_empty(): print("FAIL ", name); continue
			var trav: bool = spec.get("trav", false)
			sol.process(c, trav)
			sol.lock_feet(c, trav)
			if spec.get("loop", false): seam_fix(c)
			c["kind"] = spec.kind
			if spec.has("height"): c["height"] = spec.height
			if spec.kind in ["loop", "idle", "start", "stop", "pivot", "turn"]: cc._mark(c, spec.kind)
			clips[name] = c
			print(CB.summary(c))
			print("    ", CC.describe(c))
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_var({"version": 100, "source": "kimodo", "bones": cb.bones, "clips": clips, "leg_k": cb.leg_k})
	f.close()
	print("WROTE ", out, " clips=", clips.size())
	quit()
