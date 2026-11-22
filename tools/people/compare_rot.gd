extends SceneTree
## Two clips compared bone by bone (every bone's rotation, 30 moments over the length; a loop also at every start offset):
## the mean and the largest bone's mean difference in degrees. Under ~1 deg: the same take; over ~4: a different one.
##   godot --headless --path . -s res://tools/people/compare_rot.gd -- yl/Walking,pwalk/walk_mx3 ...
const LIBS := {"yl": "clips_yl", "mx": "clips_mx", "pwalk": "clips_player_walk", "prun": "clips_player_run", "pidle": "clips_player_idle", "ptrav": "clips_player_trav", "pact": "clips_player_act"}
var cache := {}
func _anim(n: String) -> Animation:
	var p := n.split("/")
	if not cache.has(p[0]): cache[p[0]] = load("res://characters/rocketbox/%s_male.res" % LIBS[p[0]])
	var lib: AnimationLibrary = cache[p[0]]
	return lib.get_animation(p[1]) if lib and lib.has_animation(p[1]) else null
func _tracks(a: Animation) -> Dictionary:
	var d := {}
	for i in a.get_track_count():
		if a.track_get_type(i) == Animation.TYPE_ROTATION_3D: d[String(a.track_get_path(i)).get_slice(":", 1)] = i
	return d
func _diff(A: Animation, B: Animation, shifts: int) -> float:
	var ta := _tracks(A); var tb := _tracks(B)
	var bones := ta.keys().filter(func(k): return tb.has(k))
	var best := 1e9
	for sh in shifts:
		var tot := 0.0
		for bn in bones:
			for k in 12:
				tot += rad_to_deg((A.rotation_track_interpolate(ta[bn], k / 11.0 * A.length) as Quaternion).angle_to(B.rotation_track_interpolate(tb[bn], fmod(k + sh * 12.0 / shifts, 12.0) / 11.0 * B.length)))
		best = minf(best, tot / (12.0 * maxf(1, bones.size())))
	return best

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and args[0] == "--group":   # the same takes among many: groups of clips under 1.5 deg apart
		var names := args.slice(1); var par := {}
		for n in names: par[n] = n
		var find := func(x): 
			while par[x] != x: x = par[x]
			return x
		for i in names.size():
			var A := _anim(names[i]); if not A: continue
			for j in range(i + 1, names.size()):
				var B := _anim(names[j]); if not B: continue
				if absf(A.length - B.length) > 0.04 * maxf(A.length, B.length) + 0.034: continue
				if _diff(A, B, 12 if A.loop_mode != 0 and B.loop_mode != 0 else 1) < 1.5: par[find.call(names[j])] = find.call(names[i])
		var groups := {}
		for n in names: groups.get_or_add(find.call(n), []).append(n)
		for g in groups.values(): print("GROUP %s" % " = ".join(g))
		quit(0); return
	for pair in args:
		var ab := pair.split(","); var A := _anim(ab[0]); var B := _anim(ab[1])
		if not A or not B: print("ROT %s missing" % pair); continue
		var ta := _tracks(A); var tb := _tracks(B)
		var bones := ta.keys().filter(func(k): return tb.has(k))
		var shifts := 30 if (A.loop_mode != 0 and B.loop_mode != 0) else 1
		var best := 1e9; var best_max := 0.0
		for sh in shifts:
			var tot := 0.0; var worst := 0.0
			for bn in bones:
				var s := 0.0
				for k in 30:
					var ua := k / 29.0; var ub := fmod(k + sh, 30.0) / 29.0
					var qa: Quaternion = A.rotation_track_interpolate(ta[bn], ua * A.length)
					var qb: Quaternion = B.rotation_track_interpolate(tb[bn], ub * B.length)
					s += rad_to_deg(qa.angle_to(qb))
				s /= 30.0; tot += s; worst = maxf(worst, s)
			tot /= maxf(1, bones.size())
			if tot < best: best = tot; best_max = worst
		print("ROT %-34s %-34s mean %5.2f deg  worst bone %5.2f deg  (%.2f / %.2f s, %d bones)" % [ab[0], ab[1], best, best_max, A.length, B.length, bones.size()])
	quit(0)
