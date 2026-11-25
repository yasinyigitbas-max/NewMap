# Rig player_v4 on Mixamo and download his clips (run on the PC)

Decided 25 Nov 2026: Mixamo rigs the new character and fits every clip to him, so clips drop in with nothing to correct. This needs the Mixamo login, so it has to be done on the PC. This file replaces `Mixamo download list.md` for the player.

What I could and could not check: Mixamo's site needs a login, so the steps below follow Adobe's help page and user reports, not the live screens. Button names may differ slightly.

## What you need

`player_v4_for_mixamo.zip` (sent with this file). It holds the unrigged v4 body as an OBJ with its texture: 15,587 triangles, T-pose, 181 units tall, feet on the ground at the origin, facing forward. Upload the zip as it is; do not unpack it.

## Step 1. Upload and rig

1. Go to mixamo.com, sign in, and choose **Upload Character**. Pick `player_v4_for_mixamo.zip`.
2. Check the preview: he should stand upright facing you. If he lies down or faces away, use the rotate arrows until he does.
3. Place the markers. Mixamo asks for the chin, both wrists, both elbows, both knees and the groin. Keep **Use Symmetry** on. Where you put them decides where his joints go, so take care with three:
   - **Groin:** at the top of the gap between the legs, not lower down on the trousers.
   - **Wrists:** where the hand meets the forearm, not inside the forearm.
   - **Knees:** on the middle of each knee.
4. For **Skeleton LOD** choose **Standard Skeleton (65)**, the one with full fingers.
5. Finish. Watch the test animation: fingers should bend separately, feet should stay flat, and nothing should stretch. If the hands or feet look wrong, go back and move the markers.

## Step 2. Download the character

Download him once with these settings: **FBX Binary, T-pose, With Skin**. Name the file `player_v4_mixamo.fbx`.

## Step 3. Download the clips for him

With him as the active character, download each clip below with: **FBX Binary, Without Skin, 30 frames per second, keyframe reduction none, "In Place" off**. Download clips one at a time; packs ignore these settings.

Each line is the file name in the Drive folder; download the same Mixamo clip again and keep the same file name. Put them in a new folder called `player_v4`, so they do not mix with the X Bot versions.

**First batch: needed for Stages 2 to 7 (35 clips)**

- Standing: `Standing Idle`, `Idle`
- Walk and run: `Walking (4)`, `Walking`, `Slow Run`, `Running (3)`, `Running`, `Sprint`, `Walking Backwards`
- Curves: `Walking Left Turn`, `Running Left Turn (2)`, `Running Right Turn`
- Strafe (from the Male Locomotion Pack, downloaded singly): `left strafe walking`, `right strafe walking`, `left strafe`, `right strafe`
- Starts and stops: `Female Start Walking`, `Female Stop Walking`, `Start Walking`, `Stop Walking`, `Idle To Sprint`, `Run To Stop`
- Turns: `Left Turn 90`, `Right Turn 90`, `Walking Turn 180`, `Running Turn 180`
- Crouch: `Crouching Idle`, `Crouched Walking`, `Standing To Crouched`, `Crouched To Standing`, `Sneaking Forward`
- Stairs: `Ascending Stairs`, `Descending Stairs`, `Running Up Stairs`, `Run Down Stairs`

**Second batch: the traversal moves, Stage 8 onward (33 clips)**

- Air and landing: `Falling Idle`, `Falling To Landing`, `Hard Landing`, `falling to roll` (Action Adventure Pack), `Jumping Down (2)`, `Jump`, `Running Jump`
- Up onto things: `Step Onto Platform`, `Jumping (2)`, `Running Jump Climb`, `Sprint To Wall Climb`
- Vaults: `Vault 1 Hand`, `Vault 2 Hands`
- Braced hang: `Jump To Braced Hang`, `Braced Hang To Crouch`, `Braced Hang Shimmy Left`, `Braced Hang Shimmy Right`, `Braced Hang Drop`, `Braced To Freehang`, `Freehang To Braced`
- Free hang: `Stand To Freehang`, `Hanging Idle`, `Freehang Shimmy Left`, `Freehang Shimmy Right`, `Freehang Climb`, `Climbing single`, `Drop To Freehang`, `Freehang Drop`
- Down: `Climbing Down`, `Climbing Down (2)`
- Getting up: `Getting Up`, `Standing Up`, `Push Up To Idle`

**Third batch: cover, doors and cars, the last stages (17 clips)**

- Cover: `Cover Idle`, `Crouch cover idle`, `stand to cover`, `stand to cover (2)`, `cover to stand`, `cover to stand (2)`, `Left Cover Sneak (1)`, `Right Cover Sneak`, `Crouch Cover To Cover`, `Standing Cover Turn`, `Crouch Cover Turn`, `Crouch Look Around Corner`
- Doors: `Open Door Outwards`, `Opening Door Inwards`
- Cars: `Entering Car`, `Exiting Car`
- Ladder, if wanted: `Start Climbing Ladder`

**Fourth batch: everything else, for cinematics and for the player's acting (284 clips)**

Added after Yasin pointed out that the remaining clips are needed too. These are all the other distinct motions in the folder (the folder holds 426 files, of which 55 are copies of another file under a second name; copies are left out here). They are not needed to build the movement system, so download them after the first three batches. If the download is scripted, as the Animator session did it, run the whole list.

`180 Turn W_ Briefcase`, `180 Turn W_ Briefcase (1)`, `Acknowledging`, `Administering Cpr`, `Agreeing`, `Aim Pistol sitting`, `Aiming Gun`, `Angry`, `Angry Gesture`, `Angry Gesture sitting`, `Angry talking phone`, `Arm Gesture`, `Arm Stretching`, `Asking Question`, `Bartending`, `Being Carried out down`, `Being Carried pick up`, `Being Carried walking`, `Being Strangled`, `Big Hit To Head`, `Bored`, `Box Idle`, `Box Turn`, `Box Turn (1)`, `Box Walk Arc`, `Cards`, `Carrying Turn`, `Cheering`, `Cheering While Sitting`, `Climbing Down ladder`, `Climbing Ladder fast`, `Climbing To Top ladder`, `Climbing double`, `Climbing ladder slow`, `Closing A Lid`, `Cocky Head Turn`, `Combo Punch`, `Counting`, `Crouch To Stand`, `Crouch To Stand (1)`, `Crouch Turn To Stand`, `Crouched Sneaking Right`, `Crouched To Sprinting`, `Dancing`, `Dancing (1)`, `Dice Idle`, `Disappointed`, `Disappointed (2)`, `Drinking Fountain`, `Drunk Idle Variation`, `Drunk Turn`, `Drunk Walking Turn`, `Dying`, `Elbow Punching`, `Excited`, `Fall Flat`, `Fallen Idle`, `Falling`, `Falling Down on ass`, `Falling Flat Impact`, `Falling From Losing Balance`, `Falling Into Pool`, `Falling Into Pool (1)`, `Fast Run`, `Female Peek And Aim`, `Fight Idle (1)`, `Fight Idle To Action Idle`, `Fight backstep`, `Fight forwardstep`, `Fight idle`, `Fight sidestep (L)`, `Fight sidestep (R)`, `Fighting Idle`, `Finding`, `Fist Pump`, `Fistfight Taunt`, `Hand Raising`, `Hands Forward Gesture`, `Happy Right Turn`, `Having A Meeting, Female`, `Having A Meeting, Male`, `Head Hit`, `Hit By Car`, `Hit On The Back`, `Hit Reaction`, `Hit To Body`, `Hook`, `Hostage Situation Idle - Hostage`, `Hostage Situation Idle - Villain`, `Idle (1)`, `Idle To Push Up`, `Idle Transition`, `Injured Run Jump`, `Injured Standing Jump`, `Injured Turn Left`, `Injured Turn Right`, `Injured Walking arm`, `Injured walking leg`, `Insult`, `Jab To Elbow Punch`, `Jog In Circle`, `Jogging Stumble`, `Jogging With Box`, `Jump (1)`, `Jump To Hang`, `Jumping`, `Jumping (1)`, `Jumping Down`, `Jumping Down (1)`, `Jumping Over Into Combat`, `Jumping Rope`, `Kick To The Groin`, `Kicking Out`, `Kiss`, `Kneeling`, `Kneeling Pointing`, `Knocked Out`, `Knocked Out (1)`, `Laying Idle`, `Left Turn`, `Left Turn W_Briefcase`, `Light Hit To Head`, `Look Behind Run`, `Looking`, `Looking Around idle`, `Moonwalk`, `Neck Stretching`, `No`, `Northern Soul Dance`, `Offensive Idle`, `Old Man Walk`, `Opening A Filing Cabinet`, `Opening locked`, `Opening slide door`, `Orc Idle`, `Pacing And Talking On A Phone`, `Paddling`, `Patting`, `Pistol Idle`, `Pointing`, `Pointing Forward`, `Pointing back thumb`, `Praying`, `Praying (1)`, `Punching`, `Punching (1)`, `Push Stop`, `Quick Formal Bow`, `Rallying`, `Rapping`, `Receive Punch To The Face`, `Receiving Cpr`, `Reloading`, `Restrain`, `Rifle Start Run`, `Right Turn`, `Right Turn W_ Briefcase`, `Rolling`, `Run Look Back`, `Run To Dive`, `Run To Stop Without climb`, `Run With Sword`, `Running (1)`, `Running Away Scared`, `Running To Turn`, `Running with a box`, `Salute`, `Sarcastic Head Nod`, `Seated table Idle`, `Shaking Hands 1`, `Shaking Hands 2`, `Shooting Gun`, `Shopping Cart Dance`, `Shoulder Hit And Fall`, `Shove Reaction`, `Shove Reaction (1)`, `Shoved Reaction With Spin`, `Shuffling`, `Silly Dancing`, `Singing`, `Sit To Stand`, `Sit To Type`, `Sitting Clap`, `Sitting Disapproval`, `Sitting Disbelief`, `Sitting Idle`, `Sitting Idle (1)`, `Sitting Thumbs Up`, `Sitting Yell`, `Sitting talking`, `Situp To Idle`, `Sleeping Idle`, `Smoking`, `Sneak off the cover`, `Spat In Face`, `Spinning`, `Stand To Sit`, `Standing Arguing`, `Standing Arguing (1)`, `Standing Cheering`, `Standing Greeting`, `Standing Up (1)`, `Standing Using Touchscreen Tablet`, `Standing W_Briefcase Idle`, `Step Hip Hop Dance`, `Step Up Vault`, `Stomping`, `Stop Walking With Rifle`, `Stumble Backwards`, `Stunned`, `Swatting Bugs`, `Taking Punch`, `Talking`, `Talking (1)`, `Talking (2)`, `Talking (3)`, `Talking (4)`, `Talking At Watercooler`, `Talking On A Cell Phone`, `Talking On Phone`, `Talking Phone Pacing`, `Taunt`, `Telling A Secret`, `Tender Placement`, `Terrified`, `Texting And Walking one hand`, `Texting While Standing`, `Thankful`, `Threatening`, `Tripping`, `Tripping (1)`, `Turn To Running`, `Type To Sit`, `Typing`, `Using A Filing Cabinet`, `Vault Over Box to Cover`, `Victory`, `Walk In Circle`, `Walk With Briefcase`, `Walk With Rifle`, `Walk carry stop`, `Walking (1)`, `Walking Carry`, `Walking Drunk`, `Walking Up The Stairs`, `Walking While Texting`, `Walking With Shopping Bag`, `Waving`, `Waving (1)`, `Waving (3)`, `Wheelbarrow Dump`, `Wheelbarrow Walk`, `Wiping Sweat`, `Working On Device crouched`, `Yelling`, `Yelling Out`, `sit Stand Up`, `sitting Pointing`

From the packs, downloaded singly: `crouched sneaking left`, `crouched sneaking right`, `idle (2)`, `idle (3)`, `idle (5)`, `injured backwards turn left`, `injured backwards turn right`, `injured hurting idle`, `injured idle`, `injured run`, `injured run backwards`, `injured run backwards left turn`, `injured run backwards right turn`, `injured run left turn`, `injured run right turn`, `injured stumble idle`, `injured walk`, `injured walk backwards`, `injured walk left turn`, `injured walk right turn`, `injured wave idle`, `jumping up`, `left cover sneak`, `left turn`, `right turn`, `standard run`

A note on NPCs: a clip downloaded for player_v4 is fitted to his body only. NPCs have other bodies, so they do not use these files. Keep the existing X Bot set as the shared library for NPCs and let the game's retargeting fit it to each body; talking, gesturing and sitting clips tolerate that well, because nothing in them has to land on an exact spot.

The first batch is enough to start building. The others can follow later.

## Step 4. Send them back

Upload `player_v4_mixamo.fbx` and the `player_v4` folder to the shared Google Drive folder "mixamo". Keep raw Mixamo files out of git.

Once they are there, the cloud session will:
- measure his new skeleton (leg, arm, ankle, hip) and the clips on it, and add them to the report;
- remake the seven Kimodo clips (crouch walk, mantles, beam walk, sidle, squeeze) on his skeleton, since the current ones are on X Bot.

## If something goes wrong

- **Mixamo refuses the zip:** unpack it and upload `player_v4.obj` alone; the texture is only for looks and can be put back in Godot.
- **The auto-rigger fails or the result is badly bent:** tell the cloud session what you saw. The fallback is route 2 in the report: keep Meshy's rig of v4 and correct in the game.
