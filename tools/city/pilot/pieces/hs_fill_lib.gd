extends RefCounted
## High street fill (claude/fill-high-street, 19 Nov): small drawing helpers for the n_hs_* pieces. They draw what a
## piece script tells them to and decide nothing (no "a bench every N m", no fill loops, no seeds): every building and
## prop is listed by hand in its piece script with its reason. Copied / adapted from the pilot's block_lib, res_block and
## b_sw (the pilot files stay as they are; locked pieces were built with them).
##  - cells snap to one global grid (2 m), so two pieces that meet on a line share the same vertices there (no T-joint,
##    no crack, the same height on both sides)
##  - faces ("wall") wherever two surfaces meet at different heights: a retaining wall on every step, seen both ways
##  - fences with a post at EVERY panel joint (Yasin: "a fence post at every joint"), panels never stretched

const K := preload("res://tools/city/pilot/kit_lib.gd")
const STEP := 2.0

static func _lines(a: float, b: float, step: float, extra: Array = []) -> Array:
	var s := {a: true, b: true}
	var k := ceili(a / step - 1e-6)
	while float(k) * step < b - 1e-6:
		var x := float(k) * step
		if x > a + 1e-6: s[x] = true
		k += 1
	for e: float in extra:
		if e > a + 1e-6 and e < b - 1e-6: s[e] = true
	var out: Array = s.keys(); out.sort()
	return out

## A rectangle [x0,x1] x [z0,z1] of ground cut on the global grid and on every paint edge; each cell takes the first
## paint [x0, z0, x1, z1, mat] containing its centre (mat "-" leaves a hole), else `base`. Heights from yfn (local).
static func paint(g: K.Ground, x0: float, z0: float, x1: float, z1: float, paints: Array, base: String, yfn: Callable, step := STEP) -> void:
	var ex: Array = []; var ez: Array = []
	for p: Array in paints: ex.append_array([float(p[0]), float(p[2])]); ez.append_array([float(p[1]), float(p[3])])
	var xs := _lines(x0, x1, step, ex); var zs := _lines(z0, z1, step, ez)
	for i in xs.size() - 1:
		for j in zs.size() - 1:
			var xa: float = xs[i]; var xb: float = xs[i + 1]; var za: float = zs[j]; var zb: float = zs[j + 1]
			var cx := (xa + xb) * 0.5; var cz := (za + zb) * 0.5
			var m := base
			for p: Array in paints:
				if cx > float(p[0]) and cx < float(p[2]) and cz > float(p[1]) and cz < float(p[3]): m = String(p[4]); break
			if m == "-": continue
			g.quad(m, Vector3(xa, yfn.call(xa, za), za), Vector3(xb, yfn.call(xb, za), za), Vector3(xb, yfn.call(xb, zb), zb), Vector3(xa, yfn.call(xa, zb), zb))

## Ground between a curved / slanted edge and a straight line: columns on the global grid in x, from zlo(x) to zhi(x)
## (both Callables of x). Rows on the global grid where the column is wide enough, trapezoids at the curved ends.
static func band(g: K.Ground, mat: String, x0: float, x1: float, zlo: Callable, zhi: Callable, yfn: Callable, step := STEP, xextra: Array = []) -> void:
	var xs := _lines(x0, x1, step, xextra)
	for i in xs.size() - 1:
		var xa: float = xs[i]; var xb: float = xs[i + 1]
		var la: float = zlo.call(xa); var lb: float = zlo.call(xb); var ha: float = zhi.call(xa); var hb: float = zhi.call(xb)
		var inner := _lines(maxf(la, lb), minf(ha, hb), step)
		inner.pop_front(); inner.pop_back()
		var rows_a: Array = [la]; var rows_b: Array = [lb]
		for z: float in inner: rows_a.append(z); rows_b.append(z)
		rows_a.append(ha); rows_b.append(hb)
		for r in rows_a.size() - 1:
			var p0 := Vector3(xa, yfn.call(xa, rows_a[r]), rows_a[r]); var p1 := Vector3(xb, yfn.call(xb, rows_b[r]), rows_b[r])
			var p2 := Vector3(xb, yfn.call(xb, rows_b[r + 1]), rows_b[r + 1]); var p3 := Vector3(xa, yfn.call(xa, rows_a[r + 1]), rows_a[r + 1])
			g.quad(mat, p0, p1, p2, p3)

## paint() between two edge lines zlo(x) .. zhi(x) (Callables): columns and rows on the global grid, the first / last
## row of each column a trapezoid to the edge; each cell takes the first paint containing its centre ("-" = hole).
static func paint_band(g: K.Ground, x0: float, x1: float, zlo: Callable, zhi: Callable, paints: Array, base: String, yfn: Callable, step := STEP) -> void:
	var ex: Array = []; var ez: Array = []
	for p: Array in paints: ex.append_array([float(p[0]), float(p[2])]); ez.append_array([float(p[1]), float(p[3])])
	var xs := _lines(x0, x1, step, ex)
	for i in xs.size() - 1:
		var xa: float = xs[i]; var xb: float = xs[i + 1]
		var la: float = zlo.call(xa); var lb: float = zlo.call(xb); var ha: float = zhi.call(xa); var hb: float = zhi.call(xb)
		var inner := _lines(maxf(la, lb), minf(ha, hb), step, ez)
		inner.pop_front(); inner.pop_back()
		var ra: Array = [la]; var rb: Array = [lb]
		for z: float in inner: ra.append(z); rb.append(z)
		ra.append(ha); rb.append(hb)
		for r in ra.size() - 1:
			var cx := (xa + xb) * 0.5; var cz := (float(ra[r]) + float(ra[r + 1]) + float(rb[r]) + float(rb[r + 1])) * 0.25
			var m := base
			for p: Array in paints:
				if cx > float(p[0]) and cx < float(p[2]) and cz > float(p[1]) and cz < float(p[3]): m = String(p[4]); break
			if m == "-": continue
			g.quad(m, Vector3(xa, yfn.call(xa, ra[r]), ra[r]), Vector3(xb, yfn.call(xb, rb[r]), rb[r]), Vector3(xb, yfn.call(xb, rb[r + 1]), rb[r + 1]), Vector3(xa, yfn.call(xa, ra[r + 1]), ra[r + 1]))

## Faces along the line a-b between two surfaces (heights from ya and yb at each point), cut every `seg` metres, both
## sides drawn. Nothing where the two agree within 1 cm.
static func step_face(g: K.Ground, a: Vector2, b: Vector2, ya: Callable, yb: Callable, mat := "wall", seg := 1.0) -> void:
	var n := maxi(1, ceili(a.distance_to(b) / seg))
	var nrm := Vector3(b.y - a.y, 0.0, -(b.x - a.x))
	for k in n:
		var p := a.lerp(b, float(k) / n); var q := a.lerp(b, float(k + 1) / n)
		var p0: float = ya.call(p.x, p.y); var p1: float = yb.call(p.x, p.y); var q0: float = ya.call(q.x, q.y); var q1: float = yb.call(q.x, q.y)
		if absf(p0 - p1) < 0.01 and absf(q0 - q1) < 0.01: continue
		var A0 := Vector3(p.x, minf(p0, p1), p.y); var A1 := Vector3(p.x, maxf(p0, p1), p.y)
		var B0 := Vector3(q.x, minf(q0, q1), q.y); var B1 := Vector3(q.x, maxf(q0, q1), q.y)
		g.quad(mat, A0, B0, B1, A1, nrm, true)
		g.quad(mat, A0, B0, B1, A1, -nrm, true)

## A skirt under a piece's outer edge: from the ground down to `bot` (Callable or the ground minus 0.35 m), so any
## gap to the land or a lower neighbour shows a face, never the underside (super-builder skill, ground-and-land).
static func skirt(g: K.Ground, a: Vector2, b: Vector2, ytop: Callable, mat: String, bot: Variant = null) -> void:
	var yb: Callable = bot if bot is Callable else func(x: float, z: float) -> float: return float(ytop.call(x, z)) - 0.35
	step_face(g, a, b, ytop, yb, mat, STEP)

## Fence run from a to b that ENDS EXACTLY at a and b: n = the fewest kit panels that cover it, each shortened a
## little to L / n (never stretched; check_life reads the shortened length from the transform), a post at EVERY joint.
## gaps: [[distance along the run from a, width]]: the panel whose middle falls in a gap is left out (a gate goes there).
static func fence(props: K.Props, panel: String, post: String, a: Vector2, b: Vector2, y: Callable, pl: float, cond := "worn", gaps: Array = []) -> Array:
	var L := a.distance_to(b); var n := maxi(1, ceili(L / pl - 0.02))
	var d := (b - a).normalized(); var seg := L / n
	for i in n:
		var t0 := seg * i; var t1 := seg * (i + 1)
		var skip := false
		for gp: Array in gaps:
			if absf((t0 + t1) * 0.5 - float(gp[0])) < float(gp[1]) * 0.5: skip = true
		if skip: continue
		short_panel(props, panel, a + d * t0, a + d * t1, y, pl, cond)
	if post != "":
		var yaw := rad_to_deg(atan2(d.x, d.y))
		for i in n + 1:
			var p := a + d * seg * i
			props.add(post, cond, Vector3(p.x, float(y.call(p.x, p.y)) - 0.02, p.y), yaw)
	return [a, b]

## One fence panel SHORTENED along its length to `length` (never stretched; check_life reads the shortened length from
## the transform), centred between a and b, standing at the lower ground of its two ends.
static func short_panel(props: K.Props, panel: String, a: Vector2, b: Vector2, y: Callable, pl: float, cond := "worn") -> void:
	var L := a.distance_to(b); var s := minf(1.0, L / pl)
	var d := (b - a).normalized(); var m := (a + b) * 0.5
	var yaw := rad_to_deg(atan2(d.x, d.y)) + 90.0
	var fy := minf(float(y.call(a.x, a.y)), float(y.call(b.x, b.y))) - 0.02
	var bs := Basis(Vector3.UP, deg_to_rad(yaw)) * Basis.from_scale(Vector3(s, 1.0, 1.0))
	var k := panel + "|" + cond
	if not props.items.has(k): props.items[k] = []
	props.items[k].append(Transform3D(bs, Vector3(m.x, fy, m.y)))
	props.col_items.append([panel, cond, Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), Vector3(m.x, fy, m.y))])

## Hedge panels (2 m) from a to b, whole panels only, centred
static func hedge(props: K.Props, a: Vector2, b: Vector2, y: Callable, kind := "hedge_boxwood_low_2m") -> void:
	var L := a.distance_to(b); var n := maxi(1, int(floor(L / 2.0 + 0.02)))
	var d := (b - a).normalized(); var a2 := a + d * (L - 2.0 * n) * 0.5
	var yaw := rad_to_deg(atan2(d.x, d.y)) + 90.0
	for i in n:
		var m := a2 + d * (2.0 * i + 1.0)
		props.add(kind, "normal", Vector3(m.x, float(y.call(m.x, m.y)), m.y), yaw)

## one prop standing on the ground at (x, z)
static func put(props: K.Props, base: String, cond: String, x: float, z: float, y: Callable, yaw := 0.0, collide := true, scale := 1.0) -> void:
	props.add(base, cond, Vector3(x, float(y.call(x, z)), z), yaw, collide, scale)

## Front steps up / down a retaining face across a path: treads 0.3 m, risers <= 0.17 m (res_block's rule).
## The path runs from the low side at z0 toward z1 (sign gives the direction); width w; centred at x.
static func steps_z(g: K.Ground, x: float, w: float, z0: float, z1: float, y0: float, y1: float) -> float:
	var dh := y1 - y0
	var dz := signf(z1 - z0) * 0.3
	if absf(dh) < 0.03:     # level path: one flat 0.3 m slab where a step would be
		g.quad("concrete", Vector3(x - w * 0.5, y1, z0), Vector3(x + w * 0.5, y1, z0), Vector3(x + w * 0.5, y1, z0 + dz), Vector3(x - w * 0.5, y1, z0 + dz))
		return z0 + dz
	var n := ceili(absf(dh) / 0.17)
	for k in n:
		var ya := y0 + dh * float(k) / n; var yb := y0 + dh * float(k + 1) / n
		var za := z0 + dz * k; var zb := z0 + dz * (k + 1)
		g.quad("concrete", Vector3(x - w * 0.5, yb, za), Vector3(x + w * 0.5, yb, za), Vector3(x + w * 0.5, yb, zb), Vector3(x - w * 0.5, yb, zb))
		step_face(g, Vector2(x - w * 0.5, za), Vector2(x + w * 0.5, za), func(_x: float, _z: float) -> float: return ya, func(_x: float, _z: float) -> float: return yb, "concrete")
		for ex: float in [x - w * 0.5, x + w * 0.5]:
			step_face(g, Vector2(ex, za), Vector2(ex, zb), func(_x: float, _z: float) -> float: return yb, func(_x: float, _z: float) -> float: return y1, "wall")
	return z0 + dz * n

## A level pad (a building's or a play area's) in a sloping field: the rect at height y, and a retaining face on each
## of its four edges down / up to the field around it (only where they differ by more than 1 cm). The caller leaves a
## "-" hole for the rect in its field paint. sides: which edges get a face (an edge against another pad or a ramp is
## drawn by that one).
static func level_pad(g: K.Ground, mat: String, x0: float, z0: float, x1: float, z1: float, y: float, field: Callable, sides := "nesw", step := STEP) -> void:
	var yl := func(_x: float, _z: float) -> float: return y
	paint(g, x0, z0, x1, z1, [], mat, yl, step)
	if sides.contains("n"): step_face(g, Vector2(x0, z0), Vector2(x1, z0), yl, field)
	if sides.contains("s"): step_face(g, Vector2(x0, z1), Vector2(x1, z1), yl, field)
	if sides.contains("w"): step_face(g, Vector2(x0, z0), Vector2(x0, z1), yl, field)
	if sides.contains("e"): step_face(g, Vector2(x1, z0), Vector2(x1, z1), yl, field)

## A driveway ramp across [x0, x1] (x = the direction cars drive) from the field at x0 to height y at x1, over the
## rows z0..z1; side faces where it stands proud of or sinks into the field.
static func ramp_x(g: K.Ground, mat: String, x0: float, x1: float, z0: float, z1: float, y: float, field: Callable) -> void:
	var yr := func(x: float, z: float) -> float: return lerpf(float(field.call(x0, z)), y, (x - x0) / (x1 - x0))
	paint(g, minf(x0, x1), z0, maxf(x0, x1), z1, [], mat, yr, 1.0)
	step_face(g, Vector2(minf(x0, x1), z0), Vector2(maxf(x0, x1), z0), yr, field)
	step_face(g, Vector2(minf(x0, x1), z1), Vector2(maxf(x0, x1), z1), yr, field)

## save: ground mesh + its collision, decals, props (same as block_lib.finish, with this piece's own ground)
static func finish(root: Node3D, g: K.Ground, props: K.Props, dec: K.Decals, name: String) -> void:
	if dec:
		var wm := dec.build()
		if wm: root.add_child(wm)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"
	var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	if props.count() > 0: props.build(root, K)
	print("%s: ground tris %d, props %d, buildings %d" % [name, g.tri_count(), props.count(), root.get_node("Buildings").get_child_count() if root.has_node("Buildings") else 0])
	K.save_piece(root, name)
