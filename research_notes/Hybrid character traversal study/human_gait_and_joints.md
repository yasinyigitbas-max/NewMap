# Human gait and joint motion - real biomechanics numbers for a third-person character controller

Research date: 25 Nov 2026. Independent of the game repo (no repo file was read).

**How to read these notes**
- Every line under "Cited Findings" comes from a page or document fetched in this session; the link is the page fetched.
- Tags: **[primary]** = journal article / official dataset (full text or abstract). **[abstract]** = only the abstract was read
  (via the Europe PMC REST API; the link is the Europe PMC record of the same paper). **[secondary]** = textbook-style
  summary, teaching page, Wikipedia or a clinical form - usable, but one step from the measurement.
- "Inferences" are my own arithmetic or reasoning on the cited numbers - NOT sourced facts.
- "Gaps" lists what could not be verified. Nothing there should be treated as known. Numbers that appeared only in
  search-result snippets (page not opened) are listed in Gaps, flagged "snippet only".
- Blocked in this session: physio-pedia.com (HTTP 403), ncbi.nlm.nih.gov Bookshelf / PubMed (captcha / cookies),
  core.ac.uk (403), exrx.net (403), peerj.com (403), NASA msis.jsc.nasa.gov (host not allowed by the session network).
  So Perry's and Winter's books, StatPearls, Novacheck 1998 full text and NASA-STD-3000 were NOT read.

---

## 1. Gait cycle: walking, running, sprinting (phases, cadence, step length, speed, centre of mass, pelvis, trunk, arms)

### Takeaway
Walking is ~60 % stance / 40 % swing with two double-support periods of ~10-12 % each; as speed rises stance shrinks to
~31 % of the cycle in running and ~22 % in sprinting and double support is replaced by flight. Comfortable adult walking
is ~1.3-1.45 m/s at ~100-120 steps/min with a centre of mass that moves only ~3-5 cm up-down and ~4-7 cm side-to-side;
the pelvis moves only a few degrees (tilt ~3°, list ~8°, rotation ~12° total range at normal speed).

### Cited Findings

**Walking phases**
- Stance ≈ 60 % of the gait cycle, swing ≈ 40 %; both feet are on the ground at the start and end of stance, each
  double-support period ≈ 10-12 % of the cycle. Stance sub-phases: initial contact (heel strike), loading response,
  mid-stance, terminal stance, pre-swing; swing: initial swing (toe-off), mid-swing (tibia vertical), terminal swing.
  [primary review] - [Pirker & Katzenschlager 2017, Wien Klin Wochenschr](https://pmc.ncbi.nlm.nih.gov/articles/PMC5318488/)
- Same split given as 10 % initial double-limb stance + 40 % single-limb stance + 10 % terminal double-limb stance, swing
  40 %. Seven events: initial contact, opposite toe-off, heel rise, opposite initial contact, toe-off, feet adjacent,
  tibia vertical. [secondary] - [Wikipedia: Bipedal gait cycle](https://en.wikipedia.org/wiki/Bipedal_gait_cycle)
- Phase windows used by a clinical rating study: early stance 0-10 %, mid stance 10-30 %, late stance 30-60 %, early
  swing 60-70 %, late swing 70-100 % of the gait cycle. [primary, table of "normal" values given to raters] -
  [Brunnekreef et al. 2005, BMC Musculoskelet Disord](https://pmc.ncbi.nlm.nih.gov/articles/PMC555760/)
- Stride = distance between successive initial contacts of the same foot; step = between initial contacts of
  alternating feet. [secondary] - [OrthoBullets: Gait cycle](https://www.orthobullets.com/foot-and-ankle/7001/gait-cycle)
- In a mature walking gait each arm swings opposite to its same-side leg; shoulders and pelvis stay relatively level,
  body held upright. [primary review] - [Pirker & Katzenschlager 2017](https://pmc.ncbi.nlm.nih.gov/articles/PMC5318488/)

**Walking → running → sprinting**
- Stance phase shortens with speed: 62 % of the cycle in walking, 31 % in running, 22 % in sprinting (13 runners:
  2 sprinters, 5 joggers, 6 elite distance runners). Sagittal joint motion grows with speed; the body lowers its centre
  of gravity with speed by flexing hips and knees more and dorsiflexing the ankle more. [abstract] -
  [Mann & Hagy 1980, Am J Sports Med](https://europepmc.org/article/MED/7416353)
- Walking always has a double-support phase; running has none and instead has a "double float" phase.
  [secondary] - [Wikipedia: Transition from walking to running](https://en.wikipedia.org/wiki/Transition_from_walking_to_running)
- Time spent in float increases as running speed increases; swing is 62 % of the running cycle vs 40 % in walking;
  ground reaction force in running reaches ~250 % body weight. [secondary - a university-hosted copy of Physiopedia's
  "Running Biomechanics" page, unreferenced numbers] -
  [CSJM University copy](https://gyansanchay.csjmu.ac.in/wp-content/uploads/2022/02/Biomechanics-of-Running.pdf)
- Preferred walk-run transition speed ≈ 2.0 m/s (7.2 km/h), Froude number ≈ 0.5. [secondary] -
  [Wikipedia: Transition from walking to running](https://en.wikipedia.org/wiki/Transition_from_walking_to_running);
  measured: preferred transition 2.06 m/s, energetically optimal transition 2.24 m/s (20 young adults) [abstract] -
  [Hreljac 1993, Med Sci Sports Exerc](https://europepmc.org/article/MED/8231761)

**Foot strike**
- Three types: heel (rear-foot), mid-foot, forefoot; classified by which third of the shoe lands first. About 75 % of
  shod runners heel-strike. Barefoot walking is heel or mid-foot strike; barefoot running tends to mid-/forefoot.
  [secondary] - [Wikipedia: Gait (human)](https://en.wikipedia.org/wiki/Gait_(human))
- 28 regular runners on a treadmill: rear-foot / mid-foot / forefoot = 68 / 14 / 18 % at 2.5 m/s, 68 / 18 / 14 % at
  3.5 m/s, 61 / 21 / 18 % at 4.5 m/s (no significant speed effect). [primary] -
  [Fukuchi, Fukuchi & Duarte 2017, PeerJ](https://pmc.ncbi.nlm.nih.gov/articles/PMC5426356/)

**Walking speed**
- Mean comfortable walking speed by decade (meta-analysis, Bohannon & Andrews 2011), m/s - men: 20s 1.36, 30s 1.43,
  40s 1.43, 50s 1.43, 60s 1.34, 70s 1.26, 80-99 0.97; women: 20s 1.34, 30s 1.34, 40s 1.39, 50s 1.31, 60s 1.24,
  70s 1.13, 80-99 0.94. [secondary handout reproducing the primary table] -
  [University of Toronto iWalk handout](https://www.physicaltherapy.utoronto.ca/sites/default/files/assets/files/11walking-speed-age-and-sex-specific-normative-values-final.pdf)
- 230 healthy adults aged 20-79: mean comfortable speed 127.2 cm/s (women in their 70s) to 146.2 cm/s (men in their 40s);
  mean MAXIMUM walking speed 174.9 cm/s (women 70s) to 253.3 cm/s (men 20s). [abstract] -
  [Bohannon 1997, Age Ageing](https://europepmc.org/article/MED/9143432)
- Preferred walking speed 1.10-1.65 m/s across sources; gross cost of transport minimal at ≈ 1.23 m/s; design guides use
  1.33-1.4 m/s. [secondary] - [Wikipedia: Preferred walking speed](https://en.wikipedia.org/wiki/Preferred_walking_speed)
- Preferred speed ≈ 1.4 m/s in healthy adults up to 59; falls ~1 %/year from 1.3 m/s in the 60s to 0.95 m/s over 80;
  the decline comes from shorter steps, not lower cadence. [primary review] -
  [Pirker & Katzenschlager 2017](https://pmc.ncbi.nlm.nih.gov/articles/PMC5318488/)

**Cadence, step and stride length (walking)**
- Average stride length in healthy adults 150-170 cm; average cadence in young adults 115-120 steps/min; elderly use a
  ~40 % wider step width (≈ 8 cm elderly women, ≈ 10 cm elderly men). [primary review] -
  [Pirker & Katzenschlager 2017](https://pmc.ncbi.nlm.nih.gov/articles/PMC5318488/)
- Cadence bands: slow 60-79, medium 80-99, brisk 100-119, faster locomotion 120+ steps/min. Treadmill: 80 steps/min ≈
  2.6 km/h, 90 ≈ 3.0, 100 ≈ 4.0, 110 ≈ 4.7, 120 ≈ 5.6 km/h; 3.2-6.4 km/h ≈ 96-134 steps/min. ≥ 100 steps/min ≈ moderate
  intensity; self-paced "brisk" ≈ 124 steps/min. Cadence falls ≈ 1.15 steps/min per extra cm of leg length. People speed
  up mainly by cadence up to preferred speed, then by cadence and step length about equally. [primary review] -
  [Tudor-Locke et al. 2018, Br J Sports Med](https://pmc.ncbi.nlm.nih.gov/articles/PMC6029645/)
- Cadence ≈ 100-115 steps/min in normal gait; comfortable speed ≈ 80 m/min; stride length = 2 × step length and left
  and right steps are equal in normal gait (page flags these as lacking citations). [secondary, weak] -
  [Wikipedia: Bipedal gait cycle](https://en.wikipedia.org/wiki/Bipedal_gait_cycle)
- Significant sex differences exist in all basic gait parameters; speed and step length change with age at normal and
  fast gait, step frequency does not (233 subjects, 10-79 y). [abstract; the tables were not accessible] -
  [Öberg et al. 1993, J Rehabil Res Dev](https://europepmc.org/article/MED/8035350)
- Experimentally observed step length during gait initiation ≈ 0.42 statures (cited inside a modelling paper).
  [primary, citing others] -
  [Anand, Seipel & Rietdyk 2017 (post-print)](https://purdue.edu/hhs/hk/Biomechanics-MotorBehavior/wp-content/uploads/2017/04/Anand-Seipel-Rietdyk-2017-Model-Gait-Initiation-Post-Print-version.pdf)

**Running and sprinting speed, stride, cadence, contact / flight time**
- Treadmill running, 28 regular runners: at 2.5 / 3.5 / 4.5 m/s stride length 1.86 / 2.46 / 2.96 m, cadence
  80.8 / 85.7 / 91.7 strides/min, stride width 0.10 / 0.09 / 0.08 m. [primary] -
  [Fukuchi et al. 2017, PeerJ](https://pmc.ncbi.nlm.nih.gov/articles/PMC5426356/)
- Overground running at 3.35 m/s: stance ≈ 260 ms (recreational rear-foot strikers). [primary] -
  [Fellin et al. 2010, J Sci Med Sport](https://pmc.ncbi.nlm.nih.gov/articles/PMC3266867)
- Elite 100 m sprinters at maximal velocity (19 men / 19 women): velocity 10.59 / 9.58 m/s; step length 2.25 / 2.08 m;
  step rate 4.71 / 4.62 steps/s; ground contact 0.090 / 0.095 s; flight 0.124 / 0.123 s; leg length 0.94 / 0.87 m.
  [primary] - [Murphy et al. 2021, J Clin Transl Res](https://pmc.ncbi.nlm.nih.gov/articles/PMC8580521)
- Trained (non-elite) sprinters accelerating on an instrumented treadmill (14 men): steps 1-10 contact 0.160 s, flight
  0.084 s; steps 11-to-top-speed contact 0.138 s, flight 0.102 s; step frequency ≈ 4.1-4.2 Hz throughout; swing time
  ≈ 0.33 s; top speed 6.63 m/s reached in 20-28 steps (treadmill top speeds are lower than track). [primary] -
  [Morin et al. 2015, Front Physiol](https://pmc.ncbi.nlm.nih.gov/articles/PMC4689850/)
- Top speeds of 33 subjects of mixed ability: 6.2 to 11.1 m/s; faster runners apply more ground force (1.26× from the
  slowest to the fastest), the time to swing the leg forward does not differ. [abstract] -
  [Weyand et al. 2000, J Appl Physiol](https://europepmc.org/article/MED/11053354)
- Up to ~7 m/s people run faster mainly by longer strides (more support force); above ~7 m/s mainly by higher stride
  frequency (hip muscles swing the leg faster). [abstract] -
  [Dorn, Schache & Pandy 2012, J Exp Biol](https://europepmc.org/article/MED/22573774)
- Vertical oscillation of the centre of mass in running: experts 91 mm at 10 km/h and 95 mm at 15 km/h; novices
  82 mm and 81 mm; duty factor falls and step frequency rises from 10 to 15 km/h. [primary] -
  [Fadillioglu et al. 2022, Bioengineering](https://pmc.ncbi.nlm.nih.gov/articles/PMC9687194)

**Centre of mass excursion (walking)**
- 10 normal subjects, 0.7 → 1.6 m/s: vertical excursion grows from 2.74 ± 0.52 cm to 4.83 ± 0.92 cm; side-to-side
  excursion SHRINKS from 6.99 ± 1.34 cm to 3.85 ± 1.41 cm. [abstract] -
  [Orendurff et al. 2004, J Rehabil Res Dev](https://europepmc.org/article/MED/15685471)
- Vertical excursion 0.050 ± 0.010 m at 1.25 m/s; unchanged when the arms are bound or held. [primary] -
  [Collins, Adamczyk & Kuo 2009, Proc R Soc B](https://pmc.ncbi.nlm.nih.gov/articles/PMC2817299/)
- Horizontal (side-to-side) displacement of the centre of gravity ≈ 5 cm per adult male step. [secondary] -
  [OrthoBullets](https://www.orthobullets.com/foot-and-ankle/7001/gait-cycle)
- At very slow speeds the side-to-side range grows by ≈ 0.07 m per 1 m/s of slowing; step width roughly unchanged.
  [primary] - [Best & Wu 2020, Proc R Soc B](https://pmc.ncbi.nlm.nih.gov/articles/PMC7657866)
- The centre of mass is lowest at heel contact (double support) and highest over the stance leg; flattening the path
  does not save energy - the "six determinants" theory is contradicted, the stance leg works like an inverted pendulum.
  [secondary + abstract] - [Wikipedia: Gait (human)](https://en.wikipedia.org/wiki/Gait_(human));
  [Kuo 2007, Hum Mov Sci](https://europepmc.org/article/MED/17617481)

**Pelvis and trunk**
- Pelvis range of motion in level walking, 16 healthy young adults, optical system (mean, SD), slow 1.01 m/s / normal
  1.34 m/s / fast 1.56 m/s: tilt (sagittal) 2.9° / 3.3° / 3.9°; obliquity (list, frontal) 6.8° / 8.5° / 9.5°; rotation
  (transverse) 10.1° / 11.8° / 14.5° (SD ≈ 1°, 3°, 3-5° respectively). [primary] -
  [Buganè et al. 2014, Biomed Eng Online](https://pmc.ncbi.nlm.nih.gov/articles/PMC4216872/)
- Textbook-style values: pelvis rotates 4° toward the swing side; pelvis drops 4° on the swing side. [secondary] -
  [OrthoBullets](https://www.orthobullets.com/foot-and-ankle/7001/gait-cycle). Rater table: pelvis 5° forward rotation at
  initial contact, 0° mid-stance, 5° backward in late stance / early swing. [primary table] -
  [Brunnekreef et al. 2005](https://pmc.ncbi.nlm.nih.gov/articles/PMC555760/)
- Above ~3 km/h transverse pelvic rotation lengthens the step ("pelvic step"). Pelvis and thorax rotate nearly in phase
  at slow speed and shift toward counter-rotation as speed rises (2.0-5.2 km/h tested); pelvis + thorax contribute
  < 10 % of whole-body angular momentum about the vertical, legs and arms ≈ 90 %. [abstract] -
  [Bruijn et al. 2008, Gait Posture](https://europepmc.org/article/MED/17669652)
- Pelvic rotation accounts for ≈ 12 % reduction of vertical centre-of-mass travel; pelvic obliquity for at most 2-4 mm;
  stance-phase knee flexion averages ≈ 15°. Females walk with smaller step width and more pelvic movement.
  [secondary] - [Wikipedia: Gait (human)](https://en.wikipedia.org/wiki/Gait_(human))
- In running the chest counter-rotates against the pelvis ("spinal engine"). [secondary, qualitative] -
  [CSJM copy of Physiopedia](https://gyansanchay.csjmu.ac.in/wp-content/uploads/2022/02/Biomechanics-of-Running.pdf)

**Arm swing**
- Each arm swings with the opposite leg; this lowers whole-body angular momentum about the vertical. Below ≈ 0.8 m/s
  the arms swing at twice the leg frequency (2:1), above it 1:1; amplitude increases with walking speed.
  [secondary] - [Wikipedia: Arm swing in human locomotion](https://en.wikipedia.org/wiki/Arm_swing_in_human_locomotion)
- At 1.25 m/s normal arm swing needs only ≈ 2.5 N·m peak shoulder torque (< 25 % of what holding the arm horizontal
  needs). Holding the arms still costs +12 % metabolic energy, binding them +7 %, swinging them in phase with the
  same-side leg +26 %; the vertical ground reaction moment rises 63 % with bound arms. [primary] -
  [Collins, Adamczyk & Kuo 2009](https://pmc.ncbi.nlm.nih.gov/articles/PMC2817299/)
- Arms act as passive mass dampers driven by the lower body; they reduce torso and HEAD rotation; removing arm swing
  increased head yaw; front and rear deltoid fire together, not alternately. [abstract] -
  [Pontzer et al. 2009, J Exp Biol](https://europepmc.org/article/MED/19181900)
- Walking: the arm is kept mostly straight; running: the arm is bent at the elbow. Bending the elbow cuts shoulder
  torque by ~33 % (walk) / ~32 % (run) but raises elbow torque +110 % (walk) / +30 % (run); walking with bent arms costs
  11 % more oxygen, running cost is the same straight or bent. [abstract] - [Yegian et al. 2019, J Exp Biol](https://europepmc.org/article/MED/31289110)

### Inferences
- Sprint duty: contact 0.090 s + flight 0.124 s = 0.214 s per step, so one foot is on the ground ≈ 21 % of its stride
  (0.090 / 0.428) - consistent with Mann & Hagy's 22 % for sprinting. Roughly: foot-on-ground share of a stride
  62 % walk → ~31 % run → ~21 % sprint.
- Fukuchi's cadence is in strides/min; ×2 gives ≈ 162, 171, 183 steps/min at 2.5, 3.5, 4.5 m/s, with step lengths
  ≈ 0.93, 1.23, 1.48 m. Elite sprint: 4.7 steps/s ≈ 283 steps/min, 2.25 m steps.
- Speed bands an animator can defend from the above: slow walk < 1.0 m/s; normal walk 1.3-1.45; fastest walk
  1.75-2.5; walk→run switch ≈ 2.0-2.1; jog 2.5-3.5; fast run 4.5; untrained top sprint ≈ 6-7; elite ≈ 9.6-10.6 m/s.
- Body bob: walk 3-5 cm peak-to-peak (grows with speed), run 8-9.5 cm. Side sway: walk 4-7 cm, larger when SLOW.
- Pelvis motion is small: at normal walk about ±1.5° tilt, ±4° list, ±6° rotation around neutral (half the ranges).
- A character whose arms swing in phase with the same-side leg, or whose arms are locked, is physically "expensive"
  and will read as wrong; straight-ish arms for walking and bent elbows for running is the human stereotype.

### Gaps (not found / unverified)
- Exact elbow angle in running (the commonly quoted "about 90°") and arm-swing amplitude in degrees at the shoulder:
  NOT found in any fetched page. Yegian's abstract gives no angles.
- Trunk forward lean in steady walking / running in degrees: not found.
- Thorax transverse rotation amplitude in degrees: not found (only the phase relation).
- Novacheck 1998 (toe-off at 39 % in running and 36 % in sprinting; float phases): snippet only - full text blocked.
- Perry's eight-phase percentages (loading response 0-10/12 %, mid-stance to ~30 %, terminal stance to ~50 %,
  pre-swing 50-60 %, initial swing 60-73 %, mid-swing 73-87 %, terminal swing 87-100 %): NOT fetched; only the coarser
  windows above are sourced.
- Step width of healthy young adults in cm; double-support % as a function of speed; reference tables of step length by
  age and sex (Öberg 1993 tables) - not accessible.
- Typical recreational "jogging" speed as a population norm: not found; the 2.5-3.5 m/s band is from study protocols.

---

## 2. Joint angle curves during walk and run (hip, knee, ankle)

### Takeaway
Walking uses a small part of each joint's range: hip ≈ 25-30° flexion to 10° extension, knee ≈ 15-20° flexion in early
stance and ≈ 60° peak in swing, ankle ≈ 10° dorsiflexion to 20° plantarflexion. Running roughly doubles the knee swing
flexion (≈ 95-125°) and raises hip flexion with speed (44° → 61° from 2.5 to 4.5 m/s), while ankle range barely changes.

### Cited Findings

**Walking (sagittal plane)**
- "Normal" joint angles given to raters, by phase (early stance 0-10 % / mid stance 10-30 % / late stance 30-60 % /
  early swing 60-70 % / late swing 70-100 %):
  hip 25° flexion / 0° / 10° extension at 30-50 % then 0° at 50-60 % / 15° flexion / 25° flexion;
  knee 20° flexion / 0° / 40° flexion / 60° flexion / 0°;
  ankle 10° plantarflexion / 10° dorsiflexion / 20° plantarflexion / 10° plantarflexion / 0°;
  trunk stays positioned above the hip. [primary table, summarising textbook norms] -
  [Brunnekreef et al. 2005](https://pmc.ncbi.nlm.nih.gov/articles/PMC555760/)
- Early-stance knee flexion ≈ 15°; ankle plantarflexes at heel strike and early stance; at mid-stance the knee extends.
  [secondary] - [OrthoBullets](https://www.orthobullets.com/foot-and-ankle/7001/gait-cycle)
- Stance-phase knee flexion averages ≈ 15°, starting after foot-flat; at heel contact the knee is fully extended and
  the foot dorsiflexed. [secondary] - [Wikipedia: Gait (human)](https://en.wikipedia.org/wiki/Gait_(human))
- The knee is most flexed at "feet adjacent" (mid-swing); the hip is most flexed at "tibia vertical" (late swing).
  [secondary] - [Wikipedia: Bipedal gait cycle](https://en.wikipedia.org/wiki/Bipedal_gait_cycle)
- Great toe: first MTP joint needs a minimum of 35-40° dorsiflexion for normal function; expected range 70-90°;
  plantarflexion ≈ 45°. [secondary, university podiatry page] -
  [QUT podiatry: 1st MTP joint ROM](https://podiatry-anatomy-app.qut.edu.au/content/joints/1st-mtp-joint-rom.html)
- In 33 people without foot pathology, clinical ranges of the first MTP joint exceeded the motion needed in walking
  (except passive weight-bearing); active weight-bearing range correlated best with gait. [abstract - numbers not in
  the abstract] - [Nawoczenski et al. 1999, JBJS Am](https://europepmc.org/article/MED/10199275)

**Running (sagittal plane)**
- Peak angles on a treadmill at 2.5 / 3.5 / 4.5 m/s (28 runners): hip flexion 43.8° / 52.8° / 60.5°; hip extension
  3.6° / 8.0° / 11.8°; knee flexion (swing) 93.5° / 108.7° / 119.1°; ankle dorsiflexion 26.4° / 26.5° / 26.8° (no speed
  effect); ankle plantarflexion 16.6° / 20.5° / 23.2°; foot eversion 4.9° / 6.6° / 7.8°. [primary] -
  [Fukuchi et al. 2017, PeerJ](https://pmc.ncbi.nlm.nih.gov/articles/PMC5426356/)
- Recreational runners at a slow pace: arcs of motion ≈ ankle 50°, knee 95°, hip 40°. At a fast pace the hip extends
  more in early swing and hip and knee flex more in mid / late swing; ankle motion does not change with speed. Peak
  vertical force is near mid-stance, when ankle, knee and hip approach maximum (stance) flexion. [abstract] -
  [Pink et al. 1994, Am J Sports Med](https://europepmc.org/article/MED/7943522)
- Running curve described phase by phase: hip ≈ 50° flexion at heel strike, extends through stance to ≈ 10°
  hyperextension after toe-off, flexes to ≈ 55° in late swing. Knee ≈ 40° at heel strike, flexes to ≈ 60° in loading
  response, back to ≈ 40° just before toe-off, peaks ≈ 125° in mid-swing, extends to ≈ 40° for the next strike. Ankle
  ≈ 10° dorsiflexion at heel strike, quickly to ≈ 25° dorsiflexion, then plantarflexes to ≈ 25° early in swing, back
  to ≈ 10° dorsiflexion late in swing. [secondary, unreferenced copy of Physiopedia - the 40° knee at strike and 50°
  hip at strike are higher than most measured data; use with caution] -
  [CSJM copy](https://gyansanchay.csjmu.ac.in/wp-content/uploads/2022/02/Biomechanics-of-Running.pdf)
- Elite sprinters at top speed, thigh (upper-leg) angle in the paper's own convention: touchdown 210° / 213°
  (men / women), take-off 156° / 155°, full extension 155° / 152°, full flexion 256° / 253°. [primary] -
  [Murphy et al. 2021](https://pmc.ncbi.nlm.nih.gov/articles/PMC8580521)

### Inferences
- Thigh excursion at top-speed sprint ≈ 256° − 155° ≈ 100° (my subtraction of the reported extremes) vs ≈ 40° hip arc
  in walking and ≈ 47-72° in running at 2.5-4.5 m/s (flexion + extension peaks from Fukuchi).
- For foot IK: in walking the knee is nearly straight at heel strike, gives ≈ 15-20° under load, straightens at
  mid-stance, is already ≈ 40° flexed at toe-off and peaks ≈ 60° about one third into swing. A stance knee that stays
  locked straight, or a swing knee peaking far below 60°, looks stiff.
- Ankle: the foot is plantarflexed ≈ 20° at toe-off in walking and the toes must bend up ≥ 35-40° at the MTP joint -
  a rigid foot at push-off is wrong.

### Gaps (not found / unverified)
- Full normative curves (degree vs % cycle) with standard deviations from a gait-lab dataset: the Fukuchi 2018 walking
  dataset article gives no summary numbers in the text; the Figshare data were not downloaded.
- Effect of walking speed on each peak in degrees: snippet only (search summaries of PMC6889403 / PMC6606631 say joint
  ranges shrink as walking slows and that a mismatch of speed, age, sex or BMI can shift sagittal curves by > 5°);
  those pages were not opened.
- First MTP dorsiflexion actually used in walking: snippet only (≈ 42° in gait, 44° active test, 58° heel rise from
  Nawoczenski 1999; other snippets say 50° or 65-75° "needed") - sources disagree, none of those numbers was in a
  fetched page except the QUT 35-40° minimum.
- Frontal / transverse knee and hip curves in gait; sprint knee and ankle angles: not found.

---

## 3. Normal joint ranges of motion and degrees of freedom

### Takeaway
Measured population means (CDC, 20-44 y) are a little lower than the classic chart values: hip 130-134° flexion /
17-18° extension, knee 138-142° flexion with only ≈ 1-2° past straight, ankle 13-14° dorsiflexion / 55-62°
plantarflexion, shoulder flexion 169-172°, elbow 145-150° flexion with ≈ 1-5° past straight, forearm ≈ 77-82° pronation
and 85-91° supination. The spine's motion is unevenly shared: the neck has the most (≈ 64° flexion, 63° extension,
49° side bend, 85° rotation each way), the lumbar spine bends but hardly twists (≈ 15°), the thoracic spine twists
(≈ 47°) but hardly bends forward.

### Cited Findings

**CDC normal joint range of motion study (> 600 people without joint conditions, 2003-2006; Soucie et al., Haemophilia), mean
values in degrees, ages 20-44, female / male:** hip extension 18.1 / 17.4; hip flexion 133.8 / 130.4; knee flexion
141.9 / 137.7; knee extension (beyond straight) 1.6 / 1.0; ankle dorsiflexion 13.8 / 12.7; ankle plantarflexion
62.1 / 54.6; shoulder flexion 172.0 / 168.8; elbow flexion 150.0 / 144.6; elbow extension (beyond straight) 4.7 / 0.8;
pronation 82.0 / 76.9; supination 90.6 / 85.0. Ages 45-69: hip extension 16.7 / 13.5; hip flexion 130.8 / 127.2; knee
flexion 137.8 / 132.9; knee extension 1.2 / 0.5; dorsiflexion 11.6 / 11.9; plantarflexion 56.5 / 49.4; shoulder flexion
168.1 / 164.0; elbow flexion 148.3 / 143.5; elbow extension 3.6 / −0.7; pronation 80.8 / 77.7; supination 87.2 / 82.4.
Children 2-8 are looser (e.g. knee flexion 152.6 / 147.8, hip extension 26.2 / 28.3, dorsiflexion 24.8 / 22.8).
[primary, official] - [CDC archive: Normal Joint Range of Motion Study](https://archive.cdc.gov/www_cdc_gov/ncbddd/jointROM/index.html)

**Clinical evaluation chart "normal" values (Washington State DSHS form 13-585A, degrees):** back flexion 90,
extension 25, lateral flexion 25 each side; neck flexion 50, extension 60, lateral bending 45 each side, rotation 80
each side; hip flexion 100, backward extension 30, abduction 40, adduction 20; knee flexion 150; shoulder abduction
150, adduction 30, flexion 150, extension 50; elbow extension 0, flexion 150; forearm pronation 80, supination 80;
wrist extension 60, flexion 60, radial deviation 20, ulnar deviation 30; ankle plantarflexion 40, dorsiflexion 20,
inversion 30, eversion 20; thumb MP flexion 60, thumb IP flexion 80. [secondary, official form; no source cited on it]
- [DSHS Range of Joint Motion Evaluation Chart](https://www.dshs.wa.gov/sites/default/files/forms/pdf/13-585a.pdf)

**Spine by region (in-vivo studies of healthy young males, meta-analysis summary):**
- Cervical (C0-C7): flexion 64°, extension 63°, lateral bending 49° each side, axial rotation 85° each side.
- Thoracic: flexion 26°, extension 22°, lateral bending 30° each side, axial rotation 47° each side.
- Lumbar: flexion 65°, extension 31°, lateral bending 30° each side, axial rotation 15.3° each side.
  [secondary, compiles ~40 primary studies] -
  [Anatomy Standard: ROM of the spine](https://anatomystandard.com/biomechanics/spine/rom-of-spine.html)
- Cervical range varies widely between people and falls with age in all directions (96 healthy volunteers).
  [abstract] - [Cagnie et al. 2007, J Manipulative Physiol Ther](https://europepmc.org/article/MED/17693335)

**Shoulder complex (glenohumeral + scapula + clavicle)**
- Bone-pin study, 12 healthy subjects: glenohumeral-to-scapulothoracic rhythm 2.1:1 in abduction, 2.4:1 in flexion,
  2.2:1 in scapular-plane abduction. Up to 120° of arm elevation the scapula rotates upward on the thorax from 11° to
  50° (≈ 40°) while the humerus elevates ≈ 85° on the scapula; the humerus externally rotates from ≈ 10° to ≈ 51°;
  the clavicle retracts 23° → 39°, elevates 11° → 17° and rotates backward about its long axis 0° → 31°. [primary] -
  [Ludewig et al. 2009, JBJS Am](https://pmc.ncbi.nlm.nih.gov/articles/PMC2657311/)
- Ball-and-socket (multiaxial) joint; ≈ 120° of unassisted flexion at the glenohumeral joint itself; in abduction the
  deltoid and supraspinatus act in the first 90°, trapezius and serratus anterior (scapular rotation) from 90° to 180°.
  [secondary, uncited on the page] - [Wikipedia: Shoulder joint](https://en.wikipedia.org/wiki/Shoulder_joint)

**Elbow and forearm**
- Flexion from 0° (full extension) to 150°; active flexion limited to 145°, passive 160° (Kapandji). [secondary] -
  [Wikipedia: Elbow](https://en.wikipedia.org/wiki/Elbow)
- Measured hyperextension is small: mean 0.8° in men and 4.7° in women aged 20-44 (CDC, above).

**Wrist**
- Flexion up to 70°, extension up to 60°, radial deviation up to 20°, ulnar deviation up to 30°; pronation /
  supination happen at the radio-ulnar joints, not the wrist proper. [secondary] -
  [Wikipedia: Wrist](https://en.wikipedia.org/wiki/Wrist)

**Fingers and thumb**
- PIP flexion ≈ 100°, DIP flexion ≈ 80°; hyperextension limited by the palmar plate / ligaments. MCP joints flex,
  extend, abduct, adduct and circumduct; abduction / adduction is very limited and impossible in a fist.
  [secondary] - [Wikipedia: Interphalangeal joints of the hand](https://en.wikipedia.org/wiki/Interphalangeal_joints_of_the_hand);
  [Wikipedia: Metacarpophalangeal joint](https://en.wikipedia.org/wiki/Metacarpophalangeal_joint)
- Functional (everyday-task) flexion postures average 61° at the MCP, 60° at the PIP and 39° at the DIP joints; thumb
  21° at the MCP and 18° at the IP, using only 32 % of available thumb flexion. [abstract] -
  [Hume et al. 1990, J Hand Surg](https://europepmc.org/article/MED/2324451)
- Thumb MP flexion 60°, thumb IP flexion 80° (DSHS chart, above).

**Hip**
- Flexion 140°, extension 20°, abduction 50° (hip extended) / 80° (hip flexed), adduction 30° / 20°, external rotation
  30° (extended) / 50° (flexed), internal rotation 40° (Thieme Atlas values). [secondary] -
  [Wikipedia: Hip](https://en.wikipedia.org/wiki/Hip)

**Knee**
- Flexion 120-150°; extension 5-10° (maximum); with the knee flexed 90°: internal rotation 10°, external rotation
  30-40°; about 5° of automatic rotation during the last 10° of extension (the "screw-home"). [secondary, Thieme /
  Platzer] - [Wikipedia: Knee](https://en.wikipedia.org/wiki/Knee)

**Ankle, subtalar, toes**
- Talocrural joint: dorsiflexion and plantarflexion (CDC means above; chart values 20° / 40°). Inversion 30°,
  eversion 20° (DSHS chart). First MTP: 70-90° dorsiflexion expected, ≈ 45° plantarflexion (QUT page, above).
- Qualitative: the ankle joint proper only dorsi- / plantarflexes, with slight side glide and rotation when
  plantarflexed. [secondary] - [Wikipedia: Ankle](https://en.wikipedia.org/wiki/Ankle)

**Source disagreement worth knowing**
- Hip flexion: 100° (DSHS chart) vs 130-134° (CDC measured) vs 140° (Thieme). Shoulder flexion: 150° (DSHS) vs
  169-172° (CDC). Plantarflexion: 40° (DSHS) vs 55-62° (CDC). Neck flexion: 50° (DSHS) vs 64° (meta-analysis). Lumbar
  /"back" flexion 90° on the chart includes hip motion; the lumbar spine alone is ≈ 65°. Knee extension: "5-10°"
  (Thieme maximum) vs ≈ 1-2° mean (CDC).
- Boone & Azen 1979 measured 109 males and found the AAOS handbook values needed age-specific correction - AAOS values
  are "estimations". [abstract] - [Boone & Azen 1979, JBJS Am](https://europepmc.org/article/MED/457719)

### Inferences
- Degrees of freedom to model: neck / spine 3 each region (bend forward-back, side-bend, twist) with the twist budget
  mostly in neck and thoracic, almost none in lumbar; shoulder 3 at the ball joint plus scapula following at roughly
  one third of arm elevation; elbow 1 hinge + forearm twist 1 (≈ 80° each way, done by the forearm, not the wrist);
  wrist 2 (no twist); MCP 2 (flex + small spread), PIP / DIP 1 each; hip 3; knee 1 hinge + small axial rotation only
  when flexed (≈ 10° in, 30-40° out at 90°) and none when straight; ankle 1 + subtalar inversion / eversion 1; toes 1.
- Elbow hyperextension clamp: 0° to about 5° (women slightly more) is the measured norm - an IK solver must not bend
  the elbow backwards. Same for the knee: ≈ 1-2° mean, never a visible back-bend.
- Total head turn available from the neck alone ≈ 80-85° each way; adding thoracic (≈ 47°) and lumbar (≈ 15°) twist
  gives roughly 145° of look-behind from fixed hips if every region is used to its end range - a comfortable look-at
  should use far less (see section 4: 15-30° head lead in real turning).
- Hand reach overhead: beyond ≈ 30° of elevation the shoulder girdle must visibly rotate / rise (≈ 1° scapula per 2°
  humerus; ≈ 40° of scapular upward rotation by 120° elevation).

### Gaps (not found / unverified)
- AAOS "Joint Motion: Method of Measuring and Recording" original table: not fetched (only charts derived from it).
- Finger MCP flexion / hyperextension limits (commonly quoted ≈ 90° / 20-30°), thumb CMC ranges, finger abduction
  angles: NOT found in any fetched page.
- Shoulder internal / external rotation, horizontal adduction / abduction: not found in a fetched page.
- Subtalar range measured in a study (only the chart's inversion 30° / eversion 20°); lesser-toe MTP ranges: not found.
- Per-vertebra spine ranges (White & Panjabi): not fetched.
- NASA-STD-3000 joint motion tables: host blocked in this session.

---

## 4. Turning, starting, stopping

### Takeaway
People turn head-first: gaze leads the body by ≈ 0.3-0.55 s and the head by ≈ 0.2-0.25 s, with the head yawed
≈ 15-30° into the turn; they slow down and lean / shift the centre of mass inward. A walk can be stopped in under two
steps and reaches steady speed in about 3 steps (up to 5); stopping from a fast run takes about 5 steps and ≈ 2.9 m.

### Cited Findings

**How much turning there is, and the two strategies**
- Turning steps are 8 % (office to car park), 35 % (store), 45 % (office to office) and 50 % (cafeteria) of all steps
  in everyday walking tasks. [abstract] - [Glaister et al. 2007, Gait Posture](https://europepmc.org/article/MED/16730441)
- Step turn = turning away from the stance foot (e.g. right foot in front, turn left: shift weight to the right leg,
  externally rotate the left hip, step onto the left leg, continue until the right leg steps in the new direction).
  Spin turn = pivoting toward the stance foot (right foot in front, turn right: spin the body about the right foot).
  The step turn is easy and stable because the base of support is much wider; some subjects used it everywhere in the
  cycle. A sudden turn starts with a braking action like a rapid stop; foot placement and trunk rotation are adjusted
  within one step of the cue; most subjects complete the turn without resetting the walking rhythm. [abstract] -
  [Hase & Stein 1999, J Neurophysiol](https://europepmc.org/article/MED/10368408)
- 90° turns: spin turns come in two forms ("ipsilateral crossover" and "ipsilateral pivot"), need more transverse-plane
  range and more muscle effort than step turns; step turns keep a wide base and are no more demanding than straight
  walking. [abstract] - [Taylor et al. 2005, Hum Mov Sci](https://europepmc.org/article/MED/16129503)
- 90° corner, 10 young adults: approach speeds 0.93 / 1.43 / 2.03 m/s became turning speeds 1.10 / 1.27 / 1.65 m/s;
  the centre of mass was outside the base of support for the whole first half of stance; lean (mediolateral
  centre-of-mass to centre-of-pressure angle at ≈ 10 % of stance) 4.4° slow, 6.8° normal, 12.7° fast; 14.6° for step
  turns vs 3.4° for spin turns; faster walkers cut closer to the corner. [primary] -
  [Fino, Lockhart & Fino 2015, J Biomech](https://pmc.ncbi.nlm.nih.gov/articles/PMC4274227)

**Walking a curve**
- 1 m radius circle: self-selected speed 0.96 ± 0.12 m/s vs 1.61 ± 0.22 m/s straight; more stance knee flexion on the
  inside leg, more ankle plantarflexion on the outside leg (consistent with body lean); mediolateral ground impulses
  push the body toward the inside. [abstract] - [Orendurff et al. 2006, Gait Posture](https://europepmc.org/article/MED/16311202)
- Stride length is unchanged for the outer leg and shorter for the inner leg; the feet pivot toward the inside at heel
  strike, ahead of the body rotation; the centre of mass shifts and the trunk rolls toward the inside; the head turns
  more than the heading change and head yaw leads body yaw by ≈ 200 ms; with eyes open the head is pitched down to look
  at the path. [abstract] - [Courtine & Schieppati 2003, Eur J Neurosci](https://europepmc.org/article/MED/12859351)
- Sharp corner on a 50 cm radius is taken over two steps, a 200 cm radius in five to seven steps; peak centripetal
  acceleration in sharp turns ≈ 0.4 g, tilting the apparent "down" by ≈ 21°; the head rolls into the turn by up to 8°
  in anticipation; head yaw leads the change of path by up to 25°; the TRUNK does not anticipate; gaze jumps ahead along
  the path in saccades, further ahead when turning faster. In straight walking the body sways sideways at stride
  frequency and yaws with each step while the head keeps pointing along the heading. [abstract] -
  [Imai et al. 2001, Exp Brain Res](https://europepmc.org/article/MED/11204402)

**Head / gaze anticipation**
- Order: gaze, then head, then trunk / pelvis and feet. Relative to the pelvis, gaze leads by 557 ± 160 ms and head by
  264 ± 134 ms in light (269 ms and 129 ms in darkness); angular lead in light: gaze 27.5 ± 6.9°, head 14.8 ± 6.0°
  (halved in darkness). Walking speed on the curved paths 0.80 ± 0.14 m/s. [primary] -
  [Authié et al. 2015, Front Hum Neurosci](https://www.frontiersin.org/journals/human-neuroscience/articles/10.3389/fnhum.2015.00312/full)
- Figure-of-eight path: maximum head deviation toward the future direction 29.75 ± 7.41° (left) and 30.86 ± 9.92°
  (right). [abstract] - [Hicheur, Vieilledent & Berthoz 2005, Neurosci Lett](https://europepmc.org/article/MED/15936517)
- The head starts turning at a constant DISTANCE before the turn (≈ 1.1 m before the obstacle) for 45°, 90° and 135°
  turns, not at a constant time; the head-trunk difference grows with turn angle; walking speed drops steadily as the
  turn angle grows (45° → 180°). [abstract] - [Sreenivasa et al. 2008, Exp Brain Res](https://europepmc.org/article/MED/18688604)

**Turning on the spot (180°), 21 healthy young adults**
- Segment onset order at every speed: head (≈ 0.52-0.54 s after the cue), thorax (0.55-0.58 s), pelvis (0.57-0.65 s),
  leading foot (0.69-0.91 s), trailing foot (0.89-1.25 s). Peak head yaw velocity 272 °/s (fast, 1.5 s turn),
  181 °/s (moderate, 2 s), 137 °/s (slow, 3 s). Peak head-to-pelvis twist 22.5° / 18.5° / 15.7°. Steps to complete
  180°: 2.95 / 3.43 / 4.31; each step turns the foot ≈ 73-79°. [primary] -
  [Khobkhun, Hollands & Richards 2021, Sensors](https://pmc.ncbi.nlm.nih.gov/articles/PMC8074235/)

**Running a bend**
- Six sprinters at maximal effort, radius 41.85 m: body lean (vertical vs foot-to-centre-of-mass line) at toe-off 13.6°
  on the outside (right) foot and 2.05° on the inside (left) foot - lean increases during outside-foot contact and
  decreases during inside-foot contact; contact time 0.112 s outside vs 0.125 s inside; required centripetal force
  F = m v² / r. [primary, conference paper] -
  [Ishimura & Sakurai, ISBS](https://ojs.ub.uni-konstanz.de/cpa/article/view/4574/4261)
- Seven sprinters, bend radius 37.72 m: speed drops 4.7 % vs the straight (9.86 → 9.39 m/s on left steps); left step
  frequency −0.11 Hz, right step length −0.10 m; inside (left) hip 4° more adducted at touchdown. [abstract] -
  [Churchill, Salo & Trewartha 2015, Sports Biomech](https://europepmc.org/article/MED/25896099)

**Starting (gait initiation)**
- Before the first step the centre of pressure moves backward (anticipatory postural adjustment: tibialis anterior
  switches on, soleus relaxes - seen in all subjects), so the body "falls" forward; initiation cannot happen without an
  offset between centre of mass and centre of pressure. Velocity at the end of the first step is ≈ 90 % of the mean
  velocity of the second step; early papers therefore said gait is initiated in 1-2 steps, but studies tracking more
  steps show steady state is reached over 3 to 5 steps; the experimental data used here show ≈ 3 steps. The time to
  initiate is roughly invariant across target speeds. In the model, the anticipatory adjustment cut the energy cost of
  starting by ≈ 58 %. [primary modelling paper reviewing experiments] -
  [Anand, Seipel & Rietdyk 2017](https://pmc.ncbi.nlm.nih.gov/articles/PMC5378148);
  [post-print PDF](https://purdue.edu/hhs/hk/Biomechanics-MotorBehavior/wp-content/uploads/2017/04/Anand-Seipel-Rietdyk-2017-Model-Gait-Initiation-Post-Print-version.pdf)

**Stopping (gait termination)**
- Rapid stop from comfortable walking: people stop with one foot in front of the other; three mechanisms -
  (1) the swing leg is stiffened in extension just before it lands, to brake; (2) the push-off of the rear leg is
  suppressed so it stays on the ground behind the body; (3) if that is not enough, the body rises onto the toes of the
  front leg (kinetic → potential energy). If momentum would still carry the centre of mass past the front foot, one
  more quick short step is taken. Muscle responses appear across legs and trunk within 150-200 ms of the cue.
  [abstract] - [Hase & Stein 1998, J Neurophysiol](https://europepmc.org/article/MED/9658047)
- Walking can be terminated in less than 2 steps (citing Hase & Stein 1998); stopping from a run needs several. Adults
  running as fast as possible and stopping at a target: 5.13 ± 0.91 steps, deceleration distance 2.89 m, deceleration
  time 0.72 s, step length 0.71 m, stance time 0.16 s; the centre of mass is kept BEHIND the feet (mean posterior
  position 0.30 of standing centre-of-mass height; in front of the feet only 9 % of the time) and never rises above
  standing height. Children: 4.59 steps, 2.58 m, 0.78 s. [primary] -
  [Cesar & Sigward 2015, Hum Mov Sci](https://pmc.ncbi.nlm.nih.gov/articles/PMC4570872)

### Inferences
- Lean check: tan(lean) = v² / (r·g). Sprint at 9.4 m/s on r = 37.7 m gives ≈ 13.4°, matching the measured 13.6° on
  the outside foot. Walking 0.96 m/s on r = 1 m gives ≈ 5.4°, in line with Fino's 4-7° at slow-to-normal corner
  speeds. So procedural lean should follow v² / (r·g), not speed alone, and is only a few degrees at walking speed.
- Yaw rate while walking a 1 m radius at 0.96 m/s = v / r ≈ 0.96 rad/s ≈ 55 °/s; a 90° walking corner on a 0.5 m radius
  takes two steps (≈ 1 s at ~115 steps/min), i.e. ≈ 90 °/s average. On-the-spot 180° turns peak at ≈ 140-270 °/s at the
  head and take about 3-4 steps of ≈ 75° each. An instant 180° snap, or > 300 °/s body yaw, is outside this data.
- People slow down to turn (1.61 → 0.96 m/s on a tight circle; fast walkers 2.03 → 1.65 m/s at a corner); a character
  holding full speed through a tight turn is not human-like.
- Look-at: start head yaw ≈ 0.2-0.3 s (or ≈ 1.1 m of travel) before the body turns, eyes ≈ 0.3 s earlier still; head
  yaw offset 15-30° toward the new direction, plus up to ≈ 8° of head roll into a sharp turn; the trunk follows without
  leading.
- Stop from walk: 1-2 steps, with a visible stiff front leg, a rear foot that stays planted, and a slight rise onto the
  toes when the stop is abrupt. Stop from sprint: ≈ 5 short (0.7 m) steps over ≈ 3 m with the body leaning BACK.
- Start: a small backward / sideways weight shift precedes the first step; first step already ≈ 90 % speed, full walk
  speed by step 3.

### Gaps (not found / unverified)
- Head-before-trunk lead of "0.2-0.6 s across studies": snippet only; the fetched values are ≈ 200 ms (Courtine) and
  264 ms (Authié).
- Duration and size of the anticipatory weight shift before the first step (ms, cm): not found in a fetched page.
- Forward trunk lean during acceleration and backward lean during deceleration in DEGREES: not found (only the
  centre-of-mass-behind-feet measure for stopping).
- Steps to reach top running speed for untrained people on ground; steps to stop from a jog (not a sprint): not found.
  The conference-poster figure (5.56 steps) is snippet only.
- Peak whole-body turning velocity during walking turns in free living (wearable-sensor norms): not found.
- Lean angle vs radius for running at jog speeds: not measured in a fetched source (only the physics relation).

---

## 5. Balance and posture (centre of mass, base of support, load, idle sway)

### Takeaway
The standing centre of mass sits at about 55 % of body height, just in front of the upper sacrum; quiet standing is
never still - the pressure point under the feet wanders slowly (most power below ≈ 0.3 Hz) with faster corrections up
to ≈ 1-2.5 Hz. A backpack makes people lean the trunk forward (≥ 10° reported with 10-17 kg military loads), step
faster and, in most studies, shorter.

### Cited Findings
- Whole-body centre of gravity at the sacral promontory, anterior to S2, at 55 % of body height. Stability rises with
  larger mass, lower centre of gravity, larger base of support and a centre-of-gravity projection near the centre of
  the base; mobility with the opposite. [secondary, university course notes citing Brunnstrom's Clinical Kinesiology] -
  [Thompson, Univ. of Oklahoma HSC: Body segments and masses](https://ouhsc.edu/bserdac/dthompso/web/namics/mass.htm)
- Standing centre of gravity 5 cm anterior to the S2 vertebral body. [secondary] -
  [OrthoBullets](https://www.orthobullets.com/foot-and-ankle/7001/gait-cycle)
- Quiet standing, 15 healthy young men, eyes open, 70 s trials: mean front-back centre-of-pressure position 51 ± 18 mm
  relative to the force-platform origin (a position, not a sway amplitude); median sway frequency ≈ 0.33 Hz in both directions, 95 % of power below
  ≈ 1.14 Hz (front-back); sway bands described as slow (≈ 0.04-0.5 Hz), fast (0.5-1.0 Hz), very fast (1.0-2.5 Hz);
  velocity changes direction ≈ 140 times per 70 s (median interval ≈ 0.2 s). [primary] -
  [Yamamoto et al. 2015, Physiol Rep](https://pmc.ncbi.nlm.nih.gov/articles/PMC4393163/)
- During a turn, and in the first half of every stance when cornering, the centre of mass is OUTSIDE the base of
  support - walking balance is dynamic, not static. [primary] -
  [Fino et al. 2015](https://pmc.ncbi.nlm.nih.gov/articles/PMC4274227)
- Backpack carriage (54 studies): increased trunk flexion angle, increased hip and ankle range of motion, higher
  vertical and horizontal ground reaction forces, increased cadence, reduced stride length; results depend on speed,
  skill, hip belt and how far the load sits behind the trunk. [abstract] -
  [Liew, Morris & Netto 2016, J Appl Biomech](https://europepmc.org/article/MED/27705050)
- Soldiers with 4.2-17.5 kg (6.5-27.2 % body weight) at self-selected speed: step length, stride length and cadence all
  INCREASED vs no load; ankle more dorsiflexed, knee and hip more flexed at foot strike; trunk forward inclination
  ≥ 10° with a 10.7 kg backpack, 14.9 kg (pack + rifle) and 17.5 kg (pack + light machine gun). [abstract] -
  [Majumdar, Pal & Majumdar 2010, Ergonomics](https://europepmc.org/article/MED/20496244)

### Inferences
- Stride length under load: the meta-analysis says shorter, the Indian infantry study says longer (speed was free to
  change there) - treat "more cadence, more trunk lean, more knee / hip flexion at strike" as the robust part.
- Idle animation: a slow drift (period ≈ 3 s and longer) with small quick corrections is the measured character of
  standing; a perfectly rigid stand or a regular metronome sway is not.
- With the centre of mass at ≈ 55 % of height (≈ 0.97 m for a 1.76 m man), the pivot for whole-body lean is the foot,
  and a few degrees of lean moves the centre of mass several centimetres (1° ≈ 1.7 cm at 0.97 m).

### Gaps (not found / unverified)
- Sway amplitude in mm for healthy adults (range / RMS): not in the fetched text (the paper reports log-transformed
  velocity and path length). The "contained within the size of a dime" description and 9.2 mm/s mean velocity are
  snippet only.
- Frequency of spontaneous weight shifts in long relaxed standing (Duarte & Zatsiorsky's shifting / fidgeting /
  drifting): not found.
- Sex difference in centre-of-mass height (often quoted ≈ 55 % women / 57 % men): not found in a fetched page.
- Base-of-support dimensions (natural stance width, foot angle): not found.
- Posture with one-handed / front / asymmetric loads: not found.

---

## 6. Body proportions (anthropometry), eye height, reach, step height

### Takeaway
For a median US Army man (stature 1755 mm): eye height ≈ 93.5 % of stature, shoulder ≈ 82 %, elbow ≈ 62 %, hip
(trochanter) ≈ 51 %, knuckle ≈ 42 %, arm span ≈ 103 %, standing vertical grip reach ≈ 122 %. Women's ratios are within
about one percentage point. The classic Drillis & Contini / Winter segment table itself could not be opened.

### Cited Findings
- 2012 Anthropometric Survey of US Army Personnel (Gordon et al. 2014) as tabulated by NC State's Ergonomics Center,
  inches, 5th / 50th / 95th percentile, men then women:
  stature 64.88 / 69.09 / 73.62 and 60.04 / 64.02 / 68.50;
  eye height 60.47 / 64.57 / 69.02 and 55.94 / 59.72 / 64.02;
  shoulder height 52.72 / 56.65 / 60.87 and 48.90 / 52.44 / 56.46;
  elbow height 39.53 / 42.64 / 45.94 and 36.69 / 39.45 / 42.68;
  hip height 32.44 / 35.39 / 38.78 and 30.47 / 33.23 / 36.18;
  knuckle height 26.50 / 28.78 / 30.51 and 24.88 / 27.01 / 28.50;
  fingertip height 23.35 / 25.75 / 28.23 and 21.89 / 24.13 / 26.46;
  sitting height 33.86 / 36.14 / 38.46 and 31.61 / 33.74 / 35.91; sitting eye height (50th) 31.65 and 29.45;
  sitting knee height (50th) 21.77 and 20.08; popliteal height (50th) 16.93 and 15.24;
  shoulder breadth bideltoid (50th) 20.04 and 17.72, biacromial 16.34 and 14.37; hip breadth 13.54 and 13.90;
  shoulder-elbow length (50th) 14.29 and 13.15; elbow-fingertip length 18.90 and 17.24; upper-limb length 30.94 and
  28.35; hand length 7.60 and 7.09; foot length 10.67 and 9.59; foot breadth 4.02 and 3.66; head length 7.87 and 7.48;
  arm span 66.14 / 71.34 / 77.05 and 60.20 / 65.24 / 70.98;
  vertical grip reach standing 77.68 / 84.21 / 91.90 and 71.34 / 77.32 / 84.21;
  forward grip reach (50th) 29.76 and 27.20. [secondary table of a primary survey; military population, not civilians] -
  [NC State Ergonomics Center: Anthropometry Summary Tables](https://ergocenter.ncsu.edu/wp-content/uploads/sites/358/2026/02/01-Anthropometry-Summary-Tables.pdf)
- Leg length of elite sprinters: 0.94 ± 0.02 m (men), 0.87 ± 0.03 m (women). [primary] -
  [Murphy et al. 2021](https://pmc.ncbi.nlm.nih.gov/articles/PMC8580521)
- Artists' canon: average figure ≈ 7.5 heads tall; legs (floor to crotch) 3.5-4 heads; arms ≈ 3 heads; hand ≈ one face
  length; the half-height point is at the level of the greater trochanters, just above the pubic arch.
  [secondary] - [Wikipedia: Body proportions](https://en.wikipedia.org/wiki/Body_proportions)
- The Drillis & Contini (1966) segment-length fractions (as reproduced in Winter) were derived from adults; applied to
  children they mis-predict arm, forearm, sitting height and shoulder width by ≈ 5-16 %. [primary, conference paper] -
  [Wisner et al. 2006, ISBS](https://ojs.ub.uni-konstanz.de/cpa/article/view/292/249)

### Inferences (my arithmetic on the NC State 50th-percentile values)
- Men, as a fraction of stature (69.09 in = 1755 mm): eye 0.935 (1640 mm); shoulder 0.820; elbow 0.617; hip 0.512;
  knuckle 0.417; fingertip 0.373; sitting height 0.523; arm span 1.033; vertical grip reach 1.219 (2139 mm);
  shoulder-elbow 0.207; elbow-fingertip 0.274; whole upper limb 0.448; hand 0.110; foot length 0.154; biacromial
  breadth 0.237; hip breadth 0.196.
- Women (64.02 in = 1626 mm): eye 0.933 (1517 mm); shoulder 0.819; elbow 0.616; hip 0.519; arm span 1.019; vertical
  grip reach 1.208 (1964 mm).
- Standing reach without rising on the toes or jumping is therefore ≈ 1.2 × stature to the GRIP centre (fingertips a
  little higher); a ledge above ≈ 2.1-2.2 m needs a jump for a median man.
- Camera / look-at origin: eyes sit ≈ 115 mm below the top of the head for the median man (1755 − 1640 mm).

### Gaps (not found / unverified)
- Winter / Drillis & Contini fraction-of-height table (the widely quoted upper arm, forearm, thigh, shank, foot and
  shoulder-width fractions) and Winter's / Dempster's segment mass and centre-of-mass fractions: NOT fetched - the
  Penn State page returned 404, Human Kinetics shows the figure only as an image, exrx.net and BioNumbers failed. Do not
  use remembered values; take them from the book or from the NC State / ANSUR numbers above.
- Maximum step-up height a person can manage without hands, comfortable stair riser, vault / climb heights: not found.
- NASA-STD-3000 / MSIS anthropometry and reach envelopes: host blocked.
- Civilian (non-military) eye height and reach percentiles: not found.
