extends SceneTree
## x_wall_feet (19 Nov 2026, Yasin on the trial picture of a face under a growth block's wall: "Yes, add it"): the faces
## under the growth blocks' outer retaining walls where the wall's foot stops above the land (a sliver of air, at most
## 32 cm). The blocks are LOCKED: the faces live in this overlay piece instead, as the shore foam lives in x_shore_foam.
## Geometry from map_dc/coronado/city_kit/zoning/wall_feet.json (tools/city/pilot/zoning/wall_feet.py: measured from the
## blocks' own wall faces and the land; it decides nothing). One "ground" mesh per block, in the walls' own material
## ("wall", UVs as kit_lib's wall faces), both sides: the runtime bake merges them into the cells' ground (no draw of
## their own). No props, no colliders. Placed at [0, 0, 0] in the grid frame (city_grid_layout.json).
## Rebuild after the land or a growth block changes: wall_feet.py --write, then this script.
const K := preload("res://tools/city/pilot/kit_lib.gd")

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var root := Node3D.new(); root.name = "x_wall_feet"
	var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/zoning/wall_feet.json"))
	var nb := 0; var ntri := 0
	var keys: Array = (j.blocks as Dictionary).keys(); keys.sort()
	for key: String in keys:
		var g := K.Ground.new()
		for q: Array in j.blocks[key]:
			var a1 := Vector3(float(q[0]), float(q[1]), float(q[2])); var b1 := Vector3(float(q[3]), float(q[4]), float(q[5]))
			var a0 := Vector3(a1.x, float(q[6]), a1.z); var b0 := Vector3(b1.x, float(q[7]), b1.z)
			var n := Vector3(b1.z - a1.z, 0.0, -(b1.x - a1.x))
			g.quad("wall", a0, b0, b1, a1, n, true)
			g.quad("wall", a0, b0, b1, a1, -n, true)
		if g.tri_count() == 0: continue
		var holder := Node3D.new(); holder.name = "feet_" + key.replace("#", "_")
		var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(mi); root.add_child(holder); nb += 1; ntri += g.tri_count()
	print("x_wall_feet blocks=%d tris=%d" % [nb, ntri])
	K.save_piece(root, "x_wall_feet")
	quit()
