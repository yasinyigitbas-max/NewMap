extends RefCounted
## city1 lived-in pass (Yasin 16 Nov: "the entire block looks brand new"): where wear marks go and WHY. Each mark is
## put where the thing that makes it happens. Uses the main branch's photo atlas (kit_lib Decals, tiles below).
##   oil (6/7)    under parked / idling engines: stall centres, bus stop, the stop bar queue, driveways
##   tyre (8)     braking before stop bars, turning arcs at the junction, alley mouths
##   (atlas tiles checked 16 Nov: 1 is nearly invisible, 2/3 are dark sealed patches, 4/5 pale concrete patches,
##   15 is a tyre SKID arc - never a foot scuff; foot wear uses grime 14 at low alpha)
##   crack (0)    ageing asphalt, more on side streets and in the alley; root cracks in sidewalks beside street trees
##   sealed       the same crack line in dark sealant tint (someone already sealed it)
##   patch (2/3)  dark asphalt trench patches: around manholes and across one lane where a service line was laid
##   grime (14)   gutters (water carries dirt to the kerb), under dumpsters, around bins, and at low alpha where
##                people stand and walk most: bus stops, crosswalk landings, shop doors, benches
##   paint (13)   red kerbs (California: no stopping) at bus zones, hydrants, crosswalk approaches
## Deterministic: every piece seeds its own random numbers from its name.

const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")

const RED := Color(0.70, 0.11, 0.09, 0.9)

static func rng_for(name: String) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new(); r.seed = hash(name); return r

static func oil(d: K.Decals, r: RandomNumberGenerator, c: Vector2, yaw: float, yfn: Callable, strength := 0.75) -> void:
	d.add(6 + r.randi() % 2, c + Vector2(r.randf_range(-0.3, 0.3), r.randf_range(-0.3, 0.3)), yaw + r.randf_range(-20, 20), r.randf_range(1.2, 1.9), r.randf_range(0.8, 1.2), yfn, Color(1, 1, 1, strength * r.randf_range(0.6, 1.0)), 0.012, r.randf() < 0.5)

static func cracks(d: K.Decals, r: RandomNumberGenerator, x0: float, z0: float, x1: float, z1: float, n: int, yfn: Callable, sealed_share := 0.4) -> void:
	for i in n:
		var c := Vector2(r.randf_range(x0, x1), r.randf_range(z0, z1))
		# cracks read on asphalt only as dark lines (sealant black or dirt-filled)
		var sealed := r.randf() < sealed_share
		var tint := Color(0.12, 0.12, 0.12, 0.95) if sealed else Color(0.28, 0.27, 0.26, 0.9)
		d.add(0, c, r.randf_range(0, 360), r.randf_range(3.0, 5.5), r.randf_range(1.2, 2.2), yfn, tint, 0.012, r.randf() < 0.5)

## Lane wear along a lane from s0 to s1 (lane runs along z if along_z, else x; centre line at `c`):
## the dark oil-drip stripe down the middle (engines leak there, every street has it), darker polished wheel paths
static func lane_wear(d: K.Decals, r: RandomNumberGenerator, c: float, s0: float, s1: float, along_z: bool, yfn: Callable) -> void:
	var a := minf(s0, s1); var b := maxf(s0, s1)
	var s := a + r.randf_range(0.0, 3.0)
	while s < b - 3.0:
		var L := r.randf_range(4.0, 7.0)
		var m := s + L * 0.5
		var p := Vector2(c, m) if along_z else Vector2(m, c)
		d.add(6, p, 0.0 if along_z else 90.0, 0.9, L, yfn, Color(1, 1, 1, r.randf_range(0.35, 0.55)), 0.012, r.randf() < 0.5)
		for wp: float in [-0.85, 0.85]:
			var q := Vector2(c + wp, m) if along_z else Vector2(m, c + wp)
			d.add(14, q, 0.0 if along_z else 90.0, 0.7, L, yfn, Color(1, 1, 1, 0.22), 0.012)
		s += L + r.randf_range(0.5, 3.0)

## red kerb paint on the kerb face and top between two points along a straight kerb (kerb line at constant x or z)
static func red_kerb(d: K.Decals, a: Vector2, b: Vector2, road_side: Vector2) -> void:
	var n := maxi(1, int(ceil(a.distance_to(b) / 2.0)))
	for k in n:
		var p := a.lerp(b, float(k) / n); var q := a.lerp(b, float(k + 1) / n)
		var out := Vector3(road_side.x, 0, road_side.y)
		var p0 := Vector3(p.x, S.road_y(p.x), p.y); var q0 := Vector3(q.x, S.road_y(q.x), q.y)
		var p1 := Vector3(p.x, S.walk_y(p.x), p.y); var q1 := Vector3(q.x, S.walk_y(q.x), q.y)
		d.add_face(13, p0, q0, q1, p1, out, RED)
		# top of the kerb: a 0.15 m strip
		var inn := -out * 0.15
		d.add_face(13, p1, q1, q1 + inn, p1 + inn, Vector3.UP, RED)

## A pale concrete patch / pad (tiles 4/5) ALWAYS tinted grey: untinted they read as white smears or spilled paint
## (17 Nov audit, s_ind). Use this instead of dec.add(4 / 5, ...) for any repaired-slab look.
static func pale_patch(dec: K.Decals, rr: RandomNumberGenerator, p: Vector2, rot: float, w: float, l: float, yfn: Callable, a := 0.75) -> void:
	var v := rr.randf_range(0.46, 0.54)
	dec.add(4 + rr.randi() % 2, p, rot, w, l, yfn, Color(v, v * 0.98, v * 0.94, a))
