#!/usr/bin/env python3
from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[2]

def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

def need(src,text,label):
    if text not in src:
        raise AssertionError(f"{label}: missing {text!r}")

model=json.loads(read("src/StarterGui/BloomUI.model.json"))
bloom=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau")
quests=read("src/StarterPlayer/StarterPlayerScripts/Controllers/QuestsController.luau")
activity=read("src/StarterPlayer/StarterPlayerScripts/Controllers/ActivityController.luau")
state=read("src/ServerScriptService/Services/UIStateService.luau")
editor=read("tools/bloom-ui-editor/app.js")
editor_html=read("tools/bloom-ui-editor/index.html")

def walk(node,path=""):
    name=node.get("Name") or node.get("ClassName")
    current=f"{path}/{name}" if path else name
    yield current,node
    for child in node.get("Children",[]) or []:
        yield from walk(child,current)

nodes=list(walk(model))
by_name={}
for path,node in nodes:
    by_name.setdefault(node.get("Name"),[]).append((path,node))

def one(name):
    items=by_name.get(name,[])
    return items[0] if items else (None,None)

prototype_path,prototype=one("QuestsPrototype")
if prototype is None:
    raise AssertionError("authored QuestsPrototype missing")
if prototype.get("Properties",{}).get("Visible") is not False:
    raise AssertionError("QuestsPrototype must stay hidden until runtime clone")

required=[
    "QuestsShell","Sidebar","Tab_Main","Tab_Activities","Tab_Trials","Tab_Completed",
    "SummaryBar","SummaryJourney","SummaryTrials","SummaryActivities","QuestList",
    "Components","QuestCardTemplate","IconBox","ProgressTrack","Fill","ProgressText",
    "RewardBox","RewardLabel","RewardIcon","RewardText","ActionButton","StatePill",
    "EmptyStateTemplate",
]
for name in required:
    if one(name)[1] is None:
        raise AssertionError(f"authored Quests V2 node missing: {name}")

if one("TrialsKit")[1] is not None:
    raise AssertionError("legacy TrialsKit returned")
for name in ("QuestTrackerHUD","Quest_1","Quest_2","Quest_3"):
    if one(name)[1] is None:
        raise AssertionError(f"right-side quest tracker node missing: {name}")

quest_card=one("QuestCardTemplate")[1]
if quest_card.get("Properties",{}).get("Visible") is not False:
    raise AssertionError("QuestCardTemplate must be an authored hidden template")

need(bloom,'local QuestsV2=require(script.Parent.QuestsController)',"Quests controller require")
need(bloom,'Trials="QuestsV2"',"stable Trials feature id routes to Quests V2")
need(bloom,'Trials="Quests"',"player-facing menu name")
need(bloom,'Trials="Tasks, progress & rewards"',"player-facing menu subtitle")
need(bloom,'elseif renderer=="QuestsV2" then',"Quests renderer branch")
need(bloom,'QuestsV2.Render(self,p,ui)',"Quests authored renderer call")
need(bloom,'math.min(980,math.max(760,safeW-48))',"Quests desktop width cap")
need(bloom,'math.min(560,math.max(500,safeH-64))',"Quests desktop height cap")
if 'elseif name=="Trials" then' in bloom:
    raise AssertionError("legacy generated Trials renderer returned")

need(quests,'local TABS={"Main","Activities","Trials","Completed"}',"Quests tab contract")
need(quests,'controller.Panel:FindFirstChild("QuestsPrototype")',"authored prototype binding")
need(quests,'cardTemplate(runtime):Clone()',"authored card cloning")
need(quests,'uiState.Trials',"authoritative trial snapshot")
need(quests,'controller.Activities and controller.Activities.Items',"live activity source")
need(quests,'elseif trial.CanStart then',"server-derived trial availability")
need(quests,'description=trial.StartHint or trial.ReasonText',"server-derived trial guidance")
need(quests,'controller:Send("Trial",trial.Id)',"server trial request")
need(quests,'state.Tab=="Completed"',"completed view")
need(quests,'controller:JourneyText(step)',"shared Journey objective source")
if 'Instance.new(' in quests:
    raise AssertionError("QuestsController must not construct Roblox GUI objects at runtime")

need(state,'CanStart=reason==nil',"server-authoritative CanStart")
need(state,'RewardText=(profile.Quests.Trials[id] and "Repeat • 5 Coins"', "server-derived reward copy")
need(state,'function S:QuestTracker(profile)',"authoritative quest tracker projection")
need(state,'self.X.HiveService:QuestStatus(profile,nextLevel)',"Hive Quest reuses authoritative rules")
need(state,'QuestTracker=self:QuestTracker(profile)',"quest tracker included in state snapshot")
need(bloom,'function UI:RenderQuestTracker()', "right-side quest tracker renderer")
need(bloom,'self.QuestRows[1]', "first tracker slot reserved for Hive Quest")
need(bloom,'"BLOOM QUEST"', "third tracker slot is recurring Bloom quest")
need(bloom,'hiveRow.Visible=not hideHive',"finished Hive quest leaves tracker")
need(bloom,'journeyRow.Visible=not journeyDone',"finished Journey leaves tracker")
need(bloom,'bloomReady and "ROLL READY"',"actionable Bloom state uses specific copy")
assert 'hive.Complete and "READY"' not in bloom, "generic READY completion copy returned"
need(bloom,'row.Position=UDim2.fromOffset(8,22+visibleCount*43)',"remaining quest cards compact upward")
need(activity,'function S:SetTracked(id)',"activity tracking")
need(activity,'prefix=tracked and "◆ TRACKED  •  " or ""',"tracked world checkpoint feedback")

need(editor,'trials:"QuestsPrototype"',"UI Studio Quests focus")
need(editor,'if(name==="QuestsPrototype")return scene==="trials";',"UI Studio Quests preview visibility")
if 'trials:"TrialsKit"' in editor:
    raise AssertionError("UI Studio still points Quests state at legacy TrialsKit")
need(editor_html,'data-ui-state="trials" title="Quests"',"UI Studio Quests state button")
need(editor_html,'<span>Quests</span>',"UI Studio Quests state label")

# Runtime max scale is 1.15. Keep the authored desktop menu inside the two alpha target viewports.
max_scale=1.15
panel_w=980*max_scale
panel_h=560*max_scale
for width,height in ((1366,768),(1280,720)):
    if panel_w>width or panel_h>height:
        raise AssertionError(f"Quests V2 max scaled panel exceeds {width}x{height}")

print("quests-v2 authored menu: PASS")
print("Covered: authored geometry, Main/Activities/Trials/Completed, server authority, tracking, UI Studio editing and desktop bounds.")
