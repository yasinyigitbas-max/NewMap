# The story

## Current: *Alien Status* (working title): `alien_status/`
Yasin, 28 Nov: "check coronado source and its story first, then adapt it to work with the map ... make it much more
game like. this is an english learning game, but it shouldn't make it that obvious and play like a real and great game
first", and: "disregard the new map drafts".

This is the old game's own story (the camp, the gate, the flatmate, the job, the aliens, Goo, fired, the argument,
the hospital drive) kept in its order, set in the new map's real places, and rebuilt as missions:
- **Kept:** the old people, events and jokes, and 323 of the old lines word for word (checked against
  `i18n/strings.csv` and the camp playthrough).
- **Changed:** no lesson screens, quizzes or "let me check my phone" on the story path. English is how you act:
  you say a thing and it happens.
- **New:** chapters 3 and 4, made from what the old story left open (the officer's tests, the rent, Grace, Ivan, the
  locked room, the aliens' return), and one new person, Commander Rhodes.
- **Places:** every room named is in `docs/INDOORS.md`. Three sets come from the old game (camp, interrogation
  room, ship) and the base gate needs the kit's unused gatehouse placed.

Start with `alien_status/BIBLE.md`, then the four `MISSIONS_*.md` files, then `OPEN_WORLD.md`.

The drafts below were set aside on 28 Nov and were not used for it.

## Set aside: *The Long Way Round*, A1 edition: `long_way_round_a1/`
Yasin, 20 Nov: "fit the A1 syllabus to your first draft with my scenario … use as few non-existing places and props as
possible, our game has many locations now".

This is Version A (Yasin's own beats in Yasin's order) rebuilt for A1:
- **Shape:** four acts, 23 missions.
- **Lines:** every player line is A1.
- **The climax:** the mayday is all A1 ("There is a fire. There are twelve people. We need help.").
- **Places:** every scene is set in a place already in the city: the Harbor Office, the Navy Gatehouse, Shoal, Hillcrest
  Terraces, Hilltop Market, the library, The Fish House, Island Legal Aid, Island Laundry, Ocean Travel, the Villager
  Theatre, The Crown & Anchor, the Ferry Landing, the courthouse, and more.
- **Still to build:** the flat interior, one interview room, three motel rooms, a burned state for The Fish House and a
  few small props (BIBLE.md section 8).

Start with `long_way_round_a1/BIBLE.md`, then `A1_MAP.md`.

## Also A1: *Wish You Were Here*: `wish_you_were_here/`
Yasin, after reading A, B and C: "we aim language starters, and no one can reach B2 in 25 hours from zero." The game
now covers **A1 only** (A2 is the sequel or the post-game), and Yasin asked for an entirely new story designed for
that.

The new story:
- The hero comes to Coronado to find their missing sibling, Ari, and becomes a delivery rider in Ari's jacket.
- Ari's postcards, written in A1 English, are a trail across the island.
- The rider job is an A1 job: names, numbers, addresses, *Here you are*, repeated at every door.
- The finale is a night of twelve deliveries.
- The confrontation is won by a hundred riders each saying one small true sentence.

Start with `wish_you_were_here/BIBLE.md`, then `A1_MAP.md` (the rules for every player line).

## Earlier: three versions that climb to B2 (kept for their scenes and ideas, not for their level)
Yasin asked (20 Nov 2026) for the old game's story rewritten as a real game that also teaches English, plus two more
versions of the designer's own. All three:
- follow the same rules: voice is the verb, the Word Fog with the word > sentence > syntax translation tiers, optional
  phone lessons, needs tied to the plot, any hero;
- follow the same CEFR path (`CEFR_MAP.md`, Pre-A1 to B2, mission by mission);
- use the same island.

Pick one, or mix scenes between them.

| | **A: The Long Way Round** | **B: Lost Signal** | **C: The Grand** |
|---|---|---|---|
| Built from | Yasin's outline (camp interview, taxi, flatmate, first job, hospital drive) | The designer's idea | The designer's idea |
| Genre | Crime drama with comedy | Noir mystery | Ensemble heist comedy with heart |
| The hero | Pulled out of the sea, owes the smuggler who brought them | A ship's cook's mate, the only witness to a man going overboard | A newcomer at the bottom of a 100-year-old hotel's laundry |
| Why English is the story | The villain is the only one who speaks your language; English is the way out | A 76-second recording on your phone; each act's English unlocks new words, then a new clue | English is the crew's only shared language; the plan is written in it; the pay slip's small print is the crime |
| Climax | A mayday radio call in English on a sinking boat, then the testimony in court | A confrontation on the same deck at 2 a.m., heard live by the Coast Guard; the last clean layer of the tape | A gala-night vault heist in front of 600 guests, run by your voice from inside a locked vault |
| Tone | Darker; the most emotional | Tense, clever, a puzzle | Warmest and funniest |
| Best feature | The mediation mechanic (you translate between two people and choose how) | Grammar twists: a structure you learn changes the meaning of a line you heard hours ago | A team of thirteen, recruited across the whole island |
| Files | `STORY_BIBLE.md`, `CEFR_MAP.md`, `SCRIPT_*.md`, `MUSIC.md`, `NEW_LOCATIONS.md` | `version_b/` | `version_c/` |

Notes:
- B repeats two of A's character shapes: the warm villain who speaks your language, and the retired radio expert. If B
  is chosen, it may be worth changing them so it doesn't feel like A.
- B fixes the hero's job as a cook, so the job perks of A and C don't apply.
- B and C were written by two writers in parallel from the designer's brief. Nobody has read them end to end yet.
- Music cue ids: A uses `MUS-xx`, C uses `MUS-Cxx`, B has its own list in `version_b/MUSIC.md`.
