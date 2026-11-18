extends SceneTree
## Piece f_sw (waterfront sample, SW): the town beach.
## Promenade (z 9.2-18) along the drive: benches facing the sea, pier lamps, bins, bike racks parallel to the walk
## (people ride down), the snack kiosk with its picnic tables out on the sand, an outdoor shower at each beach
## access, then the boardwalk (4 x 3 m kit modules) along the top of the sand. The sand slopes 8 % from the boardwalk
## into the water and on under it (the shore line moves with the slope, no hard edge). On the sand: the lifeguard tower
## mid-beach facing the water, two volleyball courts at the quiet west end, umbrellas (open where families sit, a few
## furled), the kayak rental rack by the seawall, life rings at the seawall corner. The quay ends at the pier plaza in a
## rounded outside corner and a seawall return running back to the boardwalk (its toe shows more the lower the sand).
## Wear: sand blown onto the promenade and boardwalk edges, wet sand darker at the shower grates, grime round the bins
## and the kiosk, footpaths worn across the sand from each access to the water. Run once; never when locked.
const WF := preload("res://tools/city/pilot/pieces/wf_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const SL := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const CC := preload("res://tools/city/pilot/pieces/cc_lib.gd")
const SZ0 := 21.0           # top of the sand (behind the boardwalk)
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var root := Node3D.new(); root.name = "f_sw"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for("f_sw")
	var paints: Array = []
	var wy := WF.wy(); var QZ := WF.QZ
	# audit fix 2 (17 Nov, Yasin: "sand turns into the water abruptly and as a straight line"): the beach no longer has
	# one even 8 % slope. Its top stays on the straight boardwalk line, but where it meets the water wanders in gentle
	# bays and points (_shore_z), so each strip of beach has its own slope (about 7-9 %).
	var sy := func(x: float, z: float) -> float: return _sand_y(x, z)
	var on_sand := func(x: float, z: float) -> Vector3: return Vector3(x, _sand_y(x, z), z)
	# ---- promenade + boardwalk
	K.painted_rect(g, -100.0, 9.2, -11.0, SZ0, paints, S.walk_y, "plaza")
	for k in 22: I.add(props, "prop_prom_boardwalk", "worn", Vector3(-98.0 + k * 4.0, wy - 0.3, 19.5), 0.0)   # deck sits flush-ish with the walk
	for k2 in 6:
		var bx := -94.0 + k2 * 15.0
		I.add(props, "prop_park_bench", "worn", Vector3(bx, wy, 16.4), 0.0)              # facing the sea
		dec.add(14, Vector2(bx, 17.1), 0.0, 2.2, 1.3, S.walk_y, Color(1, 1, 1, 0.45))
		if k2 % 2 == 0: I.add(props, "prop_trash_receptacle", "dirty", Vector3(bx + 2.1, wy, 16.4), 0.0)
	for k3 in 8: I.add(props, "prop_pier_lamp", "worn", Vector3(-96.0 + k3 * 12.0, wy, 12.0), 0.0)
	for rx: float in [-88.0, -58.0, -28.0]: I.add(props, "prop_bike_rack", "worn", Vector3(rx, wy, 10.6), 0.0)   # parallel to the walk
	# snack kiosk facing the beach, its tables out on the sand in front
	var kio := K.building(bl, "commercial/com_kiosk", Vector3(-40.0, wy, 12.4), 0.0, "beach_kiosk", 0.8)
	CC.back_of_house(props, kio, "commercial/com_kiosk", false)      # meters on its back, the drive side
	for t: Vector2 in [Vector2(-44.0, 24.0), Vector2(-37.0, 24.5)]: I.add(props, "prop_picnic_table", "worn", on_sand.call(t.x, t.y), 90.0)
	I.add(props, "prop_shade_sail", "worn", on_sand.call(-44.0, 24.0), 90.0)     # one sail over each table
	I.add(props, "prop_shade_sail", "worn", on_sand.call(-37.0, 24.5), 90.0)
	I.add(props, "prop_trash_receptacle", "dirty", Vector3(-44.2, wy, 16.6), 0.0)
	I.add(props, "prop_recycling_receptacle", "worn", Vector3(-43.2, wy, 16.6), 0.0)
	dec.add(14, Vector2(-40.0, 16.4), 0.0, 4.0, 2.0, S.walk_y, Color(1, 1, 1, 0.6))    # the queue at the window
	# showers at the two beach accesses, wet sand at their grates
	for sx2: float in [-74.0, -20.0]:
		I.add(props, "prop_beach_shower", "worn", on_sand.call(sx2, 22.4), 0.0)
		dec.add(2, Vector2(sx2, 22.4), 0.0, 1.8, 1.8, sy, Color(1, 1, 1, 0.55))
	# ---- the sand
	g.rect("sand", -100.0, SZ0, -11.0, 70.0, sy, 1.5)      # 1.5 m grid: the curved waterline stays smooth
	# wet sand: a darker band the last metres above the waterline, following its curve, and a narrow darker strip
	# right at the edge where the swash runs up
	var wx := -98.0
	while wx < -12.5:
		var zs := _shore_z(wx)
		var ang := rad_to_deg(atan2(_shore_z(wx + 1.0) - _shore_z(wx - 1.0), 2.0))
		dec.add(14, Vector2(wx, zs - 1.5), -ang, 3.6, 2.6, sy, Color(0.78, 0.68, 0.52, 0.4))   # soft grime tile, heavy overlap: no seams
		dec.add(14, Vector2(wx + 0.7, zs - 0.4), -ang, 3.4, 1.2, sy, Color(0.66, 0.57, 0.44, 0.5))
		wx += 1.4
	_shore_foam(root)      # (Yasin 17 Nov: "wavy bubbly transition") the foam strip along the waterline
	I.add(props, "prop_lifeguard_tower", "worn", on_sand.call(-56.0, 31.0), 0.0)
	for vx: float in [-88.0, -72.0]: I.add(props, "prop_volleyball_net", "worn", on_sand.call(vx, 30.0), 0.0)    # nets along the beach, courts running down to the water
	var spots: Array = [Vector2(-66.0, 25.5), Vector2(-62.0, 29.0), Vector2(-50.0, 26.0), Vector2(-46.0, 30.5), Vector2(-32.0, 28.0), Vector2(-28.0, 32.5), Vector2(-24.0, 26.0)]
	for k4 in spots.size():
		var sp: Vector2 = spots[k4]
		I.add(props, "prop_beach_umbrella" if k4 % 3 != 2 else "prop_beach_umbrella_closed", "worn", on_sand.call(sp.x, sp.y), k4 * 37.0)
		dec.add(14, sp + Vector2(0.0, 1.4), k4 * 20.0, 2.6, 2.0, sy, Color(1, 1, 1, 0.3))    # where people lie
	# a busy summer day: more families further down toward the water, a second tower at the west end, palms along the
	# top of the sand (the Coronado look; trees stand in sand, never in the paving), skiffs pulled up at the waterline
	var more: Array = [Vector2(-70.0, 36.0), Vector2(-58.0, 35.0), Vector2(-54.0, 37.5), Vector2(-40.0, 34.0), Vector2(-36.0, 37.5), Vector2(-18.0, 33.0), Vector2(-64.0, 33.5), Vector2(-30.0, 36.0)]
	for k7 in more.size():
		var sp2: Vector2 = more[k7]
		I.add(props, "prop_beach_umbrella" if k7 % 4 != 3 else "prop_beach_umbrella_closed", "worn", on_sand.call(sp2.x, sp2.y), 20.0 + k7 * 41.0)
		dec.add(14, sp2 + Vector2(0.0, 1.4), k7 * 25.0, 2.6, 2.0, sy, Color(1, 1, 1, 0.3))
	I.add(props, "prop_lifeguard_tower", "worn", on_sand.call(-96.0, 35.0), 0.0)
	for px2: float in [-98.0, -86.0, -62.0, -50.0, -28.0]:
		I.add(props, ["palm_mexican_fan_a", "palm_mexican_fan_b", "palm_canary_date_a"][int(absf(px2)) % 3], "normal", on_sand.call(px2, 22.8), px2 * 7.0)
	# audit fix (17 Nov): the skiffs used to sit level on the 8 % beach, so one end hung in the air. A beached hull lies
	# on the slope (tilted with the sand) and sits a little into it.
	# audit fix 2: the skiff hull is a V with an upturned bow; lying upright it touched the sand along a thin keel line
	# only and its bow hung free. A boat pulled up on a beach heels over onto its side and settles in. Each hull is
	# now laid on the local slope, heeled 13 degrees, and lowered until its lowest point is 12 cm into the sand
	# (worked out from the model's own vertices, so it fits whatever the slope is there).
	var hull := PackedVector3Array()
	var sk_inst: Node = (load(K.prop_file("prop_boat_skiff", "worn", "near")) as PackedScene).instantiate()
	var sk_mi := K._first_mesh(sk_inst)
	for v: Vector3 in sk_mi.mesh.get_faces(): hull.append(sk_mi.transform * v)
	sk_inst.free()
	for sk: Vector2 in [Vector2(-14.5, 36.6), Vector2(-17.5, 37.0)]:
		var gy0: float = _sand_y(sk.x, sk.y)
		var n := Vector3(-(_sand_y(sk.x + 0.5, sk.y) - _sand_y(sk.x - 0.5, sk.y)), 1.0, -(_sand_y(sk.x, sk.y + 0.5) - gy0) * 2.0).normalized()
		var yw := deg_to_rad(15.0 if sk.x > -16.0 else -10.0)
		var f0 := Vector3(sin(yw), 0.0, cos(yw))
		var fz := (f0 - n * f0.dot(n)).normalized()
		var bas := Basis(n.cross(fz).normalized(), n, fz)
		bas = Basis(fz, deg_to_rad(13.0 if sk.x > -16.0 else -13.0)) * bas      # heeled onto one side
		var low := INF
		for hv: Vector3 in hull: low = minf(low, (bas * hv).dot(n))
		var pos: Vector3 = Vector3(sk.x, gy0, sk.y) - n * (low + 0.12)
		if not props.items.has("prop_boat_skiff|worn"): props.items["prop_boat_skiff|worn"] = []
		props.items["prop_boat_skiff|worn"].append(Transform3D(bas, pos))
		props.col_items.append(["prop_boat_skiff", "worn", Transform3D(bas, pos)])
	I.add(props, "prop_kayak_rack", "worn", on_sand.call(-16.0, 24.0), 0.0)
	I.add(props, "prop_lifering_stand", "worn", on_sand.call(-12.6, QZ - 2.4), -90.0)   # audit fix: on the sand at the seawall foot (it hung 1.3 m over the sand)
	# paths worn from the accesses to the water
	for ax: float in [-74.0, -40.0, -20.0]:
		for k5 in 4: dec.add(14, Vector2(ax + rr.randf_range(-0.6, 0.6), 23.0 + k5 * 4.2), 0.0, 1.6, 4.0, sy, Color(1, 1, 1, 0.3))
	# sand blown onto the boardwalk / promenade edge (pale patches, sand-tinted)
	for k6 in 10: dec.add(4 + k6 % 2, Vector2(rr.randf_range(-98.0, -14.0), rr.randf_range(17.6, 18.8)), rr.randf_range(0, 180), rr.randf_range(1.5, 3.5), rr.randf_range(0.6, 1.2), S.walk_y, Color(0.86, 0.79, 0.64, 0.6))
	# ---- seawall end: rounded outside corner + the return wall back to the boardwalk (water face to the west)
	I.add(props, "prop_quay_corner_out", "worn", Vector3(-10.0, WF.bed(), QZ - 1.0), 0.0)
	for rz: float in [35.0, 29.0, 23.0]: I.add(props, "prop_quay_straight", "worn", Vector3(-10.0, WF.bed(), rz), -90.0)
	# far out: two mooring buoys off the beach (summer boats)
	for mb: Vector2 in [Vector2(-60.0, 110.0), Vector2(-30.0, 120.0)]: I.add(props, "prop_buoy_mooring", "worn", Vector3(mb.x, WF.bed(), mb.y), 0.0)
	SL.finish(root, g, props, dec, "f_sw", [])
	quit()

## where the sand meets the water (z) along the beach: gentle bays and points, 0 to 5 m seaward of the old straight
## line, fading back to it near both ends (the seawall return at x -10 and the piece edge at x -100)
static func _shore_z(x: float) -> float:
	var w := smoothstep(-11.0, -24.0, x) * smoothstep(-100.0, -88.0, x)
	return SZ0 + 1.5 / 0.08 + w * (2.2 + 1.8 * sin(x * 0.15 + 0.7) + 0.9 * sin(x * 0.37 + 2.1))

## sand height: level with the walk at the boardwalk line, falling straight to the water at _shore_z, on under it
static func _sand_y(x: float, z: float) -> float:
	return WF.wy() - maxf(0.0, z - SZ0) * 1.5 / (_shore_z(x) - SZ0)

## the foam strip: from 3 m up the wet sand to 4.5 m out to sea along the curved waterline, 2 cm over whichever is
## higher (sand or water), drawn by city_kit/shaders/shore_foam.gdshader (one draw, unshaded, no shadows)
static func _shore_foam(root: Node3D) -> void:
	var x0 := -98.5; var x1 := -12.5
	var nx := int((x1 - x0) / 1.0); var nv := 12
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pt := func(i: int, j: int) -> Array:
		var x := x0 + (x1 - x0) * float(i) / nx
		var v := float(j) / nv
		var z := _shore_z(x) - 3.0 + v * 7.5
		return [Vector3(x, maxf(_sand_y(x, z), WF.water()) + 0.02, z), Vector2(float(i) / nx, v)]
	for i in nx:
		for j in nv:
			var q: Array = [pt.call(i, j), pt.call(i + 1, j), pt.call(i + 1, j + 1), pt.call(i, j + 1)]
			for k: int in [0, 1, 2, 0, 2, 3]:
				st.set_normal(Vector3.UP); st.set_uv(q[k][1]); st.add_vertex(q[k][0])
	var mi := MeshInstance3D.new(); mi.name = "shore_foam"; mi.mesh = st.commit()
	var mat := ShaderMaterial.new(); mat.shader = load("res://map_dc/coronado/city_kit/shaders/shore_foam.gdshader")
	var nt := NoiseTexture2D.new(); nt.width = 256; nt.height = 256; nt.seamless = true; nt.generate_mipmaps = true
	var fn := FastNoiseLite.new(); fn.noise_type = FastNoiseLite.TYPE_CELLULAR; fn.frequency = 0.06
	fn.cellular_return_type = FastNoiseLite.RETURN_DISTANCE; nt.noise = fn
	mat.set_shader_parameter("foam_noise", nt)
	mat.set_shader_parameter("shore_v", 3.0 / 7.5)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = 220.0
	root.add_child(mi)
