local TweenService=game:GetService("TweenService")
local RS=game:GetService("ReplicatedStorage")

local Icons=require(RS.Config.IconsConfig)
local Theme=require(RS.Config.UIThemeConfig)

local C=Theme.Colors
local S={Badges={}}

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

function S:Init(ui)
 self.UI=ui
 self.Root=ui.SafeRoot:WaitForChild("ActiveBoostsHUD")
 self.List=self.Root:WaitForChild("BoostList")
 self.Template=self.List:WaitForChild("BoostTemplate")
 self.Empty=self.Root:WaitForChild("EmptyLabel")
 self.Tooltip=ui.SafeRoot:WaitForChild("ActiveBoostTooltip")
 self.TooltipTitle=self.Tooltip:WaitForChild("Title")
 self.TooltipTotal=self.Tooltip:WaitForChild("Total")
 self.TooltipBreakdown=self.Tooltip:WaitForChild("Breakdown")
 self.LastRevision=nil
 self.Hovered=nil
 self.Root.Visible=true
 self.Tooltip.Visible=false
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
 if revision~=nil and revision==self.LastRevision then return end
 self.LastRevision=revision
 self:Clear()

 local items=payload and payload.Items or {}
 self.Empty.Visible=#items==0
 self.List.Visible=#items>0

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
  self:BindBadge(badge,item)
  table.insert(self.Badges,badge)
 end
end

function S:Tick()
 for _,badge in ipairs(self.Badges) do
  if badge.Parent then
   local id=badge:GetAttribute("BoostId")
   if id=="SolarBloom" then
    local hovered=self.Hovered and self.Hovered.Badge==badge
    local item=hovered and self.Hovered.Item or nil
    if not item then
     for _,candidate in ipairs(self.Badges) do
      if candidate==badge and self.Hovered and self.Hovered.Badge==candidate then item=self.Hovered.Item break end
     end
    end
    local data=item
    if not data then
     -- The server will remove expired boosts; no local state mutation is needed when not hovered.
    elseif data._ExpiresAt then
     local seconds=remaining(data._ExpiresAt)
     local value=badge:FindFirstChild("Value")
     if value and value:IsA("TextLabel") then value.Text=timedText(seconds) or "0s" end
    end
   end
  end
 end
 if self.Hovered and self.Hovered.Badge and self.Hovered.Badge.Parent then
  self:PlaceTooltip(self.Hovered.Badge,self.Hovered.Item)
 end
end

return S
