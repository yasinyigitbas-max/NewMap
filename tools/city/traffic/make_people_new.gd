extends SceneTree
## THE FAR CROWD FROM THE NEW BODIES (look uplift, 28 Nov). Since the night of 28 Nov the old figures are out of the game
## (Yasin: "out of the game entirely"), so past the 18 near bodies nobody was drawn and the streets read empty. This
## poses the NEW bodies (traversal/npc/npc_XX.scn, the Meshy cast, Mixamo skeleton) the way PeopleBake posed the old
## ones and writes the same table the crowd reads (CityCrowd::make_look_new, native/src/city_crowd.cpp):
##   characters/meshy_far/far_poses.bin   per body: its cut-down mesh (~900 triangles, Godot's own LOD) in 17 poses
##   characters/meshy_far/tex/rb_npc_albedo.png   the bodies' own pictures, 256 px, one layer each (a 2D array)
##   characters/meshy_far/tex/rb_npc_mask.png     all black: nobody is re-dyed (the new bodies wear their own clothes)
##   characters/meshy_far/rb_meta.json            who is a man or a woman, which layer
## Poses (the order PeopleBake uses): 0-7 the walk (KM_Walk, 8 phases), 8 standing, 9 sitting on a seat, 10 lying on the
## back, 11 lying on the front, 12 sitting on the ground, 13-16 the riding poses (sitting: the new people ride no bikes).
## A tool: it measures and writes; it places nothing in the city.
##   godot --headless --path . -s res://tools/city/traffic/make_people_new.gd     then  godot --headless --path . --import
const NPC := "res://traversal/npc/"
const LIB := "res://traversal/character/library.res"
const OUT := "res://characters/meshy_far/"
const POSES := 17
const W := 512
const TEX := 256
const TARGET_TRIS := 700      # (and no body over 850: the largest sets the table's rows for all)
const WALK := "KM_Walk"

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var lib: AnimationLibrary = load(LIB)
	if lib == null or not lib.has_animation(WALK): print("PEOPLE ERROR no clip library at ", LIB); quit(1); return
	var cast: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/people/meshy/cast.json"))
	# the far crowd is the everyday people: 12 women and 12 men in the cast's order; uniforms and special roles (police,
	# medics, the mime, the sailor ...) stay near-only (the table's memory grows with every body: 24 = ~17 MB as used)
	const SPECIAL := ["police", "paramedic", "firefighter", "nurse", "mime", "navy", "lifeguard", "security", "sex_worker"]
	var female := {}; var keep := {}; var nw := 0; var nmen := 0
	for c: Array in cast:
		# a woman or a man: the description's first sentence ("The new person is a young Black man of about 25 ...")
		var first := String(c[3]).to_lower().get_slice(".", 0) + " "
		female[String(c[0])] = " woman" in first or " girl" in first or " lady" in first or " she " in first
		var special := false
		for sp: String in SPECIAL: if sp in String(c[2]): special = true
		if special: continue
		if female[String(c[0])] and nw < 12: keep[String(c[0])] = true; nw += 1
		elif not female[String(c[0])] and nmen < 12: keep[String(c[0])] = true; nmen += 1
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "tex"))
	var bodies: Array = []      # [id, female, corners, height, data PackedFloat32Array (blocks x corners x 3)]
	var stack: Array[Image] = []
	for n in range(1, 61):
		var id := "npc_%02d" % n
		if not ResourceLoader.exists(NPC + id + ".scn") or not keep.has(id): continue
		var b := _pose_body(id, lib, bool(female.get(id, false)))
		if b.is_empty(): continue
		var layer := stack.size(); stack.append(b[5]); b[5] = layer
		var dd: PackedFloat32Array = b[4]; var cn := int(b[2]); var ou := 2 * POSES * cn * 3
		for c in cn: dd[ou + c * 3 + 2] = float(layer)
		b[4] = dd
		bodies.append(b)
	if bodies.is_empty(): print("PEOPLE ERROR no body could be posed"); quit(1); return
	var most := 0
	for b: Array in bodies: most = maxi(most, int(b[2]))
	var corner_h := (most + W - 1) / W
	var block_rows := (2 * POSES + 1) * corner_h
	var H := block_rows * bodies.size()
	var px := PackedFloat32Array(); px.resize(W * H * 4); px.fill(0.0)
	for d in bodies.size():
		var b: Array = bodies[d]; var data: PackedFloat32Array = b[4]; var corners := int(b[2])
		for blk in 2 * POSES + 1:
			for c in corners:
				var o := ((d * block_rows + blk * corner_h) * W + c) * 4
				var s := (blk * corners + c) * 3
				px[o] = data[s]; px[o + 1] = data[s + 1]; px[o + 2] = data[s + 2]; px[o + 3] = 1.0
	var img := Image.create_from_data(W, H, false, Image.FORMAT_RGBAF, px.to_byte_array())
	img.convert(Image.FORMAT_RGBAH)
	var f := FileAccess.open_compressed(OUT + "far_poses.bin", FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	f.store_32(0x32525046)
	f.store_32(W); f.store_32(H); f.store_32(corner_h); f.store_32(POSES); f.store_32(bodies.size()); f.store_32(corner_h * W)
	# the walk: KM_Walk carries a person 1.45 m in its 1.07 s (measured on the hips below); jog and sprint as the old table
	var walk_m := 1.45; var walk_s: float = lib.get_animation(WALK).length
	for g in 2:
		for q: float in [walk_m, walk_s, 2.4, 0.9, 3.6, 0.7]: f.store_float(q)
	var meta := {}
	for b: Array in bodies:
		f.store_pascal_string(String(b[0])); f.store_32(int(b[5])); f.store_32(1 if b[1] else 0); f.store_32(int(b[2])); f.store_float(float(b[3]))
		meta[b[0]] = {"g": "women" if b[1] else "men", "layer": float(b[5]), "lm": 0.45, "tag": ""}
	f.store_buffer(img.get_data()); f.close()
	var mf := FileAccess.open(OUT + "rb_meta.json", FileAccess.WRITE); mf.store_string(JSON.stringify({"donors": meta}, "\t")); mf.close()
	# the pictures: one layer each, stacked top to bottom (the 2D array import cuts them: slices/vertical = n)
	var tall := Image.create(TEX, TEX * stack.size(), false, Image.FORMAT_RGBA8)
	for i in stack.size(): tall.blit_rect(stack[i], Rect2i(0, 0, TEX, TEX), Vector2i(0, TEX * i))
	tall.save_png(ProjectSettings.globalize_path(OUT + "tex/rb_npc_albedo.png"))
	var mask := Image.create(16, 16 * stack.size(), false, Image.FORMAT_RGBA8); mask.fill(Color(0, 0, 0, 0))
	mask.save_png(ProjectSettings.globalize_path(OUT + "tex/rb_npc_mask.png"))
	for nm: String in ["rb_npc_albedo", "rb_npc_mask"]:
		var imp := FileAccess.open(OUT + "tex/" + nm + ".png.import", FileAccess.WRITE)
		imp.store_string('[remap]\n\nimporter="2d_array_texture"\ntype="CompressedTexture2DArray"\n\n[deps]\n\nsource_file="%s"\n\n[params]\n\ncompress/mode=%d\ncompress/high_quality=false\ncompress/lossy_quality=0.7\ncompress/uastc_level=0\ncompress/rdo_quality_loss=0.0\ncompress/hdr_compression=1\ncompress/channel_pack=0\nmipmaps/generate=true\nmipmaps/limit=-1\nslices/horizontal=1\nslices/vertical=%d\n' % [OUT + "tex/" + nm + ".png", 2 if nm == "rb_npc_albedo" else 0, stack.size()])
		imp.close()
	var tris := 0
	for b: Array in bodies: tris += int(b[2]) / 3
	print("PEOPLE_NEW posed %d bodies (%d women) in %d poses, %d triangles a body on average, the most corners %d; table %d x %d (%.1f MB as used)" % [bodies.size(), bodies.filter(func(b): return b[1]).size(), POSES, tris / bodies.size(), most, W, H, W * H * 8.0 / 1048576.0])
	quit(0)

## one body: [id, female, corners, standing height, data (POSES x (positions, normals) + uv/layer, per corner), picture]
func _pose_body(id: String, lib: AnimationLibrary, fem: bool) -> Array:
	var root_n: Node3D = (load(NPC + id + ".scn") as PackedScene).instantiate()
	root.add_child(root_n)
	var skel: Skeleton3D = root_n.find_children("*", "Skeleton3D", true, false)[0] if root_n.find_children("*", "Skeleton3D", true, false).size() > 0 else null
	var mis := root_n.find_children("*", "MeshInstance3D", true, false)
	if skel == null or mis.is_empty(): print("PEOPLE ", id, ": no skeleton or mesh, left out"); root_n.queue_free(); return []
	var mi: MeshInstance3D = mis[0]
	var arr := mi.mesh.surface_get_arrays(0)
	var V: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]; var N: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]; var UV: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var BN = arr[Mesh.ARRAY_BONES]; var WT: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
	if BN == null or WT.is_empty(): print("PEOPLE ", id, ": no bones in the mesh, left out"); root_n.queue_free(); return []
	var per: int = BN.size() / V.size()
	# fewer triangles: Godot's own LOD of this surface, the level nearest TARGET_TRIS
	# fewer triangles: vertices that fall in one small cell (and lie near each other in the picture, so the seams of the
	# texture do not smear) become one; the cell grows until the body is near TARGET_TRIS
	var IX := _cluster(V, UV, arr[Mesh.ARRAY_INDEX])
	var corners := IX.size()
	# the skin: bind i -> bone and its bind pose
	var skin: Skin = mi.skin
	var binds: Array = []
	for i in skin.get_bind_count():
		var bb := skin.get_bind_bone(i)
		if bb < 0: bb = skel.find_bone(skin.get_bind_name(i))
		binds.append([bb, skin.get_bind_pose(i)])
	var ap := AnimationPlayer.new(); root_n.add_child(ap); ap.add_animation_library("", lib)
	var hips := skel.find_bone("mixamorig_Hips")
	var data := PackedFloat32Array(); data.resize((2 * POSES + 1) * corners * 3)
	var height := 1.8
	var clips := [WALK, WALK, WALK, WALK, WALK, WALK, WALK, WALK, "Standing_Idle", "Sitting_Idle", "Standing_Idle", "Standing_Idle", "Crouching_Idle", "Sitting_Idle", "Sitting_Idle", "Sitting_Idle", "Sitting_Idle"]
	var walk_len: float = lib.get_animation(WALK).length
	for p in POSES:
		var clip: String = clips[p]
		var t := walk_len * float(p) / 8.0 if p < 8 else minf(1.0, lib.get_animation(clip).length * 0.5)
		ap.play(clip); ap.seek(t, true); ap.pause()
		skel.force_update_all_bone_transforms()
		var mats: Array[Transform3D] = []
		for bd: Array in binds: mats.append(skel.transform * skel.get_bone_global_pose(int(bd[0])) * (bd[1] as Transform3D))
		var shift := Vector3.ZERO
		if hips >= 0 and p < 8:
			var hp := (skel.transform * skel.get_bone_global_pose(hips)).origin
			shift = Vector3(-hp.x, 0, -hp.z)
		# skin every vertex the corners use (once), then lay them out by corner
		var sk := {}
		var o := 2 * p * corners * 3; var on := o + corners * 3
		var lo := Vector3(1e9, 1e9, 1e9); var hi := -lo
		for c in corners:
			var vi := IX[c]
			var sp: Vector3; var sn: Vector3
			if sk.has(vi): sp = sk[vi][0]; sn = sk[vi][1]
			else:
				sp = Vector3.ZERO; sn = Vector3.ZERO
				for k in per:
					var w := WT[vi * per + k]
					if w <= 0.0: continue
					var bi: int = BN[vi * per + k]
					if bi < 0 or bi >= mats.size(): continue
					sp += (mats[bi] * V[vi]) * w; sn += (mats[bi].basis * N[vi]) * w
				sp += shift; sn = sn.normalized() if sn.length_squared() > 1e-12 else Vector3.UP
				sk[vi] = [sp, sn]
			data[o + c * 3] = sp.x; data[o + c * 3 + 1] = sp.y; data[o + c * 3 + 2] = sp.z
			data[on + c * 3] = sn.x; data[on + c * 3 + 1] = sn.y; data[on + c * 3 + 2] = sn.z
			lo = lo.min(sp); hi = hi.max(sp)
		if p == 8: height = hi.y
		if p == 10 or p == 11:      # lying: the standing figure laid on its back (10) or front (11), on the ground
			# about X by -90 (back: the face turns up) or +90 (front: the face turns down): y' = -s z, z' = s y
			var s := -1.0 if p == 10 else 1.0
			var m := 1e9
			for c in corners:
				var y := data[o + c * 3 + 1]; var z := data[o + c * 3 + 2]
				data[o + c * 3 + 1] = -s * z; data[o + c * 3 + 2] = s * y
				var ny := data[on + c * 3 + 1]; var nz := data[on + c * 3 + 2]
				data[on + c * 3 + 1] = -s * nz; data[on + c * 3 + 2] = s * ny
				m = minf(m, data[o + c * 3 + 1])
			for c in corners: data[o + c * 3 + 1] -= m - 0.02
	# the UVs and this body's layer (filled in by the caller's order: the layer is its place in the stack)
	var ou := 2 * POSES * corners * 3
	for c in corners:
		var uv := UV[IX[c]]
		data[ou + c * 3] = uv.x; data[ou + c * 3 + 1] = uv.y; data[ou + c * 3 + 2] = 0.0
	# its picture, small
	var pic := Image.create(TEX, TEX, false, Image.FORMAT_RGBA8); pic.fill(Color(0.5, 0.5, 0.5))
	var mat := mi.get_active_material(0)
	if mat is BaseMaterial3D and (mat as BaseMaterial3D).albedo_texture:
		var src := (mat as BaseMaterial3D).albedo_texture.get_image()
		if src.is_compressed(): src.decompress()
		src.convert(Image.FORMAT_RGBA8); src.resize(TEX, TEX, Image.INTERPOLATE_LANCZOS); pic = src
	root_n.queue_free()
	return [id, fem, corners, height, data, pic]

func _cluster(V: PackedVector3Array, UV: PackedVector2Array, I0: PackedInt32Array) -> PackedInt32Array:
	var out := I0
	for cell: float in [0.03, 0.04, 0.05, 0.06, 0.07, 0.085, 0.1, 0.12, 0.14, 0.17, 0.21, 0.26]:
		if out.size() / 3 <= 850: break
		var rep := {}; var map := PackedInt32Array(); map.resize(V.size())
		for v in V.size():
			var k := Vector4i(floori(V[v].x / cell), floori(V[v].y / cell), floori(V[v].z / cell), floori(UV[v].x * 12.0) * 64 + floori(UV[v].y * 12.0))
			if not rep.has(k): rep[k] = v
			map[v] = rep[k]
		var seen := {}; var I := PackedInt32Array()
		for t in range(0, I0.size(), 3):
			var a := map[I0[t]]; var b := map[I0[t + 1]]; var c := map[I0[t + 2]]
			if a == b or b == c or a == c: continue
			var key := Vector3i(mini(a, mini(b, c)), maxi(a, maxi(b, c)), a + b + c)
			if seen.has(key): continue
			seen[key] = true; I.append(a); I.append(b); I.append(c)
		out = I
	return out
