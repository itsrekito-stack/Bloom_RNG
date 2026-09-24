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

function S:Init(ui)
 self.UI=ui

 local a=Instance.new("Part")
 a.Name="LocalGuideTarget"
 a.Transparency=1
 a.Anchored=true
 a.CanCollide=false
 a.CanTouch=false
 a.CanQuery=false
 a.Size=Vector3.new(.25,.25,.25)
 a.Parent=workspace
 self.Target=a

 local bill=Instance.new("BillboardGui")
 bill.Name="BloomTutorialWorldArrow"
 bill.Size=UDim2.fromOffset(190,72)
 bill.StudsOffset=Vector3.new(0,1.5,0)
 bill.AlwaysOnTop=true
 bill.MaxDistance=220
 bill.Enabled=false
 bill.Parent=a
 self.Billboard=bill

 local billText=Instance.new("TextLabel")
 billText.Size=UDim2.fromScale(1,1)
 billText.BackgroundTransparency=1
 billText.Text="ЦЕЛЬ\n▼"
 billText.TextSize=19
 billText.TextColor3=C.Gold
 billText.TextStrokeColor3=C.Black
 billText.TextStrokeTransparency=.35
 billText.Font=Enum.Font.GothamBlack
 billText.TextWrapped=true
 billText.Parent=bill
 self.BillboardText=billText

 self.Attachment=Instance.new("Attachment")
 self.Attachment.Parent=a
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
 self.Beam.Parent=a

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
 callout.Size=UDim2.fromOffset(190,38)
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

 TweenService:Create(self.SpotlightScale,TweenInfo.new(.6,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Scale=1.06}):Play()
 TweenService:Create(self.SpotlightStroke,TweenInfo.new(.6,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Transparency=.4,Thickness=2}):Play()
end

function S:HideScreenTarget()
 self.Spotlight.Visible=false
 self.Callout.Visible=false
end

function S:PlaceScreenTarget(button,label)
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

 local calloutW=math.min(210,math.max(140,rootSize.X-20))
 self.Callout.Size=UDim2.fromOffset(calloutW,38)
 self.Callout.Text=label
 local above=cy-h*.5-30
 local calloutY
 if above>26 then
  calloutY=above
 else
  calloutY=cy+h*.5+30
 end
 calloutY=math.clamp(calloutY,22,rootSize.Y-22)
 local calloutX=math.clamp(cx,calloutW*.5+8,rootSize.X-calloutW*.5-8)
 self.Callout.Position=UDim2.fromOffset(calloutX,calloutY)
 self.Callout.Visible=true
 return true
end

function S:SetWorldTarget(pos,label)
 if not pos then
  self.Billboard.Enabled=false
  self.Beam.Enabled=false
  return
 end
 self.Target.Position=pos+Vector3.new(0,7,0)
 self.BillboardText.Text=(label or "ЦЕЛЬ").."\n▼"
 self.Billboard.Enabled=true

 local root=self.UI.Player.Character and self.UI.Player.Character:FindFirstChild("HumanoidRootPart")
 if not root then
  self.Beam.Enabled=false
  return
 end
 if not self.RootAttachment or self.RootAttachment.Parent~=root then
  if self.RootAttachment then self.RootAttachment:Destroy() end
  self.RootAttachment=Instance.new("Attachment")
  self.RootAttachment.Parent=root
  self.Beam.Attachment0=self.RootAttachment
 end
 local distance=(root.Position-pos).Magnitude
 self.Beam.Enabled=distance>30
 self.UI.Guide.Text=(label or "Цель").."   •   "..math.floor(distance).." м"
 self.UI.Guide.Visible=true
end

function S:ResolveWorldTarget(target)
 local ui=self.UI
 local world=workspace:FindFirstChild("BloomWorld")
 local hivePos=ui.State and ui.State.HivePosition
 if target=="Hive" then return hivePos,"УЛЕЙ" end
 if target=="Garden" then
  local plot=world and world:FindFirstChild("Garden_"..ui.Player.UserId)
  local ground=plot and plot:FindFirstChild("Ground")
  if ground and ground:IsA("BasePart") then return ground.Position+Vector3.new(0,1,0),"САД" end
  if hivePos then return hivePos-Vector3.new(0,1,19),"САД" end
 elseif target=="Token" then
  local token=ui.Activities:Target()
  if token then return token.Position,"АКТИВНОСТЬ" end
 elseif target=="Workshop" then
  local part=world and world:FindFirstChild("Workshop")
  if part and part:IsA("BasePart") then return part.Position,"МАСТЕРСКАЯ" end
 elseif L.Sectors[target] then
  local part=world and world:FindFirstChild(target.."Gate")
  if part and part:IsA("BasePart") then return part.Position,string.upper(L.Sectors[target].Name) end
 end
 return nil,nil
end

function S:Update()
 local ui=self.UI
 if not ui.State then return end
 local p=ui.State.Profile
 local step=T.Steps[ui.ReplayIndex or p.Tutorial.Step]
 local target=step and step.Target

 self.Billboard.Enabled=false
 self.Beam.Enabled=false
 self:HideScreenTarget()
 ui.Guide.Visible=false
 if not target then return end

 if target=="Roll" then
  if self:PlaceScreenTarget(ui.Roll,"НАЖМИ ROLL") then
   -- The persistent guide banner already explains the action. Keeping a second
   -- callout above the bottom HUD caused it to overlap Bloom/Roll on short screens.
   self.Callout.Visible=false
   ui.Guide.Text="Следующий шаг: запусти auto roll"
   ui.Guide.Visible=true
  end
  return
 end

 if target=="SeedSatchel" then
  if ui.DockButtons.SeedSatchel and ui.DockButtons.SeedSatchel.Visible then ui.Dock.Visible=true end
  if self:PlaceScreenTarget(ui.DockButtons.SeedSatchel,"ОТКРОЙ СУМКУ СЕМЯН") then
   ui.Guide.Text="Следующий шаг: открой сумку семян"
   ui.Guide.Visible=true
  end
  return
 end

 local pos,label=self:ResolveWorldTarget(target)
 if target=="Token" and not pos then
  ui.Guide.Text="Ожидай следующую активность — указатель появится автоматически"
  ui.Guide.Visible=true
  return
 end
 if pos then self:SetWorldTarget(pos,label) end
end

return S
