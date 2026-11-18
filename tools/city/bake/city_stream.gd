extends Node3D
## Streams the baked city (city_kit/runtime) round a point with no loading stop:
##  - far/far_world.scn is loaded once and stays (the skyline of the whole island);
##  - a 200 m cell is requested on a loader thread when its rectangle comes within `load_dist` of the focus, built
##    (instantiated) on a worker thread, and added to the scene at most one per frame; it is dropped past `unload_dist`.
## The game may use this node as it is (call `update_focus(player position)` every frame or so) or point its own
## streamer at the same cell scenes. `update_focus(pos, true)` loads everything in range at once (previews, checks).
@export var runtime_dir := "res://map_dc/coronado/city_kit/runtime/"
@export var load_dist := 240.0
@export var unload_dist := 300.0
var manifest := {}
var cell_m := 200.0
var cells := {}          # "x_z" -> {"state": 0 none / 1 loading / 2 building / 3 in, "node": Node3D, "task": int, "ps": PackedScene}
var far_world: Node3D
var add_ms: Array[float] = []      ## main-thread cost of each cell added (the hitch a player could feel)
var focus := Vector3.ZERO
var night := 0.0

## 0 day .. 1 night: drives the window glow (global ck_night) and shows the lamps' halos and pools only at night
func set_night(v: float) -> void:
	night = v
	RenderingServer.global_shader_parameter_set(&"ck_night", v)
	for k: String in cells:
		if cells[k].state == 3: _apply_night(cells[k].node)

func _apply_night(cell: Node) -> void:
	for nm in ["glow_halo", "glow_pool"]:
		var g := cell.get_node_or_null(nm)
		if g: (g as Node3D).visible = night > 0.02

func _ready() -> void:
	var mp := runtime_dir + "manifest.json"
	if FileAccess.file_exists(mp): manifest = JSON.parse_string(FileAccess.get_file_as_string(mp))
	cell_m = float(manifest.get("cell_m", 200.0))
	for k: String in manifest.get("cells", {}): cells[k] = {"state": 0, "node": null, "task": -1, "ps": null}
	var fp := runtime_dir + "far/far_world.scn"
	if ResourceLoader.exists(fp):
		far_world = (load(fp) as PackedScene).instantiate(); add_child(far_world)

func _dist(k: String, p: Vector3) -> float:
	var cx := float(k.get_slice("_", 0)) * cell_m; var cz := float(k.get_slice("_", 1)) * cell_m
	var dx := maxf(maxf(cx - p.x, p.x - (cx + cell_m)), 0.0); var dz := maxf(maxf(cz - p.z, p.z - (cz + cell_m)), 0.0)
	return sqrt(dx * dx + dz * dz)

func _path(k: String) -> String: return runtime_dir + "cells/cell_%s.scn" % k

func update_focus(p: Vector3, now := false) -> void:
	focus = p
	for k: String in cells:
		var c: Dictionary = cells[k]; var d := _dist(k, p)
		if c.state == 0 and d <= load_dist:
			if now:
				c.node = (load(_path(k)) as PackedScene).instantiate(); add_child(c.node); c.state = 3; _apply_night(c.node)
			else:
				ResourceLoader.load_threaded_request(_path(k), "", true); c.state = 1
		elif c.state == 3 and d > unload_dist:
			(c.node as Node).queue_free(); c.node = null; c.state = 0

func _process(_dt: float) -> void:
	var added := false
	for k: String in cells:
		var c: Dictionary = cells[k]
		if c.state == 1 and ResourceLoader.load_threaded_get_status(_path(k)) == ResourceLoader.THREAD_LOAD_LOADED:
			c.ps = ResourceLoader.load_threaded_get(_path(k))
			c.task = WorkerThreadPool.add_task(func() -> void: c.node = (c.ps as PackedScene).instantiate())
			c.state = 2
		elif c.state == 2 and not added and WorkerThreadPool.is_task_completed(c.task):
			WorkerThreadPool.wait_for_task_completion(c.task)
			var t0 := Time.get_ticks_usec()
			add_child(c.node); _apply_night(c.node)
			add_ms.append((Time.get_ticks_usec() - t0) / 1000.0)
			c.state = 3; c.ps = null; added = true

func loaded_count() -> int:
	var n := 0
	for k: String in cells:
		if cells[k].state == 3: n += 1
	return n

func busy() -> bool:
	for k: String in cells:
		if cells[k].state in [1, 2]: return true
	return false
