# ALIEN STATUS: the open world

Version 2 (GTA rework). What there is to do between missions and after the story. The island is open from the
moment you get out of Sal's taxi on day ten.

Nearly all of it is the old game's content (jobs and their minigames, the alien dream, taxi, delivery, bus,
lessons, radio, films, books, home problems, street talk, beggars) plus Yasin's list of 28 Nov: the birds, the
sea, car races, hobby clubs, strangers in every neighbourhood.

Each thing here is met once inside a story mission before it is left for you to find again.

---

## 1. A day
- **Morning:** {H} at the cooker, the radio on. Today's letters on the map.
- **Day:** a shift, a mission, a fare, a club, a car that is not yours. One game hour is ten minutes.
- **Evening:** the bar and its darts, the class on Tuesdays, the dance night, the races, the fights.
- **Night:** bed. The Report. Goo eats. The game saves.

## 2. Work: the old job minigames
A shift is the old work day, as it was (`jobs/jobs.gd`, `minigames/jobs/`): you go to the place, start work, and
play **two of the five old minigames**, sixty seconds each, picked by the day, on that job's own words
(`data/jobs/minigames.json`). **Voice only**, as Yasin set it. Pass with three right, flawless with no mistakes.
Pay is the old rate by sector; two flawless games pay one and a half times.

| Minigame | How it plays (unchanged) |
|---|---|
| **Triage** | Three problem cards with urgency bars. Tap them in order, then say: *"First I will X, then I will Y, and finally I will Z."* |
| **Beat shift** | The job's words fall in three lanes. Say each one as it crosses the line. |
| **Conveyor** | Things slide along a belt. Name the one in the frame: *"a large cup"*. |
| **Spot the problem** | Nine things in a grid. Tap the wrong one and say it: *"The cup is dirty."* |
| **Sentence stack** | Sentences fall. Keep the ones about this job (say them for double), clear the others. |

Two changes only: the game is played **in the place** (the camera sits at the counter, the pass or the desk,
with the real room and people behind it), and the filler lines that were copied between jobs are replaced with
lines about that job.

| Job | Where | From | Old rate |
|---|---|---|---|
| Cashier | Hilltop Market | 1.2 | shops 19 |
| Kitchen hand | Hank's Diner | 1.2 | food 20 |
| Room cleaner | Casa del Mar Inn | 1.2 | care 21 |
| Bike courier | Spokes Bike Repair | 1.2 | transport 28 |
| Library assistant | Coronado Public Library | 2.2 | education 32 |
| Taxi driver | Ferry Landing taxi bay | 3.2 | transport 28 |
| Cook | Little Frenchy | 3.5 | food 20 |
| Your old job | wherever it fits on the new map | after day 40 | its sector's |

- **Every shift has one thing that is not a minigame:** a thief to chase, a customer who faints, a delivery to
  the wrong door, a fight in the queue.
- **Late and fired are real now.** Three late days: *"You're fired."* `(old)` Reyes asks about it.
- **The job you had at home** gives one quiet advantage all game, by its old sector: Health ({H}'s bar rises
  more slowly, cheaper hospital bills), Education (class nights pay), Food (bigger kitchen tips), Transport
  (fares pay more, faster in races), Safety (one more calm line with the police), Shops (better prices), Office
  and Tech (forms half filled in), Arts (*Look!* lasts longer), Building (you climb faster), Farming and Care
  (strangers trust you sooner), Sports (you run longer and hit harder).

## 3. The Report: the old alien dream, every night
As it was built (`minigames/alien_dream.gd`, `data/dreams/alien_dreams.json`), switched back on.
1. Bed. Green. **Zib and Orla:** *"Hello, Earth friend! We are Zib and Orla. Tell us about your day!"* `(old)`
2. **Order.** Today's real events as pictures (the old log: *job, shop, fuel, ride, hitch, home, talk, ferry,
   beach, lesson, money, eat*; now also *fight, chase, race, police, bird, swim, club, stranger, car*). Put them
   in the order they happened.
3. **The scramble.** For each, build the sentence from word tiles and say it. The past form is in the tiles and
   so is its trap, exactly as the old data has them: *worked / worken, bought / buyed, took / taked, got /
   getted, called / calt, talked / talkt, swam / swimmed, ate / eated, woke / waked, had / haved, walked /
   walkt, saw / seed.* New events get new pairs: *drove / drived, ran / runned, won / winned, fought / fighted,
   stole / stealed, hit / hitted, caught / catched, flew / flied, shot / shooted, fell / falled.* (The old
   data lists *learnt* as wrong. It is not; that pair goes.)
4. **Pick the past** for one more: three forms, one right.
5. **Tomorrow** (from the second night): *"Tomorrow I am going to ___."* `(old)` Whatever you say goes on the
   map as a reminder.
6. **Orla:** *"Wow! Tell us more!"* / *"Interesting! On our planet we don't do that."* / *"Very good! We
   understand you."* / *"Amazing! Earth is fun."* `(old)` Zib writes it down, slightly wrong.
   *"Thank you! Your English is great. Sleep well, Earth friend!"* `(old)`
7. Goo eats the day's words. The game saves. A clean Report (no trap tile taken) charges your kit to full.

- **Homework.** One small thing for tomorrow: a photo (*something red, a bus stop, your boss*), a taste, a word
  (*"What is a queue?"*: go and stand in one).
- **Every third night is a ship night:** 1.6, 2.5, 3.1, 3.8, W3, 4.1, 4.4.
- The same scramble is used three times with humans: {H} in 1.4, Reyes at each check-in, and the judge in 4.5.

## 4. Goo and the kit
Goo grows with the number of different words and lines you have *used* in the world. Reading or hearing does not
feed Goo. Using does.

| Goo | Looks like | About | Kit that needs it |
|---|---|---|---|
| 1 | a spoonful | day 13 | Stopper; *Open!* |
| 2 | an orange | 150 words | Puddler; *Look!* |
| 3 | a grapefruit | 300 | Lifter; Hummer; *Come here!* |
| 4 | a melon | 450 | Shrinker; *Listen.*; bird view |
| 5 | a cat | 600 | Goo bombs; *Puddle.* on yourself |

The story never needs a size you could not have by then. Kit charge runs down as you fire and comes back with
sleep, a clean Report, or sugar (Goo likes soda).

- **In your ear:** the Turkish under the line, in Goo's voice. Tap a word; hold the line; ask *"Why?"* (the old
  game's three kinds of help). Free, always.
- **Goo School:** the kitchen, any time. The old phone lessons (13 A1 and 7 A2 topics), taught by a jelly. A
  finished lesson is a big meal and a certificate on the fridge. Nobody ever tells you to go.
- **The sink:** the old six home problems (blocked sink, leaking tap, no hot water, power cut, broken heater,
  locked out) happen in a house with a jelly in the plumbing. You ring the plumber `(old: "I called the
  plumber.")` and keep him away from the sink.

## 5. Cars
- **Take any car.** Standing, parked or moving. The driver fights or runs (the game has this). A car alarm is a
  star.
- **The garage** on the alley behind the house holds four. What is in it is yours.
- **Ivan's list** (from 3.3). A board at Big Al's Tires, new each week, in words: *a red pickup, a white van, a
  blue taxi, a black sports car, the bus.* Read it, find one, bring it in one piece. Later lists say more: *a
  green saloon with a dent in the left door.*
- **Fix, clean, fill:** Bridge Tire Pros and Junction Auto Glass mend it. Ten Minute Lube makes it faster for a
  day. **Bayside Express Wash** takes the stars off it. Shoal sells fuel, as in the old game: *"Twenty dollars
  on pump two, please."* `(old pattern)`
- **Sal** will lend you the taxi. **Bridge Motors** will sell you something, after an argument about the price.
- Bikes: the beach cruiser, from any rack.

## 6. Races
You meet each kind in the story (1.3 bikes, 3.2 taxis, 3.9 the ring). Then they are on the map with a flag.

| Race | Route | Start | With |
|---|---|---|---|
| **Beach bikes** | Amber Ave, 10th St to the sea; the promenade end to end | Trident Café | {F} |
| **Fare race** | Ferry Landing to Hotel Bel; to the hospital; to the stadium | the taxi bay | Sal, against Island Cab |
| **The Ring** | Alameda, Ocean Blvd, Glorietta Blvd, 1st St: one lap of the island | Big Al's Tires, midnight | Ivan's crowd |
| **The Hill** | 4th St over Crown Hill and back (the postcard drive) | the base gate | Ivan's crowd |
| **The Lot** | cones and barrels in the Tailgate Lot | the stadium | Sal's stopwatch |
| **The Docks** | a straight quarter mile on J Ave | Harbor Freight | Ivan's crowd, for slips |
| **Roofs** | on foot: the Quad to the Science Tower; 10th St to the construction site | Coronado University | the Roof Club |

- **Your co-driver calls the road**, a second ahead: *"Left! Hard right! Straight on! Bus! Go round!"* Sal is
  clear. Ivan has fifty words. {F} shouts over a shoulder. Hear it and you keep your speed.
- **For slips:** win and you keep the other car. Lose and yours goes to Ivan's list.
- Traffic is real, the police are real, and kit is allowed unless somebody finds a clause.

## 7. Hobby clubs
Ten clubs. Each has a door, a person, a minigame, three ranks, a thing you get, and one small story.

| Club | Where | The minigame | What you get |
|---|---|---|---|
| **Coronado Bird Club** | Finch's van, the Crest Lookout | Through the camera: find the ones that do not blink before they find your lens. Then describe it to Finch: *"It is grey. It is on the red car."* | bird view lasts longer |
| **Gull Tavern Darts League** | The Gull Tavern | 301. Throw, then **say what is left**. Say it wrong and the bartender takes the points. | free drinks; the tavern as a hiding place |
| **Dance Night** | Hill Rec Center, Fridays | The caller calls the steps a beat early: *"Left. Right. Turn. Clap."* {H} is your partner. | {H} teaches you the shove-and-spin; an outfit |
| **Pier Fishing Club** | Pier Bait & Tackle, the pier | Cast, wait, reel on the pull. Then name it and its size to the club book. | fish sell at Dockside Fish Market |
| **Wheels** | Ocean Park Skate | Bike tricks on the plaza: the kid on the wall calls the next one, you land it. | a faster cruiser |
| **Sweat Circuit** | the gym, civic band | The old gym game: the rep on the beat. Then three rounds in the ring. | health; a harder punch |
| **The Lot** | the vacant lot, nights | Fist fights for small money, Ivan in your corner with his only advice: *"Up! Down! Go!"* | money; a name |
| **Community Kitchen** | Christ Church Community Center, Thursdays | Omar reads a recipe once. Cook it: *first, then, a little, a lot, don't burn it.* | food that refills health; {H}'s respect |
| **Book Club** | Coronado Public Library | The old thirty easy books. Read one; at the club, say who did it and why, and vote. | a story to tell the aliens for a big Report |
| **Yusuf's Table** | Tenth Street Park | A dice board game. **Call your dice** before you move: *"Six and five!"* Yusuf cheats, gently. | gold lines; the pawn's whole story |
| **The Roof Club** | Coronado University | Students who run the campus roofs. Time trials on every climbing move. | climbing stamina; routes marked on the map |

(Eleven, with the Lot. The Lot is not exactly a club.)

## 8. Strangers
In every neighbourhood people stop you. A small **?** on the map when one is near. A ten-second cutscene, a
request in plain fast English, and your answer: *yes*, *no*, *how much?* Some want money, some a small job, some
a favour. About one in five is lying, and the way to tell is to listen.

| Neighbourhood | Who stops you | What they want |
|---|---|---|
| Base gate, Alameda | the man with the cup; a sailor late for the gate | a dollar (he remembers you all game); a lift, fast |
| High street | a lost tourist with a map; a busker | the way to Hotel Bel (give it right and they tip); a request for a song |
| Hill rows, 10th St | a woman locked out; a man with a ladder | climb in at the window; hold it while he does the gutter (he is not the owner) |
| Amber beach | a mother who has lost a child's ball in the water; a man selling watches | swim for it (inside the buoys); forty dollars for nothing |
| City centre | a man in a suit who dropped his phone down a drain; a woman with leaflets | *Lift!* it out; a signature (read it first) |
| Construction site | the foreman | a tool left on the top deck: climb for it |
| Apartment band | two students and a sofa; a man with flat tyres | carry it up; push him to Hill Street Bikes |
| Civic band | a boy whose kite is in a tree; a couple outside City Hall | climb for it; be the witness at their wedding, and say the line |
| University | a student with a camera; one with a late essay | *"Can you film my jump?"*; drive it to Founders Hall in four minutes |
| Stadium | a man with tickets; a lost fan | the tickets are for last year; walk him to Gate C |
| Gritty edge | a beggar; a man whose bike was just taken | change `(old beggars)`; chase the thief over the fences |
| Docks | a driver with a full truck; a fisherman | help unload, by the label on each box; carry his catch to the market |
| Commercial strip | a woman with a dead battery; a boy with a shopping trolley | drive her to Strand Auto Parts; race him across the car park |
| Hospital | a patient in a gown outside the door; a nurse | a taxi to anywhere (he should not be out); hold the lift, find Dr. somebody by name |
| Ferry Landing | a family with a camera; a man with a suitcase | *"Can you take a photo of us?"*; watch it for one minute (do not) |
| Crown Hill | an old lady with shopping; a gardener | carry it up the steps; lend a hand, and a Lifter |
| Glorietta | a jogger who has lost her keys; a man painting the bay | find them by where she says she ran; stand still for his picture |
| East shore | a swimmer in trouble; a lifeguard | swim out and bring him in; watch the water while she eats |
| Waterfront, marina | a boat owner locked out of his cabin; a man who says he is one | *Open!*; *Open!* (it is not his boat) |

- A stranger you helped becomes a **regular**: a name, a wave, a few lines that move on each time, sometimes a
  second job. Twenty-odd on the island.
- A stranger you robbed remembers too.

## 9. The birds
- Gulls on the lamp posts, pigeons on the wires, crows on the fences. One to three are always where they can see
  you. Their heads turn to follow. They do not come indoors; they wait at the door you used.
- They are in the frame of every cutscene.
- Finch tells you in W1. You learn what they are in W3. After W3 you can look through them (**bird view**).
- **They cannot be killed.** Hit one with a fist, a car or a weapon and it does not fall. The sound cuts. Its
  head turns all the way round. Its eye is green. Black. Then one of six games, sixty to ninety seconds each.
  Each attack brings the next one in the list; after six they come round again, harder.

| # | The game | What you do |
|---|---|---|
| 1 | **Don't Look Away** | Your own street at dusk, a hundred birds on it. They move only when you are not looking at them. Get to your front door, backwards. |
| 2 | **The Wire** | A long street at night, every wire full. The street lights go out one by one behind you. Run, vault, climb: reach the last light. |
| 3 | **Playback** | Your phone rings. It is your own voice: things you said today, the words in the wrong order. Something with a bird's head takes one step closer for each. **Put the words back in order** to stop it. (The scramble, in the dark.) |
| 4 | **Roll Call** | The camp yard at night. A line of people in orange shoes; they all have birds' heads. The guard calls orders: *"Look left. Get down. Don't move."* Do exactly that. One wrong move and the line turns round. |
| 5 | **Feeding Time** | You are the size of a crab on the beach. The gulls are the size of houses. Sand castle to sand castle to the storm drain. |
| 6 | **The Eye** | Your bed. *"I can't move!"* `(old)` A bird on your chest, walking up it. Hit the side of your phone, as you did for the goo in your ears `(old)`, until you can. |

- **Get through:** you wake where you stood. A feather in your pocket (six kinds; Finch pays for them).
- **Fail:** wasted. *"We put you back together. It took a long time."* `(old)` The doctor: *"A bird? Gulls don't
  do that."*

## 10. The sea
- A line of orange buoys rings the island. {F}, Finch, a teacher and a lifeguard all tell you not to pass it.
- **Past the buoys, nine times in ten:** the music stops. The water gets dark. A fin crosses in front of you,
  goes down, and comes up behind. One short cutscene. *"We put you back together. It took a long time."* `(old)`
  You wake in bed, and that night Orla asks, a little coldly, why you *swam*.
- **One time in ten:** no fin. Keep swimming. The waves stop. The water is flat as a floor. And your hand
  touches the sky.

### The edge (three visits; the odds are rolled again every swim)
1. **The wall.** The horizon is paint on a curved wall, sea-colour below, sky-colour above, a little faded where
   the water touches it. A steel ladder. A grey door with a wheel. Above it, a word in a writing you have seen
   on Zib's notebook, and under that, in English: **CREW.** It is locked. On the ladder, a gull, looking at you.
   You knock. White. Your bed. *"Huh? It's morning... Was it a dream?"* `(old)` Your clothes are wet.
2. **The corridor.** The door is open a hand's width. Cables on the floor. A wall of screens: each one is a
   bird's view of somebody you know. {H} cooking. Sal at the taxi bay. Reyes eating lunch alone. Rhodes, asleep
   at a desk. A board of small cards in rows: every mission you have played, with a title and a number of stars
   out of five. (2.2 *"You're Fired"* got five. So did the bar fight.) A voice round the corner. White. Your bed.
3. **The room.** A round room like the ship's. One chair. Zib is in it, in front of every screen at once,
   wearing headphones. Zib turns round, and for the first time, speaks. Very slowly, very carefully, in an
   accent made of every person you have talked to: **Zib:** *"You. Should not. Be here."*
   What Zib tells you, in the smallest words in the game:
   - The island is real. The people are real. *"The sky is... helped."*
   - The birds are cameras. The sharks are theirs. *"For safety. Yours."*
   - The Report goes home every night. *"It is a small show. They love you there."*
   - It is how they pay for the trip. *"Forty light years is expensive."*
   - And at home, very many of them watch it to learn. *"They say your words. 'Slowly, please.' 'It's on me.'
     They say 'taked'. I am sorry about 'taked'."*
   **Zib:** *"Please. Go back. Day forty is the finale."* Zib gives you a jacket that says CREW on the back.
   White. Your bed. The jacket is on the chair.

After the third visit: the screens become a thing you can come back to (the game's own statistics, as an alien
control room: hours, words, arrests, stars per mission), and now and then a letter is pushed under your bedroom
door in careful English from somebody very far away who has been watching, and has a question about *usually*.

## 11. People
- **{H}.** Dinner most nights: *pizza or tacos?* The sofa talk `(old: "Do you like music?")`. Dance Night. After
  2.5, the weekly report is something you write together.
- **{F}.** The beach, the bikes, the board on Sundays, the Book Club.
- **Sal.** Fares, races, the radio (the old five stations; he argues with *City Talk*), and a phone call
  whenever anything happens on the island.
- **Ivan.** The list, the Ring, the Lot. He rings with one word (*"Help."* *"Food?"* *"Car."*).
- **Grace.** Tuesday class. Often you teach: what you did in a mission last week, shown to ten people.
- **Finch.** The Bird Club. He will also tell you, twice, where the Navy is tonight.
- **Omar, Lina, Yusuf, Mei.** One small story each, three visits: Omar's own food trolley at the Ferry Landing
  (a sign, a price list, a permit from Public Works Permits); Lina's dress for someone she will not name;
  Yusuf's game by post with his brother; Mei's form to be a nurse again.
- **Reyes** eats lunch alone on the memorial green by City Hall. You can sit down.
- **Coronado Cab** (old taxi): **YOU:** *"Where to?"* `(old)` The fare says a place once. They talk; answer and
  the tip grows. **YOU:** *"Here we are."* `(old)`
- **Deliveries** (old delivery, turned round): you are the courier now, finding doors from what people say about
  their own house.
- **Thumb up** (old hitchhiking): `(old: "Hi! Do you need a ride?" "Yes, please. Can you take me there?")`

## 12. Things to find
- **Gold lines:** the old fifty (`expr.*`) and Rhodes's idioms. Hear one and it goes in your phone. Use one
  where it fits and it is yours: a better price, a bigger tip, a calmer officer.
- **Feathers:** six kinds.
- **Zib's notebook:** forty pages, one for each thing Zib got wrong.
- **Photos:** the aliens' homework album.
- **The thirty books.** **The ten films** at the beach cinema by Hotel Bel (one is called *Hello Earth!* Take
  Orla). **The radio.**
- **Every room:** about 190 places to walk into, each with someone to say one thing to.
- **The edge**, three times.

## 13. Trouble and money
| | What starts it | What ends it | What it costs |
|---|---|---|---|
| **Stars** | fighting, taking cars, kit in public, bad driving in front of a patrol car | out of sight, indoors, new clothes, the car wash, or talk at one star | busted: $50 a star, your kit until you sleep, and the number read out by Reyes |
| **Hum** | kit, where people can see | walking away | four stars of Navy |
| **Wasted** | fists, falls, cars, stun rifles, pistols, sharks, birds | Orla | a hospital bill, or nothing, and a remark |

- You start with the old game's $20 in your pocket and $200 in the bank.
- Rent: $400 every ten days from day 24. Miss it and you lose your key until you can pay: the beach, a car, the
  police moving you on. (The old *"You're broke!"* game over is gone.)
- Money comes from shifts, fares, Ivan's list, races, the Lot, strangers, clubs and other people's tills.
