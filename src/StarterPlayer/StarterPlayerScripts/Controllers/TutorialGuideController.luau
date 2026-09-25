local RS=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local T=require(RS.Config.TutorialConfig)
local L=require(RS.Config.LocationsConfig)
local Theme=require(RS.Config.UIThemeConfig)

local C=Theme.Colors
local S={}

local function corner(x,r)
 local c=Instance.new("UICorner")
 c.CornerRadius=UDim.new(0,r)
 c.Parent=x
 return c
end

local function outline(x,color,thickness,transparency)
 local s=Instance.new("UIStroke")
 s.Color=color
 s.Thickness=thickness
 s.Transparency=transparency or 0
 s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
 s.Parent=x
 return s
end

local function worldPosition(target)
 if typeof(target)=="Vector3" then return target end
 if typeof(target)=="Instance" then
  if target:IsA("BasePart") then return target.Position end
  if target:IsA("Model") then return target:GetPivot().Position end
 end
 return nil
end

function S:Init(ui)
 self.UI=ui

 local anchor=Instance.new("Part")
 anchor.Name="LocalGuideTarget"
 anchor.Transparency=1
 anchor.Anchored=true
 anchor.CanCollide=false
 anchor.CanTouch=false
 anchor.CanQuery=false
 anchor.Size=Vector3.new(.25,.25,.25)
 anchor.Parent=workspace
 self.Target=anchor

 local bill=Instance.new("BillboardGui")
 bill.Name="BloomTutorialWorldArrow"
 bill.Size=UDim2.fromOffset(210,76)
 bill.StudsOffset=Vector3.new(0,1.6,0)
 bill.AlwaysOnTop=true
 bill.MaxDistance=260
 bill.Enabled=false
 bill.Parent=anchor
 self.Billboard=bill

 local billText=Instance.new("TextLabel")
 billText.Size=UDim2.fromScale(1,1)
 billText.BackgroundTransparency=1
 billText.Text="TARGET\n▼"
 billText.TextSize=19
 billText.TextColor3=C.Gold
 billText.TextStrokeColor3=C.Black
 billText.TextStrokeTransparency=.28
 billText.Font=Enum.Font.GothamBlack
 billText.TextWrapped=true
 billText.Parent=bill
 self.BillboardText=billText

 self.Attachment=Instance.new("Attachment")
 self.Attachment.Parent=anchor
 self.Beam=Instance.new("Beam")
 self.Beam.Attachment1=self.Attachment
 self.Beam.Width0=.09
 self.Beam.Width1=.14
 self.Beam.FaceCamera=true
 self.Beam.Color=ColorSequence.new({
  ColorSequenceKeypoint.new(0,C.Blue),
  ColorSequenceKeypoint.new(1,C.Gold),
 })
 self.Beam.Transparency=NumberSequence.new({
  NumberSequenceKeypoint.new(0,.12),
  NumberSequenceKeypoint.new(1,.42),
 })
 self.Beam.Enabled=false
 self.Beam.Parent=anchor

 local highlight=Instance.new("Highlight")
 highlight.Name="BloomTutorialHighlight"
 highlight.FillColor=C.Gold
 highlight.FillTransparency=.82
 highlight.OutlineColor=C.Blue
 highlight.OutlineTransparency=.05
 highlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
 highlight.Enabled=false
 highlight.Parent=anchor
 self.WorldHighlight=highlight

 local frame=Instance.new("Frame")
 frame.Name="TutorialSpotlight"
 frame.AnchorPoint=Vector2.new(.5,.5)
 frame.BackgroundColor3=C.Gold
 frame.BackgroundTransparency=.92
 frame.BorderSizePixel=0
 frame.Visible=false
 frame.ZIndex=90
 frame.Parent=ui.SafeRoot
 corner(frame,Theme.Radius.Large)
 self.Spotlight=frame
 self.SpotlightStroke=outline(frame,C.Gold,4,0)
 self.SpotlightScale=Instance.new("UIScale")
 self.SpotlightScale.Scale=1
 self.SpotlightScale.Parent=frame

 local callout=Instance.new("TextLabel")
 callout.Name="TutorialCallout"
 callout.AnchorPoint=Vector2.new(.5,.5)
 callout.Size=UDim2.fromOffset(230,42)
 callout.BackgroundColor3=C.Panel
 callout.BackgroundTransparency=.02
 callout.BorderSizePixel=0
 callout.Text=""
 callout.TextColor3=C.Text
 callout.TextSize=12
 callout.Font=Enum.Font.GothamBold
 callout.TextWrapped=true
 callout.Visible=false
 callout.ZIndex=92
 callout.Parent=ui.SafeRoot
 corner(callout,Theme.Radius.Medium)
 outline(callout,C.BorderDark,2,0)
 self.Callout=callout

 local arrow=Instance.new("TextLabel")
 arrow.Name="TutorialScreenArrow"
 arrow.AnchorPoint=Vector2.new(.5,.5)
 arrow.Size=UDim2.fromOffset(28,28)
 arrow.BackgroundTransparency=1
 arrow.Text="▼"
 arrow.TextColor3=C.Gold
 arrow.TextStrokeColor3=C.Black
 arrow.TextStrokeTransparency=.25
 arrow.TextSize=24
 arrow.Font=Enum.Font.GothamBlack
 arrow.Visible=false
 arrow.ZIndex=93
 arrow.Parent=ui.SafeRoot
 self.ScreenArrow=arrow
 self.ScreenArrowScale=Instance.new("UIScale")
 self.ScreenArrowScale.Parent=arrow

 TweenService:Create(self.SpotlightScale,TweenInfo.new(.6,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Scale=1.06}):Play()
 TweenService:Create(self.SpotlightStroke,TweenInfo.new(.6,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Transparency=.4,Thickness=2}):Play()
 TweenService:Create(self.ScreenArrowScale,TweenInfo.new(.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Scale=1.16}):Play()
end

function S:HideScreenTarget()
 self.Spotlight.Visible=false
 self.Callout.Visible=false
 self.ScreenArrow.Visible=false
end

function S:HideWorldTarget()
 self.Billboard.Enabled=false
 self.Beam.Enabled=false
 self.WorldHighlight.Enabled=false
 self.WorldHighlight.Adornee=nil
end

function S:PlaceScreenTarget(button,label,helper)
 local ui=self.UI
 local root=ui.SafeRoot
 if not button or not button.Parent or not button.Visible or not root or root.AbsoluteSize.X<=0 then
  self:HideScreenTarget()
  return false
 end

 local rootPos=root.AbsolutePosition
 local rootSize=root.AbsoluteSize
 local absolute=button.AbsolutePosition
 local targetSize=button.AbsoluteSize
 local localX=absolute.X-rootPos.X
 local localY=absolute.Y-rootPos.Y
 local w=math.clamp(targetSize.X+18,58,math.max(58,rootSize.X-20))
 local h=math.clamp(targetSize.Y+18,54,math.max(54,rootSize.Y-20))
 local cx=math.clamp(localX+targetSize.X*.5,w*.5+8,rootSize.X-w*.5-8)
 local cy=math.clamp(localY+targetSize.Y*.5,h*.5+8,rootSize.Y-h*.5-8)

 self.Spotlight.Size=UDim2.fromOffset(w,h)
 self.Spotlight.Position=UDim2.fromOffset(cx,cy)
 self.Spotlight.Visible=true

 local calloutW=math.min(260,math.max(150,rootSize.X-20))
 self.Callout.Size=UDim2.fromOffset(calloutW,42)
 self.Callout.Text=label
 local above=cy-h*.5-34
 local calloutY=above>28 and above or cy+h*.5+34
 calloutY=math.clamp(calloutY,24,rootSize.Y-24)
 local calloutX=math.clamp(cx,calloutW*.5+8,rootSize.X-calloutW*.5-8)
 self.Callout.Position=UDim2.fromOffset(calloutX,calloutY)
 self.Callout.Visible=true

 local arrowY=math.clamp(cy-h*.5-14,14,rootSize.Y-14)
 self.ScreenArrow.Position=UDim2.fromOffset(cx,arrowY)
 self.ScreenArrow.Visible=true

 if helper and helper~="" then
  ui.Guide.Text=helper
  ui.Guide.Visible=true
 end
 return true
end

function S:SetWorldTarget(target,label,helper)
 local pos=worldPosition(target)
 if not pos then self:HideWorldTarget() return false end

 self.Target.Position=pos+Vector3.new(0,7,0)
 self.BillboardText.Text=(label or "TARGET").."\n▼"
 self.Billboard.Enabled=true

 if typeof(target)=="Instance" then
  self.WorldHighlight.Adornee=target
  self.WorldHighlight.Enabled=true
 else
  self.WorldHighlight.Adornee=nil
  self.WorldHighlight.Enabled=false
 end

 local root=self.UI.Player.Character and self.UI.Player.Character:FindFirstChild("HumanoidRootPart")
 if not root then
  self.Beam.Enabled=false
  return true
 end
 if not self.RootAttachment or self.RootAttachment.Parent~=root then
  if self.RootAttachment then self.RootAttachment:Destroy() end
  self.RootAttachment=Instance.new("Attachment")
  self.RootAttachment.Parent=root
  self.Beam.Attachment0=self.RootAttachment
 end
 local distance=(root.Position-pos).Magnitude
 self.Beam.Enabled=distance>15
 self.UI.Guide.Text=(helper or label or "Target").."  •  "..math.floor(distance).." studs"
 self.UI.Guide.Visible=true
 return true
end

function S:PlayerPlot()
 local world=workspace:FindFirstChild("BloomWorld")
 return world and world:FindFirstChild("Garden_"..self.UI.Player.UserId)
end

function S:GardenSlot(slot)
 local plot=self:PlayerPlot()
 if not plot then return nil end
 return plot:FindFirstChild("Slot_"..tostring(slot),true)
end

function S:ResolveWorldTarget(step)
 local ui=self.UI
 local target=step.Target
 local world=workspace:FindFirstChild("BloomWorld")
 local plot=self:PlayerPlot()

 if target=="Hive" then
  local hive=plot and plot:FindFirstChild("Hive")
  if hive and hive:IsA("BasePart") then return hive,"HIVE" end
  return ui.State and ui.State.HivePosition,"HIVE"
 elseif target=="Bee" then
  local bee=ui.Bees and ui.Bees:Target(true)
  if bee then return bee,"YOUR BEE" end
  local ground=plot and plot:FindFirstChild("Ground")
  if ground then return ground,"GARDEN" end
 elseif target=="TutorialToken" then
  local token=ui.Activities and ui.Activities:Target("Tutorial")
  if token then return token,"TOUCH" end
 elseif target=="GardenSlot" then
  local slot=self:GardenSlot(step.Slot or 3)
  if slot then return slot,"PLANT HERE" end
 elseif target=="SynergySlot" then
  local slot=self:GardenSlot(step.Slot or 2)
  if slot then return slot,"SYNERGY SLOT" end
 elseif target=="Workshop" then
  local part=world and world:FindFirstChild("Workshop")
  if part and part:IsA("BasePart") then return part,"WORKSHOP" end
 elseif L.Sectors[target] then
  local gate=world and world:FindFirstChild(target.."Gate")
  if gate and gate:IsA("BasePart") then return gate,string.upper(L.Sectors[target].Name) end
 end
 return nil,nil
end

function S:Missing(step)
 local key=tostring(step.Id)..":"..tostring(step.Target)
 if self.LastMissingKey~=key then
  self.LastMissingKey=key
  warn(string.format("[Tutorial] target missing step=%s target=%s",tostring(step.Id),tostring(step.Target)))
 end
 self.UI.Guide.Text=step.Helper or "Target is loading. The guide will reconnect automatically."
 self.UI.Guide.Visible=true
end

function S:Update()
 local ui=self.UI
 if not ui.State then return end
 local p=ui.State.Profile
 local step=T.Steps[ui.ReplayIndex or p.Tutorial.Step]

 if not ui.ReplayIndex and step then
  if step.Id=="Delivery" and ui.Menu=="SeedSatchel" then ui:Close() end
  if step.Id=="Synergy" and ui.Menu=="Workshop" then ui:Close() end
 end

 self:HideWorldTarget()
 self:HideScreenTarget()
 ui.Guide.Visible=false
 if not step then self.LastMissingKey=nil return end

 if step.Target=="Roll" then
  if self:PlaceScreenTarget(ui.Roll,"CLICK ROLL",step.Helper) then self.LastMissingKey=nil else self:Missing(step) end
  return
 end

 if step.Target=="SeedSatchel" then
  local button=ui.DockButtons.SeedSatchel
  if button and button.Visible then ui.Dock.Visible=true end
  if self:PlaceScreenTarget(button,"OPEN INVENTORY",step.Helper) then self.LastMissingKey=nil else self:Missing(step) end
  return
 end

 if step.Target=="WorkshopNode" then
  local runtime=ui.WorkshopRuntime
  local node=runtime and runtime:FindFirstChild("Node_"..tostring(step.NodeId or "ROLL_1"),true)
  if node and node:IsA("GuiObject") and node.Visible then
   if self:PlaceScreenTarget(node,"BUY "..tostring(step.NodeId or "ROLL_1"),step.Helper) then self.LastMissingKey=nil return end
  end
  local world=workspace:FindFirstChild("BloomWorld")
  local workshop=world and world:FindFirstChild("Workshop")
  if workshop then
   self:SetWorldTarget(workshop,"WORKSHOP","Open the Workshop to continue.")
   self.LastMissingKey=nil
  else
   self:Missing(step)
  end
  return
 end

 local target,label=self:ResolveWorldTarget(step)
 if target then
  self:SetWorldTarget(target,label,step.Helper)
  self.LastMissingKey=nil
 else
  self:Missing(step)
 end
end

return S
