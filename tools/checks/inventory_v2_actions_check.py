#!/usr/bin/env python3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src: raise AssertionError(f"{label}: missing {text!r}")

client=read("src/StarterPlayer/StarterPlayerScripts/Controllers/InventoryV2Controller.luau")
player=read("src/ServerScriptService/Services/PlayerService.luau")
inventory=read("src/ServerScriptService/Services/InventoryService.luau")
garden=read("src/ServerScriptService/Services/GardenPlotService.luau")
mastery=read("src/ServerScriptService/Services/FlowerProgressionService.luau")
state=read("src/ServerScriptService/Services/UIStateService.luau")
bloom=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau")

# Browser controls.
for text,label in [
 ('CATEGORY_ORDER={"Flowers","Bees","Seeds","Resources","Special"}',"category coverage"),
 ('SORT_ORDER={"Rarity","Name","Count"}',"sort modes"),
 ('FILTER_ORDER={"All","Favorite","Protected","Available"}',"filter modes"),
 ('local function filteredItems(source,search,filter,sortMode)',"search/filter/sort pipeline"),
 ('setupSearch(searchBar,state,refreshGrid)',"search binding"),
 ('state.Sort=cycle(SORT_ORDER,state.Sort)',"sort cycling"),
 ('state.Filter=cycle(FILTER_ORDER,state.Filter)',"filter cycling"),
]:
    need(client,text,label)

# Client action wiring.
for text,label in [
 ('controller:Send("Flag",item.Id,"FavoriteFlowers")',"Favorite action"),
 ('controller:Send("Flag",item.Id,"LockedFlowers")',"Protect action"),
 ('controller:Send("Dissolve",item.Id,1)',"Flower dissolve action"),
 ('controller:Send("DissolveBee",item.Id,1)',"Bee dismantle action"),
 ('controller:Send("DistillNectar")',"Ancient Nectar distill action"),
 ('controller:Send("FlowerUpgrade",item.Id)',"Mastery action"),
 ('controller:Send("EquipBee","",equippedSlot)',"Bee unequip action"),
 ('controller:Send("EquipBee",item.Id,slot)',"Bee equip action"),
 ('controller.LastSeed=item.Id',"Plant selection handoff"),
 ('controller:Send("Plant",plantSlot,item.Id)',"Inventory Plant request"),
 ('"PLANT IN SLOT "..tostring(plantSlot)',"target garden slot action"),
]:
    need(client,text,label)

# Physical planting opens Inventory V2 on Flowers and remains world/proximity gated.
need(bloom,'function UI:OpenPlantInventory(slot)',"Inventory Plant picker entry point")
need(bloom,'state.Category="Flowers"',"Plant picker opens Flowers category")
need(bloom,'state.Filter="Available"',"Plant picker defaults to available copies")
need(bloom,'self:Open("SeedSatchel",{PlantSlot=slot},{SilentMenu=true})',"Plant picker uses Inventory without tutorial Menu event")
need(bloom,'elseif kind=="PlantPicker" then self:OpenPlantInventory(payload)',"PlantPicker event route")
assert 'elseif name=="Plant" then' not in bloom, "standalone Plant renderer returned"
need(garden,'self.X.U.Near(player,pos,C.InteractionDistance)',"Plant proximity validation")
need(garden,'self.X.InventoryService:Available(p,id)<1',"Plant free-copy validation")
need(garden,'Rules.HasProgress(old)',"Plant progression protection")

# Server request ownership and unlocks.
for text,label in [
 ('elseif action=="Plant" then return self.GardenPlotService:Plant(player,a,b)',"Plant server route"),
 ('elseif action=="EquipBee" then return self.InventoryService:EquipBee(player,a,b)',"Equip server route"),
 ('return self.InventoryService:Dissolve(player,a,b)',"Flower dissolve server route"),
 ('return self.InventoryService:DissolveBee(player,a,b)',"Bee dismantle server route"),
 ('return self.SeasonService:DistillNectar(player)',"Ancient Nectar distill server route"),
 ('return self.FlowerProgressionService:Upgrade(player,a)',"Mastery server route"),
 ('if b~="LockedFlowers" and b~="FavoriteFlowers" then return false,"INVALID_ACTION" end',"Flag field allowlist"),
]:
    need(player,text,label)
if player.count('if not p.Tutorial.FeatureUnlocks.SeedSatchel then return false,"LOCKED" end') < 4:
    raise AssertionError("Flower/bee dissolve, FlowerUpgrade and Flag must all require SeedSatchel unlock")

# Dissolve / equip authority.
for text,label in [
 ('if f.LockedFlowers[id] then return false,"PROTECTED" end',"protected dissolve guard"),
 ('if f.FavoriteFlowers[id] then return false,"FAVORITE" end',"favorite dissolve guard"),
 ('if self:Available(p,id)<n then return false,"NO_FREE_COPY" end',"free copy guard"),
 ('if (f.OwnedSeedCopies[id] or 0)-n<1 then return false,"LAST_COPY" end',"flower last copy guard"),
 ('if self:AvailableBee(p,id)<n then return false,"NO_FREE_COPY" end',"free bee copy guard"),
 ('if (inv.BeeInventory[id] or 0)-n<1 then return false,"LAST_COPY" end',"bee last copy guard"),
 ('if not self.X.U.Integer(slot,capacity) then return false,"INVALID_SLOT" end',"equip capacity guard"),
 ('if (p.Pollinators.BeeInventory[id] or 0)<1 then return false,"NOT_OWNED" end',"bee ownership guard"),
]:
    need(inventory,text,label)

# Mastery authority.
for text,label in [
 ('not p.FlowerCollection.DiscoveredFlowers[id]',"Mastery discovery guard"),
 ('if m.Level>=C.MasteryCap then return false,"MASTERY_MAX" end',"Mastery cap"),
 ('if p.Currencies.PetalDust<cost then return false,"DUST_REQUIRED" end',"Mastery cost guard"),
]:
    need(mastery,text,label)

# State projection drives button availability.
for text,label in [
 ('Free=free',"free copies projection"),
 ('CanDissolve=free>0 and count>1 and not locked and not favorite',"dissolve projection"),
 ('CanUpgrade=(mastery.Level or 1)<Bloom.MasteryCap and profile.Currencies.PetalDust>=cost',"upgrade projection"),
 ('Favorite=favorite',"favorite projection"),
 ('Protected=locked',"protected projection"),
 ('EquippedBeeSlots=self.X.U.Copy(profile.Pollinators.EquippedBeeSlots)',"equipped slots projection"),
 ('DissolveValue=Bloom.BeeDustPerCopy',"bee dismantle value projection"),
 ('NectarDistill={',"Ancient Nectar distill projection"),
]:
    need(state,text,label)

print("inventory-v2 action contract: PASS")
print("Covered: category/search/sort/filter, Garden Plant picker through Flowers, Favorite, Protect, flower dissolve, Bee dismantle, Mastery and Bee equip/unequip.")
print("Server authority: unlock, proximity, ownership, protection, cost and capacity guards verified.")
