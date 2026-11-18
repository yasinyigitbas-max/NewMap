@tool
extends EditorScript
## Editor authoring -> runtime bake bridge.
## Open an assembly scene (root Node3D with the loose modular pieces as direct children), then File > Run this script.
## Writes res://modular_layouts/<root name>/layout.json; bake it with:
##   python3 modular/tools/merge_assembly.py <layout.json>
## and place the merged mod_<name>_{near,mid,far,col}.glb in the game. Loose pieces are for editor authoring only.
##
## Root metadata (Inspector > Metadata): group = "houses"|"shops"; outline = {kind, W, D, wall, tint, roof, budget}.
## Each child: its scene file must be mod_<piece>_near.glb (or set metadata "piece"); rotation must be 0/90/180/270 deg
## about Y; position must sit on the 0.5 m grid.

const GRID := 0.5

func _run() -> void:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		push_error("open an assembly scene first"); return
	var lay := build_layout(root)
	if lay.is_empty(): return
	var dir := "res://modular_layouts/%s" % root.name
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(dir + "/layout.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(lay, " "))
	print("wrote ", ProjectSettings.globalize_path(dir + "/layout.json"), " (", lay["pieces"].size(), " pieces)")

static func piece_name(n: Node) -> String:
	if n.has_meta("piece"): return String(n.get_meta("piece"))
	var f := n.scene_file_path.get_file().get_basename()   # mod_<piece>_near
	if f.begins_with("mod_") and f.ends_with("_near"): return f.substr(4, f.length() - 9)
	return ""

static func build_layout(root: Node) -> Dictionary:
	var pieces := []
	var ok := true
	for c in root.get_children():
		if not (c is Node3D): continue
		var p := piece_name(c)
		if p == "":
			push_error("%s: not a modular piece" % c.name); ok = false; continue
		var t: Vector3 = c.position
		var ry := int(round(rad_to_deg(c.rotation.y))) % 360
		if ry < 0: ry += 360
		if ry % 90 != 0 or absf(c.rotation.x) > 1e-4 or absf(c.rotation.z) > 1e-4:
			push_error("%s: rotate in 90 deg steps about Y only" % c.name); ok = false
		# pieces are snapped by their snap ends; the centre of a wall piece sits on the grid or half a slab off it
		pieces.append({"piece": p, "x": snappedf(t.x, 0.001), "z": snappedf(t.z, 0.001), "rot_y": ry})
	if not ok: return {}
	return {"name": String(root.name), "group": root.get_meta("group", "houses"),
		"outline": root.get_meta("outline", {}), "pieces": pieces}
