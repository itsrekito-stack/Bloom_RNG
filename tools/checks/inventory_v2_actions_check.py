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
state=read("src/ServerScriptService/Services/UIStateService.luau")
bloom=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau")

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

for text,label in [
 ('controller:Send("Flag",item.Id,"FavoriteFlowers")',"Favorite action"),
 ('controller:Send("Flag",item.Id,"LockedFlowers")',"Protect action"),
 ('controller:Send("EquipBee","",equippedSlot)',"Bee unequip action"),
 ('controller:Send("EquipBee",item.Id,slot)',"Bee equip action"),
 ('controller.LastSeed=item.Id',"Plant selection handoff"),
 ('controller:Send("Plant",plantSlot,item.Id)',"Inventory Plant request"),
 ('"PLANT IN SLOT "..tostring(plantSlot)',"target Garden slot action"),
 ('traitEquipPreview(item,inventory)',"Trait delta preview"),
 ('item.Odds or "1/—"',"1/N presentation"),
 ('item.Obtained or 1',"obtained count presentation"),
]:
    need(client,text,label)

need(client,'setButton(dissolve,false)',"obsolete duplicate-dismantle buttons are hidden")
need(client,'setButton(mastery,false)',"obsolete Dust mastery button is hidden")
if 'controller:Send("DissolveBee",item.Id,1)' in client:
    raise AssertionError("Bee dismantle action returned to Inventory V2")
if 'controller:Send("FlowerUpgrade",item.Id)' in client:
    raise AssertionError("manual Flower Dust upgrade returned to Inventory V2")

need(bloom,'function UI:OpenPlantInventory(slot)',"Plant picker entry point")
need(bloom,'state.Category="Flowers"',"Plant picker opens Flowers")
need(bloom,'state.Filter="Available"',"Plant picker shows available species")
need(bloom,'self:Open("SeedSatchel",{PlantSlot=slot},{SilentMenu=true})',"Plant picker reuses Inventory")
need(bloom,'local inventoryOpen=self.MenuRenderer=="InventoryV2" and self.Menu~=nil',"Inventory state suppresses Roll")
need(bloom,'self.Roll.Visible=rollUnlocked and not inventoryOpen',"Roll button hidden while Inventory is open")
need(garden,'self.X.U.Near(player,pos,C.InteractionDistance)',"world Plant remains server proximity gated")
need(garden,'self.X.InventoryService:Available(p,id)<1',"Plant ownership validation")
need(garden,'return false,"ALREADY_PLANTED"',"same Flower cannot be planted twice")

for text,label in [
 ('elseif action=="Plant" then return self.GardenPlotService:Plant(player,a,b)',"Plant server route"),
 ('elseif action=="EquipBee" then return self.InventoryService:EquipBee(player,a,b)',"Equip server route"),
 ('if b~="LockedFlowers" and b~="FavoriteFlowers" then return false,"INVALID_ACTION" end',"Flag field allowlist"),
]:
    need(player,text,label)

need(inventory,'if not self.X.U.Integer(slot,capacity) then return false,"INVALID_SLOT" end',"Bee slot capacity guard")
need(inventory,'if (p.Pollinators.BeeInventory[id] or 0)<1 then return false,"NOT_OWNED" end',"Bee species ownership guard")
need(inventory,'if i~=slot and v==id then return false,"ALREADY_EQUIPPED" end',"one equipped copy per Bee species")
need(inventory,'function S:Dissolve()',"legacy Flower dissolve endpoint exists only as rejection")
need(inventory,'function S:DissolveBee()',"legacy Bee dissolve endpoint exists only as rejection")
if inventory.count('return false,"ACTION_UNAVAILABLE"')<2:
    raise AssertionError("obsolete duplicate actions must fail closed")

for text,label in [
 ('Obtained=profile.FlowerCollection.ObtainedFlowers[id] or 1',"Flower obtained projection"),
 ('Count=1',"species ownership projects one owned entry"),
 ('CanDissolve=false',"dismantle projection disabled"),
 ('Obtained=profile.Pollinators.BeeObtained[id] or 1',"Bee obtained projection"),
 ('EquippedBeeSlots=self.X.U.Copy(profile.Pollinators.EquippedBeeSlots)',"equipped slots projection"),
]:
    need(state,text,label)

print("inventory-v2 action contract: PASS")
print("Inventory uses species ownership, 1/N, duplicate progression, manual Bee equip and guarded Garden handoff; obsolete dismantle/manual mastery actions are hidden.")
