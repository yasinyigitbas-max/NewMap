# THE GRAND: music (Version C)

Every music cue of Version C, in words, for composers, songwriters and the audio programmer. Cue ids `MUS-Cxx` match
SCRIPT.md. All lyrics here are original and written for this game.

## 1. The three motifs (the whole score grows from them)
The score is built from three short melodies. Every cue uses at least one of them, so the music tells the story even
when nobody speaks.

### A. "Home" (the music box)
- **What it is:** eight notes played by the hero's wooden music box from home. Simple, a little tinny, sweet.
- **Notes:** in D major, 6/8: A – D – E – F# – E – D – B – A (the last note held). Easy to hum.
- **Where it goes:** it *is* the main theme's melody (`MUS-C04`). In the prologue it is small and alone. By the end it
  is sung by 140 staff. The music box itself is a prop and a sound (a hand-cranked comb mechanism, slightly out of
  tune on the 6th note: B is a few cents flat, which makes it ours).
- **Why:** the player should feel that home did not disappear; it became something bigger in a new place.

### B. "Lucerito" (Luz's lullaby, hidden inside Hale's waltz)
- **What it is:** a Mexican-style lullaby Luz sang to her boy in the Annex (full song: `MUS-C40`).
- **Notes:** A minor, 3/4: E – A – B – C – B – A – G# – A.
- **The secret:** Hale's villain theme (`MUS-C13`) is an elegant waltz in C major whose melody is *this lullaby turned
  upside down and dressed in silk*: C – G – F – E – F – G – A – G, with trills and harpsichord ornaments. Most players
  will never notice. In M27 the real lullaby is heard faintly under his waltz for the first time; in M29 and M30 it is
  played plainly on a guitar, and the waltz is gone.
- **Why:** the villain's music hides his mother's song, the way his posh accent hides the boy from the laundry.

### C. "The Whistle" (Wendell)
- **What it is:** two notes, whistled, rising a perfect fourth (A to D). Wendell's doorman whistle.
- **Where it goes:** the first sound of welcome (P1), the funeral (M21), the lookout call (M26), the last firework
  (M29), the end-credits hook (`MUS-C43`), the very last sound of the game.
- **Note:** A to D is also the first two notes of "Home". Wendell's whistle is the start of the hero's home melody.
  Nobody in the story knows this. The music does.

## 2. Rules for the score
- **Diegetic first.** A hotel is full of music: the lounge piano, the ballroom band, Amparo's karaoke speaker, the
  Annex radio, car radios. Where a scene can have its music *inside* the world, it does. Non-diegetic score is kept
  for chases, stealth, and the big emotional moments.
- **The laundry is the drum kit.** The washers' drum, the dryer tumble, the chute's thump, the front desk bell, the
  brass lift chime and the time lock's tick are recorded clean and used as percussion across the score. The hotel's
  own sounds become its music.
- **Stems, not tracks.** Every gameplay cue is delivered as stems (usually 4–6: rhythm, bass, harmony, melody,
  tension, sweetener) so the game can add or drop layers by state (calm / alert / chase; the planning board's gaps;
  the gala clock).
- **Loops.** Every looping cue has a loop point at a phrase end (4 or 8 bars), plus a 2-bar outro sting for clean
  exits.
- **Needs and the mix.** When the hero is very hungry or very tired, the music's high frequencies roll off slightly
  and the tempo of looping cues slows 3 % (the world feels heavy). When the bladder is full in stealth, a soft
  ticking hi-hat is added to any stealth cue (the comic pressure).
- **Language and the mix.** In scenes where the Word Fog is thick, music ducks lower under speech than usual (−4 dB
  more), so the player can listen. As the player's level rises, the ducking returns to normal.
- **Vocals.** Sung lines with lyrics are recorded so that every word is clear (they are also language content: the
  lyrics enter Notes when heard, and S10 Sonny's Requests uses them).

## 3. The cue list

### Prologue

#### MUS-C01 "Twenty Hours"
- **Scene:** P1, the suitcase, the journey, the Bridge, the back door.
- **Mood:** tender, lonely, brave.
- **Tempo / key:** 66 BPM, D major (6/8), moving to B minor on the Bridge.
- **Instruments:** starts *inside* the music box (the Home motif, 8 notes); a solo nylon-string guitar takes it over;
  a soft string pad joins on the bus; rain and the bus engine are mixed as texture; the guitar ends alone.
- **Vocals:** none.
- **Changes:** non-looping, scored to picture. At the hotel door, the last guitar note is held and becomes the first
  chord of `MUS-C04` (two bars only, then cut to black on the title).

#### MUS-C02 "Back of House"
- **Scene:** P2, the HR glass box.
- **Mood:** dry, bureaucratic, a little funny.
- **Tempo / key:** 92 BPM, F major, swung.
- **Instruments:** a dryer's tumble used as a shaker; brushed snare; upright bass; a clock-like marimba; a muted
  trombone that "sighs" every 8 bars; the badge printer's chunk-chunk sampled on beat 4.
- **Vocals:** none.
- **Changes:** loops (8 bars). Stops dead when Hale enters (a cut, not a fade: the room goes silent).

#### MUS-C03 "Seven Days"
- **Scene:** P2 end (Amparo) and the P3 montage; later the laundry's day theme in Act 1.
- **Mood:** busy, warm, hopeful.
- **Tempo / key:** 104 BPM, G major.
- **Instruments:** the washers' drum loop as the beat; ukulele; hand claps; a bass line on a Fender bass; Amparo's
  humming (a real voice, the actor's, recorded loose); on Day 7, a small brass section and a tambourine.
- **Vocals:** humming only (Amparo).
- **Changes:** built in 7 layers; the montage adds one per day. In Act 1 free play inside the laundry, the game uses
  layers 1–4 and adds the brass when a sorting combo is high.

#### MUS-C04 "The Grand (Main Theme)"
- **Scene:** the end of P3 (first full statement, instrumental); M6 end (muted trumpet); M13 end (full band and a
  humming choir); M26 lookout; M30 Palm Court (sung by the staff: `MUS-C41`). The title screen uses the instrumental.
- **Mood:** big, warm, swinging, a little bittersweet: a grand old hotel with a beating heart.
- **Tempo / key:** 116 BPM, D major (the Home motif's key), a shuffle groove.
- **Instruments:** big band (four trumpets, four trombones, five saxes), rhythm section (piano, upright bass, drums
  with brushes in verses and sticks in choruses), a Hammond organ, a string section in the last chorus, the front-desk
  bell on beat 4 of the intro.
- **Vocals (the vocal version, used for the trailer and `MUS-C41`):** a warm lead voice (alto or baritone, the
  casting is open), with a gospel-style choir in the last chorus.
- **Melody:** the Home motif is the chorus melody, note for note.
- **Lyrics (full):**

> **Verse 1**
> Five a.m., the rain comes down on the back-door light,
> One suitcase and a squeaky wheel and nobody in sight.
> A hundred years of windows, and not a single one was mine,
> But somebody held the door for me and said, "You'll be fine."
>
> **Pre-chorus**
> And I didn't know the words yet,
> I only knew the tune...
>
> **Chorus**
> Oh, the Grand, the Grand, she was built by tired hands,
> Folded sheets and borrowed English, and a hundred broken plans,
> Twenty countries at one table learning one way to say "stay":
> Leave a light on in the laundry, we are coming home today.
>
> **Verse 2**
> Blue is for the swimming pool and white is for the rooms,
> Red is for the kitchen, and the green one's for... I'll learn it soon.
> There's a soup that isn't on the menu, there's a song that's out of tune,
> And the steam comes up the staircase like a warning or a moon.
>
> **Pre-chorus**
> And I didn't know the words yet,
> But I was learning soon...
>
> **Chorus**
>
> **Bridge**
> They wrote it small, they wrote it fast, they thought we'd never read,
> But every word they hid from us, we learned and said instead.
> So read it out and read it loud, from the basement to the dome:
> A door is just a wall, my friend, till someone walks you home.
>
> **Last chorus (key change up a tone, the choir in)**
> Oh, the Grand, the Grand, she was built by tired hands,
> Folded sheets and borrowed English, and a hundred broken plans,
> Twenty countries at one table, and we finally found the way:
> Leave a light on in the laundry. We are home. We're here to stay.

- **Changes:** the instrumental version loops on the chorus (16 bars). A slow solo-piano version is used on the pause
  menu.

### Act 1

#### MUS-C05 "Main Character" (KSDX radio)
- **Scene:** M1, Courtney's phone and the van radio (diegetic); also on car radios across the game (station KSDX).
- **Mood:** bubbly, shiny, self-aware pop.
- **Tempo / key:** 124 BPM, A major.
- **Instruments:** bright synth pluck, a four-on-the-floor kick, finger snaps, a funky guitar.
- **Vocals:** a young pop singer (fictional artist "Kaylee Shore"), breathy and confident.
- **Lyrics (radio edit: verse and chorus):**

> I wake up in my best light, I narrate my own coffee,
> Every stranger on the sidewalk is a background in my movie,
> Got a ring light in my pocket and a filter on my heart,
> And the credits haven't rolled yet, 'cause I'm only at the start.
>
> I'm the main character, main character,
> Walking in slow motion down the avenue,
> I'm the main character, main character...
> (spoken) Wait, who are you?

- **Changes:** diegetic only; the van's speaker EQ (tinny). Courtney sings the chorus over it, a half-step flat.
  The spoken last line becomes a running joke (Courtney says it to the hero in S1).

#### MUS-C06 "Suds & Duds" (Birdie's theme)
- **Scene:** M1 (the laundromat), M10, M22; the Spin Room when Birdie is in it.
- **Mood:** slinky, sly, retro; an old pro who has seen everything.
- **Tempo / key:** 88 BPM, E minor, swung.
- **Instruments:** brushes; walking upright bass; bass clarinet melody; vibraphone; the polyrhythm of twenty washers
  (recorded in a real laundromat, cut into a 7-against-4 pattern under the beat).
- **Vocals:** none.
- **Changes:** loops (8 bars). In M22 a stripped version: bass clarinet alone, rubato, no swing.

#### MUS-C07 "The Annex" (home base)
- **Scene:** M2, the Annex in free play; slow version in M20 (the roof).
- **Mood:** cheap and warm; a home made of other people.
- **Tempo / key:** 78 BPM, C major.
- **Instruments:** lazy nylon guitar; a harmonica (Dawit's, played badly on purpose: two bum notes per loop); a
  radio's crackle; distant voices in many languages through walls (sound design layer).
- **Vocals:** none.
- **Changes:** loops (16 bars). At night, the guitar is replaced by a soft electric piano. Slow version (M20):
  harmonica alone, 64 BPM.

#### MUS-C08 "Amber Ave" (the high street by day)
- **Scene:** M3; Amber Ave free roam by day.
- **Mood:** bright, walking, sunny, a little silly.
- **Tempo / key:** 108 BPM, F major.
- **Instruments:** ukulele; hand claps; Wurlitzer; a glockenspiel answering phrases; a light shaker.
- **Vocals:** none.
- **Changes:** loops (16 bars); a "shop interior" version with the drums dropped; resolves on a happy chord at mission
  end.

#### MUS-C09 "Juju's Run"
- **Scene:** M3 (the onion chase), M7 (the skateboard race), Juju's courier side jobs (S2).
- **Mood:** fast, cheeky, punk.
- **Tempo / key:** 168 BPM, E major (punk power chords).
- **Instruments:** fast punk drums; a surf guitar with spring reverb; slap bass; skateboard wheel sounds sampled as
  a riser; a gang shout ("HEY!") on the downbeat of each 8-bar section.
- **Vocals:** gang shouts only.
- **Changes:** stems: full when the target is close; drums and bass only when far; a "trick" sting (a guitar slide)
  when the player cuts a corner.

#### MUS-C10 "Orsi's Kitchen"
- **Scene:** M4 interview, M5 service, the kitchen job (repeatable).
- **Mood:** comic fury; fast hands; a genius shouting.
- **Tempo / key:** 152 BPM, D minor (a Hungarian minor flavour: raised 4th).
- **Instruments:** a fiery solo violin (csárdás-inspired runs); a cimbalom; kitchen percussion (pans, knife on board,
  the ticket printer's rattle as a snare roll); upright bass.
- **Vocals:** none.
- **Changes:** stems react to the minigame: more percussion with more open tickets; the violin plays a triumphant run
  when a rush is cleared; a single falling violin glissando on a mistake.

#### MUS-C11 "The Cake Run"
- **Scene:** M4, the cargo-bike run.
- **Mood:** cartoon chase; wobbly; ridiculous.
- **Tempo / key:** 132 BPM, B-flat major.
- **Instruments:** tuba bass line; pizzicato strings; brass stabs; a slide whistle on wobbles; a xylophone.
- **Vocals:** none.
- **Changes:** speeds up downhill (up to 148 BPM), drops to a single nervous clarinet at each red light; the slide
  whistle tracks the wobble meter.

#### MUS-C12 "Family Meal"
- **Scene:** M2 (the secret meal), every family-meal scene, Orsi's World Menu (S4).
- **Mood:** warm, generous, many-voiced.
- **Tempo / key:** 96 BPM, G major.
- **Instruments:** one simple 8-bar tune, passed around the table: a guitar plays it, then an accordion, then a
  kalimba, then a fiddle, then a bansuri flute, then all together. Each instrument plays it in its own style (a
  little Filipino rondalla strum, a little Ethiopian krar pattern, a little Hungarian fiddle ornament).
- **Vocals:** none (the table's chatter is the vocal layer).
- **Changes:** loops; each loop changes the lead instrument. In S4 the dish's country picks the lead instrument.

#### MUS-C13 "Mr. Hale" (the villain's waltz)
- **Scene:** P2 (first statement), M4, M5 (music-box version), M7, M13 (minor), M24 (cold piano), M27 (cello, with the
  lullaby under it), M29 (distorted, `MUS-C39d`).
- **Mood:** charming, elegant, rich; with one sour note at the end of every phrase.
- **Tempo / key:** 132 BPM in 3/4 (a fast-ish waltz), C major (the minor versions in A minor).
- **Instruments:** string quartet, harpsichord, a celesta for sparkle. The sour note: the first violin bends the last
  note of each 8-bar phrase a quarter-tone flat.
- **Melody:** the Lucerito lullaby, inverted and ornamented (section 1B).
- **Vocals:** none.
- **Changes:** versions as listed. Each version is a little slower and colder than the one before. In M27 the real
  lullaby is mixed under it at −18 dB (felt, not heard).

#### MUS-C14 "Lookout" (Wendell's theme)
- **Scene:** M6 (the bungalow, the lookout), M20 end (muted trumpet alone), M21 (piano only), M26 (lookout, into the
  main theme).
- **Mood:** late night, wise, tender, a little sad.
- **Tempo / key:** 70 BPM, B-flat major.
- **Instruments:** upright piano; muted trumpet (the melody); brushes; a warm double bass; on the lookout, a soft
  string pad.
- **Melody:** starts with the Whistle (A–D, transposed), then a slow phrase that ends on the Home motif's first four
  notes.
- **Vocals:** none.
- **Changes:** non-looping in cutscenes; a 16-bar loop for free time at the lookout (any time in the game).

#### MUS-C15 "Fold It Like You Mean It" (Amparo's karaoke song)
- **Scene:** P3 end (muffled through the laundry door); Sunday karaoke in the laundry (a repeatable side scene: the
  player can sing along, which is a fun voice exercise).
- **Mood:** a joyful, over-the-top 1980s-style power ballad, karaoke-machine production.
- **Tempo / key:** 76 BPM, E-flat major, a big key change for the last chorus.
- **Instruments:** a karaoke-machine backing track: cheesy DX7 electric piano, a gated snare, a saxophone solo.
- **Vocals:** Amparo (the actor sings it, loud, enthusiastic, a little off pitch on purpose).
- **Lyrics (original, the fictional 1986 hit by "Celestine & The Linens"):**

> **Verse**
> Every morning in the dark I take the corners of my life,
> I shake them out, I smooth them down, I hold them straight and tight.
> The world can come in crumpled and the world can come in torn,
> But it leaves here looking better than the day that it was born.
>
> **Chorus**
> So fold it like you mean it, fold it like you care,
> Corner into corner, like a little prayer,
> Nobody will thank you, nobody will see,
> But fold it like you mean it, and you'll be free.
>
> **Last chorus (key change; Amparo stands on a chair)**
> Fold it like you mean it! Fold it like you care!
> Corner into corner, like a little prayer!
> Nobody will thank you, nobody will see,
> But I see you, anak, and you see me!

- **Note:** Amparo changes the last line every time (the "anak" line is hers, not the record's). The player hears the
  record's line on the karaoke screen and Amparo's change in her voice: a tiny lesson that songs are made of choices.

### Act 2

#### MUS-C16 "Room Service"
- **Scene:** M7; the room-service job (repeatable).
- **Mood:** smooth elevator bossa that gets nervous.
- **Tempo / key:** 100 BPM (rising to 126), A minor bossa.
- **Instruments:** nylon guitar, soft brush kit, vibraphone melody, a flute; the lift chime sampled as a bell hit.
- **Vocals:** none.
- **Changes:** the tempo follows the trolley's heat meter: as the food cools, the cue speeds up and adds a ticking
  woodblock. A delivered order resolves with the lift chime.

#### MUS-C17 "Wendell Drives"
- **Scene:** M8 lessons and the valet job; S11 Valet Runs.
- **Mood:** 1960s soul, cool, unhurried, proud.
- **Tempo / key:** 98 BPM, G major.
- **Instruments:** Hammond organ; tambourine; baritone sax riff; a clean electric guitar with tremolo; Wendell humming
  over it in the lessons (the actor hums freely: recorded as a separate stem so it plays only when he's in the car).
- **Vocals:** humming (Wendell).
- **Changes:** loops; when Wendell is not in the car (later valet jobs), the humming stem is absent. After M21, the
  cue plays once more, without the humming, the first time the hero drives the town car alone; then it is retired
  for the rest of the game.

#### MUS-C18 "Stakeout"
- **Scene:** M9.
- **Mood:** patient, cold, watchful.
- **Tempo / key:** 80 BPM, D minor.
- **Instruments:** a low synth pulse; ticking hi-hat; a sampled foghorn (real, recorded at a harbour, pitched to D);
  a bowed vibraphone; rain as texture.
- **Vocals:** none.
- **Changes:** stems: calm (pulse only), alert (hi-hat and bowed vibes), chase (a fast breakbeat layer). Fog weather
  thins the high end.

#### MUS-C19 (reserved)
- Kept free for a later safe-lesson cue if `MUS-C06` proves too busy under the M10 minigame. Until then, the M10 safe
  lesson uses no music: only clicks.

#### MUS-C20 "Duke Is Missing"
- **Scene:** M11.
- **Mood:** comic panic; a mambo chase through a palace.
- **Tempo / key:** 184 BPM, F major (Latin big band).
- **Instruments:** brass section stabs, timbales, congas, a frantic montuno piano, a bari sax; a dog bark sampled
  on the "hey!" hits.
- **Vocals:** a band shout "¡Duke!" on the break (a gag).
- **Changes:** stems by floor (each floor of the hotel drops or adds a section); Suite 501 cuts it dead for the
  gramophone record.

#### MUS-C21 "Small Print"
- **Scene:** M12 (city hall by day), M16 (the archive at night).
- **Mood:** precise, anxious, a little comic.
- **Tempo / key:** 116 BPM (day) / 84 BPM (night), C minor.
- **Instruments:** a typewriter recorded as percussion; pizzicato strings; a bassoon melody; a ticket-machine beep;
  (night) a bowed double bass replaces the bassoon.
- **Vocals:** none.
- **Changes:** loops; when a document is found, a single harp gliss.

#### MUS-C22 "The Pay Slip"
- **Scene:** M13, the reading (the Act 2 climax).
- **Mood:** quiet shock turning into anger and resolve.
- **Tempo / key:** free time, then 72 BPM; E minor to G major.
- **Instruments:** a single piano note (E) repeated; a chord with each line read; strings enter one section at a time
  (cellos, violas, violins); on "Stolen so far", a low brass swell.
- **Vocals:** none.
- **Changes:** interactive: each line the player reads aloud advances the cue one step (it waits for the player).
  It never loops; it ends on a held string chord that crossfades into the stealth of Beat 2.

### Act 3

#### MUS-C23 "Front Desk"
- **Scene:** M14; the front-desk job (repeatable).
- **Mood:** smooth, professional, warm; a city lobby.
- **Tempo / key:** 94 BPM, E-flat major.
- **Instruments:** Rhodes, muted guitar, soft kick and rim-click, a synth bass; the front-desk bell sampled on beat 4
  of every second bar.
- **Vocals:** none.
- **Changes:** layers grow with the queue length; a complaint drops the Rhodes to a single tense chord until resolved.

#### MUS-C24 "Authorised Personnel Only"
- **Scene:** M15, the container yard.
- **Mood:** industrial, stealthy, threatening.
- **Tempo / key:** 96 BPM, C# minor.
- **Instruments:** containers struck with mallets (recorded at a real yard), chains, a low cello ostinato, a ticking
  delay guitar; a dog's growl as a sub layer when the dog is near.
- **Vocals:** none.
- **Changes:** stealth stems (calm / searched / chase); the jump into the water cuts to an underwater low-pass, then
  silence, then the *Saudade*'s engine (two coughs: they are in tempo).

#### MUS-C25 "Saudade" (Manny's song)
- **Scene:** M15 (instrumental, the boat), M26 (sung by Manny, the full song), S7 fishing trips (instrumental loops).
- **Mood:** the ache of missing something, made beautiful; a sea song.
- **Tempo / key:** 63 BPM, B minor (rubato).
- **Instruments:** Portuguese guitar (guitarra portuguesa) and a classical guitar; on the M26 sung version, only
  Manny's own guitar on the deck (diegetic, recorded live in a room with a little air).
- **Vocals:** Manny (the actor sings; a worn, true voice; not polished).
- **Lyrics (full, original):**

> **Verse 1**
> My boat is older than my name, my nets are more hole than net,
> I go out in the dark each day and I come back with what I get.
> Rosa used to stand right there and wave me out to sea;
> Now only the gulls are waving, and they're not waving at me.
>
> **Chorus**
> Saudade, saudade, there's no English for the ache
> Of loving something gone so long you keep it half awake.
> I tie my heart up at the pier and I pay it what I owe:
> Saudade, saudade, the tide comes in, and I don't go.
>
> **Verse 2**
> They tell you that the sea gives back the things it takes away;
> They never tell you how it keeps them, or how long they have to stay.
> I sold my watch, I sold my ring, I'd sell the moon for one more year,
> But nobody buys the moon, my love, and nobody buys a pier.
>
> **Chorus**
>
> **Last lines (spoken more than sung)**
> If I did one wrong thing, Rosa, to keep the thing I love,
> Would you still wave from the pier... or from above?

- **Note:** the last two lines are Manny's own addition to the song, sung only in M26: the confession in advance. On
  a second play, they break the heart.

#### MUS-C26 "Code Blue"
- **Scene:** M17 (the pool rescue; then the ER, calm version).
- **Mood:** urgent, clinical, human.
- **Tempo / key:** 72 BPM rising to 120 (the heart monitor), F# minor; the calm version 72 BPM, A major.
- **Instruments:** a pulse synth locked to a heart-monitor beep; high sustained strings; (calm) a soft piano and a
  low hum of hospital air.
- **Vocals:** none.
- **Changes:** the tempo follows the rescue minigame (the pulse speeds while the patient is in danger, steadies when
  he's safe).

#### MUS-C27 "Hangar" (Jo's theme)
- **Scene:** M18 (the hangar, the runway), S8 Jo's Garage.
- **Mood:** Southern rock, sunny, cocky, kind.
- **Tempo / key:** 120 BPM, A major (open-G slide on the guitar).
- **Instruments:** slide guitar, a stomping kick, handclaps, harmonica, a honky-tonk piano.
- **Vocals:** a few whoops (Jo).
- **Changes:** loops; the runway challenge adds a double-time drum layer; a successful lap ends on a big slide.

#### MUS-C28 "Champagne for the Ones Who Pay" (Sonny's song)
- **Scene:** M19, the preview party (diegetic: Sonny at the Crown Room piano with a trio).
- **Mood:** sly, smoky lounge jazz; a protest song in a tuxedo.
- **Tempo / key:** 84 BPM, D-flat major, swung.
- **Instruments:** piano (Sonny), upright bass, brushes, a muted trumpet answering the vocal.
- **Vocals:** Sonny (smoky baritone, half spoken).
- **Lyrics (full, original):**

> **Verse 1**
> There's a man upstairs in a linen suit, he says "family" every night,
> He's got a smile like a chandelier and a handshake soft and white.
> He'll tell you all about the view, the champagne and the cake,
> But he never tells you who folds the sheets, or what the sheets will take.
>
> **Chorus**
> So it's champagne for the ones who pay,
> And the bill for the ones who stay.
> Pour it slow, baby, pour it gold:
> Somebody downstairs is folding it cold.
>
> **Verse 2**
> Now the old room's got a hole in the sky where the crystal used to be,
> And the people dance beneath it like they don't know what they see.
> I've played this piano forty years, I know every key that's out,
> And I know a song that's in the wrong key when the whole room starts to shout.
>
> **Chorus**
>
> **Coda**
> Pour it slow... pour it gold...
> Somebody downstairs... is getting old.

- **Note:** the guests applaud. The staff carrying trays don't. Hale smiles and raises a glass to Sonny. Sonny raises
  nothing.

#### MUS-C29 "Penthouse"
- **Scene:** M20, the cradle climb and the penthouse.
- **Mood:** vertigo, tension, wind.
- **Tempo / key:** 108 BPM, G minor.
- **Instruments:** tense spiccato strings; a pulsing low brass; a clock tick; the cradle's motor whine pitched into the
  key; wind as a sweeping layer.
- **Vocals:** none.
- **Changes:** stems (calm / exposed / caught); the chute ride down to the basement (M20, Beat 5) is a 6-second comic
  sting (a falling slide whistle and a thump), then the chase stem.

#### MUS-C30 "Hold the Door (Hymn)"
- **Scene:** M21: the letter (organ alone), the funeral on the steps (the staff sing).
- **Mood:** grief, dignity, community.
- **Tempo / key:** 60 BPM, F major, a gospel hymn.
- **Instruments:** a church organ (Sonny's portable keyboard on the organ setting, diegetic), nothing else.
- **Vocals:** the staff choir: 140 voices recorded in small groups and layered (real non-professional singers from
  many language backgrounds, singing in English with their own accents), Sonny leading, Amparo's voice clear above
  the others and breaking on the last line.
- **Lyrics (the hymn verse; the chorus is the chorus of `MUS-C43`):**

> **Verse**
> Lay down your coat, old doorman, your shift is over now,
> You held it for the famous and the ones who don't know how.
> You never asked us where we're from, you only asked our name,
> And every one who came in wet, you sent back out the same... but warm.
>
> **Chorus (slow)**
> Hold the door, hold the door,
> For the one who's come too far,
> For the stranger with the suitcase, for whoever you are...

- **Changes:** ends on the Whistle, blown by the hero (the player's button press) instead of a final chord.

#### MUS-C31 "Questions"
- **Scene:** M22, the immigration waiting room and the window.
- **Mood:** suspended time; dread; patience.
- **Tempo / key:** 60 BPM, no clear key (a drone on D, with a clock-like marimba on irregular beats).
- **Instruments:** marimba; a low drone (a bowed bass and an organ pedal); a single sustained violin note that bends
  slightly; the ticket board's beep as a sound cue.
- **Vocals:** none.
- **Changes:** at the window it drops to the drone only; when Grayson says "Good luck, Mr. Haile," a soft major chord
  for the first time.

#### MUS-C32 "Spin Room" (the planning theme)
- **Scene:** M20 (first, small), M23 (the full plan), every visit to the planning board afterwards.
- **Mood:** the heist groove: cool, funky, confident, growing.
- **Tempo / key:** 108 BPM, E-flat minor (Dorian), straight 16ths.
- **Instruments:** funky bass (the foundation); clavinet; a washing machine's spin cycle sampled as a rising swish
  every 4 bars; drum kit with a tight snare; a horn section; a Rhodes; a string stab; Lock the cat's meow (once, as a
  joke, at the very end).
- **Vocals:** none.
- **Changes (interactive, the core of BIBLE 4G):** the board has gaps; the cue begins with bass and the spin swish
  only; **each gap the player fills by voice adds one instrument** (in order: drums → clavinet → Rhodes → horns →
  strings → the main theme's melody in the horns). A wrong form plays a comic "wrong" sting (a clavinet bend) and
  nothing is lost. When the board is full, the whole band plays the theme twice and ends on a big chord, as twenty
  washers beep together (a sampled chorus of end-of-cycle beeps tuned to the chord).

#### MUS-C33 "Fire Drill"
- **Scene:** M24, the drill and the lift rescue.
- **Mood:** urgent, driving, controlled.
- **Tempo / key:** 140 BPM, the alarm's pitch (B-flat) as the root.
- **Instruments:** the fire alarm (recorded) as a rhythmic element; driving 4/4 drums; brass stabs in the alarm's
  rhythm; a rising string ostinato during the lift rescue.
- **Vocals:** none.
- **Changes:** the alarm stem stops when Jo cuts the lift power; the lift rescue is a separate stem set (calm / the
  lift drops / saved: a big brass chord).

#### MUS-C34 "Wanted"
- **Scene:** M18 (a short version for the tail), M24 (the police chase across the island).
- **Mood:** breakneck, desperate, cinematic.
- **Tempo / key:** 172 BPM, G minor.
- **Instruments:** breakbeat drums; a distorted bass synth; police-radio samples; sirens pitched into the key; the
  main theme's first four notes in brass as a fanfare whenever the player breaks line of sight.
- **Vocals:** none.
- **Changes:** stems follow Status (high: full; losing them: drums and bass; lost: a 4-bar outro); the car wash
  (third time) gets its own comic sting: the beat drops, a soapy synth bubble sound, a church-organ chord, the beat
  comes back.

#### MUS-C35 "Council"
- **Scene:** M25, the police station (morning version) and the council chamber.
- **Mood:** stately, tense, civic.
- **Tempo / key:** 76 BPM, D minor.
- **Instruments:** organ pedal; pizzicato strings; a slow snare; (morning) a ticking clock and a vending machine hum.
- **Vocals:** none.
- **Changes:** silent under the hero's speech (no music competes with the player's voice); the vote is a single
  timpani hit per hand raised; the result is silence.

#### MUS-C36 "Homesick"
- **Scene:** M6 (the first video call), M25 (end of Act 4), M26 (the lookout).
- **Mood:** longing; small and private.
- **Tempo / key:** 56 BPM, D major (the Home motif's key), but harmonised in B minor.
- **Instruments:** the music box (the Home motif), then a cello under it; in M26, a soft piano and a distant string
  pad.
- **Vocals:** none.
- **Changes:** M25's version ends on an unresolved chord (the 6th note, B, the box's flat note, held). M26's version
  resolves when the hero blows the whistle.

### Act 5

#### MUS-C37 "Cocktails on the LUZ"
- **Scene:** M27, the yacht party.
- **Mood:** glossy deep house; rich people's music; turns cold below decks.
- **Tempo / key:** 118 BPM, F minor.
- **Instruments:** a deep-house groove (soft kick, shuffled hats, a warm sub bass), a sultry wordless vocal sample,
  champagne glasses as percussion; below decks, the groove filters down to a muffled thump through the hull and a
  cold synth pad; in the cabin, it's replaced by `MUS-C13` (cello).
- **Vocals:** a wordless sampled vocal ("ooh").
- **Changes:** location-based filtering (deck / saloon / below decks / cabin).

#### MUS-C38 "The Night Before"
- **Scene:** M28, all seven scenes.
- **Mood:** a slow-building anthem; nerves and love.
- **Tempo / key:** 90 BPM, D major.
- **Instruments:** starts with a heartbeat kick and the main theme's notes on a low synth. **Each finished scene adds
  one instrument:** A (Jo) a slide guitar; B (Juju) a skateboard-wheel riser and a snare; C (Orsi) the cimbalom; D
  (313) a choir pad (held back to a whisper in that scene); E (Desmond) a bandoneón; F (Manny) the Portuguese guitar;
  G (the roof) the full band and the strings.
- **Vocals:** none.
- **Changes:** non-linear (the player does A–F in any order; the layers stack in the order completed). The last chord
  is held unresolved under the title "GALA NIGHT - TONIGHT".

#### MUS-C39 "Gala Night" (the heist suite)
One suite in seven parts, with shared material (the main theme, the Lucerito lullaby, the Whistle), so the whole
night feels like one piece of music.

- **C39a "Arrival":** an elegant Viennese waltz from the ballroom band (diegetic, distant through walls) layered with a
  low, sneaking pizzicato bass line (non-diegetic): the party and the plan at once. 3/4 waltz at 168 BPM against a
  4/4 bass at 112 BPM (they meet every 3 bars: a deliberate, slightly dizzy feel). Inside the cake: everything
  muffled and sweet.
- **C39b "The Tango":** Sonny's band (bandoneón, piano, double bass, violin), 120 BPM, A minor. Written as a tango
  that keeps "almost ending" and finding new sections (six false endings; Sonny improvises a seventh). Stems let the
  game extend it as long as the player needs.
- **C39c "The Vault":** almost silence: the time lock's tick (60 BPM), a single low cello note on D, the dial clicks
  (the gameplay sound, mixed as music). At 23:45 the first firework is a huge timpani hit, and then the power cut
  kills everything, even the tick.
- **C39d "The Double-Cross":** Hale's waltz (`MUS-C13`) slowed to 72 BPM, detuned, low brass, the lullaby notes buried
  and broken in a toy piano. Cold.
- **C39e "Trapped":** silence; the music box (8 notes); then radio static used as an instrument (filtered to pitch);
  a slow build in the main theme's chords as the hero starts to coordinate the crew; the stems rise with each crew
  instruction the player gives (like `MUS-C32`, but softer: piano, then strings, then the horns). During Manny's
  persuasion everything drops to the Portuguese guitar alone (`MUS-C25`'s chorus melody) and the Resolve meter
  brings the strings back.
- **C39f "The Microphone":** silence; Luz's lullaby on a single nylon guitar, unaccompanied, slow (`MUS-C40`'s
  melody). It stops when Halvorsen's voice comes through the floor.
- **C39g "The Fireworks Chase":** the main theme at full force: orchestra, surf guitar, big-band brass, timpani synced
  to the real fireworks; 156 BPM, D major. The fireworks are cued to the music's hits (the fireworks show is timed to
  this track, so audio drives the visuals). The final firework (the whistle shape) lands on the last chord; then the
  tide; then silence.

#### MUS-C40 "Lucerito" (Luz's lullaby)
- **Scene:** heard hidden in Hale's waltz all game; plainly in M29 (C39f) and M30 (Hale and the card); hummed by Luz
  in the epilogue.
- **Mood:** a mother's lullaby; tender; old; simple.
- **Tempo / key:** 60 BPM in 3/4, A minor, ending on A major (a Picardy third: a small light at the end).
- **Instruments:** a single nylon guitar (M29); Sonny's piano top notes (M30); Luz's voice, unaccompanied (epilogue,
  in the laundry, one verse, very soft).
- **Vocals:** Luz (an older woman's voice, untrained, warm; the actor should be a native Mexican Spanish speaker).
- **Lyrics (original; Spanish, with the meaning in English for translators):**

> **Verse 1**
> Duérmete, lucerito,
> sobre la sábana blanca;
> mamá dobla las estrellas
> y te guarda la mañana.
>
> *(Sleep, little light, / on the white sheet; / mama folds the stars / and keeps the morning for you.)*
>
> **Verse 2**
> Si me voy, lucerito,
> no me busques en el mar;
> busca el sol en la ventana,
> que yo siempre he de llegar.
>
> *(If I go away, little light, / don't look for me in the sea; / look for the sun in the window, / for I will always
> come.)*

- **Note:** *Luz* means "light"; *lucerito* is "little light" (a small star). Hale named his yacht after her. The
  lullaby is never translated on screen in M29 or M30: the player hears it as music. The words appear in Notes only
  after the epilogue, as a gift.

#### MUS-C41 "The Grand (Staff Chorus)"
- **Scene:** M30, the Palm Court at 3 a.m.
- **Mood:** joy, exhaustion, family.
- **Tempo / key:** 104 BPM (a little slower than `MUS-C04`), D major.
- **Instruments:** Sonny at the Palm Court's old upright piano, a tambourine someone found, glasses tapped with
  forks, Juju beatboxing badly in the second chorus.
- **Vocals:** the whole staff and crew, in English, in twenty accents, singing the main theme's chorus and last
  chorus (lyrics: `MUS-C04`). Recorded as a real group singalong (not tuned): Amparo too loud, Orsi refusing then
  joining, Desmond harmonising seriously, Courtney filming, Dawit getting every word right, Manny quietly.
- **Changes:** non-looping; under the camera crane at the end, the singing fades and the band version of `MUS-C04`
  takes over for the title.

#### MUS-C42 "Housekeeping"
- **Scene:** the epilogue montage.
- **Mood:** morning; peace; things working.
- **Tempo / key:** 92 BPM, D major.
- **Instruments:** the music box (Home motif), then a nylon guitar (the P1 guitar, now confident), then a light kit,
  upright bass, Wurlitzer, and finally the whole main theme on a small band (no big band: this is everyday life now).
- **Vocals:** none (Luz's lullaby verse is heard in the laundry scene over a pause in the cue).
- **Changes:** scored to picture; each montage shot gets a small instrumental colour from its character's theme (Jo's
  slide, Manny's guitar, Orsi's cimbalom, Juju's snare, Desmond's bandoneón).

#### MUS-C43 "Hold the Door" (end credits)
- **Scene:** the end credits.
- **Mood:** a soul ballad that becomes a gospel celebration; grief turned into a mission.
- **Tempo / key:** 72 BPM, A-flat major (half-time feel), building; the last chorus up a tone in B-flat.
- **Instruments:** piano, Hammond organ, a soul rhythm section, a string section, a horn section; a gospel choir in the
  last two choruses; **the hook is the Whistle** (two whistled notes, rising, at the start of every chorus).
- **Vocals:** a lead soul singer (any voice type; the casting note is "the voice of someone who has opened a door at
  five in the morning"), and the choir.
- **Lyrics (full, original):**

> **Verse 1**
> He wore a coat of faded green with gold along the seams,
> Fifty-eight years on the same front step, holding up other people's dreams.
> Movie stars and nobodies, he gave them all the same:
> An umbrella in the rain, and the sound of their own name.
>
> **Chorus**
> *(whistle: two notes)*
> Hold the door, hold the door
> For the one who's come too far,
> For the stranger with the suitcase, for whoever you are.
> It won't cost you nothing but a moment and your hand:
> Hold the door, hold the door, till they're standing where you stand.
>
> **Verse 2**
> I came in with no words at all, just "thank you" and "I'm sorry,"
> I signed a page I couldn't read, I folded up my worry.
> But a laundry full of strangers taught me every word I know,
> And the first one was "welcome," and the last one's "don't let go."
>
> **Chorus**
>
> **Bridge**
> And if the one who hurt you comes walking down the hall
> With his head down and his hands tied and nothing left at all,
> You don't have to forgive him, and you don't have to forget,
> But hold the door. Hold the door. He isn't through it yet.
>
> **Verse 3 (soft, piano only)**
> Now it's five a.m., it's raining, and the bell rings down below:
> Somebody with a squeaky wheel and nowhere else to go.
> I put on the old green coat and I take it nice and slow:
> "My name is... what's your name? It's okay. We've got time. Hello."
>
> **Last chorus (up a tone, the choir, the whole band)**
> *(whistle: two notes)*
> Hold the door, hold the door
> For the one who's come too far,
> For the stranger with the suitcase, for whoever you are.
> It won't cost you nothing but a moment and your hand:
> Hold the door, hold the door, till they're standing where you stand.
> *(choir)* Till they're standing where you stand.
> *(choir)* Till they're standing where you stand.
>
> **Outro**
> *(whistle: two notes, alone; the last sound of the game)*

- **Changes:** full length (about 4:30) over the credits. The after-credits Kroll scene has no music: only rain and
  the car park barrier.

#### MUS-C44 "Bathroom Run"
- **Scene:** every Bathroom Run (P3 onward); a stealth sting cue.
- **Mood:** sneaky, comic, urgent.
- **Tempo / key:** 126 BPM, F minor.
- **Instruments:** pizzicato strings tiptoeing; a bassoon; a ticking hi-hat that speeds up with the bladder meter; a
  triumphant toilet-flush-into-harp-gliss sting on success.
- **Vocals:** none.
- **Changes:** loops (8 bars); stems by danger (unseen / suspected / spotted: a brass "uh-oh" stab).

#### MUS-C45 "Henderson" (Kroll's sting)
- **Scene:** every time Kroll appears in a stealth or chase section, and before every "Morning, Henderson."
- **Mood:** heavy, robotic, a little ridiculous.
- **Tempo / key:** a 2-bar sting at 80 BPM, low C.
- **Instruments:** a low tuba and a bass drum, three heavy steps (DUM. DUM. DUM.), then a muted trombone that falls a
  semitone.
- **Vocals:** none.
- **Changes:** a single sting; in the after-credits scene it plays one last time, and the stranger's line cuts it off.

#### MUS-C46 "Coronado Moon" (Dawit's country song)
- **Scene:** P3 (through the Annex wall, a neighbour's radio), M13 (Dawit sings one line alone), the Annex radio in
  free play.
- **Mood:** an old 1990s country radio hit; homesick but cheerful.
- **Tempo / key:** 96 BPM, G major.
- **Instruments:** acoustic guitar, pedal steel, a fiddle, a shuffle drum kit.
- **Vocals:** a deep country baritone (the fictional artist "Wade Calloway"); in M13, Dawit (the actor, soft, a few
  words wrong in a loving way).
- **Lyrics (verse and chorus, original):**

> **Verse**
> I come in on the night bus with a dollar and a song,
> They gave me a mop and a nametag that they spelled a little wrong.
> But the ocean don't care what you're called or where you're from,
> It just rolls up to your boots and says, "Well, howdy. Here you come."
>
> **Chorus**
> Coronado moon, hanging low over the bay,
> I been working all night, I'll be working all day,
> Somebody back home's looking up at you too,
> So shine a little extra, Coronado moon.

- **Note:** in M13 Dawit sings only the last two lines of the chorus, alone, very soft, and stops on "you too". The
  game uses his version, not the record, from then on whenever the hero is alone in the Annex at night.

## 4. Diegetic sources (for the sound team)
| Source | Where | Plays |
|---|---|---|
| The music box | the hero's pocket | the Home motif (8 notes) when opened; in M29 it is also a live microphone |
| Amparo's karaoke speaker | the laundry | `MUS-C15` and other fictional karaoke songs |
| The Annex radio | the hero's building | `MUS-C46`, KSDX pop (`MUS-C05`), a country station, a talk station |
| Car radios | every car | KSDX (pop), a country station, a Latin station, a jazz station, a news station |
| Sonny's piano | the Crown Room, the Palm Court | standards, `MUS-C28`, `MUS-C39b`, `MUS-C41` |
| The gramophone | Suite 501 | 1950s crooner records (Sonny's younger voice) |
| The ballroom band | the Crown Room, gala night | waltzes, swing, the tango |
| The yacht's sound system | the *LUZ* | `MUS-C37` |
| Manny's guitar | the *Saudade* | `MUS-C25` |
| Wendell's whistle | the doorman's stand; later the hero | the Whistle (two notes) |

## 5. Cue index
| Cue | Title | Missions |
|---|---|---|
| C01 | Twenty Hours | P1 |
| C02 | Back of House | P2 |
| C03 | Seven Days | P2, P3, Act 1 laundry |
| C04 | The Grand (Main Theme) | P3, M6, M13, M26, M30, title |
| C05 | Main Character (KSDX) | M1, radios |
| C06 | Suds & Duds | M1, M10, M22 |
| C07 | The Annex | M2, M20, free play |
| C08 | Amber Ave | M3, free play |
| C09 | Juju's Run | M3, M7, S2 |
| C10 | Orsi's Kitchen | M4, M5, kitchen job |
| C11 | The Cake Run | M4 |
| C12 | Family Meal | M2, S4 |
| C13 | Mr. Hale | P2, M4, M5, M7, M13, M24, M27 |
| C14 | Lookout | M6, M20, M21, M26 |
| C15 | Fold It Like You Mean It | P3, karaoke |
| C16 | Room Service | M7, room-service job |
| C17 | Wendell Drives | M8, S11 |
| C18 | Stakeout | M9 |
| C19 | (reserved) | — |
| C20 | Duke Is Missing | M11 |
| C21 | Small Print | M12, M16 |
| C22 | The Pay Slip | M13 |
| C23 | Front Desk | M14, front-desk job |
| C24 | Authorised Personnel Only | M15 |
| C25 | Saudade | M15, M26, S7 |
| C26 | Code Blue | M17 |
| C27 | Hangar | M18, S8 |
| C28 | Champagne for the Ones Who Pay | M19 |
| C29 | Penthouse | M20 |
| C30 | Hold the Door (Hymn) | M21 |
| C31 | Questions | M22 |
| C32 | Spin Room | M20, M23, the planning board |
| C33 | Fire Drill | M24 |
| C34 | Wanted | M18, M24 |
| C35 | Council | M25 |
| C36 | Homesick | M6, M25, M26 |
| C37 | Cocktails on the LUZ | M27 |
| C38 | The Night Before | M28 |
| C39a–g | Gala Night (suite) | M29 |
| C40 | Lucerito | M29, M30, E |
| C41 | The Grand (Staff Chorus) | M30 |
| C42 | Housekeeping | E |
| C43 | Hold the Door (End Credits) | credits |
| C44 | Bathroom Run | every Bathroom Run |
| C45 | Henderson | Kroll stings |
| C46 | Coronado Moon | P3, M13, the Annex radio |
