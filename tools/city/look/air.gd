extends RefCounted
## LOOK QUEUE 2, JOB 5: life in the air, one draw (tools/city/look/air.gdshader): gulls over the water off the
## waterfront, a plane crossing high every 120 s (blinking lights at night), smoke from the factory's roof and steam
## from a warehouse vent in the industrial zone. FIXED PLACES (no reading of any cell): the factory is the kit's
## industrial/ind_factory of the industrial sample (-800, -1400) ("harbor steel mill", cell -4_-8: the building at
## (-714.5, 2.15, -1458) turned 90 degrees, its chimney's top at (-12, 18, -9.8) in the model), found once offline.
## look.gd `air` (rig --air=1), OFF by default until measured on the phone.

const SHADER := "res://tools/city/look/air.gdshader"
## gull circles: [centre x, z, radius, height, count]: over the water east of the waterfront promenade (the coast at
## x ~636 on z 200) and over the pier
const GULLS := [[648.0, 205.0, 18.0, 9.0, 4], [665.0, 165.0, 24.0, 14.0, 3], [700.0, 250.0, 34.0, 20.0, 4]]
## smoke and steam: [x, y, z, rise in m, life in s, puffs]
const PUFFS := [[-704.7, 20.4, -1470.0, 34.0, 16.0, 16],      # the steel mill's chimney: slow grey-white smoke
	[-742.0, 10.4, -1420.0, 16.0, 7.0, 8]]                       # a warehouse vent: quick steam
const PLANE := [0.0, 650.0, -600.0]

static var _mat: ShaderMaterial

static func material() -> ShaderMaterial:
	if _mat == null:
		_mat = ShaderMaterial.new(); _mat.shader = load(SHADER)
	return _mat

static func build() -> MultiMeshInstance3D:
	var quad := QuadMesh.new(); quad.size = Vector2(1, 1)
	var items: Array = []      # [origin, custom]
	var k := 0
	for g: Array in GULLS:
		for i in int(g[4]):
			k += 1; items.append([Vector3(g[0], 0.0, g[1]), Color(0.0, fmod(k * 0.618, 1.0), float(g[2]) * (0.6 + 0.4 * fmod(k * 0.37, 1.0)), float(g[3]) + fmod(k * 3.7, 6.0))])
	items.append([Vector3(PLANE[0], PLANE[1], PLANE[2]), Color(1.0, 0.13, 0.0, 0.0)])
	for p: Array in PUFFS:
		for i in int(p[5]):
			items.append([Vector3(p[0], p[1], p[2]), Color(2.0, float(i) / float(p[5]), float(p[3]), float(p[4]))])
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.use_custom_data = true; mm.mesh = quad
	mm.instance_count = items.size()
	for i in items.size():
		mm.set_instance_transform(i, Transform3D(Basis(), items[i][0])); mm.set_instance_custom_data(i, items[i][1])
	var mi := MultiMeshInstance3D.new(); mi.name = "look_air"; mi.multimesh = mm; mi.material_override = material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.custom_aabb = AABB(Vector3(-5000, -50, -5000), Vector3(10000, 1500, 10000))      # moved in the shader: never culled
	return mi
