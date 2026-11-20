extends Resource
## One collision shape of the baked city as PLAIN DATA (lib/s_*.res). Not a Shape3D on purpose: a Shape3D that a loader
## thread loads is handed to the physics thread at once, and on the phone (physics on its own thread) the main thread
## then waits until the whole cell's collision is built: 52-141 ms frames in the runs of 18 Nov, however small the
## pieces. As data it costs nothing to load; the streamer (C++ CityStream, native/src/city_stream.cpp) makes the Shape3D itself from kind / data / backface, a measured amount a frame, and keeps it in `shape`; make() and weight() below are for the tools only.
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
