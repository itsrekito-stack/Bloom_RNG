local RS=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")

local Flowers=require(RS.Config.FlowersConfig)
local Bees=require(RS.Config.BeesConfig)
local Icons=require(RS.Config.IconsConfig)
local Rarity=require(RS.Config.RarityConfig)
local GardenSynergy=require(RS.Config.GardenSynergyConfig)
local Theme=require(RS.Config.UIThemeConfig)

local C=Theme.Colors
local InventoryV2={}

local CATEGORY_ORDER={"Bees","Resources","Special"}
local CATEGORY_TITLES={Bees="BEES",Resources="RESOURCES",Special="SPECIAL"}
local SORT_ORDER={"Rarity","Name","Count"}
local SORT_LABELS={Rarity="RARITY  ˅",Name="NAME  ˅",Count="COUNT  ˅"}

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

local PASSIVE_ORDER={
 "CoinMultiplier","PollinatorYieldMultiplier","PollinatorPowerMultiplier","PollinatorTravelSpeedMultiplier",
 "LuckMultiplier","FlowerGrowthMultiplier","HiveHoneyMultiplier","BeeMasteryXPMultiplier","AbilityCooldownMultiplier",
}

local function passiveIcon(stat)
 if stat=="CoinMultiplier" then return Icons.GetCurrencyIcon("Coins") end
 if stat=="PollinatorYieldMultiplier" then return Icons.Get("System","Bee") end
 if stat=="PollinatorPowerMultiplier" then return Icons.Get("System","Upgrade") end
 if stat=="PollinatorTravelSpeedMultiplier" then return Icons.Get("System","ArrowRight") end
 if stat=="LuckMultiplier" then return Icons.Get("WorkshopHex","Luck") end
 if stat=="FlowerGrowthMultiplier" then return Icons.Get("System","Flower") end
 if stat=="HiveHoneyMultiplier" then return Icons.Get("System","Hive") end
 if stat=="BeeMasteryXPMultiplier" then return Icons.Get("WorkshopHex","Mastery") end
 if stat=="AbilityCooldownMultiplier" then return Icons.Get("WorkshopHex","AutoRoll") end
 return Icons.Get("System","Bee")
end

local function passivePercent(stat,value)
 local multiplier=tonumber(value) or 1
 local delta=(multiplier-1)*100
 if stat=="AbilityCooldownMultiplier" and multiplier<1 then
  return "-"..tostring(math.floor((1-multiplier)*100+.5)).."%"
 end
 local rounded=math.floor(math.abs(delta)+.5)
 return (delta>=0 and "+" or "-")..tostring(rounded).."%"
end

local function equippedCount(slots)
 local n=0
 for _,id in pairs(slots or {}) do
  if type(id)=="string" and id~="" then n+=1 end
 end
 return n
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

local function autoReplaceBeeSlot(slots,capacity,newId)
 local newBee=Bees.Get(newId)
 local newRank=newBee and (Rarity.Rank[newBee.Rarity] or 0) or 0
 local bestSlot=nil
 local bestRank=math.huge
 for i=1,(tonumber(capacity) or 0) do
  local equippedId=slots[i]
  local equipped=Bees.Get(equippedId)
  local rank=equipped and (Rarity.Rank[equipped.Rarity] or 0) or 0
  if equipped and rank<newRank and (rank<bestRank or (rank==bestRank and (bestSlot==nil or i<bestSlot))) then
   bestSlot=i
   bestRank=rank
  end
 end
 return bestSlot
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
 local target=firstFreeBeeSlot(slots,inventory.BeeCapacity)
 local replacedId=nil
 if not target then
  target=autoReplaceBeeSlot(slots,inventory.BeeCapacity,item.Id)
  if not target then return "All equipped Bees are equally or more rare" end
  replacedId=slots[target]
 end
 local before=Bees.GetTraitState(slots)
 slots[target]=item.Id
 local after=Bees.GetTraitState(slots)
 local byId={} for _,state in ipairs(before) do byId[state.Id]=state end
 local changes={}
 if replacedId then
  local replaced=Bees.Get(replacedId)
  table.insert(changes,"Replaces "..(replaced and replaced.DisplayName or replacedId))
 end
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
 local out={Bees={},Resources={},Special={}}
 for _,entry in ipairs(inventory.Bees or {}) do
  local cfg=Bees.Get(entry.Id)
  if cfg then
   table.insert(out.Bees,{
    Kind="Bee",Id=entry.Id,DisplayName=entry.DisplayName or cfg.DisplayName,Rarity=entry.Rarity or cfg.Rarity,
    Count=entry.Count or 0,Obtained=entry.Obtained or entry.Count or 0,Equipped=entry.Equipped or 0,Free=entry.Free or 0,CanDissolve=false,DissolveValue=0,
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
  {Id="PetalDust",DisplayName="Petal Dust",Count=currencies.PetalDust or 0,Description="A world and seasonal resource used by progression systems and Workshop upgrades."},
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
  if item.Kind=="Flower" then return (item.Planted or 0)==0 end
  if item.Kind=="Bee" then return (item.Equipped or 0)==0 end
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

local function matchesTrait(item,traitId)
 if not traitId or traitId=="" then return true end
 if item.Kind~="Bee" then return true end
 return table.find(item.Traits or {},traitId)~=nil
end

local function filteredItems(source,search,filter,sortMode,traitId)
 local out={}
 local q=normalized(search)
 for _,item in ipairs(source or {}) do
  local match=q=="" or string.find(normalized(item.DisplayName),q,1,true) or string.find(normalized(item.Id),q,1,true)
  if match and matchesFilter(item,filter) and matchesTrait(item,traitId) then table.insert(out,item) end
 end
 sortItems(out,sortMode)
 return out
end

local function availableTraits(bees)
 local seen={}
 for _,item in ipairs(bees or {}) do
  for _,traitId in ipairs(item.Traits or {}) do seen[traitId]=true end
 end
 local out={}
 for traitId in pairs(seen) do out[#out+1]=traitId end
 table.sort(out,function(a,b)
  local ta,tb=Bees.GetTrait(a),Bees.GetTrait(b)
  return tostring(ta and ta.Name or a)<tostring(tb and tb.Name or b)
 end)
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
  state={Category="Bees",Search="",Sort="Rarity",Filter="All",TraitFilter=nil,TraitPanelOpen=false,Selected={}}
  controller.InventoryV2State=state
 end
 if not table.find(CATEGORY_ORDER,state.Category) then state.Category="Bees" end
 if not table.find(SORT_ORDER,state.Sort) then state.Sort="Rarity" end
 if state.Filter==nil then state.Filter="All" end
 state.Selected=state.Selected or {}
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
 local gridLayout=grid:FindFirstChildOfClass("UIGridLayout")
 local searchBar=browser:WaitForChild("SearchBar")
 local sortButton=browser:WaitForChild("SortButton")
 local filterButton=browser:WaitForChild("FilterButton")
 local unequipAllButton=browser:WaitForChild("UnequipAllButton")
 local traitPanel=browser:WaitForChild("TraitFilterPanel")
 local traitList=traitPanel:WaitForChild("TraitFilterList")
 local traitTemplate=traitList:WaitForChild("TraitChipTemplate")
 local sectionTitle=browser:WaitForChild("SectionTitle")
 local sectionCount=browser:WaitForChild("SectionCount")
 for _,child in ipairs(grid:GetChildren()) do
  if child:IsA("GuiButton") or child.Name=="_EmptyState" then child:Destroy() end
 end

 local totalBees=countMap(Bees.GetAll())
 local counts={
  Bees={#all.Bees,totalBees},
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
    state.TraitFilter=nil
    state.TraitPanelOpen=false
    rerender()
   end)
  end
 end

 sortButton.Text=SORT_LABELS[state.Sort] or SORT_LABELS.Rarity
 sortButton.Activated:Connect(function()
  state.Sort=cycle(SORT_ORDER,state.Sort)
  rerender()
 end)
 local traitIds=availableTraits(all.Bees)
 local selectedTrait=state.TraitFilter and Bees.GetTrait(state.TraitFilter) or nil
 filterButton.Visible=state.Category=="Bees"
 filterButton.Text=selectedTrait and ("TRAITS • "..tostring(selectedTrait.Name)) or "TRAITS"
 traitPanel.Visible=state.Category=="Bees" and state.TraitPanelOpen==true
 for _,child in ipairs(traitList:GetChildren()) do
  if child:GetAttribute("TraitFilterRuntime") then child:Destroy() end
 end
 local function addTraitChip(label,traitId,order)
  local chip=traitTemplate:Clone()
  chip.Name=traitId and ("Trait_"..traitId) or "Trait_All"
  chip.Text=label
  chip.LayoutOrder=order
  chip.Visible=true
  chip:SetAttribute("TraitFilterRuntime",true)
  local selected=state.TraitFilter==traitId
  chip.BackgroundColor3=selected and C.Blue or C.Panel
  local stroke=chip:FindFirstChildOfClass("UIStroke")
  if stroke then stroke.Color=selected and C.Blue or C.BorderSoft stroke.Transparency=selected and .02 or .32 end
  chip.Activated:Connect(function()
   state.TraitFilter=traitId
   state.TraitPanelOpen=false
   rerender()
  end)
  chip.Parent=traitList
 end
 addTraitChip("ALL TRAITS",nil,1)
 for index,traitId in ipairs(traitIds) do
  local trait=Bees.GetTrait(traitId)
  addTraitChip(tostring(trait and trait.Name or traitId),traitId,index+1)
 end
 filterButton.Activated:Connect(function()
  if state.Category~="Bees" then return end
  state.TraitPanelOpen=not state.TraitPanelOpen
  traitPanel.Visible=state.TraitPanelOpen
 end)

 sectionTitle.Text=CATEGORY_TITLES[state.Category] or string.upper(state.Category)
 local equippedSlots=inventory.EquippedBeeSlots or (profile.Pollinators and profile.Pollinators.EquippedBeeSlots) or {}
 local equippedTotal=equippedCount(equippedSlots)
 setButton(
  unequipAllButton,
  state.Category=="Bees",
  equippedTotal>0 and ("UNEQUIP ALL  •  "..tostring(equippedTotal)) or "UNEQUIP ALL",
  equippedTotal>0,
  function() controller:Send("UnequipAllBees") end
 )

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
   fav.Visible=item.Kind=="Flower"
   fav.Text=item.Favorite and "★" or "☆"
  end
  local badge=details:FindFirstChild("RarityBadge")
  if badge then
   local badgeText=badge:FindFirstChild("Text")
   if badgeText and badgeText:IsA("TextLabel") then
    badgeText.Text=string.upper(item.Rarity or item.Kind)
    badgeText.TextColor3=color
   end
   badge.BackgroundColor3=C.Panel
   local st=badge:FindFirstChildOfClass("UIStroke") if st then st.Color=color st.Transparency=.06 end
  end
  local preview=details:FindFirstChild("PreviewCard")
  if preview then
   local icon=preview:FindFirstChild("ItemIcon")
   if icon and icon:IsA("ImageLabel") then icon.Image=item.Icon or "" end
   local glow=preview:FindFirstChild("PreviewGlow")
   if glow and glow:IsA("Frame") then glow.BackgroundColor3=color end
   local tag=preview:FindFirstChild("Tag")
   if tag and tag:IsA("TextLabel") then tag.Text=string.upper(item.Kind) end
  end

  local description=details:FindFirstChild("Description")
  local beeSummary=details:FindFirstChild("BeeSummary")
  local stats=details:FindFirstChild("StatsCard")
  local isBee=item.Kind=="Bee"
  if description and description:IsA("TextLabel") then
   description.Visible=not isBee
   if item.Kind=="Flower" then
    local synergyId=uiState.Garden and uiState.Garden.ActiveSynergy or ""
    local synergyName="None"
    for _,recipe in ipairs(GardenSynergy.Recipes or {}) do
     if recipe.Id==synergyId then synergyName=recipe.Name or recipe.Id break end
    end
    description.Text=item.DisplayName.." • "..item.Rarity.." • 1/N: "..tostring(item.Odds or "1/—").." • Level "..tostring(item.Mastery.Level or 1).." • Current Synergy: "..synergyName..". Duplicate rolls increase this Flower species Level."
   elseif item.Kind=="Bee" then
    description.Text=""
   elseif item.Kind=="Resource" then
    description.Text=item.Description or "A Bloom RNG progression resource."
   else
    description.Text="A seasonal keepsake that preserves the selected item as part of long-term progression."
   end
  end

  if beeSummary and beeSummary:IsA("GuiObject") then
   beeSummary.Visible=isBee
   local passiveList=beeSummary:FindFirstChild("PassiveList")
   local passiveTemplate=passiveList and passiveList:FindFirstChild("PassiveRowTemplate")
   local abilityDescription=beeSummary:FindFirstChild("AbilityDescription")
   if passiveList then
    for _,child in ipairs(passiveList:GetChildren()) do
     if child:GetAttribute("BeePassiveRuntime") then child:Destroy() end
    end
   end
   if isBee and passiveList and passiveTemplate and passiveTemplate:IsA("Frame") then
    local bee=Bees.Get(item.Id)
    local passive=bee and bee.Passive or {}
    local seen={}
    local order=0
    local function addPassive(stat,value)
     if seen[stat] or tonumber(value)==nil then return end
     seen[stat]=true
     order+=1
     local row=passiveTemplate:Clone()
     row.Name="Passive_"..tostring(stat)
     row.LayoutOrder=order
     row.Visible=true
     row:SetAttribute("BeePassiveRuntime",true)
     local icon=row:FindFirstChild("Icon")
     local valueLabel=row:FindFirstChild("Value")
     if icon and icon:IsA("ImageLabel") then icon.Image=passiveIcon(stat) end
     if valueLabel and valueLabel:IsA("TextLabel") then valueLabel.Text=passivePercent(stat,value) end
     row.Parent=passiveList
    end
    for _,stat in ipairs(PASSIVE_ORDER) do
     if passive[stat]~=nil then addPassive(stat,passive[stat]) end
    end
    local extras={}
    for stat in pairs(passive) do if not seen[stat] then extras[#extras+1]=stat end end
    table.sort(extras)
    for _,stat in ipairs(extras) do addPassive(stat,passive[stat]) end
    if abilityDescription and abilityDescription:IsA("TextLabel") then
     abilityDescription.Text=Bees.GetAbilityDescription(item.Id)
    end
   end
  end

  if stats then
   stats.Visible=not isBee
   local ownedLabel=stats:FindFirstChild("OwnedLabel")
   local ownedValue=stats:FindFirstChild("OwnedValue")
   local freeLabel=stats:FindFirstChild("FreeLabel")
   local freeValue=stats:FindFirstChild("FreeValue")
   local masteryLabel=stats:FindFirstChild("MasteryLabel")
   local masteryLevel=stats:FindFirstChild("MasteryLevel")
   local masteryTrack=stats:FindFirstChild("MasteryTrack")
   local masteryXP=stats:FindFirstChild("MasteryXP")
   if item.Kind=="Flower" then
    if ownedLabel then ownedLabel.Text="Obtained" end
    if ownedValue then ownedValue.Text=tostring(item.Obtained or 1) end
    if freeLabel then freeLabel.Text="Garden" end
    if freeValue then freeValue.Text=(item.Planted or 0)>0 and "Planted" or "Available" end
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
    if ownedLabel then ownedLabel.Text="Obtained" end
    if ownedValue then ownedValue.Text=tostring(item.Obtained or 1) end
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

  if item.Kind=="Bee" then
   local slots=equippedSlots
   local equippedSlot=findEquippedSlot(slots,item.Id)
   if equippedSlot then
    setButton(plant,true,"UNEQUIP BEE",true,function() controller:Send("EquipBee","",equippedSlot) end)
   else
    local slot=firstFreeBeeSlot(slots,inventory.BeeCapacity)
    setButton(plant,true,"EQUIP",true,function() controller:Send("EquipBee",item.Id,slot) end)
   end
   setButton(favorite,false)
   setButton(protect,false)
   setButton(dissolve,false)
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
  local visible=filteredItems(all[state.Category] or {},state.Search,state.Filter,state.Sort,state.Category=="Bees" and state.TraitFilter or nil)
  sectionCount.Text=tostring(#visible).." ITEMS"
  local cellWidth=gridLayout and gridLayout.CellSize.X.Offset or math.max(1,cardTemplate.Size.X.Offset)
  local cellHeight=gridLayout and gridLayout.CellSize.Y.Offset or math.max(1,cardTemplate.Size.Y.Offset)
  local gapX=gridLayout and gridLayout.CellPadding.X.Offset or 9
  local gapY=gridLayout and gridLayout.CellPadding.Y.Offset or 9
  local usableWidth=math.max(cellWidth,grid.AbsoluteSize.X-8)
  local columns=math.max(1,math.floor((usableWidth+gapX)/(cellWidth+gapX)))
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
   local zeroIndex=index-1
   local column=zeroIndex%columns
   local row=math.floor(zeroIndex/columns)
   card.Position=UDim2.fromOffset(1+column*(cellWidth+gapX),1+row*(cellHeight+gapY))
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
   local traitNames=card:FindFirstChild("Traits")
   if rarity and rarity:IsA("TextLabel") then
    if item.Kind=="Bee" then rarity.Text="M "..tostring(item.Mastery and item.Mastery.Level or 1)
    elseif item.Kind=="Flower" or item.Kind=="Seed" then rarity.Text="LV "..tostring(item.Mastery and item.Mastery.Level or 1)
    else rarity.Text=string.upper(item.Rarity or "") end
    rarity.TextColor3=color
   end
   if traitNames and traitNames:IsA("TextLabel") then
    traitNames.Visible=item.Kind=="Bee"
    traitNames.Text=item.Kind=="Bee" and string.upper(table.concat(item.Traits or {}," • ")) or ""
   end
   local fav=card:FindFirstChild("Favorite")
   if fav and fav:IsA("TextLabel") then
    fav.Visible=item.Kind=="Flower" or item.Kind=="Seed"
    fav.Text=item.Favorite and "★" or (item.Protected and "◆" or "")
    fav.TextColor3=item.Protected and C.Blue or C.Gold
   end
   local marker=card:FindFirstChild("SelectedMarker")
   if marker and marker:IsA("GuiObject") then marker.Visible=selected end
   local equippedBadge=card:FindFirstChild("EquippedBadge")
   local equippedSlot=item.Kind=="Bee" and findEquippedSlot(equippedSlots,item.Id) or nil
   if equippedBadge and equippedBadge:IsA("TextLabel") then
    equippedBadge.Visible=equippedSlot~=nil
    equippedBadge.Text=equippedSlot and ("EQUIPPED  •  S"..tostring(equippedSlot)) or ""
   end
   local hoverScale=card:FindFirstChild("InventoryHoverScale")
   if hoverScale and hoverScale:IsA("UIScale") then
    card.MouseEnter:Connect(function()
     TweenService:Create(hoverScale,TweenInfo.new(Theme.Motion.Fast),{Scale=1.04}):Play()
     if stroke then TweenService:Create(stroke,TweenInfo.new(Theme.Motion.Fast),{Thickness=selected and 2.6 or 1.8,Transparency=0}):Play() end
    end)
    card.MouseLeave:Connect(function()
     TweenService:Create(hoverScale,TweenInfo.new(Theme.Motion.Fast),{Scale=1}):Play()
     if stroke then TweenService:Create(stroke,TweenInfo.new(Theme.Motion.Fast),{Thickness=selected and 2.2 or 1,Transparency=selected and 0 or .28}):Play() end
    end)
   end
   card.Activated:Connect(function()
    state.Selected[state.Category]=item.Id
    refreshGrid()
   end)
  end
  if not gridLayout then
   local rows=math.ceil(#visible/columns)
   grid.AutomaticCanvasSize=Enum.AutomaticSize.None
   grid.CanvasSize=UDim2.fromOffset(0,math.max(0,rows*cellHeight+math.max(0,rows-1)*gapY+14))
  else
   grid.AutomaticCanvasSize=Enum.AutomaticSize.Y
  end
  drawDetails(active)
 end

 setupSearch(searchBar,state,refreshGrid)
 refreshGrid()
end

return InventoryV2
