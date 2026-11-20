# THE LONG WAY ROUND — story bible (Coronado)

Written 20 Nov 2026 from Yasin's brief:
- a real game first, like GTA, that happens to teach English;
- rewrite every beat, with drama and comedy;
- cinematic scenes, emotion cues on the lines, music in words;
- subtle teaching;
- adventures across the whole island;
- needs that make sense;
- a story that works for any player character, whatever they look like.

The old game's story (coronado-source `main`: story/intro, story/chapters ch1–ch8, the camp) was read first.

What we keep from it:
- the camp interview as character creation;
- the chatty taxi;
- the flatmate;
- the first job;
- the hospital drive;
- the aliens, which become a running comic thread.

What we drop: the lesson-after-every-scene rhythm. In the old game, the story stopped to teach.

In this one, the story never stops. The English lives inside what you do.

Files (Version A, the story built on Yasin's own outline):
- `STORY_BIBLE.md`: this file. The vision, the cast, the island, the systems.
- `CEFR_MAP.md`: the syllabus, mission by mission: what each scene teaches without saying so.
- `SCRIPT_0_PROLOGUE_ACT1.md`, `SCRIPT_2_ACT2.md`, `SCRIPT_3_ACT3.md`, `SCRIPT_4_ACT4.md`,
  `SCRIPT_5_ACT5_EPILOGUE.md`: every mission, beat by beat, with camera, music cue and voiced lines with emotion
  cues.
- `MUSIC.md`: every music cue in words (instruments, tempo, vocals, original lyrics) plus the radio stations.
- `NEW_LOCATIONS.md`: the places, props and sounds to build.

Two more stories, the designer's own, are in `version_b/` and `version_c/`. They have the same rules, the same CEFR
path and the same island, but completely different plots.

---

## 1. The one-line pitch
You were pulled out of the sea by the U.S. Navy with nothing but your name. On Coronado Island you must:
- feed yourself;
- keep a roof over your head;
- pay off the smuggler who brought you;
- and find a voice loud enough to stop him.

## 2. The theme, and why English is the story
**The man who smuggled you, MAREK, is the only person on the island who speaks your language.**

Every scene with him is easy: no fog, no effort, home. Every scene with everyone else is hard. That is the
temptation of the whole game. Comfort is with the villain. Freedom is on the other side of a language.

The story question: *will you take the short way round (Marek's money, Marek's language) or the long way round
(work, friends, English)?*

The climax: you call the Navy on a radio, in English, the same way they once found you. Then you stand in a court
and tell your own story in your own English words.

The language is not a school subject bolted onto a crime game. It is the weapon, the key and the prize.

## 3. Pillars
1. **A game first.** Missions, chases, stealth, driving, jobs, money, a city that lives. Someone who already speaks
   perfect English should still want to finish it.
2. **Every scene earns its place.** Each mission in SCRIPT.md has a *Why it's here* line: what it does for the
   story, for the player's skills and for the hidden English. If it does only one of the three, it is cut or merged.
3. **Comedy keeps the drama honest.** Every heavy scene has a light one before it. Theo, Benny, Kai and Mrs. Finch
   are funny people in a hard world.
4. **The whole island.** The story walks you from the naval base in the north to the hotel in the south, from the
   docks to the hill. Every district has a reason to be visited (section 7).
5. **Anyone can be the hero.** Section 9.

## 4. How the English is taught, subtly
We do not stop the game for lessons. Five mechanics carry the language instead.

### A. Your voice is the verb
Every line the player character says is spoken aloud by the player. There are no exceptions: ordering, lying to a
cop, comforting a friend, the radio mayday.

The lines are always within what the player has met so far (SCRIPT.md marks the new structure of each mission as
**Language under the hood**). The player never sees that label.

### B. The Word Fog
NPC speech above the player's level shows on screen partly blurred:
- words the player has met are sharp;
- the rest are soft and grey.

The voice is the full line, at native speed, and the meaning comes from context, faces and the sharp words. The
player can always:
- say **"Sorry, can you say that again?"**: the line is repeated;
- say **"Slower, please."**: the line is repeated slowly, and the fog thins.

These two lines are taught in mission 1 by need, not by a lesson. As the player learns, the fog clears by itself, and
the city literally becomes clearer. Marek's lines are never fogged: they are in your language.

**With Yasin's translation tiers (word > sentence > syntax).** The fog is the first layer; the tiers sit under it:
1. **Tap a grey word** for its translation (word tier).
2. **Hold the subtitle** for the whole sentence translated (sentence tier).
3. **Hold again** for how it is built (syntax tier: "*have* + *been* + *-ing* = it started in the past and is
   still going").

The tiers cost nothing and never pause the scene, but the game notices. A structure the player has translated three
times gets a soft "you keep meeting this" note in **Pocket**, with a lesson ready.

That is how the syllabus becomes systematic without a classroom. The game:
- puts the structure in the scene;
- lets the player meet it until they need it;
- offers the lesson at that moment.

`CEFR_MAP.md` lists, mission by mission, the structure each scene is built to show.

### C. Thinking under pressure (the old scramble, made a game moment)
When the hero must say something new and hard, time slows. The camera pushes in, the world goes muted, and the words
float around the hero's head as tiles. The player arranges them (a thought), then says the line (an action).

A wrong order is not a fail. The hero says the scrambled version out loud and the NPC reacts in character. That is
usually a joke, sometimes a danger. Then the player gets another go.

These moments are rare: one or two per mission, at the dramatic peak.

### D. The phone (optional depth)
The hero's phone has these apps:
- **Pocket**: lessons with practice. Ruth installs it. Never required, always rewarded: finishing a lesson clears fog
  for that structure and gives a small cash grant (the resettlement programme pays for progress).
- **Notes**: every phrase the hero has heard or said is saved automatically, with the voice clip.
- **Map**, **Bank**, **Bites** (food delivery), **Messages** and **Jobs**.

### E. Check-ins with Officer Ruth (the tests, made story)
Four times in the game the hero reports to Ruth (P2, M6, M13, M21). The fifth and last test is the asylum hearing
(M30). Each check-in is a real conversation
about the hero's real life in the game, so it is a test, but you cannot study for it with flashcards. You prepare for
it by living.

A poor check-in is never a game over. Ruth says *"We'll talk again next week"*, a smaller version comes back, and the
case moves slower.

## 5. Needs that make sense
The game keeps the three needs from the old code (`player/needs.gd`): **hunger, energy, bladder**. The story is built
so that each one matters for a reason, not as a chore.

### Hunger: the money clock
You arrive broke. Food is the first thing money is for.
- Act 1 is about feeding yourself:
  - Theo's shelf vs your empty shelf in the fridge;
  - the $40 resettlement card;
  - your first pay from Gus.
- Ordering food is the first real use of English in a shop, from *"This one, please"* in Act 1 to arguing with a
  wrong delivery in Act 2.
- When hungry, the hero's hands shake slightly in fights and driving. When very hungry, the Word Fog thickens: hunger
  makes it harder to listen. That is true to life.
- Marek always offers food. Accepting is easy. That is the point.

### Energy: the day's budget
Sleep is the save, and it moves the clock.
- Night jobs (Marek's runs, Theo's hospital, the stakeout) cost the next morning.
- Act 2's pressure is double life: work for Gus by day, Marek by night, and energy runs out.
- Coffee from the Amber Ave cafés is a small boost (and an ordering moment).
- At low energy the screen edges soften and the hero yawns over NPC lines, and the fog thickens.

### Bladder: comedy and stakes
- Comedy: Benny's 40-minute taxi ride, the UFO stakeout in a parked car, the open-mic night.
- A real-life lesson hidden in a gag: *"Restrooms are for customers only."* You must buy something, or ask nicely
  (*"Excuse me, can I use the restroom, please?"*). Asking nicely works only with the right person.
- Stakes: in the stealth mission in Marek's warehouse, a full bladder means you cannot hold still for long.

### Rule for writers
A need never interrupts a cinematic. Before a big scene the game tops the needs up quietly, or the script gives the
hero a reason to eat, sleep or go first.

## 6. The cast
The hero is never described by gender in any line. Every other character has a fixed identity.

| Character | Who | Voice direction | Function |
|---|---|---|---|
| **YOU ({NAME})** | Chosen in the prologue. Age chosen (18–45). Skilled at one thing back home (the job pick: cook, mechanic, nurse, teacher, builder, driver) | The player's own voice. The hero's thought lines (italic, inner) are recorded by a narrator voice per look (two takes; section 9) | The bridge between two languages |
| **MAREK** | 50s. The smuggler. Captain of the trawler *Good Hope*. Warm, funny, fatherly, rotten | Recorded in each localisation language (the player's language), never in English until the finale. Smooth baritone, a smoker's laugh | Temptation. Home in a bottle |
| **OFFICER RUTH ALVARADO** | 54. Immigration caseworker at the naval base. Daughter of migrant farm workers. Dry, tired, decent. Eats sunflower seeds | Low, flat, deadpan. Every kindness sounds accidental | The law, and the long way |
| **BENNY OKAFOR** | 61. Taxi driver, born in Lagos, 30 years in San Diego County. Talks fast, idioms, conspiracy theories about "the lights over North Island". Calls everyone "boss" | Fast, musical, laughing. Sings along to the radio | Comedy, fast travel, the first friend |
| **THEO PARK** | 28. The flatmate. Night-shift hospital porter, failed stand-up comic, cooks one dish perfectly (kimchi fried rice) and everything else badly. Behind on rent | Quick, self-mocking, warm, cracks in serious moments | The heart. Comedy partner |
| **MRS. DOLORES FINCH** | 79. The landlady, downstairs. Retired Navy cryptographer. Binoculars, rules, iced tea, no mercy | Crisp, precise, dry. Never shouts, never needs to | The surprise genius. Cracks Marek's ledger |
| **GUS FERRANTE** | 66. Owns *Gus's*, the fish shack on the pier. Shouts as a love language | Loud, gravel, Brooklyn-via-Coronado | First job, first boss, first loss |
| **KAI FERRANTE** | 16. Gus's grand-nephew. Skater. Teaches the hero slang, half of it wrong on purpose | Lazy teenage drawl, cracks up at his own jokes | Comedy, side quests, the skater network |
| **PRIYA NAIR** | 34. Reporter at the local paper, the *Coronado Eagle*. Chasing a waterfront land deal nobody wants written about | Fast, sharp, under-slept | The investigation |
| **DET. HAL BRODY** | 47. Coronado PD. Suspects the hero first, Marek later | Slow, heavy, a man who has heard every lie | Pressure, then ally |
| **LALI** | 9. On Marek's next boat. Speaks only your language | Recorded per localisation, like Marek. Small, brave, curious | The mirror: you, a year ago |
| **JUDGE ESTHER OYELARAN** | 60s. Federal judge in the finale | Calm, slow, kind, unhurried | The last listener |
| **CLAY WHITMORE** | 52. Property developer, the waterfront deal, Marek's money partner | A friendly radio host's voice. Every sentence sounds like a gift and is a threat | The second villain: the money behind the boats |
| **CHAD WHITMORE** | 26. His nephew, "head of security", the heckler at the open mic | Sneering, entitled, loud when drunk | Small menace, the arson link |
| **DUTCH** | 40s. Marek's muscle and skipper | Almost no lines. One-word sentences | The wall between the hero and Marek |
| **NADIA** | 30s. Lali's mother, already in Marek's safehouse | Recorded per localisation, like Marek. Hope, then fierce | The rescue's face |
| **LT. CMDR. DANNY REYES** | The sailor from the camp football match (P3), later harbour security | Easy laugh, competent | The Navy, a friend from day 5 |
| **DR. OKONKWO** | Hospital doctor | Unflappable, kind, precise | Gus after the fire; Lali in M27 |
| **SHARON KOWALCZYK** | Marek's "house manager" | Flat Midwestern English, a smoker's cough, tired more than evil | The other side of the mediation mechanic |
| **The Trans, Salim, Mr. Delgado, Brenda (and Admiral the dog), Joy, Professor Halvorsen** | The town | See the scripts | The island's life; each comes back at least once |

## 7. The island: where the story goes
Every district in the city kit has at least one main mission and one side activity. Real street names follow the
kit (Amber Ave, Ocean Blvd, Orange-style arterial strip, the hill rows).

| District (city kit zone) | Main story | Side life |
|---|---|---|
| **Naval base / the gate (north)** | Prologue camp, release, the finale's radio call to the Navy | Ruth's office for check-ins |
| **The hill (residential rows, Hillside Park lookout)** | The house (Mrs. Finch's, upstairs flat with Theo). Home base | Finch's errands, the lookout at night (The Lights) |
| **Amber Ave high street** | Market, cafés, library (CV), cinema arcade (Theo's open mic) | Coffee, groceries, clothes, the post office |
| **City centre (towers, city hall, courthouse)** | Ruth's Act 2 check-in at the federal office; the trial in the courthouse | Priya's newsroom |
| **The strip (arterial)** | The police stop in mission 5; Benny's favourite diner | Gas, fast food, car shop |
| **Hospital and university** | Gus after the fire; Theo's night shift | Pharmacy errands; free conversation club at the university library |
| **Industrial docks** | Marek's warehouse (stealth), the *Good Hope* at the quay, the finale | Night delivery runs |
| **The gritty edge** | Marek's people live here; the pawn shop where your old watch ends up | Laundry, pawn, the 24h store |
| **Waterfront: pier and beach** | Gus's fish shack; the UFO stakeout; the Fourth of July | Fishing, swimming, the skate plaza |
| **The hero hotel (Amber x Ocean Blvd, south)** | Finale: the fireworks gala, where Marek's partner, the developer, is celebrated | Valet job (side) |
| **The Bridge (skyline only)** | Seen from everywhere; crossed only in the epilogue | — |

## 8. Structure
| Part | CEFR | Missions | Hours (est.) | Player's goal | Story question |
|---|---|---|---|---|---|
| Prologue: *Salt Water* | Pre-A1 | P1–P3 | 0.5 | Be released | Who are you? |
| Act 1: *Off the Boat* | A1 | 1–6 | 4 | Food, a roof, a job | Can you survive here? |
| Act 2: *The Debt* | A2 | 7–13 | 6 | Pay Marek, or escape him | Which way round? |
| Act 3: *Undertow* | B1 | 14–20 | 6 | Fight back: the ledger, the fire, the land deal | Who can you trust? |
| Act 4: *The Long Way Round* | B1+ | 21–25 | 5 | Save the next boat; tell the truth in court | Will they listen? |
| Act 5: *Open Water* | B2 | 26–31 | 5 | The storm, the hearing, a life | Who are you now? |
| Epilogue: *The Bridge* | — | E | 0.5 | — | — |

**Why five acts and not three:**
- The CEFR levels map onto the acts, so each act is a level of the hero's English and a level of their life:
  - **A1**: survive;
  - **A2**: get by;
  - **B1**: take part;
  - **B1+**: stand up;
  - **B2**: lead.
- The story's shape follows the learner's shape:
  - at A1 the hero can only react, so things happen *to* them;
  - at B2 the hero argues, persuades and saves others, so they make things happen.
- The plot never repeats itself, because the hero's power changes with each act. The same island is a different
  game at each level.

Between missions the city is open: side activities, jobs, money, food. Main missions unlock by story and by **time
of day** (a mission marker shows only in its hours), which makes the day planner (energy) a real choice.

### GTA-feel systems the story relies on
- **Mission markers.** Each main character has an icon on the map. A side quest is a smaller icon.
- **Status, not stars.** Police attention (from Marek jobs, reckless driving, fights) fills a **Status** meter
  instead of a wanted level. Being stopped means a conversation, not a shoot-out. The hero must talk their way out
  in English: name, address, what they are doing.
  - Fail the talk and you are taken to the station.
  - Too many stations and Ruth's case slows (a soft cost, never a game over).
  - Language is the escape button.
- **Driving.** From M8 (Theo's car, "Pickle"). Before that: on foot, bus, bike, Benny's taxi (fast travel with a chat).
- **Money.** Gus's shifts, deliveries, the side jobs and Marek's runs (big money, Status risk).
- **Mission failure.** A failed mission is retried from its last checkpoint. The story never punishes slow English:
  only actions fail.

## 9. Any player, any look
The hero is chosen in the prologue: face, body, hair, clothes and a voice for the inner thoughts.

**Rule 1: The hero's own lines are never gendered.** "I am {NAME}. I am a cook." Never "I'm a waitress" or
"I'm a man".

**Rule 2: Nobody's attitude to the hero depends on the look.**
- Benny says "boss".
- Theo says "roomie".
- Gus says "kid".
- Kai says "dude", which in his mouth means everybody.
- Mrs. Finch says your name, always in full.
- Marek's nickname is *"little fish"*: the same in every language and to everyone.

**Rule 3: Third-person lines about the hero use tokens** `{they}` `{them}` `{their}` `{they're}`, filled from the
look's pronoun choice (he / she / they; a free pick on the form, separate from the look).
- Lines with a token are marked ⚥ in SCRIPT.md. Voice actors record one take per pronoun.
- There are few of them by design: the hero is almost always spoken *to*, not *about*.

**Rule 4: No romance gate.** No storyline depends on attraction. Theo is a friend, the closest friend in the game.

**Rule 5: Danger is equal.** Marek's threat, the police, the fights: the same for everyone. We do not write a
softer or harder game for one look.

The inner voice (the hero's thoughts in italics) has two recorded narrator voices, lower and higher. The player picks
one in the interview, separately from the look and the pronouns.

## 10. Notes for implementation
- Lines in SCRIPT.md: `**SPEAKER** [emotion / delivery cue] "Line."`
  - `PLAYER:` = the player says it (voice check).
  - `PLAYER (think):` = the word-tile moment.
  - `(inner)` = the hero's recorded thought.
  - ⚥ = a pronoun token (one take per pronoun).
  - `MAREK*` / `LALI*` = recorded in each localisation language. The English text in SCRIPT.md is the meaning to
    translate, not English to record.
- Camera and music cue names (`MUS-xx`) match MUSIC.md.
- The old game's systems to keep and reuse:
  - camp / character creator;
  - TalkAnim;
  - the seat system;
  - the voice check (SpeechOut);
  - DrivingIntro;
  - the hospital lobby;
  - Jobs and Economy;
  - the delivery app.
- Rebuilt: the chapter order (chapters.json goes away; the new mission list is SCRIPT.md), the lesson-after-scene
  rhythm (gone), the Goo / alien chapters (folded into the comic thread *The Lights*, side strand S5).
