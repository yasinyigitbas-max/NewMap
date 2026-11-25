#!/bin/bash
# STUDY CHECK (LOCKED): a hash of the lab's code as it is on disk now (sources, scenes, tools, tests, project, body),
# not docs. Committed or not. The hooks use it to know whether a gate result belongs to this code.
HERE=$(cd "$(dirname "$0")/.." && pwd)
LAB=$(cd "$HERE/.." && pwd)
cd "$LAB" || exit 1
{
	git ls-files -s -- native/src native/SConstruct scenes tools tests body project.godot layered.gdextension 2>/dev/null
	git diff HEAD -- native/src native/SConstruct scenes tools tests body project.godot layered.gdextension 2>/dev/null
	git ls-files --others --exclude-standard -- native/src scenes tools tests 2>/dev/null | while read -r f; do sha1sum "$f" 2>/dev/null; done
} | sha1sum | cut -c1-12
