extends SceneTree
## Pictures of one person's body at work (C++ class CityPed), for a look by eye. A small window, leaves by itself:
##   godot --path . --rendering-method mobile --resolution 640x400 -s res://tests/people/ped_shots.gd -- --out=OUT/ped_shots
## Five pictures from the side: standing in its animation, in the middle of a stagger (a shove of 150 N s), going down
## (a charge of 420 N s), lying, getting up. The person wears one plain colour: its real look comes with the crowd.
var ped: Node3D
var cam: Camera3D
var t := 0.0
var out := "OUT/ped_shots"
var shots := [[1.0, "1_stands"], [1.42, "2_staggers"], [6.55, "3_goes_down"], [8.6, "4_lies"], [10.9, "5_gets_up"]]
var done := 0
var pushed := 0

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
	if not ClassDB.class_exists(&"CityPed"): print("PED ERROR no native module"); quit(1); return
	DirAccess.make_dir_recursive_absolute(out)
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
	sh.size = Vector3(400, 2, 400); cs.shape = sh; b.add_child(cs); b.position = Vector3(0, -1, 0); root.add_child(b)
	var fl := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(60, 60); fl.mesh = pm
	var fm := StandardMaterial3D.new(); fm.albedo_color = Color(0.42, 0.43, 0.45); fl.material_override = fm; root.add_child(fl)
	for i in 13:      # marks on the floor every metre along the way it is pushed
		var mk := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(1.6, 0.01, 0.04); mk.mesh = bm; mk.position = Vector3(0, 0.005, float(i) - 2.0); root.add_child(mk)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 40, 0); sun.shadow_enabled = true; root.add_child(sun)
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.7, 0.78, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.7, 0.72, 0.76); env.ambient_light_energy = 0.7; we.environment = env; root.add_child(we)
	ped = ClassDB.instantiate(&"CityPed"); ped.set(&"body_id", "M1"); root.add_child(ped)
	cam = Camera3D.new(); cam.fov = 40.0; root.add_child(cam); cam.current = true

func _physics_process(delta: float) -> bool:
	if ped == null: return true
	t += delta
	if pushed == 0 and t >= 1.02: pushed = 1; ped.call(&"push", Vector3(0, 0, 150), ped.global_position + Vector3(0, 1.3, 0))
	if pushed == 1 and t >= 6.0: pushed = 2; ped.call(&"push", Vector3(0, 0, 420), ped.global_position + Vector3(0, 1.3, 0))
	return false

func _process(_delta: float) -> bool:
	if ped == null: return true
	var s: Dictionary = ped.call(&"get_state")
	var c: Vector3 = s.get("pelvis", Vector3.ZERO)
	cam.global_position = Vector3(c.x + 4.6, 1.25, c.z + 0.9)
	cam.look_at(Vector3(c.x, 0.85, c.z))
	if done < shots.size() and t >= float(shots[done][0]) + 0.03:
		var img := root.get_texture().get_image()
		img.save_png("%s/%s.png" % [out, String(shots[done][1])])
		print("PED shot %s at %.2f s: mode %d state %d steps %d" % [String(shots[done][1]), t, int(s.mode), int(s.state), int(s.steps)])
		done += 1
	if done >= shots.size(): quit(0); return true
	return false
