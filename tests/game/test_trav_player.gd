extends SceneTree
## The game's player on the traversal body (C++: CityPlayer::set_traversal, native/src/city_player.cpp; the body and its
## moves are native/traversal/src, compiled into the game's module; Yasin, 27 Nov: "wire the new npcs, cars and movement
## in"), on a made-up street:
##   godot --headless --fixed-fps 60 --path . -s res://tests/game/test_trav_player.gd
## Needs res://traversal/ (bash tools/traversal/sync_to_game.sh). A floor, a kerb 0.15 m, a step 0.40 m, a thin wall
## 0.90 m, in a row ahead of him (7.5 m on). Checks: the switch takes; told to walk (set_move, as the keys do) he walks at the
## traversal body's walking pace and this node is where the body is every tick; he is over the kerb, up the step, over
## the wall (three moves begun, or more); "riding" puts the body away and stand_at sets it down again where it is told;
## switched off he is the old player again.
var pl: CharacterBody3D
var fails := 0
func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("TRAVPL  %s: %s" % ["ok" if ok else "FAIL", what])
func _box(size: Vector3, at: Vector3) -> void:
	var b := StaticBody3D.new(); var c := CollisionShape3D.new(); var s := BoxShape3D.new(); s.size = size; c.shape = s
	b.add_child(c); b.position = at; root.add_child(b)
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	_box(Vector3(80, 1, 80), Vector3(0, -0.5, 0))
	# (ahead for him, with the camera as it starts, is +Z)
	_box(Vector3(4, 0.15, 3.0), Vector3(0, 0.075, 9.0))
	_box(Vector3(4, 0.40, 3.0), Vector3(0, 0.20, 14.0))
	_box(Vector3(4, 0.90, 0.2), Vector3(0, 0.45, 19.0))
	pl = ClassDB.instantiate(&"CityPlayer"); pl.position = Vector3(0, 0.05, 0); root.add_child(pl)
	for i in 10: await physics_frame
	pl.call(&"set_traversal", true)
	_check(bool(pl.call(&"get_traversal")), "the switch takes: the traversal body is under him")
	if not bool(pl.call(&"get_traversal")):
		print("RESULT FAIL (%d)" % fails); quit(1); return
	var body: CharacterBody3D = pl.call(&"get_traversal_body")
	var trav: Node = body.get_node_or_null("Traverse")
	_check(body.get_node_or_null("Character") != null and trav != null and body.get_node_or_null("Interact") != null and body.get_node_or_null("Hold") != null, "its character, moves, doors-and-seats and things-in-hand are there")
	_check(pl.collision_layer == 0 and body.collision_layer == 2, "the body stands in the world on the player's layer, this node does not")
	for i in 30: await physics_frame
	pl.call(&"set_move", Vector2(0, 1), false)
	var apart := 0.0; var fastest := 0.0; var highest := 0.0
	var z_at := {}
	for t in 1200:
		await physics_frame
		apart = maxf(apart, pl.global_position.distance_to(body.global_position))
		if t == 240: z_at[150] = body.global_position.z       # (a second on the flat, once he is walking: before the kerb at 7.5 m)
		if t == 180: z_at[90] = body.global_position.z
		highest = maxf(highest, body.global_position.y)
	var pace := absf(float(z_at[150]) - float(z_at[90]))
	_check(absf(pace - 1.45) < 0.1, "walking on the flat he goes %.2f m in a second (the traversal body's walk: 1.45 m/s)" % pace)
	# (this node is set where the body was a tick before, at most: 1.45 m/s for a 60th of a second, and the moves' travel)
	_check(apart < 0.15, "this node is where the body is: never further than %.3f m from it" % apart)
	_check(body.global_position.z > 19.5 and absf(body.global_position.y) < 0.05, "he is past the kerb, the step and the wall, on the ground again (z %.2f, y %.2f)" % [body.global_position.z, body.global_position.y])
	_check(int(trav.get(&"plays")) >= 3 and highest > 0.38, "moves begun on the way: %d (the step up, the step off, the wall); highest he stood %.2f m" % [int(trav.get(&"plays")), highest])
	pl.call(&"set_move", Vector2(0, 0), false)
	for i in 60: await physics_frame
	pl.call(&"set_riding", true)
	for i in 5: await physics_frame
	_check(not body.visible and body.collision_layer == 0, "riding: the body is put away (not drawn, not in the world)")
	pl.call(&"set_riding", false)
	pl.call(&"stand_at", Vector3(5.0, 0.0, 5.0), 1.0)
	for i in 30: await physics_frame
	_check(body.visible and body.global_position.distance_to(Vector3(5.0, 0.0, 5.0)) < 0.1 and pl.global_position.distance_to(body.global_position) < 0.05, "set down again where he was told (%.2f m off)" % body.global_position.distance_to(Vector3(5.0, 0.0, 5.0)))
	# a person in his way (a capsule on the people's layer, 32): his body is stopped by it or goes round it, and none of
	# his probes takes it for a wall to climb or a step to take
	var man := StaticBody3D.new(); var mc := CollisionShape3D.new(); var ms := CapsuleShape3D.new(); ms.radius = 0.3; ms.height = 1.8; mc.shape = ms
	man.add_child(mc); man.collision_layer = 32; man.collision_mask = 0; man.position = Vector3(5.0, 0.9, 7.0); root.add_child(man)
	var plays_was := int(trav.get(&"plays")); var nearest := 9.0; var top := 0.0
	pl.call(&"set_move", Vector2(0, 1), false)
	for t in 300:
		await physics_frame
		nearest = minf(nearest, Vector2(body.global_position.x - 5.0, body.global_position.z - 7.0).length())
		top = maxf(top, body.global_position.y)
	pl.call(&"set_move", Vector2(0, 0), false)
	_check(nearest > 0.45 and nearest < 1.0, "a person in his way is solid to him: he came no nearer than %.2f m to its middle" % nearest)
	_check(int(trav.get(&"plays")) == plays_was and top < 0.05, "and he began no move against it (moves begun: %d, highest %.2f m)" % [int(trav.get(&"plays")) - plays_was, top])
	man.queue_free()
	pl.call(&"set_traversal", false)
	for i in 5: await physics_frame
	_check(not bool(pl.call(&"get_traversal")) and pl.collision_layer == 2, "switched off he is the old player again")
	print("RESULT %s (%d)" % ["PASS" if fails == 0 else "FAIL", fails])
	quit(0 if fails == 0 else 1)
