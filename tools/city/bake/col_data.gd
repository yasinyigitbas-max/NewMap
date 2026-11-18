extends Resource
## One collision shape of the baked city as PLAIN DATA (lib/s_*.res). Not a Shape3D on purpose: a Shape3D that a loader
## thread loads is handed to the physics thread at once, and on the phone (physics on its own thread) the main thread
## then waits until the whole cell's collision is built: 52-141 ms frames in the runs of 18 Nov, however small the
## pieces. As data it costs nothing to load; city_stream.gd makes the Shape3D itself, a measured amount a frame.
@export var kind := 0                           ## 0 triangles (data = faces), 1 convex (data = points), 2 box (data[0] = size)
@export var data := PackedVector3Array()
@export var backface := false
var shape: Shape3D                              ## made by the streamer on the main thread; lives as long as this resource

func weight() -> int:                           ## what making it costs, in triangles (a convex point counts as one)
	return data.size() / 3 if kind == 0 else (data.size() if kind == 1 else 1)

func make() -> Shape3D:
	if shape == null:
		if kind == 0:
			var c := ConcavePolygonShape3D.new(); c.backface_collision = backface; c.set_faces(data); shape = c
		elif kind == 1:
			var x := ConvexPolygonShape3D.new(); x.points = data; shape = x
		else:
			var b := BoxShape3D.new(); b.size = data[0]; shape = b
	return shape
