local RS=game:GetService("ReplicatedStorage")

local Flowers=require(RS.Config.FlowersConfig)
local Bees=require(RS.Config.BeesConfig)
local Icons=require(RS.Config.IconsConfig)
local Rarity=require(RS.Config.RarityConfig)
local Theme=require(RS.Config.UIThemeConfig)

local C=Theme.Colors
local InventoryV2={}

local CATEGORY_ORDER={"Flowers","Bees","Seeds","Resources","Special"}
local CATEGORY_TITLES={Flowers="FLOWERS",Bees="BEES",Seeds="SEEDS",Resources="RESOURCES",Special="SPECIAL"}
local SORT_ORDER={"Rarity","Name","Count"}
local SORT_LABELS={Rarity="RARITY  ˅",Name="NAME  ˅",Count="COUNT  ˅"}
local FILTER_ORDER={"All","Favorite","Protected","Available"}
local FILTER_LABELS={All="ALL  ›",Favorite="FAVORITES  ›",Protected="PROTECTED  ›",Available="AVAILABLE  ›"}

local function countMap(t)
 local n=0
 for _ in pairs(t or {}) do n+=1 end
 return n
end

local function compact(n)
 n=tonumber(n) or 0
 local a=math.abs(n)
 local div,suffix=1,""
 if a>=1e12 then div,suffix=1e12,"T"
 elseif a>=1e9 then div,suffix=1e9,"B"
 elseif a>=1e6 then div,suffix=1e6,"M"
 elseif a>=1e3 then div,suffix=1e3,"K" end
 local v=n/div
 if div==1 then return tostring(math.floor(v+.5)) end
 local digits=math.abs(v)>=100 and 0 or math.abs(v)>=10 and 1 or 2
 return string.format("%."..digits.."f",v):gsub("(%..-)0+$","%1"):gsub("%.$","")..suffix
end

local function setText(root,name,value)
 local x=root and root:FindFirstChild(name)
 if x and x:IsA("TextLabel") then x.Text=tostring(value or "") end
 return x
end

local function rarityColor(rarity)
 return Rarity.Colors[rarity] or C.Blue
end

local function flowerIcon(id)
 local icon=Icons.GetRewardIcon("FlowerSeed",id)
 return icon~="" and icon or Icons.Get("System","Flower")
end

local function resourceIcon(id)
 if id=="Honey" then return Icons.Get("System","Hive") end
 local icon=Icons.Get("Currencies",id)
 if icon=="" and id=="PetalDust" then icon=Icons.Get("Currencies","FruitDust") end
 if icon=="" then icon=Icons.Get("System","Flower") end
 return icon
end

local function firstFreeGardenSlot(profile)
 local garden=profile and profile.Garden
 if type(garden)~="table" then return nil end
 local slots=garden.Slots or {}
 local unlocked=tonumber(garden.UnlockedSlots) or #slots
 for i=1,unlocked do
  local slot=slots[i]
  if type(slot)~="table" or not slot.SpeciesId or slot.SpeciesId=="" then return i end
 end
 return nil
end

local function findEquippedSlot(slots,id)
 for i,v in pairs(slots or {}) do
  if v==id then return tonumber(i) end
 end
 return nil
end

local function firstFreeBeeSlot(slots,capacity)
 for i=1,(tonumber(capacity) or 0) do
  if slots[i]==nil or slots[i]=="" then return i end
 end
 return nil
end

local function cloneTable(t)
 local out={}
 for k,v in pairs(t or {}) do out[k]=v end
 return out
end

local function traitEquipPreview(item,inventory)
 if not item or item.Kind~="Bee" then return "" end
 local slots=cloneTable(inventory.EquippedBeeSlots or {})
 if findEquippedSlot(slots,item.Id) then return "Equipped" end
 local free=firstFreeBeeSlot(slots,inventory.BeeCapacity)
 if not free then return "No free Bee slot" end
 local before=Bees.GetTraitState(slots)
 slots[free]=item.Id
 local after=Bees.GetTraitState(slots)
 local byId={} for _,state in ipairs(before) do byId[state.Id]=state end
 local changes={}
 for _,state in ipairs(after) do
  local old=byId[state.Id]
  if old and (state.Count~=old.Count or state.Tier~=old.Tier) then
   local oldNext=old.NextThreshold or old.Count
   local newNext=state.NextThreshold or state.Count
   table.insert(changes,state.Name.." "..old.Count.."/"..oldNext.." → "..state.Count.."/"..newNext)
  end
 end
 return #changes>0 and table.concat(changes,"  •  ") or "No Trait tier change"
end

local function buildItems(profile,inventory)
 local out={Flowers={},Bees={},Seeds={},Resources={},Special={}}
 for _,entry in ipairs(inventory.Flowers or {}) do
  local cfg=Flowers.Species[entry.Id]
  if cfg then
   local item={
    Kind="Flower",Id=entry.Id,DisplayName=entry.DisplayName or cfg.DisplayName,Rarity=entry.Rarity or cfg.Rarity,
    Count=entry.Count or 0,Free=entry.Free or 0,Planted=entry.Planted or 0,Mastery=entry.Mastery or {Level=1,XP=0,NextXP=25},
    Favorite=entry.Favorite==true,Protected=entry.Protected==true,CanDissolve=entry.CanDissolve==true,CanUpgrade=entry.CanUpgrade==true,
    Icon=flowerIcon(entry.Id),Odds=entry.Odds or "1/—",
   }
   table.insert(out.Flowers,item)
   if item.Free>0 then
    local seed=cloneTable(item)
    seed.Kind="Seed"
    seed.Count=item.Free
    table.insert(out.Seeds,seed)
   end
  end
 end

 for _,entry in ipairs(inventory.Bees or {}) do
  local cfg=Bees.Get(entry.Id)
  if cfg then
   table.insert(out.Bees,{
    Kind="Bee",Id=entry.Id,DisplayName=entry.DisplayName or cfg.DisplayName,Rarity=entry.Rarity or cfg.Rarity,
    Count=entry.Count or 0,Equipped=entry.Equipped or 0,Free=entry.Free or 0,CanDissolve=entry.CanDissolve==true,DissolveValue=entry.DissolveValue or 0,
    Traits=entry.Traits or cfg.Traits or {},Ability=entry.Ability or (cfg.Ability and cfg.Ability.Name) or "",
    Mastery=entry.Mastery or Bees.GetMasteryState(0),Icon=Icons.GetBeeIcon(entry.Id),Favorite=false,Protected=false,Odds=entry.Odds or "1/—",
   })
  end
 end

 local currencies=profile.Currencies or {}
 local distill=inventory.NectarDistill or {}
 local resources={
  {Id="Coins",DisplayName="Coins",Count=currencies.Coins or 0,Description="Main currency for progression and upgrades."},
  {Id="Honey",DisplayName="Honey",Count=(profile.Hive and profile.Hive.Honey) or 0,Description="Honey delivered to the hive by your bees."},
  {Id="PetalDust",DisplayName="Petal Dust",Count=currencies.PetalDust or 0,Description="A duplicate resource used for Mastery and upgrades."},
  {Id="AncientNectar",DisplayName="Ancient Nectar",Count=currencies.AncientNectar or 0,Description="Permanent seasonal currency for Legacy progression and post-Legacy distillation.",DistillUnlocked=distill.Unlocked==true,CanDistill=distill.CanDistill==true,DistillCost=distill.Cost or 1,DistillDust=distill.Dust or 0},
 }
 for _,entry in ipairs(resources) do
  entry.Kind="Resource"
  entry.Rarity="Resource"
  entry.Icon=resourceIcon(entry.Id)
  table.insert(out.Resources,entry)
 end

 local keepsakes=inventory.Keepsakes or (profile.Season and profile.Season.Keepsakes) or {}
 for _,slotName in ipairs({"Flower","Flower2","Bee"}) do
  local id=keepsakes[slotName]
  if type(id)=="string" and id~="" then
   local cfg=slotName=="Bee" and Bees.Get(id) or Flowers.Species[id]
   table.insert(out.Special,{
    Kind="Special",Id=slotName..":"..id,SourceId=id,Slot=slotName,
    DisplayName=(slotName=="Flower2" and "Keepsake II • " or "Keepsake • ")..(cfg and cfg.DisplayName or id),
    Rarity=cfg and cfg.Rarity or "Special",Count=1,
    Icon=slotName=="Bee" and Icons.GetBeeIcon(id) or flowerIcon(id),
   })
  end
 end
 return out
end

local function cycle(list,current)
 local i=table.find(list,current) or 1
 return list[i%#list+1]
end

local function normalized(text)
 return string.lower(tostring(text or ""))
end

local function matchesFilter(item,filter)
 if filter=="Favorite" then return item.Favorite==true end
 if filter=="Protected" then return item.Protected==true end
 if filter=="Available" then
  if item.Kind=="Flower" or item.Kind=="Seed" then return (item.Free or 0)>0 end
  if item.Kind=="Bee" then return (item.Count or 0)>(item.Equipped or 0) end
 end
 return true
end

local function sortItems(items,mode)
 table.sort(items,function(a,b)
  if mode=="Name" then
   if a.DisplayName==b.DisplayName then return a.Id<b.Id end
   return a.DisplayName<b.DisplayName
  elseif mode=="Count" then
   if (a.Count or 0)==(b.Count or 0) then return a.DisplayName<b.DisplayName end
   return (a.Count or 0)>(b.Count or 0)
  end
  local ar=Rarity.Rank[a.Rarity] or 0
  local br=Rarity.Rank[b.Rarity] or 0
  if ar==br then return a.DisplayName<b.DisplayName end
  return ar>br
 end)
end

local function filteredItems(source,search,filter,sortMode)
 local out={}
 local q=normalized(search)
 for _,item in ipairs(source or {}) do
  local match=q=="" or string.find(normalized(item.DisplayName),q,1,true) or string.find(normalized(item.Id),q,1,true)
  if match and matchesFilter(item,filter) then table.insert(out,item) end
 end
 sortItems(out,sortMode)
 return out
end

local function componentTemplate(instance,name)
 local runtime=instance and instance:FindFirstAncestor("InventoryV2Runtime")
 local components=runtime and runtime:FindFirstChild("Components")
 local template=components and components:FindFirstChild(name)
 if not template then error("[InventoryV2] Missing authored component template: "..tostring(name)) end
 return template
end

local function setButton(button,visible,text,enabled,callback)
 if not button or not button:IsA("TextButton") then return end
 local oldHitbox=button:FindFirstChild("_InventoryV2ActionHitbox")
 if oldHitbox then oldHitbox:Destroy() end
 button.Visible=visible==true
 button.Text=text or button.Text
 button.Active=false
 button.AutoButtonColor=false
 button.TextTransparency=enabled==false and .45 or 0
 button.BackgroundTransparency=enabled==false and .24 or .02
 if visible and enabled~=false and callback then
  local hitbox=componentTemplate(button,"ActionHitboxTemplate"):Clone()
  hitbox.Name="_InventoryV2ActionHitbox"
  hitbox.Visible=true
  hitbox.ZIndex=button.ZIndex+5
  hitbox.Parent=button
  hitbox.Activated:Connect(callback)
 end
end

local function overlayButton(frame,callback)
 if not frame or not frame:IsA("GuiObject") then return end
 frame.Active=true
 local b=componentTemplate(frame,"OverlayHitboxTemplate"):Clone()
 b.Name="_InventoryV2Hitbox"
 b.Visible=true
 b.ZIndex=frame.ZIndex+20
 b.Parent=frame
 b.Activated:Connect(callback)
end

local function setupSearch(searchBar,state,onChanged)
 local placeholder=searchBar:FindFirstChild("Placeholder")
 local box=componentTemplate(searchBar,"SearchBoxTemplate"):Clone()
 box.Name="_InventoryV2Search"
 box.Visible=true
 box.Text=state.Search or ""
 box.ZIndex=searchBar.ZIndex+8
 box.Parent=searchBar
 local function sync()
  state.Search=box.Text
  if placeholder and placeholder:IsA("TextLabel") then placeholder.Visible=box.Text=="" and not box:IsFocused() end
  onChanged()
 end
 box:GetPropertyChangedSignal("Text"):Connect(sync)
 box.Focused:Connect(function() if placeholder then placeholder.Visible=false end end)
 box.FocusLost:Connect(sync)
 if placeholder and placeholder:IsA("TextLabel") then placeholder.Visible=box.Text=="" end
 return box
end

function InventoryV2.Render(controller,profile,uiState)
 local inventory=uiState.Inventory or {}
 local prototype=controller.Panel:FindFirstChild("InventoryPrototype")
 if not prototype then
  controller:Label(controller.Content,"InventoryPrototype missing",32)
  return
 end

 local state=controller.InventoryV2State
 if type(state)~="table" then
  state={Category="Flowers",Search="",Sort="Rarity",Filter="All",Selected={}}
  controller.InventoryV2State=state
 end
 if not table.find(CATEGORY_ORDER,state.Category) then state.Category="Flowers" end
 if not table.find(SORT_ORDER,state.Sort) then state.Sort="Rarity" end
 if not table.find(FILTER_ORDER,state.Filter) then state.Filter="All" end
 state.Selected=state.Selected or {}
 local plantSlot=tonumber(controller.InventoryPlantSlot)
 if plantSlot and (plantSlot%1~=0 or plantSlot<1) then
  controller.InventoryPlantSlot=nil
  plantSlot=nil
 end

 local all=buildItems(profile,inventory)
 local shellRoot=prototype:Clone()
 shellRoot.Name="InventoryV2Runtime"
 shellRoot.Visible=true
 shellRoot.Position=UDim2.fromScale(0,0)
 shellRoot.Size=UDim2.fromScale(1,1)
 shellRoot.LayoutOrder=1
 shellRoot.Parent=controller.Content

 local components=shellRoot:WaitForChild("Components")
 components.Visible=false
 local cardTemplate=components:WaitForChild("ItemCardTemplate")
 local shell=shellRoot:WaitForChild("InventoryShell")
 local categories=shell:WaitForChild("CategoryPanel")
 local browser=shell:WaitForChild("BrowserPanel")
 local details=shell:WaitForChild("DetailsPanel")
 local grid=browser:WaitForChild("ItemGrid")
 local searchBar=browser:WaitForChild("SearchBar")
 local sortButton=browser:WaitForChild("SortButton")
 local filterButton=browser:WaitForChild("FilterButton")
 local sectionTitle=browser:WaitForChild("SectionTitle")
 local sectionCount=browser:WaitForChild("SectionCount")

 for _,child in ipairs(grid:GetChildren()) do
  if child:IsA("GuiButton") or child.Name=="_EmptyState" then child:Destroy() end
 end

 local totalFlowers=countMap(Flowers.Species)
 local totalBees=countMap(Bees.GetAll())
 local counts={
  Flowers={#all.Flowers,totalFlowers},
  Bees={#all.Bees,totalBees},
  Seeds={#all.Seeds,totalFlowers},
  Resources={#all.Resources,#all.Resources},
  Special={#all.Special,3},
 }

 local function rerender()
  if controller.MenuRenderer=="InventoryV2" then controller:RenderMenu() end
 end

 for _,category in ipairs(CATEGORY_ORDER) do
  local frame=categories:FindFirstChild("Category_"..category)
  if frame then
   local countLabel=frame:FindFirstChild("Count")
   if countLabel and countLabel:IsA("TextLabel") then countLabel.Text=tostring(counts[category][1]).." / "..tostring(counts[category][2]) end
   local selected=state.Category==category
   local stroke=frame:FindFirstChildOfClass("UIStroke")
   if stroke then
    stroke.Color=selected and C.Blue or C.BorderSoft
    stroke.Thickness=selected and 2 or 1
    stroke.Transparency=selected and .02 or .35
   end
   frame.BackgroundTransparency=selected and .02 or .14
   overlayButton(frame,function()
    state.Category=category
    state.Search=""
    state.Filter="All"
    rerender()
   end)
  end
 end

 sortButton.Text=SORT_LABELS[state.Sort] or SORT_LABELS.Rarity
 sortButton.Activated:Connect(function()
  state.Sort=cycle(SORT_ORDER,state.Sort)
  rerender()
 end)
 local filterAllowed=state.Category=="Flowers" or state.Category=="Seeds"
 filterButton.Visible=filterAllowed
 filterButton.Text=FILTER_LABELS[state.Filter] or FILTER_LABELS.All
 filterButton.Activated:Connect(function()
  state.Filter=cycle(FILTER_ORDER,state.Filter)
  rerender()
 end)

 sectionTitle.Text=CATEGORY_TITLES[state.Category] or string.upper(state.Category)
 if plantSlot and state.Category=="Flowers" then
  sectionTitle.Text="FLOWERS  •  GARDEN SLOT "..tostring(plantSlot)
 end

 local function drawDetails(item)
  if not item then
   details.Visible=false
   return
  end
  details.Visible=true
  local color=rarityColor(item.Rarity)
  local itemName=details:FindFirstChild("ItemName")
  if itemName and itemName:IsA("TextLabel") then itemName.Text=item.DisplayName end
  local fav=details:FindFirstChild("Favorite")
  if fav and fav:IsA("TextLabel") then
   fav.Visible=item.Kind=="Flower" or item.Kind=="Seed"
   fav.Text=item.Favorite and "★" or "☆"
  end
  local badge=details:FindFirstChild("RarityBadge")
  if badge then
   local badgeText=badge:FindFirstChild("Text")
   if badgeText and badgeText:IsA("TextLabel") then badgeText.Text=string.upper(item.Rarity or item.Kind) end
   badge.BackgroundColor3=color
   local st=badge:FindFirstChildOfClass("UIStroke") if st then st.Color=color end
  end
  local preview=details:FindFirstChild("PreviewCard")
  if preview then
   local icon=preview:FindFirstChild("ItemIcon")
   if icon and icon:IsA("ImageLabel") then icon.Image=item.Icon or "" end
   local glow=preview:FindFirstChild("PreviewGlow")
   if glow and glow:IsA("Frame") then glow.BackgroundColor3=color end
   local tag=preview:FindFirstChild("Tag")
   if tag and tag:IsA("TextLabel") then tag.Text=state.Category=="Seeds" and "SEED" or string.upper(item.Kind) end
  end

  local description=details:FindFirstChild("Description")
  if description and description:IsA("TextLabel") then
   if item.Kind=="Flower" or item.Kind=="Seed" then
    if plantSlot then
     description.Text=item.DisplayName.." • "..item.Rarity..". Choose an available copy for Garden Slot "..tostring(plantSlot).."."
    else
     description.Text=item.DisplayName.." • "..item.Rarity..". Plant a free copy, protect rare items, and upgrade Mastery with Petal Dust."
    end
   elseif item.Kind=="Bee" then
    local ability=Bees.GetAbilityDescription(item.Id)
    local passive=Bees.GetPassiveDescription(item.Id)
    local traits=#(item.Traits or {})>0 and table.concat(item.Traits,", ") or "None"
    local preview=traitEquipPreview(item,inventory)
    description.Text="1/N: "..tostring(item.Odds or "1/—").."  •  Traits: "..traits.."  •  "..passive.."  •  "..ability.."  •  Mastery: "..tostring(item.Mastery.BonusText or "No mastery bonus yet").."  •  Equip preview: "..preview
   elseif item.Kind=="Resource" then
    description.Text=item.Description or "A Bloom RNG progression resource."
   else
    description.Text="A seasonal keepsake that preserves the selected item as part of long-term progression."
   end
  end

  local stats=details:FindFirstChild("StatsCard")
  if stats then
   local ownedLabel=stats:FindFirstChild("OwnedLabel")
   local ownedValue=stats:FindFirstChild("OwnedValue")
   local freeLabel=stats:FindFirstChild("FreeLabel")
   local freeValue=stats:FindFirstChild("FreeValue")
   local masteryLabel=stats:FindFirstChild("MasteryLabel")
   local masteryLevel=stats:FindFirstChild("MasteryLevel")
   local masteryTrack=stats:FindFirstChild("MasteryTrack")
   local masteryXP=stats:FindFirstChild("MasteryXP")
   if item.Kind=="Flower" or item.Kind=="Seed" then
    if ownedLabel then ownedLabel.Text="Owned" end
    if ownedValue then ownedValue.Text=tostring(item.Kind=="Seed" and (item.Count+item.Planted) or item.Count).."" end
    if freeLabel then freeLabel.Text="Available" end
    if freeValue then freeValue.Text=tostring(item.Free).."" end
    if masteryLabel then masteryLabel.Text="Mastery" end
    if masteryLevel then masteryLevel.Text="Lv. "..tostring(item.Mastery.Level or 1) end
    if masteryTrack then
     masteryTrack.Visible=true
     local fill=masteryTrack:FindFirstChild("MasteryFill")
     local nextXP=math.max(1,tonumber(item.Mastery.NextXP) or 1)
     if fill and fill:IsA("Frame") then fill.Size=UDim2.fromScale(math.clamp((tonumber(item.Mastery.XP) or 0)/nextXP,0,1),1) end
    end
    if masteryXP then masteryXP.Text=tostring(item.Mastery.XP or 0).." / "..tostring(item.Mastery.NextXP or 0) end
   elseif item.Kind=="Bee" then
    if ownedLabel then ownedLabel.Text="Owned" end
    if ownedValue then ownedValue.Text=tostring(item.Count).."" end
    if freeLabel then freeLabel.Text="Equipped" end
    if freeValue then freeValue.Text=tostring(item.Equipped or 0).."" end
    if masteryLabel then masteryLabel.Text="Bee Mastery" end
    if masteryLevel then masteryLevel.Text="Lv. "..tostring(item.Mastery.Level or 1).." / "..tostring(item.Mastery.Cap or 10) end
    if masteryTrack then
     masteryTrack.Visible=true
     local fill=masteryTrack:FindFirstChild("MasteryFill")
     if fill and fill:IsA("Frame") then fill.Size=UDim2.fromScale(math.clamp(tonumber(item.Mastery.Progress) or 0,0,1),1) end
    end
    if masteryXP then
     masteryXP.Text=item.Mastery.IsMax and ("MAX • "..tostring(item.Mastery.BonusText or "")) or (compact(item.Mastery.XP).." / "..compact(item.Mastery.NextXP).." XP • NEXT "..tostring(item.Mastery.NextRewardText or ""))
    end
   else
    if ownedLabel then ownedLabel.Text=item.Kind=="Resource" and "Amount" or "Slot" end
    if ownedValue then ownedValue.Text=item.Kind=="Resource" and compact(item.Count) or tostring(item.Slot or "Keepsake") end
    if freeLabel then freeLabel.Text="" end
    if freeValue then freeValue.Text="" end
    if masteryLabel then masteryLabel.Text="" end
    if masteryLevel then masteryLevel.Text="" end
    if masteryTrack then masteryTrack.Visible=false end
    if masteryXP then masteryXP.Text="" end
   end
  end

  local plant=details:FindFirstChild("PlantButton")
  local favorite=details:FindFirstChild("FavoriteButton")
  local protect=details:FindFirstChild("ProtectButton")
  local dissolve=details:FindFirstChild("DissolveButton")
  local mastery=details:FindFirstChild("MasteryButton")

  if item.Kind=="Flower" or item.Kind=="Seed" then
   if plantSlot then
    local canPlant=(item.Free or 0)>0
    setButton(plant,true,canPlant and ("PLANT IN SLOT "..tostring(plantSlot)) or "NO FREE COPY",canPlant,function()
     controller.LastSeed=item.Id
     controller.PendingPlantFlowerId=item.Id
     controller:Send("Plant",plantSlot,item.Id)
    end)
   else
    local slot=firstFreeGardenSlot(profile)
    local canPrepare=(item.Free or 0)>0 and slot~=nil
    setButton(plant,true,canPrepare and "PLANT AT GARDEN" or ((item.Free or 0)<=0 and "NO FREE COPY" or "NO FREE PLOT"),canPrepare,function()
     controller.LastSeed=item.Id
     controller:Close()
     controller:Toast("Flower selected. Go to an unlocked garden pad and use its Plant prompt.")
    end)
   end
   setButton(favorite,true,item.Favorite and "★  REMOVE FAVORITE" or "★  FAVORITE",true,function() controller:Send("Flag",item.Id,"FavoriteFlowers") end)
   setButton(protect,true,item.Protected and "◆  UNPROTECT" or "◆  PROTECT",true,function() controller:Send("Flag",item.Id,"LockedFlowers") end)
   setButton(dissolve,true,"DISSOLVE ×1",item.CanDissolve==true,function() controller:Send("Dissolve",item.Id,1) end)
   setButton(mastery,true,"MASTERY +"..tostring(item.Mastery.Cost or "").." DUST",item.CanUpgrade==true,function() controller:Send("FlowerUpgrade",item.Id) end)
  elseif item.Kind=="Bee" then
   local slots=inventory.EquippedBeeSlots or (profile.Pollinators and profile.Pollinators.EquippedBeeSlots) or {}
   local equippedSlot=findEquippedSlot(slots,item.Id)
   if equippedSlot then
    setButton(plant,true,"UNEQUIP BEE",true,function() controller:Send("EquipBee","",equippedSlot) end)
   else
    local slot=firstFreeBeeSlot(slots,inventory.BeeCapacity)
    setButton(plant,true,slot and "EQUIP" or "SLOTS FULL",slot~=nil,function() controller:Send("EquipBee",item.Id,slot) end)
   end
   setButton(favorite,false)
   setButton(protect,false)
   setButton(dissolve,true,"DISMANTLE ×1  •  +"..tostring(item.DissolveValue or 0).." DUST",item.CanDissolve==true,function() controller:Send("DissolveBee",item.Id,1) end)
   setButton(mastery,false)
  elseif item.Kind=="Resource" and item.Id=="AncientNectar" then
   setButton(plant,false)
   setButton(favorite,false)
   setButton(protect,false)
   local label=item.DistillUnlocked and ("DISTILL "..tostring(item.DistillCost or 1).." NECTAR  →  +"..tostring(item.DistillDust or 0).." DUST") or "COMPLETE LEGACY TO DISTILL"
   setButton(dissolve,true,label,item.CanDistill==true,function() controller:Send("DistillNectar") end)
   setButton(mastery,false)
  else
   setButton(plant,false)
   setButton(favorite,false)
   setButton(protect,false)
   setButton(dissolve,false)
   setButton(mastery,false)
  end
 end

 local function refreshGrid()
  for _,child in ipairs(grid:GetChildren()) do
   if child:IsA("GuiButton") or child.Name=="_EmptyState" then child:Destroy() end
  end
  local visible=filteredItems(all[state.Category] or {},state.Search,state.Filter,state.Sort)
  sectionCount.Text=tostring(#visible).." ITEMS"
  local selectedId=state.Selected[state.Category]
  local active=nil
  for _,item in ipairs(visible) do if item.Id==selectedId then active=item break end end
  if not active then active=visible[1] end
  if active then state.Selected[state.Category]=active.Id end

  if #visible==0 then
   local empty=componentTemplate(grid,"EmptyStateTemplate"):Clone()
   empty.Name="_EmptyState"
   empty.Visible=true
   empty.ZIndex=grid.ZIndex+2
   empty.Parent=grid
   drawDetails(nil)
   return
  end

  for index,item in ipairs(visible) do
   local card=cardTemplate:Clone()
   card.Name="Item_"..item.Id:gsub("[^%w_]","_")
   card.Visible=true
   card.LayoutOrder=index
   card.Parent=grid
   local selected=active and active.Id==item.Id
   local color=rarityColor(item.Rarity)
   local stroke=card:FindFirstChildOfClass("UIStroke")
   if stroke then
    stroke.Color=selected and C.Blue or color
    stroke.Thickness=selected and 2.2 or 1
    stroke.Transparency=selected and 0 or .28
   end
   local glow=card:FindFirstChild("TopGlow")
   if glow and glow:IsA("Frame") then glow.BackgroundColor3=color end
   local icon=card:FindFirstChild("Icon")
   if icon and icon:IsA("ImageLabel") then icon.Image=item.Icon or "" end
   local count=card:FindFirstChild("Count")
   if count and count:IsA("TextLabel") then
    count.Text=(item.Kind=="Flower" or item.Kind=="Seed" or item.Kind=="Bee") and tostring(item.Odds or "1/—") or "x"..compact(item.Count)
   end
   local name=card:FindFirstChild("Name")
   if name and name:IsA("TextLabel") then name.Text=item.DisplayName end
   local rarity=card:FindFirstChild("Rarity")
   if rarity and rarity:IsA("TextLabel") then
    if item.Kind=="Bee" then rarity.Text="M "..tostring(item.Mastery and item.Mastery.Level or 1)
    elseif item.Kind=="Flower" or item.Kind=="Seed" then rarity.Text="LV "..tostring(item.Mastery and item.Mastery.Level or 1)
    else rarity.Text=string.upper(item.Rarity or "") end
    rarity.TextColor3=color
   end
   local fav=card:FindFirstChild("Favorite")
   if fav and fav:IsA("TextLabel") then
    fav.Visible=item.Kind=="Flower" or item.Kind=="Seed"
    fav.Text=item.Favorite and "★" or (item.Protected and "◆" or "")
    fav.TextColor3=item.Protected and C.Blue or C.Gold
   end
   local marker=card:FindFirstChild("SelectedMarker")
   if marker and marker:IsA("GuiObject") then marker.Visible=selected end
   card.Activated:Connect(function()
    state.Selected[state.Category]=item.Id
    refreshGrid()
   end)
  end
  drawDetails(active)
 end

 setupSearch(searchBar,state,refreshGrid)
 refreshGrid()
end

return InventoryV2
