extends Node3D
# Creates Label3D nodes with new glyphs every frame, as the game does when 3D text first appears.
# Count "p_image->is_empty()" errors in the output: baseline engine > 0 (timing dependent), patched engine 0.
var frame := 0
var code := 0  # walks Latin, Greek and Cyrillic (the default font has them): new glyphs every frame

func _ready() -> void:
	var cam := Camera3D.new()
	cam.position = Vector3(0, 0, 6)
	add_child(cam)

func _process(_dt: float) -> void:
	frame += 1
	if frame > 240:
		print("font_race: done")
		get_tree().quit()
		return
	for i in 4:
		var l := Label3D.new()
		var s := ""
		for j in 12:
			var c := code % 900
			s += String.chr(0x21 + c if c < 94 else (0xA1 + (c - 94) if c < 500 else 0x391 + (c - 500)))
			code += 7
		s += " Ag%d" % frame
		l.text = s
		l.font_size = 24 + (frame % 12) * 6    # several sizes = several glyph caches / atlases
		l.position = Vector3(randf_range(-3, 3), randf_range(-2, 2), randf_range(-2, 0))
		add_child(l)
