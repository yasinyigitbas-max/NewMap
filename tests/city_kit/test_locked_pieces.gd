extends SceneTree
## city1: every approved (locked) block-kit piece is byte-identical to the file Yasin approved. Adding or fixing another
## piece can never change a locked one: if this fails, the change touched an approved piece and must be undone.
var fails := 0
func ok(c: bool, m: String) -> void:
	print(("PASS " if c else "FAIL ") + m); if not c: fails += 1
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/locked.json"))
	ok(typeof(v) == TYPE_DICTIONARY, "locked.json reads")
	var pieces: Dictionary = (v as Dictionary).get("pieces", {}) if typeof(v) == TYPE_DICTIONARY else {}
	for name: String in pieces:
		var e: Dictionary = pieces[name]
		var path := "res://map_dc/coronado/city_kit/pieces/%s.scn" % name
		ok(FileAccess.file_exists(path), "%s exists" % name)
		if FileAccess.file_exists(path):
			ok(FileAccess.get_sha256(path) == String(e.sha256), "%s unchanged since it was approved (%s)" % [name, String(e.get("date", "?"))])
	# approved plan files (zoning map, street skeleton): repo-relative paths
	var files: Dictionary = (v as Dictionary).get("files", {}) if typeof(v) == TYPE_DICTIONARY else {}
	for path: String in files:
		var fe: Dictionary = files[path]
		var rp := "res://" + path
		ok(FileAccess.file_exists(rp), "%s exists" % path)
		if FileAccess.file_exists(rp):
			ok(FileAccess.get_sha256(rp) == String(fe.sha256), "%s unchanged since it was approved (%s)" % [path, String(fe.get("date", "?"))])
	print("locked pieces: %d, locked plan files: %d" % [pieces.size(), files.size()])
	print("RESULT ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(1 if fails else 0)
