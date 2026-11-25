## The clips Lab B uses, where they come from, and how each is cut. Data only (a tool file, not runtime).
## kind: idle | loop | start | stop | pivot | turn. mirror: also build the left/right mirror (suffix "_M").
## src: a Mixamo FBX by its Drive name (clip_manifest.tsv), or "zip:<pack>/<file>" for one inside a pack.
extends RefCounted

const PACK_LOCO := "Male Locomotion Pack.zip"

const CLIPS := [
	{"name": "idle", "src": "Idle.fbx", "kind": "idle", "loop": true},
	{"name": "walk", "src": "Walking.fbx", "kind": "loop", "loop": true},
	{"name": "jog", "src": "Slow Run.fbx", "kind": "loop", "loop": true},
	{"name": "run", "src": "zip:" + PACK_LOCO + "/standard run.fbx", "kind": "loop", "loop": true},
	{"name": "run_fast", "src": "Running.fbx", "kind": "loop", "loop": true},
	{"name": "walk_start", "src": "Start Walking.fbx", "kind": "start", "mirror": true},
	{"name": "walk_stop", "src": "Stop Walking.fbx", "kind": "stop", "mirror": true},
	{"name": "run_start", "src": "Idle To Sprint.fbx", "kind": "start", "mirror": true},
	{"name": "run_stop", "src": "Run To Stop.fbx", "kind": "stop", "mirror": true},
	{"name": "run_pivot", "src": "Running Turn 180.fbx", "kind": "pivot", "mirror": true},
	{"name": "walk_pivot", "src": "Walking Turn 180.fbx", "kind": "pivot", "mirror": true},
	{"name": "turn_l90", "src": "Left Turn 90.fbx", "kind": "turn"},
	{"name": "turn_r90", "src": "Right Turn 90.fbx", "kind": "turn"},
	{"name": "run_start_turn", "src": "Turn To Running.fbx", "kind": "start", "mirror": true},
]

## Drive ids for every src (from clip_manifest.tsv).
static func drive_ids(manifest_path: String) -> Dictionary:
	var ids := {}
	var f := FileAccess.open(manifest_path, FileAccess.READ)
	if f == null: return ids
	while not f.eof_reached():
		var l := f.get_line()
		var p := l.split("\t")
		if p.size() >= 2: ids[p[1].strip_edges()] = p[0].strip_edges()
	return ids

## Files to download: {file_name: drive_id}.
static func needed_files(manifest_path: String) -> Dictionary:
	var ids := drive_ids(manifest_path)
	var out := {}
	for c in CLIPS:
		var src: String = c.src
		var file := src.substr(4).get_slice("/", 0) if src.begins_with("zip:") else src
		if ids.has(file): out[file] = ids[file]
	return out
