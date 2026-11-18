extends RefCounted
## Hand-made kit rooms (17 Nov, interiors session): the room inside a kit building, authored in the BUILDING MODEL'S
## own frame (origin = footprint bottom centre, front = +Z, metres) so it is placed with the building's transform.
## Visuals only for now (Yasin 17 Nov: "they dont need to be interactable yet ... make them look good").
##
## A room = shell (floor, walls with real holes where the building's door and windows are, ceiling, skirting,
## wainscot, door jambs through the wall to the facade) + kit indoor props (assets/coronado_kit/props/indoor, page I)
## + light fixtures with real lights + floor wear. Saved as a scene per room: interiors/rooms/<name>.scn.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const TEX := "res://map_dc/coronado/shops/interior/assets/tex/"
const INDOOR := "res://assets/coronado_kit/props/indoor/"

var root: Node3D
var _mats := {}
var _surf := {}             # material key -> [verts, normals, uvs]
var _props := {}            # base -> Array[Transform3D]
var lights: Node3D
var dec: K.Decals
var floor_y := 0.0
var _floors: Array = []     # [x0, z0, x1, z1] walkable floor rects (meta "floors")
var _solids: Array = []     # [x0, z0, x1, z1] partitions / wall boxes standing on the floor (meta "solids")
var _cut: Array = []        # [facade, along] of every building opening this room fills (meta "cut": the bake cuts exactly these)
var _doors: Array = []      # entrances: [axis, at, s0, s1] (meta "entrances")
const SWING := preload("res://map_dc/coronado/city_kit/interiors/rooms/door_swing.gd")
const SLAB_OUT := 0.9      # door threshold / storefront plinth: metres out past the facade (covers the ground strip)
const SLAB_TOP := 0.001    # slab top over the door sill: level with the ground (measured: pavement / porch = sill), 1 mm against z-fight (Yasin 18 Nov: "they should be level")
const PROP_WEAR := 0.2    # indoor props: the kit's "clean" condition (a light wear, never brand new)
const NEAR_END := 62.0      # the kit building near tier's end (kit_lib Props / building ranges)

func _init(name: String, fy := 0.0) -> void:
	root = Node3D.new(); root.name = name
	lights = Node3D.new(); lights.name = "Lights"; root.add_child(lights)
	dec = K.Decals.new()
	floor_y = fy

## a photo-textured material (ambientCG set from the shop rooms' texture folder), tile metres, tint
func mat(key: String, tex: String, tile: float, tint := Color(1, 1, 1), rough := 0.85) -> void:
	var m := StandardMaterial3D.new()
	for res: String in ["_2k", "_1k"]:
		var c := TEX + tex + res + "_color.jpg"
		if ResourceLoader.exists(c):
			m.albedo_texture = load(c)
			var nrm := TEX + tex + res + "_normal.jpg"
			if ResourceLoader.exists(nrm): m.normal_enabled = true; m.normal_texture = load(nrm)
			break
	m.albedo_color = tint; m.roughness = rough
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mats[key] = [m, tile]

func plain(key: String, col: Color, rough := 0.6, emit := 0.0) -> void:
	var m := StandardMaterial3D.new(); m.albedo_color = col; m.roughness = rough
	if emit > 0.0: m.emission_enabled = true; m.emission = col; m.emission_energy_multiplier = emit
	_mats[key] = [m, 1.0]

func _q(key: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, uva: Vector2, uvb: Vector2, uvc: Vector2, uvd: Vector2) -> void:
	if not _surf.has(key): _surf[key] = [[], [], []]      # plain Arrays: packed arrays are copied on access
	var s: Array = _surf[key]
	# Godot front faces wind clockwise seen from the front
	for p: Array in [[a, uva], [c, uvc], [b, uvb], [a, uva], [d, uvd], [c, uvc]]:
		(s[0] as Array).append(p[0]); (s[1] as Array).append(n); (s[2] as Array).append(p[1])

## a horizontal rectangle at height y facing up (floor) or down (ceiling)
func flat(key: String, x0: float, z0: float, x1: float, z1: float, y: float, up := true) -> void:
	var t: float = _mats[key][1]
	if up and key.contains("floor"): _floors.append([minf(x0, x1), minf(z0, z1), maxf(x0, x1), maxf(z0, z1)])
	if up and key.contains("floor"): y += 0.02     # 2 cm over the piece's own ground under the building (no z-fight)
	var a := Vector3(x0, y, z0); var b := Vector3(x1, y, z0); var c := Vector3(x1, y, z1); var d := Vector3(x0, y, z1)
	var ua := Vector2(x0, z0) / t; var ub := Vector2(x1, z0) / t; var uc := Vector2(x1, z1) / t; var ud := Vector2(x0, z1) / t
	if up: _q(key, a, d, c, b, Vector3.UP, ua, ud, uc, ub)
	else: _q(key, a, b, c, d, Vector3.DOWN, ua, ub, uc, ud)

## a wall on the plane axis = "x" (constant x, runs along z) or "z" (constant z, runs along x), facing `inward`
## (the direction into the room), from s0..s1 along it and y0..y1 high, with rectangular holes [s0, s1, y0, y1]
func wall(key: String, axis: String, at: float, s0: float, s1: float, y0: float, y1: float, inward: float, holes: Array = []) -> void:
	var ss := {s0: true, s1: true}; var ys := {y0: true, y1: true}
	for h: Array in holes:
		ss[clampf(float(h[0]), s0, s1)] = true; ss[clampf(float(h[1]), s0, s1)] = true
		ys[clampf(float(h[2]), y0, y1)] = true; ys[clampf(float(h[3]), y0, y1)] = true
	var sa: Array = ss.keys(); sa.sort(); var ya: Array = ys.keys(); ya.sort()
	var t: float = _mats[key][1]
	for i in sa.size() - 1:
		for j in ya.size() - 1:
			var cs := (float(sa[i]) + float(sa[i + 1])) * 0.5; var cy := (float(ya[j]) + float(ya[j + 1])) * 0.5
			var hole := false
			for h: Array in holes:
				if cs > float(h[0]) and cs < float(h[1]) and cy > float(h[2]) and cy < float(h[3]): hole = true
			if hole: continue
			_wall_quad(key, axis, at, float(sa[i]), float(sa[i + 1]), float(ya[j]), float(ya[j + 1]), inward, t)

func _wall_quad(key: String, axis: String, at: float, a0: float, a1: float, y0: float, y1: float, inward: float, t: float) -> void:
	var p := func(s: float, y: float) -> Vector3: return Vector3(at, y, s) if axis == "x" else Vector3(s, y, at)
	var n := Vector3(inward, 0, 0) if axis == "x" else Vector3(0, 0, inward)
	var A: Vector3 = p.call(a0, y0); var B: Vector3 = p.call(a1, y0); var C: Vector3 = p.call(a1, y1); var D: Vector3 = p.call(a0, y1)
	var ua := Vector2(a0, -y0) / t; var ub := Vector2(a1, -y0) / t; var uc := Vector2(a1, -y1) / t; var ud := Vector2(a0, -y1) / t
	# face the inward side: the winding flips with the axis and the side
	var flip := (inward > 0) == (axis == "z")
	if flip: _q(key, A, B, C, D, n, ua, ub, uc, ud)
	else: _q(key, A, D, C, B, n, ua, ud, uc, ub)

## the reveal of an opening through a wall of thickness th (door jambs and head), wall plane axis "z" at z = at, the
## facade further out at z = at + th (front wall) - closes the gap between the room and the building's door
func reveal_z(key: String, at: float, th: float, x0: float, x1: float, y0: float, y1: float) -> void:
	var t: float = _mats[key][1]
	var z0 := at; var z1 := at + th
	_q(key, Vector3(x0, y0, z0), Vector3(x0, y0, z1), Vector3(x0, y1, z1), Vector3(x0, y1, z0), Vector3(1, 0, 0), Vector2(z0, -y0) / t, Vector2(z1, -y0) / t, Vector2(z1, -y1) / t, Vector2(z0, -y1) / t)
	_q(key, Vector3(x1, y0, z0), Vector3(x1, y1, z0), Vector3(x1, y1, z1), Vector3(x1, y0, z1), Vector3(-1, 0, 0), Vector2(z0, -y0) / t, Vector2(z0, -y1) / t, Vector2(z1, -y1) / t, Vector2(z1, -y0) / t)
	_q(key, Vector3(x0, y1, z0), Vector3(x0, y1, z1), Vector3(x1, y1, z1), Vector3(x1, y1, z0), Vector3(0, -1, 0), Vector2(x0, z0) / t, Vector2(x0, z1) / t, Vector2(x1, z1) / t, Vector2(x1, z0) / t)

## a box (skirting, shelves, partitions, window glass panels ...) as six quads
func box(key: String, c: Vector3, size: Vector3) -> void:
	var h := size * 0.5
	if key == "wall" and c.y - h.y <= floor_y + 0.1: _solids.append([c.x - h.x, c.z - h.z, c.x + h.x, c.z + h.z])
	var x0 := c.x - h.x; var x1 := c.x + h.x; var y0 := c.y - h.y; var y1 := c.y + h.y; var z0 := c.z - h.z; var z1 := c.z + h.z
	wall(key, "x", x1, z0, z1, y0, y1, 1.0); wall(key, "x", x0, z0, z1, y0, y1, -1.0)
	wall(key, "z", z1, x0, x1, y0, y1, 1.0); wall(key, "z", z0, x0, x1, y0, y1, -1.0)
	flat(key, x0, z0, x1, z1, y1, true); flat(key, x0, z0, x1, z1, y0, false)

## one kit indoor prop (file base without the prop_ prefix is fine), on the floor, facing yaw (kit front = +Z)
func prop(base: String, x: float, z: float, yaw := 0.0, y := 0.0) -> void:
	if not (base.begins_with("prop_") or base.begins_with("plant_") or base.begins_with("tree_") or base.begins_with("palm_")): base = "prop_" + base
	if not _props.has(base): _props[base] = []
	(_props[base] as Array).append(Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), Vector3(x, floor_y + y, z)))

## a ceiling light fixture: an emissive pendant shade (or flush panel) + a real omni light under it
func pendant(x: float, z: float, ceil_y: float, drop := 0.9, col := Color(1.0, 0.82, 0.6), energy := 1.4, rng := 5.5, panel := false) -> void:
	var y := ceil_y - (0.05 if panel else drop)
	if panel: box("light_panel", Vector3(x, ceil_y - 0.02, z), Vector3(1.2, 0.03, 0.6))
	else:
		box("pendant_cord", Vector3(x, (ceil_y + y) * 0.5, z), Vector3(0.015, drop, 0.015))
		box("pendant_shade", Vector3(x, y, z), Vector3(0.36, 0.2, 0.36))
		box("bulb", Vector3(x, y - 0.11, z), Vector3(0.14, 0.04, 0.14))
	var l := OmniLight3D.new(); l.position = Vector3(x, y - 0.15, z); l.light_color = col; l.light_energy = energy
	l.omni_range = rng; l.omni_attenuation = 1.3; l.shadow_enabled = false
	lights.add_child(l)

## ------------------------------------------------------------------------------------------------- real windows
## (Yasin 17 Nov: rooms must be seen from outside too, frames visible inside and out) The building's painted window
## panel is removed at bake time (preview: in memory), and the room supplies the real window in that opening:
## reveals from the room's inner wall face out to the facade plane, a 3D frame at the facade (the same frame seen from
## the street and from inside) with mullions by window type, an inside window board, and a clear pane.
## axis "z": the window is in a wall of constant z (front / back), "x": constant x (sides). wall_at = the room's inner
## wall face, plane = the building's facade plane there (from room_contracts.json), s = along the wall, y = sill..head.
const FRAME_STYLE := {"storefront": ["frame_metal", 0.07, 1.4, 2.25], "casement": ["frame_white", 0.06, 0.0, 0.0], "civic": ["frame_white", 0.06, 0.0, 0.0],
	"small": ["frame_white", 0.05, 0.0, 0.0], "dh": ["frame_white", 0.06, 0.0, 0.0]}
func window(axis: String, wall_at: float, plane: float, s0: float, s1: float, y0: float, y1: float, kind := "casement", ry0 := -1.0, ry1 := -1.0, with_board := true) -> void:
	if not _mats.has("glass_clear"):
		var g := StandardMaterial3D.new(); g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		g.albedo_color = Color(0.55, 0.62, 0.66, 0.18); g.roughness = 0.04; g.metallic_specular = 0.9
		g.cull_mode = BaseMaterial3D.CULL_DISABLED; g.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
		_mats["glass_clear"] = [g, 1.0]
	if not _mats.has("frame_metal"): plain("frame_metal", Color(0.16, 0.15, 0.14), 0.35)
	if not _mats.has("frame_white"): plain("frame_white", Color(0.86, 0.85, 0.82), 0.5)
	if not _mats.has("board"): mat("board", "Wood058", 1.0, Color(0.8, 0.7, 0.58))
	var st: Array = FRAME_STYLE.get(kind, FRAME_STYLE.casement)
	var fm: String = st[0]; var fw: float = st[1]
	var out := signf(plane - wall_at)              # +1 / -1: the direction out of the room
	var fz := plane - out * 0.05                   # the frame sits just inside the facade plane
	var depth := absf(plane - wall_at)
	var P := func(s: float, y: float, z: float) -> Vector3: return Vector3(s, y, z) if axis == "z" else Vector3(z, y, s)
	var B := func(c: Vector3, sz: Vector3) -> void:
		box(fm, c if axis == "z" else Vector3(c.z, c.y, c.x), sz if axis == "z" else Vector3(sz.z, sz.y, sz.x))
	# reveals: jambs, head and sill from the inner wall face to the facade (wall colour; a deep storefront sill = a ledge)
	_reveal(axis, wall_at, plane, s0, s1, y0, y1)
	# the frame: a perimeter at the facade, mullions / transom by type
	var w := s1 - s0; var h := y1 - y0
	# the frame laps 3 cm past the cut on every side (no sliver of the opening shows at the edges)
	s0 -= 0.03; s1 += 0.03; w += 0.06
	B.call(Vector3((s0 + s1) * 0.5, y1 - fw * 0.5, fz), Vector3(w, fw, 0.08))
	B.call(Vector3((s0 + s1) * 0.5, y0 + fw * 0.5, fz), Vector3(w, fw, 0.08))
	B.call(Vector3(s0 + fw * 0.5, (y0 + y1) * 0.5, fz), Vector3(fw, h, 0.08))
	B.call(Vector3(s1 - fw * 0.5, (y0 + y1) * 0.5, fz), Vector3(fw, h, 0.08))
	match kind:
		"storefront":
			var n := maxi(1, int(round(w / float(st[2]))))
			for i in range(1, n): B.call(Vector3(s0 + w * i / n, (y0 + y1) * 0.5, fz), Vector3(fw, h, 0.08))
			if h > 2.0: B.call(Vector3((s0 + s1) * 0.5, y0 + minf(float(st[3]) - y0, h - 0.4), fz), Vector3(w, fw * 0.8, 0.08))
		"casement", "civic":
			B.call(Vector3((s0 + s1) * 0.5, (y0 + y1) * 0.5, fz), Vector3(fw * 0.8, h, 0.07))
			if kind == "civic" or h > 1.6: B.call(Vector3((s0 + s1) * 0.5, y0 + h * 0.62, fz), Vector3(w, fw * 0.8, 0.07))
		"dh":
			B.call(Vector3((s0 + s1) * 0.5, (y0 + y1) * 0.5, fz), Vector3(w, fw, 0.07))
	# the parts of the building's painted panel outside the glass (storefront bulkhead below, spandrel above) are
	# filled at the facade plane, so the street sees a finished front where the panel was removed
	if not _mats.has("bulkhead"): mat("bulkhead", "Tiles101", 0.5, Color(0.62, 0.3, 0.26))
	if ry0 >= 0.0:
		_slab(axis, wall_at, plane, s0, s1, ry0)       # the ground under the storefront, level with the street
	for band: Array in [[ry0, y0, "bulkhead"], [y1, ry1, fm]]:
		if float(band[0]) >= 0.0 and float(band[1]) - float(band[0]) > 0.02:
			var by := (float(band[0]) + float(band[1])) * 0.5; var bh := float(band[1]) - float(band[0])
			if axis == "z": box(String(band[2]), Vector3((s0 + s1) * 0.5, by, plane - out * 0.06), Vector3(w, bh, 0.1))
			else: box(String(band[2]), Vector3(plane - out * 0.06, by, (s0 + s1) * 0.5), Vector3(0.1, bh, w))
	# the inside window board under the sill (a ledge people lean on; on the storefront it is a real counter)
	if with_board:
		var bd := 0.06 + (0.22 if kind == "storefront" else 0.0)
		var bz := wall_at - out * bd * 0.5 + out * 0.01
		if axis == "z": box("board", Vector3((s0 + s1) * 0.5, y0 - 0.02, bz), Vector3(w + 0.12, 0.04, bd + 0.02))
		else: box("board", Vector3(bz, y0 - 0.02, (s0 + s1) * 0.5), Vector3(bd + 0.02, 0.04, w + 0.12))
	# the pane (one quad, both sides)
	var gz := plane - out * 0.09
	var a: Vector3 = P.call(s0, y0, gz); var b: Vector3 = P.call(s1, y0, gz); var c: Vector3 = P.call(s1, y1, gz); var d: Vector3 = P.call(s0, y1, gz)
	_q("glass_clear", a, b, c, d, Vector3(0, 0, -out) if axis == "z" else Vector3(-out, 0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0))

## a doorway in the building's door opening: reveal through to the facade, a metal frame at the facade, a transom
## light over 2.3 m (the painted door panel's transom becomes real glass). The doorway itself stays open (preview);
## the game's sliding leaf goes in the lower part.
func door(axis: String, wall_at: float, plane: float, s0: float, s1: float, y0: float, y1: float, style := "shop") -> void:
	if not _mats.has("frame_metal"): plain("frame_metal", Color(0.16, 0.15, 0.14), 0.35)
	if not _mats.has("door"): mat("door", "Wood058", 1.0, Color(0.55, 0.42, 0.3))
	var ty := y0 + 2.3
	_reveal(axis, wall_at, plane, s0, s1, y0, ty)
	var out := signf(plane - wall_at); var fz := plane - out * 0.05
	var bx := func(c: Vector3, sz: Vector3) -> void: box("frame_metal", c if axis == "z" else Vector3(c.z, c.y, c.x), sz if axis == "z" else Vector3(sz.z, sz.y, sz.x))
	bx.call(Vector3(s0 + 0.04, (y0 + ty) * 0.5, fz), Vector3(0.08, ty - y0, 0.1))
	bx.call(Vector3(s1 - 0.04, (y0 + ty) * 0.5, fz), Vector3(0.08, ty - y0, 0.1))
	if y1 - ty > 0.25: window(axis, wall_at, plane, s0, s1, ty, y1, "small", -1.0, -1.0, false)
	else: bx.call(Vector3((s0 + s1) * 0.5, ty, fz), Vector3(s1 - s0, 0.08, 0.1))
	_leaves(axis, plane, out, s0 + 0.08, s1 - 0.08, y0, ty, style)
	_slab(axis, wall_at, plane, s0, s1, y0)

## the ground at a door / storefront, level with what is around it (Yasin 18 Nov: "they should be level ... the same
## material and colour as what they are placed on"). Measured (zz ground probe): the street ground is at the sill.
## A shop door meets the pavement, which the kit stops ~0.45 m short of the facade (grass in the gap): the slab is the
## kit's own pavement material (g_concrete) mapped like the street's (world xz * 0.5), so the pattern runs through.
## A civic door opens onto the building's porch (sill 0.3 over the street): only the doorway in the wall is filled,
## in the room's floor material.
func _slab(axis: String, wall_at: float, plane: float, s0: float, s1: float, y: float) -> void:
	var out := signf(plane - wall_at)
	var porch := y > 0.1
	var p1 := plane if porch else plane + out * SLAB_OUT
	var a0 := s0 - 0.15; var a1 := s1 + 0.15
	var x0: float; var x1: float; var z0: float; var z1: float
	if axis == "z": x0 = a0; x1 = a1; z0 = minf(wall_at, p1); z1 = maxf(wall_at, p1)
	else: z0 = a0; z1 = a1; x0 = minf(wall_at, p1); x1 = maxf(wall_at, p1)
	var yt := y + SLAB_TOP
	var key := "floor" if porch and _mats.has("floor") else "pave"
	if key == "pave" and not _mats.has("pave"): _mats["pave"] = [load(PAVE), 1.0]
	var c := [Vector3(x0, yt, z0), Vector3(x1, yt, z0), Vector3(x1, yt, z1), Vector3(x0, yt, z1)]
	var uvs: Array = []
	for v: Vector3 in c:
		if key == "pave":
			var wv := world_xf * v
			uvs.append(Vector2(wv.x, wv.z) * 0.5)
		else: uvs.append(Vector2(v.x, v.z) / float(_mats[key][1]))
	_q(key, c[0], c[3], c[2], c[1], Vector3.UP, uvs[0], uvs[3], uvs[2], uvs[1])

const PAVE := "res://map_dc/coronado/city_kit/materials/g_concrete.tres"
var world_xf := Transform3D()
## the building's world transform (sample_buildings.json): surfaces that continue the street's own (the door slabs)
## are mapped in world space like it
func place(piece: String, label: String) -> void:
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/interiors/sample_buildings.json"))
	var rows: Array = doc if doc is Array else (doc as Dictionary).buildings
	for b: Dictionary in rows:
		if String(b.piece) == piece and String(b.label) == label:
			var p: Array = b.pos
			world_xf = Transform3D(Basis(Vector3.UP, deg_to_rad(float(b.yaw))), Vector3(float(p[0]), float(p[1]), float(p[2]))); return
	push_error("room place: no building %s/%s" % [piece, label])

## ------------------------------------------------------------------------------------------------- openings from the contract
## Every ground-floor opening of the building, exactly as measured from its mesh (room_contracts.json), so a hole, frame
## and glass always match the panel the bake cuts - nothing typed by hand. walls = {"front": z, "back": z, "left": x,
## "right": x} (the room's inner wall faces). Returns the holes per wall for wall(). Entrance doors (shop / civic)
## get an open frame + leaves; other doors (back / side) a closed solid leaf; windows by their atlas type.
const WIN_KIND := {"O_storefront": "storefront", "O_glass_plain": "storefront", "O_civic_win": "civic", "O_lancet": "civic",
	"O_win_dh_white": "dh", "O_win_dh_div": "dh", "O_ribbon": "small", "O_small_white": "small", "O_small_dark": "small"}
## bounds = [x0, z0, x1, z1] of the room (a bay of a row): only openings inside it are built (and cut); outer = the
## facades whose wall IS the building's outer wall (a party wall between two bays has no openings)
func openings(contract: Dictionary, walls: Dictionary, bounds: Array = [], outer: Dictionary = {}) -> Dictionary:
	var holes := {"front": [], "back": [], "left": [], "right": []}
	for o: Dictionary in contract.openings:
		if int(o.floor) != 0 or not walls.has(String(o.facade)): continue
		if not outer.is_empty() and not bool(outer.get(String(o.facade), false)): continue
		if not bounds.is_empty():
			var fr := String(o.facade) == "front" or String(o.facade) == "back"
			var lo := float(bounds[0]) if fr else float(bounds[1]); var hi := float(bounds[2]) if fr else float(bounds[3])
			if float(o.along) - float(o.w) * 0.5 < lo - 0.05 or float(o.along) + float(o.w) * 0.5 > hi + 0.05: continue
		_cut.append([String(o.facade), float(o.along)])
		var reg := String(o.region)
		var fac := String(o.facade)
		var axis := "z" if (fac == "front" or fac == "back") else "x"
		var at: float = walls[fac]
		var s0 := float(o.along) - float(o.w) * 0.5; var s1 := float(o.along) + float(o.w) * 0.5
		var y0 := float(o.y0); var y1 := float(o.y1)
		if reg == "O_shopdoor" or reg == "O_civic_door":
			# the building's own pier stands in front of part of the painted door ("clear" in the contract): the door
			# takes the clear part, a dark frame panel closes the doorway behind the pier
			var c0 := s0; var c1 := s1
			if o.has("clear"): c0 = float(o.clear[0]); c1 = float(o.clear[1])
			(holes[fac] as Array).append([c0, c1, y0, y1])
			_openings.append([axis, at, c0, c1, y0, y1, "door"])
			door(axis, at, float(o.plane), c0, c1, y0, y1, "civic" if reg == "O_civic_door" else "shop")
			_doors.append([axis, at, c0, c1, float(o.plane)])
			for bl: Array in [[s0, c0], [c1, s1]]:
				if float(bl[1]) - float(bl[0]) < 0.02: continue
				_closed_part(axis, at, float(o.plane), float(bl[0]), float(bl[1]), y0, y1)
		elif reg == "O_apt_door" or reg == "O_patio" or reg == "O_rollup":
			(holes[fac] as Array).append([s0, s1, y0, y1])
			solid_door(axis, at, s0, s1, y0, y1)
		elif reg.begins_with("O_win_") or WIN_KIND.has(reg):
			var kind: String = WIN_KIND.get(reg, "casement")
			if kind == "storefront":
				# the storefront panel runs from the ground: glass over a tiled bulkhead, a spandrel under the head
				var gy0 := y0 + 0.55; var gy1 := y1 - 0.25
				(holes[fac] as Array).append([s0, s1, gy0, gy1])
				_openings.append([axis, at, s0, s1, y0, y1, "window"])
				window(axis, at, float(o.plane), s0, s1, gy0, gy1, kind, y0, y1)
			else:
				(holes[fac] as Array).append([s0, s1, y0, y1])
				_openings.append([axis, at, s0, s1, y0, y1, "window"])
				window(axis, at, float(o.plane), s0, s1, y0, y1, kind)
	return holes

## the room's four walls with every ground-floor opening of its building inside the room (bay rooms: bounds + outer)
func walls4(contract: Dictionary, X0: float, X1: float, ZB: float, ZF: float, F: float, H: float, outer: Dictionary = {}) -> void:
	var holes: Dictionary = openings(contract, {"front": ZF, "back": ZB, "left": X0, "right": X1}, [X0, ZB, X1, ZF], outer)
	wall("wall", "z", ZF, X0, X1, F, H, -1.0, holes.front)
	wall("wall", "z", ZB, X0, X1, F, H, 1.0, holes.back)
	wall("wall", "x", X0, ZB, ZF, F, H, 1.0, holes.left)
	wall("wall", "x", X1, ZB, ZF, F, H, -1.0, holes.right)

## the part of a painted doorway the building's pier stands in front of: the room wall runs on behind it (no hole), and
## a dark metal panel fills the painted door's place at the frame plane, so the bake's cut shows a door frame, not a gap
func _closed_part(axis: String, wall_at: float, plane: float, s0: float, s1: float, y0: float, y1: float) -> void:
	if not _mats.has("frame_metal"): plain("frame_metal", Color(0.16, 0.15, 0.14), 0.35)
	var out := signf(plane - wall_at); var fz := plane - out * 0.05
	var c := Vector3((s0 + s1) * 0.5, (y0 + y1) * 0.5, fz); var sz := Vector3(s1 - s0 + 0.03, y1 - y0, 0.1)
	if axis == "z": box("frame_metal", c, sz)
	else: box("frame_metal", Vector3(c.z, c.y, c.x), Vector3(sz.z, sz.y, sz.x))
	# the reveal behind the panel, so nothing shows between the panel and the room wall
	var mz := (wall_at + fz) * 0.5; var dz := absf(fz - wall_at)
	if axis == "z": box("wall", Vector3((s0 + s1) * 0.5, (y0 + y1) * 0.5, mz), Vector3(s1 - s0, y1 - y0, dz))
	else: box("wall", Vector3(mz, (y0 + y1) * 0.5, (s0 + s1) * 0.5), Vector3(dz, y1 - y0, s1 - s0))

## a closed solid door leaf filling a hole in the room wall (back and side doors: staff, deliveries)
## every opening built in the room's walls, for the indoor checker's "cover" rule: [axis, at, s0, s1, y0, y1, kind]
var _openings: Array = []

func solid_door(axis: String, at: float, s0: float, s1: float, y0: float, y1: float) -> void:
	_openings.append([axis, at, s0, s1, y0, y1, "door"])
	if not _mats.has("door"): mat("door", "Wood058", 1.0, Color(0.55, 0.42, 0.3))
	var c := (s0 + s1) * 0.5
	if axis == "z": box("door", Vector3(c, (y0 + y1) * 0.5, at), Vector3(s1 - s0, y1 - y0, 0.06))
	else: box("door", Vector3(at, (y0 + y1) * 0.5, c), Vector3(0.06, y1 - y0, s1 - s0))

func _ensure_glass() -> void:
	if not _mats.has("glass_clear"):
		var g := StandardMaterial3D.new(); g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		g.albedo_color = Color(0.55, 0.62, 0.66, 0.18); g.roughness = 0.04; g.metallic_specular = 0.9
		g.cull_mode = BaseMaterial3D.CULL_DISABLED; g.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
		_mats["glass_clear"] = [g, 1.0]

## door leaves as their own nodes (the game will swing / slide them; visuals only for now): hinged at the jambs, a
## pair when the opening is wider than 1.3 m. "shop": aluminium stiles and rails, full glass, kick plate, push bars;
## "civic": painted wood, glass in the upper part, a panel below.
func _leaves(axis: String, plane: float, out: float, s0: float, s1: float, y0: float, y1: float, style: String) -> void:
	_ensure_glass()
	var w := s1 - s0; var n := 2 if w > 1.3 else 1
	var lw := w / n
	for i in n:
		var hinge := s0 if i == 0 else s1
		var dir := 1.0 if i == 0 else -1.0
		var node := Node3D.new(); node.name = "DoorLeaf_%d_%d" % [int(s0 * 100), i]
		var z := plane - out * 0.07
		node.position = Vector3(hinge, y0, z) if axis == "z" else Vector3(z, y0, hinge)
		node.set_meta(&"hinge_axis", axis); node.set_meta(&"swing", dir)
		var st := {}
		var h := y1 - y0
		var parts: Array = []
		if style == "civic":
			for side: float in [0.05, lw - 0.05]: parts.append(["door", Vector3(side, h * 0.5, 0), Vector3(0.1, h, 0.05)])
			parts.append(["door", Vector3(lw * 0.5, h - 0.06, 0), Vector3(lw, 0.12, 0.05)])
			parts.append(["door", Vector3(lw * 0.5, h * 0.22, 0), Vector3(lw - 0.1, h * 0.44, 0.045)])
			parts.append(["door", Vector3(lw * 0.5, h * 0.45, 0), Vector3(lw, 0.1, 0.05)])
			parts.append(["glass_clear", Vector3(lw * 0.5, h * 0.72, 0), Vector3(lw - 0.2, h * 0.5, 0.01)])
			parts.append(["frame_metal", Vector3(lw - 0.14, h * 0.48, 0.045), Vector3(0.03, 0.18, 0.03)])
		else:
			for side: float in [0.045, lw - 0.045]: parts.append(["frame_metal", Vector3(side, h * 0.5, 0), Vector3(0.09, h, 0.05)])
			parts.append(["frame_metal", Vector3(lw * 0.5, h - 0.05, 0), Vector3(lw, 0.1, 0.05)])
			parts.append(["frame_metal", Vector3(lw * 0.5, 0.12, 0), Vector3(lw, 0.24, 0.05)])       # kick plate
			parts.append(["glass_clear", Vector3(lw * 0.5, (0.24 + h - 0.1) * 0.5, 0), Vector3(lw - 0.18, h - 0.34, 0.01)])
			parts.append(["frame_metal", Vector3(lw * 0.5, 1.0, 0.06), Vector3(lw - 0.2, 0.035, 0.035)])   # push bars
			parts.append(["frame_metal", Vector3(lw * 0.5, 1.0, -0.06), Vector3(lw - 0.2, 0.035, 0.035)])
		for pt: Array in parts:
			var c: Vector3 = pt[1]; var sz: Vector3 = pt[2]
			var cc := Vector3(c.x * dir, c.y, c.z); var s2 := sz
			if axis == "x": cc = Vector3(c.z, c.y, c.x * dir); s2 = Vector3(sz.z, sz.y, sz.x)
			_leaf_box(st, String(pt[0]), cc, s2)
		var am := ArrayMesh.new()
		for m: String in st:
			var arr := []; arr.resize(Mesh.ARRAY_MAX)
			arr[Mesh.ARRAY_VERTEX] = PackedVector3Array(st[m][0]); arr[Mesh.ARRAY_NORMAL] = PackedVector3Array(st[m][1]); arr[Mesh.ARRAY_TEX_UV] = PackedVector2Array(st[m][2])
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr); am.surface_set_material(am.get_surface_count() - 1, _mats[m][0])
		var mi := MeshInstance3D.new(); mi.name = "leaf"; mi.mesh = am; node.add_child(mi)
		# hinged: turns about its jamb, swinging out of the room (door_swing.gd); the leaf's middle for the trigger
		node.set_script(SWING)
		var midl := Vector3(lw * 0.5 * dir, h * 0.5, 0) if axis == "z" else Vector3(0, h * 0.5, lw * 0.5 * dir)
		node.set_meta(&"mid", midl)
		# rotating +Y turns local +X toward -Z: for a leaf along +x (dir 1) on a wall facing out (+z, out = 1) the
		# outward swing is a negative angle; the sign flips with the leaf's direction, the wall side and the axis
		var sgn := -dir * out
		if axis == "x": sgn = dir * out
		node.set_meta(&"open_sign", sgn)
		node.set_meta(&"out_dir", Vector3(0, 0, out) if axis == "z" else Vector3(out, 0, 0))
		root.add_child(node)

## a box into a leaf's own surfaces (both windings: leaves are seen from both sides)
func _leaf_box(st: Dictionary, m: String, c: Vector3, size: Vector3) -> void:
	if not st.has(m): st[m] = [[], [], []]
	var h := size * 0.5
	var x0 := c.x - h.x; var x1 := c.x + h.x; var y0 := c.y - h.y; var y1 := c.y + h.y; var z0 := c.z - h.z; var z1 := c.z + h.z
	var faces: Array = [
		[Vector3(x1, y0, z0), Vector3(x1, y1, z0), Vector3(x1, y1, z1), Vector3(x1, y0, z1), Vector3.RIGHT],
		[Vector3(x0, y0, z0), Vector3(x0, y0, z1), Vector3(x0, y1, z1), Vector3(x0, y1, z0), Vector3.LEFT],
		[Vector3(x0, y1, z0), Vector3(x0, y1, z1), Vector3(x1, y1, z1), Vector3(x1, y1, z0), Vector3.UP],
		[Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector3(x1, y0, z1), Vector3(x0, y0, z1), Vector3.DOWN],
		[Vector3(x0, y0, z1), Vector3(x1, y0, z1), Vector3(x1, y1, z1), Vector3(x0, y1, z1), Vector3.BACK],
		[Vector3(x0, y0, z0), Vector3(x0, y1, z0), Vector3(x1, y1, z0), Vector3(x1, y0, z0), Vector3.FORWARD]]
	for q: Array in faces:
		for idx: Array in [[0, 1, 2, 0, 2, 3], [0, 2, 1, 0, 3, 2]]:
			for k: int in idx:
				var pv: Vector3 = q[k]
				(st[m][0] as Array).append(pv); (st[m][1] as Array).append(q[4]); (st[m][2] as Array).append(Vector2(pv.x + pv.z, pv.y))

## the four faces lining an opening from the room's inner wall face out to the facade plane (wall material)
func _reveal(axis: String, wall_at: float, plane: float, s0: float, s1: float, y0: float, y1: float) -> void:
	var t: float = _mats["wall"][1]
	var z0 := minf(wall_at, plane); var z1 := maxf(wall_at, plane)
	var P := func(s: float, y: float, z: float) -> Vector3: return Vector3(s, y, z) if axis == "z" else Vector3(z, y, s)
	var Nv := func(ns: float, ny: float) -> Vector3: return Vector3(ns, ny, 0) if axis == "z" else Vector3(0, ny, ns)
	# jamb at s0 faces +s, jamb at s1 faces -s, head faces down, sill faces up; both windings are emitted so the
	# reveal reads from the room and from the street whichever way the axis runs
	for f: Array in [[s0, 1.0], [s1, -1.0]]:
		var s := float(f[0])
		var A: Vector3 = P.call(s, y0, z0); var Bv: Vector3 = P.call(s, y0, z1); var C: Vector3 = P.call(s, y1, z1); var D2: Vector3 = P.call(s, y1, z0)
		_q("wall", A, Bv, C, D2, Nv.call(float(f[1]), 0.0), Vector2(z0, -y0) / t, Vector2(z1, -y0) / t, Vector2(z1, -y1) / t, Vector2(z0, -y1) / t)
		_q("wall", A, D2, C, Bv, Nv.call(float(f[1]), 0.0), Vector2(z0, -y0) / t, Vector2(z0, -y1) / t, Vector2(z1, -y1) / t, Vector2(z1, -y0) / t)
	for f2: Array in [[y1, -1.0], [y0, 1.0]]:
		var y := float(f2[0])
		var A2: Vector3 = P.call(s0, y, z0); var B2: Vector3 = P.call(s1, y, z0); var C2: Vector3 = P.call(s1, y, z1); var D3: Vector3 = P.call(s0, y, z1)
		_q("wall", A2, B2, C2, D3, Vector3(0, float(f2[1]), 0), Vector2(s0, z0) / t, Vector2(s1, z0) / t, Vector2(s1, z1) / t, Vector2(s0, z1) / t)
		_q("wall", A2, D3, C2, B2, Vector3(0, float(f2[1]), 0), Vector2(s0, z0) / t, Vector2(s0, z1) / t, Vector2(s1, z1) / t, Vector2(s1, z0) / t)

## find a kit indoor prop's near glb
static var _files := {}
static func indoor_file(base: String) -> String:
	if _files.is_empty():
		for d in DirAccess.get_directories_at(INDOOR):
			for f in DirAccess.get_files_at(INDOOR + d):
				if f.ends_with("_near.glb"): _files[f.get_slice("_clean_near", 0)] = INDOOR + d + "/" + f
	return _files.get(base, "")

func build() -> Node3D:
	# shell: one mesh, one surface per material
	var am := ArrayMesh.new()
	for k: String in _surf:
		var s: Array = _surf[k]
		var arr := []; arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = PackedVector3Array(s[0]); arr[Mesh.ARRAY_NORMAL] = PackedVector3Array(s[1]); arr[Mesh.ARRAY_TEX_UV] = PackedVector2Array(s[2])
		var st := SurfaceTool.new(); st.create_from_arrays(arr); st.generate_tangents()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
		am.surface_set_material(am.get_surface_count() - 1, _mats[k][0])
	var mi := MeshInstance3D.new(); mi.name = "shell"; mi.mesh = am
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	# props: one MultiMesh per kit prop
	var pn := Node3D.new(); pn.name = "Props"; root.add_child(pn)
	for base: String in _props:
		var f := indoor_file(base)
		if f == "": f = K.prop_file(base, "normal", "near")      # kit foliage / street props (potted plants ...)
		if f == "": push_warning("room: no indoor prop " + base); print("ROOM missing prop ", base); continue
		var inst: Node = (load(f) as PackedScene).instantiate()
		var src := K._first_mesh(inst)
		var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.mesh = src.mesh
		var ts: Array = _props[base]; mm.instance_count = ts.size()
		for i in ts.size(): mm.set_instance_transform(i, (ts[i] as Transform3D) * src.transform)
		var mmi := MultiMeshInstance3D.new(); mmi.name = base; mmi.multimesh = mm
		# the kit's prop shader (as the street props): applies the vertex colours the kit paints colour variants with
		# (the plant's leaf green, upholstery) and a light lived-in wear - the plain material drops them (leaves white)
		if src.mesh.get_surface_count() == 1:
			var wm: Material = K.prop_wear_mat(src.mesh.surface_get_material(0), PROP_WEAR)
			if wm != src.mesh.surface_get_material(0): mmi.material_override = wm
		pn.add_child(mmi); inst.free()
	var wm := dec.build()
	if wm: wm.name = "wear"; root.add_child(wm)
	root.set_meta(&"floors", _floors); root.set_meta(&"solids", _solids); root.set_meta(&"entrances", _doors); root.set_meta(&"cut", _cut); root.set_meta(&"openings", _openings)
	# the room is drawn exactly as long as its building shows the near tier (0-62 m, the tier with the openings cut);
	# past that the building's mid tier paints its windows shut again and the room is not needed. Lights fade out
	# over the last 12 m so nothing pops.
	for gi: GeometryInstance3D in root.find_children("*", "GeometryInstance3D", true, false):
		gi.visibility_range_end = NEAR_END; gi.visibility_range_end_margin = 2.0
	for l: Light3D in root.find_children("*", "Light3D", true, false):
		l.distance_fade_enabled = true; l.distance_fade_begin = NEAR_END - 12.0; l.distance_fade_length = 12.0
	var sm := _sign_mesh()
	if sm: root.add_child(sm)
	return root

## ------------------------------------------------------------------------------------------------- shop signs
## (Yasin 18 Nov: "many shops dont have their names written on the signs ... one of them says its a cinema but inside
## isnt a cinema") The kit paints fixed names into its models - every copy of a model repeats them (15 models say
## VILLAGE THEATRE, 8 say CROWN CAFE) - or leaves a blank dark board. A room names its own building: a plate over each
## board it claims, the board's rectangle from room_contracts.json "signs" (found in the mesh, never typed), the text
## the shop's. Text is drawn with the project's OFL fonts (ui/fonts) into one small atlas per room, Basis-compressed
## and embedded in the room scene. Plates draw to SIGN_END (a sign reads from down the street, past the room's range).
const SIGN_END := 160.0
## board, letters, border
const SIGN_STYLE := {"green": [Color(0.08, 0.2, 0.15), Color(0.94, 0.86, 0.6), Color(0.75, 0.63, 0.36)],
	"red": [Color(0.42, 0.07, 0.06), Color(0.98, 0.93, 0.8), Color(0.85, 0.75, 0.5)],
	"navy": [Color(0.07, 0.1, 0.22), Color(0.95, 0.95, 0.92), Color(0.7, 0.72, 0.78)],
	"black": [Color(0.05, 0.05, 0.05), Color(0.93, 0.78, 0.42), Color(0.7, 0.55, 0.28)],
	"teal": [Color(0.05, 0.36, 0.38), Color(0.98, 0.98, 0.95), Color(0.85, 0.92, 0.9)],
	"cream": [Color(0.93, 0.88, 0.76), Color(0.25, 0.14, 0.08), Color(0.42, 0.28, 0.16)],
	"sea": [Color(0.1, 0.42, 0.55), Color(1.0, 0.97, 0.88), Color(0.95, 0.85, 0.6)],
	"sun": [Color(0.98, 0.78, 0.2), Color(0.1, 0.18, 0.32), Color(0.1, 0.18, 0.32)]}
var _signs: Array = []      # [contract sign entry, text, style, font]
var _sign_imgs: Array = []  # rendered plate images, same order

## claim the building's sign board on <facade> at <along> (room_contracts.json "signs") and put <text> on it
func sign(contract: Dictionary, facade: String, along: float, text: String, style := "green", font := "Overpass") -> void:
	for e: Dictionary in contract.get("signs", []):
		if String(e.facade) == facade and absf(float(e.along) - along) < 0.15:
			_signs.append([e, text, style, font]); return
	push_error("room sign: no board on %s at %.2f" % [facade, along]); print("ROOM no sign board ", facade, " ", along)

## render every claimed plate's text (needs the real renderer: run the room script with --rendering-method mobile)
func make_signs(tree: SceneTree) -> void:
	if _signs.is_empty(): return
	var vps: Array = []
	for sg: Array in _signs:
		var e: Dictionary = sg[0]
		var w := float(e.w); var h := float(e.y1) - float(e.y0)
		var cw := clampi(int(w * 140.0) / 4 * 4, 128, 768); var ch := maxi(32, int(float(cw) * h / w) / 4 * 4)
		var st: Array = SIGN_STYLE.get(String(sg[2]), SIGN_STYLE.green)
		var vp := SubViewport.new(); vp.size = Vector2i(cw, ch); vp.transparent_bg = false; vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		var pnl := Panel.new(); pnl.size = Vector2(cw, ch)
		var sb := StyleBoxFlat.new(); sb.bg_color = st[0]; sb.border_color = st[2]; sb.set_border_width_all(maxi(2, ch / 14))
		pnl.add_theme_stylebox_override("panel", sb); vp.add_child(pnl)
		var ff := FontFile.new(); ff.load_dynamic_font(ProjectSettings.globalize_path("res://ui/fonts/%s.ttf" % String(sg[3])))
		var fv := FontVariation.new(); fv.base_font = ff; fv.variation_embolden = 0.7
		var fs := int(ch * 0.6)
		while fs > 8 and ff.get_string_size(String(sg[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x * 1.06 > cw * 0.86: fs -= 1
		var lb := Label.new(); lb.text = String(sg[1]); lb.size = Vector2(cw, ch)
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var ls := LabelSettings.new(); ls.font = fv; ls.font_size = fs; ls.font_color = st[1]
		ls.shadow_color = Color(0, 0, 0, 0.35); ls.shadow_offset = Vector2(1, 1); ls.shadow_size = 1
		lb.label_settings = ls; vp.add_child(lb)
		tree.root.add_child(vp); vps.append(vp)
	for i in 4: await tree.process_frame
	await RenderingServer.frame_post_draw
	_sign_imgs.clear()
	for vp2: SubViewport in vps:
		var im := vp2.get_texture().get_image(); im.convert(Image.FORMAT_RGB8); _sign_imgs.append(im)
		vp2.queue_free()

func _sign_mesh() -> MeshInstance3D:
	if _sign_imgs.size() != _signs.size() or _signs.is_empty(): return null
	var aw := 0; var ah := 0
	for im: Image in _sign_imgs: aw = maxi(aw, im.get_width()); ah += im.get_height()
	ah = (ah + 3) / 4 * 4
	var atlas := Image.create(aw, ah, false, Image.FORMAT_RGB8)
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var y := 0
	for i in _signs.size():
		var im: Image = _sign_imgs[i]; var e: Dictionary = _signs[i][0]
		atlas.blit_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(0, y))
		var u0 := 0.5 / aw; var u1 := (float(im.get_width()) - 0.5) / aw; var v0 := (y + 0.5) / float(ah); var v1 := (y + im.get_height() - 0.5) / float(ah)
		y += im.get_height()
		var f := String(e.facade)
		var n := Vector3(0, 0, 1) if f == "front" else (Vector3(0, 0, -1) if f == "back" else (Vector3(1, 0, 0) if f == "right" else Vector3(-1, 0, 0)))
		var rt := (-n).cross(Vector3.UP)                     # the viewer's right, looking at the facade
		var along_x := f == "front" or f == "back"
		var pl := float(e.plane); var al := float(e.along)
		var c := Vector3(al if along_x else pl, (float(e.y0) + float(e.y1)) * 0.5, pl if along_x else al) + n * 0.02
		var hw := float(e.w) * 0.5 + 0.01; var hh := (float(e.y1) - float(e.y0)) * 0.5 + 0.01
		var tl := c - rt * hw + Vector3.UP * hh; var tr := c + rt * hw + Vector3.UP * hh
		var br := c + rt * hw - Vector3.UP * hh; var bl := c - rt * hw - Vector3.UP * hh
		for q: Array in [[tl, Vector2(u0, v0)], [tr, Vector2(u1, v0)], [br, Vector2(u1, v1)], [tl, Vector2(u0, v0)], [br, Vector2(u1, v1)], [bl, Vector2(u0, v1)]]:
			st.set_normal(n); st.set_uv(q[1]); st.add_vertex(q[0])
	atlas.generate_mipmaps()
	# keep the compressed data on the resource, or the saved scene holds an empty texture (pink plates, 18 Nov)
	var tex := PortableCompressedTexture2D.new(); tex.keep_compressed_buffer = true
	tex.create_from_image(atlas, PortableCompressedTexture2D.COMPRESSION_MODE_BASIS_UNIVERSAL)
	var m := StandardMaterial3D.new(); m.albedo_texture = tex; m.roughness = 0.7
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var mi := MeshInstance3D.new(); mi.name = "Signs"; mi.mesh = st.commit(); mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = SIGN_END; mi.visibility_range_end_margin = 5.0
	return mi

func save(name: String) -> String:
	var dir := "res://map_dc/coronado/city_kit/interiors/rooms/"
	K._own(root, root)
	var ps := PackedScene.new(); ps.pack(root)
	var p := dir + name + ".scn"
	var err := ResourceSaver.save(ps, p, ResourceSaver.FLAG_COMPRESS)
	print("ROOM %s saved (%s)" % [p, error_string(err)])
	return p
