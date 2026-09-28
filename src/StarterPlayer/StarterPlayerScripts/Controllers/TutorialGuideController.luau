local RS=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local T=require(RS.Config.TutorialConfig)
local L=require(RS.Config.LocationsConfig)
local Theme=require(RS.Config.UIThemeConfig)

local C=Theme.Colors
local S={}

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

 local prototypes=ui.SafeRoot and ui.SafeRoot:FindFirstChild("WorldUIPrototypes")
 local template=prototypes and prototypes:FindFirstChild("TutorialWorldLabelTemplate",true)
 if not template or not template:IsA("TextLabel") then
  error("[TutorialGuide] Authored TutorialWorldLabelTemplate missing from SafeRoot/WorldUIPrototypes")
 end
 local billText=template:Clone()
 billText.Name="Label"
 billText.Size=UDim2.fromScale(1,1)
 billText.Position=UDim2.fromScale(0,0)
 billText.Visible=true
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

 local secondaryHighlight=Instance.new("Highlight")
 secondaryHighlight.Name="BloomTutorialSecondaryHighlight"
 secondaryHighlight.FillColor=C.Blue
 secondaryHighlight.FillTransparency=.9
 secondaryHighlight.OutlineColor=C.Gold
 secondaryHighlight.OutlineTransparency=.08
 secondaryHighlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
 secondaryHighlight.Enabled=false
 secondaryHighlight.Parent=anchor
 self.SecondaryWorldHighlight=secondaryHighlight

 local linkStart=Instance.new("Part")
 linkStart.Name="BloomTutorialLinkStart"
 linkStart.Transparency=1
 linkStart.Anchored=true
 linkStart.CanCollide=false
 linkStart.CanTouch=false
 linkStart.CanQuery=false
 linkStart.Size=Vector3.new(.2,.2,.2)
 linkStart.Parent=workspace
 local linkEnd=linkStart:Clone()
 linkEnd.Name="BloomTutorialLinkEnd"
 linkEnd.Parent=workspace
 local linkStartAttachment=Instance.new("Attachment")
 linkStartAttachment.Parent=linkStart
 local linkEndAttachment=Instance.new("Attachment")
 linkEndAttachment.Parent=linkEnd
 local synergyLink=Instance.new("Beam")
 synergyLink.Attachment0=linkStartAttachment
 synergyLink.Attachment1=linkEndAttachment
 synergyLink.Width0=.08
 synergyLink.Width1=.08
 synergyLink.FaceCamera=true
 synergyLink.Color=ColorSequence.new(C.Gold)
 synergyLink.Transparency=NumberSequence.new(.18)
 synergyLink.Enabled=false
 synergyLink.Parent=anchor
 self.SynergyLinkStart=linkStart
 self.SynergyLinkEnd=linkEnd
 self.SynergyLink=synergyLink

 local frame=ui.SafeRoot:FindFirstChild("TutorialSpotlight")
 local callout=ui.SafeRoot:FindFirstChild("TutorialCallout")
 local arrow=ui.SafeRoot:FindFirstChild("TutorialScreenArrow")
 if not frame or not callout or not arrow then
  error("[TutorialGuide] Authored tutorial screen UI is incomplete. Expected TutorialSpotlight, TutorialCallout and TutorialScreenArrow in SafeRoot.")
 end
 self.Spotlight=frame
 self.SpotlightStroke=frame:FindFirstChildOfClass("UIStroke")
 self.SpotlightScale=frame:FindFirstChild("SpotlightScale")
 self.Callout=callout
 self.ScreenArrow=arrow
 self.ScreenArrowScale=arrow:FindFirstChild("ArrowScale")
 if not self.SpotlightStroke or not self.SpotlightScale or not self.ScreenArrowScale then
  error("[TutorialGuide] Authored tutorial screen UI modifiers are incomplete.")
 end

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
 self.SecondaryWorldHighlight.Enabled=false
 self.SecondaryWorldHighlight.Adornee=nil
 self.SynergyLink.Enabled=false
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
  if token then return token,"STEP HERE" end
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

function S:SetSynergyPartner(primary,partner)
 if not primary or not partner or not primary:IsA("BasePart") or not partner:IsA("BasePart") then return false end
 self.SecondaryWorldHighlight.Adornee=partner
 self.SecondaryWorldHighlight.Enabled=true
 self.SynergyLinkStart.Position=primary.Position+Vector3.new(0,1.2,0)
 self.SynergyLinkEnd.Position=partner.Position+Vector3.new(0,1.2,0)
 self.SynergyLink.Enabled=true
 return true
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
 if not ui.ReplayIndex and p.Settings and p.Settings.TutorialsEnabled==false then
  self:HideWorldTarget()
  self:HideScreenTarget()
  ui.Guide.Visible=false
  self.LastMissingKey=nil
  return
 end
 local step=T.Steps[ui.ReplayIndex or p.Tutorial.Step]

 if not ui.ReplayIndex and step then
  if (step.Id=="PollenSpark" or step.Id=="SunnyVisit") and ui.Menu then
   ui:Close({SuppressInventoryReturn=true})
  end
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

 if step.Target=="QuestsButton" then
  local button=ui.DockButtons.Trials
  if not button or not button.Visible then
   local inventory=ui.DockButtons.SeedSatchel
   if inventory and inventory.Visible then
    ui.Dock.Visible=true
    if self:PlaceScreenTarget(inventory,"OPEN INVENTORY","Open Inventory first to reveal the menu row, then choose Quests.") then self.LastMissingKey=nil else self:Missing(step) end
   else
    self:Missing(step)
   end
   return
  end
  ui.Dock.Visible=true
  if self:PlaceScreenTarget(button,"OPEN QUESTS",step.Helper) then self.LastMissingKey=nil else self:Missing(step) end
  return
 end

 if step.Target=="RouletteReward" then
  local resultTarget=ui.RouletteViewport
  if resultTarget and resultTarget.Visible then
   if self:PlaceScreenTarget(resultTarget,"FLOWER SEED",step.Helper) then self.LastMissingKey=nil else self:Missing(step) end
  else
   ui.Guide.Text=step.Helper or "Your Flower Seed is secured. Watch the roulette result."
   ui.Guide.Visible=true
   self.LastMissingKey=nil
  end
  return
 end

 if step.Target=="InventoryStats" then
  if ui.Menu~="SeedSatchel" then
   local button=ui.DockButtons.SeedSatchel
   if button and button.Visible then ui.Dock.Visible=true end
   if self:PlaceScreenTarget(button,"OPEN INVENTORY",step.Helper) then self.LastMissingKey=nil else self:Missing(step) end
   return
  end
  local runtime=ui.Content and ui.Content:FindFirstChild("InventoryV2Runtime",true)
  local stats=runtime and runtime:FindFirstChild("StatsCard",true)
  if stats and stats:IsA("GuiObject") and stats.Visible then
   if self:PlaceScreenTarget(stats,"OWNED • AVAILABLE • MASTERY",step.Helper) then self.LastMissingKey=nil else self:Missing(step) end
  else
   self:Missing(step)
  end
  return
 end

 if step.Target=="GardenEditorSlot" then
  if ui.Menu~="Garden" then
   local garden=ui.DockButtons.Garden
   if not garden or not garden.Visible then
    local inventory=ui.DockButtons.SeedSatchel
    if inventory and inventory.Visible then
     ui.Dock.Visible=true
     if self:PlaceScreenTarget(inventory,"OPEN INVENTORY","Open Inventory to reveal the menu row, then choose Garden.") then self.LastMissingKey=nil else self:Missing(step) end
    else
     self:Missing(step)
    end
    return
   end
   ui.Dock.Visible=true
   if self:PlaceScreenTarget(garden,"OPEN GARDEN",step.Helper) then self.LastMissingKey=nil else self:Missing(step) end
   return
  end

  local runtime=ui.Content and ui.Content:FindFirstChild("GardenRuntime",true)
  local flowerId=tostring(step.FlowerId or "")
  local selected=ui.GardenEditorState and ui.GardenEditorState.SelectedFlowerId
  if flowerId~="" and selected~=flowerId then
   local flowerCard=runtime and runtime:FindFirstChild("Flower_"..flowerId,true)
   if flowerCard and flowerCard:IsA("GuiObject") and flowerCard.Visible then
    if self:PlaceScreenTarget(flowerCard,"SELECT "..string.upper(flowerId),step.Helper) then self.LastMissingKey=nil else self:Missing(step) end
   else
    self:Missing(step)
   end
   return
  end

  local slot=runtime and runtime:FindFirstChild("Slot"..tostring(step.Slot or 1),true)
  if slot and slot:IsA("GuiObject") and slot.Visible then
   if self:PlaceScreenTarget(slot,"PLANT HERE",step.Helper) then self.LastMissingKey=nil else self:Missing(step) end
  else
   self:Missing(step)
  end
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
  if step.Target=="SynergySlot" then
   self:SetSynergyPartner(target,self:GardenSlot(step.PartnerSlot or 1))
  end
  self.LastMissingKey=nil
 else
  self:Missing(step)
 end
end

return S
