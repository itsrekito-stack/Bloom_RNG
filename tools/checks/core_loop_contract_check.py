#!/usr/bin/env python3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,needle,label):
    if needle not in src: raise AssertionError(f"{label}: missing contract {needle!r}")

roll=read("src/ServerScriptService/Services/RollService.luau")
inventory=read("src/ServerScriptService/Services/InventoryService.luau")
garden=read("src/ServerScriptService/Services/GardenPlotService.luau")
pollinator=read("src/ServerScriptService/Services/PollinatorService.luau")
hive=read("src/ServerScriptService/Services/HiveService.luau")
workshop=read("src/ServerScriptService/Services/WorkshopService.luau")
player=read("src/ServerScriptService/Services/PlayerService.luau")
ui_state=read("src/ServerScriptService/Services/UIStateService.luau")
bloom_ui=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau")
inventory_ui=read("src/StarterPlayer/StarterPlayerScripts/Controllers/InventoryV2Controller.luau")

checks=[
 (roll,'self.X.InventoryService:Grant(player,item.Kind,item.Id)',"Roll grants through InventoryService"),
 (roll,'self.X:Send(player,"Reward",result)',"Roll returns authoritative reward"),
 (roll,'tutorialStep.Id=="FirstFlowerRoll"', "tutorial Flower roll is explicit"),
 (roll,'tutorialStep.Id=="FirstBeeRoll"', "tutorial Bee roll is explicit"),
 (roll,'self.X.InventoryService:EquipBee(player,item.Id,1)',"tutorial first Bee equips through server"),
 (inventory,'f.OwnedSeedCopies[id]=1',"first Flower grants species ownership"),
 (inventory,'f.ObtainedFlowers[id]=(f.ObtainedFlowers[id] or 0)+1',"Flower obtained count increments"),
 (inventory,'self.X.FlowerProgressionService:AddDuplicate(player,id,1)',"duplicate Flower advances Level"),
 (inventory,'pollinators.BeeInventory[id]=1',"first Bee grants species ownership"),
 (inventory,'self.X.PollinatorService:AddMastery(player,id,C.BeeDuplicateXP)',"duplicate Bee advances Mastery"),
 (bloom_ui,'MENU_RENDERERS={SeedSatchel="InventoryV2",Garden="GardenV1",Trials="QuestsV2",Settings="SettingsV2"}',"authored menu routes stay centralized"),
 (inventory_ui,'"PLANT IN GARDEN"',"Inventory hands unplanted Flowers to Garden editor"),
 (inventory_ui,'"EDIT / REMOVE IN GARDEN"',"Inventory hands planted Flowers to Garden editor"),
 (bloom_ui,'"PlantPicker"',"physical Garden opens editor"),
 (bloom_ui,'GardenEditor.Render(self,p,ui)',"authored Garden editor renderer"),
 (player,'elseif action=="GardenEdit" then return self.GardenPlotService:GardenEdit(player,a,b)',"Garden editor route stays server-owned"),
 (garden,'self.X.U.Near(player,pos,C.InteractionDistance)',"Plant remains server proximity gated"),
 (garden,'self.X.InventoryService:Available(p,id)<1',"Plant validates owned available species"),
 (garden,'return false,"ALREADY_PLANTED"', "Garden prevents duplicate planted species"),
 (garden,'self.X:Emit(player,"Plant",1)',"Plant advances progression event"),
 (pollinator,'profile.Hive.Honey+=honey',"Bee delivery produces Honey"),
 (pollinator,'profile.Currencies.Coins+=coins',"Bee delivery produces Coins"),
 (pollinator,'self.X.GardenPlotService:AddFlowerXP(player,state.Slot,workAmount)',"Bee work updates Flower telemetry/presentation"),
 (pollinator,'self.X.RollService:Charge(player,C.Charge.Delivery',"Bee delivery charges Bloom meter"),
 (pollinator,'self.X:Emit(player,"Delivery",1)',"Delivery advances progression event"),
 (hive,'self.X:Emit(player,"FirstGardenSlot",1)',"Hive unlocks first Garden slot"),
 (hive,'self:QuestStatus(p,nextLevel)',"Hive upgrades require cross-system quest"),
 (hive,'C.WorkshopPointHiveMilestones[nextLevel] or 0',"Hive uses static Workshop point milestones"),
 (workshop,'w.Nodes[id]=true',"Workshop purchase owns node"),
 (player,'elseif action=="Roll" then return self.RollService:Roll',"remote Roll route remains server-owned"),
 (player,'elseif action=="Plant" then return self.GardenPlotService:Plant',"remote Plant route remains server-owned"),
 (ui_state,'Inventory=self:Inventory(player,profile)',"snapshot exposes Inventory"),
 (ui_state,'Garden={ActiveSynergy=profile.Garden.ActiveSynergy or "",Hint=Effects.Feature(profile,"GARDEN_5","PatternHints") and self.X.GardenSynergyService:Hint(profile) or nil}',"snapshot exposes gated Garden hint without hidden recipe data"),
]

for src,needle,label in checks: need(src,needle,label)

if 'self.X.InventoryService:Grant(player,"Bee","WorkerBee")' in hive:
    raise AssertionError("direct Hive starter Bee grant returned")
if 'self:AddMastery(player,bee.Id,1' in pollinator:
    raise AssertionError("routine pollination still grants Bee Mastery")

print(f"core-loop contract: PASS ({len(checks)} assertions)")
print("Covered chain: tutorial slot -> Flower Roll -> Garden -> Bee Roll -> pollination -> Hive -> Workshop.")
