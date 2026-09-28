local RS=game:GetService("ReplicatedStorage")

local Flowers=require(RS.Config.FlowersConfig)
local Bees=require(RS.Config.BeesConfig)
local Icons=require(RS.Config.IconsConfig)
local Theme=require(RS.Config.UIThemeConfig)

local C=Theme.Colors
local Index={}

local CATEGORY_ORDER={"Flowers","Bees","Synergies","Traits"}
local CATEGORY_TITLES={Flowers="FLOWERS",Bees="BEES",Synergies="FLOWER SYNERGIES",Traits="BEE SYNERGIES"}

local STAT_LABELS={
 FlowerGrowthMultiplier="Flower Growth",
 SplashChance="Splash Chance",
 SplashPercent="Splash Power",
 DualPollinationChance="Dual Pollination",
 DualPollinationPercent="Dual Power",
 PollinatorTravelSpeedMultiplier="Travel Speed",
 AbilityCooldownMultiplier="Ability Cooldown",
 PollinatorYieldMultiplier="Yield",
 HiveHoneyMultiplier="Hive Honey",
 LuckMultiplier="Roll Luck",
 BeeMasteryXPMultiplier="Mastery XP",
 CoinMultiplier="Coins",
 CriticalChance="Critical Chance",
 CriticalMultiplier="Critical Power",
 ClonePowerMultiplier="Clone Power",
 AbilityDurationMultiplier="Ability Duration",
 PollinatorPowerMultiplier="Bee Power",
}

local function iconFor(category,item)
 if category=="Flowers" then return Icons.GetFlowerIcon(item.Id) end
 if category=="Bees" then return Icons.GetBeeIcon(item.Id) end
 if category=="Traits" then
  local icon=Icons.GetTraitIcon(item.Id)
  return icon~="" and icon or Icons.Get("System","Info")
 end
 if category=="Synergies" then return Icons.Get("System","Garden") end
 return Icons.Get("System","Info")
end

local function categoryIcon(category)
 if category=="Flowers" then return Icons.Get("System","Flower") end
 if category=="Bees" then return Icons.Get("System","Bee") end
 if category=="Synergies" then return Icons.Get("System","Garden") end
 if category=="Traits" then
  local icon=Icons.GetTraitIcon("Bloom")
  return icon~="" and icon or Icons.Get("System","Info")
 end
 return Icons.Get("System","Info")
end

local function pctText(progress)
 progress=progress or {}
 return tostring(progress.Unlocked or 0).." / "..tostring(progress.Total or 0).." • "..tostring(progress.Percent or 0).."%"
end

local function bonusValue(key,value)
 value=tonumber(value) or 0
 if string.find(key,"Chance",1,true) or string.find(key,"Percent",1,true) then
  return string.format("+%.0f%%",value*100)
 end
 if string.find(key,"Multiplier",1,true) then
  return string.format("×%.2f",value)
 end
 return tostring(value)
end

local function bonusText(bonus)
 local out={}
 for key,value in pairs(bonus or {}) do
  out[#out+1]=(STAT_LABELS[key] or key).." "..bonusValue(key,value)
 end
 table.sort(out)
 return #out>0 and table.concat(out,", ") or "No effect"
end

local function beeName(id)
 local bee=Bees.Get(id)
 return bee and bee.DisplayName or tostring(id)
end

local function flowerName(id)
 local flower=Flowers.Species[id]
 return flower and flower.DisplayName or tostring(id)
end

local function traitName(id)
 local trait=Bees.GetTrait(id)
 return trait and trait.Name or tostring(id)
end

local function flowerDetail(item)
 local level=math.max(1,math.floor(tonumber(item.Level) or 1))
 local current=Flowers.FormatLevelBuff(item.Id,level)
 local nextBuff=level<100 and Flowers.FormatLevelBuff(item.Id,level+1) or "MAX"
 local body="Level • "..tostring(level).."\n\nPlanted passive • "..current.."\nNext Level • "..nextBuff.."\n\nDuplicate rolls and pollination increase Flower Level, making this passive stronger."
 return tostring(item.Odds or "1/—"),body
end

local function beeDetail(item)
 local mastery=item.Mastery or {}
 local traits={}
 for _,id in ipairs(item.Traits or {}) do traits[#traits+1]=traitName(id) end
 local ability=item.Ability or {}
 local passive=Bees.GetPassiveDescription(item.Id)
 local body={
  "Mastery Lv. "..tostring(mastery.Level or 1),
  "Obtained • "..tostring(item.Obtained or 1),
  "Traits • "..(#traits>0 and table.concat(traits,", ") or "None"),
  "Passive • "..tostring(passive),
  "Ability • "..tostring(ability.Name or "None"),
  tostring(ability.Description or "No ability description."),
 }
 return tostring(item.Odds or "1/—"),table.concat(body,"\n\n")
end

local function synergyDetail(item)
 local species={}
 for _,id in ipairs(item.Species or {}) do
  local required=tonumber(item.LevelRequirements and item.LevelRequirements[id]) or 1
  species[#species+1]=flowerName(id).." • Lv. "..tostring(required)
 end
 local body={
  "Required Flowers",
  #species>0 and table.concat(species,"\n") or "None",
  "",
  "Effect",
  bonusText(item.Effect),
 }
 return "Tier "..tostring(item.Tier or 1).."  •  Strength "..tostring(item.Strength or 0),table.concat(body,"\n")
end

local function traitDetail(item)
 local thresholds={}
 for tier,bp in ipairs(item.Breakpoints or {}) do
  thresholds[#thresholds+1]="Tier "..tostring(tier).." • "..tostring(bp.Count or 0).." Bees • "..bonusText(bp.Bonus)
 end
 local biome={}
 for key,value in pairs(item.BiomeModifiers or {}) do biome[#biome+1]=tostring(key).." • "..tostring(value) end
 table.sort(biome)
 local body={
  tostring(item.Description or ""),
  "",
  "Tier thresholds",
  #thresholds>0 and table.concat(thresholds,"\n") or "None",
  "",
  "Matching Bees",
  "Shown as icons above. Equip a matching loadout directly from this entry.",
  "",
  "Biome modifiers",
  #biome>0 and table.concat(biome,"\n") or "None in the current release",
 }
 return tostring(#(item.Breakpoints or {})).." tiers",table.concat(body,"\n")
end

local function detailsFor(category,item)
 if category=="Flowers" then return flowerDetail(item) end
 if category=="Bees" then return beeDetail(item) end
 if category=="Synergies" then return synergyDetail(item) end
 if category=="Traits" then return traitDetail(item) end
 return "",""
end

local function cardMeta(category,item)
 if category=="Flowers" then return tostring(item.Odds or "1/—") end
 if category=="Bees" then return tostring(item.Odds or "1/—") end
 if category=="Synergies" then return "TIER "..tostring(item.Tier or 1) end
 if category=="Traits" then return tostring(#(item.Breakpoints or {})).." TIERS" end
 return ""
end

local function runtimeChildren(container)
 for _,child in ipairs(container:GetChildren()) do
  if child:GetAttribute("IndexRuntime") then child:Destroy() end
 end
end

function Index.Render(controller,profile,uiState)
 local payload=uiState.Index or {}
 local template=controller.Panel:FindFirstChild("IndexPrototype")
 if not template then
  controller:Label(controller.Content,"IndexPrototype missing",32)
  return
 end

 local state=controller.IndexState
 if type(state)~="table" then
  state={Category="Flowers",Selected={}}
  controller.IndexState=state
 end
 if not table.find(CATEGORY_ORDER,state.Category) then state.Category="Flowers" end
 state.Selected=state.Selected or {}

 local root=template:Clone()
 root.Name="IndexRuntime"
 root.Visible=true
 root.Size=UDim2.fromScale(1,1)
 root.Position=UDim2.fromScale(0,0)
 root.LayoutOrder=1
 root.Parent=controller.Content

 local nav=root:WaitForChild("CategoryNav")
 local catalog=root:WaitForChild("CatalogPanel")
 local details=root:WaitForChild("DetailsPanel")
 local grid=catalog:WaitForChild("CatalogGrid")
 local cardTemplate=grid:WaitForChild("IndexCardTemplate")
 local catalogTitle=catalog:WaitForChild("CatalogTitle")
 local catalogProgress=catalog:WaitForChild("CatalogProgress")
 local emptyDetail=details:WaitForChild("EmptyDetail")
 local detail=details:WaitForChild("DetailContent")
 local detailIcon=detail:WaitForChild("DetailIcon")
 local detailName=detail:WaitForChild("DetailName")
 local detailMeta=detail:WaitForChild("DetailMeta")
 local detailScroll=detail:WaitForChild("DetailScroll")
 local detailBody=detailScroll:WaitForChild("DetailBody")
 local traitBeeStrip=detail:WaitForChild("TraitBeeStrip")
 local traitBeeIconTemplate=traitBeeStrip:WaitForChild("TraitBeeIconTemplate")
 local equipSynergyButton=detail:WaitForChild("EquipSynergyButton")

 local function rerender()
  if controller.MenuRenderer=="IndexV1" then controller:RenderMenu(true) end
 end

 for _,category in ipairs(CATEGORY_ORDER) do
  local data=payload[category] or {Items={},Progress={}}
  local button=nav:FindFirstChild("Category_"..category)
  if button and button:IsA("TextButton") then
   local selected=state.Category==category
   local icon=button:FindFirstChild("Icon")
   local name=button:FindFirstChild("Name")
   local progress=button:FindFirstChild("Progress")
   local stroke=button:FindFirstChildOfClass("UIStroke")
   if icon and icon:IsA("ImageLabel") then icon.Image=categoryIcon(category) end
   if name and name:IsA("TextLabel") then name.Text=CATEGORY_TITLES[category] end
   if progress and progress:IsA("TextLabel") then progress.Text=pctText(data.Progress) end
   if stroke then
    stroke.Color=selected and C.Blue or C.BorderSoft
    stroke.Thickness=selected and 2 or 1
    stroke.Transparency=selected and 0.04 or 0.36
   end
   button.BackgroundTransparency=selected and 0.01 or 0.08
   button.Activated:Connect(function()
    state.Category=category
    rerender()
   end)
  end
 end

 local category=state.Category
 local data=payload[category] or {Items={},Progress={}}
 catalogTitle.Text=CATEGORY_TITLES[category] or string.upper(category)
 catalogProgress.Text=pctText(data.Progress)

 runtimeChildren(grid)
 local selectedId=state.Selected[category]
 local selectedItem=nil

 for order,item in ipairs(data.Items or {}) do
  local card=cardTemplate:Clone()
  card.Name="IndexCard_"..tostring(item.Slot or order)
  card.Visible=true
  card.LayoutOrder=item.Slot or order
  card:SetAttribute("IndexRuntime",true)
  card.Parent=grid

  local unlocked=item.Unlocked==true
  local icon=card:FindFirstChild("Icon")
  local lock=card:FindFirstChild("LockIcon")
  local name=card:FindFirstChild("Name")
  local meta=card:FindFirstChild("Meta")
  local newBadge=card:FindFirstChild("NewBadge")
  local stroke=card:FindFirstChildOfClass("UIStroke")
  if icon and icon:IsA("ImageLabel") then
   icon.Visible=unlocked
   icon.Image=unlocked and iconFor(category,item) or ""
  end
  if lock and lock:IsA("ImageLabel") then lock.Visible=not unlocked end
  if name and name:IsA("TextLabel") then
   name.Visible=unlocked
   name.Text=unlocked and tostring(item.Name or item.Id or "") or ""
  end
  if meta and meta:IsA("TextLabel") then
   meta.Visible=unlocked
   meta.Text=unlocked and cardMeta(category,item) or ""
  end
  if newBadge and newBadge:IsA("TextLabel") then newBadge.Visible=unlocked and item.New==true end

  local selected=unlocked and selectedId~=nil and item.Id==selectedId
  if stroke then
   stroke.Color=selected and C.Gold or (unlocked and C.Border or C.BorderSoft)
   stroke.Thickness=selected and 2 or 1
   stroke.Transparency=selected and 0.02 or (unlocked and 0.24 or 0.55)
  end
  card.BackgroundTransparency=unlocked and 0.02 or 0.18
  card.Active=unlocked

  if selected then selectedItem=item end
  if unlocked then
   card.Activated:Connect(function()
    state.Selected[category]=item.Id
    if item.New then controller:Send("IndexViewed",category,item.Id) end
    rerender()
   end)
  end
 end

 if selectedId and not selectedItem then
  for _,item in ipairs(data.Items or {}) do
   if item.Unlocked and item.Id==selectedId then selectedItem=item break end
  end
 end

 if not selectedItem then
  emptyDetail.Visible=true
  detail.Visible=false
 else
  emptyDetail.Visible=false
  detail.Visible=true
  detailIcon.Image=iconFor(category,selectedItem)
  detailName.Text=tostring(selectedItem.Name or selectedItem.Id or "ENTRY")
  local meta,body=detailsFor(category,selectedItem)
  detailMeta.Text=meta
  detailBody.Text=body

  for _,child in ipairs(traitBeeStrip:GetChildren()) do
   if child:GetAttribute("IndexRuntime") then child:Destroy() end
  end
  local traitMode=category=="Traits"
  traitBeeStrip.Visible=traitMode
  equipSynergyButton.Visible=traitMode

  if traitMode then
   for order,beeId in ipairs(selectedItem.BeeIds or {}) do
    local icon=traitBeeIconTemplate:Clone()
    icon.Name="TraitBee_"..tostring(beeId)
    icon.Visible=true
    icon.LayoutOrder=order
    icon.Image=Icons.GetBeeIcon(beeId)
    icon:SetAttribute("IndexRuntime",true)
    icon.Parent=traitBeeStrip
   end
   local tier=math.max(0,math.floor(tonumber(selectedItem.ActiveTier) or 0))
   local canEquip=selectedItem.CanEquip==true
   equipSynergyButton.Active=canEquip
   equipSynergyButton.Selectable=canEquip
   equipSynergyButton.Text=tier>0 and ("RE-EQUIP SYNERGY  •  TIER "..tostring(tier)) or (canEquip and "EQUIP SYNERGY" or "MORE MATCHING BEES REQUIRED")
   equipSynergyButton.TextTransparency=canEquip and 0 or .45
   equipSynergyButton.BackgroundTransparency=canEquip and .02 or .18
   local stroke=equipSynergyButton:FindFirstChildOfClass("UIStroke")
   if stroke then
    stroke.Color=canEquip and C.Blue or C.BorderSoft
    stroke.Transparency=canEquip and .08 or .55
   end
   if not equipSynergyButton:GetAttribute("IndexEquipBound") then
    equipSynergyButton:SetAttribute("IndexEquipBound",true)
    equipSynergyButton.Activated:Connect(function()
     local current=controller.IndexState and controller.IndexState.Selected and controller.IndexState.Selected.Traits
     if current and equipSynergyButton.Active then controller:Send("EquipSynergy",current) end
    end)
   end
   detailScroll.Position=UDim2.fromOffset(16,218)
   detailScroll.Size=UDim2.new(1,-32,1,-234)
  else
   detailScroll.Position=UDim2.fromOffset(16,104)
   detailScroll.Size=UDim2.new(1,-32,1,-120)
  end

  local lines=1
  for _ in string.gmatch(body,"\n") do lines+=1 end
  detailBody.Size=UDim2.new(1,-8,0,math.max(260,lines*20+80))
 end
end

return Index
