# FIRST GEAR: story bible
An A1 English game set on our Coronado. Written 20 Nov 2026 for Yasin's brief: "a story to teach English, covering each
topic of the CEFR A1 syllabus, using the existing assets and locations ... without being a good game first I don't think
it can teach well ... a story progression and a well designed, meaningful story and game."

Files:
- `BIBLE.md`: this file. The idea, the systems, the people, the places, the shape.
- `A1_SYLLABUS.md`: the full CEFR A1 checklist and the mission where each item is taught and comes back; the rules for
  every line the player says.
- `SCRIPT_1_PROLOGUE_ACT1.md`, `SCRIPT_2_ACT2.md`, `SCRIPT_3_ACT3.md`, `SCRIPT_4_ACT4_EPILOGUE.md`: every mission, beat
  by beat, every voice line.
- `SIDE_STORIES.md`: the open-world loops (fares, the diner, the plaques, karaoke, messages home) and their lines.
- `MUSIC.md`: the cues, and the songs with their A1 lyrics.

**How a voice line is written.** `ID SPEAKER [tone, feeling]: line`. The square brackets are for the renderer.
`YOU (say)` lines are spoken by the player into the microphone; they are also recorded once per hero voice as the
fallback when the player types or skips. `YOU (think)` lines are the hero's inner voice. `{NAME}` is the hero's name.
Lines about the hero that need a pronoun use `{they}`, `{them}`, `{their}` and are recorded once per pronoun choice.

---

## 1. The pitch
You come to Coronado for a summer job at a hotel. The job is gone before you put your bag down.

In a diner on Amber Avenue an old man in a good hat can't order his breakfast. Six weeks ago he had a stroke, and his
words are locked inside him. You have very few English words either. You point at the menu for him. He looks at you
for a long time and says one word: *"You."*

He is **Lou Brannigan**, 77. For thirty-five years he was the island's driving teacher. Half of Coronado learned to
drive in his green 1974 sedan, Bonnie, and every one of them remembers his two words: *"Slow down."* His granddaughter
hires you to drive him, because the doctors say he can't, and because Lou likes people who don't talk much.

So you drive him. To his speech therapy. To his breakfast. To the old lookout tower on the beach, every day at five
o'clock, for reasons he can't say. You learn English; he learns English again. You race each other for words.

And slowly the island tells you what Lou can't. That forty years ago, on the night of the Fourth of July, a bank van was
robbed on Amber Avenue, a young guard was hurt, and the getaway driver the police called *the Ghost* was never found.
That the man who went to prison for it is out now, and wants his money. That the guard still lives on the island. And
that Lou has been trying, for forty years, to give something back.

## 2. The theme, in one line
**Small words tell the truth.**

- The hero has small words because they are a beginner.
- Lou has small words because of the stroke.
- Duke, the villain, has the biggest, fastest English in the game, and he uses it to lie.
- The game's last scene is a confession made of A1 sentences: *"My name is Lou Brannigan. I was the driver. I took the
  money. I am sorry."*

The second theme is written on twelve brass plaques around the island, on things a stranger paid for over forty years:
**"For people who start again."** The player is one of those people. So is everyone who plays this game.

## 3. Why English is the story (and not a test on top of it)
1. **The hero and Lou are both beginners.** Lou's words come back at the speed the player's do. In Act 1 he says one
   word at a time; by Act 4 he says short, correct sentences. He is the one character the player always understands,
   because he speaks at the player's level. He is a mirror, a rival and a friend.
2. **The hero is Lou's voice.** Again and again Lou points, says one word, or the wrong word, and the hero has to say
   what he means to someone else: the pharmacist, the police, his granddaughter. This is CEFR *mediation* (passing on
   simple information for someone), and it is the game's most original verb.
3. **The hero's English is a key.** Every act opens new parts of the island and new people, because the hero can now
   ask, read and say new things.
4. **The climax is A1 English under pressure.** A kidnapping on the night of the fireworks, an emergency call (*"My
   name is {NAME}. I am at Amber Beach Plaza. A man has got my friend."*), and a car chase steered by listening to an
   old man singing directions down a phone, because singing is the one way his words still come out.

## 4. How the game plays (the systems)
Everything here uses systems the game already has: the microphone and `CityTalk` (say / type / skip), the walk-in shops
(`CityRooms`), the crowd (`CityCrowd`, with its fights, pushes and falls), cars with doors, the buses (`make_bus_lines`,
two loop lines), the phone and its apps, and the clock.

### 4.1 Voice is the verb
- The player says every `YOU (say)` line aloud. Typing and skipping always work, as in `CityTalk`.
- A line is never failed on grammar. If the meaning is clear, the NPC answers the meaning and, once, says the correct
  form back naturally (*"I is hungry." → "You're hungry? Me too!"*).
- After three tries the NPC understands from the hero's gesture. A voice check never blocks the story.

### 4.2 The Word Fog and Yasin's three tiers
- NPCs speak natural English. Words the player knows are sharp; words they don't are fogged.
- Tapping fog gives Yasin's tiers: **word** (that word's translation) → **sentence** (the whole line) → **syntax** (why
  it is built like that).
- **"Sorry?"** and **"Slower, please."** always work. The NPC repeats, slower and simpler. Every NPC has a slow version
  of their important lines (written in the scripts as `(slow)`).

### 4.3 The Nod (new: the pretending button)
- Next to the reply buttons there is always a quick **nod**: *pretend you understood.* It is faster, and often it is
  fine.
- But at some moments a nod has a cost: the wrong pills, the wrong bus, a missed clue. The cost is always small and
  always recoverable, and the scene that follows is funny or kind, never a punishment.
- It teaches the most useful A1 strategy there is (*ask, don't pretend*), and it carries the theme: the nod is a small
  lie, Lou's secret is a big one, and Duke's whole life is one.
- The game counts nods quietly. In the epilogue, Lou knows: *"You nod. A lot. Me too. Forty years."*

### 4.4 WordBook (Dr. Rao's phone app)
Dr. Rao installs it on Lou's tablet and on the hero's phone in Mission 2. It holds:
- **The photo cards.** The player takes photos in the open world (the phone camera). Each photo becomes a word card in
  *both* books, the hero's and Lou's. Lou's therapy literally uses the pictures the player brings him. Dr. Rao asks for
  photos by topic ("Lou needs food words this week. Bring me twelve.").
- **Lou vs You.** Both word counts, side by side. Lou is a fierce rival; he wins some weeks.
- **The lessons.** When a structure has been met three times in the story, its lesson page opens (a short screen, a
  voice drill), as Yasin designed for Pocket. Never forced.
- **The Five Cards.** Yasin's five-question practice test (scrambled sentences plus voice), offered after each mission.
  Optional; it gives a small money bonus from Tess ("for good work").

### 4.5 Thinking moments (Yasin's word tiles)
At two or three dramatic peaks a mission, time slows and the words of the hero's next line float. The player orders
them and says them. A wrong order is said out loud, and the world reacts in character (a laugh, a frown, danger), and
the player tries again.

### 4.6 Bonnie and the Ghost's Rules (driving as progression)
Bonnie is Lou's 1974 sedan: green, heavy, no GPS, a cassette player, a roof sign in the garage (*LOU'S DRIVING SCHOOL*).
Lou won't let the hero use the phone's map in his car (*"No. Look."*), so the hero reads street signs and asks the way.
Lou teaches seven rules across the game. Each is a driving skill and an A1 lesson in imperatives:

| Rule | Lou says | The skill | Taught in |
|---|---|---|---|
| 1 | *"Slow. Down."* | smooth driving: a calm bar that fills when you drive gently, and empties at every hard brake (Lou grips the door) | M1 |
| 2 | *"Look. Left. Right."* | junctions: the mirrors and head-turn; Lou's late "Left!" calls are a listening game | M1 |
| 3 | *"Keys. Always. Take. Keys."* | a running joke (Lou takes every key he sees) that pays off in the finale | M8 |
| 4 | *"Turn. Now!"* | the Ghost Turn (a tight handbrake turn) | M8 |
| 5 | *"Lights. Off."* | night driving with the lights off; harder to see, harder to be seen | M12 |
| 6 | *"Bus. Hide."* | the Bus Trick: drive in a bus's shadow to break a follower's view (the buses are real, on their two lines) | M12 |
| 7 | *"Fast. Now. Fast."* | full speed. Lou has not said *fast* since his daughter died on the bridge in 2012. He says it once, in M19. | M19 |

A *Park and Wait* trick (hide among the cars on a level of the 11th St parking garage) is the hero's own idea in M12.

### 4.7 Being Lou's voice (mediation scenes)
A mediation scene has two halves:
1. **Understand Lou.** He points, gestures, says a word, often the wrong word. The player picks what he means from two
   or three readings, or asks him (*"The blue pills? Or the white pills?"*).
2. **Say it for him.** The player tells the other person, in A1 English (*"He takes the blue pills at nine."*).

A wrong reading plays out (Lou gets a bag of fish food instead of a fishing magazine). It is always recoverable.

### 4.8 The open world between missions
Every day has a morning, an afternoon, an evening and a night on the game clock. Missions open at set times; the rest is
the island. The loops (lines in `SIDE_STORIES.md`):
- **Lou's Rounds:** Tess's shopping lists, in real shops (the market, the pharmacy, the post office, the barber, the
  laundry). Reading lists, prices, change.
- **Hank's Breakfast Rush:** mornings at Hank's Diner; listen to orders, say them back, give change. Money and tips.
- **Lou's People:** fares for Lou's old students and friends, who still call him for rides. Four people, three rides
  each, each a small story with its own A1 topic.
- **The Friend's Gifts:** twelve brass plaques around the island. Each is an A1 reading text and a person who remembers.
  Finding them changes the epilogue.
- **Thursday Karaoke** at The Crown & Anchor: Yasin's A1 songs, sung into the microphone.
- **Nico's Challenges:** an eleven-year-old's races and dares at Ocean Park Skate (bikes, imperatives, numbers).
- **Messages Home:** texts to the person the hero left behind, at the end of each act and any time. A1 writing with
  word tiles or typing; the replies are A1 reading (they write in English because the hero asked them to).

### 4.9 Needs and money (light)
- The hero starts with $60. Tess pays $200 a week plus the spare room and food. The diner and the fares pay extra.
- Lou's pills are at 9 a.m. and 9 p.m.; his energy runs down over a day out (plan the route, or he falls asleep in the
  car and snores, which is a joke, not a failure).
- Sleep is the save. Needs never interrupt a cinematic or a climax.

### 4.10 Choices (few, and they matter)
| # | When | The choice | What changes |
|---|---|---|---|
| 1 | M10 | Duke offers $500 for "a little information" about where Lou goes. Take it, or say no. | Take it: in M12 Duke phones during the stakeout and the hero must lie to him in the present continuous ("I'm sleeping"); Tess finds out in M16 and the hero must say sorry. Refuse: Duke has Troy follow the hero instead, a harder tail in M12. |
| 2 | M14 | Tell Peg about the song, or keep Lou's secret. | Tell: Peg comes to the tower on the Fourth knowing; her line in M20 is quiet. Keep: she learns it on the dock; her line is a shock. Either way she comes. |
| 3 | M15 | After the flashback: push Lou to tell Tess today, or let him wait. | Duke tells Tess that night either way; but if the hero pushed, Tess knows it in M16 ("You told him to tell me. Thank you.") and forgives the hero first. |
| 4 | Epilogue | Stay on the island, or take the bus home on the 31st of July. | Two endings, both complete. |
| — | Always | The Nod. | Small comic or kind costs; Lou's line in the epilogue. |

## 5. The people
Every main character has a want (what they chase), a need (what they really lack), a wound, a contradiction, and a
relationship to words. That last one is the game's spine.

### YOU ({NAME}), the hero
- **Made by the player** in P2 (the hotel's staff badge is character creation: name, spelling, age, country, look, a job
  from home, and two choices: *why are you here?* and *who do you write to?*).
- **Why are you here** (three answers, A1): *"I want to work." / "I want to help my family." / "I want a new life."*
  Each colours three lines (P2, the low point in M15, the epilogue).
- **Who do you write to** ({HOME}): mum, dad, grandmother, grandfather, a brother, a sister or a best friend.
- **Wound:** in their own language they are funny, quick, someone. In English they are a child again: slow, quiet,
  invisible. *"In my language I am me. In English I am nobody."* (Act 2, said to Lou.)
- **Flaw:** they nod. They pretend to understand rather than look stupid.
- **Want:** money, a job, to survive the summer.
- **Need:** to accept being a beginner, and to speak anyway: small, wrong, true.
- **Arc:** silent and ashamed → Lou's voice → their own voice. In the epilogue they stand on a stage and say who they
  are, in A1 English, to four hundred people.
- **Never gendered.** Nicknames are neutral: Lou says "kid", Hank says "chief", Nico uses the name, Duke says "friend",
  Peg always says the full name.

### LOU BRANNIGAN, 77: the old man in the good hat
- **Then:** born on the island in 1949; his father was a fisherman who drowned. He left school at fourteen, a mechanic
  and the fastest driver on the island. In the 1970s and 80s he drove getaway cars for his childhood friend Duke, who
  had protected him from bullies when Lou was seven. The police called the driver *the Ghost*: they never saw his car.
- **The night:** the Fourth of July, 1986. The Amber Savings Bank van job, during the fireworks. Duke hit the young
  guard with his gun, hard. Lou, instead of driving to the meeting place, put the bleeding guard in Bonnie's back seat,
  drove her to Island Hospital, sang to her all the way to keep her awake, and left her at the emergency door. Duke and
  the third man waited for a car that never came, and were caught. Lou drove away with the bag.
- **After:** he never spent a dollar of it on himself. He became the island's driving teacher (his first student, in
  1987, was a young woman who was afraid of cars after an attack: the guard. She never knew). For forty years he gave
  the money away in secret, to things the island needed, with the same brass plaque every time: *"For people who start
  again. — A friend."* He married Rose, a singer; she died in 2009. His daughter Annie died in a crash on the bridge in
  2012, and Lou, who had taught her to drive, never said *fast* again. He raised his granddaughter Tess.
- **Now:** a stroke six weeks ago. Broca's aphasia: he understands almost everything and can say almost nothing. One
  word at a time; sometimes the wrong word (*fish* for *boat*). What still comes out whole: counting, the days of the
  week said in a row, swearing (kept clean: *"Oh, for crying out loud!"*), and singing. Right side weak; a cane.
- **Personality:** proud, funny, sharp-dressed (the hat), impatient with himself and endlessly patient with others.
  Chews mints. Takes every key he sees (an old getaway driver's habit he can't explain). Furious at his body. Gentle
  with children.
- **Want:** to stay in his house, and to finish something on the fortieth Fourth of July: give back what is left, and
  tell the guard the truth.
- **Need:** to accept help, and to say the truth while he still can (the stroke was a warning).
- **Fear:** dying with the lie; Tess hearing it from someone else.
- **Contradiction:** the fastest driver on the island is the man who has said *slow down* for forty years.
- **His words by act** (the player's level, and a little below):
  - Act 1: single words. *"Eggs." "You." "No!" "Keys."*
  - Act 2: two or three words. *"Duke. Bad. Money." "Here. July. Four."*
  - Act 3: short broken sentences. *"I go there. Every day. Five o'clock."*
  - Act 4: short correct sentences, slowly. *"I was the driver. I am sorry."*
- **Voice:** warm gravel; a singer's chest voice; every word costs him something, and the actor must let us hear it.

### TESS BRANNIGAN, 25: the granddaughter
- **Then:** her mother Annie died on the bridge when Tess was eleven. Lou raised her. She grew up fast and in control.
- **Now:** a night-shift nurse in Island Hospital's Emergency Department, studying for an exam online in the mornings
  instead of sleeping. Fridge notes, lists, alarms: the house runs on her handwriting (the player's reading material).
  She can't drive, and doesn't say why (the bridge). She takes the bus.
- **Want:** keep Lou safe; keep the house. The hospital bills are $38,000 and the bank, Hill Savings, wants $38,000 by
  the first of July or the house is sold.
- **Need:** to let people in; to see Lou as a man and not a patient; to forgive.
- **Contradiction:** a nurse who can't look after her own; a planner with no plan for herself.
- **Arc:** control → betrayal (Duke tells her who Lou was; she throws the hero out) → forgiveness → letting the town
  help. In the epilogue she takes her first driving lesson, from the hero, in Bonnie.
- **With the hero:** boss → flatmate → sister. Never romance. In the end: *"You are family. Sorry. You are family.
  Don't argue."*
- **Voice:** quick, tired, dry; she talks fast, then catches herself and slows down for the hero (*"Sorry. Slow. I'm
  tired."*). The slow versions of her lines are where her warmth is.

### PEG OYELARAN, 70: the crossing guard
- **Then:** in 1986, thirty years old, a security guard on the bank van, the first in her family with a uniform job.
  Hit on the head; she woke in the ER, and a nurse told her *"a man brought you in. He was singing."* After that she
  was afraid of cars. In 1987 she saw a newspaper ad, *free lessons for people who are afraid to drive*, and learned to
  drive again with a patient, quiet man called Lou. Then she joined the police, made detective, and chased *the Ghost*
  for thirty years. Her son is a Navy officer on the base. Widowed. Retired five years ago.
- **Now:** a volunteer school crossing guard at Hilltop Elementary every morning and afternoon, with her STOP paddle
  and her whistle (*"I like the children. And I like to watch the street."*), and two days a week at the police front
  desk.
- **Want:** to close the case: who was the Ghost, and who saved her. She half believes they were the same man.
- **Need:** to learn that the second question was always the one that mattered.
- **Contradiction:** the most rule-bound woman on the island has carried one unofficial case for forty years. She has
  always liked Lou. She has always watched his car.
- **Arc:** watcher → hunter → the woman in Bonnie's back seat again, listening to a tape. Mercy. Friendship.
- **Voice:** slow, exact, police-clear. She is naturally easy for a beginner to understand, and she knows it.

### DUKE HALLORAN, 79: the old friend
- **Then:** Lou's protector when they were boys (*"I was nine. You were seven. Remember?"*). The crew's boss. Caught
  on the Fourth of July 1986 because his driver never came. Thirty-eight years in prison; out two years ago, with
  nothing: no family left but a grand-nephew, no money, a body that hurts.
- **Want:** "his share". Deeper: to make Lou say, out loud, that he betrayed him; to matter to someone.
- **Need** (which he never meets): to accept that his life was his own choice.
- **Contradiction:** he loves Lou and hates him, and both are true.
- **With words:** the fastest, richest, most idiomatic English in the game, and the thickest fog. He uses words as
  tools and as weapons. His crowning move is not violence: he tells Tess the truth about her grandfather, in the
  cruellest way, at work, at three in the morning. The only times he speaks plainly, he is telling the truth: *"I was
  nine. You were seven. I helped you."*
- **End:** on the dock, he opens the bag and finds no fortune, only a notebook of forty years of gifts. *"You gave it
  to strangers."* Lou: *"To people. Starting again."* Duke: *"I'm starting again! Me! Where's mine?"* He is arrested.
  In the epilogue, a letter from prison, in very simple words: *"Lou. Sing it for me. Duke."*

### TROY HALLORAN, 34: the nephew
- Duke's grand-nephew. Runs nights at Big Al's Tires on the gritty edge. Owes Payday Loans 4U more than he earns. A
  single father; his daughter Kayla, six, crosses the road every morning with Peg.
- **Want:** money, fast, for Kayla. **Need:** to stop letting Duke decide who he is.
- **The thing nobody knows:** in 2009 Lou taught him to drive for free, because he was seventeen and had nothing.
- **Arc:** the man in the garage at night (M5) → the man holding a little girl's hand (M6) → the father whose lost
  daughter the hero finds at the parade (M17) → on the dock, the man who will not hurt Lou: *"He taught me to drive,
  Uncle Duke. Free. I had nothing. He taught me free."*
- **Voice:** a mumble, slang, tired; very kind to Kayla.

### DR. ANITA RAO, 41: the speech therapist
- From Bangalore; came at twenty-two to study; English is her third language (after Kannada and Hindi). Lou's speech
  and language therapist at the Bayview Wellness Center in Island Hospital: a room with a brass plaque on the wall.
- Her teaching *is* the game's classroom: picture cards, *look, listen, say it again*, *mistakes are good*. She models
  classroom English (*"How do you say...? What does ... mean? Can you spell it?"*).
- **Wound** (one scene, M11): her father had a stroke in India four years ago, and she was here. *"Lou is not my
  father. I know. But."*
- **Function:** the diegetic teacher; WordBook; the Five Cards. In the epilogue she phones her father, in Kannada, and
  says to the hero: *"Every language is a home. You have two now."*
- **Voice:** clear, warm, a light accent, endlessly encouraging, firm.

### HANK DELGADO, 54: the diner
- Owner of Hank's Diner on Amber Avenue. Loud, a gossip, the high street's living newspaper. At sixteen, in his first
  lesson with Lou, he drove into the diner's window. *"I liked it here. Later I bought it."* Lou's stool has a
  *RESERVED* sign that Hank made himself.
- Lonely since his divorce; the diner is his family; chains are killing it. Gives the hero morning work (the
  Breakfast Rush). In Act 4 he closes the diner on the busiest day of the year to help.
- **Voice:** fast, warm, loud; the hero's first real test of *"Slower, please."*

### ROSA ALVAREZ, 47, and NICO, 11: the taqueria
- Rosa owns Rosa's Taqueria on Amber Avenue. Came from Oaxaca at nineteen *"with ten words."* Lou taught her to drive
  in 2000: *"He spoke no Spanish. I spoke no English. He was my best teacher."* Tough love for the hero: **"Speak. Bad
  English is English."** (the hero hears it again in their head at the climax).
- Nico, her son: a skater at Ocean Park Skate, bilingual, cheeky, corrects the hero bluntly (*"It's 'I am', not 'I
  is'."*). He is a little ashamed of his mother's accent, a true immigrant-kid feeling. Watching the hero struggle and
  speak anyway changes how he sees her. In the epilogue: *"This is my mum. She speaks three languages. I speak two."*
- **Voices:** Rosa: fast, warm, Spanish in the gaps. Nico: a kid's speed, very clear, merciless.

### MARISOL VEGA, 48: the bus driver
- Drives Line 1. Learned with Lou at seventeen. The first person the hero meets (P1), the voice of timetables and
  directions (M9), and in the finale she parks her bus across a road (M19).
- **Voice:** a professional announcer's English, then a laugh.

### Smaller parts
| Who | Where | What they carry |
|---|---|---|
| **Mr. Prewitt**, 60 | Casa del Mar Inn | The apologetic manager who takes your photo for a badge for a job that is gone (P2) |
| **Mr. Ilić**, 74 | Gold & Pawn | An old fence who knew Duke and Lou in 1986; buys Lou's watch; tells the legend of the Ghost for a price (M10) |
| **Mr. Feld**, 72 | Coronado Public Library | The librarian, deaf in one ear, speaks loud and slow (a gift to beginners); the newspaper archive (M13) |
| **Kayla**, 6 | Hilltop Elementary | Troy's daughter; lost at the parade (M17) |
| **The pharmacist** | Ninth Street Pharmacy | The first mediation scene (M3) |
| **The desk officer** | Crownado Police Front Desk | Bored, until Peg takes over (M6) |
| **The 911 operator** | the phone | Calm, slow, trained (M18) |
| **Lou's People** | all over | Mrs. Grace Kim, 84, swims every morning; Mr. Arun Banerjee, 80, visits his wife's bench; Gloria Santos, 22, a Navy wife learning to drive; Coach Dunn of Hilltop Elementary (`SIDE_STORIES.md`) |
| **Clutch** | Lou's house | Lou's old grey cat (pets, M1) |
| **Rose** (died 2009), **Annie** (died 2012) | photos; a 1979 poster in The Crown & Anchor; Rose's recorded song | The dead who are present |

## 6. The places (all already in the city)
"Placed" means the building or room is in our city kit now. The file named is where it is listed.

| Story place | Where in our city | Missions | Status |
|---|---|---|---|
| The bus over the bridge; the arrival | The bridge approach and ramp (`s_br_appr`, `s_br_ramp`), Island Transit Center (`n_hp_transit`, room in `assignment_hp.json`) | P1, M9, E | Placed |
| The hotel and the lost job | **Casa del Mar Inn** (waterfront, `assignment_wf.json`) | P2 | Placed room |
| The diner | **Hank's Diner** (high street, Amber Ave, `b_ne`) | P3, M4, side | Placed room |
| **Lou's house** | The cedar craftsman house with the picket fence and the detached single garage: the first lot east of the alley, north side of 10th St on the hill (pilot `r_n`, `site.gd` LOTS row 1: `houses/craftsman_cedar` + `garages/single_siding_comp`). Two minutes from the diner, the school and Hillside Park. Any hill-row house with a detached garage works if Yasin prefers another. | M1 on | **House placed; the interior and the garage interior are new** (section 8) |
| The school crossing | **Hilltop Elementary** (`n_hs_b5_school`), on 10th St's hill | M1, M6, M14, side | Placed |
| Speech therapy | **Bayview Wellness Center**, Island Hospital (`assignment_hp.json`) | M2, M11, M15 | Placed room |
| The hospital | **Island Hospital Main Lobby**, **Emergency Department** (and its night door), the healing garden on the bay (`n_hp_main`) | M2, M15, M16 | Placed rooms |
| The care home | **Bayview Care Residences** and their garden court (`n_hp_west`) | M16 | Placed (garden court, outdoors) |
| Errands | **Hilltop Market**, **Ninth Street Pharmacy**, **Coronado Post Office**, **Hill Savings** (high street, `assignment_hs.json`) | M3, M10 | Placed rooms |
| The taqueria | **Rosa's Taqueria** (high street) | M4, side | Placed room |
| The tower | **Amber Beach Plaza** and its old **lookout tower** (`n_hs_b3_amber`, `lmk_beach_lookout`) | M5, M18 | Placed; **the tower's base room is new** |
| The police | **Crownado Police Front Desk** (civic, `v_se`) | M6 | Placed room |
| Duke's bar | **The Anchor Inn** (gritty edge, `assignment_grt.json`) | M6, M10 | Placed room |
| Troy's work | **Big Al's Tires** (gritty edge) | M6, M12 | Placed room |
| The pawn shop | **Gold & Pawn** (gritty edge) | M10 | Placed room |
| Payday Loans 4U | gritty edge | M12 (Troy's debt) | Placed room |
| The bank of 1986 | **Amber Savings Bank** (city centre, Amber, `assignment_cc.json`) | M9, M15 | Placed room |
| The driving lessons | **Island Hospital visitors' car park** (7 rows), the **11th St parking garage** (`n_hs_b1_eleventh`) | M8, M12 | Placed |
| The skate plaza | **Ocean Park Skate** (high street block 4) | M8, side | Placed |
| The bus line | the two bus lines (`CityTraffic::make_bus_lines`), stops and shelters | M9, M12, M19 | Placed / running |
| The rain fares | everywhere; **Crown Hill Community Center**, **Seventh Street Community Church**, **Ridge Senior Center** | M10, side | Placed rooms |
| The karaoke bar | **The Crown & Anchor** (high street) | M11, side | Placed room; Rose's 1979 poster is a new decal |
| The stakeout | Big Al's Tires; 4th St; **Harbour Boatworks** (waterfront) | M12 | Placed |
| The library | **Coronado Public Library** (high street block 1, its plaza and jacarandas) | M13 | Placed room |
| Peg's lookout | **Hillside Park** lookout terrace (`n_hs_b5_hill`) | M14 | Placed |
| The realty office | **Ocean Realty** (high street) | M15 (Tess and the sale papers) | Placed room |
| The Fourth of July | Amber Ave (the parade), the fireworks over Glorietta Bay, Amber Beach Plaza | M17, M18 | Placed |
| Urgent care | **Bay Medical Plaza Urgent Care** (`n_hp_west`) | M17 | Placed room |
| The chase | the whole island; Fire Station 2 on 11th St (`n_hs_b5_eleventh`), the red-spire church's bell, the bridge ramp | M19 | Placed |
| The dock | **Harbour Boatworks** and the marina floats (waterfront) | M20 | Placed |
| The concert | **Villager Theatre** (high street, `lmk_village_theatre`, venue room) | E | Placed room |
| The clothes | **Tide Threads** (high street block 1) | E | Placed room |

The island opens with the story: Act 1 is the high street and the hospital; Act 2 adds the civic centre, the city
centre and the gritty edge; Act 3 adds the industrial docks, the waterfront and the library's past; Act 4 is all of it at
night.

## 7. The shape
| Part | A1 stage | Missions | Dates (2026) | Hours | Goal on screen |
|---|---|---|---|---|---|
| Prologue: *Arrivals* | Starter | P1–P3 | Mon 1 June | 1 | Find a job |
| Act 1: *First Gear* | A1.1: me, my home, things, food, my day | M1–M5 | 2–7 June | 5 | Drive Lou. Learn the house. |
| Act 2: *The Ghost* | A1.2: people, family, the town, ability, the weather | M6–M10 | 8–20 June | 5 | Who is Duke? |
| Act 3: *Lights Off* | A1.3: free time, now, the past of *be*, a little past | M11–M15 | 21 June–3 July | 5 | What happened in 1986? |
| Act 4: *The Last Drive* | A1 review under pressure | M16–M20 | 3–4 July | 3.5 | Give it back. |
| Epilogue: *For People Who Start Again* | review; writing | E1–E3 | 5–31 July | 1 | — |

Plus the open world: about 8 hours of side stories, plaques, fares, karaoke and the diner, all recycling A1.

### The story in one paragraph per act
- **Prologue.** The bus over the bridge. A hotel badge for a job that is gone. A diner, an old man who can't order,
  and a job: drive him.
- **Act 1: First Gear.** The house, the cat, the car under its cover. Speech therapy, where Lou and the hero learn
  together and a brass plaque says *for people who start again*. Errands, where a charming old man called Duke makes Lou
  drop the eggs. Lou goes to the beach tower every day at five, and a crossing guard called Peg is always watching.
  Then a man breaks into the garage at night. Lou's first three words: *"Duke. Bad. Money."*
- **Act 2: The Ghost.** The hero describes the man to the police; Peg listens. The man is Troy, Duke's nephew, and he
  holds his little daughter's hand. A photo album: Rose, Annie, and a 1986 photo of three young men. Lou's driving
  rules. Lou runs away on a bus and is found staring at the door of Amber Savings Bank. In the rain, a pawn dealer
  tells the legend of the Ghost, and Duke offers the hero money. The bank wants $38,000 by the first of July.
- **Act 3: Lights Off.** Lou can sing what he can't say; at karaoke he sings his dead wife's song, and Peg goes white.
  A stakeout: Duke is buying a boat. In the library, a newspaper from the fifth of July 1986: the guard's name was
  Margaret Oyelaran. Peg tells her story: *"He was singing."* Lou tells his, and the player drives it: the night of
  the Fourth, 1986, a young man racing a bleeding stranger to the hospital, singing. The hiding place is the tower. And
  that night Duke tells Tess everything. She throws the hero out. The hero sleeps in Bonnie.
- **Act 4: The Last Drive.** The hero carries Lou's small words to Tess, and she listens. On the Fourth of July the
  hero asks everyone Lou ever taught for help. At the tower, under the fireworks, Duke takes Lou and the bag. An
  emergency call in A1. A chase steered by Lou's singing down a phone. A dock, a boat that won't start because Lou has
  the keys, a nephew who won't hurt the man who taught him free, and a confession in the smallest words in the game.
  Peg sits in Bonnie's back seat and listens to a tape of a young man's voice, forty years old.
- **Epilogue.** A concert at the Villager Theatre to save the house. The hero says who they are, on a stage. Lou sings.
  A letter from Duke. Tess's first driving lesson. The 31st of July: stay, or go.

## 8. What has to be built (short)
Everything else in the scripts is already in the city.
1. **Lou's house inside** (the main new interior, home base): hall, kitchen (the fridge with Tess's notes, two cups on
   hooks, Clutch's bowl), living room (the armchair facing the window, the photo album on the shelf, Rose's record
   player), Lou's room (ground floor since the stroke), the hero's spare room (Annie's old room: a single bed, a desk,
   a window over the alley), a bathroom.
2. **Lou's garage inside:** Bonnie under a grey cover; a workbench; a pegboard of tools; the roof sign *LOU'S DRIVING
   SCHOOL* on a shelf; forty years of calendars on the wall, every Fourth of July circled; an old radio.
3. **The tower's base room** at Amber Beach Plaza: a small round room with a stair going up, a bench, a loose board.
4. **Vehicles:** Bonnie (a green 1974 full-size sedan, chrome, bench seats, a cassette player); Bonnie in 1986 (the
   same car, new paint, for the flashback); a 1980s armoured bank van (flashback); Troy's black SUV (a black paint of
   an existing SUV).
5. **Character props:** Lou's hat and cane; Peg's STOP paddle, whistle and hi-vis vest; Tess's scrubs.
6. **Story props:** twelve brass plaques (one model, twelve texts); the Blue Bag (a faded blue canvas sports bag); the
   ledger (a brown notebook); Peg's 1986 guard badge; a cassette tape; the photo album; Lou's pill box (blue and white
   pills); the bank letter; the DRIVER WANTED card in the diner window; Rose's 1979 poster (a decal); Duke's boat (an
   existing moored boat at Harbour Boatworks).
7. **Two small characters:** Kayla (6) and Nico (11), if the crowd has no children's bodies.
8. **UI pages** (2D): the fridge notes, the newspaper of 5 July 1986, the timetable, the forms, the WordBook cards.
