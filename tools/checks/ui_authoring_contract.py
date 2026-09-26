#!/usr/bin/env python3
from pathlib import Path
import json,re

ROOT=Path(__file__).resolve().parents[2]

def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

def need(src,text,label):
    if text not in src:
        raise AssertionError(f"{label}: missing {text!r}")

bloom=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau")
inventory=read("src/StarterPlayer/StarterPlayerScripts/Controllers/InventoryV2Controller.luau")
quests=read("src/StarterPlayer/StarterPlayerScripts/Controllers/QuestsController.luau")
boost=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BoostHUDController.luau")
tutorial=read("src/StarterPlayer/StarterPlayerScripts/Controllers/TutorialGuideController.luau")
activity=read("src/StarterPlayer/StarterPlayerScripts/Controllers/ActivityController.luau")
loading=read("src/ReplicatedFirst/LoadingScreen.client.luau")
editor=read("tools/bloom-ui-editor/app.js")
editor_html=read("tools/bloom-ui-editor/index.html")
roflow=read("tools/roflow/src-tauri/src/lib.rs")
model=json.loads(read("src/StarterGui/BloomUI.model.json"))
loading_model=json.loads(read("src/ReplicatedFirst/BloomLoadingTemplate.model.json"))

screen_classes=[
    "ScreenGui","Frame","ScrollingFrame","TextLabel","TextButton","TextBox",
    "ImageLabel","ImageButton","UICorner","UIStroke","UIPadding","UIScale",
    "UIListLayout","UIGridLayout",
]
pattern=re.compile(r'Instance\.new\("('+"|".join(map(re.escape,screen_classes))+r')"\)')
for name,src in [
    ("BloomUI",bloom),
    ("InventoryV2Controller",inventory),
    ("QuestsController",quests),
    ("BoostHUDController",boost),
    ("LoadingScreen",loading),
]:
    hits=pattern.findall(src)
    assert not hits, f"{name} creates ScreenGui UI at runtime: {hits}"

# Tutorial world guidance may author BillboardGui/TextLabel in Workspace, but all
# on-screen tutorial overlays must be real SafeRoot objects.
assert 'Instance.new("Frame")' not in tutorial
assert 'Instance.new("UIScale")' not in tutorial
need(tutorial,'ui.SafeRoot:FindFirstChild("TutorialSpotlight")',"tutorial spotlight authored binding")
need(tutorial,'ui.SafeRoot:FindFirstChild("TutorialCallout")',"tutorial callout authored binding")
need(tutorial,'ui.SafeRoot:FindFirstChild("TutorialScreenArrow")',"tutorial arrow authored binding")
need(tutorial,'prototypes:FindFirstChild("TutorialWorldLabelTemplate",true)',"tutorial world label authored prototype")
assert 'Instance.new("TextLabel")' not in tutorial, "tutorial creates visual TextLabel at runtime instead of cloning authored prototype"
need(activity,'prototypes:FindFirstChild("ActivityCheckpointLabelTemplate",true)',"activity world label authored prototype")
assert 'Instance.new("TextLabel")' not in activity, "activity creates visual TextLabel at runtime instead of cloning authored prototype"

def walk(node):
    yield node
    for child in node.get("Children",[]) or []:
        yield from walk(child)

nodes={n.get("Name"):n for n in walk(model)}
for required in [
    "TutorialSpotlight","TutorialCallout","TutorialScreenArrow",
    "ActionHitboxTemplate","OverlayHitboxTemplate","SearchBoxTemplate","EmptyStateTemplate",
    "QuestsPrototype","QuestCardTemplate","QuestList","Tab_Main","Tab_Activities","Tab_Trials","Tab_Completed",
    "WorkshopTemplate","WorkshopBody","TreePanel","TreeCanvas","PanMap","NodeTooltip","WorkshopCurrencyBar",
    "WorkshopPoints","WorkshopCoins","WorkshopPetalDust","WorkshopAncientNectar",
    "StateKits","HoverScale","TutorialCompleteScale","WorkshopZoomScale",
    "WorldUIPrototypes","TutorialWorldBillboard","ActivityCheckpointBillboard",
    "TutorialWorldLabelTemplate","ActivityCheckpointLabelTemplate",
]:
    assert required in nodes, f"authored BloomUI node missing: {required}"

for kit in ["SettingsKit","SeasonKit","ReplayKit","CardsKit"]:
    assert kit in nodes, f"authored UI state kit missing: {kit}"
for retired in ["TrialsKit","PlantKit","FieldGuideKit","MapKit","Dock_FieldGuide","Dock_Map"]:
    assert retired not in nodes, f"retired alpha menu returned: {retired}"

need(bloom,'function UI:MenuTemplate(name)',"dynamic menu authored template resolver")
need(bloom,'self.StateKits=self.Panel:FindFirstChild("StateKits")',"state kit runtime binding")
need(inventory,'componentTemplate(button,"ActionHitboxTemplate"):Clone()',"inventory authored hitbox clone")
need(inventory,'componentTemplate(searchBar,"SearchBoxTemplate"):Clone()',"inventory authored search clone")
need(quests,'cardTemplate(runtime):Clone()',"Quests authored card clone")
need(quests,'EmptyStateTemplate',"Quests authored empty-state clone")
need(bloom,'local function workshopStructure(shell)',"Workshop authored structure binding")
need(bloom,'local currencyBar=structure.CurrencyBar',"Workshop authored currency binding")
assert 'WaitForChild("NodeTooltip")' not in bloom, "Workshop must not wait forever for a stale authored tooltip"
need(boost,'badge:FindFirstChild("HoverScale")',"boost authored hover scale")

assert loading_model.get("ClassName")=="ScreenGui"
assert loading_model.get("Name")=="BloomLoadingTemplate"
loading_nodes={n.get("Name"):n for n in walk(loading_model)}
for required in ["Background","Card","ProgressTrack","ProgressFill","Status","Detail","ResponsiveScale"]:
    assert required in loading_nodes, f"authored loading node missing: {required}"
need(loading,'RF:WaitForChild("BloomLoadingTemplate",10)',"loading authored model binding")
assert 'Instance.new("ScreenGui")' not in loading

states=["gameplay","inventory_v2","workshop","trials","settings","season","replay","cards","reward","toast","tutorial","boosts","world_ui","loading"]
for state in states:
    assert f'data-ui-state="{state}"' in editor_html, f"UI STATE button missing: {state}"
for retired in ("fieldguide","map","plant"):
    assert f'data-ui-state="{retired}"' not in editor_html, f"retired UI STATE still exposed: {retired}"
need(editor,'const closing=state.activeUiState===scene',"UI STATE toggle-off behavior")
need(editor,'state.activeUiState=null',"empty workspace state")
need(editor,'if(!state.activeUiState){',"empty Explorer state")
need(editor,'world_ui:"World UI"', "World UI state title")
need(editor,'world_ui:"WorldUIPrototypes"', "World UI authored focus")
assert "MOCK PREVIEW · NOT RUNTIME" not in editor
assert '<div class="preview-menu-generic">' not in editor
need(editor,'LOADING_TARGET="src/ReplicatedFirst/BloomLoadingTemplate.model.json"',"loading model editor target")
need(roflow,'const LOADING_MODEL_PATH: &str = "src/ReplicatedFirst/BloomLoadingTemplate.model.json";',"RoFlow loading model path")
need(roflow,'fn ui_model_path(requested: Option<String>)',"RoFlow model path whitelist")

print("UI authoring contract: PASS")
print("Permanent screen UI is authored in Roblox GUI models; runtime code only binds/clones authored templates.")
