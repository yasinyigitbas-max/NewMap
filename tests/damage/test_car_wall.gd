extends "res://tests/car/test_city_car.gd"
## Damage: the car test (tests/car/test_city_car.gd, unchanged) with the world's damage node in it, headless:
##   godot --headless --fixed-fps 60 --path . -s res://tests/damage/test_car_wall.gd
## The car drives into a wall at ~65 km/h; CityCar::hit reports it through hit(..., CAR, car). Checks, besides the car
## test's own: a CAR hit came in, on the wall (not the car), and left a mark there (a scrape or a big chip).
var dmg: Node3D
var reported := false

func _initialize() -> void:
	dmg = ClassDB.instantiate(&"CityDamage"); dmg.name = "Damage"; root.add_child(dmg)
	super._initialize()

func _physics_process(dt: float) -> bool:
	var s: Dictionary = dmg.call(&"get_state")
	if not reported and int((s.hits as Dictionary).car) > 0:
		reported = true
		var marks: Array = dmg.call(&"marks_near", car.global_position, 6.0)
		print("DMGCAR car hits %d, last surface %s, marks near the car %d %s" % [int((s.hits as Dictionary).car), str(s.last_surface), marks.size(), str(marks.map(func(m: Dictionary) -> int: return int(m.tile)))])
		_check(String(s.last_surface) == "concrete", "the car's impact reached the damage node, on the wall (%s)" % str(s.last_surface))
		_check(marks.size() >= 1, "the wall took a mark where the car hit (%d)" % marks.size())
	return super._physics_process(dt)
