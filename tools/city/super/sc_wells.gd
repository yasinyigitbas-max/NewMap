extends RefCounted
## Superchecker: paving over a tree well whose tree was taken out (Yasin, 19 Nov: "the checker should remove all of the
## trees in the area and fill the wells with the material surrounding it").
## The two functions below are the runtime bake's own well filler (tools/city/bake/bake_runtime.gd, _fill_wells and
## _lift_wells, written and tried there on 19 Nov), copied here without its cache and counters so that the fixer can do
## the same to ONE well of a saved piece. A well = soil ("mulch") triangles that all lie within 1 m of a trunk, with the
## trunk near their middle, whose edge vertices have a hard, up-facing vertex right above them (the rim, 2-15 cm up).
## The soil's triangles are lifted to the rim's plane and join the rim's surface (its material, its texture mapping);
## the rim's inner face goes. A trunk in a bed or on grass matches none of that and nothing changes there.
## Returns [mesh, [[centre on the rim plane, radius, slope x, slope z], ...]].

static func _k3(p: Vector3) -> Vector3i: return Vector3i(roundi(p.x * 1000.0), roundi(p.y * 1000.0), roundi(p.z * 1000.0))

static func fill_wells(gm: Mesh, trees: Array) -> Array:
	if not (gm is ArrayMesh): return [gm, []]
	var ns := gm.get_surface_count(); var soil := -1
	for si in ns:
		var sm := gm.surface_get_material(si) as BaseMaterial3D
		if gm.surface_get_name(si) == "mulch" or (sm and sm.albedo_texture and sm.albedo_texture.resource_path.contains("ground037")): soil = si
	if soil < 0: return [gm, []]
	var arrs: Array = []; var idx: Array = []
	for si in ns:
		var a: Array = gm.surface_get_arrays(si); arrs.append(a)
		var ix := PackedInt32Array()
		if a[Mesh.ARRAY_INDEX] != null: ix = a[Mesh.ARRAY_INDEX]
		if ix.is_empty():
			ix.resize((a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
			for q in ix.size(): ix[q] = q
		idx.append(ix)
	# the 2 m squares round the trunks: everything else of the mesh is skipped with one lookup
	var near := {}
	for t2: Vector3 in trees:
		for dx in range(-1, 2):
			for dz in range(-1, 2): near[Vector2i(floori(t2.x / 2.0) + dx, floori(t2.z / 2.0) + dz)] = true
	# soil triangles near a trunk, by 2 m square
	var SV: PackedVector3Array = arrs[soil][Mesh.ARRAY_VERTEX]; var SI: PackedInt32Array = idx[soil]
	var sgrid := {}
	for t3 in SI.size() / 3:
		var c3: Vector3 = (SV[SI[t3 * 3]] + SV[SI[t3 * 3 + 1]] + SV[SI[t3 * 3 + 2]]) / 3.0
		var k3 := Vector2i(floori(c3.x / 2.0), floori(c3.z / 2.0))
		if not near.has(k3): continue
		if not sgrid.has(k3): sgrid[k3] = []
		(sgrid[k3] as Array).append(t3)
	if sgrid.is_empty(): return [gm, []]
	# hard, up-facing vertices near a trunk: 2 mm buckets of x, z -> [surface, vertex]
	var hard := {}
	for si in ns:
		if si == soil: continue
		var HV: PackedVector3Array = arrs[si][Mesh.ARRAY_VERTEX]; var HN: PackedVector3Array = arrs[si][Mesh.ARRAY_NORMAL]
		for v in HV.size():
			var hp: Vector3 = HV[v]
			if not near.has(Vector2i(floori(hp.x / 2.0), floori(hp.z / 2.0))) or HN[v].y < 0.7: continue
			var kh := Vector2i(roundi(hp.x * 500.0), roundi(hp.z * 500.0))
			if not hard.has(kh): hard[kh] = []
			(hard[kh] as Array).append([si, v])
	var gone := {}                # soil triangles that become paving
	var add: Array = []           # [dst surface, twin vertex (attributes to copy), [3 positions], [3 uvs], normal]
	var wells: Array = []
	for t4: Vector3 in trees:
		var cand: Array = []; var bed := false
		var kt := Vector2i(floori(t4.x / 2.0), floori(t4.z / 2.0))
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				var kk := kt + Vector2i(dx, dz)
				if not sgrid.has(kk): continue
				for ti: int in sgrid[kk]:
					if gone.has(ti): continue
					var inside := 0
					for e in 3:
						var pv: Vector3 = SV[SI[ti * 3 + e]]
						if Vector2(pv.x - t4.x, pv.z - t4.z).length_squared() <= 1.0: inside += 1
					if inside == 3: cand.append(ti)
					elif inside > 0: bed = true
		if cand.is_empty(): continue                       # the trunk stands in grass, gravel or a big bed
		if bed: continue
		# every soil vertex of the patch and the rim vertex above it
		var tw: Array = []; var free: Array = []          # [soil position, surface, vertex] / soil positions without one
		var seen := {}
		for ti2: int in cand:
			for e2 in 3:
				var sp: Vector3 = SV[SI[ti2 * 3 + e2]]
				var ks := _k3(sp)
				if seen.has(ks): continue
				seen[ks] = true
				var best: Array = []; var by := 1.0e9
				var kb := Vector2i(roundi(sp.x * 500.0), roundi(sp.z * 500.0))
				for bx in range(-1, 2):
					for bz in range(-1, 2):
						var kq := kb + Vector2i(bx, bz)
						if not hard.has(kq): continue
						for hv: Array in hard[kq]:
							var q3: Vector3 = (arrs[int(hv[0])][Mesh.ARRAY_VERTEX] as PackedVector3Array)[int(hv[1])]
							if absf(q3.x - sp.x) > 0.002 or absf(q3.z - sp.z) > 0.002: continue
							var up := q3.y - sp.y
							if up > 0.02 and up < 0.15 and up < by: by = up; best = hv
				if best.is_empty(): free.append(sp)
				else: tw.append([sp, int(best[0]), int(best[1])])
		if tw.size() < 3: continue
		# the rim plane (least squares over the rim vertices) and the well's centre and radius
		var cen := Vector3.ZERO; var votes := {}
		for w: Array in tw:
			cen += (arrs[int(w[1])][Mesh.ARRAY_VERTEX] as PackedVector3Array)[int(w[2])]
			votes[int(w[1])] = int(votes.get(int(w[1]), 0)) + 1
		cen /= float(tw.size())
		var dst := -1; var dn := 0
		for vs: int in votes:
			if int(votes[vs]) > dn: dn = int(votes[vs]); dst = vs
		var sxx := 0.0; var sxz := 0.0; var szz := 0.0; var sxy := 0.0; var szy := 0.0; var rad := 0.0
		for w2: Array in tw:
			var rp: Vector3 = (arrs[int(w2[1])][Mesh.ARRAY_VERTEX] as PackedVector3Array)[int(w2[2])] - cen
			sxx += rp.x * rp.x; sxz += rp.x * rp.z; szz += rp.z * rp.z; sxy += rp.x * rp.y; szy += rp.z * rp.y
			rad = maxf(rad, Vector2(rp.x, rp.z).length())
		var det := sxx * szz - sxz * sxz
		var gx := 0.0; var gz := 0.0
		if absf(det) > 1.0e-6: gx = (sxy * szz - szy * sxz) / det; gz = (szy * sxx - sxy * sxz) / det
		var ok := Vector2(t4.x - cen.x, t4.z - cen.z).length() < 0.5 and rad < 1.2
		for fp: Vector3 in free:
			if Vector2(fp.x - cen.x, fp.z - cen.z).length() > rad * 0.6: ok = false      # an edge vertex with no rim over it
		# the rim surface's texture mapping over the well (u and v are planes over x, z)
		var DV: PackedVector3Array = arrs[dst][Mesh.ARRAY_VERTEX]
		var DU := PackedVector2Array()
		if arrs[dst][Mesh.ARRAY_TEX_UV] != null: DU = arrs[dst][Mesh.ARRAY_TEX_UV]
		var ucen := Vector2.ZERO; var dcen := Vector3.ZERO; var un := 0; var twin_v := -1
		if not DU.is_empty():
			for w3: Array in tw:
				if int(w3[1]) != dst: continue
				ucen += DU[int(w3[2])]; dcen += DV[int(w3[2])]; un += 1; twin_v = int(w3[2])
		if un < 3: ok = false
		if not ok: continue
		ucen /= float(un); dcen /= float(un)
		var uxx := 0.0; var uxz := 0.0; var uzz := 0.0; var uxu := 0.0; var uzu := 0.0; var uxv := 0.0; var uzv := 0.0
		for w5: Array in tw:
			if int(w5[1]) != dst: continue
			var dp: Vector3 = DV[int(w5[2])] - dcen; var du: Vector2 = DU[int(w5[2])] - ucen
			uxx += dp.x * dp.x; uxz += dp.x * dp.z; uzz += dp.z * dp.z
			uxu += dp.x * du.x; uzu += dp.z * du.x; uxv += dp.x * du.y; uzv += dp.z * du.y
		var udet := uxx * uzz - uxz * uxz
		if absf(udet) < 1.0e-6: continue
		var ua := Vector2((uxu * uzz - uzu * uxz) / udet, (uzu * uxx - uxu * uxz) / udet)      # d u / d x, d u / d z
		var va := Vector2((uxv * uzz - uzv * uxz) / udet, (uzv * uxx - uxv * uxz) / udet)
		var top := {}                 # soil position -> its rim position
		for w6: Array in tw:
			top[_k3(w6[0] as Vector3)] = (arrs[int(w6[1])][Mesh.ARRAY_VERTEX] as PackedVector3Array)[int(w6[2])]
		var nrm := Vector3(-gx, 1.0, -gz).normalized()
		for ti3: int in cand:
			gone[ti3] = true
			var ps: Array = []; var us: Array = []
			for e3 in 3:
				var s7: Vector3 = SV[SI[ti3 * 3 + e3]]
				var k7 := _k3(s7)
				var np := Vector3(s7.x, cen.y + gx * (s7.x - cen.x) + gz * (s7.z - cen.z), s7.z)
				if top.has(k7): np = top[k7]
				ps.append(np)
				us.append(ucen + Vector2(ua.x * (np.x - dcen.x) + ua.y * (np.z - dcen.z), va.x * (np.x - dcen.x) + va.y * (np.z - dcen.z)))
			add.append([dst, twin_v, ps, us, nrm])
		wells.append([cen, rad, gx, gz])
	if wells.is_empty(): return [gm, []]
	# the soil loses the wells' triangles
	var keep_i := PackedInt32Array()
	for t5 in SI.size() / 3:
		if gone.has(t5): continue
		keep_i.append(SI[t5 * 3]); keep_i.append(SI[t5 * 3 + 1]); keep_i.append(SI[t5 * 3 + 2])
	idx[soil] = keep_i
	# the rim's inner face goes: upright triangles wholly inside a filled well
	var wgrid := {}
	for wi in wells.size():
		var wc: Vector3 = wells[wi][0]
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				var kw := Vector2i(floori(wc.x / 2.0) + dx, floori(wc.z / 2.0) + dz)
				if not wgrid.has(kw): wgrid[kw] = []
				(wgrid[kw] as Array).append(wi)
	for si in ns:
		if si == soil: continue
		var RV: PackedVector3Array = arrs[si][Mesh.ARRAY_VERTEX]; var RI: PackedInt32Array = idx[si]
		var out_i := PackedInt32Array(); var cut := 0
		for t6 in RI.size() / 3:
			var a6: Vector3 = RV[RI[t6 * 3]]; var b6: Vector3 = RV[RI[t6 * 3 + 1]]; var c6: Vector3 = RV[RI[t6 * 3 + 2]]
			var drop := false
			var k6 := Vector2i(floori(a6.x / 2.0), floori(a6.z / 2.0))
			if wgrid.has(k6):
				var n6 := (b6 - a6).cross(c6 - a6)
				if n6.length_squared() > 1.0e-12 and absf(n6.normalized().y) < 0.3:
					for wi2: int in wgrid[k6]:
						var wc2: Vector3 = wells[wi2][0]; var wr := float(wells[wi2][1]) + 0.004
						var all_in := true
						for q6: Vector3 in [a6, b6, c6]:
							if Vector2(q6.x - wc2.x, q6.z - wc2.z).length() > wr or q6.y > wc2.y + 0.1 or q6.y < wc2.y - 0.25: all_in = false
						if all_in: drop = true
			if drop: cut += 1; continue
			out_i.append(RI[t6 * 3]); out_i.append(RI[t6 * 3 + 1]); out_i.append(RI[t6 * 3 + 2])
		if cut > 0: idx[si] = out_i
	# the new paving: added to the rim's surface, every other attribute copied from a rim vertex
	for ad: Array in add:
		var d := int(ad[0]); var tv := int(ad[1]); var da: Array = arrs[d]
		var base := (da[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		for e4 in 3:
			for at in Mesh.ARRAY_MAX:
				if da[at] == null or at == Mesh.ARRAY_INDEX: continue
				if at == Mesh.ARRAY_VERTEX:
					var av: PackedVector3Array = da[at]; av.append((ad[2] as Array)[e4]); da[at] = av
				elif at == Mesh.ARRAY_NORMAL:
					var an: PackedVector3Array = da[at]; an.append(ad[4]); da[at] = an
				elif at == Mesh.ARRAY_TEX_UV:
					var au: PackedVector2Array = da[at]; au.append((ad[3] as Array)[e4]); da[at] = au
				elif at == Mesh.ARRAY_TANGENT:
					var atn: PackedFloat32Array = da[at]
					for q7 in 4: atn.append(atn[tv * 4 + q7])
					da[at] = atn
				elif at == Mesh.ARRAY_COLOR:
					var ac: PackedColorArray = da[at]; ac.append(ac[tv]); da[at] = ac
				elif at == Mesh.ARRAY_TEX_UV2:
					var a2: PackedVector2Array = da[at]; a2.append(a2[tv]); da[at] = a2
		var di: PackedInt32Array = idx[d]; di.append(base); di.append(base + 1); di.append(base + 2); idx[d] = di
	var nm := ArrayMesh.new()
	for si in ns:
		if (idx[si] as PackedInt32Array).is_empty(): continue
		var oa: Array = arrs[si]; oa[Mesh.ARRAY_INDEX] = idx[si]
		nm.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, oa)
		nm.surface_set_material(nm.get_surface_count() - 1, gm.surface_get_material(si))
		nm.surface_set_name(nm.get_surface_count() - 1, gm.surface_get_name(si))
	return [nm, wells]

## the ground collision under filled wells: the soil lifted to the rim plane, the rim's face gone.
## wells: [[centre on the rim plane, radius, slope x, slope z], ...] in the shape's own frame
static func lift_faces(s: ConcavePolygonShape3D, wells: Array) -> ConcavePolygonShape3D:
	var wl: Array = []; var grid := {}
	for w: Array in wells:
		var c: Vector3 = w[0]
		var r := float(w[1]) + 0.004
		for gx in range(floori((c.x - r) / 2.0), floori((c.x + r) / 2.0) + 1):
			for gz in range(floori((c.z - r) / 2.0), floori((c.z + r) / 2.0) + 1):
				var k := Vector2i(gx, gz)
				if not grid.has(k): grid[k] = []
				(grid[k] as Array).append(wl.size())
		wl.append([c, r * r, float(w[2]), float(w[3])])
	var f := s.get_faces(); var o := PackedVector3Array(); var moved := 0
	for t in f.size() / 3:
		var tri: Array = [f[t * 3], f[t * 3 + 1], f[t * 3 + 2]]; var hit := false
		for e in 3:
			var p: Vector3 = tri[e]
			var kp := Vector2i(floori(p.x / 2.0), floori(p.z / 2.0))
			if not grid.has(kp): continue
			for wi: int in grid[kp]:
				var wc: Vector3 = wl[wi][0]
				var dx := p.x - wc.x; var dz := p.z - wc.z
				if dx * dx + dz * dz > float(wl[wi][1]): continue
				var py := wc.y + float(wl[wi][2]) * dx + float(wl[wi][3]) * dz
				if p.y < py - 0.005 and p.y > py - 0.25: tri[e] = Vector3(p.x, py, p.z); hit = true
		if hit:
			moved += 1
			if ((tri[1] as Vector3) - (tri[0] as Vector3)).cross((tri[2] as Vector3) - (tri[0] as Vector3)).length_squared() < 1.0e-10: continue
		o.append(tri[0]); o.append(tri[1]); o.append(tri[2])
	if moved == 0: return s
	var nsh := ConcavePolygonShape3D.new(); nsh.backface_collision = s.backface_collision; nsh.set_faces(o)
	return nsh
