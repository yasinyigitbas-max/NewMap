## CLI: run the sole-point step (clip_soles.gd) over a cache in place and print each clip's contacts.
##   godot --headless --path . -s tools/soles_cli.gd -- <cache.bin> [traverse_prefix,...]
extends SceneTree
const SOL := preload("res://tools/clip_soles.gd")
const CB := preload("res://tools/clip_build.gd")
func _initialize():
	var a := OS.get_cmdline_user_args()
	var d: Dictionary = FileAccess.open(a[0], FileAccess.READ).get_var()
	var trav: PackedStringArray = a[1].split(",") if a.size() > 1 else PackedStringArray()
	var sol := SOL.new()
	sol.setup(root)
	await process_frame
	for nm in d.clips:
		var t := false
		for p in trav: if p != "" and String(nm).contains(p): t = true
		sol.process(d.clips[nm], t)
		sol.lock_feet(d.clips[nm], t)
		print(CB.summary(d.clips[nm]), "  floor_fix=%.3f" % d.clips[nm].floor_fix)
	var f := FileAccess.open(a[0], FileAccess.WRITE)
	f.store_var(d); f.close()
	quit()
