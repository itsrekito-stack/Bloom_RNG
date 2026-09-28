#!/usr/bin/env python3
from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src: raise AssertionError(f"{label}: missing {text!r}")

model=json.loads(read("src/StarterGui/BloomUI.model.json"))
bloom=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau")
quests=read("src/StarterPlayer/StarterPlayerScripts/Controllers/QuestsController.luau")
activity=read("src/StarterPlayer/StarterPlayerScripts/Controllers/ActivityController.luau")
state=read("src/ServerScriptService/Services/UIStateService.luau")
editor=read("tools/bloom-ui-editor/app.js")
editor_html=read("tools/bloom-ui-editor/index.html")

def walk(node):
    yield node
    for child in node.get("Children",[]) or []: yield from walk(child)
nodes=list(walk(model))
by_name={}
for node in nodes: by_name.setdefault(node.get("Name"),[]).append(node)
def one(name): return (by_name.get(name) or [None])[0]

required=["QuestsPrototype","QuestsShell","Sidebar","Tab_Main","Tab_Activities","Tab_Completed",
          "SummaryBar","SummaryJourney","SummaryQuests","SummaryActivities","QuestList",
          "Components","QuestCardTemplate","ProgressTrack","ProgressText","RewardBox","ActionButton","StatePill","EmptyStateTemplate",
          "Dock_Quests"]
for name in required:
    if one(name) is None: raise AssertionError(f"authored Quests node missing: {name}")
for retired in ("Tab_Trials","SummaryTrials","Dock_Trials","TrialsKit"):
    if one(retired) is not None: raise AssertionError(f"retired Trial UI returned: {retired}")

need(bloom,'local QuestConfig=require(RS.Config.QuestConfig)',"shared quest copy")
need(bloom,'Quests="QuestsV2"',"Quests menu route")
need(bloom,'for _,name in ipairs({"SeedSatchel","Garden","Hive","Index","Workshop","Quests","Settings"}) do',"Quests dock binding")
need(bloom,'FeatureUnlocks.Quests',"Quests unlock")
need(bloom,'self:Open("Quests")',"tracker opens Quests")
need(quests,'local TABS={"Main","Activities","Completed"}',"three-tab quest menu")
need(quests,'uiState.Quests or{Items={}}',"authoritative quest snapshot")
need(quests,'controller:Send("ClaimQuest",item.Id)',"claim button")
need(quests,'controller.Activities and controller.Activities.Items',"activity tab")
need(activity,'function S:SetTracked(id)',"activity tracking")
assert 'Trial' not in quests and 'Trials' not in quests, "QuestsController still contains Trial behavior"
assert 'Instance.new(' not in quests, "QuestsController must clone authored GUI only"
need(state,'Quests=self.X.QuestService:State(profile)',"server quest projection")

need(editor,'quests:"QuestsPrototype"',"UI Studio Quests focus")
need(editor,'scene==="quests"', "UI Studio Quests visibility")
need(editor_html,'data-ui-state="quests" title="Quests"',"UI Studio Quests state")

print("quests-v2 authored menu: PASS")
print("Authored Quests/Activities/Completed UI, claims, tracker, UI Studio state and complete Trial removal verified.")
