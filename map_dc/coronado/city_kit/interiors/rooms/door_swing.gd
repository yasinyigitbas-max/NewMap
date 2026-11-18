extends Node3D
## A hinged door leaf (17 Nov, Yasin: "so long as they are swing doors we should see their swinging, they shouldnt
## slide open" / "doors should always open away from the player"). The node's origin is the hinge; the leaf turns about
## Y. A double-acting leaf: when the camera / player comes within TRIGGER metres of the door's middle it swings AWAY
## from them (into the room when they come from the street, out to the street when they leave), and closes again
## behind them. The direction is chosen when the leaf starts opening and kept until it is shut again (never flips
## mid-swing). Visuals only for now: no lock, no collision change (interactions come later).
## force_open >= 0 holds the leaf at that fraction (0..1) - used by the preview shots.
@export var max_angle := 95.0        ## degrees at full open
@export var trigger := 2.2           ## metres from the door's middle
@export var speed := 2.6             ## open fraction per second (about 0.4 s to open)
var force_open := -1.0
var amount := 0.0
var _sign := 1.0                     ## the angle sign that swings the leaf out of the room (set by the room builder)
var _dir := 1.0                      ## the current swing: +1 out of the room, -1 into it

func _ready() -> void:
	_sign = float(get_meta(&"open_sign", 1.0))

func _process(dt: float) -> void:
	var want := 0.0
	var cam := get_viewport().get_camera_3d()
	var mid: Vector3 = (get_parent() as Node3D).to_global(position + (get_meta(&"mid", Vector3.ZERO) as Vector3))
	if force_open >= 0.0: want = force_open
	elif cam and cam.global_position.distance_to(mid) < trigger: want = 1.0
	if amount <= 0.001 and want > 0.0 and cam:
		# pick the side: away from the viewer. "out" = the leaf's out-of-room direction in world space
		var outw := (get_parent() as Node3D).global_transform.basis * (get_meta(&"out_dir", Vector3.BACK) as Vector3)
		_dir = -1.0 if (cam.global_position - mid).dot(outw) > 0.0 else 1.0
	if force_open >= 0.0: amount = want
	else: amount = move_toward(amount, want, speed * dt)
	# ease in and out, a little overshoot-free settle
	var e := amount * amount * (3.0 - 2.0 * amount)
	rotation.y = deg_to_rad(max_angle * e) * _sign * _dir
