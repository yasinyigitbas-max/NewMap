## Boot (a tool step, GDScript): on first Play, download the Mixamo clips this lab needs from Yasin's Drive folder
## (clip_manifest.tsv), retarget and measure them into user://clip_cache/clips.bin, then open the course.
## Nothing downloaded or built here is ever committed (Mixamo terms; DECISIONS 0.3).
## User args: --clips-dir=<folder with the files already downloaded>  --rebuild
extends Control

const SET := preload("res://tools/clip_set.gd")
const CC := preload("res://tools/clip_cache.gd")
const CACHE := "user://clip_cache/clips.bin"
const RAW := "user://clips_raw"

var label: Label
var http: HTTPRequest
var queue: Array = []

func _ready():
	label = Label.new()
	label.position = Vector2(40, 40)
	label.add_theme_font_size_override("font_size", 22)
	add_child(label)
	var rebuild := "--rebuild" in OS.get_cmdline_user_args()
	if not rebuild and _cache_ok():
		_go()
		return
	var raw := RAW
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--clips-dir="): raw = a.substr(12)
	DirAccess.make_dir_recursive_absolute(raw)
	var need: Dictionary = SET.needed_files("res://clip_manifest.tsv")
	for f in need:
		if not FileAccess.file_exists(raw.path_join(f)): queue.append([f, need[f], raw])
	http = HTTPRequest.new()
	http.max_redirects = 10
	http.request_completed.connect(_on_done)
	add_child(http)
	_next(raw)

func _cache_ok() -> bool:
	if not FileAccess.file_exists(CACHE): return false
	var f := FileAccess.open(CACHE, FileAccess.READ)
	var d = f.get_var()
	return d is Dictionary and d.get("version", 0) == CC.VERSION

func _next(raw: String):
	if queue.is_empty():
		_build.call_deferred(raw)
		return
	var it = queue[0]
	_say("Downloading clips from Yasin's Drive (first run only): %s  (%d left)" % [it[0], queue.size()])
	http.download_file = it[2].path_join(it[0])
	var url := "https://drive.usercontent.google.com/download?id=%s&export=download&confirm=t" % it[1]
	if http.request(url) != OK:
		_say("Could not start the download of " + it[0]); return

func _on_done(result, code, _h, _b):
	var it = queue.pop_front()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_say("Download failed for %s (result %d, HTTP %d). Check the internet connection and press Play again." % [it[0], result, code])
		DirAccess.remove_absolute(it[2].path_join(it[0]))
		return
	_next(it[2])

func _build(raw: String):
	_say("Retargeting and measuring the clips onto player_v3 (first run only, a few seconds)...")
	await get_tree().process_frame
	await get_tree().process_frame
	var cc := CC.new()
	var err := cc.build(raw, CACHE)
	for l in cc.log_lines: printerr(l)
	if err != OK:
		_say("Clip build failed (%d): %s" % [err, "\n".join(cc.log_lines)]); return
	_go()

func _go():
	get_tree().change_scene_to_file.call_deferred("res://scenes/main.tscn")

func _say(t: String):
	label.text = t
	print(t)
