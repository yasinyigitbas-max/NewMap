#!/bin/bash
# STUDY CHECK gate (LOCKED). The only judge of lab B's motion. Run from anywhere:
#   bash lab/traversal_layered/study_check/check.sh quick   # ~1 min: lock, build, mutation tests, 5 min of free play
#   bash lab/traversal_layered/study_check/check.sh full    # ~8 min: the study's acceptance run (9.2, 9.3), also run by
#                                                          # the push hook before anything reaches lab/layered
# Prints "GATE RESULT PASS" or "GATE RESULT FAIL" (and why) as its last line; exit 0 only on PASS.
# Writes the report to study_check/results/<mode>_<code hash>.txt (not committed; the hooks read it).
# Environment: GODOT (Godot 4.7.2 binary), GODOT_CPP (godot-cpp checkout, default /opt/lab/godot-cpp).
set -u
MODE=${1:-quick}
HERE=$(cd "$(dirname "$0")" && pwd)
LAB=$(cd "$HERE/.." && pwd)
ROOT=$(cd "$LAB" && git rev-parse --show-toplevel)
RES=$HERE/results
mkdir -p "$RES"
REPORT=$(mktemp)
say() { echo "$*" | tee -a "$REPORT"; }
fail_now() { say "GATE ERROR: $*"; finish FAIL; }
finish() {
	local r=$1
	say "GATE RESULT $r ($MODE, code $CODE_HASH)"
	cp "$REPORT" "$RES/${MODE}_${CODE_HASH}.txt"
	cp "$REPORT" "$RES/last_${MODE}.txt"
	echo "$CODE_HASH" > "$RES/last_hash"
	rm -f "$REPORT"
	[ "$r" = PASS ] && exit 0 || exit 1
}
CODE_HASH=$(bash "$HERE/hooks/code_hash.sh")
say "STUDY CHECK gate, mode $MODE, $(date -u '+%Y-%m-%d %H:%M UTC'), code $CODE_HASH"

# 1. the lock: study_check/, the hooks' settings and STUDY.md must equal origin/lab/checker (the overseer's branch)
LOCKED="lab/traversal_layered/study_check lab/traversal_layered/STUDY.md lab/traversal_layered/CLAUDE.md .claude/settings.json"
(cd "$ROOT" && git fetch -q origin lab/checker 2>/dev/null) || say "  (could not fetch origin/lab/checker; comparing with the local copy)"
if (cd "$ROOT" && git rev-parse -q --verify origin/lab/checker >/dev/null); then
	CHANGED=$(cd "$ROOT" && { git diff --name-only origin/lab/checker -- $LOCKED; git ls-files --others --exclude-standard -- $LOCKED; } | grep -v '^lab/traversal_layered/study_check/results/' | sort -u)
	if [ -n "$CHANGED" ]; then
		say "LOCK BROKEN: these locked files differ from origin/lab/checker (only Yasin or the overseer session may change them):"
		echo "$CHANGED" | sed 's/^/    /' | tee -a "$REPORT"
		finish FAIL
	fi
	say "  lock: study_check, STUDY.md, CLAUDE.md and .claude/settings.json equal origin/lab/checker"
else
	fail_now "origin/lab/checker not found: the lock can't be verified"
fi
SCOPE=$(tr -d ' \r\n' < "$HERE/SCOPE")
say "  scope: $SCOPE (set by Yasin / the overseer in study_check/SCOPE)"

# 2. Godot, and the two native libraries built from the sources that are here now
find_godot() {
	[ -n "${GODOT:-}" ] && [ -x "$GODOT" ] && { echo "$GODOT"; return; }
	for c in godot godot4 Godot_v4.7.2-stable_linux.x86_64; do command -v "$c" >/dev/null 2>&1 && { command -v "$c"; return; }; done
	for c in /opt/lab/godot/Godot_v4.7.2-stable_linux.x86_64 /opt/lab/Godot_v4.7.2-stable_linux.x86_64 /opt/godot/godot /usr/local/bin/godot \
		"/c/Users/yasin/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"; do
		[ -x "$c" ] && { echo "$c"; return; }
	done
	ls /opt/lab/*/Godot_v4.7.2* /opt/lab/Godot_v4.7.2* 2>/dev/null | head -1
}
G=$(find_godot)
[ -n "$G" ] || fail_now "no Godot 4.7.2 binary (set GODOT)"
"$G" --version 2>/dev/null | grep -q '^4\.7\.2' || say "  WARNING: $("$G" --version 2>/dev/null) is not Godot 4.7.2"
case "$(uname -s)" in
	Linux*)
		GC=${GODOT_CPP:-/opt/lab/godot-cpp}
		[ -d "$GC" ] || fail_now "godot-cpp not found at $GC (set GODOT_CPP)"
		PY=$(command -v python3 || command -v python)
		(cd "$HERE/native" && "$PY" -m SCons platform=linux target=template_debug godot_cpp="$GC" -j4 -Q >/tmp/study_check_build.log 2>&1) \
			|| { tail -20 /tmp/study_check_build.log; fail_now "the checker library did not build"; }
		(cd "$LAB/native" && "$PY" -m SCons platform=linux target=template_debug godot_cpp="$GC" -j4 -Q >/tmp/lab_build.log 2>&1) \
			|| { tail -20 /tmp/lab_build.log | tee -a "$REPORT"; say "LAB BUILD FAILED"; finish FAIL; }
		say "  built: the checker and the lab's library (linux), from the sources here" ;;
	*) say "  windows: using the committed DLLs (the lab's own DLL must be rebuilt by the lab after every change)" ;;
esac
EL=$LAB/.godot/extension_list.cfg
if [ ! -d "$LAB/.godot" ]; then (cd "$LAB" && timeout 900 "$G" --headless --path . --import >/dev/null 2>&1); fi
mkdir -p "$LAB/.godot"
grep -qs 'res://layered.gdextension' "$EL" || echo 'res://layered.gdextension' >> "$EL"
grep -qs 'res://study_check/study_check.gdextension' "$EL" || echo 'res://study_check/study_check.gdextension' >> "$EL"

run() { # fps, script, args...
	local fps=$1 script=$2; shift 2
	(cd "$LAB" && timeout 3000 "$G" --headless --path . --fixed-fps "$fps" -s "res://study_check/tests/$script" -- "$@" 2>&1)
}
SEED=$(( 16#${CODE_HASH:0:6} % 100000 + 1 ))
ALL_OK=1

# 3. mutation tests first (9.2, 9.6): if they fail, nothing else counts
for f in 60 30; do
	OUT=$(run $f mutation.gd seed=$((SEED + f)))
	echo "$OUT" | grep -E 'MUTATION RESULT|FAIL  ' | head -20 | sed 's/^/  /' | tee -a "$REPORT"
	echo "$OUT" | grep -q 'MUTATION RESULT PASS' || { say "MUTATION TESTS FAILED at $f fps: no other result counts (9.6)"; finish FAIL; }
done
if [ "$MODE" = full ]; then
	for f in 20 144; do
		OUT=$(run $f mutation.gd seed=$((SEED + f)))
		echo "$OUT" | grep -E 'MUTATION RESULT|FAIL  ' | head -20 | sed 's/^/  /' | tee -a "$REPORT"
		echo "$OUT" | grep -q 'MUTATION RESULT PASS' || { say "MUTATION TESTS FAILED at $f fps"; finish FAIL; }
	done
fi

# 4. free play (9.3)
fuzz() { # label fps seconds seed hitches [snapfile]
	local label=$1 fps=$2 secs=$3 seed=$4 hitch=$5 snap=${6:-}
	local log="$RES/fuzz_${label}.txt"
	local OUT
	OUT=$(run "$fps" fuzz.gd seconds="$secs" seed="$seed" hitches="$hitch" scope="$SCOPE" out="$log" ${snap:+snap="$snap"})
	say "  -- free play: $label ($secs s simulated at $fps fps, seed $seed, hitches $hitch)"
	echo "$OUT" | grep -E '^FUZZ|^  ' | grep -v 'FUZZ RESULT' | sed 's/^/  /' | tee -a "$REPORT"
	if echo "$OUT" | grep -q 'FUZZ RESULT PASS'; then say "     PASS"; else say "     FAIL (first violations: study_check/results/fuzz_${label}.txt)"; ALL_OK=0; fi
}
if [ "$MODE" = full ]; then
	fuzz main60 60 1800 "$SEED" 0
	fuzz hitch60 60 600 $((SEED + 1)) 1
	fuzz fps30 30 600 $((SEED + 2)) 0
	fuzz fps20 20 600 $((SEED + 3)) 0
	fuzz fps144 144 300 $((SEED + 4)) 0
	# frame-rate agreement (9.3): the same input at 60 / 30 / 20 / 144 fps gives the same pose within 1 deg / 1 cm
	for f in 60 30 20 144; do run $f fuzz.gd seconds=120 seed=$((SEED + 9)) scope="$SCOPE" snap="$RES/snap_$f.json" >/dev/null; done
	for f in 30 20 144; do
		OUT=$(cd "$LAB" && "$G" --headless --path . -s res://study_check/tests/rate_compare.gd -- a="$RES/snap_60.json" b="$RES/snap_$f.json" 2>&1)
		echo "$OUT" | grep -E '^RATE' | sed 's/^/  /' | tee -a "$REPORT"
		echo "$OUT" | grep -q 'RATE RESULT PASS' || ALL_OK=0
	done
else
	fuzz quick60 60 300 "$SEED" 0
fi
say "  what this gate can't see: how the motion looks (9.4: frame strips against reference footage, then Yasin plays it),"
say "  skin and mesh problems (the waist pinching), feet crossing under the body, wet ground, the obstacles outside the scope."
[ $ALL_OK = 1 ] && finish PASS || finish FAIL
