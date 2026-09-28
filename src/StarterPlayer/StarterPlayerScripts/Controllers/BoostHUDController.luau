local TweenService=game:GetService("TweenService")
local RS=game:GetService("ReplicatedStorage")

local Icons=require(RS.Config.IconsConfig)
local Theme=require(RS.Config.UIThemeConfig)

local C=Theme.Colors
local S={Badges={},BadgesById={},ItemsByBadge={},Minimized=false,Suppressed=false,ItemCount=0}

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
 local luck=payload and payload.Luck
 if luck then
  table.insert(parts,"Luck")
  table.insert(parts,tostring(luck.Total or ""))
  table.insert(parts,tostring(luck.ValueText or ""))
  for _,source in ipairs(luck.Sources or {}) do
   table.insert(parts,tostring(source.Group or ""))
   table.insert(parts,tostring(source.Name or ""))
   table.insert(parts,tostring(source.ValueText or ""))
  end
 end
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
 self.LuckBadge=self.List and self.List:FindFirstChild("LuckBadge")
 self.ScrollLeft=self.Root:FindFirstChild("ScrollLeft")
 self.ScrollRight=self.Root:FindFirstChild("ScrollRight")
 self.Title=self.Root:FindFirstChild("Title")
 self.Toggle=self.Root:FindFirstChild("MinimizeButton")
 self.TooltipTitle=self.Tooltip:FindFirstChild("Title")
 self.TooltipTotal=self.Tooltip:FindFirstChild("Total")
 self.TooltipBreakdown=self.Tooltip:FindFirstChild("Breakdown")
 if not self.List or not self.Template or not self.LuckBadge or not self.ScrollLeft or not self.ScrollRight or not self.Empty or not self.Title or not self.Toggle or not self.TooltipTitle or not self.TooltipTotal or not self.TooltipBreakdown then
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
 self.BadgesById={}
 self.RootStroke=self.Root:FindFirstChildOfClass("UIStroke")
 if self.RootStroke then
  self.RootStrokeBaseColor=self.RootStroke.Color
  self.RootStrokeBaseThickness=self.RootStroke.Thickness
  self.RootStrokeBaseTransparency=self.RootStroke.Transparency
 end
 self.RollHighlightUntil=0
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
 self.ScrollLeft.Activated:Connect(function()
  local x=math.max(0,self.List.CanvasPosition.X-116)
  TweenService:Create(self.List,TweenInfo.new(Theme.Motion.Fast),{CanvasPosition=Vector2.new(x,0)}):Play()
 end)
 self.ScrollRight.Activated:Connect(function()
  local maxX=math.max(0,self.List.AbsoluteCanvasSize.X-self.List.AbsoluteWindowSize.X)
  local x=math.min(maxX,self.List.CanvasPosition.X+116)
  TweenService:Create(self.List,TweenInfo.new(Theme.Motion.Fast),{CanvasPosition=Vector2.new(x,0)}):Play()
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
 self.ViewportWidth=tonumber(width) or self.ViewportWidth or 1366
 local maxWidth=math.max(168,math.min(340,self.ViewportWidth-24))
 local count=math.max(1,tonumber(self.DisplayCount) or ((tonumber(self.ItemCount) or 0)+1))
 local contentWidth=16+count*52+math.max(0,count-1)*6
 local expandedWidth=math.clamp(contentWidth,168,maxWidth)
 self.ExpandedSize=UDim2.fromOffset(expandedWidth,82)
 self.Root.Position=UDim2.new(0,12,1,-14)
 if not self.Minimized then self.Root.Size=self.ExpandedSize end
end

function S:SetMinimized(minimized,animate)
 self.Minimized=minimized==true
 self.Hovered=nil
 self.Tooltip.Visible=false
 self.Toggle.Text=self.Minimized and "+" or "−"
 self.Title.Text=self.Minimized and ("BOOSTS  •  "..tostring(self.ItemCount)) or "ACTIVE BOOSTS"
 self.List.Visible=not self.Minimized
 self.Empty.Visible=false
 self.ScrollLeft.Visible=not self.Minimized
 self.ScrollRight.Visible=not self.Minimized
 local target=self.Minimized and UDim2.fromOffset(132,30) or (self.ExpandedSize or UDim2.fromOffset(168,82))
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
 table.clear(self.BadgesById)
 table.clear(self.ItemsByBadge)
end

function S:SourceRemaining(source)
 return remaining(source and source._ExpiresAt)
end

function S:TooltipText(item)
 local lines={}
 for _,entry in ipairs(item.Sources or {}) do
  local seconds=self:SourceRemaining(entry)
  if not entry._ExpiresAt or (seconds and seconds>0) then
   local group=tostring(entry.Group or "Source")
   local name=tostring(entry.Name or "")
   local line=group
   if name~="" and name~=group then line=line.." • "..name end
   if entry.ValueText and entry.ValueText~="" then line=line.."   "..tostring(entry.ValueText) end
   if seconds then line=line.."   •   "..timedText(seconds) end
   table.insert(lines,line)
  end
 end
 if #lines==0 then table.insert(lines,"Active") end
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
 local height=math.clamp(58+math.max(1,sourceCount)*20,78,180)
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
 if not scale or not scale:IsA("UIScale") then
  error("[BoostHUD] Authored BoostTemplate/HoverScale is missing")
 end
 self.ItemsByBadge[badge]=item
 if badge:GetAttribute("BoostHoverBound") then return end
 badge:SetAttribute("BoostHoverBound",true)

 badge.MouseEnter:Connect(function()
  local current=self.ItemsByBadge[badge]
  if not current then return end
  local timed=current.Remaining~=nil
  self.Hovered={Badge=badge,Item=current}
  if stroke then TweenService:Create(stroke,TweenInfo.new(Theme.Motion.Fast),{Color=C.Gold,Thickness=2}):Play() end
  TweenService:Create(badge,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=C.PanelHover}):Play()
  TweenService:Create(scale,TweenInfo.new(Theme.Motion.Fast),{Scale=1.06}):Play()
  self:PlaceTooltip(badge,current)
 end)
 badge.MouseLeave:Connect(function()
  local current=self.ItemsByBadge[badge]
  local timed=current and current.Remaining~=nil
  if self.Hovered and self.Hovered.Badge==badge then self.Hovered=nil self.Tooltip.Visible=false end
  if stroke then TweenService:Create(stroke,TweenInfo.new(Theme.Motion.Fast),{Color=timed and C.Gold or C.Border,Thickness=1.5}):Play() end
  TweenService:Create(badge,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=C.Panel}):Play()
  TweenService:Create(scale,TweenInfo.new(Theme.Motion.Fast),{Scale=1}):Play()
 end)
end

local function hydrateTimedItem(raw)
 local item=cloneData(raw)
 if item.Remaining then item._ExpiresAt=os.clock()+math.max(0,tonumber(item.Remaining) or 0) end
 for _,entry in ipairs(item.Sources or {}) do
  if entry.Remaining then entry._ExpiresAt=os.clock()+math.max(0,tonumber(entry.Remaining) or 0) end
 end
 return item
end

function S:UpdateBadge(badge,item,layoutOrder)
 badge.LayoutOrder=layoutOrder
 badge.Visible=true
 local icon=badge:FindFirstChild("Icon")
 local value=badge:FindFirstChild("Value")
 if icon and icon:IsA("ImageLabel") then icon.Image=self:Icon(item) end
 if value and value:IsA("TextLabel") then value.Text=tostring(item.ValueText or "") end
 badge:SetAttribute("BoostId",tostring(item.Id or ""))
 self.ItemsByBadge[badge]=item
 self:BindBadge(badge,item)
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

 local canvasPosition=self.List.CanvasPosition
 local items=payload and payload.Items or {}
 local luck=hydrateTimedItem(payload and payload.Luck or {Id="Luck",Label="Luck",ValueText="0%",Total=1,Sources={}})
 self.ItemCount=#items+1

 local luckValue=self.LuckBadge:FindFirstChild("Value")
 local luckIcon=self.LuckBadge:FindFirstChild("Icon")
 if luckValue and luckValue:IsA("TextLabel") then luckValue.Text=tostring(luck.ValueText or "0%") end
 if luckIcon and luckIcon:IsA("ImageLabel") then luckIcon.Image=self:Icon(luck) end
 self.LuckBadge.Visible=true
 self.LuckBadge.LayoutOrder=0
 self.LuckBadge:SetAttribute("BoostId","Luck")
 self.ItemsByBadge[self.LuckBadge]=luck
 self:BindBadge(self.LuckBadge,luck)

 local desired={}
 local ordered={}
 for index,raw in ipairs(items) do
  local item=hydrateTimedItem(raw)
  local id=tostring(item.Id or index)
  desired[id]=true
  local badge=self.BadgesById[id]
  if not badge or not badge.Parent then
   badge=self.Template:Clone()
   badge.Name="Boost_"..id
   badge:SetAttribute("RuntimeBoost",true)
   badge.Parent=self.List
   self.BadgesById[id]=badge
  end
  self:UpdateBadge(badge,item,index)
  ordered[#ordered+1]=badge
 end

 for id,badge in pairs(self.BadgesById) do
  if not desired[id] then
   if self.Hovered and self.Hovered.Badge==badge then
    self.Hovered=nil
    self.Tooltip.Visible=false
   end
   self.ItemsByBadge[badge]=nil
   self.BadgesById[id]=nil
   if badge and badge.Parent then badge:Destroy() end
  end
 end
 self.Badges=ordered

 if self.Hovered and self.Hovered.Badge and self.Hovered.Badge.Parent then
  local current=self.ItemsByBadge[self.Hovered.Badge]
  if current then
   self.Hovered.Item=current
   self:PlaceTooltip(self.Hovered.Badge,current)
  end
 end

 local safeWidth=self.UI.SafeRoot and self.UI.SafeRoot.AbsoluteSize.X or self.ViewportWidth or 1366
 self:ApplyResponsiveLayout(safeWidth)
 self:SetSuppressed(self.UI:IsWorkshopExclusive())
 self.List.CanvasPosition=canvasPosition
 task.defer(function()
  if not self.List or not self.List.Parent then return end
  local maxX=math.max(0,self.List.AbsoluteCanvasSize.X-self.List.AbsoluteWindowSize.X)
  self.List.CanvasPosition=Vector2.new(math.clamp(canvasPosition.X,0,maxX),0)
 end)
end

function S:FlashRollBoost(payload)
 if type(payload)~="table" or (payload.IsSpecialRoll~=true and payload.ServerBloomLuck~=true) then return end
 self.RollHighlightUntil=os.clock()+1.35
 local color=payload.ServerBloomLuck and C.Blue or C.Gold
 if self.RootStroke then
  TweenService:Create(self.RootStroke,TweenInfo.new(Theme.Motion.Fast),{Color=color,Thickness=2.6,Transparency=0}):Play()
 end
 TweenService:Create(self.Root,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=C.PanelHover}):Play()
end

function S:Tick()
 if self.RollHighlightUntil and self.RollHighlightUntil>0 and os.clock()>=self.RollHighlightUntil then
  self.RollHighlightUntil=0
  if self.RootStroke then
   TweenService:Create(self.RootStroke,TweenInfo.new(Theme.Motion.Fast),{
    Color=self.RootStrokeBaseColor or C.Border,
    Thickness=self.RootStrokeBaseThickness or 1.25,
    Transparency=self.RootStrokeBaseTransparency or .18,
   }):Play()
  end
  TweenService:Create(self.Root,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=C.Panel}):Play()
 end
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
