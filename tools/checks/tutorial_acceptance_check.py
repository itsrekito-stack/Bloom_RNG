from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src: raise AssertionError(f"{label}: missing {text!r}")

config=read("src/ReplicatedStorage/Config/TutorialConfig.luau")
features=read("src/ReplicatedStorage/Config/FeatureUnlockConfig.luau")
guide=read("src/StarterPlayer/StarterPlayerScripts/Controllers/TutorialGuideController.luau")
service=read("src/ServerScriptService/Services/TutorialService.luau")
player=read("src/ServerScriptService/Services/PlayerService.luau")
default=read("src/ServerScriptService/Data/DefaultProfile.luau")
locations=read("src/ReplicatedStorage/Config/LocationsConfig.luau")
bloom=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau")
settings=read("src/StarterPlayer/StarterPlayerScripts/Controllers/SettingsController.luau")
activity=read("src/ServerScriptService/Services/GardenActivityService.luau")
activity_client=read("src/StarterPlayer/StarterPlayerScripts/Controllers/ActivityController.luau")
roll=read("src/ServerScriptService/Services/RollService.luau")
hive=read("src/ServerScriptService/Services/HiveService.luau")
data=read("src/ServerScriptService/Services/DataService.luau")
remote=read("src/ServerScriptService/Services/RemoteService.luau")
ui_state=read("src/ServerScriptService/Services/UIStateService.luau")

ids=re.findall(r'\{Id="([^"]+)"',config)
expected=["GardenSlot","FirstFlowerRoll","Plant","FirstBeeRoll","BeeWork","NormalRoll","Inventory","InventoryExplain","PollenSpark","HiveUpgrade","WorkshopVisit","WorkshopPurchase","Synergy","SunnyVisit","Quests"]
assert ids==expected, f"unexpected tutorial sequence: {ids}"
assert 'Version=6' in config and len(ids)==15

for forbidden in ("Trait","BloomRoll","WorldActivity","TutorialActivity","Deliveries","Delivery"):
    assert f'Event="{forbidden}"' not in config, f"random/slow mandatory step returned: {forbidden}"

need(config,'Target="Hive"',"Hive targets authored")
need(config,'Target="Roll"',"Roll targets authored")
need(config,'Target="GardenSlot",Slot=1',"first Garden planting target")
need(config,'Target="TutorialToken"',"tutorial checkpoint target")
need(config,'Target="InventoryStats"',"Inventory explanation target")
need(config,'Target="QuestsButton"',"Quests handoff target")
need(config,'Target="WorkshopNode",NodeId="ROLL_1"',"first Workshop node target")
need(config,'Target="SynergySlot",Slot=2',"Synergy target")

targets=set(re.findall(r'Target="([^"]+)"',config))
screen={"Roll","SeedSatchel","InventoryStats","WorkshopNode","QuestsButton"}
world={"Hive","Bee","TutorialToken","GardenSlot","SynergySlot","Workshop"}
sectors=set(re.findall(r'(SunnyOrchard|CrystalGreenhouse|TwilightGrove)=\{',locations))
unknown=targets-screen-world-sectors
assert not unknown, f"tutorial has unmapped targets: {sorted(unknown)}"

for token in (
    'if step.Target=="Roll" then',
    'if step.Target=="SeedSatchel" then',
    'if step.Target=="InventoryStats" then',
    'if step.Target=="QuestsButton" then',
    'if step.Target=="WorkshopNode" then',
    'if target=="Hive" then',
    'elseif target=="Bee" then',
    'elseif target=="TutorialToken" then',
    'elseif target=="GardenSlot" then',
    'elseif target=="SynergySlot" then',
    'elseif target=="Workshop" then',
    'elseif L.Sectors[target] then',
):
    need(guide,token,"tutorial guide resolver")

for token in (
    'math.clamp(localX+targetSize.X*.5',
    'math.clamp(localY+targetSize.Y*.5',
    'calloutY=math.clamp(calloutY,24,rootSize.Y-24)',
):
    need(guide,token,"screen guide stays on-screen")
need(guide,'self.Beam.Enabled=distance>15',"short-distance beam suppression")
need(guide,'warn(string.format("[Tutorial] target missing step=%s target=%s"', "missing target diagnostic")
need(guide,'ui.Activities:Target("Tutorial")',"checkpoint pointer")
need(guide,'ui.Bees:Target(true)',"local Bee pointer")
need(guide,'runtime and runtime:FindFirstChild("StatsCard",true)',"Inventory stats pointer")
need(guide,'function S:SetSynergyPartner(primary,partner)',"Synergy partner guidance")
need(guide,'step.Id=="PollenSpark" or step.Id=="Synergy" or step.Id=="SunnyVisit"',"world-step menu handoff")
need(guide,'ui:Close({SuppressInventoryReturn=true})',"world-step menu closes without bouncing back to Inventory")

need(service,'local function completionKey(step)',"step completion persistence")
need(service,'if not step or step.Event~=event then return false end',"future event rejection")
need(player,'self.TutorialService:RecordEvent(player,event)',"events route through TutorialService")
need(service,'while T.Steps[t.Step] and t.Events[completionKey(T.Steps[t.Step])] do t.Step+=1 end',"ordered progression")
need(service,'self.X.U.Near(player,pos,6.5)',"Hive approach server validation")
need(service,'self.X.GardenActivityService:EnsureTutorialSpark(player)',"guaranteed Pollen Spark")
need(service,'p.Hive.Honey=need',"tutorial Hive assist")
need(service,'p.WorkshopV5.Points=math.max(p.WorkshopV5.Points,node.Cost or 0)',"first Workshop node assist")
need(service,'self.X.InventoryService:Grant(player,"FlowerSeed","Tulip")',"Synergy partner uses normal species grant")
need(hive,'self.X:Emit(player,"FirstGardenSlot",1)',"first Garden slot comes from Hive interaction")
if 'InventoryService:Grant(player,"Bee","WorkerBee")' in hive:
    raise AssertionError("direct starter Bee grant returned")

need(roll,'if stepId=="FirstFlowerRoll" then',"Flower-only tutorial roll mode")
need(roll,'item.Kind=="FlowerSeed" and item.Id=="Daisy"',"first Flower is deterministic when available")
need(roll,'elseif stepId=="FirstBeeRoll" then',"Bee-only tutorial roll mode")
need(roll,'item.Kind=="Bee" and item.Id=="WorkerBee"',"first Bee is deterministic when available")
need(roll,'self.X.InventoryService:EquipBee(player,item.Id,1)',"first Bee auto-equips")
need(roll,'self.X:Emit(player,"TutorialFlowerRoll",1)',"Flower tutorial event")
need(roll,'self.X:Emit(player,"TutorialBeeRoll",1)',"Bee tutorial event")
need(roll,'self.X:Emit(player,"TutorialNormalRoll",1)',"normal RNG handoff event")
need(features,'Roll={Step=2}',"Roll unlock timing")

need(activity,'function S:EnsureTutorialSpark(player)',"tutorial checkpoint factory")
need(activity,'Tutorial=tutorial==true',"tutorial activity ownership")
need(activity_client,'STEP INTO CHECKPOINT',"checkpoint instruction")
need(activity_client,'self.UI:Send("Activity",id,item.Index,"Reach")',"checkpoint sends Reach request")
assert "ProximityPrompt" not in activity_client, "activity client must not require E"

need(default,'SchemaVersion=6',"new profile schema")
need(default,'Tutorial={Version=6,Step=1,FeatureUnlocks={},Events={}}',"new profile tutorial version")
need(default,'UnlockedSlots=0',"fresh profile starts before first Garden slot")
need(default,'OwnedSeedCopies={}',"fresh profile has no direct starter Flower")
need(default,'BeeInventory={}',"fresh profile has no direct starter Bee")
need(service,'if t.Version==T.Version then return false end',"tutorial migration guard")
need(service,'local wasComplete=t.Skipped or t.Events.TutorialComplete or t.Step>#T.Steps',"completed tutorial migration")
need(service,'p.Tutorial.Step=#T.Steps+1',"Skip follows config length")
need(service,'p.Tutorial.Skipped=true',"Skip persists")

need(data,'function Service:BeginStudioTransientProfile(player)',"Studio transient profile entry point")
need(data,'if not RunService:IsStudio() then return false,"NOT_STUDIO" end',"Studio reset server guard")
need(player,'function X:ResetStudioTutorial(player)',"Studio reset action")
need(player,'self.GardenPlotService:Remove(player)',"Studio reset tears down old Garden")
need(player,'self.GardenPlotService:Build(player)',"Studio reset builds fresh Garden")
need(player,'elseif action=="StudioTutorialReset" then return self:ResetStudioTutorial(player)',"Studio reset route")
need(remote,'StudioTutorialReset=true',"Studio reset remote validation")
need(ui_state,'NOT_STUDIO="This developer action is available only in Roblox Studio"', "production rejection copy")
need(settings,'if RunService:IsStudio() then',"Studio reset control visibility")
need(settings,'StudioTutorialResetButton',"authored Studio reset control")
need(settings,'ui:Send("StudioTutorialReset")',"Studio reset request")

need(player,'tutorialStep and tutorialStep.Id=="InventoryExplain"',"Inventory review server validation")
need(player,'self.Temp[player].MenuName=a',"server tracks open menu")
need(player,'tutorialStep and tutorialStep.Id=="Quests"',"Quests tutorial open is step-scoped")
need(player,'self:Emit(player,"QuestsOpen",1)',"Quests tutorial completion event")
need(bloom,'function UI:OpenPlantInventory(slot)',"Plant picker Garden handoff")
need(bloom,'self:Open("Garden",{Slot=slot},{SilentMenu=true})',"Plant picker opens authored Garden editor without synthetic Menu completion")
need(bloom,'elseif kind=="PlantPicker" then self:OpenPlantInventory(payload)',"PlantPicker event opens Garden editor")
need(bloom,'self.ObjectiveTitle.Text="TUTORIAL COMPLETE"',"completion title")
need(bloom,'self.ObjectiveText.Text="Your garden journey begins now."',"completion copy")
need(guide,'local step=T.Steps[ui.ReplayIndex or p.Tutorial.Step]',"replay follows current config")
need(bloom,'self.ReplayIndex=i%#T.Steps+1',"Replay next is config-driven")

for path in (
    "src/ReplicatedStorage/Config/TutorialConfig.luau",
    "src/ServerScriptService/Services/TutorialService.luau",
    "src/StarterPlayer/StarterPlayerScripts/Controllers/TutorialGuideController.luau",
    "src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau",
):
    text=read(path)
    for stale in ("StarterBee",'"Roll",Event="Roll"','"FirstSeed"',"#T.Steps==18","#T.Steps==17"):
        if path.endswith("TutorialConfig.luau") and stale in text:
            raise AssertionError(f"{path} contains stale tutorial token {stale}")

print("PASS tutorial acceptance: v6 follows Q&A goal — first slot, Flower Roll, Bee Roll, normal RNG, core progression systems, then Quests.")
