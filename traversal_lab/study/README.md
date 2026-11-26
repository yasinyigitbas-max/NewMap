# The study gate

Yasin, 26 Nov 2026: "IT IS A RULE AND NECESSITY TO TAKE YOUR EVERY FUTURE STEP ACCORDING TO THE STUDY AND FOLLOW IT
LIKE THE HOLY BOOK", "TIGHTEN ALL THE CHECKS TO THE LEVEL OF THE STUDY ... MAKE GOD DAMN SURE EVERYTHING HAPPENS
WITHIN THE MARGINS OF THE STUDY", and "OTHER SESSION INVENTED NEW CHECKS TO MAKE ITS TESTS PASS IN THE MIDDLE OF THE
WORK AND EVERYTHING BROKE DOWN! MAKE SURE IT DOESNT HAPPEN THIS TIME!"

The study is `reports/Hybrid character traversal study.md`. This folder makes following it mechanical, so that it
does not rest on anyone's memory or good intentions.

## What is here

| File | What |
|---|---|
| `bars.json` | every pass bar of the audit. Each bar is a sentence of the study (or of its sourced notes), quoted word for word, and the numbers of the bar are the numbers printed in that sentence |
| `../tests/audit.gd` | the audit: measures the finished skeleton and the body in every built behaviour and holds each number to its bar. It has no pass bar of its own |
| `checks.lock` | the fingerprints of the two files above, and Yasin's words that locked them |
| `audit_result.json` | what the last audit run found, stamped with a fingerprint of the code and clips it ran on |
| `../../tools/traversal/check_study.py` | the tool behind it all (`verify`, `gate`, `lock`, `remind`, `tree`) |
| `../../.githooks/commit-msg` | git runs the gate on every commit that touches `traversal_lab/` |

## The rules

1. **Read the study before every step.** After a context compression your memory of it is gone; the session hook
   prints its Part 1 (sections 1 and 2) and Part 2 again, and the bars. Open the file itself before building or
   changing a stage.
2. **A bar is the study's own words.** `python3 -I tools/traversal/check_study.py verify` proves that every quote in
   `bars.json` is in the study word for word and that every bar's numbers are printed in its quote. A bar written
   from memory does not verify.
3. **Margins (Yasin's decision, 26 Nov 2026).** A range the study prints is the bar, exactly. Where its source notes
   give the measured spread, the bar is that spread. A single figure with no spread anywhere passes within 10 % of
   it. That 10 % is the only tolerance in the audit and it is his.
4. **The checks are locked.** `bars.json` and `tests/audit.gd` change only at Yasin's word. The gate refuses a commit
   that changes either unless its message carries `Checks-changed: <what and why>` and `Yasin: "<his words>"`, and
   it then writes `*** THE CHECKS CHANGED IN THIS COMMIT ***` into the message. To re-lock after such a change:
   `python3 -I tools/traversal/check_study.py lock --by=Yasin --words="<his words>"`.
   **If a line fails, fix the movement. Never the line.** If a line is measured wrongly, say so to Yasin, show him
   the case, and change it only when he says so.
5. **Every commit of movement code or clips quotes the study.** Its message carries one or more lines
   `Study: "<a sentence of the study the change follows, word for word>"` (the gate checks each against the file),
   or the line `Study: the study is silent on this, the number is mine`, which the gate accepts ONLY together
   with a line `Yasin: "<his words allowing that number>"`. A number the study does not give does not go in on a
   session's own say-so (26 Nov: a made-up standing foot-spacing was on its way in that way).
6. **No commit can claim more than the audit showed.** The audit must have been run on exactly the code being
   committed (the gate compares fingerprints), and the gate itself writes the result into the commit message:
   `Audit (written by the gate, not by hand): N of M study lines FAIL: ...`.
7. **A number in the code that the study does not give is marked `NOT in the study`** in a comment, and is said to
   Yasin as ours when it is reported.

## Running it

    godot --headless --path traversal_lab --import            # once in a fresh checkout
    godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/audit.gd
    python3 -I tools/traversal/check_study.py verify

The audit prints one line per bar: `PASS` or `FAIL`, the measured number, the study's range, what was measured.
`INFO` lines are not judged (the study gives no number, or the build cannot measure it). `NOT BUILT` lines belong to
stages that do not exist yet. Lines under "OUTSIDE THE STUDY" are things kept at Yasin's word that the study does
not cover; they are held to our own figures and do not count in the result.

In a fresh clone git does not know about the gate until this has been run once (the Claude session hook does it):

    git config core.hooksPath .githooks

## Yasin's decisions of 26 Nov 2026 (asked, and answered by him)

- **Margins:** "±10 % (Recommended)", as rule 3.
- **Steep slopes:** "Keep it, body in charge". He still climbs to 50 degrees, but the body sets the pace and the clips
  follow it; every steep-slope number stays marked as outside the study and the audit lists those lines apart.
- **AnimationTree:** "Rebuild as the study says (Recommended)". Stages 3 to 5 are rebuilt on an `AnimationTree` and
  the study's modifier order, one stage at a time, each judged by the locked audit before the next starts. The body
  (stages 0 and 1) and the baked clips are kept.

## What the audit defines itself (how things are measured, not how good they must be)

These are ours; they are named in `tests/audit.gd` where they are used. A foot is "down" when it is within 3 cm of
its standing height above its surface and its ball moves over the ground slower than 0.4 of the body's speed (or
0.5 m/s); it is "resting" when its ball and ankle both move slower than 0.10 m/s; it has "taken a step" when it left
the ground and came down at least 5 cm from where it left; a part has "started turning" when it is 3 degrees from
where it was; "steady speed" is 99 % of walking speed; a "flight phase" is at least one tick a stride with both feet
off the ground. Rise and fall and sway are measured at the hips, because the centre of mass needs body-part masses
the study could not source.

## Things found while writing the bars (26 Nov)

- **The old step-width bar was a misreading.** The earlier audit held walking feet to "0.08 to 0.10 m apart". The
  study's notes give those figures for ELDERLY walkers ("≈ 8 cm elderly women, ≈ 10 cm elderly men", about 40 % wider
  than young adults) and list young adults' step width as not found. The legs were angled in at the bake to hit that
  bar. There is no walking step-width bar now; the audit prints the measure for information.
- **The study disagrees with itself on the ankle.** Its limit table gives "13 up" for the ankle, while its own
  measurements have the ankle 26.8 degrees up in running and 31 going down stairs. The 13 is not judged until Yasin
  decides; the measured lines are.
- **Not measured yet:** wrist, forearm twist, fingers, the big toe's most, knee twist, hip twist, ankle side tilt.
  The audit says so in a line of its own instead of leaving them out silently.
