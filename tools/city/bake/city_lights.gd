extends Node3D
## Real lights for the baked city at night, sized for the engine's mobile light grid (docs/engine: patch e, project
## setting rendering/lights_and_shadows/mobile_light_grid: the nearest 32 omni + 32 spot lights for a fixed cost,
## no 8-per-mesh limit). The bake records every lamp of a cell as a light anchor (cell meta "lights"); this node keeps
## a small pool of OmniLight3D on the anchors nearest to the focus and fades them with ck_night. Every other lamp shows
## as its halo and ground pool (rt_glow.gdshader). `budget` leaves room in the 32 for room lamps and car lights.
## Without the light grid (the stock engine) keep `budget` at 8 or less: a mesh is lit by 8 omni lights at most.
@export var budget := 26      ## look uplift (28 Nov): 20 -> 26 of the grid's 32 omni (signs and canopies joined the lamps); 6 left for rooms and cars
@export var reach_scale := 1.0
@export var energy := 2.2
var stream: Node3D           ## the city_stream node (its loaded cells carry the anchors)
var _pool: Array[OmniLight3D] = []

func _ready() -> void:
	for i in budget:
		var l := OmniLight3D.new(); l.shadow_enabled = false; l.visible = false; l.omni_attenuation = 1.4
		add_child(l); _pool.append(l)

## call when the focus moved a few metres (not every frame) and when night falls
func update_lights(focus: Vector3, night: float) -> void:
	var cand: Array = []
	if night > 0.05 and stream:
		for k: String in stream.cells:
			var c: Dictionary = stream.cells[k]
			if c.state != stream.IN or not (c.node as Node).has_meta(&"lights"): continue
			for L: Array in (c.node as Node).get_meta(&"lights"):
				var p := Vector3(L[0], L[1], L[2]); var d := p.distance_to(focus)
				if d < 140.0: cand.append([d + (25.0 if int(L[7]) == 1 else (8.0 if int(L[7]) == 2 else 0.0)), p, L])     # street lamps, then lit signs / canopies (kind 2), then porch lights
	cand.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for i in _pool.size():
		var l := _pool[i]
		if i >= cand.size(): l.visible = false; continue
		var L2: Array = cand[i][2]
		l.global_position = (cand[i][1] as Vector3) - Vector3(0, 0.3, 0); l.omni_range = float(L2[3]) * reach_scale
		l.light_color = Color(L2[4], L2[5], L2[6]); l.light_energy = energy * smoothstep(0.15, 0.6, night); l.visible = true
