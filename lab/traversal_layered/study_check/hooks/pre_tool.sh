#!/bin/bash
# STUDY CHECK (LOCKED): PreToolUse hook. Exit 2 blocks the tool call and shows stderr to the session.
#  - edits to locked files are blocked;
#  - shell commands that would change locked files are blocked;
#  - a git push that can reach lab/layered runs the full gate first and is blocked unless it passes
#    (pushes to lab/layered-wip are always allowed).
HERE=$(cd "$(dirname "$0")/.." && pwd)
IN=$(cat)
PY=""
for c in python3 python py; do
	if command -v "$c" >/dev/null 2>&1 && "$c" -c "import json" >/dev/null 2>&1; then PY=$c; break; fi
done
field() {
	if [ -n "$PY" ]; then
		printf '%s' "$IN" | "$PY" -c "import sys, json
d = json.load(sys.stdin); t = d.get('tool_input', {})
print(d.get('tool_name', '') if sys.argv[1] == 'tool' else (t.get('command') or t.get('file_path') or t.get('notebook_path') or ''))" "$1" 2>/dev/null | tr -d '\r'
	elif [ "$1" = tool ]; then
		printf '%s' "$IN" | sed -n 's/.*"tool_name" *: *"\([^"]*\)".*/\1/p'
	else
		printf '%s' "$IN" | sed -n 's/.*"\(command\|file_path\|notebook_path\)" *: *"\(\([^"\\]\|\\.\)*\)".*/\2/p'
	fi
}
TOOL=$(field tool)
ARG=$(field arg)
# locked: the judge, the study, the lab's CLAUDE.md, the hooks' settings
PATH_RE='(study_check([^A-Za-z0-9_]|$)|traversal_layered/STUDY\.md$|traversal_layered/CLAUDE\.md$|\.claude/settings(\.local)?\.json$)'
CMD_RE='(study_check([^A-Za-z0-9_]|$)|STUDY\.md|traversal_layered/CLAUDE\.md|\.claude/settings)'
WRITE_RE='((sed|perl) +-i|(^|[;&|( ])(rm|mv|cp|tee|truncate|chmod|ln|touch|install|rsync|dd) |git +(checkout|restore|rm|mv|reset|stash|apply|am|cherry-pick|revert|update-index|update-ref) )'
case "$TOOL" in
	Edit|Write|MultiEdit|NotebookEdit)
		P=$(printf '%s' "$ARG" | tr '\\' '/')
		if printf '%s' "$P" | grep -Eq "$PATH_RE"; then
			echo "BLOCKED: $P is locked (study_check/RULES.md). Only Yasin or the overseer session changes the judge, the study and the hooks. Write your objection in STATUS.md." >&2
			exit 2
		fi ;;
	Bash)
		C=$ARG
		if printf '%s' "$C" | grep -Eq "$WRITE_RE[^;&|]*$CMD_RE" || printf '%s' "$C" | grep -Eq ">>? *[^ ;&|]*$CMD_RE"; then
			echo "BLOCKED: this command would change a locked file (study_check/, STUDY.md, CLAUDE.md, .claude/settings.json). See study_check/RULES.md." >&2
			exit 2
		fi
		if printf '%s' "$C" | grep -Eq 'git( +-C +[^ ]+)? +push'; then
			if printf '%s' "$C" | grep -q 'lab/layered-wip' && ! printf '%s' "$C" | grep -Eq '(:| )lab/layered( |$)|--all|--mirror'; then
				exit 0
			fi
			echo "push gate: running study_check/check.sh full before this push (about 8 minutes)..." >&2
			OUT=$(bash "$HERE/check.sh" full 2>&1)
			if ! printf '%s' "$OUT" | tail -1 | grep -q 'GATE RESULT PASS'; then
				echo "BLOCKED: the study gate failed, so this can't reach lab/layered. Push work in progress to lab/layered-wip instead (git push origin HEAD:lab/layered-wip). Gate summary:" >&2
				printf '%s\n' "$OUT" | tail -60 >&2
				exit 2
			fi
		fi ;;
esac
exit 0
