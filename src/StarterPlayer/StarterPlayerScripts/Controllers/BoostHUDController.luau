local TweenService=game:GetService("TweenService")
local RS=game:GetService("ReplicatedStorage")

local Icons=require(RS.Config.IconsConfig)
local Theme=require(RS.Config.UIThemeConfig)

local C=Theme.Colors
local S={Badges={},ItemsByBadge={},Minimized=false,Suppressed=false,ItemCount=0}

local function cloneData(value)
 if type(value)~="table" then return value end
 local out={}
 for k,v in pairs(value) do out[k]=cloneData(v) end
 return out
end

local function remaining(expiresAt)
 if not expiresAt then return nil end
 return math.max(0,expiresAt-os.clock())
end

local function timedText(seconds)
 if not seconds then return nil end
 return tostring(math.max(0,math.ceil(seconds))).."s"
end

local function payloadSignature(payload)
 local parts={}
 for _,item in ipairs(payload and payload.Items or {}) do
  table.insert(parts,tostring(item.Id or ""))
  table.insert(parts,tostring(item.Label or ""))
  table.insert(parts,tostring(item.Total or ""))
  if item.Remaining==nil then table.insert(parts,tostring(item.ValueText or "")) end
  table.insert(parts,tostring(item.Description or ""))
  for _,source in ipairs(item.Sources or {}) do
   table.insert(parts,tostring(source.Group or ""))
   table.insert(parts,tostring(source.Name or ""))
   table.insert(parts,tostring(source.ValueText or ""))
   table.insert(parts,tostring(source.Description or ""))
  end
 end
 return table.concat(parts,"\31")
end

function S:Init(ui)
 self.UI=ui
 self.Root=ui.SafeRoot:FindFirstChild("ActiveBoostsHUD")
 self.Tooltip=ui.SafeRoot:FindFirstChild("ActiveBoostTooltip")
 if not self.Root or not self.Tooltip then
  error("[BoostHUD] Authored boost HUD is missing from canonical BloomUI. Expected SafeRoot/ActiveBoostsHUD and SafeRoot/ActiveBoostTooltip.")
 end
 self.List=self.Root:FindFirstChild("BoostList")
 self.Empty=self.Root:FindFirstChild("EmptyLabel")
 self.Template=self.List and self.List:FindFirstChild("BoostTemplate")
 self.Title=self.Root:FindFirstChild("Title")
 self.Toggle=self.Root:FindFirstChild("MinimizeButton")
 self.TooltipTitle=self.Tooltip:FindFirstChild("Title")
 self.TooltipTotal=self.Tooltip:FindFirstChild("Total")
 self.TooltipBreakdown=self.Tooltip:FindFirstChild("Breakdown")
 if not self.List or not self.Template or not self.Empty or not self.Title or not self.Toggle or not self.TooltipTitle or not self.TooltipTotal or not self.TooltipBreakdown then
  error("[BoostHUD] Authored boost HUD hierarchy is incomplete. Re-sync BloomUI.model.json before Play.")
 end
 self.LastRevision=nil
 self.LastSignature=nil
 self.ExpandedSize=self.Root.Size
 self.Minimized=false
 self.Suppressed=false
 self.ItemCount=0
 self.Hovered=nil
 self.ItemsByBadge={}
 self.Root.Visible=true
 self.Tooltip.Visible=false

 self.Toggle.Activated:Connect(function()
  self:SetMinimized(not self.Minimized,true)
 end)
 self.Toggle.MouseEnter:Connect(function()
  TweenService:Create(self.Toggle,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=C.PanelHover,TextColor3=C.Text}):Play()
 end)
 self.Toggle.MouseLeave:Connect(function()
  TweenService:Create(self.Toggle,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=C.Panel,TextColor3=C.Muted}):Play()
 end)
 self:SetMinimized(false,false)
end

function S:SetSuppressed(suppressed)
 self.Suppressed=suppressed==true
 self.Root.Visible=not self.Suppressed
 if self.Suppressed then
  self.Hovered=nil
  self.Tooltip.Visible=false
 end
end

function S:ApplyResponsiveLayout(width)
 self.ExpandedSize=UDim2.fromOffset(math.max(280,math.min(360,(tonumber(width) or 360)-20)),72)
 self.Root.Position=UDim2.new(0,10,1,-118)
 if not self.Minimized then self.Root.Size=self.ExpandedSize end
end

function S:SetMinimized(minimized,animate)
 self.Minimized=minimized==true
 self.Hovered=nil
 self.Tooltip.Visible=false
 self.Toggle.Text=self.Minimized and "+" or "−"
 self.Title.Text=self.Minimized and ("BOOSTS  •  "..tostring(self.ItemCount)) or "ACTIVE BOOSTS"
 self.List.Visible=not self.Minimized and self.ItemCount>0
 self.Empty.Visible=not self.Minimized and self.ItemCount==0
 local target=self.Minimized and UDim2.fromOffset(132,30) or (self.ExpandedSize or UDim2.fromOffset(360,72))
 if animate then
  TweenService:Create(self.Root,TweenInfo.new(Theme.Motion.Normal,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=target}):Play()
 else
  self.Root.Size=target
 end
end

function S:Icon(item)
 local icon=Icons.Get(tostring(item.IconGroup or "System"),tostring(item.IconId or "Info"))
 if icon=="" then icon=Icons.Get("System","Info") end
 return icon
end

function S:Clear()
 self.Hovered=nil
 self.Tooltip.Visible=false
 for _,badge in ipairs(self.Badges) do
  if badge and badge.Parent then badge:Destroy() end
 end
 table.clear(self.Badges)
 table.clear(self.ItemsByBadge)
end

function S:SourceRemaining(source)
 return remaining(source and source._ExpiresAt)
end

function S:TooltipText(item)
 local lines={}
 if item.Description and item.Description~="" then
  table.insert(lines,tostring(item.Description))
 end
 for _,entry in ipairs(item.Sources or {}) do
  local seconds=self:SourceRemaining(entry)
  if not entry._ExpiresAt or (seconds and seconds>0) then
   local line=tostring(entry.Group or "Source").." • "..tostring(entry.Name or "")
   if entry.ValueText and entry.ValueText~="" then line=line.."   "..tostring(entry.ValueText) end
   if seconds then line=line.."   •   "..timedText(seconds) end
   table.insert(lines,line)
   if entry.Description and entry.Description~="" then
    table.insert(lines,"  "..tostring(entry.Description))
   end
  end
 end
 if #lines==0 then table.insert(lines,"No active sources.") end
 return table.concat(lines,"\n")
end

function S:PlaceTooltip(badge,item)
 local root=self.UI.SafeRoot
 if not root or root.AbsoluteSize.X<=0 then return end
 local rootPos=root.AbsolutePosition
 local rootSize=root.AbsoluteSize
 local pos=badge.AbsolutePosition-rootPos
 local width=math.min(330,math.max(250,rootSize.X-24))
 local sourceCount=#(item.Sources or {})
 local descriptionRows=item.Description and item.Description~="" and 1 or 0
 local height=math.clamp(72+(sourceCount*34)+(descriptionRows*18),92,280)
 local x=math.clamp(pos.X,12,rootSize.X-width-12)
 local y=math.clamp(pos.Y-10,12+height,rootSize.Y-12)
 self.Tooltip.Size=UDim2.fromOffset(width,height)
 self.Tooltip.Position=UDim2.fromOffset(x,y)
 self.Tooltip.AnchorPoint=Vector2.new(0,1)
 self.TooltipTitle.Text=tostring(item.Label or item.Id or "Boost")
 self.TooltipTotal.Text="TOTAL  •  "..tostring(item.ValueText or "")
 self.TooltipBreakdown.Text=self:TooltipText(item)
 self.Tooltip.Visible=true
end

function S:BindBadge(badge,item)
 local stroke=badge:FindFirstChildOfClass("UIStroke")
 local scale=badge:FindFirstChild("HoverScale")
 if not scale then
  scale=Instance.new("UIScale")
  scale.Name="HoverScale"
  scale.Parent=badge
 end
 local timed=item.Remaining~=nil
 if stroke then stroke.Color=timed and C.Gold or C.Border end

 badge.MouseEnter:Connect(function()
  self.Hovered={Badge=badge,Item=item}
  if stroke then TweenService:Create(stroke,TweenInfo.new(Theme.Motion.Fast),{Color=C.Gold,Thickness=2}):Play() end
  TweenService:Create(badge,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=C.PanelHover}):Play()
  TweenService:Create(scale,TweenInfo.new(Theme.Motion.Fast),{Scale=1.06}):Play()
  self:PlaceTooltip(badge,item)
 end)
 badge.MouseLeave:Connect(function()
  if self.Hovered and self.Hovered.Badge==badge then self.Hovered=nil self.Tooltip.Visible=false end
  if stroke then TweenService:Create(stroke,TweenInfo.new(Theme.Motion.Fast),{Color=timed and C.Gold or C.Border,Thickness=1.5}):Play() end
  TweenService:Create(badge,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=C.Panel}):Play()
  TweenService:Create(scale,TweenInfo.new(Theme.Motion.Fast),{Scale=1}):Play()
 end)
end

function S:Update(payload,revision)
 local signature=payloadSignature(payload)
 if signature==self.LastSignature then
  self.LastRevision=revision
  self:SetSuppressed(self.UI:IsWorkshopExclusive())
  return
 end
 self.LastSignature=signature
 self.LastRevision=revision
 self:Clear()

 local items=payload and payload.Items or {}
 self.ItemCount=#items
 self:SetSuppressed(self.UI:IsWorkshopExclusive())
 self:SetMinimized(self.Minimized,false)

 for index,raw in ipairs(items) do
  local item=cloneData(raw)
  if item.Remaining then item._ExpiresAt=os.clock()+math.max(0,tonumber(item.Remaining) or 0) end
  for _,entry in ipairs(item.Sources or {}) do
   if entry.Remaining then entry._ExpiresAt=os.clock()+math.max(0,tonumber(entry.Remaining) or 0) end
  end

  local badge=self.Template:Clone()
  badge.Name="Boost_"..tostring(item.Id or index)
  badge.LayoutOrder=index
  badge.Visible=true
  badge.Parent=self.List
  badge:SetAttribute("RuntimeBoost",true)

  local icon=badge:FindFirstChild("Icon")
  local value=badge:FindFirstChild("Value")
  if icon and icon:IsA("ImageLabel") then icon.Image=self:Icon(item) end
  if value and value:IsA("TextLabel") then value.Text=tostring(item.ValueText or "") end

  badge:SetAttribute("BoostId",tostring(item.Id or ""))
  self.ItemsByBadge[badge]=item
  self:BindBadge(badge,item)
  table.insert(self.Badges,badge)
 end
end

function S:Tick()
 for _,badge in ipairs(self.Badges) do
  local item=self.ItemsByBadge[badge]
  if badge.Parent and item and item._ExpiresAt then
   local seconds=remaining(item._ExpiresAt)
   local value=badge:FindFirstChild("Value")
   if value and value:IsA("TextLabel") then value.Text=timedText(seconds) or "0s" end
   if not seconds or seconds<=0 then badge.Visible=false end
  end
 end
 if not self.Minimized and self.Hovered and self.Hovered.Badge and self.Hovered.Badge.Parent and self.Hovered.Badge.Visible then
  self:PlaceTooltip(self.Hovered.Badge,self.Hovered.Item)
 elseif self.Hovered then
  self.Hovered=nil
  self.Tooltip.Visible=false
 end
end

return S
