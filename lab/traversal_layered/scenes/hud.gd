## Debug HUD (a tool overlay, not gameplay): state of the locomotion stack and the controls.
extends CanvasLayer
@export var player_path: NodePath
var label: Label
func _ready():
	label = Label.new()
	label.position = Vector2(12, 10)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)
func _process(_d):
	var p = get_node_or_null(player_path)
	if p == null: return
	var modes := ["idle", "start", "loop", "stop", "pivot"]
	var lay = p.get_pose_layer()
	label.text = "Lab B (layered)  %s  clip %s\nspeed %.2f m/s  rate %.2f  stride %.2f  lean %.0f°  head %.0f°\nfeet %s %s   switches %d   fps %d\nWASD/stick move · Shift run · C crouch (later) · Space jump (later) · mouse/right stick look · F1 hide" % [
		modes[p.get_mode()], p.get_clip(), p.get_speed(), p.get_play_rate(), p.get_stride_scale(),
		lay.get_lean_deg() if lay else 0.0, lay.get_head_yaw_deg() if lay else 0.0,
		"L-down" if p.get_contact(0) else "L-air", "R-down" if p.get_contact(1) else "R-air",
		p.get_switches(), Engine.get_frames_per_second()]
func _unhandled_input(e):
	if e is InputEventKey and e.pressed and e.physical_keycode == KEY_F1: label.visible = not label.visible
