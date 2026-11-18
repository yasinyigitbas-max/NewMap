extends RefCounted
## Shop-name plates for baked buildings (18 Nov trial). The kit paints fixed names into its models, so every copy of
## a model repeats them (VILLAGE THEATRE on 15 models) and they turn up in the wrong district. A plate sits 2 cm in
## front of each painted or blank board (board rectangles from interiors/room_contracts.json "signs", found in the
## mesh) and carries a name drawn from a list for the district. The method and the styles are the interiors'
## (rooms/room_lib.gd sign / make_signs); here every board of every building gets one, all plates of a call in ONE
## mesh and one texture. A name is fixed by the building's own name, so it never changes between bakes.
const CONTRACTS := "res://map_dc/coronado/city_kit/interiors/room_contracts.json"
const STYLE := [[Color(0.08, 0.2, 0.15), Color(0.94, 0.86, 0.6), Color(0.75, 0.63, 0.36)], [Color(0.42, 0.07, 0.06), Color(0.98, 0.93, 0.8), Color(0.85, 0.75, 0.5)],
	[Color(0.07, 0.1, 0.22), Color(0.95, 0.95, 0.92), Color(0.7, 0.72, 0.78)], [Color(0.05, 0.05, 0.05), Color(0.93, 0.78, 0.42), Color(0.7, 0.55, 0.28)],
	[Color(0.05, 0.36, 0.38), Color(0.98, 0.98, 0.95), Color(0.85, 0.92, 0.9)], [Color(0.93, 0.88, 0.76), Color(0.25, 0.14, 0.08), Color(0.42, 0.28, 0.16)],
	[Color(0.1, 0.42, 0.55), Color(1.0, 0.97, 0.88), Color(0.95, 0.85, 0.6)], [Color(0.98, 0.78, 0.2), Color(0.1, 0.18, 0.32), Color(0.1, 0.18, 0.32)]]
## boards that already say what the building is stay as painted
const KEEP := ["POLICE", "RECREATION CENTER", "HARBOR OFFICE", "ST. ANNE'S CHURCH", "PUBLIC LIBRARY", "CITY HALL", "POST OFFICE", "FIRE STATION", "COMMUNITY CENTER"]
const SHOPS := ["CORNER MARKET", "SUDS LAUNDRY", "ORANGE AVE DELI", "ISLAND BIKES", "BAY PHARMACY", "TACOS EL REY", "HARBOR BARBER", "VIDEO & GAMES", "DRY CLEANERS", "NAILS & SPA", "SLICE PIZZA", "CROWN HARDWARE",
	"PET SUPPLY", "THRIFT SHOP", "DONUT HOUSE", "FLORIST", "SHOE REPAIR", "KEYS & LOCKS", "PHO BAY", "SURF & SKATE", "USED BOOKS", "TAILOR", "CHECK CASHING", "NOODLE BAR"]
const HOMES := ["THE PALMS", "CASA DEL MAR", "BAYVIEW COURT", "ORANGE GROVE", "VILLA CORONA", "SEASIDE ARMS", "EL CORDOVA", "THE TIDES", "PALM COURT", "MARINA VIEW", "ISLAND TERRACE", "GLORIETTA"]

## buildings: nodes with meta "kit" (baked cells' Buildings children). Returns one MeshInstance3D (world space) or null.
static func build(tree: SceneTree, buildings: Array) -> MeshInstance3D:
	var models: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(CONTRACTS)) as Dictionary).models
	var plates: Array = []      # [board entry, text, style index, building transform]
	for b: Node3D in buildings:
		var kit := String(b.get_meta(&"kit", ""))
		if not models.has(kit): continue
		var home := kit.begins_with("apartments/") or kit.contains("apt")
		for e: Dictionary in (models[kit] as Dictionary).get("signs", []):
			var painted := String(e.get("text", ""))
			if painted in KEEP: continue
			var h := absi(hash(String(b.name) + "|" + painted))
			var pool: Array = HOMES if (home and painted == "") else SHOPS
			plates.append([e, String(pool[h % pool.size()]), (h / 31) % STYLE.size(), b.global_transform])
	if plates.is_empty(): return null
	var vps: Array = []
	for p: Array in plates:
		var e: Dictionary = p[0]; var w := float(e.w); var hgt := float(e.y1) - float(e.y0)
		var cw := clampi(int(w * 110.0) / 4 * 4, 96, 512); var ch := maxi(24, int(float(cw) * hgt / w) / 4 * 4)
		var st: Array = STYLE[p[2]]
		var vp := SubViewport.new(); vp.size = Vector2i(cw, ch); vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		var pnl := Panel.new(); pnl.size = Vector2(cw, ch)
		var sb := StyleBoxFlat.new(); sb.bg_color = st[0]; sb.border_color = st[2]; sb.set_border_width_all(maxi(2, ch / 14)); pnl.add_theme_stylebox_override("panel", sb); vp.add_child(pnl)
		var ff := FontFile.new(); ff.load_dynamic_font(ProjectSettings.globalize_path("res://ui/fonts/%s.ttf" % ("Overpass" if int(p[2]) % 2 == 0 else "Nunito")))
		var fv := FontVariation.new(); fv.base_font = ff; fv.variation_embolden = 0.7
		var fs := int(ch * 0.6)
		while fs > 8 and ff.get_string_size(String(p[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x * 1.06 > cw * 0.86: fs -= 1
		var lb := Label.new(); lb.text = String(p[1]); lb.size = Vector2(cw, ch); lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var ls := LabelSettings.new(); ls.font = fv; ls.font_size = fs; ls.font_color = st[1]; lb.label_settings = ls; vp.add_child(lb)
		tree.root.add_child(vp); vps.append(vp)
	for i in 4: await tree.process_frame
	await RenderingServer.frame_post_draw
	var imgs: Array = []; var aw := 0; var ah := 0
	for vp2: SubViewport in vps:
		var im := vp2.get_texture().get_image(); im.convert(Image.FORMAT_RGB8); imgs.append(im); vp2.queue_free()
		aw = maxi(aw, im.get_width()); ah += im.get_height()
	var atlas := Image.create(aw, (ah + 3) / 4 * 4, false, Image.FORMAT_RGB8)
	var stl := SurfaceTool.new(); stl.begin(Mesh.PRIMITIVE_TRIANGLES)
	var y := 0
	for i in plates.size():
		var im2: Image = imgs[i]; var e2: Dictionary = plates[i][0]; var xf: Transform3D = plates[i][3]
		atlas.blit_rect(im2, Rect2i(Vector2i.ZERO, im2.get_size()), Vector2i(0, y))
		var u0 := 0.5 / aw; var u1 := (float(im2.get_width()) - 0.5) / aw; var v0 := (y + 0.5) / float(atlas.get_height()); var v1 := (y + im2.get_height() - 0.5) / float(atlas.get_height())
		y += im2.get_height()
		var f := String(e2.facade)
		var n := Vector3(0, 0, 1) if f == "front" else (Vector3(0, 0, -1) if f == "back" else (Vector3(1, 0, 0) if f == "right" else Vector3(-1, 0, 0)))
		var rt := (-n).cross(Vector3.UP); var along_x := f == "front" or f == "back"; var pl := float(e2.plane); var al := float(e2.along)
		var c := Vector3(al if along_x else pl, (float(e2.y0) + float(e2.y1)) * 0.5, pl if along_x else al) + n * 0.02
		var hw := float(e2.w) * 0.5 + 0.01; var hh := (float(e2.y1) - float(e2.y0)) * 0.5 + 0.01
		var tl := c - rt * hw + Vector3.UP * hh; var tr := c + rt * hw + Vector3.UP * hh; var br := c + rt * hw - Vector3.UP * hh; var bl := c - rt * hw - Vector3.UP * hh
		for q: Array in [[tl, Vector2(u0, v0)], [tr, Vector2(u1, v0)], [br, Vector2(u1, v1)], [tl, Vector2(u0, v0)], [br, Vector2(u1, v1)], [bl, Vector2(u0, v1)]]:
			stl.set_normal((xf.basis * n).normalized()); stl.set_uv(q[1]); stl.add_vertex(xf * (q[0] as Vector3))
	atlas.generate_mipmaps()
	var m := StandardMaterial3D.new(); m.albedo_texture = ImageTexture.create_from_image(atlas); m.roughness = 0.7
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var mi := MeshInstance3D.new(); mi.name = "SignPlates"; mi.mesh = stl.commit(); mi.material_override = m; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta(&"plates", plates.size())
	return mi
