# ALIEN STATUS: the open world

What you do between missions and after the story. Nearly all of it is the old game's content (jobs, taxi, delivery,
bus, lessons, radio, films, books, home problems, street talk, the alien dreams), put to work as play.

The rule from the bible holds here too: nothing in this file is a lesson screen. Things are worth doing because
they pay, because they are fun, or because someone you like asked.

---

## 1. A day
- **Morning:** {H} at the cooker, the radio on. The map shows today's letters.
- **Day:** a shift, a mission, a fare, the beach. One game hour is ten minutes (as now).
- **Evening:** the bar, the class on Tuesdays, the fights, the beach cinema.
- **Night:** bed. The Report. Goo eats. The game saves.

## 2. Work (the old jobs, made into shifts you play in the place itself)
The old job games were sixty-second word games on a flat screen, the same five for all 73 jobs. Their word lists
are good (`data/jobs/minigames.json`: each job's things, problems and sentences). Here those words are said by
real customers, in the real room, about real things. A shift is five to eight minutes. Pay follows the old rates
(dollars an hour by sector) and the old rule: a clean shift pays one and a half times.

| Job | Where | What the shift is | Old sector rate |
|---|---|---|---|
| Cashier | Hilltop Market | People from the street put things on the counter and ask the price. Tell them, take the money, give the change. Someone always tries to walk out with something. | shops 19 |
| Kitchen hand | Hank's Diner | Orders are shouted from the counter. Put the right things on the right plate and take it to the right table number. | food 20 |
| Room cleaner | Casa del Mar Inn | A note on every door (*two towels, no pillows, late check-out*). Six rooms against the clock. Things guests left behind go to the desk, with a description. | care 21 |
| Bike courier | Spokes Bike Repair | Parts and mended bikes to addresses across the centre. A name, a street, a number. | transport 28 |
| Library assistant (from 2.2) | Coronado Public Library | Put returned books back by the letter on the spine. Find a book for someone who can only describe it. The book bike round. | education 32 |
| Taxi driver (from 3.2) | Ferry Landing taxi bay | See *Coronado Cab* below. | transport 28 |
| Cook's hands (from 3.5) | Little Frenchy | The Friday rush, with {H} or alone. | food 20 |

- **Being late and being fired are real now** (the old game had them only as story). Three late days and Mr. Dunn's
  line comes back: *"You're fired."* `(old)` You can always get another job. Reyes will ask about it.
- **Your old job.** The job you told Sal about on day ten gives you one quiet advantage for the whole game, by its
  old sector:

  | You were in... | You are better at... |
  |---|---|
  | Health | {H}'s bar in 2.4 rises more slowly; the pharmacy is cheaper |
  | Education | Grace's class fills faster; class nights pay |
  | Food | bigger tips in every kitchen |
  | Transport | fares pay more; the driving test allows two more marks |
  | Safety | one more calm line in every talk-down |
  | Shops | better prices when you bargain |
  | Office, Tech | forms fill themselves in halfway; the CV has one more skill |
  | Arts | people stop and listen: *Look!* lasts longer |
  | Building | you climb a little faster |
  | Farming, Care | people trust you sooner: strangers talk more |
  | Sports | you run longer and hit harder |

  After day 40 the old job itself opens (`vocations.json` has a workplace for most of them; each needs a place on
  the new map).

## 3. Hustles
- **Coronado Cab** (old taxi and CityRide). Wait at the Ferry Landing bay or answer the radio. **YOU:** *"Where
  to?"* `(old)` The fare says a place, once. No pin unless you ask (and asking costs the tip). They talk: where
  they are from, the weather, their day. Answer and the tip grows. The old fare: $3.80 and $4.10 a mile.
  **YOU:** *"Here we are."* `(old)` Some fares are stories: a sailor late for his ship, a bride, a man who gives
  the wrong address three times.
- **Deliveries** (old delivery system, turned round). In 1.1 a courier brought you dinner. Now you are the
  courier: pick up at Rosa's Taqueria, Gus' Pizza, Taco Shack or Sunrise Donuts, and find the door from what the
  customer tells you on the phone about their own house.
- **The book bike.** A round a day from the library: schools, the senior centre, the hospital, the motels.
- **The vacant lot** (from 3.3). Fist fights at night for a little money, with Ivan in your corner shouting the
  only advice he has: *"Up! Down! Go!"* Nobody is badly hurt. A police car means everyone runs.
- **Sweat Circuit** (old gym workout). Makes you run and climb longer.
- **Thumb up** (old hitchhiking). Still free, still one car in five, still more if you are polite. `(old lines:
  "Hi! Do you need a ride?" "Yes, please. Can you take me there?")`

## 4. The Report (every night)
From the old alien dreams (`data/dreams/alien_dreams.json`), which were built and then switched off.
- The game keeps the old log of your day: *job, shop, fuel, ride, hitch, home, talk, ferry, beach, lesson, money,
  eat*, and now also *fight, police, bus, bike, swim, photo, trick*.
- In bed, three pictures from today. Tell them: *"I worked as a cashier." "I took a taxi." "I swam in the
  ocean."* `(old)` In chapter 1 the present is enough (*"I work. I take the bus."*). After 1.4 the past comes in,
  and Orla starts asking for it.
- **Orla answers** `(old)`: *"Wow! Tell us more!" "Interesting! On our planet we don't do that." "Amazing! Earth
  is fun."* And one real question back about what you said.
- **Zib writes it down, a little wrong.** Zib's notebook is a thing to read and collect: *"Stadium = hat." "Bus =
  best." "Is that your kid = hello."*
- **Homework for tomorrow.** One small thing, in the world:
  - a photo (the phone camera): *something red, a bus stop, a person running, your boss*;
  - a taste: eat something you have never ordered, and say what it was like;
  - a word: *"What is a queue?"* Go and stand in one, and tell them.
- **Goo gets the day's words.** Then the save.
- **Every third night is a ship night:** a mission (1.6, 2.5, 3.1, 3.6, 4.1), or a short scene on the glass floor.

## 5. Goo
- **Size.** Goo grows with the number of different words and lines you have *used* in the world (said, typed or
  tapped, to a person or a thing). Reading or hearing a word does not feed Goo. Using it does.

  | Size | Looks like | About | Trick |
  |---|---|---|---|
  | 1 | a spoonful | day 13 | Stop! |
  | 2 | an orange | 150 words | Open! / Close!, Look! |
  | 3 | a grapefruit | 300 | Up! / Down!, Come here! / Go away! |
  | 4 | a melon | 450 | Listen., Slow! / Fast! |
  | 5 | a cat | 600 | Puddle. |

  The story never needs a size you could not have by then.
- **In your ear.** The Turkish under the line, in Goo's voice. Tap a word: that word. Hold the line: the whole
  line. Ask *"Why?"*: how the sentence is built (the old game's three kinds of help: `glossary.json`, the
  translate button, `explain.json`). All free, always.
- **Goo School.** The kitchen, any time: the old phone lessons (the 13 A1 and 7 A2 topics of
  `lessons/data/grammar`), taught by a jelly that takes it very seriously. A finished lesson is a big meal for
  Goo and a new certificate on the fridge. Nobody in the game ever tells you to go.
- **The sink.** The old home problems come back as things that happen in a house with a jelly in the plumbing:
  the blocked sink, the leaking tap, no hot water, the power cut, the broken heater, locked out. You ring the
  plumber or the landlord `(old: "I called the plumber.")` and then keep him away from the sink.

## 6. People
- **{H}.** Dinner most nights: *pizza or tacos?* Cook together once you have worked a kitchen. The sofa talk
  `(old: "Do you like music?" "What do you do in your free time?")` is how you learn what {H} likes, and what
  {H} writes down. After 2.5, the weekly report is something you do together.
- **{F}.** The town beach. Swim to the buoy and back; later, further. The beach cruiser routes round the island
  ring. On Sundays, the board: {F} surfs, you fall off. The library's thirty easy books (old book reader): read
  one and you have a story to tell the aliens that night.
- **Sal.** Fares, the radio in his taxi (the old five stations; *City Talk* is the one he argues with), and a
  phone call whenever something happens on the island. Always too fast, always sorry.
- **Ivan.** The lot. He rings with one word (*"Help."* *"Food?"* *"Car."*) and you work out the rest.
- **Grace.** Tuesday nights. Each week she asks one student to teach, and it is often you: how to order a
  coffee, how to talk to the police, how to ask the way. What you did in a mission last week, you now show ten
  people.
- **Omar, Lina, Yusuf, Mei.** One small story each, three visits long:
  - Omar wants to sell his own food from a trolley at the Ferry Landing and needs a sign, a price list and a
    permit (Public Works Permits, in the docks).
  - Lina is making a dress for someone and will not say who.
  - Yusuf wants a chess game by post with his brother. You write the moves on cards at the post office.
  - Mei wants to be a nurse again. The form is long. (Bayview Wellness Center, the hospital.)
- **Sam** still works for Mr. Dunn and still thinks it was unfair.
- **Officer Reyes** eats lunch alone on the memorial green by City Hall. You can sit down.
- **Everybody else.** The old street talk (`npc/talk`: the 92 small exchanges and the seven topics) stays, with
  one change: people remember. The woman at the bus stop you spoke to on Monday says hello on Tuesday. Twenty
  people on the island become **regulars**, with a name and a few lines that move on each time.

## 7. Gold lines
The old game's fifty expressions (`expr.*`: *Break a leg, It's on me, No worries, Take it easy, Here you go...*)
are the game's collectibles.
- You **hear** one: it shows in gold, as now, and goes in your phone.
- You **use** one, to anybody, where it fits: it is yours. Yours means something small and real: a better price,
  a bigger tip, a calmer police officer, a friend who laughs.
- Some are only said in one place by one person. *"On Uncle Sam"* is Sal's. *"Welcome aboard"* is Mr. Dunn's.
- Rhodes speaks almost nothing else. Every idiom he uses on you in 2.6 and 3.7 can be found, and learned, and
  used, somewhere on the island before day 40.

## 8. Things to find and do
- **Zib's notebook:** forty pages, one for each thing Zib got wrong.
- **Photos:** the aliens' homework album.
- **The thirty books** at the library.
- **The beach cinema** beside Hotel Bel: the old game's ten short films, one each evening. One of them is called
  *Hello Earth!* Take Orla.
- **The radio:** five stations, in any car.
- **Every room:** the map has about 190 places you can walk into. Each has someone to say one thing to.
- **Every bus stop:** ride both lines all the way round. Zib has.

## 9. Trouble
| | What starts it | What ends it | What it costs |
|---|---|---|---|
| **Stars** | fighting, hitting people or cars, driving badly in front of a patrol car | out of sight, or stop and talk at one or two stars | a fine of $50 a star if they catch you, and a **strike** |
| **Strikes** | being caught | nothing: they stay on the paper | three before a check-in: back to the camp for a night, and the day starts again |
| **Hum** | tricks, where people can see | walking away; it fades | a helicopter; in chapter 4, vans |

## 10. Money
- You start with the old game's $20 in your pocket and $200 in the bank.
- Rent is $400 every ten days from day 24.
- If you cannot pay, the game does not end (the old *"You're broke!"* screen is gone). You lose your key until
  you can. You sleep on the beach or in a car, wake up stiff, and the police move you on. The Report still comes:
  Orla is very interested in what a bench is.
- The bank, the cash machines, paying by phone: as in the old game.

## 11. After day 40
The clock is gone. The rent, the class, the cab, the lot and the Report go on. Your old job opens. The attic is
either empty, or full, or waiting for a very long form to be answered. The next story (A2) starts from there.
