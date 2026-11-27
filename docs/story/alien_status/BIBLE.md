# ALIEN STATUS (working title): story and game bible

The old Coronado story, adapted to the new map and rebuilt as a game. Written 28 Nov 2026 for Yasin's brief: "check
coronado source and its story first, then adapt it to work with the map ... make it much more game like. this is an
english learning game, but it shouldn't make it that obvious and play like a real and great game first."

Built from two things only:
- **the old game's own story** (coronado-source: `story/intro`, `story/camp`, `story/chapters/ch1..ch8`,
  `i18n/strings.csv`, `data/dreams`, `data/jobs`), and
- **the new map as it is built** (`docs/INDOORS.md`, `interiors/assignment_*.json`, `player_home.json`, the pieces).

The earlier drafts in `docs/story/` were not used.

Files:
- `BIBLE.md`: this file. The idea, what is kept, how it plays, the people, the places, the shape, what to build.
- `MISSIONS_1_PROLOGUE_CH1.md`, `MISSIONS_2_CH2.md`, `MISSIONS_3_CH3.md`, `MISSIONS_4_CH4_EPILOGUE.md`: every story
  mission, beat by beat, with the key lines.
- `OPEN_WORLD.md`: jobs, hustles, the nightly Report, Goo's growth, friends, things to find.

---

## 1. The pitch

You crossed a border with no papers. They caught you, held you ten days in a camp on the Navy base, asked you one
question you could not answer (*"Who... are... you?"*) and let you out at the gate with a phone, a room in a
stranger's house and thirty days: **find a job, keep an address, learn the language, stay out of trouble.**

Your government file says one word about you: **ALIEN.**

Forty light years away, two travellers called Orla and Zib are reading Earth's computers. They are looking for a way
in. They find a list of *aliens* who were allowed to stay, and at the bottom, the newest name: yours. So on your
third night in Coronado a green light fills your bedroom, and you wake up on a ship above the ocean.

They do not want to hurt you. They want what you want. They want to **get in**. And they think you are the expert.

So now you have two jobs. By day you survive Coronado: the bus, the boss, the rent, the housemate with the locked
room. By night you teach two aliens everything you learned that day. They pay you in alien tricks. The tricks run on
English, because every machine on Earth they listened to (planes, ships, phones) obeys English. **Say it, and it
happens.**

The Navy has noticed the green light. A man in a clean uniform has noticed *you*. And the day-forty hearing will ask
you the same question as the first day. This time you have to answer it.

## 2. The theme, in one line

**In the camp, English gave you orders. By the end, you give them.**

- The first English you hear is commands: *Look right. Get down. Stop. Come here.* (the old camp's days 1 to 5).
- The first trick the aliens give you is the same word turned around: you say *"Stop!"* and a car stops.
- The last mission is the camp's morning sport flown in a spaceship: *up, down, under, over,* by your voice.

The second theme is the joke in the title. There are two kinds of alien on this island and they have the same
problems: no papers, no words, a test coming. The hero is always one lesson ahead of somebody, so the hero is never
only a student.

## 3. What is kept from the old story (nearly all of it)

The people, the order of events and the jokes are the old game's. The table shows where each old part went.

| Old game | Here | What changed |
|---|---|---|
| Ink sketches p1–p10 ("I was cornered ... They caught us ... Now my new story starts.") | Prologue P1, P3 | Kept word for word. |
| The camp, 10 days: Grace, the guard, Omar, Lina, Yusuf, Mei, the fight with Ivan | Prologue P2, one playable day | Ten days of lessons became one day of play. The fight, the obstacle sport and "talk to everybody" stay. The letter and *am / is / are* tests are gone from the story path. |
| "Do you know English?" (skip the camp) | P2, first question | Now sets how much help you get. It skips nothing. |
| Interrogation = character creation | P3 | Kept. Its question comes back in the last mission. |
| Day 10 at the base gate: the officer, the apps, the fast taxi driver, "on Uncle Sam" | P4 | Kept. The officer's "we will test you regularly" is now the game's clock (days 20, 30, 40). |
| The flat: the flatmate (Emma / Jack), the tour, pizza or tacos, the locked room, the strange noise | 1.1 | The flat is now the brick house on 10th St (the new map's player home). The locked room finally has an answer. |
| Day 2: job hunt on the PC, CV (*can / can't*, "Can you drive?"), bus directions, the interview with silly answers | 1.2 | Kept. The interview's silly answers were already the most game-like thing in the old game. |
| The café, QR pay, the new friend (Mia / Leo, works at the library, surfs) | 1.3 | Kept. |
| ch1 drinks: the bar, ID if under 21, the friend drops in | 1.4 | Kept, plus trouble at the bar. |
| ch2 first work day: the alarm, the boss's rules, Sam | 1.5 | Kept. Being on time is now a real race. |
| ch3 the abduction: goo in the ears, the display of power, "teach us about your world", the deal, the puddle | 1.6 | Kept. The list of continents and months became a game played through the ship's glass floor. The puddle game over is untouched. |
| ch4 Goo school: *have you ever*, comparatives, "Catch me!", missed work | 2.1 | Kept. Goo's quiz is now physical: Goo grows and shrinks. The chase leaves the house. |
| ch5 fired, the friend's call, the new job | 2.2 | Kept. The call starts a race across town. |
| ch6 the argument, the wine, the cut hand | 2.3 | Kept. Now it has a reason: what is in the locked room. |
| ch7 the hospital drive, licence or no licence | 2.4 | Kept. The driving-school checklist became an emergency drive. |
| ch8 the doctor's *should*, the drive home, your advice | 2.5 | Kept. "What should I do now?" comes back as the game's last choice. |
| Alien dreams: every night you tell them about your day | The Report (the save) | Kept and made the core loop. |
| Home problems, jobs and job minigames, delivery, taxi, bus, ATM, QR | OPEN_WORLD.md | Kept as the open world. |
| The 50 gold expressions ("Break a leg", "It's on me") | Gold lines | Kept, now things to collect and use. |
| Game over when broke | Lose your key | Softer: you sleep rough until you can pay. |
| "Let me check my phone" lesson breaks, "Quick test!", red flash on a wrong answer | Gone from the story path | See section 4. The lessons still exist, in Goo School, and are never forced. |

**New, and why:** the old story stops on day 14 with nothing resolved. Chapters 3 and 4 are new, but they are made
of the old story's loose ends: the officer's tests, the rent "in two weeks", Grace's "maybe we will meet again",
Ivan's "we are friends?", the aliens who "come back every three days", the locked room. One new person was needed to
give the game an ending: **Commander Rhodes** of the Navy.

## 4. How it plays

### 4.1 Rules of the house
1. **A game first.** Every mission has something to do that is not answering: drive, run, climb, hide, deliver,
   fight, follow, fly.
2. **English is the controller, not the subject.** You speak to make things happen. Nobody stops the game to teach
   you. There is no lesson screen, no quiz and no score for grammar anywhere on the story path.
3. **Understanding is information.** The game never fails you for not understanding. It just gives you less: no map
   pin, a worse price, the long way round.
4. **A wrong answer is a funny answer.** The world reacts in character and the scene goes on. No red flash, no "try
   again" (the old interview already worked like this).
5. **You are always ahead of someone.** The aliens, Ivan, later the whole night class. What you survive by day, you
   teach by night.
6. **Help is free.** A beginner who needs Turkish under every line gets it, always. Skill is rewarded with style
   (medals, tips, respect), never demanded.

### 4.2 Say It
- Every hero line is said into the microphone, as in the old game. Typing and tapping always work too.
- Choices are shown as short lines. Say any of them. The answer matters: jobs, friendships, prices and fights turn
  on what you say, not on how well you say it.
- In action, speech is a button with a timer. Shout *"Stop!"* in a chase, *"Sorry!"* when you bump someone,
  *"Help!"* in a fight, *"Left or right?"* in a car.
- **"Slowly, please."** always works, on everyone, forever. The person says it again, slower and simpler, with
  their hands. Sal the taxi driver teaches it in the first ten minutes (the old "Heywelcomebackbuddy!" joke).
  One person in the game refuses to slow down. He is the villain.

### 4.3 The map marks what you understood
People tell you where to go in words (*"The bus stop is on Amber Avenue, at the corner of 9th Street"*: the old
flatmate's directions). If you got it, walk there. If you ask (*"Sorry? Where?"*), they point and the pin appears.
If Goo translates, the pin appears. Later missions lean on this: an address shouted once from a window, a number
plate, a time. You can always get the pin. Getting it without asking is the gold medal.

### 4.4 Goo (from chapter 2)
The aliens leave you a teacher: a green jelly called Goo (old ch3, ch4). In this version Goo stays. Most of Goo
lives in the kitchen sink of the house. A drop of Goo lives in your ear.
- **Goo is the translator.** The Turkish line under the English, and the old *word → sentence → why* help, now come
  from a character with a voice (*"Blub. He says: where to?"*). Before Goo, in chapter 1, the same help comes from
  the officer's phone app, which is slow and needs a free hand.
- **Goo is the progress bar.** Goo eats words. Every new word or line you *use* in the world is a snack. Goo in the
  sink grows from a spoonful to the size of a cat. Nothing else in the game shows your level.
- **Goo is the key to the tricks.** Bigger Goo, more tricks.
- **Goo is a bad teacher, and knows only one way to teach:** school. *"Class is not over!"* Goo was grown by the
  aliens from the grammar app on your phone, so Goo teaches like an app. The game's joke on itself: nobody learns
  like that, and the story proves it. **Goo School** (the old phone lessons, in the kitchen) is always open and
  never needed.

### 4.5 Tricks (alien tech that obeys English)
Small, physical and a bit silly, like the old ship scene (the green light, the hum, "I can't move!", the phone that
shakes itself, the puddle). You say the word and point. A button works too, at half strength.

| Goo size | You say | What happens | First used |
|---|---|---|---|
| 1 | **"Stop!"** | One person or one car freezes for three seconds. | 2.2, to hold a bus |
| 2 | **"Open!" / "Close!"** | A door, a gate, a car door, a shutter, from across the street. | 2.3, the attic door |
| 2 | **"Look!"** | A green light blinks where you point. Everybody looks. | 3.1 |
| 3 | **"Up!" / "Down!"** | A thing floats: a box, a bin, later a car a metre off the road. | 3.3 |
| 3 | **"Come here!" / "Go away!"** | Pull or push. Also calls your bike or car to you. | 3.2 |
| 4 | **"Listen."** | You hear through a wall or across a square. | 3.6 |
| 4 | **"Slow!" / "Fast!"** | Three seconds of slow or fast time, on foot or at the wheel. | 3.5 |
| 5 | **"Puddle."** | You are a green puddle for five seconds: under a door, under a fence, under a punch. | 4.2 |

- These are the camp guard's words (*stop, up, down, under, over, come here, look, listen*). The prologue makes you
  obey them. The game lets you use them.
- Tricks leave a green glow. People film it. Too much green in one place fills the **Hum meter**, and a Navy
  helicopter comes to look (the map already has them overhead). Then you hide the way you hide from the police.

### 4.6 Stars and strikes
The new game already has wanted stars, police on foot and a BUSTED arrest with a fine. For a normal game hero that
is a joke. For you it is the whole danger.
- **Busted = a strike.** It is written in your file. Three strikes before a check-in and you are back in the camp
  (the old *GAME OVER / Go back to your choice* screen).
- **Talk it down.** At one or two stars, stop, put your hands where the officer can see them, and talk: *"Sorry,
  officer." "I am going home." "Here is my ID."* Calm, clear, true lines clear the stars. At three stars or more
  nobody is listening.
- So the best players of this game are polite, fast and never caught. That is the hero.

### 4.7 The Report (the save)
You sleep in your bed. The green light comes. Orla asks about your day (old alien dreams, old deal: *"What you did.
Where you went. What you ate."*).
- The game shows what you really did today as small pictures: the bus, the taco, the fight, the fare. You pick three
  and tell them.
- Zib writes everything down and gets it slightly wrong. Orla asks one question back. The aliens give you
  **homework** for tomorrow: a photo of something, a taste of something, a word.
- Goo gets the day's snacks. The game saves.
- Every third night is a **ship night**: a story mission (the old "we come back every three days").

### 4.8 The clock
- The gate is **Day 10** (old title card). Your release runs to **Day 40**. Check-ins on days 20, 30 and 40.
- The calendar moves with the story and with sleep, not with the real clock. You cannot lose the game by walking on
  the beach.
- **Rent** is due on day 24 (the old "the rent is in two weeks") and every ten days after.
- A check-in is a boss scene: an address, a job, your strikes, and five minutes of talking about your own save file.

### 4.9 Missions, medals, map letters
- Mission givers are letters on the phone map: **H** housemate, **S** Sal, **F** the friend, **G** Grace, **I**
  Ivan, **O** the officer, a green dot for Orla and Zib.
- Missions open in strands, so there are usually two or three letters to choose from.
- Every mission ends on a card: bronze, silver, gold. Gold is always style: *first time, no help, no stars, in
  time.* Replay from the phone.

## 5. The people

Names, looks and voices follow the old game's table (`story/PHASE4_PLAN.md` section 5).

### YOU
Made in the interrogation room (P3): name, age, look, the job you had at home. Never given a gender by anyone:
Sal says "my friend" and "buddy", the housemate uses your name, Orla says "human" (and is told off for it).
- **Starts:** silent. Other people talk about you in front of you.
- **Flaw:** says *yes* to make a conversation end.
- **Ends:** stands up in a courtroom and says who they are.

### THE HOUSEMATE: Emma (if you are a man) or Jack (if you are a woman)
Old rule kept. Warm, loud, a cook who loves tacos and dancing and does not like fish or sport. Works the kitchen at
Little Frenchy on the high street.
- **The tic:** *"Quick question!" "Quick test!"* In the old game it was just how the flatmate talked. Here it is a
  clue.
- **The secret:** the release office pays hosts. Every week the housemate fills in a form about you: what you eat,
  when you sleep, what you can say. The forms, a recorder and a printer are in the locked attic studio. That is the
  strange noise at night: your own voice, played back.
- **The wound:** needs the money, likes you, hates the job, drinks about it.
- **Arc:** host → caught → the cut hand and the drive → writes the last report as a friend, and reads it out in
  court.

### THE FRIEND: Mia (if you are a man) or Leo (if you are a woman)
Old rule kept. Works at the Coronado Public Library, surfs every weekend, met in the café on your second day. The
one person who wants nothing from you. Gets you your second job. Teaches you the island: the beach, the bike, the
water.

### GRACE, the camp teacher
Always a woman, office clothes, the voice of the phone lessons (old rule: she *is* that voice). In the camp she
says: *"In this world, you can talk to every person."* That is the game's real instruction manual.
- Outside, she runs a free night class in the Christ Church Community Center, and the city is about to close it.
- She recorded the lessons on your phone years ago and is a little ashamed of them: *"I made the app. The app is
  not a teacher. People are teachers. Go and talk."*

### IVAN
The man who shouts at you in Russian on camp day 9, loses the fight, and says the first English sentence he knows:
*"OK, OK! Sorry. We are friends?"* Released a week after you. Works nights at Big Al's Tires. His English is the
camp's fifty words and no more, so the two of you plan everything in fifty words. Loyal, enormous, bad at quiet.

### OMAR, LINA, YUSUF, MEI
The people of camp day 4 and day 7. Each is somewhere on the island now, and each is a small story (OPEN_WORLD.md):
Omar cooks at the Shift Canteen in the docks, Lina irons at Adela Wash & Fold, Yusuf plays chess in Tenth Street
Park, Mei cleans at the Atrium Cafe in the hospital ("I am very tired").

### SAL, the taxi driver
Fifty. *"I drive this taxi every day. I love it!"* Talks too fast, thinks everyone is a sailor, knows every street.
Parks at the Ferry Landing taxi bay. Your first friend, your driving teacher, and the reason you learn to say
*"Slowly, please."*

### OFFICER REYES
The gate officer of the old game: *"Good luck. I really hope you make it."* He means it. He runs the Release Desk
at City Hall and tests you on days 20 and 30. By the book, tired, fair. In chapter 4 the book is used against him
too.

### MR. DUNN (the boss) and SAM (the co-worker)
The interviewer and first boss: office shirt, *"Welcome aboard!"*, then *"You're fired."* Not a villain, just a man
with a schedule. Sam shows you the job and covers for you once.

### ORLA and ZIB
Old designs kept. Orla talks. Zib is silent, waves, and writes everything down.
- Their day is four hundred hours long and they are always tired. Their planet has one continent and it is very
  boring. Hollywood is wrong about them: no lasers, no tests. (They do have one weapon. See *puddle*.)
- They read the word ALIEN on your file and believed it. You do not have the English to explain the mistake. That
  is a running joke for three chapters and the hero's best line in the last one.
- **Want:** to live on Earth, legally, like you. **Problem:** everything.

### GOO
See 4.4. Round, green, proud of its certificate. Says *"Blub."* Afraid of the plughole.

### COMMANDER RHODES (new)
Navy, "Special Projects". Clean, friendly, never raises his voice. He reads the hosts' forms, and one of them says:
*"Says a green jelly taught English all day. Ha ha."*
- He talks in idioms, fast, and smiles while you are lost. *"Slowly, please"* does not work on him. He says it
  again at the same speed.
- **Want:** the ship. **Offer:** your papers, today, for your friends.
- He is beaten in the hero's own way: slowly, clearly, in front of people.

### Smaller parts (all from the old game)
The camp guard (*"Morning sport!"*), the barista, the bartender, the courier, the bus driver, the ER receptionist,
the doctor, the new boss at the library, the driving examiner.

## 6. The places (all on the new map)

Names are as written in the map data (some signs say Crownado, some Coronado: both are in the game).

| In the story | On the new map | Missions |
|---|---|---|
| The camp and the interrogation room | Stage sets off the map, as in the old game (`camp_set.gd`, `interrogation_office.gd`) | P2, P3 |
| The base gate | Alameda Blvd at 4th St, on the base fence. Needs the kit's unused `lmk_navy_gatehouse` placed there. | P4, 4.3 |
| The ride into town | 4th St east from the gate, over Crown Hill (the "postcard drive"), down Amber Ave to 10th St | P4 |
| **Home** | The brick house on the hilltop, north side of 10th St (`player_home.json`: `tudor_brick_player`, lot n1 of `n_hs_b6_tenth`). Rooms as built: hall, living room, snug, dining room, kitchen, office, bath; upstairs the attic bedroom (yours), attic bath and the **attic studio (locked)**. Garage on the alley behind. Address in the story: 15 Tenth Street. | from 1.1 |
| The bus | The two loop lines and their stops; Island Transit Center | 1.2, 2.2 |
| The first job | The player's pick: Hilltop Market (Sal's tip: "they need a cashier"), Hank's Diner, Casa del Mar Inn or Spokes Bike Repair | 1.2, 1.5, 2.2 |
| The café | Trident Café, pilot high street | 1.3 |
| The bar "near here" | The Gull Tavern, in the hill rows by the house | 1.4 |
| The ship | A stage set above the real island: its glass floor shows the live map | 1.6, ship nights |
| The second job | Coronado Public Library (and Library Grounds Coffee next door) | 2.2 |
| The hospital | Island Hospital: Emergency Department, Main Lobby, Island Pharmacy, the helipad | 2.4, 2.5 |
| The check-ins | City Hall Front Desk (the Release Desk) | 2.6, 3.7 |
| The housemate's work | Little Frenchy | 3.5 |
| Sal | Ferry Landing taxi bay; the stadium's Tailgate Lot for driving practice | 3.2 |
| Zib's jacket | Second Hand Rose and Crownado Vintage, gritty edge | 3.1 |
| Ivan | Big Al's Tires, the car pound, the vacant lot, Payday Loans 4U, all gritty edge | 3.3 |
| Grace's class | Christ Church Community Center | 3.4 |
| Rhodes's table | Overlook Cafe, Glorietta Ring Park | 3.7 |
| Where the ship hides | Under the water of Glorietta Bay, off the marina's fuel dock | 4.1, 4.4 |
| Where they hold Goo | Coronado University: the Science Building, the Quad, the campus garage | 4.2 |
| The last flight | The marina, the bay, **under the bridge**, round the island ring | 4.4 |
| The hearing | Coronado County Courthouse; Island Legal Aid next door | 4.5 |

The island opens with the story. Prologue and chapter 1: the hill, the high street, your work. Chapter 2: the
library, the hospital, the north-east. Chapter 3: everything (the gritty edge, the docks, the campus, the east
shore). Chapter 4: all of it at night.

## 7. The shape

| Part | Days | Story missions | Hours | On the screen |
|---|---|---|---|---|
| Prologue: **They Caught Us** | 1–10 | P1–P4 | 0.7 | Get out |
| Chapter 1: **Make Yourself at Home** | 10–12 | 1.1–1.6 | 3 | A room, a job |
| Chapter 2: **Forty Light Years** | 13–20 | 2.1–2.6 | 3.5 | Keep the job. What is in the attic? |
| Chapter 3: **The Rent** | 21–30 | 3.1–3.7 | 5 | Pay the rent. Who is watching? |
| Chapter 4: **Make It** | 31–40 | 4.1–4.5 | 3 | Get everyone home |
| Epilogue: **Day 41** | 41– | E1 | 0.3 | — |

About 15 hours of story, and about as much again in the open world.

### The story in one paragraph each
- **Prologue.** The old sketches. One day in the camp: the morning sport, the people, the fight with Ivan, Grace's
  goodbye. A room, a desk, a question you cannot answer. The gate. Sal's taxi, too fast.
- **Chapter 1: Make Yourself at Home.** A brick house on a hill and a housemate who asks a lot of quick questions.
  A locked door at the top of the stairs. A CV, a bus, an interview you can ruin for fun. A coffee, a friend. A
  drink, and a sailor who wants a fight you cannot afford. A first day at work. Then a green light at three in the
  morning: a ship, two aliens, a glass floor over the whole island, and a deal you cannot refuse (you can try).
- **Chapter 2: Forty Light Years.** A jelly in your bedroom says *school*. You lose a morning, a job, and most of
  your dignity on 10th Street. The friend finds you a new job and you have nineteen minutes to get there. At home
  the attic door opens: thirty pages about you. The argument, the wine, the glass. You drive a bleeding housemate
  across the island with no licence and a jelly in your ear. A doctor says *should* nine times. A tired officer
  stamps day 20, and a man in the corner of the room writes one word in a notebook: *jelly*.
- **Chapter 3: The Rent.** The island opens. Zib needs a jacket. Sal thinks you should have a licence. Ivan's car
  is in the pound and his plan has four words in it. Grace's class has six chairs and two students. The housemate
  cannot cook with one hand, the rent is $400, and Little Frenchy needs someone who can understand a shouting chef.
  Every third night the aliens ask harder questions. Then Commander Rhodes buys you a coffee above the bay and
  offers you the one thing you want.
- **Chapter 4: Make It.** The ship is too tired to stay up. It comes down into Glorietta Bay and two aliens move
  into the attic. Rhodes takes Goo. You take Goo back, out of a science building, with a class of beginners as your
  crew. On the last night the Navy closes the bay, and somebody has to fly a ship that only obeys English. Under
  the bridge. Then one question, *should they stay or should they go*, and one more: *who are you?*
- **Epilogue.** Day 41. Nobody is counting.

## 8. What the game is quietly teaching

Nothing here is shown to the player. It is for us: the old chapters' grammar (PHASE4_PLAN section 3) is all still
carried, by play.

| Mission | The play | What it carries |
|---|---|---|
| P2 | the morning sport, the fight | look / go / get down / jump; under, over; hello, thank you; *we are friends* |
| P3, P4 | the room, the taxi | *I am ...*, name, age, job, address; *Please speak slowly* |
| 1.1 | the house, the takeaway | *there is / there are*; rooms and things; *I like / I don't like*; *Can I have ...?* |
| 1.2 | CV, bus, interview | *can / can't*; directions; present simple about yourself |
| 1.3 | the café queue | *I'd like*, *Would you like*, sizes, prices; first small talk |
| 1.4 | the bar | past simple (*I took, I went, I met*); *let's*; *sorry*, calming lines |
| 1.5 | the race to work | the time; the boss's imperatives; *usually / sometimes / always* |
| 1.6 | the glass floor | *it is / they are*; *this / that*; places; days, months, numbers |
| 2.1 | Goo school | *have you ever*; comparatives (bigger, smaller, faster) |
| 2.2 | fired and hired | *why didn't you*; past negatives; *going to* |
| 2.3 | the attic, the argument | present continuous (*you're always leaving*, *what are you doing?*) |
| 2.4 | the drive | left, right, straight on, stop; *he / she was*; telling what happened |
| 2.5 | the pharmacy, the porch | *should / shouldn't*; how often; with food |
| 2.6 | check-in | telling your week |
| 3.1 | Zib in town | *don't*; clothes, colours, sizes; *too big / too small* |
| 3.2 | the driving test | *turn left at ...*, *behind / in front of / next to*; ordinal numbers |
| 3.3 | the car pound | fifty words used well: *wait, go, up, over, behind, quiet* |
| 3.4 | Grace's class | inviting; *want to*; days and times |
| 3.5 | the kitchen | food, amounts, *how many / how much*; *first, then* |
| 3.6 | the stake-out | hearing a time, a place, a number |
| 3.7 | check-in, the offer | *have to*; saying no |
| 4.x | everything, fast | review under pressure; *because*; *should* as a real choice; telling your story |

A1 comes first and is complete by the end of chapter 2 (as far as the old game went). Chapters 3 and 4 recycle it
and reach into A2 only where the old game already did (present perfect, comparatives, *going to*, *should*).

## 9. Lines: the rules
- **Old lines stay word for word** wherever the scene survives. They are already translated and 177 of them already
  have a recorded clip. The mission files mark them `(old)`.
- Hero lines: short A1, the old rule. Never a line the hero could not build from what they have already heard.
- Every other speaker talks like a person, then says it again plainly when asked.
- Gold expressions keep their `[gold]` tag and their list (`expr.*`, 50 of them). New ones are added to that list,
  not scattered.
- English with Turkish under it, everywhere, as now.

## 10. What has to be built

Everything else is already in the city or in the old game.
1. **Places.** The gatehouse landmark placed at Alameda x 4th. The camp set and the interrogation room ported from
   the old game. The ship (one round room with a glass floor that shows the baked city far below). The attic studio
   dressed as the report room (a desk, a recorder, a printer, forms pinned to the wall).
2. **People.** Orla, Zib and Goo (old designs). Rhodes and two Navy men. Grace, Ivan and the camp four in street
   clothes.
3. **Vehicles.** The housemate's car in the alley garage. Sal's taxi with a second set of pedals for the lesson
   joke. A dark Navy van (the existing van, repainted). The library's book bike (the beach cruiser with a box).
   The ship as something you can fly, once.
4. **Systems.** Say It on top of CityTalk (timed lines in action). "The map marks what you understood". Goo
   (translator voice, size, the sink). The eight tricks and the Hum meter. Strikes on top of the law system and the
   talk-down. The Report. Mission cards and medals. The calendar.
5. **Old systems this story needs ported** (already on `docs/GAME_PORT_BOARD.md`): money and ATMs (10), jobs and
   deliveries (11), lessons for Goo School (12), captions and dialogue (13), the character creator (15).
6. **UI pages.** The host's forms (they print your real save file), the CV, the release paper with its three
   stamps, the doctor's note, Zib's notebook.
