extends Node3D
## Streams the baked city (city_kit/runtime) round a moving point with no loading stop. Written new for this map
## (18 Nov; nothing taken from the old game's streamer).
##
## Three layers: far/far_world.scn (whole island, loaded once, stays) - 200 m cells round the player - the rooms
## (theirs to wake; not in this node).
##
## What makes it hold up at speed (each point was measured, see docs/RUNTIME_BAKE.md):
##  - FORWARD LEAD: the loading range is swept ahead of a moving player by `lead_seconds` of travel (at most `max_lead`).
##  - A QUEUE: wanted cells are loaded nearest-first, at most `max_loading` at a time, on the streamer's OWN loader
##    threads (low priority), which also build (instantiate) the cell; a request the player has left behind is taken
##    off the list, or dropped when it arrives. Not the engine's thread pool: physics and drawing run their jobs there.
##  - NO HOLE: the far world shows the far version of everything in a cell until that cell is really in the scene
##    (global shader texture ck_cells_loaded, read by rt_far), so a late cell looks like low detail, never like nothing.
##  - SHARED THINGS STAY: every material of the bake (manifest "keep") is loaded at start and held. Measured: letting the
##    last user of a material go costs ~250 ms on the main thread, and its shader is built again on the next use.
##  - COLLISION IN STEPS: a cell's collision bodies (32 m blocks of ground and props, one per building; triangle
##    collision in pieces of 400 triangles, 1,600 a body at most: see bake_runtime.gd COL_*) are held back when the
##    cell is added and attached nearest-first, `bodies_per_frame` and `body_tris_per_frame` a frame. (The old game's phone laps:
##    adding colliders in one go was its own class of hitch, 70-147 ms.)
##  - REMOVAL IN PARTS: a cell leaves the scene piece by piece inside `frame_budget_ms` a frame.
##  - A MEMORY CAP: never more than `max_cells` in; beyond it the farthest wanted cells simply stay far versions.
##  - `prepare(pos)` / `is_ready(pos)`: get a place ready before the player is put there (respawn, mission start).
##
## Use: add the node, then every frame `update_focus(player position, false, player velocity)`.
## `update_focus(pos, true)` loads everything in range at once (start of the game behind its one loading screen,
## previews, checks). `warm_up()` draws one of everything once so shaders are built before the player moves.
signal cell_in(key: String)
signal cell_out(key: String)

@export var runtime_dir := "res://map_dc/coronado/city_kit/runtime/"
@export var load_dist := 240.0        ## a cell is wanted when its rectangle is within this of the swept focus (mid tier: 220 m)
@export var unload_dist := 300.0
@export var lead_seconds := 2.0
@export var max_lead := 200.0
@export var max_loading := 2          ## cells on the loader threads at once
@export var max_cells := 30           ## memory cap: cells in the scene
@export var frame_budget_ms := 1.5    ## main-thread time a frame may spend removing (the old game's phone budget for streaming)
@export var bodies_per_frame := 6     ## collision bodies made and attached a frame, at most
@export var body_tris_per_frame := 1200   ## and at most this much NEW collision a frame, in triangles (a convex point counts as one; the first body always goes). The phone builds roughly 5 microseconds a triangle on its physics thread.
@export var attach_bodies := true    ## test switch: false = a cell's collision is never attached (to see what attaching costs)
@export var show_cells := true       ## test switch: false = cells are added hidden (to see what their first drawing costs)
@export var loader_mode := 0         ## 0 = the streamer's own loader threads (the way to run it). 1 / 2 = the engine's thread pool without / with sub-threads, kept to compare: the pool is also what the physics engine and the renderer run their jobs on, and a cell's hundreds of files filled it (phone, 18 Nov: the main thread waited 65-350 ms for the physics step each time two cells were asked for)
@export var ready_col_m := 70.0      ## is_ready(): collision this near the place must be attached
@export var probe := false           ## test switch: time how long the physics and render servers take to digest what this frame gave them
@export var urgent_m := 90.0          ## a body this near the player is attached even while a cell is loading

enum {NONE, LOADING, BUILDING, READY, IN}
const MAP := 64                       ## ck_cells_loaded is MAP x MAP texels, cell (0, 0) at its middle

var manifest := {}
var cell_m := 200.0
var cells := {}          # "x_z" -> {state, node, task, ps, t_req, cancel}
var far_world: Node3D
var focus := Vector3.ZERO
var night := 0.0
var _keep: Array = []    # shared materials, held for the node's life
var _leaving: Array = [] # nodes on their way out, freed in parts
var _map_img: Image
var _map_tex: ImageTexture
var _map_dirty := false
var _prepared: Array = []      # extra focus points (prepare)
## counters for tests and the game's own overlay
var stats := {"in": 0, "out": 0, "dropped": 0, "add_ms_worst": 0.0, "remove_ms_worst": 0.0, "ready_ms_worst": 0.0, "ready_ms_sum": 0.0, "capped": 0, "bodies": 0, "body_ms_worst": 0.0, "body_late": 0}
var _probe_body: StaticBody3D
var _threads: Array = []       # own loader threads (loader_mode 0)
var _jobs: Array = []          # [key, path] waiting for a loader thread, nearest first (under _mx)
var _done: Array = []          # [key, node, bodies] loaded and built, waiting for the main thread (under _mx)
var _mx := Mutex.new()
var _sem := Semaphore.new()
var _quit := false
var _pending: Array = []       # collision bodies waiting to be attached: [centre, parent, body, cell key]
var add_ms: Array[float] = []
var ready_ms: Array[float] = []

func _ready() -> void:
	var mp := runtime_dir + "manifest.json"
	if FileAccess.file_exists(mp): manifest = JSON.parse_string(FileAccess.get_file_as_string(mp))
	cell_m = float(manifest.get("cell_m", 200.0))
	for k: String in manifest.get("cells", {}): cells[k] = {"state": NONE, "node": null, "task": -1, "ps": null, "t_req": 0, "cancel": false, "bodies": []}
	for p: String in manifest.get("keep", []):
		if ResourceLoader.exists(p): _keep.append(load(p))
	_map_img = Image.create(MAP, MAP, false, Image.FORMAT_R8); _map_img.fill(Color(0, 0, 0))
	_map_tex = ImageTexture.create_from_image(_map_img)
	RenderingServer.global_shader_parameter_set(&"ck_cells_loaded", _map_tex)
	if loader_mode == 0:
		for i in max_loading:
			var th := Thread.new(); th.start(_loader, Thread.PRIORITY_LOW); _threads.append(th)
	var fp := runtime_dir + "far/far_world.scn"
	if ResourceLoader.exists(fp):
		far_world = (load(fp) as PackedScene).instantiate(); add_child(far_world)

# ---------------------------------------------------------------- queries
func _dist(k: String, p: Vector3) -> float:
	var cx := float(k.get_slice("_", 0)) * cell_m; var cz := float(k.get_slice("_", 1)) * cell_m
	var dx := maxf(maxf(cx - p.x, p.x - (cx + cell_m)), 0.0); var dz := maxf(maxf(cz - p.z, p.z - (cz + cell_m)), 0.0)
	return sqrt(dx * dx + dz * dz)

func _path(k: String) -> String: return runtime_dir + "cells/cell_%s.scn" % k

func loaded_count() -> int:
	var n := 0
	for k: String in cells:
		if cells[k].state == IN: n += 1
	return n

func loading_keys() -> Array:
	var out: Array = []
	for k: String in cells:
		if cells[k].state in [LOADING, BUILDING, READY]: out.append("%s:%d" % [k, cells[k].state])
	return out

func busy() -> bool:
	for k: String in cells:
		if cells[k].state in [LOADING, BUILDING, READY]: return true
	return not _leaving.is_empty() or not _pending.is_empty()

## every cell within `load_dist` of `p` is in the scene, and the collision within `ready_col_m` of it is in the world
## (so a player put there stands on something)
func is_ready(p: Vector3) -> bool:
	for e: Array in _pending:
		if (e[0] as Vector3).distance_to(p) < ready_col_m: return false
	for k: String in cells:
		if _dist(k, p) <= load_dist and cells[k].state != IN: return false
	for b: Array in _pending:      # and the ground near it can be stood on
		if (b[0] as Vector3).distance_to(p) < 120.0: return false
	return true

## start getting the place round `p` ready (it stays wanted until `release(p)` or the player arrives)
func prepare(p: Vector3) -> void:
	_prepared.append(p)

func release_prepared() -> void:
	_prepared.clear()

## 0 day .. 1 night: drives the window glow (global ck_night) and shows the lamps' halos and pools only at night
func set_night(v: float) -> void:
	night = v
	RenderingServer.global_shader_parameter_set(&"ck_night", v)
	for k: String in cells:
		if cells[k].state == IN: _apply_night(cells[k].node)

func _apply_night(cell: Node) -> void:
	for nm in ["glow_halo", "glow_pool"]:
		var g := cell.get_node_or_null(nm)
		if g: (g as Node3D).visible = night > 0.02

func _mark(k: String, on: bool) -> void:
	var x := int(k.get_slice("_", 0)) + MAP / 2; var z := int(k.get_slice("_", 1)) + MAP / 2
	if x < 0 or z < 0 or x >= MAP or z >= MAP: return
	_map_img.set_pixel(x, z, Color(1, 0, 0) if on else Color(0, 0, 0)); _map_dirty = true

# ---------------------------------------------------------------- the loop
func update_focus(p: Vector3, now := false, velocity := Vector3.ZERO) -> void:
	focus = p
	var lead := Vector3(velocity.x, 0, velocity.z) * lead_seconds
	if lead.length() > max_lead: lead = lead.normalized() * max_lead
	var steps := 1 + int(lead.length() / 60.0)      # the range is swept along the lead, a point every 60 m or less
	var pts: Array = [p]
	for i in range(1, steps + 1): pts.append(p + lead * (float(i) / steps))
	for q: Vector3 in _prepared: pts.append(q)
	var want: Array = []      # [priority distance, key]
	for k: String in cells:
		var c: Dictionary = cells[k]; var d := 1.0e9
		for q2: Vector3 in pts: d = minf(d, _dist(k, q2))
		if d <= load_dist:
			c.cancel = false
			if c.state == NONE: want.append([d, k])
		elif d > unload_dist:
			if c.state == IN: _remove(k)
			elif c.state == LOADING and loader_mode == 0 and _unqueue(k): c.state = NONE; stats.dropped += 1      # not started yet: just taken off the list
			elif c.state != NONE: c.cancel = true      # asked for, no longer needed: dropped when it arrives
	want.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	if now:
		for w: Array in want:
			var c2: Dictionary = cells[w[1]]
			c2.node = (load(_path(w[1])) as PackedScene).instantiate(); _add(w[1])
		_flush_map(); return
	var loading := 0; var have := 0
	for k2: String in cells:
		if cells[k2].state in [LOADING, BUILDING]: loading += 1
		if cells[k2].state != NONE: have += 1
	for w2: Array in want:
		if loading >= max_loading: break
		if have >= max_cells: stats.capped += 1; break      # the cap: the rest stay far versions
		var c3: Dictionary = cells[w2[1]]
		if loader_mode == 0:
			_mx.lock(); _jobs.append([w2[1], _path(w2[1])]); _mx.unlock(); _sem.post()
		else: ResourceLoader.load_threaded_request(_path(w2[1]), "", loader_mode == 2)
		c3.state = LOADING; c3.t_req = Time.get_ticks_usec(); loading += 1; have += 1

func _process(_dt: float) -> void:
	var t0 := Time.get_ticks_usec()
	_process_stream(t0)
	stats["proc_ms"] = (Time.get_ticks_usec() - t0) / 1000.0      # this frame's main-thread time in here, for the rig's breakdown
	stats["t_proc0"] = t0
	if probe:
		# A question with an answer makes the caller wait until the server has worked off everything queued before it.
		# So these two waits are the cost of what was just handed over: bodies to the physics thread (which builds
		# their shapes), and meshes / textures the loader threads created to the render server.
		if _probe_body == null:
			_probe_body = StaticBody3D.new(); var cs := CollisionShape3D.new(); cs.shape = BoxShape3D.new(); _probe_body.add_child(cs); _probe_body.position.y = -2000.0; add_child(_probe_body)
		var t1 := Time.get_ticks_usec()
		PhysicsServer3D.body_get_state(_probe_body.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM)
		var t2 := Time.get_ticks_usec()
		RenderingServer.force_sync()
		stats["phys_wait_ms"] = (t2 - t1) / 1000.0; stats["rs_wait_ms"] = (Time.get_ticks_usec() - t2) / 1000.0
	stats["t_proc1"] = Time.get_ticks_usec()

func _process_stream(t0: int) -> void:
	if loader_mode == 0:      # what the loader threads finished since the last frame
		_mx.lock(); var fin: Array = _done; _done = []; _mx.unlock()
		for r: Array in fin:
			var cf: Dictionary = cells[r[0]]
			cf.node = r[1]; cf.bodies = r[2]; cf.state = READY      # a cancelled one is dropped in the arrival step below
	for k: String in cells:
		if loader_mode == 0: break
		var c: Dictionary = cells[k]
		if c.state == LOADING:
			var st := ResourceLoader.load_threaded_get_status(_path(k))
			if st == ResourceLoader.THREAD_LOAD_LOADED:
				c.ps = ResourceLoader.load_threaded_get(_path(k))
				if c.cancel: c.ps = null; c.state = NONE; stats.dropped += 1; continue
				c.task = WorkerThreadPool.add_task(func() -> void: _build(c))
				c.state = BUILDING
			elif st != ResourceLoader.THREAD_LOAD_IN_PROGRESS: c.state = NONE      # failed: try again when wanted
		elif c.state == BUILDING and WorkerThreadPool.is_task_completed(c.task):
			WorkerThreadPool.wait_for_task_completion(c.task); c.ps = null; c.state = READY
	# one arrival a frame, nearest first
	var best := ""; var bd := 1.0e9
	for k2: String in cells:
		if cells[k2].state == READY:
			if cells[k2].node == null: cells[k2].state = NONE; continue      # its file did not load: asked for again when wanted
			if cells[k2].cancel:
				for b0: Array in cells[k2].bodies: _leaving.append(b0[2])
				_leaving.append(cells[k2].node); cells[k2].bodies = []; cells[k2].node = null; cells[k2].state = NONE; stats.dropped += 1; continue
			var d := _dist(k2, focus)
			if d < bd: bd = d; best = k2
	if best != "":
		var ta := Time.get_ticks_usec(); _add(best); var ms := (Time.get_ticks_usec() - ta) / 1000.0
		add_ms.append(ms); stats.add_ms_worst = maxf(stats.add_ms_worst, ms)
		var rm := (Time.get_ticks_usec() - int(cells[best].t_req)) / 1000.0
		ready_ms.append(rm); stats.ready_ms_worst = maxf(stats.ready_ms_worst, rm); stats.ready_ms_sum += rm
	# While a loader thread is creating a cell's meshes and shapes it holds the render and physics servers' locks for
	# moments, and anything the main thread asks of them then waits (measured: a 0.05 ms body attach took 14-35 ms,
	# a removal step 45 ms). So collision and removals run in the frames when nothing is loading - unless a body is
	# needed soon (within `urgent_m` of the player).
	var quiet := true
	for kq: String in cells:
		if cells[kq].state in [LOADING, BUILDING]: quiet = false; break
	# collision: the nearest waiting bodies first, a few a frame
	if not _pending.is_empty():
		var spent := 0
		for i in bodies_per_frame:
			if _pending.is_empty(): break
			var bi := 0; var bdist := 1.0e18
			for j in _pending.size():
				var dd := (_pending[j][0] as Vector3).distance_squared_to(focus)
				if dd < bdist: bdist = dd; bi = j
			var mk := _pending[bi][2] as Node3D
			var cost := 0      # only shapes not made yet cost: one that a neighbour cell already uses is there
			for it: Array in mk.get_meta(&"col"):
				if (it[0] as Resource).get(&"shape") == null: cost += int((it[0] as Resource).call(&"weight"))
			if i > 0 and spent + cost > body_tris_per_frame: break
			spent += cost
			var e: Array = _pending[bi]; _pending.remove_at(bi)
			var tb := Time.get_ticks_usec()
			var body := StaticBody3D.new(); body.name = mk.name; body.transform = mk.transform
			body.collision_layer = int(mk.get_meta(&"layer")); body.collision_mask = int(mk.get_meta(&"mask"))
			for it2: Array in mk.get_meta(&"col"):
				var cs := CollisionShape3D.new(); cs.shape = (it2[0] as Resource).call(&"make"); cs.transform = it2[1]; body.add_child(cs)
			(e[1] as Node).add_child(body); mk.free()
			var bms := (Time.get_ticks_usec() - tb) / 1000.0
			if bms > float(stats.body_ms_worst): stats.body_ms_worst = bms; stats["body_worst_what"] = "%s shapes=%d new=%d" % [body.name, body.get_child_count(), cost]
			stats.bodies += 1; stats["col_units"] = int(stats.get("col_units", 0)) + cost
			stats["body_wait_ms_worst"] = maxi(int(stats.get("body_wait_ms_worst", 0)), Time.get_ticks_msec() - int(e[4]))      # from its cell's arrival to the body being in the world
		for e2: Array in _pending:      # a body still waiting with the player 40 m away would be a hole in the ground
			if (e2[0] as Vector3).distance_to(focus) < 40.0: stats.body_late += 1; break
	# cells on their way out: a part at a time inside the frame budget
	while quiet and not _leaving.is_empty() and (Time.get_ticks_usec() - t0) / 1000.0 < frame_budget_ms:
		var tr := Time.get_ticks_usec()
		var n: Node = _leaving[_leaving.size() - 1]
		if n.get_child_count() > 0 and not (n is CollisionObject3D):
			var ch := n.get_child(n.get_child_count() - 1); n.remove_child(ch); _leaving.append(ch)
		else:
			_leaving.pop_back(); n.free()
		stats.remove_ms_worst = maxf(stats.remove_ms_worst, (Time.get_ticks_usec() - tr) / 1000.0)
	_flush_map()

func _flush_map() -> void:
	if _map_dirty: _map_tex.update(_map_img); _map_dirty = false

## A loader thread of the streamer's own: it loads a cell's file with everything in it, builds the cell, and hands
## it over. It never uses the engine's thread pool and never touches `cells`: the main thread owns that.
func _loader() -> void:
	while true:
		_sem.wait()
		if _quit: return
		_mx.lock(); var job: Array = _jobs.pop_front() if not _jobs.is_empty() else []; _mx.unlock()
		if job.is_empty(): continue
		var ps := ResourceLoader.load(job[1]) as PackedScene
		var tmp := {"ps": ps, "node": null, "bodies": []}
		if ps: _build(tmp)
		_mx.lock(); _done.append([job[0], tmp.node, tmp.bodies]); _mx.unlock()

func _unqueue(k: String) -> bool:
	var hit := false
	_mx.lock()
	for i in _jobs.size():
		if String(_jobs[i][0]) == k: _jobs.remove_at(i); hit = true; break
	_mx.unlock()
	return hit

func _exit_tree() -> void:
	_quit = true
	for th: Thread in _threads: _sem.post()
	for th2: Thread in _threads: th2.wait_to_finish()
	_threads.clear()

## loader or worker thread: build the cell and take its collision bodies off, to be attached in steps
func _build(c: Dictionary) -> void:
	var node: Node3D = (c.ps as PackedScene).instantiate()
	var bodies: Array = []
	for b: Node in node.find_children("col*", "Node3D", true, false):      # the bodies-to-be (bake_runtime.gd _col_marker)
		if not b.has_meta(&"col"): continue
		var par := b.get_parent(); var centre := Vector3.ZERO
		if par != node and par is Node3D: centre = (par as Node3D).position
		else: centre = (b as Node3D).position
		par.remove_child(b); bodies.append([centre, par, b])
	c.bodies = bodies; c.node = node

func _add(k: String) -> void:
	var c: Dictionary = cells[k]
	if not show_cells: (c.node as Node3D).visible = false
	add_child(c.node); _apply_night(c.node)
	for b: Array in c.bodies:
		if attach_bodies: _pending.append([b[0], b[1], b[2], k, Time.get_ticks_msec()])
		else: _leaving.append(b[2])
	c.bodies = []
	c.state = IN; stats["in"] += 1; _mark(k, true); cell_in.emit(k)

func _remove(k: String) -> void:
	var c: Dictionary = cells[k]
	_mark(k, false)      # the far world shows the cell's far versions from this frame on
	for i in range(_pending.size() - 1, -1, -1):      # bodies it never got to attach
		if String(_pending[i][3]) == k: _leaving.append(_pending[i][2]); _pending.remove_at(i)
	remove_child(c.node); _leaving.append(c.node)
	c.node = null; c.state = NONE; stats.out += 1; cell_out.emit(k)

## Draw one of every baked material once (lib/warm.scn) so its shaders are built now and not at the first cell that
## uses it. Call behind the game's loading screen with the camera that will be used; takes `frames` frames.
func warm_up(cam: Camera3D, frames := 3) -> void:
	var wp := runtime_dir + "lib/warm.scn"
	if not ResourceLoader.exists(wp): return
	var w: Node3D = (load(wp) as PackedScene).instantiate()
	add_child(w); w.global_transform = Transform3D(Basis.IDENTITY, cam.global_position - cam.global_transform.basis.z * 6.0)
	for g: Node in w.find_children("*", "GeometryInstance3D", true, false): (g as GeometryInstance3D).visible = true
	var prev := night; RenderingServer.global_shader_parameter_set(&"ck_night", 1.0)      # night variants too
	for i in frames: await get_tree().process_frame
	RenderingServer.global_shader_parameter_set(&"ck_night", prev)
	w.queue_free()
