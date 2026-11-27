extends "res://traversal/character/character.gd"
## An NPC: the player's character with another body (made by tools/build_npc.gd), fitted to the player's clips in
## two ways, both read from the two skeletons, neither set by hand:
## - before every other correction, the hips are put at the height this body's legs need (body_fit.gd);
## - the ground a clip's stride covers is taken as the player's times `leg`, this body's leg length over the
##   player's (the study: "A clip copies joint angles, so the same clip on this body takes strides about 13 %
##   shorter", and "Root travel has to be scaled by the leg ratio"): so at any speed he takes his own, shorter
##   strides at a quicker beat, and his legs are not stretched to cover the player's stride.
## The player's own character is not this script and is not changed by it (Yasin, 27 Nov: "we worked hard to get the
## player right, i dont want anything messing that up").

const BodyFit := preload("res://traversal/npc/body_fit.gd")

var fit: SkeletonModifier3D
var leg := 1.0                  # this body's leg (hip joint to ankle joint) over the player's


func _ready() -> void:
	super._ready()
	fit = BodyFit.new()
	fit.name = "BodyFit"
	skel.add_child(fit)
	skel.move_child(fit, 0)     # (the corrections run in child order: this one first)
	fit.call(&"bind", skel)
	leg = float(fit.get(&"leg"))


func _gait_for(v: float) -> Vector2:
	var g := super._gait_for(v / leg)
	return Vector2(g.x, g.y * leg)


func _measure(dt: float) -> void:
	super._measure(dt)
	_measured *= leg


# Seated, he is carried by the seat, not by his feet: the takes that hold him seated, and the takes that take him
# down onto a seat or up off it (through those, by how far the take's own hips have come down).
const SEATED := ["sit_idle", "sit_type", "type_to_sit"]
const TO_SEAT := ["sit_down", "sit_up", "car_in", "car_out"]
const SEAT_EASE := 0.2          # NOT in the study, mine: seconds to pass from one to the other where a take changes
var _seat := 0.0


func _physics_process(dt: float) -> void:
	super._physics_process(dt)
	var want := 0.0
	if _mode == "move" and _act in SEATED:
		want = 1.0
	elif _mode == "move" and _act in TO_SEAT and ACTS.has(_act):
		var a := _lib.get_animation(ACTS[_act])
		var t := a.find_track(NodePath("%s:mixamorig_Hips" % SKEL), Animation.TYPE_POSITION_3D)
		if t >= 0:
			var h0 := a.position_track_interpolate(t, 0.0).y
			var h1 := a.position_track_interpolate(t, a.length).y
			var h := a.position_track_interpolate(t, clampf(_act_t, 0.0, a.length)).y
			if absf(h1 - h0) > 0.05:
				want = clampf((maxf(h0, h1) - h) / absf(h1 - h0), 0.0, 1.0)
	_seat = move_toward(_seat, want, dt / SEAT_EASE)
	fit.set(&"seat", _seat)
