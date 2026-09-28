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
bloom=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau")
settings=read("src/StarterPlayer/StarterPlayerScripts/Controllers/SettingsController.luau")
activity=read("src/ServerScriptService/Services/GardenActivityService.luau")
roll=read("src/ServerScriptService/Services/RollService.luau")
hive=read("src/ServerScriptService/Services/HiveService.luau")
map_service=read("src/ServerScriptService/Services/MapService.luau")
locations=read("src/ReplicatedStorage/Config/LocationsConfig.luau")
inventory=read("src/ServerScriptService/Services/InventoryService.luau")
pollinator=read("src/ServerScriptService/Services/PollinatorService.luau")

ids=re.findall(r'\{Id="([^"]+)"',config)
expected=["GardenSlot","FirstFlowerRoll","Plant","FirstBeeRoll","EquipBee","FillBloom","BloomRoll","InventoryExplain","PollenSpark","HiveUpgrade","WorkshopPurchase","Synergy","Quests"]
assert ids==expected, f"unexpected tutorial sequence: {ids}"
assert 'Version=11' in config and len(ids)==13

for removed in ("BeeWork","NormalRoll","WorkshopVisit","SunnyVisit"):
    assert f'Id="{removed}"' not in config, f"removed tutorial step returned: {removed}"
assert 'Id="Inventory",Event="SatchelOpen"' not in config, "standalone Inventory-open step returned"

need(config,'Target="GardenEditorSlot",Slot=1,FlowerId="Daisy"',"first Garden planting")
need(config,'Target="InventoryBeeEquip",BeeId="WorkerBee"',"explicit Bee equip")
need(config,'Target="BloomMeter"',"Bloom meter target")
need(config,'Target="WorkshopNode",NodeId="ROLL_1"',"menu Workshop purchase target")
need(config,'Target="GardenEditorSlot",Slot=2,PartnerSlot=1,FlowerId="Tulip"',"Synergy target")
need(config,'It gives +4 Bloom Charge, counts as an Activity for progression and Hive Quests, and contributes to the Server Bloom.',"Pollen Spark reward explanation")

need(features,'Workshop={Event="HiveUpgrade"}',"Workshop menu unlocks from Hive progression")
need(features,'Quests={Event="HiveUpgrade"}',"Quests unlock from Hive progression")
need(guide,'if step.Target=="WorkshopNode" then',"Workshop node guide")
need(guide,'local button=ui.DockButtons.Workshop',"Workshop is opened from bottom menu")
if 'world:FindFirstChild("Workshop")' in guide:
    raise AssertionError("tutorial guide still targets a physical Workshop")
if 'LocationsConfig' in guide or 'SunnyOrchard' in guide:
    raise AssertionError("tutorial guide still references removed locations")

need(roll,'if step.Id=="FirstFlowerRoll" then return "FlowerSeed" end',"Flower-only first roll")
need(roll,'if step.Id=="FirstBeeRoll" then return "Bee" end',"Bee-only first Bee roll")
need(roll,'step.Id=="BloomRoll"',"single Bloom Roll allowlist")
if 'step.Id=="NormalRoll"' in roll or 'TutorialNormalRoll' in roll:
    raise AssertionError("NormalRoll tutorial runtime returned")
need(roll,'if T.Steps[p.Tutorial.Step] and automatic then return false,"TUTORIAL_SINGLE_ROLL" end',"tutorial Auto Roll rejected")
need(inventory,'self.X:Emit(player,"EquipBee",1)',"Bee equip progression event")
if 'StarterBeeGranted' in pollinator:
    raise AssertionError("obsolete StarterBeeGranted runtime gate returned")

need(service,'step.Id=="FillBloom" and not t.Events.TutorialAssistBloom',"fast Bloom tutorial assist")
need(service,'Bloom.BloomMax-deliveryCharge',"Bloom stops one delivery short")
need(service,'self.X:Emit(player,"BloomReady",1)',"Bloom-ready completion")
need(service,'p.Hive.Honey=need',"Hive tutorial assist")
need(service,'p.WorkshopV5.Points=math.max(p.WorkshopV5.Points,node.Cost or 0)',"Workshop purchase assist")
need(service,'self.X.InventoryService:Grant(player,"FlowerSeed","Tulip")',"Synergy Tulip assist")
need(activity,'self.X.RollService:Charge(player,A.Types[kind].Charge',"activities add Bloom Charge")

need(bloom,'self.BloomTutorialIndicator.Visible=bloomTutorialActive',"persistent Bloom indicator")
need(bloom,'previousTutorialId=="EquipBee"',"Equip Bee transition is detected")
need(bloom,'if closeInventoryAfterEquip then self:Close() end',"Inventory closes before Fill Bloom")
need(bloom,'self.MeterLabel.Text=string.format("BLOOM  %.0f%%",bloomPercent)',"Bloom label")
assert 'DISCOVERY  %d/%d' not in bloom, "Discovery n/n returned to Bloom HUD"
assert 'NormalRoll' not in bloom, "removed NormalRoll client step returned"

need(default,'Tutorial={Version=11,Step=1,FeatureUnlocks={},Events={}}',"fresh tutorial version")
need(settings,'find(runtime,"StudioTutorialResetButton","TextButton")',"Studio tutorial reset authored binding")
need(settings,'ui:Send("StudioTutorialReset")',"Studio tutorial reset action")
need(hive,'self.X:Emit(player,"FirstGardenSlot",1)',"first Garden slot")
need(hive,'self.X:Emit(player,"HiveUpgrade",1)',"Hive upgrade event")
assert 'LocationsConfig' not in hive and 'gate is ready to unlock' not in hive, "Hive still exposes location gates"

need(locations,'Order={}',"location list removed")
need(locations,'Sectors={}',"location sectors removed")
assert 'SunnyOrchard' not in map_service and 'CrystalGreenhouse' not in map_service and 'TwilightGrove' not in map_service, "MapService still builds removed locations"
assert '"Workshop"' not in map_service, "MapService still builds physical Workshop"

need(player,'tutorialStep and tutorialStep.Id=="InventoryExplain"',"Inventory explanation close validation")
assert 'tutorialStep.Id=="Inventory"' not in player, "standalone Inventory tutorial event returned"
need(player,'tutorialStep and tutorialStep.Id=="Quests"',"Quests completion validation")

print("PASS tutorial acceptance: v10 has 13 focused steps, menu-only Workshop, no locations, and explicit Pollen Spark rewards.")
