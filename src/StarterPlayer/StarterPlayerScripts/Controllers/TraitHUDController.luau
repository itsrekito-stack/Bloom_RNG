local TweenService=game:GetService("TweenService")
local RS=game:GetService("ReplicatedStorage")

local Bees=require(RS.Config.BeesConfig)
local Icons=require(RS.Config.IconsConfig)
local Theme=require(RS.Config.UIThemeConfig)

local C=Theme.Colors
local S={}
S.__index=S

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

local function signature(traits,equippedSlots)
 local parts={}
 for _,item in ipairs(traits or {}) do
  if (tonumber(item.Count) or 0)>0 then
   parts[#parts+1]=table.concat({
    tostring(item.Id),
    tostring(item.Count or 0),
    tostring(item.Tier or 0),
    tostring(item.NextThreshold or 0),
   },":")
  end
 end
 local equipped={}
 for _,beeId in pairs(equippedSlots or {}) do
  if type(beeId)=="string" and beeId~="" then equipped[#equipped+1]=beeId end
 end
 table.sort(parts)
 table.sort(equipped)
 parts[#parts+1]="equipped:"..table.concat(equipped,",")
 return table.concat(parts,"|")
end

local function equippedSet(slots)
 local out={}
 for _,beeId in pairs(slots or {}) do
  if type(beeId)=="string" and beeId~="" then out[beeId]=true end
 end
 return out
end

local function traitIcon(id)
 local icon=Icons.GetTraitIcon(tostring(id or ""))
 if icon=="" then
  if id=="Swift" then return Icons.Get("System","ArrowRight") end
  return Icons.Get("System","Bee")
 end
 return icon
end

local function beeIcon(id)
 local icon=Icons.GetBeeIcon(tostring(id or ""))
 return icon~="" and icon or Icons.Get("System","Bee")
end

local function formatScalar(key,value)
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
 local parts={}
 for key,value in pairs(bonus or {}) do
  parts[#parts+1]=(STAT_LABELS[key] or key).." "..formatScalar(key,value)
 end
 table.sort(parts)
 return table.concat(parts,", ")
end

local function thresholdText(item)
 local parts={}
 for _,bp in ipairs(item.Breakpoints or {}) do
  parts[#parts+1]=tostring(bp.Count).." • "..bonusText(bp.Bonus)
 end
 return #parts>0 and table.concat(parts,"\n") or "No thresholds"
end

local function beeNames(item)
 local names={}
 for _,id in ipairs(item.BeeIds or {}) do
  local bee=Bees.Get(id)
  names[#names+1]=bee and bee.DisplayName or id
 end
 return #names>0 and ("Bees • "..table.concat(names,", ")) or "Bees • none discovered"
end

local function progressText(item)
 local count=tonumber(item.Count) or 0
 local nextThreshold=tonumber(item.NextThreshold)
 if nextThreshold then return tostring(count).." / "..tostring(nextThreshold) end
 local breakpoints=item.Breakpoints or {}
 local maxThreshold=breakpoints[#breakpoints] and breakpoints[#breakpoints].Count or count
 return tostring(count).." / "..tostring(maxThreshold).." MAX"
end

function S.new()
 return setmetatable({
  UI=nil,
  Root=nil,
  List=nil,
  Template=nil,
  Empty=nil,
  Tooltip=nil,
  Popup=nil,
  Suppressed=false,
  LastSignature=nil,
  LastTiers={},
  LastRevision=nil,
  PopupGeneration=0,
 },S)
end

function S:Init(ui)
 self.UI=ui
 local root=ui.SafeRoot
 self.Root=root:FindFirstChild("TraitHUD")
 self.Tooltip=root:FindFirstChild("TraitTooltip")
 self.Popup=root:FindFirstChild("TraitTierPopup")
 if not self.Root or not self.Tooltip or not self.Popup then
  error("[TraitHUD] Authored Trait HUD is missing from canonical BloomUI")
 end
 self.List=self.Root:FindFirstChild("TraitList")
 self.Empty=self.Root:FindFirstChild("EmptyLabel")
 self.Template=self.List and self.List:FindFirstChild("TraitTemplate")
 if not self.List or not self.Empty or not self.Template then
  error("[TraitHUD] Authored Trait HUD hierarchy is incomplete")
 end
 self.Template.Visible=false
 self.Tooltip.Visible=false
 self.Popup.Visible=false
end

function S:SetSuppressed(value)
 self.Suppressed=value==true
 if self.Root then self.Root.Visible=not self.Suppressed end
 if self.Suppressed then
  if self.Tooltip then self.Tooltip.Visible=false end
  if self.Popup then self.Popup.Visible=false end
 end
end

function S:ShowTooltip(item)
 if self.Suppressed or not self.Tooltip then return end
 local title=self.Tooltip:FindFirstChild("Title")
 local progress=self.Tooltip:FindFirstChild("Progress")
 local description=self.Tooltip:FindFirstChild("Description")
 local thresholds=self.Tooltip:FindFirstChild("Thresholds")
 local bees=self.Tooltip:FindFirstChild("Bees")
 if title then title.Text=tostring(item.Name or item.Id or "TRAIT") end
 if progress then progress.Text=(tonumber(item.Tier) or 0)>0 and ("TIER "..tostring(item.Tier).."  •  "..progressText(item)) or ("BUILDING  •  "..progressText(item)) end
 if description then description.Text=tostring(item.Description or "") end
 if thresholds then thresholds.Text="Thresholds\n"..thresholdText(item) end
 if bees then bees.Text=beeNames(item) end
 self.Tooltip.Visible=true
end

function S:HideTooltip()
 if self.Tooltip then self.Tooltip.Visible=false end
end

function S:ShowTierPopup(item,row)
 if self.Suppressed or not self.Popup then return end
 self.PopupGeneration+=1
 local generation=self.PopupGeneration
 local title=self.Popup:FindFirstChild("Title")
 local progress=self.Popup:FindFirstChild("Progress")
 local scale=self.Popup:FindFirstChild("PopupScale")
 if title then title.Text=tostring(item.Name or item.Id or "TRAIT") end
 if progress then progress.Text="Tier "..tostring(item.Tier or 0).."  •  "..progressText(item) end
 self.Popup.Visible=true
 if scale and scale:IsA("UIScale") then
  scale.Scale=.92
  TweenService:Create(scale,TweenInfo.new(.18,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
 end
 if row then
  local stroke=row:FindFirstChildOfClass("UIStroke")
  local badge=row:FindFirstChild("IconBadge")
  local icon=row:FindFirstChild("TraitIcon")
  if stroke then
   local baseColor=stroke.Color
   local baseThickness=stroke.Thickness
   stroke.Color=C.Gold
   stroke.Thickness=2.2
   TweenService:Create(stroke,TweenInfo.new(1.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Color=baseColor,Thickness=baseThickness}):Play()
  end
  local rowScale=row:FindFirstChild("HighlightScale")
  if rowScale and rowScale:IsA("UIScale") then
   rowScale.Scale=1.04
   TweenService:Create(rowScale,TweenInfo.new(.32,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
  end
  if icon and icon:IsA("ImageLabel") then
   local base=icon.ImageColor3
   icon.ImageColor3=C.Gold
   TweenService:Create(icon,TweenInfo.new(1.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{ImageColor3=base}):Play()
  elseif badge and badge:IsA("TextLabel") then
   local base=badge.TextColor3
   badge.TextColor3=C.Gold
   TweenService:Create(badge,TweenInfo.new(1.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{TextColor3=base}):Play()
  end
 end
 task.delay(1.7,function()
  if self.PopupGeneration~=generation or not self.Popup then return end
  self.Popup.Visible=false
 end)
end

function S:ClearRows()
 for _,child in ipairs(self.List:GetChildren()) do
  if child:GetAttribute("TraitRuntime") then child:Destroy() end
 end
end

function S:BuildRows(traits,tierUps,equippedSlots)
 self:ClearRows()
 local equipped=equippedSet(equippedSlots)
 local visible={}
 for _,item in ipairs(traits or {}) do
  if (tonumber(item.Count) or 0)>0 then visible[#visible+1]=item end
 end
 self.Empty.Visible=#visible==0
 self.List.Visible=#visible>0
 local rowById={}
 for order,item in ipairs(visible) do
  local row=self.Template:Clone()
  row.Name="Trait_"..tostring(item.Id)
  row.Visible=true
  row.LayoutOrder=order
  row:SetAttribute("TraitRuntime",true)
  row.Parent=self.List
  rowById[item.Id]=row

  local color=item.Color
  if typeof(color)~="Color3" then color=C.Blue end
  local badge=row:FindFirstChild("IconBadge")
  local icon=row:FindFirstChild("TraitIcon")
  local beeStrip=row:FindFirstChild("BeeStrip")
  local beeTemplate=beeStrip and beeStrip:FindFirstChild("BeeIconTemplate")
  local name=row:FindFirstChild("Name")
  local tier=row:FindFirstChild("Tier")
  local progress=row:FindFirstChild("Progress")
  local stroke=row:FindFirstChildOfClass("UIStroke")
  if icon and icon:IsA("ImageLabel") then
   icon.Image=traitIcon(item.Id)
   icon.ImageColor3=C.White
   icon.ImageTransparency=0
   icon.Visible=true
  end
  if badge and badge:IsA("TextLabel") then
   badge.Text=tostring(item.Short or string.sub(tostring(item.Name or "?"),1,1))
   badge.BackgroundColor3=color
   badge.Visible=not (icon and icon:IsA("ImageLabel"))
  end
  if beeStrip and beeTemplate and beeTemplate:IsA("ImageLabel") then
   for _,member in ipairs(beeStrip:GetChildren()) do
    if member:GetAttribute("TraitBeeRuntime") then member:Destroy() end
   end
   for beeOrder,beeId in ipairs(item.BeeIds or {}) do
    local member=beeTemplate:Clone()
    member.Name="Bee_"..tostring(beeId)
    member.LayoutOrder=beeOrder
    member.Visible=true
    member:SetAttribute("TraitBeeRuntime",true)
    member.Image=beeIcon(beeId)
    local isEquipped=equipped[beeId]==true
    member.ImageColor3=isEquipped and C.White or Color3.fromRGB(105,112,120)
    member.ImageTransparency=isEquipped and 0 or .42
    member.BackgroundTransparency=isEquipped and .04 or .22
    local memberStroke=member:FindFirstChildOfClass("UIStroke")
    if memberStroke then
     memberStroke.Color=isEquipped and color or C.BorderSoft
     memberStroke.Transparency=isEquipped and .16 or .62
    end
    member.Parent=beeStrip
   end
  end
  if name and name:IsA("TextLabel") then name.Text=tostring(item.Name or item.Id) end
  if tier and tier:IsA("TextLabel") then
   tier.Text=(tonumber(item.Tier) or 0)>0 and ("TIER "..tostring(item.Tier)) or "BUILDING"
   tier.TextColor3=(tonumber(item.Tier) or 0)>0 and color or C.Faint
  end
  if progress and progress:IsA("TextLabel") then progress.Text=progressText(item) end
  if stroke then
   stroke.Color=color
   stroke.Transparency=(tonumber(item.Tier) or 0)>0 and .08 or .42
  end

  row.MouseEnter:Connect(function() self:ShowTooltip(item) end)
  row.MouseLeave:Connect(function() self:HideTooltip() end)
 end

 for _,item in ipairs(tierUps) do
  local row=rowById[item.Id]
  self:ShowTierPopup(item,row)
  break
 end
end

function S:Update(traits,equippedSlots,revision)
 if not self.Root then return end
 self.LastRevision=revision
 local nextSignature=signature(traits,equippedSlots)
 if nextSignature==self.LastSignature then
  self.Root.Visible=not self.Suppressed
  return
 end

 local first=self.LastSignature==nil
 local tierUps={}
 for _,item in ipairs(traits or {}) do
  local id=tostring(item.Id or "")
  local tier=tonumber(item.Tier) or 0
  local previous=self.LastTiers[id]
  if not first and previous~=nil and tier>previous then
   tierUps[#tierUps+1]=item
  end
  self.LastTiers[id]=tier
 end

 self.LastSignature=nextSignature
 self:HideTooltip()
 self:BuildRows(traits,tierUps,equippedSlots)
 self.Root.Visible=not self.Suppressed
end

return S.new()
