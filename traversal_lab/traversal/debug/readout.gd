extends CanvasLayer
## On-screen instruments: what the body says about itself, and a graph of its height over the last seconds.
## The body is any node with `get_readout() -> Dictionary` ({state, speed, height, ...}).

const HISTORY := 360          # ticks shown in the graph (6 s at 60)

var body: Node3D
var tape: Node
var station_label := ""
var _text := Label.new()
var _graph := Control.new()
var _hist := PackedFloat32Array()
var _max_step := 0.0          # largest height change between two ticks since the last reset


func _ready() -> void:
	_text.position = Vector2(12, 8)
	_text.add_theme_font_size_override(&"font_size", 18)
	_text.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_text.add_theme_constant_override(&"outline_size", 6)
	add_child(_text)
	_graph.position = Vector2(12, 310)
	_graph.size = Vector2(420, 140)
	_graph.draw.connect(_draw_graph)
	add_child(_graph)


func reset_marks() -> void:
	_max_step = 0.0
	_hist.clear()


func _physics_process(_dt: float) -> void:
	if body == null:
		return
	var y := body.global_position.y
	if _hist.size() > 0:
		_max_step = maxf(_max_step, absf(y - _hist[_hist.size() - 1]))
	_hist.append(y)
	if _hist.size() > HISTORY:
		_hist.remove_at(0)


func _process(_dt: float) -> void:
	if body == null:
		return
	var r: Dictionary = body.call(&"get_readout") if body.has_method(&"get_readout") else {}
	var mode := "live"
	if tape:
		mode = ["live", "RECORDING  %d ticks" % (tape.get(&"tape") as Array).size(),
				"REPLAY  %d / %d" % [tape.get(&"cursor"), (tape.get(&"tape") as Array).size()]][int(tape.get(&"mode"))]
	var p := body.global_position
	# which version of the movement code is running (27 Nov: C++ is the default; `-- --script` asks for the scripts)
	var cpp := 0
	var parts := 0
	for part: Node in [body, body.get_node_or_null(^"Character"), body.get_node_or_null(^"Traverse"), body.get_node_or_null(^"Interact")]:
		if part != null:
			parts += 1
			cpp += 1 if part.get_script() == null else 0
	var code := "C++ (all %d parts)" % parts if cpp == parts else ("scripts" if cpp == 0 else "MIXED: %d of %d parts in C++" % [cpp, parts])
	_text.text = "code    " + code + "\n" + "state   %s\nspeed   %.2f m/s\nheight  %.3f m\nbiggest height step  %.1f cm / tick\npos     %.2f  %.2f  %.2f\nstation %s\ninput   %s\n%s\n\nSpace jump   [ ] station   R reset   F5 record   F6 stop   F7 replay   F8 save   F9 load   Esc mouse" % [
			str(r.get("state", "?")), float(r.get("speed", 0.0)), float(r.get("height", p.y)), _max_step * 100.0,
			p.x, p.y, p.z, station_label, mode, str(r.get("note", ""))]
	_graph.queue_redraw()


func _draw_graph() -> void:
	var sz := _graph.size
	_graph.draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, 0.45))
	if _hist.size() < 2:
		return
	var lo := _hist[0]
	var hi := _hist[0]
	for v in _hist:
		lo = minf(lo, v)
		hi = maxf(hi, v)
	if hi - lo < 0.2:
		var mid := (hi + lo) * 0.5
		lo = mid - 0.1
		hi = mid + 0.1
	var pts := PackedVector2Array()
	for i in _hist.size():
		pts.append(Vector2(sz.x * i / float(HISTORY - 1), sz.y - (_hist[i] - lo) / (hi - lo) * sz.y))
	_graph.draw_polyline(pts, Color(0.4, 1.0, 0.5), 2.0)
	var font := ThemeDB.fallback_font
	_graph.draw_string(font, Vector2(4, 14), "height %.2f m" % hi, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	_graph.draw_string(font, Vector2(4, sz.y - 4), "%.2f m   (last 6 s)" % lo, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
