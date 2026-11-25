extends SceneTree
## Turning test: how long a right-angle turn and a turn-round take at a walk and at a run, how much speed is given
## up, and that he leans into the turn. The bars are the movement study's figures (Part 1, "Turning, starting,
## stopping") and his own measured turn clips, not feel.
## Run:  godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/test_turn.gd

const WALK := 1.4
const RUN := 4.5

var fails := 0
var lab: Node3D
var body: CharacterBody3D
var tape: Node
var character: Node3D
var centre := Vector3.ZERO


func ok(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
	print(("PASS  " if cond else "FAIL  ") + what)


func _initialize() -> void:
	_run.call_deferred()


## Go along -Z, then ask for the direction `turn_deg` to the left of that (negative = right). Returns per-tick
## records from the moment the turn is asked for.
func turn(run: bool, turn_deg: float) -> Array:
	var lead := 1.6 if run else 2.5
	var speed := RUN if run else WALK
	lab.call(&"place", centre + Vector3(0.0, 0.0, speed * lead * 0.5))
	body.rotation.y = 0.0
	for i in 20:
		await physics_frame
	var a := deg_to_rad(turn_deg)
	# -Z turned to the left by a: x = -sin a, z = -cos a
	tape.call(&"make", [[lead, 0.0, -1.0, 0.0, run], [1.6, -sin(a), -cos(a), 0.0, run]])
	tape.call(&"replay")
	var rec: Array = []
	var t := 0
	while int(tape.get(&"mode")) == 2:
		await physics_frame
		t += 1
		if t > int(lead * 60.0):
			var up: Vector3 = (character.get(&"_pivot") as Node3D).global_transform.basis.y
			rec.append({"p": body.global_position, "v": body.get(&"hvel"), "up": up, "s": int(body.get(&"state"))})
	return rec


func check(run: bool, turn_deg: float, least: float, most: float, why: String) -> void:
	var rec := await turn(run, turn_deg)
	var a := deg_to_rad(turn_deg)
	var goal := Vector3(-sin(a), 0.0, -cos(a))
	var done := -1
	var slowest := 99.0
	var overshoot := 0.0
	var lean_in := 0.0
	var off := 0
	var p0: Vector3 = rec[0]["p"]
	for i in rec.size():
		var v: Vector3 = rec[i]["v"]
		slowest = minf(slowest, v.length()) if done < 0 else slowest
		overshoot = maxf(overshoot, ((rec[i]["p"] as Vector3) - p0).dot(Vector3(0.0, 0.0, -1.0)))
		if rec[i]["s"] != 0:
			off += 1
			if off == 1 and OS.get_cmdline_user_args().has("--dbg"):
				print("   first tick not on ground: tick %d state %d at %s" % [i, rec[i]["s"], str(rec[i]["p"])])
		if done < 0:
			# leaning toward the side he is turning to
			lean_in = maxf(lean_in, (rec[i]["up"] as Vector3).dot(Vector3(-signf(turn_deg), 0.0, 0.0)))
			if v.length() > 0.5 and v.normalized().dot(goal) > cos(deg_to_rad(5.0)):
				done = i
	var secs := done / 60.0
	var gait := "run" if run else "walk"
	var lean_deg := rad_to_deg(asin(clampf(lean_in, 0.0, 1.0)))
	var is_round := absf(turn_deg) > 150.0
	ok(done >= 0 and secs >= least and secs <= most and off == 0 and (is_round or lean_deg > 1.0),
		"%s, turn %d deg: heading there after %.2f s (bar %.2f to %.2f: %s); slowest %.2f m/s; carried %.2f m on; leans in %.1f deg" %
		[gait, int(turn_deg), secs, least, most, why, slowest, overshoot, lean_deg])


func _run() -> void:
	lab = (load("res://traversal/main.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 3:
		await physics_frame
	body = lab.get(&"body")
	tape = lab.get(&"tape")
	character = lab.get(&"character")
	for s: Dictionary in (lab.get(&"course") as Node3D).get(&"stations"):
		if s["label"] == "floor: one triangle mesh":
			centre = Vector3(float(s["x"]), 0.1, -9.0)
	# a right angle (counted done within 5 degrees, so 85 degrees): no faster than 300 deg/s = 0.28 s, done within two steps
	await check(false, 90.0, 0.28, 1.10, "two 0.55 s steps at most")
	await check(false, -90.0, 0.28, 1.10, "two 0.55 s steps at most")
	await check(true, 90.0, 0.28, 0.77, "two 0.385 s steps at most")
	await check(true, -90.0, 0.28, 0.77, "two 0.385 s steps at most")
	# a turn-round: his Walking Turn 180 clip takes 1.00 s; on the spot it is 3 to 4 steps
	await check(false, 180.0, 0.60, 2.20, "1.00 s clip, 4 steps at most")
	# at a run: brake first (a rapid stop), then round; the Running To Turn clip takes 2.27 s and carries 4.0 m
	await check(true, 180.0, 0.60, 2.27, "0.67 s clip at best, 2.27 s Running To Turn at worst")
	print("RESULT " + ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(1 if fails else 0)
