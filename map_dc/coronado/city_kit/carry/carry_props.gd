extends RefCounted
## Carry props at runtime (page J, Yasin 22 Nov: briefcases, backpacks carried in hand, paper / plastic shopping bags,
## cardboard boxes and wood crates for NPCs and the player). Scenes are baked by tools/city/pilot/bake_carry.gd into
## carry/scenes/<name>.scn: a mesh (page-J kit prop shader) + Marker3D grip_r / grip_l.
##   var bag := CarryProps.spawn("bag_paper_kraft")            # Node3D, not yet in the tree
##   hand_bone_attachment.add_child(bag); CarryProps.attach(bag, "grip_r")   # puts the grip on the attachment origin
## hold(name): "one_hand_hang" (grip_r = grip_l on the handle; +X along the bar, +Y up) or "two_hand_sides" (boxes and
## crates: grip_l on the -X face, grip_r on the +X face; carry with both hands).
const DIR := "res://map_dc/coronado/city_kit/carry/scenes/"
static var _index := {}
static var _scenes := {}

static func index() -> Dictionary:
	if _index.is_empty():
		var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIR + "carry_props.json"))
		if typeof(v) == TYPE_DICTIONARY: _index = v
	return _index

static func names() -> Array:
	var n := index().keys(); n.sort(); return n

static func hold(name: String) -> String:
	return String((index().get(name, {}) as Dictionary).get("hold", ""))

static func two_hands(name: String) -> bool:
	return hold(name) == "two_hand_sides"

static func spawn(name: String) -> Node3D:
	if not _scenes.has(name):
		var p := DIR + name + ".scn"
		if not ResourceLoader.exists(p): push_warning("carry prop missing: " + name); return null
		_scenes[name] = load(p)
	return (_scenes[name] as PackedScene).instantiate() as Node3D

## the grip marker's transform in the prop's own frame
static func grip(prop: Node3D, side := "grip_r") -> Transform3D:
	var m := prop.get_node_or_null(side) as Node3D
	return m.transform if m else Transform3D.IDENTITY

## place a prop (already a child of a hand / bone attachment) so its grip sits on the parent's origin
static func attach(prop: Node3D, side := "grip_r") -> void:
	prop.transform = grip(prop, side).affine_inverse()

## an optional physics box for a dropped prop (the kit col box)
static func body(prop: Node3D) -> StaticBody3D:
	var a: AABB = prop.get_meta(&"col", AABB())
	var sb := StaticBody3D.new(); sb.name = "col"
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = a.size; cs.shape = bs
	cs.position = a.get_center(); sb.add_child(cs); prop.add_child(sb)
	return sb
