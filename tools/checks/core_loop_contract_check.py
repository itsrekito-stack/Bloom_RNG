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
 (inventory,'f.OwnedSeedCopies[id]=1',"first Flower grants species ownership"),
 (inventory,'f.ObtainedFlowers[id]=(f.ObtainedFlowers[id] or 0)+1',"Flower obtained count increments"),
 (inventory,'self.X.FlowerProgressionService:AddDuplicate(player,id,1)',"duplicate Flower advances Level"),
 (inventory,'pollinators.BeeInventory[id]=1',"first Bee grants species ownership"),
 (inventory,'self.X.PollinatorService:AddMastery(player,id,C.BeeDuplicateXP)',"duplicate Bee advances Mastery"),
 (bloom_ui,'MENU_RENDERERS={SeedSatchel="InventoryV2",Garden="GardenV1",Hive="HiveV1",Index="IndexV1",Quests="QuestsV2",Settings="SettingsV2"}',"authored menu routes stay centralized"),
 (inventory_ui,'CATEGORY_ORDER={"Bees","Resources","Special"}',"Inventory excludes Flowers; planting stays in Garden"),
 (bloom_ui,'function UI:OpenGardenMenu(slot)',"Garden menu owns planting entry point"),
 (bloom_ui,'GardenEditor.Render(self,p,ui)',"authored Garden editor renderer"),
 (player,'elseif action=="GardenEdit" then return self.GardenPlotService:GardenEdit(player,a,b)',"Garden editor route stays server-owned"),
 (garden,'temp.MenuOpen~=true or temp.MenuName~="Garden"',"Garden edits require active Garden menu session"),
 (garden,'(self.EditorSessions[player] or 0)<workspace:GetServerTimeNow()',"Garden editor session expires server-side"),
 (garden,'(p.FlowerCollection.OwnedSeedCopies[id] or 0)<1',"Garden edit validates Flower ownership"),
 (garden,'if slotIndex~=i and existing.SpeciesId==id then sourceIndex=slotIndex break end',"Garden moves duplicate species instead of duplicating it"),
 (garden,'self.X:Emit(player,"Plant",1)',"Garden edit advances Plant progression event"),
 (pollinator,'profile.Hive.Honey+=honey',"Bee delivery produces Honey"),
 (pollinator,'profile.Currencies.Coins+=coins',"Bee delivery produces Coins"),
 (pollinator,'self.X.GardenPlotService:AddFlowerXP(player,state.Slot,workAmount)',"Bee work updates Flower telemetry/presentation"),
 (pollinator,'self.X.RollService:Charge(player,C.Charge.Delivery',"Bee delivery charges Bloom meter"),
 (pollinator,'self.X:Emit(player,"Delivery",1)',"Delivery advances progression event"),
 (hive,'self.X:Emit(player,"FirstGardenSlot",1)',"Hive unlocks first Garden slot"),
 (hive,'self:QuestStatus(p,nextLevel)',"Hive upgrades require cross-system quest"),
 (hive,'C.WorkshopPointsForHiveLevel(nextLevel)',"Hive awards milestone and endless Workshop points"),
 (workshop,'w.Nodes[id]=true',"Workshop purchase owns node"),
 (player,'elseif action=="Roll" then return self.RollService:Roll',"remote Roll route remains server-owned"),
 (ui_state,'Inventory=self:Inventory(player,profile)',"snapshot exposes Inventory"),
 (ui_state,'Garden={ActiveSynergy=profile.Garden.ActiveSynergy or "",Hint=Effects.Feature(profile,"GARDEN_5","PatternHints") and self.X.GardenSynergyService:Hint(profile) or nil}',"snapshot exposes gated Garden hint without hidden recipe data"),
]

for src,needle,label in checks: need(src,needle,label)

if 'self.X.InventoryService:Grant(player,"Bee","WorkerBee")' in hive:
    raise AssertionError("direct Hive starter Bee grant returned")
if 'self.X.InventoryService:EquipBee(player,item.Id,1)' in roll:
    raise AssertionError("tutorial Bee roll must not auto-equip before the Equip Bee step")
if 'action=="Plant"' in player:
    raise AssertionError("legacy Plant remote returned; GardenEdit must remain the only planting route")
if 'self:AddMastery(player,bee.Id,1' in pollinator:
    raise AssertionError("routine pollination still grants Bee Mastery")

print(f"core-loop contract: PASS ({len(checks)} assertions)")
print("Covered chain: tutorial slot -> Flower Roll -> Garden -> Bee Roll -> pollination -> Hive -> Workshop.")
