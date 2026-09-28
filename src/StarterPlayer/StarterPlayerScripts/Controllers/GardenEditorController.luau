local RS=game:GetService("ReplicatedStorage")
local Flowers=require(RS.Config.FlowersConfig)
local Icons=require(RS.Config.IconsConfig)
local Rarity=require(RS.Config.RarityConfig)
local Synergies=require(RS.Config.GardenSynergyConfig)
local Theme=require(RS.Config.UIThemeConfig)

local C=Theme.Colors
local S={}

local function iconFor(id)
 local icon=Icons.GetRewardIcon("FlowerSeed",id)
 return icon~="" and icon or Icons.Get("System","Flower")
end

local function setText(root,name,value)
 local x=root and root:FindFirstChild(name,true)
 if x and x:IsA("TextLabel") then x.Text=tostring(value or "") end
 return x
end

local function masteryFor(inventory,id)
 for _,item in ipairs(inventory.Flowers or {}) do
  if item.Id==id then return item.Mastery or {Level=1},item end
 end
 return {Level=1},nil
end

local function synergyById(id)
 if not id or id=="" then return nil end
 for _,recipe in ipairs(Synergies.Recipes or {}) do
  if recipe.Id==id then return recipe end
 end
 return nil
end

local function effectText(effect)
 local parts={}
 for key,value in pairs(effect or {}) do
  local label
  if key=="LuckMultiplier" then label="Luck ×"..tostring(value)
  elseif key=="PollinatorYieldMultiplier" then label="Bee Yield ×"..tostring(value)
  elseif key=="PollinatorPowerMultiplier" then label="Bee Power ×"..tostring(value)
  elseif key=="FlowerGrowthMultiplier" then label="Flower Growth ×"..tostring(value)
  elseif key=="CoinMultiplier" then label="Coins ×"..tostring(value)
  elseif key=="HiveHoneyMultiplier" then label="Honey ×"..tostring(value)
  else label=key.." "..tostring(value) end
  parts[#parts+1]=label
 end
 table.sort(parts)
 return #parts>0 and table.concat(parts,"  •  ") or "No bonus"
end

local function selectedState(controller)
 controller.GardenEditorState=controller.GardenEditorState or {SelectedFlowerId=nil,SelectedSlot=nil}
 return controller.GardenEditorState
end

function S.Render(controller,profile,uiState)
 local template=controller.StateKits and controller.StateKits:FindFirstChild("GardenKit")
 if not template or not template:IsA("Frame") then
  controller:Label(controller.Content,"GardenKit missing",32)
  return
 end

 local runtime=template:Clone()
 runtime.Name="GardenRuntime"
 runtime.Visible=true
 runtime.Position=UDim2.fromScale(0,0)
 runtime.Size=UDim2.fromScale(1,1)
 runtime.LayoutOrder=1
 runtime.Parent=controller.Content

 local inventory=uiState.Inventory or {}
 local gardenState=uiState.Garden or {}
 local state=selectedState(controller)
 local flowerList=runtime:FindFirstChild("FlowerList",true)
 local flowerTemplate=runtime:FindFirstChild("FlowerCardTemplate",true)
 local slotRing=runtime:FindFirstChild("SlotRing",true)
 local selectedLabel=runtime:FindFirstChild("SelectedFlower",true)
 local synergyTitle=runtime:FindFirstChild("SynergyName",true)
 local synergyEffect=runtime:FindFirstChild("SynergyEffect",true)
 local hint=runtime:FindFirstChild("GhostHint",true)
 local remove=runtime:FindFirstChild("RemoveButton",true)
 local ghostSlot=slotRing and slotRing:FindFirstChild("Slot7")
 local ghostBadge=ghostSlot and ghostSlot:FindFirstChild("GhostBadge")

 if not flowerList or not flowerTemplate or not slotRing then
  error("[GardenEditor] Authored GardenKit structure is incomplete")
 end

 for _,child in ipairs(flowerList:GetChildren()) do
  if child:GetAttribute("GardenRuntimeFlower") then child:Destroy() end
 end

 local flowers={}
 for _,entry in ipairs(inventory.Flowers or {}) do flowers[#flowers+1]=entry end
 local usedById={}
 for slotIndex,slot in ipairs(profile.Garden and profile.Garden.Slots or {}) do
  local speciesId=slot and slot.SpeciesId
  if speciesId and speciesId~="" then usedById[speciesId]=slotIndex end
 end
 table.sort(flowers,function(a,b)
  local ar=Rarity.Rank[a.Rarity] or 0
  local br=Rarity.Rank[b.Rarity] or 0
  if ar==br then return tostring(a.DisplayName)<tostring(b.DisplayName) end
  return ar>br
 end)

 for order,entry in ipairs(flowers) do
  local card=flowerTemplate:Clone()
  card.Name="Flower_"..entry.Id
  card.Visible=true
  card.LayoutOrder=order
  card:SetAttribute("GardenRuntimeFlower",true)
  local icon=card:FindFirstChild("Icon",true)
  if icon and icon:IsA("ImageLabel") then icon.Image=iconFor(entry.Id) end
  setText(card,"Name",entry.DisplayName or entry.Id)
  setText(card,"Meta","1/N "..tostring(entry.Odds or "1/—").."  •  Lv. "..tostring(entry.Mastery and entry.Mastery.Level or 1))
  local usedSlot=usedById[entry.Id]
  local usedBadge=card:FindFirstChild("UsedBadge")
  if usedBadge and usedBadge:IsA("TextLabel") then
   usedBadge.Visible=usedSlot~=nil
   usedBadge.Text=usedSlot and ("USED • SLOT "..tostring(usedSlot)) or ""
  end
  card.BackgroundColor3=usedSlot and C.PanelHover or C.Panel
  local stroke=card:FindFirstChildOfClass("UIStroke")
  if stroke then
   local selected=state.SelectedFlowerId==entry.Id
   stroke.Color=selected and C.Blue or (usedSlot and C.Green or C.BorderSoft)
   stroke.Thickness=selected and 2 or (usedSlot and 1.6 or 1)
   stroke.Transparency=selected and .02 or (usedSlot and .08 or .35)
  end
  card.Activated:Connect(function()
   state.SelectedFlowerId=entry.Id
   controller:RenderMenu(true)
  end)
  card.Parent=flowerList
 end

 local clickedSlot=tonumber(controller.MenuArg and controller.MenuArg.Slot)
 if clickedSlot and not state.SelectedSlot then state.SelectedSlot=clickedSlot end

 local unlocked=tonumber(profile.Garden and profile.Garden.UnlockedSlots) or 0
 local slots=profile.Garden and profile.Garden.Slots or {}
 for i=1,7 do
  local button=slotRing:FindFirstChild("Slot"..i)
  if button and button:IsA("GuiButton") then
   local slot=slots[i] or {}
   local id=slot.SpeciesId
   local open=i<=unlocked
   local ghost=i==7 and not open
   button.Active=open
   button.AutoButtonColor=false
   button.BackgroundTransparency=open and .02 or (ghost and .62 or .35)
   if i==7 and ghostBadge and ghostBadge:IsA("TextLabel") then
    ghostBadge.Visible=ghost
   end
   local icon=button:FindFirstChild("Icon")
   local name=button:FindFirstChild("Name")
   local level=button:FindFirstChild("Level")
   local lock=button:FindFirstChild("Lock")
   if icon and icon:IsA("ImageLabel") then
    icon.Visible=(open and id~=nil and id~="") or ghost
    icon.Image=ghost and Icons.Get("System","Flower") or ((id and id~="") and iconFor(id) or "")
    icon.ImageTransparency=ghost and .52 or 0
    icon.ImageColor3=ghost and C.Blue or C.White
   end
   if name and name:IsA("TextLabel") then
    name.Text=not open and (ghost and "GHOST SLOT" or "LOCKED") or (id and Flowers.Species[id] and Flowers.Species[id].DisplayName or "EMPTY")
   end
   if level and level:IsA("TextLabel") then
    local mastery=id and masteryFor(inventory,id) or {Level=1}
    level.Visible=open and id~=nil and id~=""
    level.Text="Lv. "..tostring(mastery.Level or 1)
   end
   if lock and lock:IsA("TextLabel") then
    lock.Visible=not open and not ghost
    if ghost then lock.Text="FINAL SLOT • HIVE LV. 7" end
   end
   local stroke=button:FindFirstChildOfClass("UIStroke")
   if stroke then
    local selected=state.SelectedSlot==i
    stroke.Color=selected and C.Gold or (ghost and C.Blue or (open and C.Border or C.BorderSoft))
    stroke.Thickness=selected and 2.2 or (ghost and 1.8 or 1.2)
    stroke.Transparency=selected and 0 or (ghost and .18 or .28)
   end
   button.Activated:Connect(function()
    if not open then controller:Toast(ghost and "Reach Hive Level 7 to unlock the final Garden slot." or "This garden slot is locked.") return end
    state.SelectedSlot=i
    local selected=state.SelectedFlowerId
    if selected and selected~="" then
     controller:Send("GardenEdit",i,selected)
    else
     controller:RenderMenu(true)
    end
   end)
  end
 end

 if selectedLabel and selectedLabel:IsA("TextLabel") then
  local id=state.SelectedFlowerId
  local cfg=id and Flowers.Species[id]
  selectedLabel.Text=cfg and ("SELECTED  •  "..cfg.DisplayName) or "SELECT A FLOWER, THEN A SLOT"
 end

 local active=synergyById(gardenState.ActiveSynergy)
 if synergyTitle and synergyTitle:IsA("TextLabel") then
  synergyTitle.Text=active and ("CURRENT SYNERGY  •  "..tostring(active.Name or active.Id)) or "CURRENT SYNERGY  •  NONE"
 end
 if synergyEffect and synergyEffect:IsA("TextLabel") then
  synergyEffect.Text=active and effectText(active.Effect) or "Build a valid Flower combination to activate one."
 end

 if hint and hint:IsA("TextLabel") then
  local hintId=gardenState.Hint and gardenState.Hint.FlowerId
  local cfg=hintId and Flowers.Species[hintId]
  hint.Visible=cfg~=nil
  hint.Text=cfg and ("GHOST HINT  •  Try "..cfg.DisplayName) or ""
 end

 if remove and remove:IsA("TextButton") then
  local slot=state.SelectedSlot
  local occupied=slot and slots[slot] and slots[slot].SpeciesId
  remove.Visible=slot~=nil
  remove.Active=occupied~=nil and occupied~=""
  remove.Text=occupied and "REMOVE FROM SLOT "..tostring(slot) or "SLOT "..tostring(slot).." IS EMPTY"
  remove.TextTransparency=remove.Active and 0 or .45
  remove.Activated:Connect(function()
   if remove.Active then controller:Send("GardenEdit",slot,"") end
  end)
 end
end

return S
