extends SceneTree
## The same pop measure as clip_audit.gd, on the SOURCE library (characters/quaternius_ual/UAL*.glb, its own skeleton):
## is a pop in the source clip or made by fitting it to our figure?
##   godot --headless --path . -s res://tools/people/clip_audit_source.gd -- --clip=Kick [--from=0.2 --to=0.35]
var only := "Kick"
var t_from := -1.0
var t_to := -1.0

func _initialize() -> void:
	for s: String in OS.get_cmdline_user_args():
		if s.begins_with("--clip="): only = s.trim_prefix("--clip=")
		if s.begins_with("--from="): t_from = float(s.trim_prefix("--from="))
		if s.begins_with("--to="): t_to = float(s.trim_prefix("--to="))
	for src in ["res://characters/quaternius_ual/UAL1.glb", "res://characters/quaternius_ual/UAL2.glb"]:
		var doc := GLTFDocument.new(); var st := GLTFState.new()
		if doc.append_from_file(src, st) != OK: continue
		var sc: Node = doc.generate_scene(st)
		var ap: AnimationPlayer = sc.find_children("*", "AnimationPlayer", true, false)[0]
		if not ap.has_animation(only): sc.free(); continue
		var sk: Skeleton3D = sc.find_children("*", "Skeleton3D", true, false)[0]
		var a := ap.get_animation(only)
		var n := sk.get_bone_count()
		var tracks := {}
		for ti in a.get_track_count():
			var p := a.track_get_path(ti)
			if p.get_subname_count() < 1: continue
			var b := sk.find_bone(p.get_subname(0))
			if b >= 0:
				if not tracks.has(b): tracks[b] = []
				(tracks[b] as Array).append(ti)
		var x := Transform3D(); var nd: Node = sk
		while nd != null:
			if nd is Node3D: x = (nd as Node3D).transform * x
			nd = nd.get_parent()
		print("SOURCE %s in %s: %.2f s, %d bones, keys per track e.g. %d" % [only, src.get_file(), a.length, n, a.track_get_key_count(0)])
		var prev: Array = []
		var f := 0
		var t := 0.0
		var a0 := t_from if t_from >= 0.0 else 0.0
		var a1 := t_to if t_to >= 0.0 else a.length
		while t <= a.length + 1e-4:
			var loc: Array = []
			for b in n: loc.append(sk.get_bone_rest(b))
			for b: int in tracks:
				var xx: Transform3D = loc[b]
				for ti: int in tracks[b]:
					if a.track_get_type(ti) == Animation.TYPE_POSITION_3D: xx.origin = a.position_track_interpolate(ti, t)
					elif a.track_get_type(ti) == Animation.TYPE_ROTATION_3D: xx.basis = Basis(a.rotation_track_interpolate(ti, t))
				loc[b] = xx
			var glob: Array = []; glob.resize(n)
			for b in n: glob[b] = (glob[sk.get_bone_parent(b)] as Transform3D) * (loc[b] as Transform3D) if sk.get_bone_parent(b) >= 0 else loc[b]
			var pts: Array = []
			for b in n: pts.append(x * (glob[b] as Transform3D).origin)
			if not prev.is_empty() and t >= a0 and t <= a1:
				var mv := 0.0; var mb := 0
				for b in n:
					var d := ((pts[b] as Vector3) - (prev[b] as Vector3)).length()
					if d > mv: mv = d; mb = b
				print("SOURCE   t %.3f biggest move %.3f m (%s)" % [t, mv, sk.get_bone_name(mb)])
			prev = pts; t += 1.0 / 60.0; f += 1
		sc.free()
	quit()
