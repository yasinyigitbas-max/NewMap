# Coronado city kit (the new map)

The new map of Coronado for the game, separated from the game repo (yasinyigitbas-max/coronado-source) on 18 Nov at
Yasin's request ("completely separate the new map from the old one ... sessions take too long to start"). This repo has
ONLY the new map: hand-made, locked city-kit pieces, the kit assets they are built from, the tools, the checks.

## Read first, every session (and again after every context compression - the SessionStart hook prints it)
1. `map_dc/coronado/city_kit/JOB_BOARD.md` - the queue, Yasin's rules and decisions, where we are.
2. `.claude/skills/coronado-city-kit/SKILL.md` - how pieces are built, locked, checked; the traps.
3. `map_dc/coronado/city_kit/YASIN_MESSAGES.md` - Yasin's own words.
4. Interiors: `.claude/skills/coronado-city-interiors/SKILL.md`.
5. Before building, checking, fixing or reporting anything: `.claude/skills/coronado-super-builder/SKILL.md` (19 Nov:
   no generators, one fix = one thing changed, what each check cannot see, the outdoor and indoor audits, the land).
6. Player movement, traversal, animation clips (Mixamo, Kimodo) or the player character (Meshy): read
   `reports/TRAVERSAL STATUS.md` first (on main since 25 Nov). It holds Yasin's
   rules for that work, the decisions made, what is waiting on him and the next steps (25 Nov).

## The rules that matter most (Yasin)
- Act as architect, road / city planner and exterior designer at once; every prop has a reason. Lively, worn, varied.
- No jagged edges; smooth heights, no jumps; trees only in wells or grass; a fence post at every joint.
- Done = locked. A locked piece changes only with Yasin's word (`python3 -I tools/city/pilot/lock.py unlock ... --by=Yasin`),
  is rebuilt, re-checked (`tools/city/run/checks.sh`) and relocked. The lock test must say RESULT PASS.
- Commit and push after every step. Do not start new work when Yasin says "keep this in mind" or "just tell me".
- The Redmi / phone run comes last.

## Layout
| Path | What |
|---|---|
| `map_dc/coronado/city_kit/` | the map: pieces (.scn), layouts, plans (zoning, streets, grading, terrain), interiors, review shots, job board |
| `assets/coronado_kit/` | the kit (buildings, modular set, props, foliage) - from Yasin's assets branch in the game repo; additive updates only |
| `tools/city/` | builders (`pilot/pieces/*.gd`), libraries, validator, zoning / terrain tools (`pilot/zoning/*.py`), run scripts |
| `tests/city_kit/` | the lock test |
| borrowed from the game (read-only) | `assets/roads`, `map_dc/coronado/terrain/{textures,data,tools}`, `map_dc/coronado/streets/street_wear/wear_atlas.png`, `map_dc/coronado/shops/interior/{assets/tex,layouts}`, `map_dc/roads/lane_graph.json`, `ui/fonts`, `vehicles` (preview cars only) |

## Back into the game (integration, later)
The game repo (coronado-source) keeps the game. At integration it takes from here: `map_dc/coronado/city_kit/` (pieces,
`city_grid_layout.json`, interiors) and `map_dc/coronado/terrain/data_citykit/` (the game-format terrain, read with the
game's `--citykit` user arg, already wired in coronado-source: `CoronadoTerrain.data_dir()`). Same paths in both repos,
so it is a copy.
