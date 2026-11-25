#!/bin/bash
# STUDY CHECK (LOCKED): Stop hook. If the lab's code changed since the last gate run, the session may not stop (end
# its turn) until it has run the gate on this code. Exit 2 = keep working, with stderr as the instruction.
HERE=$(cd "$(dirname "$0")/.." && pwd)
H=$(bash "$HERE/hooks/code_hash.sh")
if [ -f "$HERE/results/quick_${H}.txt" ] || [ -f "$HERE/results/full_${H}.txt" ]; then exit 0; fi
if [ -f "$HERE/results/last_hash" ] && [ "$(cat "$HERE/results/last_hash")" = "$H" ]; then exit 0; fi
# the code is exactly what is on Yasin's branch (which passed the push gate, or predates it): nothing new to judge
LAB=$(cd "$HERE/.." && pwd)
CODE="native/src native/SConstruct scenes tools tests body project.godot layered.gdextension"
if (cd "$LAB" && git rev-parse -q --verify origin/lab/layered >/dev/null && git diff --quiet origin/lab/layered -- $CODE 	&& [ -z "$(git ls-files --others --exclude-standard -- $CODE)" ]); then exit 0; fi
echo "STOP BLOCKED by the study gate: your code changed (hash $H) and the gate has not judged it. Run
  bash lab/traversal_layered/study_check/check.sh quick
and put its summary (the GATE RESULT line and the rules that failed) in your report. A FAIL is fine to report; an
unjudged change is not. (study_check/RULES.md)" >&2
exit 2
