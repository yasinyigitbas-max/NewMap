# FIRST GEAR — Script 1: Prologue and Act 1
Format: `ID SPEAKER [tone, feeling]: line`. The brackets are for the renderer. `(slow)` is the version an NPC says after
*"Sorry?"* or *"Slower, please."*. `YOU (say)` is spoken by the player; `YOU (think)` is the hero's inner voice.
`{NAME}`, `{HOME}`, `{they}/{them}/{their}` are tokens (BIBLE, top). Stage directions are in italics.
The A1 contract for `YOU (say)` lines is in `A1_SYLLABUS.md` section 1 (Prologue and Act 1: at most 7 words).

---

# PROLOGUE: ARRIVALS
*Monday, the 1st of June.*

## P1 · Over the Bridge
- **Where:** the Line 1 bus on the bridge; Island Transit Center (its four bays, the platform shelters, the waiting hall).
- **Teaches:** *Hello, goodbye, please, thank you, yes, no*; *Sorry? / Slower, please.*; numbers 0–10.
- **Play:** the controls tutorial (left side of the screen to move, right side to look, tap to pick up and to use);
  the first talk (`CityTalk`: say / type / skip); the first Nod; find the right bay by its number.
- **New words:** bus, bay, line, ticket, dollar.

*Black. The hum of a bus engine. Then light: the bus is on the bridge, high over the water. The city's towers stand
behind; the island lies ahead, low and green, with a white hotel and red roofs. The hero sits by the window with one bag.
On the hero's phone, one message (reading, the first one):*

> **Casa del Mar Inn:** Welcome, {NAME}! Your job starts on Monday, 1 June. See you soon! — Mr. Prewitt

*The title comes up over the water: **FIRST GEAR**.*

```
P1-001 YOU (think) [quiet, nervous]: A new island. A new job.
P1-002 YOU (think) [a small smile]: English. Only English now.
P1-003 MARISOL [bright, professional, on the speaker]: Next stop, Island Transit Center. This is the last stop. Thank you for riding Line One.
P1-003s MARISOL (slow) [patient, clear]: Island Transit Center. Last stop. Thank you.
```

*The bus stops in bay 1. Tutorial: stand up (tap), pick up the bag (tap), walk to the door (left side), look at the
driver (right side). Marisol, 48, uniform, sunglasses on her head, smiles at every passenger.*

```
P1-004 MARISOL [warm, a little tired, end of shift]: Bye now. Have a good one.
P1-005 YOU (say) [shy, polite]: Hello.
P1-006 MARISOL [amused]: Hello? Honey, that's goodbye time! Ha. Hello. Welcome to Coronado.
P1-007 YOU (say) [hopeful, showing the phone]: Casa del Mar Inn?
P1-008 MARISOL [fast, friendly, pointing everywhere]: Oh, the inn, sure — you want the Two, Line Two, from bay two over there, it goes all along the bay, every fifteen minutes, you can't miss it.
```

*The first choice. Three buttons: **[nod]** / **Sorry?** / **Slower, please.** A small hint glows on the two spoken
ones: "Say it. People like it."*

*If the player NODS:*

```
P1-009 YOU (think) [embarrassed]: I don't understand. But... OK.
```

*The hero walks to bay 1, the nearest. Marisol honks twice and leans out of her window, laughing, holding up two
fingers.*

```
P1-010 MARISOL [laughing, loud, kind]: No, no, no! Two! Line two! Bay two!
P1-011 YOU (say) [red-faced]: Sorry. Thank you.
P1-012 MARISOL [warm]: Next time, ask me, OK? Ask! Nobody bites.
```

*If the player says "Sorry?" or "Slower, please.":*

```
P1-013 YOU (say) [careful]: Sorry? Slower, please.
P1-014 MARISOL (slow) [patient, holding up two fingers, then pointing]: Line two. Bay two. Over there.
P1-015 YOU (say) [relieved]: Line two. Bay two. Thank you!
P1-016 MARISOL [pleased]: You got it. Good luck, honey.
```

*Bay 2. Four bays, each with a big number. A timetable case (the player can read it now or later). A clock: 10:52. The
Line 2 bus pulls in; its sign says **2 CASA DEL MAR · BAYFRONT**. The driver of Line 2 is a silent, bearded man.*

```
P1-017 DRIVER LINE 2 [flat, bored]: Two dollars.
P1-018 YOU (say) [counting coins]: Two dollars. Here you are.
P1-019 DRIVER LINE 2 [a nod]: Thanks.
P1-020 YOU (say) [smiling]: Thank you.
```

*The ride (skippable): along the bay, the marina, the boats, the beach. The hero's phone buzzes; a message from
{HOME} (reading):*

> **{HOME}:** Are you there? Write in English! I want to learn too :)

*The player answers with word tiles (writing, the first): **Yes. I am here. The sea is beautiful.** (The tiles offer
"Yes / No / I am / here / The sea / is / beautiful / big".)*

---

## P2 · The Badge
- **Where:** Casa del Mar Inn (waterfront): the lobby, the manager's small office behind the desk.
- **Teaches:** *My name is… / I'm… / I'm from… / I'm a…*; *How do you spell…?*; the alphabet; numbers 11–20 (and the
  hero's age); *What's your…?*; countries, nationalities, languages, jobs.
- **Play:** CHARACTER CREATION is the staff badge. Each question is a creation step; the photo is the look editor.
  Then the news, and the first message home (a small writing choice: the truth or a nod).
- **New words:** badge, photo, form, manager, job.

*The lobby: cool tiles, a fan, a vase of white flowers. Mr. Prewitt, 60, a pale suit, a tie with small anchors on it,
comes out too fast. He is a man who can't say hard things, and the actor must play that under every line.*

```
P2-001 PREWITT [too bright, nervous]: You must be — yes! You must be our new summer team member. Welcome, welcome. Please. Sit down.
P2-002 YOU (say) [polite, a little formal]: Hello. Thank you.
P2-003 PREWITT [busy, avoiding something]: First things first. The badge. Every team member needs a badge. Let's do the form.
P2-003s PREWITT (slow) [careful]: First, the badge. The form. OK?
```

*He turns a screen to face the hero: a staff form. Each line he asks is a creation step.*

```
P2-004 PREWITT [kind, practised]: What's your first name?
P2-005 YOU (say) [clear]: My name is {NAME}.
P2-006 PREWITT [pen ready]: Lovely. And how do you spell that?
P2-007 YOU (say) [slowly, letter by letter]: {NAME_SPELLED}.
```

*The alphabet: the hero spells by voice (or taps letters). The game listens for each letter. If a letter is wrong
(B / V, E / I, G / J are the usual ones), Prewitt reads it back wrongly, gently:*

```
P2-008 PREWITT [checking, polite]: Was that a "B", as in "boat"? Or a "V", as in "very"?
P2-009 PREWITT [pleased]: Perfect. Got it.
P2-010 PREWITT [smiling]: And how old are you? If you don't mind.
P2-011 YOU (say) [simple]: I'm {AGE}.
P2-012 PREWITT [nodding]: {AGE}. Wonderful age. And where are you from?
P2-013 YOU (say) [a little proud]: I'm from {COUNTRY}.
P2-014 PREWITT [genuinely interested]: Oh! I've never been. Is it hot there? No — never mind. So you're {NATIONALITY}. And what languages do you speak?
P2-014s PREWITT (slow) [careful]: Your languages. What languages?
P2-015 YOU (say) [counting on fingers]: I speak {LANGUAGE} and a little English.
P2-016 PREWITT [laughs, warm]: "A little English." That's how we all start. And at home — what's your job?
```

*The job from home (six cards with pictures): driver, cook, nurse, student, builder, shop worker. It colours small lines
later (Hank asks about it; Tess reacts if "nurse"; Lou reacts if "driver").*

```
P2-017 YOU (say) [simple]: I'm a {JOB}.
P2-018 PREWITT [delighted, then a flicker of guilt]: A {JOB}! Useful. Very useful. Now. Look at the camera, please. Smile!
```

*The photo is the look editor: face, skin, hair, eyes, clothes. The camera flash is a tap. Prewitt reacts to whatever
the player makes:*

```
P2-019 PREWITT [warm]: Oh, that's a good one. That's very you.
P2-020 PREWITT [careful]: Two more questions. This one is just for us: why are you here? On the island?
```

*The choice (three cards; it colours three lines in the game):*

```
P2-021a YOU (say) [determined]: I want to work.
P2-021b YOU (say) [soft, serious]: I want to help my family.
P2-021c YOU (say) [quiet, honest]: I want a new life.
P2-022 PREWITT [touched, and that makes it worse]: That's... that's a very good answer. And the last one: an emergency contact. Who do we call? If there's a problem?
```

*The second choice: {HOME} (mum, dad, grandmother, grandfather, a brother, a sister, a best friend; the player can type
a name). This is the person the hero writes to all game.*

```
P2-023 YOU (say) [warm]: My {HOME_ROLE}. {HOME}.
P2-024 PREWITT [the pen stops]: {HOME}. Good. Good.
```

*He prints the badge: the hero's photo, the name, CASA DEL MAR INN · TEAM MEMBER. He holds it and doesn't give it.
Silence. The fan turns. He looks at the badge, then at the window, then at the hero.*

```
P2-025 PREWITT [quiet, finally]: I have to tell you something. I'm sorry. I'm very sorry.
P2-026 PREWITT [fast, ashamed, the words falling out]: The inn was sold. On Friday. The new owners — they have their own people. All the summer jobs are gone. All of them. I tried. I phoned them. I said, "There's someone on a bus, right now, over the bridge." They said no.
P2-026s PREWITT (slow) [heavy, simple]: The hotel is sold. There is no job. I'm sorry.
P2-027 YOU (say) [stunned]: No job?
P2-028 PREWITT [miserable]: No job.
```

*A thinking moment (word tiles, the first): time slows; the fan stops in mid-turn. The words float: **I / no / have /
room / . / money / no / and**. The player builds and says one of: "I have no room." / "I have no room and no money."
A wrong order is said aloud ("Room I no have."), and Prewitt winces kindly; the player tries again.*

```
P2-029 YOU (say) [very quiet]: I have no room. And no money.
P2-030 PREWITT [he can't bear it]: Here. Please. Take this.
```

*He gives two things: a twenty-dollar note from his own wallet, and a small card.*

```
P2-031 PREWITT [trying to help]: Twenty dollars. And this — Hank's Diner, on Amber Avenue. It's a free breakfast, all day. Hank's is... everybody goes to Hank's. Somebody always needs somebody at Hank's.
P2-031s PREWITT (slow) [kind]: Twenty dollars. And free food. At Hank's. Amber Avenue.
P2-032 YOU (say) [flat, polite out of habit]: Thank you.
P2-033 PREWITT [to himself, as the hero goes]: You can keep the badge. I don't know why I said that.
```

*Outside, on the waterfront, with the bag. The first message home (writing). The phone shows {HOME}'s last message.
The tiles offer two true sentences and one nod:*

- **"There is no job. I am OK."** → {HOME}: *Oh no!! Are you OK? Come home?* → tiles: **"No. I am OK. I have twenty
  dollars."** → {HOME}: *Twenty?? :( Eat something!!*
- **"The job is good. I am happy."** (the nod) → {HOME}: *Great!!! I am so happy for you!* → no tiles; the hero looks
  at the screen for a long time.

```
P2-034 YOU (think) [only if the player lied; small, tired]: A small lie. Only a small one.
P2-035 YOU (think) [both; looking at the card]: Hank's Diner. Amber Avenue.
```

*The player walks or takes Line 2 back to the high street (the first free walk; the island is open).*

---

## P3 · Eggs. Coffee. Black.
- **Where:** Hank's Diner (Amber Avenue, high street): the counter, the stools, the booths, the window with its cards.
- **Teaches:** *Can I have…, please?* (chunk); *Here you are.*; prices to $20; *Are you…? Yes, I am. / No, I'm not.*;
  *Can you drive? Yes, I can.* (chunk); food and drink on a menu.
- **Play:** read a menu (prices); the FIRST MEDIATION (order for Lou); read an ad and say a phone number aloud so it
  can be dialled; a job interview.
- **New words:** menu, eggs, pancakes, toast, coffee, black.

*Hank's Diner: red stools, chrome, a long counter, pies under glass, a radio playing old songs. A stool at the end has
a hand-painted sign on a stand: **RESERVED · LOU**. In the window, among the cards (a lost dog, guitar lessons), one in
neat capitals: **DRIVER WANTED · OLD MAN · OLD CAR · NO ENGLISH OK · CALL TESS 619-555-0147**.*

*Hank, 54, big, an apron, a pencil behind his ear, talks to the whole room at once.*

```
P3-001 HANK [loud, fast, cheerful]: Hey there! Sit anywhere, chief, I'll be right with you — Marge, your toast is up! — Hi! What can I get you?
P3-001s HANK (slow) [louder, not slower, then catches himself, slower]: What. Do you. Want? ...Sorry. What would you like?
```

*The menu (reading): EGGS (2) $6 · PANCAKES $8 · TOAST $3 · BACON $4 · COFFEE $2 · TEA $2 · ORANGE JUICE $4 · PIE $5.
The hero has $20 and the voucher.*

```
P3-002 YOU (say) [showing the card]: Hello. Here you are.
P3-003 HANK [reading it, softening]: Ah, one of Prewitt's cards. Poor guy. So the inn's gone, huh? Everybody's talking about it. OK. On the house. What would you like?
P3-004 YOU (say) [reading the menu, careful]: Can I have pancakes, please? And tea.
P3-005 HANK [writing, already moving]: Pancakes and a tea! You got it.
```

*The door opens. An old man comes in very slowly with a cane: a good grey hat, a pressed shirt buttoned to the top, a
right hand that doesn't quite close. LOU BRANNIGAN. The room changes: a few people say "Lou!" and then look away,
because they don't know what to say to him now. He goes to the RESERVED stool. It takes a long time. Nobody helps,
because he doesn't want them to, and everyone can see that.*

```
P3-006 HANK [too loud, too happy, the way people are with the sick]: LOU! Look who's back! Welcome home, my friend! Six weeks! We missed you! The usual?
P3-007 LOU [trying; the word won't come]: ...
P3-008 HANK [louder, slower, kind and terrible]: THE USUAL, LOU? EGGS? PANCAKES?
P3-009 LOU [a huge effort; the wrong word]: F... fish.
P3-010 HANK [laughing, then not]: Fish? You hate fish! You've hated fish for — Lou?
P3-011 LOU [frustrated, quiet, shaking his head]: No. No. No.
```

*Silence. The radio plays. A woman in a booth stops eating. Lou looks at the counter. His left hand moves over the
menu and stops on a word; his finger trembles on it. Nobody but the hero is close enough to see. The game gives the
player one prompt: "Look."*

*The hero looks. Lou's finger is on EGGS. Then his eyes move to COFFEE.*

*The first mediation. Step 1, understand Lou: the player says what they see.*

```
P3-012 YOU (say) [gentle, to Lou]: Eggs?
P3-013 LOU [looking up, surprised; hope]: Yes!
P3-014 YOU (say) [pointing at the menu]: Coffee?
P3-015 LOU [nodding hard; then, with everything he has]: Yes. ...Black.
```

*Step 2, say it for him (to Hank).*

```
P3-016 YOU (say) [clear, a little brave]: Eggs and coffee, please. Black.
P3-017 HANK [quiet now; he has understood something]: Eggs and a black coffee. The usual. Coming right up, Lou.
```

*Lou turns on his stool and looks at the hero for a long time. Then, one word, and it is the first time in six weeks
anyone has seen him smile:*

```
P3-018 LOU [a slow smile]: You.
P3-019 YOU (say) [unsure]: Me?
```

*The food comes. They eat side by side, a stool apart, and don't talk, and it is comfortable. Then Lou points with his
fork: at the window card, DRIVER WANTED. Then at the hero. Then at his own mouth, and shakes his head; then at the hero's
mouth, and shakes his head again. A small laugh.*

```
P3-020 LOU [pointing between them; a joke and not a joke]: You. Same.
P3-021 YOU (think) [understanding]: Same. No words. Me and him.
P3-022 LOU [tapping the card, then miming a steering wheel]: Drive?
P3-023 YOU (say) [sitting up]: Yes. I can drive.
P3-024 LOU [delighted, slapping the counter]: Ha!
```

*He pushes his old flip phone across the counter and points at the card's number. His right hand can't press the small
keys. The player reads the number aloud (numbers 0–9), and the phone dials as they say it.*

```
P3-025 YOU (say) [reading carefully]: Six one nine. Five five five. Zero one four seven.
```

*If the player says a wrong digit, a wrong person answers (a sleepy man: "Hello? ...No, this isn't Tess. Who's this?").
The player tries again. It rings.*

```
P3-026 TESS [on the phone, fast, worried]: Hello? Lou? Lou, is that you? Are you OK? Did you fall?
P3-027 YOU (say) [nervous]: Hello. I'm not Lou. I'm {NAME}.
P3-028 TESS [confused, then alarmed]: Who? Where's Lou? Is he OK?
P3-028s TESS (slow) [making herself slow down]: Sorry. Slowly. Is Lou OK?
P3-029 YOU (say) [simple]: Yes. Lou is OK. We are at Hank's.
P3-030 TESS [a breath out]: At Hank's. OK. OK. Why are you — never mind. Stay there. I'm coming. I'm two minutes away.
```

*Twelve minutes later. Tess Brannigan, 25, in blue hospital scrubs under an old hoodie, comes in fast. She hugs Lou
from behind and he pats her arm. She hasn't slept. She looks at the hero like a problem she has to solve.*

```
P3-031 TESS [fast, tired, professional]: Hi. I'm Tess. I'm his granddaughter. So you're the one who called. Thank you. Who are you?
P3-031s TESS (slow) [catching herself]: Sorry. I'm tired. I'm Tess. Who are you?
P3-032 YOU (say) [standing up, a little formal]: My name is {NAME}. Nice to meet you.
P3-033 TESS [sitting, all business; the interview]: Are you here for the job? The driver job?
P3-034 YOU (say) [glancing at Lou]: Yes, I am.
P3-035 TESS [rapid, counting on her fingers]: OK. Questions. Can you drive?
P3-036 YOU (say) [firm]: Yes, I can.
P3-037 TESS [quick]: Have you got a licence? From home is OK. Can I see it?
P3-038 YOU (say) [handing it over]: Yes. Here you are.
P3-039 TESS [reading it, half to herself]: International permit. OK. Good. Where are you from?
P3-040 YOU (say) [simple]: I'm from {COUNTRY}.
P3-041 TESS [quickly]: And where are you staying? Your hotel?
P3-042 YOU (say) [quiet]: I have no room.
P3-043 TESS [stopping]: No room?
P3-044 YOU (say) [simple, honest]: The job is gone. The hotel... no.
```

*Tess looks at Lou. Lou is eating his eggs and humming. Something old and tuneless, but humming.*

```
P3-045 TESS [low, to herself, amazed]: He's smiling. He doesn't smile. Six weeks, and he doesn't smile.
P3-046 LOU [pointing his fork at the hero, to Tess, final]: You. Yes.
P3-047 TESS [a long breath; deciding]: OK. Listen. This is the job. You drive him. His car, not mine — I don't drive. Hospital, shops, Hank's, wherever. Six weeks, maybe more. Two hundred dollars a week. There's a room in the house. And food. Is that OK?
P3-047s TESS (slow) [very simple, counting on her fingers]: You drive Lou. Two hundred dollars, every week. A room. Food. OK?
P3-048 YOU (say) [a big smile, trying not to]: Yes! Thank you. Thank you!
P3-049 TESS [standing, already late]: Don't thank me. He's not easy. Can you start tomorrow?
P3-050 YOU (say) [firm]: Yes. Tomorrow.
```

*Lou takes his car keys out of his pocket (one key, an old leather fob shaped like a steering wheel). He slides them
across the counter to the hero. Then he grabs them back. Then, slowly, he puts them in the hero's hand and closes the
hero's fingers over them with his good hand.*

```
P3-051 LOU [serious, almost a ceremony]: Keys.
P3-052 TESS [dry, leaving]: He does that. Don't ask.
P3-053 HANK [from the counter, warm]: Welcome to the family, chief. God help you.
```

*Evening. The walk home up 10th Street, slowly; Lou holds the hero's arm (a walking tutorial: match his pace, or he
stops and glares). Past Hilltop Elementary, empty now; past the lookout of Hillside Park. The house: a cedar craftsman
cottage behind a white picket fence, a garage at the back of the drive. A grey cat on the step.*

```
P3-054 LOU [to the cat, gentle]: Clutch.
P3-055 YOU (say) [crouching]: Hello, Clutch.
```

*Tess, back from the hospital for an hour before her night shift, shows the spare room quickly: a single bed, a desk,
a window over the alley, a few faded stickers on the wardrobe.*

```
P3-056 TESS [too quick, not looking at the stickers]: This is your room. It was my mum's room. A long time ago. Towels are in the bathroom. Goodnight.
P3-057 YOU (say) [softly]: Goodnight, Tess. Thank you.
```

*Sleep (the first save). The hero's phone, on the pillow: the time, 22:14, and the date, Monday 1 June.*

---

# ACT 1: FIRST GEAR
*Tuesday 2 June – Sunday 7 June. A1.1: me, my home, things, food, my day.*

## M1 · Bonnie
- **Where:** Lou's house (kitchen, living room, hall, Lou's room, bathroom); the garage; 10th Street; the school
  crossing at Hilltop Elementary; back to Hank's.
- **Teaches:** *there is / there are*; *this / that / these / those*; plurals; *in, on, under, next to*; colours;
  *old, new, big, small, very*; imperatives (understood): *stop, slow down, turn left / right, go*.
- **Play:** a house tour that is a finding game; the garage reveal; the DRIVING TUTORIAL (Bonnie: doors, seat belt,
  gears, the calm bar of Rule 1, Lou's late "Left!" calls of Rule 2); meet Peg.
- **New words:** fridge, cover, garage, seat belt, school.

*7:40. Tess has just come home from her night shift. She is making toast and reading her own lists at the same time.
On the fridge, under a magnet shaped like a lemon (reading):*

> **HOUSE RULES**
> 1. No smoking.
> 2. Lou's pills: 9 a.m. and 9 p.m.
> 3. Don't let Lou drive!!!
> 4. Clutch eats at 7 and at 6.
> 5. Slow down. (Lou's rule, not mine.)

```
M1-001 TESS [tired, quick, kind]: Morning. There's coffee. There are eggs in the fridge. Read the rules, please. Number three is the important one.
M1-002 YOU (say) [reading]: "Don't let Lou drive."
M1-003 TESS [pointing at Lou, who is pretending not to listen]: The doctor says no. For three months, maybe six. He says yes. You say no. OK?
M1-004 LOU [from the table, loudly, to no one]: Pfff.
M1-005 TESS [ignoring him]: Quick tour. Then I sleep for six hours. Don't wake me unless there's a fire.
M1-005s TESS (slow) [simple]: A quick tour. Then I sleep.
```

*The tour, room by room (*there is / there are*, *this / that*). Tess points; the player says what is there (voice or
tiles), and the room's objects light up as they are named.*

```
M1-006 TESS [in the kitchen]: This is the kitchen. What's in here? Tell me. Practise.
M1-007 YOU (say) [looking round]: There is a fridge. There are two cups.
M1-008 TESS [half a smile]: Good. That's Lou's cup — the green one. Don't use the green one.
M1-009 TESS [the living room]: Living room. That's his chair. Nobody sits in that chair. Not even me.
M1-010 YOU (say) [pointing at the shelf]: There are many books. And photos.
M1-011 TESS [the briefest pause at the photos]: Yes. Those are... old photos. Next.
M1-012 TESS [the hall; quick]: Bathroom. Lou's room — he sleeps downstairs now, because of the stairs. Your room upstairs, you know it. Questions?
M1-013 YOU (say) [thinking]: Is there a washing machine?
M1-014 TESS [pointing out of the back window]: In the garage. Next to the car. Don't touch the car.
M1-015 YOU (say) [surprised]: The car? I drive the car!
M1-016 TESS [stops on the stairs; a tired laugh]: Oh. Right. Yes. You drive the car. God. OK. Lou will show you. Goodnight. I mean good morning. I mean — bye.
```

*Tess goes up. Lou waits until her door closes. Then he stands, gets his cane, and points at his head: no hat.*

```
M1-017 LOU [urgent, gesturing at his bare head]: Hat!
M1-018 YOU (say) [looking round]: Your hat? Where is it?
```

*A finding game (prepositions). Lou can't say where; he can only say "No" or "Yes" as the hero guesses. The player
looks and says sentences: "Is it on the table? Is it under the chair? Is it next to the TV?" The hat is in the
living room, in the armchair nobody sits in, and Clutch is asleep in it.*

```
M1-019 YOU (say) [searching]: Is it on the table?
M1-020 LOU [impatient]: No.
M1-021 YOU (say) [searching]: Is it under the chair?
M1-022 LOU [more impatient]: No!
M1-023 YOU (say) [finding it; laughing]: It's in the chair. Clutch is in the hat!
M1-024 LOU [despair and love]: Oh, for crying out loud. Clutch!
```

*The cat stays. Lou lifts him out of the hat very gently with his good hand and puts him in the warm chair. The hat
goes on. He is a different man in the hat. He points at the back door.*

```
M1-025 LOU [standing straighter]: Car.
```

*The garage. Dust in the light. A workbench, a pegboard of tools, each one with its outline painted on the board. An
old radio. A shelf with a roof sign: **LOU'S DRIVING SCHOOL · LEARN WITH LOU**. And on the back wall, calendars — not
one, forty of them, pinned in rows, curling. The camera passes over them without stopping. (On every one, one date is
circled in red. The player won't notice yet. Some will.)*

*In the middle: something long and low under a grey cover. Lou hands the hero one corner.*

```
M1-026 LOU [a showman, holding his corner]: One. Two. Three!
```

*They pull. BONNIE: a 1974 full-size sedan, deep green, chrome, white-wall tyres, bench seats, a cassette player. She
is very clean. Somebody has kept her very clean.*

```
M1-027 YOU (say) [amazed]: Wow. This car is very big.
M1-028 LOU [proud, patting the roof]: Bonnie.
M1-029 YOU (say) [testing the word]: Bonnie. Bonnie is green.
M1-030 LOU [correcting, holding up a finger, enormously pleased]: Green. Beautiful.
M1-031 YOU (say) [smiling]: Bonnie is old. But beautiful.
```

*("But" is an Act 2 word; here the tiles offer only "and": "Bonnie is old and beautiful." The line above is used only
if the player says it unprompted; the game accepts it and Lou is delighted.)*

```
M1-031b YOU (say) [smiling]: Bonnie is old and beautiful.
M1-032 LOU [opening the passenger door for himself, with difficulty, waving the hero off when they try to help]: You. Drive.
```

*The DRIVING TUTORIAL. Open the door (tap), sit, seat belt (Lou taps his own and waits, staring, until the hero does),
mirrors, key, gear. Bonnie starts with a deep, old sound. Lou closes his eyes for a second when he hears it.*

*Rule 1 appears: a small calm bar on the screen with a picture of Lou's hand on the door. Hard brakes and fast turns
empty it; Lou grips the door and says:*

```
M1-033 LOU [sharp; a teacher's voice from forty years of saying it]: Slow. Down.
M1-034 LOU [pleased, when the bar is full]: Good.
```

*Rule 2: at every junction, Lou says the direction, but late, one word, with a finger. It's a listening game: "Left!"
comes a second before the turn.*

```
M1-035 LOU [late, pointing]: Left!
M1-036 LOU [later, pointing the wrong way, saying the right word]: Right!
M1-037 YOU (say) [confused]: Left or right?
M1-038 LOU [the word is right; the hand was wrong; he looks at his hand, angry]: Right. ...Right.
M1-039 LOU [at a stop sign, tapping the dash, firm]: Stop.
M1-040 LOU [quietly, when the hero stops well]: Good. Look. Left. Right.
```

*10th Street, 8:15, the school run. Ahead, outside Hilltop Elementary, a woman in a yellow vest steps into the road
with a round red sign on a pole: STOP. Children cross, holding hands. She is seventy, upright, grey hair cut short, a
whistle on a string. PEG OYELARAN. The kids call "Hi, Miss Peg!" She doesn't move the sign until the last child is on
the kerb. Then she walks to Bonnie's window. She looks at the car for a long moment before she looks at the people.*

```
M1-041 PEG [slow, exact, unreadable]: Good morning, Lou.
M1-042 LOU [clearly, at once — the clearest word he has said all morning]: Peg.
M1-043 PEG [to the hero, calm, police-clear]: And who are you?
M1-044 YOU (say) [nervous, polite]: Good morning. I'm {NAME}. I'm Lou's driver.
M1-045 PEG [a small nod]: His driver. I see. Where are you from, {NAME}?
M1-046 YOU (say) [simple]: I'm from {COUNTRY}.
M1-047 PEG [looking at Bonnie, not at the hero]: This car hasn't moved in six weeks. I walk past this house every day. Six weeks. Now it moves.
M1-047s PEG (slow) [even clearer]: This car. Six weeks, no. Today, yes.
M1-048 PEG [stepping back, lifting her sign; a warning that sounds like advice]: This is a school. Drive slowly.
M1-049 YOU (say) [carefully]: Yes. Slowly. Thank you.
```

*As they pull away, in the mirror: Peg writes something in a small notebook. Lou looks straight ahead. He has gone quiet
in a different way.*

```
M1-050 YOU (say) [curious]: Who is she?
M1-051 LOU [a long pause; then, simply]: Peg.
M1-052 YOU (think) [a small, odd feeling]: He can say "Peg". He can't say "eggs". But he can say "Peg".
```

*Hank's. Breakfast. The mission ends with the WordBook hint on the phone: "Tomorrow: Island Hospital, 8:30. Dr. Rao."*

---

## M2 · Word Cards
- **Where:** Island Hospital: the main lobby (reception), the corridors, the Bayview Wellness Center (the therapy
  room); the drop-off forecourt.
- **Teaches:** *a / an*; *What's this? It's a… / What are these? They're…*; *my / your*; personal information
  (address, phone number, email, date of birth); classroom language.
- **Play:** fill a visitor form (writing); the first therapy session (picture cards: the hero and Lou answer side by
  side); WordBook installed; the first photo task (ten photos of Lou's things, in the open world afterwards).
- **New words:** card, form, address, email, plaque.

*Wednesday 3 June, 8:25. The hospital's drop-off forecourt (the hero parks Bonnie in the visitors' car park; the
calm bar counts). The main lobby: a reception desk, a ficus, a TV with the news on mute.*

```
M2-001 RECEPTIONIST [bright, quick, a script she has said ten thousand times]: Good morning! Visitor or patient? If you're a visitor, fill in the form, please, and I'll print you a sticker.
M2-001s RECEPTIONIST (slow) [kindly]: A visitor? Please write on this form.
```

*The form (writing, on the tablet): NAME / ADDRESS / PHONE / EMAIL / DATE OF BIRTH / VISITING. The hero doesn't know
the address. Lou, beside them, takes a pen in his left hand and slowly writes on the back of his appointment card:
**14 TENTH ST**. The 4 looks like a 9. The player must ask.*

```
M2-002 YOU (say) [pointing at the card]: Lou, is this four or nine?
M2-003 LOU [holding up four fingers, firm]: ...Four.
M2-004 YOU (say) [writing, reading aloud]: Fourteen, Tenth Street.
M2-005 RECEPTIONIST [checking]: And your phone number? And your email?
M2-006 YOU (say) [reading from the phone]: My phone number is {PHONE}.
M2-007 YOU (say) [spelling]: My email is {EMAIL}.
M2-008 RECEPTIONIST [printing a sticker]: Perfect. Bayview Wellness Center, second floor, on the left. Have a good day!
```

*The Bayview Wellness Center: a bright room with big windows over the bay, a table, a mirror, picture cards in boxes,
a whiteboard, a small piano in the corner. On the wall by the door, a brass plaque. Dr. Anita Rao, 41, cardigan,
reading glasses on her head, gets up and shakes Lou's left hand first, without being asked. She has thought about
which hand.*

```
M2-009 RAO [warm, clear, unhurried]: Good morning, Lou. You look very smart today. Is that a new hat?
M2-010 LOU [pleased, touching the hat]: Old.
M2-011 RAO [delighted]: "Old"! A new word. Good. And you are...?
M2-012 YOU (say) [standing straight]: I'm {NAME}. I'm Lou's driver.
M2-013 RAO [interested]: Nice to meet you, {NAME}. Where are you from? What languages do you speak?
M2-014 YOU (say) [shy]: I'm from {COUNTRY}. I speak {LANGUAGE}. And a little English.
M2-015 RAO [a smile; something shared]: Me too. Kannada, Hindi, and English. English is my third language. I came here at twenty-two with a suitcase and a dictionary. So. You can stay. You can help. And you can learn too.
M2-015s RAO (slow) [simple]: English is my third language. Stay. Help. Learn.
```

*She explains the stroke, simply, to both of them. The actor plays it to Lou as much as to the hero: she never talks
about him as if he isn't there.*

```
M2-016 RAO [gentle, using her hands: one on her head, then a door closing]: Lou knows the words. The words are here — in his head. But the door is closed. Here — [the mouth] — they can't come out. We open the door. Slowly. Every day a little.
M2-017 LOU [bitter, tapping his head]: Here. Yes. Out — no.
M2-018 RAO [firm, kind]: Yes. For now.
M2-019 RAO [to the hero, quietly]: And you, {NAME}. Your door is closed a little too, yes? New language. Same problem. Different reason.
M2-020 YOU (say) [surprised; slowly]: Yes. Same.
```

*THE CARD GAME. Dr. Rao holds up a picture card; Lou answers, then the hero. Both are scored; the WordBook will later
show both counts. The cards: a cup, an apple, an egg, a key, a car, a hat, a phone, an orange, keys (plural), books
(plural). Rao teaches *a / an* by the cards themselves ("an apple, an egg, an orange").*

```
M2-021 RAO [holding up a card, teacher's rhythm]: Lou. What's this?
M2-022 LOU [concentrating; it comes]: Cup.
M2-023 RAO [a little round of applause]: Cup! Yes! It's a cup. {NAME}: what's this?
M2-024 YOU (say) [reading the card]: It's an apple.
M2-025 RAO [nodding]: An apple. Good — "an", because "apple" starts with "a". An apple, an egg, an orange. Lou?
M2-026 LOU [a struggle; the wrong word]: ...Car.
M2-027 RAO [patient, showing the card again: it's an egg]: Look again. Slowly.
M2-028 LOU [angry with himself, then]: Egg. An egg!
M2-029 RAO [warm]: An egg. Perfect. Wrong first, then right. That's how it works. Mistakes are good. Mistakes mean you're trying.
M2-030 RAO [holding up a card of a bunch of keys]: And these? What are these?
M2-031 LOU [instantly, perfectly, before anyone else]: Keys.
M2-032 RAO [laughing, surprised]: Wow. Fast! "Keys" is easy for you, Lou?
M2-033 LOU [a strange small smile]: Keys. Always.
M2-034 YOU (say) [reading the next card]: They're books.
M2-035 RAO [to the hero]: Good. Now you ask me. Classroom English: "How do you say ... in English?"
M2-036 YOU (say) [pointing at the small piano]: How do you say this in English?
M2-037 RAO [pleased]: A piano. "Pi-a-no." And Lou can't say many words, but listen.
```

*She plays three notes on the piano and sings: "Mon-day, Tues-day..." Lou joins in. He sings all seven days of the week
in a row, perfectly, in a clear old baritone. Then she asks him to say "Thursday" alone, and he can't.*

```
M2-038 LOU [singing, the words all there]: Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday.
M2-039 RAO [softly, explaining to the hero]: When he sings, the words come. A different door. We'll use that door.
M2-040 RAO [testing]: Lou. Just "Thursday". Not singing.
M2-041 LOU [trying; nothing; he throws the card across the table]: ...Oh, for crying out loud!
M2-042 RAO [not at all upset]: And that sentence is perfect every time. Interesting, isn't it? OK. A rest.
```

*In the rest, the hero looks at the brass plaque by the door (the first of the twelve; it goes into the WordBook as a
card). Reading:*

> **This room is a gift.**
> **For people who start again.**
> **— A friend. 1990.**

```
M2-043 YOU (say) [reading slowly]: "For people who start again."
M2-044 RAO [coming over]: Nice, isn't it? A friend paid for this room. In 1990. Nobody knows who. Just "a friend". There are more of these on the island. The library has one. The skate park has one. People say there are twelve.
M2-044s RAO (slow) [simple]: A friend paid for this room. No name. There are more. Twelve.
M2-045 YOU (say) [thinking]: Who is the friend?
M2-046 RAO [a shrug and a smile]: A mystery. I like it. "For people who start again." That's Lou. That's you. That's me, at twenty-two.
```

*The hero turns. Lou is looking at the plaque too. His face shows nothing at all. He looks away first.*

*WordBook. Rao takes the hero's phone and installs it: a blue icon, a book with a camera.*

```
M2-047 RAO [practical]: This is WordBook. It's on Lou's tablet, and now on your phone. Take photos. Every photo is a word card — for you, and for Lou. Here's your first job: ten photos of Lou's things. His cup, his hat, his car, his cat... Things he loves. On Friday we use them.
M2-047s RAO (slow) [counting on her fingers]: Ten photos. Lou's things. For Friday.
M2-048 YOU (say) [nodding]: Ten photos. Lou's things. OK.
M2-049 RAO [showing the screen]: And look — Lou's words, your words. Lou: forty-one words. You: thirty-eight.
M2-050 LOU [leaning in, reading the numbers, then pointing at himself, then at the hero, with enormous satisfaction]: Me. You.
M2-051 YOU (say) [laughing]: OK, Lou. Tomorrow, me.
```

*The forecourt. Tess, finishing her night shift in the ER across the drive, catches them at the car. She takes Lou's
flip phone, presses buttons, and hands it back.*

```
M2-052 TESS [fast, practical, a nurse's habit]: Lou. Listen. Press one: it calls {NAME}. Press two: it calls me. One, {NAME}. Two, me. OK?
M2-053 LOU [holding up one finger, then pointing at the hero]: One. You.
M2-054 TESS [kissing his hat]: Good. I'm going home to sleep. Drive slowly. Both of you.
```

*Open world. The photo task is live: ten of Lou's things (the green cup, the hat, Bonnie, Clutch, his chair, the
garage sign, the record player, his cane, a bottle of the mints he chews, the view from the lookout). Each photo makes
a card and Lou's word count ticks up too, with a small sound.*

---

## M3 · Lou's List
- **Where:** Hilltop Market; Ninth Street Pharmacy; Coronado Post Office (all on the high street).
- **Teaches:** *some / any*; countable and uncountable; *How much…? / How many…?*; *I'd like…*; numbers to 100;
  dollars, cents, change; *Is this yours?*
- **Play:** read a shopping list; buy things in real shops; MEDIATION 2 (the pharmacist), with a Nod risk; read a
  medicine label; meet Duke.
- **New words:** list, pills, label, stamps, change.

*Thursday 4 June. On the fridge, Tess's list (reading):*

> **SHOPPING — Thursday**
> eggs (12)
> milk
> bread
> apples (6)
> coffee
> cat food
> Lou's pills!!! → Ninth St Pharmacy (it's paid)
> stamps → Post Office
> Money: $60 (in the blue jar). Bring the change!! — T.

*At the bottom, in a different, shaky hand, Lou has added something: a drawing of a fish.*

```
M3-001 YOU (say) [pointing at the drawing]: Lou, what is this? A fish?
M3-002 LOU [nodding hard, then pointing at the floor, then miming eating]: Fish. Yes.
```

*The understanding half of mediation: three readings appear: a fish to eat / fish food for an aquarium / cat food.
Lou can only say yes or no. The player asks. ("Fish for you? Fish for Clutch?")*

```
M3-003 YOU (say) [guessing]: Fish for you?
M3-004 LOU [disgusted]: No!
M3-005 YOU (say) [guessing again, looking at the cat]: Fish for Clutch?
M3-006 LOU [delighted, pointing at the cat]: Yes! Clutch. Fish.
M3-007 YOU (say) [laughing]: Cat food. Fish cat food. OK.
```

*HILLTOP MARKET. A corner shop: shelves to the ceiling, a fridge humming, a counter with lottery tickets. The owner,
Omar, 60s, reading glasses on a chain, counts everything twice.*

```
M3-008 OMAR [slow, friendly, an old man's pace]: Good morning, Lou. Good morning, young — hello. What do you need?
M3-009 YOU (say) [reading the list]: I'd like some milk and some bread.
M3-010 OMAR [pointing]: Milk is in the fridge. Bread is next to the door. What else?
M3-011 YOU (say) [reading]: Have you got any eggs?
M3-012 OMAR [checking]: We've got some eggs. Not many. How many do you want?
M3-013 YOU (say) [reading carefully]: Twelve eggs, please. And six apples.
M3-014 OMAR [counting into a bag]: Twelve eggs... six apples... Coffee? We haven't got any coffee today. Sorry. Tomorrow.
M3-015 YOU (say) [checking the list]: No coffee? OK. Have you got any cat food?
M3-016 OMAR [proud]: Of course. Fish? Chicken?
M3-017 LOU [from the door, loudly]: Fish!
```

*At the counter: prices on the till (reading and listening: dollars and cents; fifteen / fifty is the trap).*

```
M3-018 YOU (say) [pointing at the milk]: How much is the milk?
M3-019 OMAR [reading the till]: The milk is three forty-nine. Three dollars, forty-nine cents. All together... fifteen dollars and eighty cents.
M3-020 YOU (say) [checking]: Fifteen or fifty?
M3-021 OMAR [laughing, writing it on a paper bag]: Fifteen! One-five. Fifty is too much for eggs, my friend.
M3-022 YOU (say) [paying]: Here you are. Twenty dollars.
M3-023 OMAR [counting the change into the hero's hand, slowly]: And your change: four dollars and twenty cents. Thank you.
```

*Then the bell over the door rings. A tall old man in a linen jacket and a white panama hat, a gold ring, a cane he
doesn't need, sunglasses he takes off slowly. He is seventy-nine and handsome and knows it. DUKE HALLORAN. He sees Lou
and opens his arms.*

```
M3-024 DUKE [rich, warm, theatrical, very fast]: Lou! Lou Brannigan! Well, would you look at that. Look at you, old friend. Standing up! They told me — the stroke — terrible thing, terrible. But look at you. The hat and everything.
M3-024s DUKE (slow) [smooth; slow is a performance for him too]: Lou. My old friend. Hello.
```

*Lou drops the bag. All twelve eggs break on the floor. He doesn't look down. He looks at Duke.*

```
M3-025 OMAR [dismayed, gentle]: Oh! The eggs!
M3-026 DUKE [laughing, enjoying it]: Still a butterfingers. Forty years and still a butterfingers. And who's this? The new help?
M3-027 YOU (say) [standing between them without meaning to]: I'm {NAME}. I'm Lou's driver.
M3-028 DUKE [delighted; a joke only he understands]: His driver! Lou has a driver! That's funny. That is very, very funny. Do you know who Lou was? Lou was the best — the best — driver on this island. Weren't you, Lou? Nobody ever saw him coming.
M3-028s DUKE (slow) [still smiling]: A driver. Funny. Lou was the best driver. The best.
M3-029 LOU [low, clear, final]: No.
M3-030 DUKE [laughing; a hand on Lou's good shoulder that stays too long]: "No." Well. He was always a man of few words. Now he's a man of fewer. I'll come by, Lou. We've got a lot to talk about. A lot. Forty years of things.
M3-031 DUKE [to the hero, warm, a business card between two fingers]: Drive carefully, friend. That's a very old car.
```

*He goes. The bell rings. Lou is shaking. Omar, without a word, gets a mop. The hero buys twelve more eggs (the same
dialogue, short: "Twelve eggs again, please." — Omar: "No charge. Not today."). In the street:*

```
M3-032 YOU (say) [worried]: Lou, who is he?
M3-033 LOU [a long time; then, a word that could mean two things]: ...Friend.
M3-034 YOU (think) [uneasy]: Friend? He doesn't look like a friend.
```

*Duke's card (an item): **H. HALLORAN · CONSULTING** and a phone number. Nothing else.*

*NINTH STREET PHARMACY. A white counter, a queue, a radio. The pharmacist, Ms. Duarte, 30s, efficient and kind, a
fast talker.*

```
M3-035 DUARTE [quick, kind]: Hi, Lou. Your prescription's ready. I just need to check a few things with you — oh. With you?
M3-036 YOU (say) [polite]: Yes. I'm his driver.
M3-037 DUARTE [reading the screen, fast]: OK. Date of birth? For the record.
```

*Mediation: Lou takes out his ID card and puts his finger on the date: 12/03/1949. The hero reads it (numbers).*

```
M3-038 YOU (say) [reading the numbers]: Twelve, zero three, nineteen forty-nine.
M3-039 DUARTE [typing]: December third, forty-nine. Thank you. Is he allergic to anything?
M3-040 LOU [shaking his head]: No.
M3-041 YOU (say) [for him]: No. He is not allergic.
```

*Then the instructions, fast. This is the Nod risk.*

```
M3-042 DUARTE [fast, holding up two boxes]: So: the white ones are the blood thinner, twice a day, morning and evening, with food. The blue ones are new — blood pressure — once a day, in the evening, but NOT with the white one: one hour after, OK? An hour apart.
M3-042s DUARTE (slow) [holding each box up]: White pill: morning and evening. With food. Blue pill: evening. One hour after the white pill.
```

*If the player NODS: Duarte smiles and hands them over. That night at 9 p.m., the hero gives Lou both pills together.
Lou looks at them, then at the hero, and shakes his head; the hero doesn't understand. The phone rings: Tess, from the
ER, checking (she always checks).*

```
M3-043 TESS [on the phone, alarmed, then controlling it]: Wait — both? Together? No, no — it's OK, nothing bad, but not together. One hour. Read the label, please. Always read the label.
M3-044 YOU (say) [ashamed]: Sorry, Tess. I didn't understand.
M3-045 TESS [tired, kind]: Then ask. Ask her, ask me, ask Lou. Asking is OK. Pretending is not OK. OK?
M3-046 LOU [in the background, to the hero, gently]: OK.
```

*If the player asks ("Sorry? Slower, please."), Duarte says the slow version, and the hero reads the label aloud:*

```
M3-047 YOU (say) [reading the label]: "White: two a day. With food."
M3-048 YOU (say) [reading the other label]: "Blue: one a day. One hour after."
M3-049 DUARTE [pleased]: Perfect. You'll be a nurse next.
```

*CORONADO POST OFFICE. A queue, a counter, a clerk who sings the numbers.*

```
M3-050 CLERK [sing-song]: Next, please!
M3-051 YOU (say) [reading the list]: Can I have some stamps, please?
M3-052 CLERK [quick]: How many?
M3-053 YOU (say) [looking at Lou; Lou holds up ten fingers]: Ten, please. How much are they?
M3-054 CLERK [tapping]: Seventy-eight cents each. That's seven dollars eighty.
M3-055 YOU (say) [counting]: Here you are.
```

*On the floor by the counter: a man's glove. The hero picks it up. A man in the queue is looking at his pockets.*

```
M3-056 YOU (say) [holding it up]: Excuse me. Is this yours?
M3-057 MAN [surprised, grateful]: Oh! Yes, that's mine. Thank you. Thanks very much.
```

*Home. The hero puts the change in the blue jar ($60 − $15.80 − $7.80 = $36.40; the game checks; Tess's note thanks
them in the evening, "Thank you!! All correct. — T.", or "Hmm. $10 missing? :)" if the hero spent some).*

---

## M4 · Breakfast Rush
- **Where:** Hank's Diner, 6:00–9:00 a.m.
- **Teaches:** *I like / I love / I don't like / I hate* + noun; *Do you like…?*; present simple *I / you / we / they*
  (*I work… Do you work…? We don't…*); the time (*o'clock, half past, quarter past, quarter to*); food and drink.
- **Play:** THE DINER JOB (it becomes a side loop): take orders by listening, say them to the kitchen, serve, give
  change, take tips; small talk; meet Rosa and Nico.
- **New words:** order, table, tip, kitchen, customer.

*Friday 5 June, 5:58 a.m. Still dark. Hank is alone, and his waitress has just texted him that she's quit.*

```
M4-001 HANK [desperate, fast]: Chief! Thank God. Lou said you're good. Can you work? Now? Six to nine. Forty bucks and the tips. Please say yes.
M4-001s HANK (slow) [hands together, pleading]: Work here. Today. Six to nine. Forty dollars. Please?
M4-002 YOU (say) [rolling up sleeves]: Yes. I can work.
M4-003 HANK [already throwing an apron]: You're a lifesaver. OK. Rules. You take the order. You say it to me — loud. I cook. You bring it. You take the money. Easy. Every day I work here from five. Every day I say, "Hank, why?"
```

*The diner job (the side loop's tutorial). A customer sits; a table number lights up. The order comes in natural
speech, often fast; *"Sorry?"* always works. The hero says the order to Hank ("Table four: pancakes and a coffee.").
Hank cooks; the hero serves; the bill and the change. The time is on the clock above the counter, and customers say it.*

```
M4-004 CUSTOMER 1 [an old fisherman, gruff]: Two eggs, toast, coffee. Black. Like Lou.
M4-005 YOU (say) [loud, to the kitchen]: Table two! Two eggs, toast and coffee!
M4-006 HANK [loud]: Two eggs, toast, coffee! Got it!
M4-007 CUSTOMER 2 [a young mother with a toddler, apologetic]: Hi, can I get the pancakes, no butter, and an orange juice, and — sorry — does he have a kids' menu? He doesn't like eggs.
M4-007s CUSTOMER 2 (slow) [smiling]: Pancakes, no butter. Orange juice. He doesn't like eggs.
M4-008 YOU (say) [to the toddler, smiling]: You don't like eggs? Me too.
M4-009 CUSTOMER 2 [laughing]: See? Nobody likes eggs.
M4-010 CUSTOMER 3 [a businessman on his phone, rude]: Coffee. Now. What time is it?
M4-011 YOU (say) [looking at the clock]: It's half past six.
M4-012 CUSTOMER 3 [not looking up]: Great.
```

*Small talk lines while serving (the like-chain; each regular asks one question; the player answers true):*

```
M4-013 CUSTOMER 1 [gruff, curious]: Where are you from, then?
M4-014 YOU (say) [pouring coffee]: I'm from {COUNTRY}. Do you like coffee?
M4-015 CUSTOMER 1 [a rare smile]: I love coffee. I hate tea. My wife likes tea. Forty years, she likes tea.
M4-016 HANK [from the kitchen, shouting]: And what do you do back home, chief? What's your job?
M4-017 YOU (say) [shouting back]: At home, I'm a {JOB}.
M4-018 HANK [shouting]: A {JOB}! And here you're a waiter! America!
```

*7:15. The door. ROSA ALVAREZ, 47, flour on her arms from her taqueria next door, and her son NICO, 11, in a school
shirt with a skateboard under his arm and no intention of going to school.*

```
M4-019 ROSA [fast, Spanish in the gaps, warm]: Hank! Two coffees to go, I have no time — ¡Nico, siéntate! — and one hot chocolate for this one, before he goes to school, because he IS going to school.
M4-019s ROSA (slow) [very clear, the accent strong]: Two coffees. One hot chocolate. Please.
M4-020 NICO [bored, to the hero]: You're new. Your English is bad.
M4-021 ROSA [slapping his arm]: ¡Nico!
M4-022 YOU (say) [laughing]: Yes. My English is bad. I'm new.
M4-023 NICO [fair, merciless]: You said "I is" before. To the fisherman. It's "I am". Not "I is".
M4-024 YOU (say) [carefully]: OK. I am new. Thank you, teacher.
M4-025 NICO [despite himself, a grin]: You're welcome.
M4-026 ROSA [to the hero, putting down money, looking at them seriously for a second]: Listen. I came here at nineteen. With ten words. Ten! Speak. Always speak. Bad English is English. OK?
M4-026s ROSA (slow) [one finger up]: Speak. Bad English is English.
M4-027 YOU (say) [smiling]: Bad English is English.
M4-028 ROSA [satisfied]: Good. Hank, the change is for the new one.
```

*8:30. The rush ends. Lou has been at his stool since seven, watching, eating his eggs. Hank leans on the counter, wiping
it, and talks. The fog is thick; he's telling a story, and the player can tap words.*

```
M4-029 HANK [fond, fast, pointing at the big front window]: You see that window? Nineteen eighty-eight. I'm sixteen. My first driving lesson. With Lou. In Bonnie. He says, "Slow down." I don't slow down. Boom. Right through that window. Into the pie case.
M4-029s HANK (slow) [miming a steering wheel, then a crash]: I was sixteen. Lou said, "Slow down." I didn't. Boom. The window.
M4-030 YOU (say) [amazed, looking at Lou]: Really?
M4-031 LOU [nodding, very dry]: Boom.
M4-032 HANK [laughing]: And later I bought the place. I liked the pie. Everybody on this island learned to drive with Lou. Everybody. Me, Rosa, the bus drivers, the cops — half the cops! — and every one of us, what does he say?
M4-033 LOU [instantly, two words, perfect]: Slow down.
M4-034 HANK [pointing at him, triumphant]: Slow down! Forty years. Lou Brannigan: "Slow down."
```

*Pay: $40 and the tips in a jar (the player counts them; the amount depends on how well the orders went).*

```
M4-035 HANK [handing over the money]: Same time tomorrow? Every day if you want. I open at six. You start at six.
M4-036 YOU (say) [tired, happy]: Yes. I start at six. See you tomorrow.
```

*The side loop is open: Hank's Breakfast Rush, any morning (`SIDE_STORIES.md`).*

---

## M5 · Five O'Clock
- **Where:** Lou's house; the town; Amber Beach Plaza and its old lookout tower; the garage and the residents' alley at
  night.
- **Teaches:** present simple *he / she / it* (*-s*, *does / doesn't*); adverbs of frequency; days of the week; the
  daily routine.
- **Play:** read Tess's note and follow Lou's day; he breaks it; the five o'clock tower; a quiet scene with Lou; write a
  note back; the BREAK-IN and the first foot chase; the end of Act 1.
- **New words:** note, routine, tower, torch, plate.

*Saturday 6 June. On the fridge, a new note (reading: the present simple third person, everywhere):*

> **{NAME} — Lou's day** (I work tonight, and tomorrow night)
> Lou gets up at 7. He has breakfast at Hank's. He takes a white pill at 9 (with food!).
> On Tuesdays and Fridays he goes to Dr. Rao.
> He has a sleep after lunch. (He says he doesn't. He does.)
> He **always** goes to the beach at 5. To the old tower. Why? I don't know. He never tells me.
> He has dinner at 7. White pill at 9. Blue pill at 10.
> He goes to bed at 10:30.
> He doesn't drink coffee after 4!!! — T.

*The day is played in short pieces with the clock running fast between them: breakfast, the pill, the shops, the nap
(Lou snores in the chair with Clutch on his chest; the player can photograph it for the WordBook), and at 4:10 Lou
pours himself a coffee.*

```
M5-001 YOU (say) [reading the note aloud, firm]: Lou. "He doesn't drink coffee after four."
M5-002 LOU [innocent, pointing at the clock: 4:10]: Four.
M5-003 YOU (say) [pointing too]: It's after four. No coffee.
M5-004 LOU [a sigh like a tyre going down; he pours it back]: Pfff. Tess.
M5-005 YOU (say) [laughing]: Yes. Tess. She always knows.
```

*4:45. Lou is at the door in his hat before the hero says anything.*

```
M5-006 LOU [tapping his watch, then pointing west]: Five.
M5-007 YOU (say) [getting the keys]: The beach? Every day?
M5-008 LOU [simply]: Yes.
```

*AMBER BEACH PLAZA. The end of Amber Avenue: palms, a fountain, benches facing the ocean, a kiosk, a beach shower. And the
old lookout tower: weathered white, a stair up the inside, a metal door with a sign (reading): **CLOSED FOR REPAIRS ·
REOPENS 4 JULY**. Lou goes to the same bench, the one facing the tower, not the sea, and sits. He looks at the tower.
He doesn't say anything.*

*On the next bench, with a paper cup of coffee: Peg, no vest, no sign. She doesn't look surprised.*

```
M5-009 PEG [mild]: Good evening, {NAME}.
M5-010 YOU (say) [surprised]: Good evening. Do you come here too?
M5-011 PEG [watching Lou, not the sea]: I walk here every day. And every day, at five o'clock, Lou comes here. He sits on that bench. He looks at that tower. For an hour. Then he goes home. Every day for forty years.
M5-011s PEG (slow) [counting on her fingers as she says it]: Every day. Five o'clock. That bench. That tower. Forty years.
M5-012 YOU (say) [looking at Lou]: Why does he come here?
M5-013 PEG [a small smile]: That's a good question. Ask him. He never tells me.
M5-014 YOU (say) [carefully]: He doesn't tell Tess. And he doesn't tell you.
M5-015 PEG [standing, throwing her cup away neatly]: No. He doesn't tell anybody. Goodnight, {NAME}. Do you always drive so slowly?
M5-016 YOU (say) [honest]: Yes. Always.
M5-017 PEG [already walking]: Good.
```

*The hero sits beside Lou. The sun goes down behind the tower. This is the first quiet scene between them, and the
actors should have room. The game gives the player no prompt for a while.*

```
M5-018 YOU (say) [after a while, quietly]: Lou. Why do you come here?
M5-019 LOU [not looking away from the tower; a long pause; then, almost to himself]: ...Promise.
M5-020 YOU (say) [gently]: A promise?
M5-021 LOU [nodding slowly; then he shakes his head and taps his mouth: the door is closed]: ...
```

*He changes the subject the only way he can: he points at the hero, then at his own mouth, and raises his eyebrows: and
you? The hero understands: what is it like for you?*

*A thinking moment: the words float over the water: **In / my / language / I / am / funny / .** The player orders and
says it. Then a second set: **In / English / I / am / nobody / .***

```
M5-022 YOU (say) [slowly, true]: In my language, I am funny.
M5-023 YOU (say) [quieter]: In English, I am nobody.
```

*Lou looks at the hero. Then he laughs: a real laugh, deep, from the chest, the laugh of a man who used to be very
funny. He taps his own chest.*

```
M5-024 LOU [still laughing, warm]: Me too. Funny. Before.
M5-025 YOU (say) [laughing too]: Before. Me too.
M5-026 LOU [patting the hero's knee twice; then, the first two-word sentence anyone has heard from him]: Not nobody.
```

*Home. The hero writes a note for Tess, who will find it at 7 a.m. (writing, tiles or typing; the game checks for the
he / she -s and accepts anything readable).*

> Tess, Lou is OK. He **has** eggs at Hank's. He **sleeps** after lunch (yes!). He **goes** to the tower at five.
> He **wants** coffee at four. I say no. :) — {NAME}

*NIGHT. 1:20 a.m. A sound from the garage. Then a thin light moving behind its small window. The hero wakes (the
controls: get up, go down, out of the back door, quietly; the alley is dark, a dog barks two gardens away).*

*The garage door is open a foot. Inside, a man in a red cap and a black hooded jacket is pulling drawers out of the
workbench with a torch in his mouth. The calendars have been torn off the wall and are on the floor.*

```
M5-027 YOU (say) [shouting, before thinking]: Hey! Stop!
M5-028 TROY [startled, a mumble]: — oh, man —
```

*He shoves the hero hard (the body falls: the ragdoll) and runs. THE FIRST CHASE: on foot, down the residents' alley,
past bins and fences, across 10th Street, down the side of Hillside Park. He is faster. At the bottom a black SUV is
waiting with its lights off; he jumps in; it pulls away. The game freezes for half a second on the number plate in the
street light, half of it in shadow: **7 K R ? 1 3 ?** (or is it 30? The 3 and what follows are dark.) It goes into the
WordBook as a photo, blurred.*

```
M5-029 YOU (think) [breathing hard]: Seven. K. R. ...Thirteen? Thirty?
```

*Back at the garage. Lou is standing in the doorway in his pyjamas and his hat, holding his cane like a bat. He is
shaking, and not from cold. He looks at the calendars on the floor, at the open drawers. Bonnie is untouched.*

```
M5-030 YOU (say) [going to him]: Lou! Are you OK?
M5-031 LOU [not hearing; looking at the floor]: ...
M5-032 YOU (say) [holding his arm]: Lou. Who was it?
```

*Lou looks up. He fights. The camera stays on his face; it takes a long time, and the actor needs every second of it.
Three words, his longest line in the act, each one dragged out through the closed door:*

```
M5-033 LOU [each word a separate battle; fear and anger]: Duke. ...Bad. ...Money.
```

*Cut to black.*

*Message home, end of Act 1 (writing; tiles built from Act 1's structures; the player picks and orders):*

> **{HOME}:** How is the new job? Is the old man nice?
> **Tiles:** *He is very nice. / He is old and funny. / There is a cat. / I drive a big green car. / I work at a diner
> too. / I like it here. / Tonight there was a — (the tiles stop: "was" is not known yet) / I am OK.*

*The player can't say what happened tonight. The tiles don't have the words yet. The game lets them notice that.*

```
M5-034 YOU (think) [lying awake; quiet]: Duke. Bad. Money. Three words. I don't understand. Not yet.
```

**END OF ACT 1.**
