#!/usr/bin/env python3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]

def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

def require(text, needle, label):
    if needle not in text:
        raise AssertionError(f"{label}: missing contract {needle!r}")

roll=read(Path("src/ServerScriptService/Services/RollService.luau"))
inventory=read(Path("src/ServerScriptService/Services/InventoryService.luau"))
garden=read(Path("src/ServerScriptService/Services/GardenPlotService.luau"))
pollinator=read(Path("src/ServerScriptService/Services/PollinatorService.luau"))
hive=read(Path("src/ServerScriptService/Services/HiveService.luau"))
workshop=read(Path("src/ServerScriptService/Services/WorkshopService.luau"))
player=read(Path("src/ServerScriptService/Services/PlayerService.luau"))
ui_state=read(Path("src/ServerScriptService/Services/UIStateService.luau"))
bloom_ui=read(Path("src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau"))
inventory_ui=read(Path("src/StarterPlayer/StarterPlayerScripts/Controllers/InventoryV2Controller.luau"))

checks=[
    (roll,'self.X.InventoryService:Grant(player,item.Kind,item.Id)',"Roll grants only through InventoryService"),
    (roll,'self.X:Send(player,"Reward",result)',"Roll returns authoritative reward"),
    (inventory,'f.OwnedSeedCopies[id]=(f.OwnedSeedCopies[id] or 0)+1',"Flower reward becomes owned inventory"),
    (inventory,'self.X:Emit(player,"SeedReward",1)',"Seed reward advances progression events"),
    (bloom_ui,'MENU_RENDERERS={SeedSatchel="InventoryV2",Trials="QuestsV2",Settings="SettingsV2"}',"Inventory V2, Quests V2 and Settings V2 own authored menu routes"),
    (inventory_ui,'"PLANT AT GARDEN"',"Inventory routes planting into world interaction"),
    (inventory_ui,'controller.LastSeed=item.Id',"Inventory carries preferred seed into PlantPicker"),
    (bloom_ui,'"PlantPicker"',"Physical garden prompt opens planting picker"),
    (garden,'self.X.U.Near(player,pos,C.InteractionDistance)',"Plant remains proximity gated"),
    (garden,'self.X.InventoryService:Available(p,id)<1',"Plant validates free owned copy"),
    (garden,'self.X:Emit(player,"Plant",1)',"Plant advances progression event"),
    (pollinator,'profile.Hive.Honey+=honey',"Bee delivery produces Honey"),
    (pollinator,'profile.Currencies.Coins+=coins', "Bee delivery produces Coins"),
    (pollinator,'self.X.GardenPlotService:AddFlowerXP(player,state.Slot,workAmount)',"Bee delivery progresses flower"),
    (pollinator,'self:AddMastery(player,bee.Id,1,',"Bee delivery progresses Bee Mastery"),
    (pollinator,'self.X.RollService:Charge(player,C.Charge.Delivery', "Bee delivery charges Bloom meter"),
    (pollinator,'self.X:Emit(player,"Delivery",1)',"Delivery advances progression event"),
    (hive,'self.X.InventoryService:Grant(player,"Bee","WorkerBee")',"Hive grants starter bee through inventory"),
    (hive,'p.Pollinators.EquippedBeeSlots[1]="WorkerBee"',"Starter bee is equipped"),
    (hive,'self.X.WorkshopService:Point(player,"Hive_"', "Hive upgrade awards Workshop points"),
    (workshop,'w.Nodes[id]=true',"Workshop purchase owns node"),
    (workshop,'self.X:Emit(player,"WorkshopPurchase",1)',"Workshop purchase advances progression event"),
    (player,'elseif action=="Roll" then return self.RollService:Roll', "Remote action routes to RollService"),
    (player,'elseif action=="Plant" then return self.GardenPlotService:Plant', "Remote action routes to GardenPlotService"),
    (player,'elseif action=="WorkshopBuy" then return self.WorkshopService:Buy', "Remote action routes to WorkshopService"),
    (ui_state,'Inventory=self:Inventory(player,profile)',"Authoritative snapshot exposes inventory"),
    (ui_state,'Workshop=self:Workshop(player,profile)',"Authoritative snapshot exposes Workshop"),
]

for text,needle,label in checks:
    require(text,needle,label)

print(f"core-loop contract: PASS ({len(checks)} assertions)")
print("Covered chain: Roll -> Inventory -> Garden -> Bees/Pollination -> Hive -> Workshop")
print("NOTE: this is a deterministic source-contract gate, not a Roblox Studio runtime playtest.")
