#!/usr/bin/env python3
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src: raise AssertionError(f"{label}: missing {text!r}")

model=json.loads(read("src/StarterGui/BloomUI.model.json"))
controller=read("src/StarterPlayer/StarterPlayerScripts/Controllers/GardenEditorController.luau")
bloom=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau")
garden=read("src/ServerScriptService/Services/GardenPlotService.luau")
player=read("src/ServerScriptService/Services/PlayerService.luau")
remote=read("src/ServerScriptService/Services/RemoteService.luau")
state=read("src/ServerScriptService/Services/UIStateService.luau")
editor=read("tools/bloom-ui-editor/app.js")
editor_html=read("tools/bloom-ui-editor/index.html")

def find(node,name):
    if node.get("Name")==name: return node
    for child in node.get("Children",[]) or []:
        hit=find(child,name)
        if hit: return hit
    return None

kit=find(model,"GardenKit")
if not kit: raise AssertionError("authored GardenKit missing")
for name in ["GardenShell","FlowerPanel","FlowerList","FlowerCardTemplate","UsedBadge","LayoutPanel","SlotRing","Slot7","GhostBadge","SynergyPanel","SynergyName","SynergyEffect","GhostHint","RemoveButton"]:
    if not find(kit,name): raise AssertionError(f"GardenKit authored node missing: {name}")
for i in range(1,8):
    slot=find(kit,f"Slot{i}")
    if not slot or slot.get("ClassName")!="ImageButton":
        raise AssertionError(f"Garden Slot{i} must be authored ImageButton")
    for child in ["Icon","Name","Level","Lock"]:
        if not find(slot,child): raise AssertionError(f"Garden Slot{i} missing {child}")

need(controller,'ui.StateKits and ui.StateKits:FindFirstChild("GardenKit")'.replace("ui.","controller."),"GardenKit clone source")
need(controller,'runtime.Name="GardenRuntime"',"runtime clone naming")
need(controller,'for i=1,7 do',"exact seven-slot renderer")
need(controller,'controller:Send("GardenEdit",i,selected)',"Flower-to-slot request")
need(controller,'controller:Send("GardenEdit",slot,"")',"remove request")
need(controller,'gardenState.Hint and gardenState.Hint.FlowerId',"ghost hint consumes only FlowerId")
if "gardenState.Hint.Recipe" in controller or "gardenState.Hint.RecipeId" in controller or "gardenState.Hint.Id" in controller:
    raise AssertionError("Garden ghost hint must not reveal a hidden recipe id")
need(controller,'CURRENT SYNERGY  •  ',"active Synergy presentation")
need(controller,'tostring(entry.Odds or "1/—")',"real Flower odds presentation")
if '"1/N "' in controller: raise AssertionError("Garden must not prepend fake 1/N text to real Flower odds")
need(controller,'Lv. ',"Flower level presentation")
need(controller,'local ghost=i==7 and not open',"seventh slot ghost state")
need(controller,'name.Text=not open and (ghost and "GHOST SLOT" or "LOCKED")',"seventh slot ghost copy")
need(controller,'icon.Image=ghost and Icons.Get("System","Flower")',"seventh slot ghost icon")
need(controller,'ghost and "Reach Hive Level 7 to unlock the final Garden slot."', "seventh slot unlock guidance")
need(garden,'local ghost=i==C.MaxFlowerSlots and not unlocked',"physical final-slot ghost state")
need(garden,'unlocked and Enum.Material.Ground or (ghost and Enum.Material.ForceField or Enum.Material.Slate)',"physical ghost material")
need(garden,'pad:SetAttribute("GhostSlot",ghost)',"physical ghost slot attribute")

need(garden,'EditorSessions={}',"server editor session state")
need(garden,'function S:OpenEditor(player)',"Garden menu editor session entry")
need(garden,'self.EditorSessions[player]=workspace:GetServerTimeNow()+600',"Garden menu opens bounded editor session")
if '"Open Garden"' in garden or 'self.X:Send(player,"Open","Garden")' in garden:
    raise AssertionError("world Flower slots must not expose Open Garden prompts; use the authored Garden menu")
need(garden,'function S:GardenEdit(player,i,id)',"server GardenEdit mutation")
need(garden,'temp.MenuOpen~=true or temp.MenuName~="Garden"',"Garden edits require the Garden menu")
need(garden,'(self.EditorSessions[player] or 0)<workspace:GetServerTimeNow()',"expired editor rejection")
need(garden,'(p.FlowerCollection.OwnedSeedCopies[id] or 0)<1',"server species ownership check")
need(garden,'if slotIndex~=i and existing.SpeciesId==id then sourceIndex=slotIndex break end',"existing species move detection")
need(garden,'p.Garden.Slots[sourceIndex]={}',"move clears previous slot")
need(garden,'TotalPollination=tonumber(source.TotalPollination) or 0',"move preserves slot telemetry")
need(garden,'Mutation=source.Mutation or ""',"move preserves mutation")
need(garden,'p.Garden.Revision+=1',"Garden revision mutation")
need(garden,'self:Build(player)',"physical world rebuild after edit")
need(garden,'self.EditorSessions[player]=nil',"session cleanup")

need(player,'elseif action=="GardenEdit" then return self.GardenPlotService:GardenEdit(player,a,b)',"server action route")
need(remote,'action=="GardenEdit"',"GardenEdit remote schema")
if 'action=="Plant"' in remote:
    raise AssertionError("legacy Plant remote route must stay removed")
need(state,'Hint=Effects.Feature(profile,"GARDEN_5","PatternHints") and self.X.GardenSynergyService:Hint(profile) or nil',"hint stays Workshop-gated")

need(bloom,'Garden="GardenV1"',"Garden renderer id")
need(bloom,'GardenEditor.Render(self,p,ui)',"Garden renderer dispatch")
need(bloom,'Garden="GardenV1"',"Garden menu renderer")
need(bloom,'for _,name in ipairs({"SeedSatchel","Garden","Hive","Index","Workshop","Trials","Settings"}) do',"Garden/Hive dock authored binding")
need(bloom,'local controlsVisible=rollUnlocked and self.Menu==nil',"Roll controls hide whenever a menu is open")
need(bloom,'self.RouletteViewport.Visible=rollUnlocked and',"roulette stays beneath the Garden menu")

need(editor_html,'data-ui-state="garden"',"Garden UI Studio state")
need(editor,'garden:"Garden"',"Garden UI Studio title")
need(editor,'garden:"GardenKit"',"Garden UI Studio focus")
need(editor,'garden:"GardenKit",hive:"HiveKit",settings:"SettingsKit"',"Garden/Hive StateKit preview mapping")
need(editor,'scene==="garden")return [[0,1040],[0,620]]',"Garden Studio preview geometry")

print("garden editor contract: PASS")
print("Authored left Flower list + seven-slot ring + active Synergy/hint are connected to a server-authoritative, world-synced editor.")
