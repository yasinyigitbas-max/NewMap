# Fast rays (28 Nov 2026)

Yasin asked for engine changes that make the people's bodies cheaper on the phone without changing how anything moves
("i dont want player animations to change how they behave, but everything needs to run much more economically"). This
is the first of the three: physics rays from the C++ movement code without a Dictionary per ray.

## Why
Every traversal ray (ground, stairs ahead, both feet, hands, squeeze and ledge probes, cover) went through
`PhysicsDirectSpaceState3D::intersect_ray(PhysicsRayQueryParameters3D)`. The engine builds a Dictionary of seven keys
for each hit (`position`, `normal`, `face_index`, `collider_id`, `collider`, `shape`, `rid`: string keys, an Object
variant), and the C++ then looks two of them up again by string. That costs more than the ray itself.

## The engine side (coronado-source, `engine/patches/p_fast_rays.patch`)
One new bound method; nothing existing changes (the hash of `intersect_ray` and of every other method is the same, so
the godot-cpp 4.5 bindings of `native/` load as before):

    PhysicsDirectSpaceState3D.intersect_rays(rays: PackedVector3Array, collision_mask: int = 0xFFFFFFFF,
        exclude: Array[RID] = [], collide_with_bodies := true, collide_with_areas := false,
        hit_back_faces := true, hit_from_inside := false) -> PackedFloat32Array

- `rays` holds from, to pairs. The result is 8 floats a ray, in order: hit (1 or 0), position xyz, normal xyz, shape
  index. A miss is 8 zeros.
- It is written once, in the base class: each ray fills the same `RayParameters` that a `PhysicsRayQueryParameters3D`
  with the same values holds and calls the same virtual `intersect_ray` of the space. So it is Jolt's own ray on the
  phone (`3d/physics_engine.android="Jolt Physics"`) and GodotPhysics3D's on the PC (and an extension's, if one is
  used), with the same hits bit for bit. The defaults are `intersect_ray`'s (bodies yes, areas no, back faces hit,
  not from inside).
- Hash in the patched engine's `extension_api.json`: `776707625` (GDExtension looks it up with that hash and calls it
  by ptrcall: no Variant, no Dictionary).
- Builds: `engine-bin/all8_rays` (Android templates: all7's five patches + this one) and `engine-bin/ed_all8_rays`
  (the matching Windows editor). The patch touches only `servers/physics_3d/physics_server_3d.{h,cpp}` and the class
  doc, none of the files of the other patches, so it combines with the shadow and skeleton patches.

## The game side (this repo, `native/traversal/src/trav_probe.h`)
- `trav::Hit { hit, position, normal }` with `is_empty()`: what the traversal read from the Dictionary, as plain values.
- `trav::rays_from(body, pairs, n, out)` (`TRAV_RAYS_FROM`): n rays from a body, each the same query as
  `ray_from(body, from, to)` (the body left out, `probe_mask`, bodies, no areas). Asked once per process (a magic
  static): if the engine has `intersect_rays` with that hash, one ptrcall for all n rays (one rays array and exclude
  list per thread, reused); otherwise the old way, one `intersect_ray` a ray, read into the same `Hit`.
  `trav::hit_from` (`TRAV_HIT_FROM`) is one ray the same way.
- The log says once which way it went: `TRAV fast rays: on (intersect_rays)` or `off (intersect_ray, one ray at a time)`.
- With 64-bit vectors (`REAL_T_IS_DOUBLE`) it always takes the old way (the result is 32-bit floats).

### Call sites
Batched (rays that do not depend on each other's hits, cast in the same order as before):
- `trav_foot_place.cpp`: each foot's ball and ankle ground rays (`gb`, `ga`): 2 rays, one call.
- `trav_body.cpp` `_find_stairs`: the ray under the body and the two rays ahead (`here`, `a`, `b`): 3 rays, one call,
  when the body is on the ground and on its way (the only case in which `a` and `b` were cast; they are read only when
  `here` hits, and casting them changes nothing). Otherwise `here` alone, as before.
- `trav_body.cpp` `_gap_at`: both side rays `a`, `b`, then both `a2`, `b2` (2 + 2). `_ledge_at`: `a`, `b` (2).

One ray a call, through the same path (no Dictionary): the ledge width walk, the narrow-passage look-aheads, the steep
check, the stairs-down ahead ray, `landing_ahead`, the stair edge search (`trav_body.cpp`); the stride landing ray and
the toe and heel rays (`trav_foot_place.cpp`); the hand ray (`trav_hand_place.cpp`); the steep step ray
(`trav_character.cpp`); the cover rays (`trav_interact.cpp`).

Left as they were: the bound `_ray_down` (called by name from `trav_traverse.cpp`, so it still returns a Dictionary),
`trav_traverse.cpp`'s own queries and the crowd's (`TRAV_RAY` with their own query objects), and the rays with `&&`
between them in `_onto` (the second is cast only when the first hits).

## Proof
Parity harness, native side (`traversal_lab/tests/parity_run.gd`, the `*_native.bin` of `tools/traversal/parity.sh`),
four runs: `lanes` (81,600 ticks), `r11` and `r23` (20,000 ticks each), `acts` (81,600 ticks), Jolt (the lab's engine).
Before = `claude/night-28nov` at 8a33beea; after = this branch. Stock = official 4.7.2; patched = the same source as
`all8_rays` built for Linux (`coronado_all8_rays_linux`, editor, production).

| run | before / stock | after / stock (old way) | before / patched | after / patched (intersect_rays) |
|---|---|---|---|---|
| lanes | da8e66ca... 73,535,064 B | identical (cmp) | identical | identical |
| r11 | 9e784ab3... 17,732,744 B | identical | identical | identical |
| r23 | c6d6d383... 19,317,288 B | identical | identical | identical |
| acts | d0745203... 108,123,792 B | identical | identical | identical |

(md5 shown; `cmp` silent on all twelve pairs.) The log of each "after / patched" run says `TRAV fast rays: on`, of each
"after / stock" run `off`. The whole `parity.sh` (script against C++) on the patched engine: `PARITY RESULT PASS`
(every run byte for byte, worst difference 0).

Game tests, `RESULT PASS (0)` on both engines (fast rays off on stock, on when patched, GodotPhysics3D):
`tests/game/test_trav_player.gd`, `tests/people/test_trav_people.gd`.

## Microbenchmark (`tools/perf/bench_rays/`, PC build, Linux, 20,000 rays, 4-core cloud machine)
A C++ GDExtension that calls the traversal's own helpers on one space (a floor, 300 boxes, a trimesh hill), from
C++ as the game does, and checks every way hit the same, bit for bit (`identical: true` every round). Microseconds a
ray, the best of three rounds (the machine was compiling the engine at the same time: take the ratios, not the
absolute numbers; the phone's will differ):

| | old: `intersect_ray` + Dictionary | 1 ray a call | 2 a call | 3 a call | 64 a call |
|---|---|---|---|---|---|
| Jolt (the phone's) | 2.19 | 1.20 | 0.96 | 0.87 | 0.70 |
| GodotPhysics3D | 4.19 | 2.98 | 2.60 | 2.70 | 2.44 |

From GDScript (one `intersect_rays` call for all rays against an `intersect_ray` loop): Jolt 2.07 -> 0.68,
GodotPhysics3D 3.85 -> 1.98. On the stock engine the helpers fall back and cost what the old way costs.
So on Jolt a traversal ray costs about half (single) to about 40 % (the batched pairs and triples) of what it did.

    bash tools/perf/bench_rays/build.sh
    bash tools/perf/bench_rays/run.sh <godot binary> 20000

## For the phone run (the night session)
Export with the `all8_rays` pair and the `ed_all8_rays` editor (or combined with the other two patches); the phone log
must show `TRAV fast rays: on (intersect_rays)`. With the all7 pair it shows `off` and everything works as before.
