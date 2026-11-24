extends SceneTree
## His animations out for editing (Cascadeur / Blender): each clip of his libraries (characters/hero_v3/clips_<stem>.res)
## as its own GLB - his skeleton only, one animation - and his model once with its mesh. tools/people/humanoid/to_fbx.py
## turns them into FBX. Back in: tools/people/humanoid/import_edits.gd (to come).
##   godot --headless --path . -s res://tools/people/humanoid/export_clips.gd -- --out=DIR [--only=stem,stem] [--max=N]
const BODY := "res://assets/people/humanoid/player_v3.glb"
const STEMS := ["base", "ual", "step", "mx", "yl", "ms", "player_idle", "player_walk", "player_run", "player_trav", "player_act"]
## --player: only what the player plays - the player_* libraries and the clips the motor loads from the others
const PLAYER_EXTRA := {"ms": ["S3_Idle_Breathing", "S2_Idle_Unarmed", "S2_Idle_Unarmed_b", "S2_Idle_Loop"],
	"yl": ["Texting_While_Standing", "Texting_And_Walking_one_hand", "Talking_On_A_Cell_Phone", "Stand_To_Sit", "Sitting_Idle", "sit_Stand_Up"]}
func _init() -> void:
	var out := "user://clips_export"; var only := []; var mx := 1000000; var player_only := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		if a.begins_with("--only="): only = a.substr(7).split(",")
		if a.begins_with("--max="): mx = int(a.substr(6))
		if a == "--player": player_only = true
	DirAccess.make_dir_recursive_absolute(out)
	# his model, with its mesh, standing in its rest pose
	var body: Node3D = (load(BODY) as PackedScene).instantiate()
	_save(body, out + "/his_model.glb")
	var n := 0
	for stem in STEMS:
		if not only.is_empty() and not only.has(stem): continue
		var lib: AnimationLibrary = load("res://characters/hero_v3/clips_%s.res" % stem)
		if lib == null: continue
		DirAccess.make_dir_recursive_absolute("%s/%s" % [out, stem])
		for nm in lib.get_animation_list():
			if n >= mx: break
			if player_only and not stem.begins_with("player_") and not (PLAYER_EXTRA.get(stem, []) as Array).has(String(nm)): continue
			var s: Node3D = (load(BODY) as PackedScene).instantiate()
			# (the body kept: without a skinned mesh the exporter writes the bones as plain nodes and Blender / Cascadeur
			# read them as empties, not a skeleton - to_fbx.py drops the mesh from the animation files)
			var ap := AnimationPlayer.new(); ap.name = "AnimationPlayer"; s.add_child(ap); ap.owner = s
			var L := AnimationLibrary.new(); L.add_animation(nm, lib.get_animation(nm)); ap.add_animation_library("", L)
			_save(s, "%s/%s/%s.glb" % [out, stem, String(nm).replace("/", "_")])
			s.free(); n += 1
	print("EXPORT %d clips -> %s" % [n, out])
	quit()
func _save(n: Node, path: String) -> void:
	var doc := GLTFDocument.new(); var st := GLTFState.new()
	if doc.append_from_scene(n, st) != OK: print("EXPORT ERROR ", path); return
	if doc.write_to_filesystem(st, path) != OK: print("EXPORT ERROR write ", path)
