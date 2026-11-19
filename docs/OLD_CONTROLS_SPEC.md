# The old game's control scheme (to copy as it was: Yasin, 19 Nov: "get the old games control scheme too, copy it as it was, same goes for everywhere else on foot too")

Read from the old checkout (player/player.gd, player/interact.gd, ui/phone/phone_button.gd, vehicles/car_touch_ui.gd,
car.gd, player/passenger_cam.gd, ui/hud/hud.gd) on 19 Nov. Base canvas 1152x648, stretch canvas_items, keep aspect,
sensor landscape. Numbers below are at that canvas. Yasin's own changes on top: the bike = the car's scheme (blank left
side that only steers, two pedal plates at the lower right); the HUD's top right box = the arrow box (see the board).

## Nothing drawn for moving or looking
- On foot the WHOLE screen is an invisible touch surface: LEFT HALF moves, RIGHT HALF looks. No sticks, no look pad.
- On-screen controls in all: the green USE plate (Get in / Get out / Talk / Sit ...), the PHONE button, and while
  driving the GAS and BRAKE plates and a speed / fuel plate. No jump, sprint, horn, handbrake, pause or exit buttons
  (jump and crouch are double taps; pause = Esc / Android back).
- touch_scale is a setting that does nothing (reserved). No gamepad bindings existed.

## On foot
- Move finger: a touch going down with x < width/2 (not on the Use plate) is a FLOATING stick from where it landed:
  mv = ((pos - start) / 80).limit_length(1). Dead zone |mv| > 0.05. Analogue: speed = |mv| x spd; spd 7.0 run when
  |mv| > 0.9 (72 px), else 4.0 walk (crouch x0.45, wading x0.75, swimming 1.8 / 2.6). Walks where the camera looks
  (screen up = forward). Returns to 0 when the last move finger lifts. Multi-touch by index.
- Look: any other touch (not the Use plate): drag relative x 1.2 -> add_look: yaw -= dx*0.25 deg, pitch clamp(-80, +75)
  -= dy*0.25 deg (so 0.3 deg/px at sensitivity 1); x cam_sens (0.2-3.0, default 1), invert_y (default off). Two look
  fingers add up.
- Double tap (per half): second press within 0.32 s and 110 px. Left half = crouch toggle (capsule 1.75 -> 1.1, eye
  x0.62, head-room check to stand). Right half = jump (4.3 m/s, coyote 0.15 s; not seated / swimming).
- Seated: stick > 0.6 (keys > 0.5) stands up. The old game was FIRST PERSON only (our CityPlayer is third person: keep
  the controls, the camera stays ours).
- Keys: WASD / arrows (0.6 walk, Shift 1.0 run), Space jump, C / Ctrl crouch, mouse drag looks, E use, 1-9 pick a Use
  option, P phone, Esc phone / pause, R radio.

## The Use plate (context button)
- Under the minimap, same width: minimap x 952-1128 y 24-200 (176x176, 24 margin + safe area); USE plate x 952-1128,
  y 208-284 (176x76). Look "green" (#1f9d63, white 1 px keyline inset 2, corner 5; pressed #187d4f), margins
  16/8/12/8, icon 32 px + English label 24 pt bold UPPERCASE + Turkish 17 pt 85 % white.
- Shown only in a car ("Get out") or near something usable: rescored every 0.1 s, reach 1.6 m horizontal 1.2 m
  vertical, score = priority - distance + 1.5 facing; hidden under menus / phone / pause / cutscenes; vibrate 200 ms on a
  new target; a yellow ring marks the target (rgba 1, .85, .35, .8; radii .34-.42; pulse 1 + .06 sin 5t).
- Tap / E: vibrate 15 ms, a column of option plates under it (x 952, 176x56, 72 with the helper, gap 8, from y 292 to
  the phone button - 8), ending with Cancel; shrink to fit (min 30 px; drop the helper under 50, the icon under 36);
  black plates, 22 px icons, 17 pt labels; fly out of the Use plate (scale .62 -> 1, fade, 0.30 s each, staggered
  from the middle, all in by 0.5 s, a tick each 2 semitones up at -15 dB). Its rectangle is excluded from move / look.

## Phone button
- Bottom right 76x76, 24 px margins: x 1052-1128, y 548-624. Plate "plate", phone icon 36 px #f4f5f3. Tap / P toggles
  the phone. Shown with the HUD (on foot and in a car).

## Car
- Get in / out: the Use plate (ui.drive / ui.get_out).
- Steer: the same invisible left-half stick: steer = -mv.x beyond 0.08 (keys first); toward
  s * 0.55 * clamp(1 - kmh/140, .35, 1) at 2.5 /s.
- GAS: plate_go (black, green keyline), 104x144, "GAS" 24 pt bold at the bottom (margin 14) over "GAZ" 17 pt dim; hold =
  throttle 1. BRAKE: plate, 120x96, "BRAKE" / "FREN"; hold = brake; after a full stop (< .05 m/s for .25 s) or rolling
  back = reverse at -0.6. Placed above the phone button, right edges aligned, 8 px gaps: GAS x 1024-1128 y 396-540,
  BRAKE x 896-1016 y 444-540. Pressed look raised_hi. TouchScreenButtons (multi-touch, passby).
- Speed / fuel plate bottom left x 24-232, y 512-624: km/h 64 pt bold + "km/h" caps; fuel icon 20 px, 6 px bar, "N L";
  red under 15 %.
- No horn button (H), no handbrake (Space = brake). Camera: right-half free look; after 0.15 s idle springs back to the
  car's forward + steer x 0.35 rad.
- Keys: W / Up gas, S / Down back (brakes above 1 m/s), A D steer, Space brake, E get out, H horn, R radio.

## Passenger (taxi, bus)
- Look only: drag, yaw -= dx*0.006 rad clamp ±110 deg, pitch -= dy*0.006 clamp -35..+25 deg (rest -4); eases back
  after 2.5 s idle.

## What shows when
| State | Shown |
|---|---|
| On foot | the top-right box, money / clock box, Phone button; Use plate only near a target |
| Driving / riding | the same + GAS, BRAKE, speed (and fuel in a car); Use plate shows Get out |
| Menu, phone, pause, cutscene | HUD and Use plate hidden |
