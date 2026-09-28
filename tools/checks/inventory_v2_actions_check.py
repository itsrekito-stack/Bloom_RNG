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
domain=read("src/ServerScriptService/Data/ProfileDomain.luau")
bloom=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau")

for text,label in [
 ('CATEGORY_ORDER={"Bees","Resources","Special"}',"Flowers removed from Inventory categories"),
 ('SORT_ORDER={"Rarity","Name","Count"}',"sort modes"),
 ('local function matchesTrait(item,traitId)',"Bee trait filter predicate"),
 ('local function availableTraits(bees)',"owned-Bee trait availability"),
 ('local function filteredItems(source,search,filter,sortMode,traitId)',"search/filter/sort/trait pipeline"),
 ('setupSearch(searchBar,state,refreshGrid)',"search binding"),
 ('local gridLayout=grid:FindFirstChildOfClass("UIGridLayout")',"authored grid layout binding"),
 ('card.Position=UDim2.fromOffset',"non-creating card placement fallback"),
 ('state.Sort=cycle(SORT_ORDER,state.Sort)',"sort cycling"),
 ('local traitPanel=browser:WaitForChild("TraitFilterPanel")',"authored trait filter panel"),
 ('local traitTemplate=traitList:WaitForChild("TraitChipTemplate")',"authored trait chip template"),
 ('filterButton.Text=selectedTrait and ("TRAITS • "..tostring(selectedTrait.Name)) or "TRAITS"',"Trait filter button copy"),
 ('state.TraitFilter=traitId',"Trait selection state"),
 ('local unequipAllButton=browser:WaitForChild("UnequipAllButton")',"authored Unequip All control"),
 ('function() controller:Send("UnequipAllBees") end',"Unequip All client action"),
 ('local equippedBadge=card:FindFirstChild("EquippedBadge")',"equipped Bee card indicator"),
 ('equippedBadge.Text=equippedSlot and ("EQUIPPED  •  S"..tostring(equippedSlot)) or ""',"equipped slot indicator copy"),
 ('local beeSummary=details:FindFirstChild("BeeSummary")',"compact Bee summary"),
 ('local passiveTemplate=passiveList and passiveList:FindFirstChild("PassiveRowTemplate")',"authored passive row template"),
 ('abilityDescription.Text=Bees.GetAbilityDescription(item.Id)',"ability description binding"),
 ('description.Visible=not isBee',"legacy long Bee description hidden"),
 ('stats.Visible=not isBee',"legacy Bee stats block hidden"),
 ('local hoverScale=card:FindFirstChild("InventoryHoverScale")',"inventory hover scale"),
]:
    need(client,text,label)

for text,label in [
 ('controller:Send("EquipBee","",equippedSlot)',"Bee unequip action"),
 ('controller:Send("EquipBee",item.Id,slot)',"Bee equip action"),
 ('traitEquipPreview(item,inventory)',"Trait delta preview"),
 ('item.Odds or "1/—"',"1/N presentation"),
 ('item.Obtained or 1',"obtained count presentation"),
 ('local traitNames=card:FindFirstChild("Traits")',"authored Bee-card trait label binding"),
 ('string.upper(table.concat(item.Traits or {}," • "))',"Bee-card trait names"),
 ('badge.BackgroundColor3=C.Panel',"readable dark rarity badge"),
 ('badgeText.TextColor3=color',"rarity text uses rarity accent"),
]:
    need(client,text,label)

if 'controller:Send("GardenEdit"' in client or '"PLANT IN GARDEN"' in client or '"EDIT / REMOVE IN GARDEN"' in client:
    raise AssertionError("Inventory must not contain Flower planting actions")

need(client,'setButton(dissolve,false)',"obsolete duplicate-dismantle buttons are hidden")
need(client,'setButton(mastery,false)',"obsolete Dust mastery button is hidden")
if 'controller:Send("DissolveBee",item.Id,1)' in client:
    raise AssertionError("Bee dismantle action returned to Inventory V2")
if 'controller:Send("FlowerUpgrade",item.Id)' in client:
    raise AssertionError("manual Flower Dust upgrade returned to Inventory V2")

need(bloom,'function UI:OpenGardenMenu(slot)',"Garden editor entry point stays inside Garden menu")
need(bloom,'GardenEditor.Render(self,p,ui)',"Garden editor renderer")
need(bloom,'for _,name in ipairs({"SeedSatchel","Garden","Hive","Index","Workshop","Quests","Settings"}) do',"Garden/Hive dock button binding")
need(bloom,'local controlsVisible=rollUnlocked and self.Menu==nil',"Roll controls hide while menus are open")
need(bloom,'self.RouletteViewport.Visible=rollUnlocked and',"roulette remains running beneath menus")
need(garden,'function S:GardenEdit(player,i,id)',"server Garden editor mutation path")
need(garden,'temp.MenuOpen~=true or temp.MenuName~="Garden"',"Garden menu required for edits")
if 'action=="Plant"' in player:
    raise AssertionError("PlayerService must not expose legacy Plant action")
need(garden,'(self.EditorSessions[player] or 0)<workspace:GetServerTimeNow()',"Garden editor session validation")
need(garden,'(p.FlowerCollection.OwnedSeedCopies[id] or 0)<1',"Garden editor species ownership validation")

for text,label in [

 ('elseif action=="EquipBee" then return self.InventoryService:EquipBee(player,a,b)',"Equip server route"),
 ('elseif action=="UnequipAllBees" then return self.InventoryService:UnequipAllBees(player)',"Unequip All server route"),
 ('if b~="LockedFlowers" and b~="FavoriteFlowers" then return false,"INVALID_ACTION" end',"Flag field allowlist"),
]:
    need(player,text,label)

need(inventory,'function S:UnequipAllBees(player)',"server-authoritative Unequip All")
need(inventory,'p.Pollinators.EquippedBeeSlots[slot]=nil',"Unequip All clears equipped slots")
need(inventory,'self.X.PollinatorService:Remove(player)',"Unequip All clears stale Bee brains")
need(inventory,'if not self.X.U.Integer(slot,capacity) then return false,"INVALID_SLOT" end',"Bee unequip slot capacity guard")
need(inventory,'if (p.Pollinators.BeeInventory[id] or 0)<1 then return false,"NOT_OWNED" end',"Bee species ownership guard")
need(inventory,'if v==id then return false,"ALREADY_EQUIPPED" end',"one equipped copy per Bee species")
need(inventory,'local function chooseEquipSlot(p,id,capacity)',"server-authoritative full-slot replacement")
need(inventory,'if rank<newRank',"auto replacement only targets lower-rarity Bees")
need(inventory,'return false,"NO_LOWER_RARITY_BEE"',"full stronger/equal loadout protection")
need(client,'setButton(plant,true,"EQUIP",true,function() controller:Send("EquipBee",item.Id,slot) end)',"Equip remains active when Bee slots are full")
assert '"SLOTS FULL"' not in client, "full Bee slots must not disable Equip"
need(client,'autoReplaceBeeSlot(slots,inventory.BeeCapacity,item.Id)',"client trait preview mirrors auto replacement")
need(inventory,'pollinators.BeeInventory[id]=1',"every Bee grant guarantees permanent ownership")
need(inventory,'local owned=(tonumber(pollinators.BeeInventory[id]) or 0)>0',"duplicate mastery uses prior ownership, not discovery flag")
need(inventory,'self.X:MarkStateDirty(player)',"Bee grants dirty authoritative state for Inventory sync")
need(domain,'if discovered==true then',"only true Bee discoveries are repaired")
need(domain,'if (tonumber(b.BeeInventory[id]) or 0)<1 then b.BeeInventory[id]=1 end',"discovered Bee ownership repair")
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
print("Inventory contains Bees/resources/keepsakes only; all Flower planting is isolated to the Garden menu.")
