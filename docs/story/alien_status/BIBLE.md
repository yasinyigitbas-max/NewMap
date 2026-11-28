# ALIEN STATUS (working title): story and game bible

The old Coronado story, adapted to the new map and rebuilt as an open-world action game.

- **Version 1** (28 Nov) for Yasin's brief: "check coronado source and its story first, then adapt it to work with
  the map ... make it much more game like. this is an english learning game, but it shouldn't make it that obvious
  and play like a real and great game first."
- **Version 2** (28 Nov, this one) for his notes on version 1: "i want it to play much more like gta. with lots of
  cut scenes and animations everywhere ... Birds are cameras that follow us ordered by aliens, nutjob bird watcher
  npc who warns us about them, birds are unkillable and give you horror minigames when attacked. Truman show reveal
  if someone tries to leave the island by swimming away ... once in every 10 times, in every 9 times the attempt
  should end with being eaten by sharks. Car races. Hobby clubs with mini games. random npc encounter everywhere in
  every neighborhood ... also job minigames and alien dream past tense sentence scrambles must be in it. sprinkle
  them into the story, add much more action like gta and rework it."

Built from the old game's own story (coronado-source: `story/`, `i18n/strings.csv`, `data/`) and the new map as it
is built. The earlier drafts in `docs/story/` were not used.

Files:
- `BIBLE.md`: this file.
- `MISSIONS_1_PROLOGUE_CH1.md` ... `MISSIONS_4_CH4_EPILOGUE.md`: every story mission, with its cutscenes.
- `OPEN_WORLD.md`: work, races, clubs, strangers, the birds, the sea, the nightly dream, things to find.
- `CUTSCENES.md`: how cutscenes are made, the clips they use, the custom takes they need.

---

## 1. The pitch

You crossed a border with no papers. They caught you on the docks of an island, held you ten days in a camp on the
Navy base, asked you one question you could not answer (*"Who... are... you?"*) and let you out at the gate with a
phone, a room in a stranger's house and thirty days.

Your file says one word about you: **ALIEN.**

Forty light years away, two travellers called Orla and Zib read that word and believed it. On your third night in
Coronado a green light fills your bedroom. They do not want to hurt you. They want what you want: to get in. They
think you are the expert. Every night you tell them your day. They pay you in weapons.

So you have a city to survive and the tools to tear it up. A boss who fires you. A housemate with a locked room. A
loan shark who owns half the people you met in the camp. A Navy commander who has seen the green light. A man in a
van at the lookout who says the birds are watching you.

He is right about the birds.

## 2. The theme, in one line

**In the camp, English gave you orders. By the end, you give them.**

The first English you hear is commands (*Stop. Get down. Come here.*). The alien weapons obey the same words. The
last mission is the camp's morning sport flown in a spaceship. And there are two kinds of alien on this island
with the same problem: no papers, no words, a test coming.

## 3. What is kept from the old story

Same people, same order of events, same jokes. 300 and more of the old lines are used word for word (marked
`(old)` in the mission files).

| Old game | Here |
|---|---|
| Ink sketches p1–p10 | Prologue. The sketch *"The journey was long and hard"* is now followed by a playable run. |
| The camp: Grace, the guard, Omar, Lina, Yusuf, Mei, the fight with Ivan | One playable day (P3) |
| Interrogation = character creation | P4. Its question comes back at the end. |
| Day 10 at the gate, the officer, the fast taxi driver, *"on Uncle Sam"* | P5. The officer's *"we will test you regularly"* is the clock: days 20, 30, 40. |
| The flat, the flatmate, the tour, pizza or tacos, the locked room, the strange noise | 1.1, in the brick house on 10th St. The locked room has an answer. |
| CV, bus, the interview with silly answers | 1.2 |
| The café, QR pay, the friend (Mia / Leo) | 1.3 |
| ch1 drinks, ID under 21 | 1.4, now a bar brawl |
| ch2 first work day, the boss's rules, Sam | 1.5 |
| **The job minigames** (triage, beat shift, conveyor, spot the problem, sentence stack) | Every work shift, as they were (OPEN_WORLD.md) |
| ch3 the abduction, goo in the ears, the display of power, the deal, the puddle game over | 1.6 |
| **The alien dreams**: put the day in order, the past-tense sentence scramble with its trap tile, the right past form, *going to* | Every night, as they were. It is the save. |
| ch4 Goo school, *"Catch me!"* | 2.1, a rooftop chase |
| ch5 fired, the friend's call, the new job | 2.2 |
| ch6 the argument, the cut hand | 2.3 |
| ch7 the hospital drive, licence or no licence | 2.4 |
| ch8 *should*, the advice | 2.5, and the game's last choice |
| Taxi, hitchhiking, bus, delivery, ATM, shops, wardrobe, gym, cinema films, radio, library books, street talk, beggars | The open world |
| The 50 gold expressions | Things to collect and use |
| *"We put you back together. It took a long time."* | What Orla says every time you die |

**Gone from the story path:** forced lesson screens, *"Let me check my phone"*, *"Quick test!"* as a test, the red
flash. The lessons live in Goo School in the kitchen and are never forced.

**New:** chapters 3 and 4, made of what the old story left open. Three new people: **Commander Rhodes** (Navy),
**Vince Marlow** (the loan shark) and **Walter Finch** (the bird watcher). The birds. The edge of the sea.

## 4. How it plays

### 4.1 Rules of the house
1. **It is an action game.** A mission is: a cutscene, a drive, something that goes wrong, a fight or a chase, an
   escape, a cutscene. The island is open from the moment you leave the taxi.
2. **Chaos is allowed.** Take a car, start a fight, run from the police. The game does not punish you for playing
   it like GTA. Nobody on this island stays dead (see 4.6).
3. **English is the controller, not the subject.** You say a word and a thing happens. Nobody stops the game to
   teach you. No lesson screen, no quiz, no grammar score, anywhere on the story path.
4. **A wrong answer is a funny answer.** The world reacts and the scene goes on.
5. **Help is free.** Turkish under every line, always, for anyone who wants it.
6. **You are always ahead of someone.** The aliens, Ivan, the night class. What you survive by day you teach by
   night.

### 4.2 A mission
- Starts at a letter on the map. Givers: **H** housemate, **S** Sal, **F** the friend, **I** Ivan, **G** Grace,
  **O** the officer, **W** the bird watcher, **$** Vince, a green dot for the aliens.
- **Opens and closes with a cutscene**, and has one more wherever the mission turns. Cutscenes are short (20 to 60
  seconds), acted with the body clips we have, and always have something to look at besides talking: a car pulls
  up, a glass breaks, a bird lands. `CUTSCENES.md` has the rules and the clips.
- Small **in-world animations** carry the rest: getting in and out of cars, sitting, eating, phoning, paying,
  handing things over, pushing through a crowd. Nothing important happens to a character standing still.
- Ends on a card: bronze, silver, gold. Gold is style: *in time, no damage, first try, no help.* Replay from the
  phone.

### 4.3 Say It
- Every hero line is said into the microphone, as in the old game. Typing and tapping always work.
- What you say matters: jobs, prices, friendships and fights turn on which line you pick, not how well you say it.
- In action, speech is a button with a timer: *"Stop!"*, *"Sorry!"*, *"Left or right?"*, *"Get in!"*
- **"Slowly, please."** works on everyone, forever (Sal teaches it in the first ten minutes: the old
  *"Heywelcomebackbuddy!"* joke). Two people in the game refuse to slow down. They are the villains.
- **The map marks what you understood.** People say where to go. If you got it, go. If you ask, or Goo translates,
  you get the pin. Getting there without asking is the gold medal, never the pass mark.

### 4.4 Goo (from chapter 2)
The green jelly teacher of old ch4 stays. Most of Goo lives in the kitchen sink. A drop lives in your ear.
- **The translator.** The Turkish under the line and the old three kinds of help (tap a word, the whole line,
  *why is it built like that*) now have a voice: *"Blub. He says: where to?"* In chapter 1 the same help comes
  from the officer's phone app.
- **The progress bar.** Goo eats words you *use*. Goo grows from a spoonful to the size of a cat. Bigger Goo
  powers bigger alien kit (4.5). Nothing else in the game shows your level.
- **A bad teacher.** Goo was grown from the grammar app on your phone and teaches like one: *"Class is not
  over!"* **Goo School** (the old lessons) is always open and never needed.

### 4.5 The alien kit
Orla pays for your Reports in kit. All of it fires with a button, like any game. **Say its word as you fire and
you get the strong shot.** The words are the camp guard's.

| Kit | Button | Say the word | From |
|---|---|---|---|
| **Stopper** | freezes one person or car for 2 s | **"Stop!"**: 5 s, and everything near it | 2.1 |
| **Puddler** | a person becomes a green puddle for 20 s and comes back confused, with empty hands | **"Puddle!"**: a group | 2.5 |
| **Lifter** | pick up a thing and throw it | **"Up!" / "Down!"**: a car | 3.3 |
| **Hummer** | a push of sound: people fall over, glass breaks | **"Go away!"**: cars slide | 3.6 |
| **Shrinker** | a car or a person is toy-sized for 15 s | **"Small!"**: the truck too | 3.9 |
| **Goo bombs** | sticky green on the road: feet and tyres stay | **"Stay!"**: a whole junction | 4.2 |

Without a weapon in hand, four words still work: **"Open!"** (doors, gates, car doors, shutters), **"Look!"** (a
green blink that turns every head), **"Listen."** (hear through a wall or across a square), **"Come here!"**
(calls your car or bike). Late in the game: **"Puddle."** on yourself, to go under a door, and **bird view**.

Earth weapons exist too: fists, a bat, a wrench, a pool cue, a frying pan, and what you take from people who came
to hurt you (pistols from Vince's men, net guns and stun rifles from the Navy).

Kit leaves a green glow. Too much green fills the **Hum meter**, and the Navy comes.

### 4.6 Wanted, busted, wasted
The new game already has five stars, police cars, officers on foot and BUSTED. This adds the top end.

| Stars | Who comes | |
|---|---|---|
| ★ | an officer on foot | You can stop and talk: *"Sorry, officer." "I am going home."* Calm lines clear it. |
| ★★ | patrol cars | They chase. On foot they arrest. |
| ★★★ | more cars, blocking the road | |
| ★★★★ | the Navy: white vans, men in white with net guns | Also what a full Hum meter brings. |
| ★★★★★ | helicopters, the bridge shut, road blocks on the island ring | |

- **Lose them:** out of sight; indoors; a change of clothes; **Bayside Express Wash** (drive through, come out
  clean); under a door as a puddle.
- **Busted:** you wake on the bench in the Crownado Police Front Desk, lighter by $50 a star and without your
  kit until you next sleep. **Reyes reads the number out at your next check-in.** That is all.
- **Wasted:** black. Then Orla's voice: *"We put you back together. It took a long time."* `(old)` You wake in
  your bed, or in the Emergency Department with a bill.
- **Nobody dies.** Puddles re-form. The knocked down get up, or an ambulance comes (it already does). The aliens
  put you back together every time. There is a reason they take such care of you (4.9).

### 4.7 Cars
- **Take any car** (the game has it: the driver fights or runs). Park it in the alley garage at home and it is
  yours.
- **Ivan's list:** a board at Big Al's Tires with what he needs this week, in words: *a red pickup, a white van,
  a blue taxi*. Bring it in one piece.
- **Races** (OPEN_WORLD.md): bikes with the friend, taxis with Sal, night races with Ivan's crowd round the
  island ring. Your co-driver calls the road: *"Left! Hard right! Straight on!"*
- **Fix and clean:** Bridge Tire Pros, Junction Auto Glass, Ten Minute Lube, Bayside Express Wash, Shoal for fuel.
- **Driving with no licence** gets you a star if a patrol car sees you do something stupid. Sal fixes that in 3.2.

### 4.8 The birds
- There are always birds: gulls on the lamp posts, pigeons on the wires, a crow on the fence. **One to three of
  them are always where they can see you.** Their heads turn. Every cutscene in the game has a bird somewhere in
  the frame.
- **Walter Finch** tells you in chapter 1. Nobody believes Walter Finch.
- **You cannot kill a bird.** Hit one (a fist, a car, the Puddler) and it does not fall. The sound cuts. Its head
  turns all the way round. Its eye is green. Then you are somewhere else, in one of six **horror games**
  (OPEN_WORLD.md): the birds that only move when you look away; the street where the lights go out behind you;
  your own voice on the phone with the words in the wrong order.
  Get through and you wake where you stood, with a feather in your pocket. Fail and you are wasted.
- In chapter 3 you find out what they are: **the aliens' cameras.** That is how they *"know everything about
  you"* (old 1.6). After that the birds are a tool: **bird view**, a look at the street ahead from a wire.

### 4.9 The sea
- There is a line of buoys round the island. People tell you not to swim past it. *"Sharks."*
- Swim past it anyway. **Nine times in ten** the music stops, a fin comes round behind you, and you are eaten. A
  short, nasty cutscene. *"We put you back together. It took a long time."* `(old)`
- **One time in ten** no fin comes. You swim on. The water goes flat as glass. And your hand touches the sky.
  It is a wall, painted like a horizon. There is a ladder. There is a door.
- What is behind the door is in OPEN_WORLD.md, and it comes in three visits. In short: the island is real, the sky
  round it is not, the sharks are theirs, the birds are their cameras, and the nightly Report is a programme that
  goes out forty light years away. They are paying for the trip by showing you. Back home, a great many of them
  are learning English from it.
- You always wake in your bed afterwards. *"Huh? It's morning... Was it a dream?"* `(old)` Your clothes are wet.

### 4.10 The Report (the old alien dream, every night)
You sleep in your bed. The green light comes. Zib and Orla ask about your day `(old: "Hello, Earth friend! We are
Zib and Orla. Tell us about your day!")`. The game shows what you really did today, from its own log, and you play
the old dream:
1. **Put today in order** (the old event-ordering puzzle).
2. **The scramble:** build each sentence from word tiles and say it. The past form is in the tiles, and so is
   the trap: *"I taked a taxi"* is there to be chosen `(old: took / taked, bought / buyed, ate / eated ...)`.
3. **Pick the right past form** for one more.
4. From your second night: **tomorrow**, with *going to* `(old: "Tomorrow I am going to work.")`.
Orla answers `(old: "Wow! Tell us more!" "Interesting! On our planet we don't do that.")`. Zib writes it down,
slightly wrong. Goo eats. The game saves. A clean Report pays in kit charge and, at set nights, new kit.
**Every third night is a ship night:** a story mission.

### 4.11 Work, clubs, strangers
- **Work** is the old job minigames, two a shift, voice only, as they were. Late three times and you are fired.
- **Hobby clubs:** ten of them, each a place, a minigame, three ranks and a small story.
- **Strangers:** in every neighbourhood people stop you. They want a dollar, a push, a lift, a favour, a witness.
  Some of them are lying.
All in OPEN_WORLD.md, and each one turns up inside a story mission first.

### 4.12 The clock
- The gate is **Day 10** (old title card). Check-ins on days **20, 30, 40**. The calendar moves with the story and
  with sleep. You cannot lose by wandering.
- **Rent** is $400 every ten days from day 24 (the old *"the rent is in two weeks"*).

## 5. The people

Names, looks and voices follow the old game's table (`story/PHASE4_PLAN.md` section 5).

**YOU.** Made in the interrogation room: name, age, look, the job you had at home. Nobody genders you: Sal says
"buddy", Orla says "human". Starts silent; other people talk about you in front of you. Ends by standing up in a
courtroom and saying who they are.

**THE HOUSEMATE: Emma (if you are a man) or Jack (if you are a woman).** Old rule. A cook at Little Frenchy, loves
tacos and dancing, hates fish. *"Quick question!"* used to be a tic. Now it is a clue: the release office pays
hosts $90 a week to write a report on you, and the forms and a tape recorder are in the locked attic studio. The
strange noise at night is your own voice played back. {H} does it because {H} owes Vince Marlow.

**THE FRIEND: Mia (if you are a man) or Leo (if you are a woman).** Old rule. Works at the library, surfs. Wants
nothing from you. Bikes, the beach, the second job.

**GRACE.** The camp teacher; her voice is the phone lessons. *"In this world, you can talk to every person."*
Runs a free night class in the Christ Church Community Center. *"I made the app. The app is not a teacher."*

**IVAN.** Shouts at you in Russian on camp day 9, loses the fight: *"OK, OK! Sorry. We are friends?"* Night shift
at Big Al's Tires. Fifty words of English. Your muscle, your co-driver, your chop shop.

**OMAR, LINA, YUSUF, MEI.** The camp four. Omar cooks at the Shift Canteen, Lina irons at Adela Wash & Fold,
Yusuf plays in Tenth Street Park, Mei cleans at the hospital. All of them pay Vince.

**SAL.** Fifty. *"I drive this taxi every day. I love it!"* Too fast, kind, knows every street. Your first friend,
your driving teacher, the reason you learn *"Slowly, please."*

**OFFICER REYES.** *"Good luck. I really hope you make it."* He means it. Runs the Release Desk at City Hall.

**MR. DUNN and SAM.** The first boss (*"Welcome aboard!"* then *"You're fired."*) and the co-worker.

**ORLA and ZIB.** Old designs. Orla talks. Zib is silent, waves, writes everything down. Four-hundred-hour days,
always tired, one boring continent. *"Hollywood is wrong about us. No lasers."* (It is not a laser. It is a
Puddler.) They want to live here, legally. They have not told you how they are paying for the trip.

**GOO.** See 4.4. Says *"Blub."* Afraid of the plughole.

**WALTER FINCH (new).** Sixties. Was a radar man on the base for thirty years. Lives in a van at the Crest
Lookout by the bridge with a telescope, a wall of photographs and string. He says everything twice, the second
time slower, because nobody listens the first time. He is the easiest person on the island to understand, and the
only one telling you the truth. *"They don't blink. Count them. They don't blink."*

**VINCE MARLOW, "Uncle Vince" (new).** Owner of Payday Loans 4U in the gritty edge, and of the car pound next to
it. Lends to people who cannot read what they sign. Friendly, a hand on your shoulder, a pen already out: *"Sign
here, here and here."* His men carry bats, then worse. Chapter 3's villain.

**COMMANDER RHODES (new).** Navy, "Special Projects". Clean, friendly, quiet. Talks in fast idioms and smiles
while you are lost. *"Slowly, please"* does not work on him. He wants the ship. He offers your papers for it.
Chapter 4's villain, beaten slowly and clearly, in front of people.

**Smaller parts (old):** the camp guard, the barista, the bartender, the courier, the bus driver, the ER
receptionist, the doctor, Ms. Bell at the library, the driving examiner.

## 6. The places (all on the new map)

Names as written in the map data (`docs/INDOORS.md`; some signs say Crownado, some Coronado).

| In the story | On the new map |
|---|---|
| Where you land | The container depot and Bayline's truck court (industrial docks), at night; the base fence on Alameda Blvd |
| The camp, the interrogation room, the ship | Stage sets, ported from the old game |
| The base gate | Alameda Blvd at 4th St. Needs the kit's unused `lmk_navy_gatehouse`. |
| **Home** | The brick house on the hilltop, north side of 10th St (`player_home.json`). Hall, living room, snug, dining room, kitchen, office, bath; upstairs your attic bedroom, the attic bath and the **attic studio (locked)**. Garage on the alley. In the story: 15 Tenth Street. |
| First job | Hilltop Market, Hank's Diner, Casa del Mar Inn or Spokes Bike Repair (your pick) |
| The café, the bar | Trident Café; The Gull Tavern |
| Second job | Coronado Public Library |
| Hospital | Island Hospital: Emergency Department, Island Pharmacy |
| Check-ins; the hearing | City Hall Front Desk; Coronado County Courthouse, Island Legal Aid |
| Wake up busted | Crownado Police Front Desk |
| The first shoot-out | The courthouse block's parking garage |
| Sal | Ferry Landing taxi bay; the stadium's Tailgate Lot |
| Ivan | Big Al's Tires, the vacant lot (gritty edge) |
| Vince | Payday Loans 4U and its fire escapes, the car pound, Wagon Bank (commercial strip) |
| Finch | The Crest Lookout by the bridge; the old lookout tower at Amber Beach Plaza; Harbor Steel's water tower |
| Grace | Christ Church Community Center |
| The housemate's work | Little Frenchy |
| Rhodes's table | Overlook Cafe, Glorietta Ring Park |
| The rooftop chase | 10th St's gardens and garages down to the construction site at the city centre corner |
| Field trips | Amber Ave to Amber Beach Plaza; the stadium's fan plazas and Stadium Walk |
| The ship hides | Glorietta Bay, off the marina's fuel dock |
| They hold Goo | Coronado University: Science Building, the Quad, the campus garage |
| The last flight | The marina, under the bridge, round the island ring |
| Races | The island ring (Alameda, Ocean, Glorietta, 1st St), Crown Hill, the Tailgate Lot, J Ave in the docks |
| The edge | Past the buoys, anywhere |

## 7. The shape

| Part | Days | Missions | Hours | On the screen |
|---|---|---|---|---|
| Prologue: **They Caught Us** | 1–10 | P1–P5 | 0.8 | Get out |
| Chapter 1: **Make Yourself at Home** | 10–12 | 1.1–1.6, W1 | 3 | A room, a job |
| Chapter 2: **Forty Light Years** | 13–20 | 2.1–2.7, W2 | 3.5 | Keep the job. What is in the attic? |
| Chapter 3: **The Rent** | 21–30 | 3.1–3.11, W3 | 5.5 | Pay Vince. Then make Vince pay. |
| Chapter 4: **Make It** | 31–40 | 4.1–4.5, W4 | 3 | Get everyone home |
| Epilogue: **Day 41** | 41– | E1 | 0.2 | — |

42 missions, about 16 hours by the times written on them (not yet played). The open world is at least as much
again.

### The story in one paragraph each
- **Prologue.** The old sketches. Then you are over the side of a ship at night and running through a container
  yard with twenty others and the lights coming on. One day in the camp: the morning sport, the people, the fight
  with Ivan. A small room and a question. The gate. Sal's taxi, too fast, and a man who hits it.
- **Chapter 1: Make Yourself at Home.** A brick house and a housemate full of quick questions. A locked door. A
  thief on a bike with your dinner. A CV, a bus, an interview you can ruin for fun. A coffee, a friend, a race to
  the beach. A bar, a sailor, a pool cue, and the back gardens of 10th Street at a run. A first day at work, and a
  man in a van who says the birds are not birds. Then a green light at three in the morning.
- **Chapter 2: Forty Light Years.** A jelly in your bedroom says *school* and takes your badge across the roofs of
  the hill and up a building site. You lose the job. You get another one with a minute to spare and a bus that
  stops in mid-air. The attic door opens: thirty pages about you. The argument, the wine, the glass. A bleeding
  housemate, no licence and a patrol car. A doctor who says *should* nine times. Day 20, a tired officer, and a
  man in white in the corner. He has you followed. You meet his men in a parking garage, with a gun that turns
  people into puddles.
- **Chapter 3: The Rent.** Everything opens. Zib needs a jacket. Sal thinks you need a licence and a race. Ivan's
  car is in a pound that belongs to a man called Vince, who also owns your housemate's debt, Lina's laundry and
  Omar's trolley. The rent is short. You sign. You collect for him, you drive for him, you race for him, and he
  cheats, because it was in the small print. So you go in through his roof. Meanwhile there is something on top
  of the steel works that Walter wants you to see, and Commander Rhodes buys you a coffee.
- **Chapter 4: Make It.** The ship is too tired to stay up. It comes down in Glorietta Bay and two aliens move
  into the attic. Rhodes takes Goo. You take Goo back, out of a science building, with a night class as your crew.
  On the last night the Navy shuts the bay, your friends hold a fuel dock with frying pans and tyre irons, and
  somebody has to fly a ship that only obeys English. Under the bridge. Then: *should they stay or should they
  go*, and *who are you?*
- **Epilogue.** Day 41. Nobody is counting. Unless you swim out past the buoys.

## 8. What the game is quietly teaching

Never shown to the player. The old chapters' grammar is all still carried.

| Where | What it carries |
|---|---|
| Prologue | look / go / get down / jump; under, over; *I am*; name, age, job, address; *please speak slowly* |
| 1.1–1.3 | *there is / are*; rooms; *I like / don't like*; *Can I have, I'd like, Would you like*; *can / can't*; directions |
| 1.4–1.6 | past simple (*took, went, met*); *let's*; the time; orders; *usually / sometimes*; *it is / they are*; days, months |
| 2.1–2.2 | *have you ever*; comparatives; *why didn't you*; *going to* |
| 2.3–2.5 | present continuous; left / right / stop; telling what happened; *should / shouldn't* |
| Chapter 3 | *don't*; clothes, colours, sizes; *turn left at, behind, in front of*; numbers and money; food and amounts; *have to*; *want to* |
| Chapter 4 | all of it, fast; *because*; *it means*; telling your own story |
| Every night | the past simple, by scramble; *going to* |
| Every shift | the job's own words, by the old minigames |
| Every chase and race | left, right, straight on, stop, faster, slower: heard at speed |
| Every weapon | the imperative, shouted |

A1 is complete by the end of chapter 2 (where the old game stopped). Chapters 3 and 4 recycle it and reach into A2
only where the old game did.

## 9. Lines: the rules
- Old lines stay word for word wherever the scene survives (already translated, 177 already recorded).
- Hero lines: short A1. Never a line the hero could not build from what they have heard.
- Everyone else talks like a person, and says it again plainly when asked. Finch always says it twice.
- Gold expressions keep their tag and their list (`expr.*`).
- English with Turkish under it, everywhere.

## 10. What has to be built
1. **Places.** The gatehouse at Alameda and 4th. The camp, the interrogation room and the ship (ported sets). The
   attic studio dressed as the report room. Finch's van at the Crest Lookout. A way up Harbor Steel's water tower.
   The buoy line. **The sky wall** (a painted horizon, a ladder, a door) and **backstage** (a corridor, a control
   room): two small sets.
2. **People.** Orla, Zib, Goo. Rhodes and the men in white. Vince and his men. Finch. Grace, Ivan and the camp
   four in street clothes.
3. **Creatures.** Birds as real animated models that perch, turn their heads and follow (today they are sound
   only, to be confirmed). A shark (a fin, and one bite).
4. **Vehicles.** The housemate's car. Sal's taxi with a second brake. White Navy vans (the van, repainted). The
   book bike. The ship, flyable once.
5. **Systems.** Cutscenes (`CUTSCENES.md`). Mission cards and medals. Say It on top of CityTalk. Goo. The alien
   kit and the Hum meter. Stars four and five. Busted / wasted with Orla's line. Races with a co-driver's calls.
   The six bird horror games. The sea's one-in-ten. The calendar.
6. **Old systems this needs ported** (already on `docs/GAME_PORT_BOARD.md`): money and ATMs (10), jobs and the job
   minigames (11), lessons for Goo School (12), captions and dialogue (13), the alien dream and other minigames
   (14), the character creator (15).
7. **UI pages.** The host's forms (printed from your save), the CV, the release paper with three stamps, Vince's
   contract, Ivan's car list, the doctor's note, Zib's notebook, the backstage episode board.
