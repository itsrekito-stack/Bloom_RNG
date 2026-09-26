#!/usr/bin/env python3
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[2]
SRC=ROOT/"src"

SCREEN_CLASSES=[
    "ScreenGui","Frame","ScrollingFrame","TextLabel","TextButton","TextBox",
    "ImageLabel","ImageButton","UICorner","UIStroke","UIPadding","UIScale",
    "UIListLayout","UIGridLayout","UIGradient","UIAspectRatioConstraint",
]
pattern=re.compile(r'Instance\.new\("('+"|".join(map(re.escape,SCREEN_CLASSES))+r')"\)')

hits=[]
for path in SRC.rglob("*.luau"):
    rel=path.relative_to(ROOT).as_posix()
    if not any(part in rel for part in ("StarterPlayer/","ReplicatedFirst/","StarterGui/")):
        continue
    text=path.read_text(encoding="utf-8")
    for m in pattern.finditer(text):
        line=text.count("\n",0,m.start())+1
        hits.append((rel,line,m.group(1)))

if hits:
    detail="\n".join(f"{p}:{line}: Instance.new({cls})" for p,line,cls in hits)
    raise AssertionError("Permanent screen UI must be authored in Roblox GUI models, not created in scripts:\n"+detail)

activity=(ROOT/"src/StarterPlayer/StarterPlayerScripts/Controllers/ActivityController.luau").read_text(encoding="utf-8")
tutorial=(ROOT/"src/StarterPlayer/StarterPlayerScripts/Controllers/TutorialGuideController.luau").read_text(encoding="utf-8")

# Runtime BillboardGui shells are allowed only because their Adornee/position exists dynamically in Workspace.
# Their visible contents must still come from editable ScreenGui prototypes.
assert 'Instance.new("BillboardGui")' in activity
assert 'ActivityCheckpointLabelTemplate' in activity
assert 'Instance.new("TextLabel")' not in activity
assert 'Instance.new("BillboardGui")' in tutorial
assert 'TutorialWorldLabelTemplate' in tutorial
assert 'Instance.new("TextLabel")' not in tutorial

print("runtime ScreenGui creation scan: PASS")
print("All permanent screen UI is authored; only dynamic world-space BillboardGui shells remain runtime-created.")
