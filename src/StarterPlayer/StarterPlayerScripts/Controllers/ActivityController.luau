local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")

local A=require(RS.Config.ActivityConfig)

local S={Items={}}
local RETRY_SECONDS=.75

local COLORS={
 PollenSpark=Color3.fromRGB(245,214,92),
 NectarBud=Color3.fromRGB(115,225,155),
 DewDrop=Color3.fromRGB(135,210,255),
 PollenTrail=Color3.fromRGB(95,205,255),
 CrossPollination=Color3.fromRGB(255,150,220),
 Overcharge=Color3.fromRGB(195,105,245),
 BloomSurge=Color3.fromRGB(255,185,85),
 PollenWind=Color3.fromRGB(130,235,205),
 SolarBloom=Color3.fromRGB(255,210,70),
 CrystalResonance=Color3.fromRGB(105,215,255),
 ShadowBloom=Color3.fromRGB(140,105,220),
 FireflyRoute=Color3.fromRGB(220,240,105),
}

local NAMES={
 PollenSpark="POLLEN SPARK",
 NectarBud="NECTAR BUD",
 DewDrop="DEW DROP",
 PollenTrail="POLLEN TRAIL",
 CrossPollination="CROSS POLLINATION",
 Overcharge="OVERCHARGE",
 BloomSurge="BLOOM SURGE",
 PollenWind="POLLEN WIND",
 SolarBloom="SOLAR BLOOM",
 CrystalResonance="CRYSTAL RESONANCE",
 ShadowBloom="SHADOW BLOOM",
 FireflyRoute="FIREFLY ROUTE",
}

local function colorFor(kind)
 return COLORS[kind] or Color3.fromRGB(115,205,255)
end

local function displayName(kind)
 return NAMES[kind] or string.upper(tostring(kind or "ACTIVITY"))
end

local function destroyItem(item)
 if not item then return end
 if item.Model then item.Model:Destroy()
 elseif item.Part then item.Part:Destroy() end
end

function S:GroundPosition(position)
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 local exclude={self.Folder}
 if self.OtherFolder then table.insert(exclude,self.OtherFolder) end
 local character=self.UI and self.UI.Player and self.UI.Player.Character
 if character then table.insert(exclude,character) end
 params.FilterDescendantsInstances=exclude
 params.IgnoreWater=true
 local result=workspace:Raycast(position+Vector3.new(0,10,0),Vector3.new(0,-32,0),params)
 if result then return result.Position+Vector3.new(0,.12,0) end
 return position-Vector3.new(0,2.8,0)
end

function S:BuildCheckpoint(o)
 local cfg=A.Types[o.Kind] or {}
 local radius=tonumber(o.CheckpointRadius) or tonumber(cfg.CheckpointRadius) or tonumber(A.CheckpointRadius) or 4.5
 local vertical=tonumber(o.VerticalTolerance) or tonumber(A.CheckpointVerticalTolerance) or 5
 local color=colorFor(o.Kind)
 local reduced=self.UI.State and self.UI.State.Profile.Settings.ReducedEffects
 local ground=self:GroundPosition(o.Position)

 local model=Instance.new("Model")
 model.Name=tostring(o.Kind).."_Checkpoint_"..tostring(o.Id)
 model.Parent=self.Folder

 local diameter=math.max(4,radius*2)
 local pad=Instance.new("Part")
 pad.Name="CheckpointPad"
 pad.Shape=Enum.PartType.Cylinder
 pad.Size=Vector3.new(.18,diameter,diameter)
 pad.CFrame=CFrame.new(ground)*CFrame.Angles(0,0,math.rad(90))
 pad.Anchored=true
 pad.CanCollide=false
 pad.CanTouch=false
 pad.CanQuery=false
 pad.Material=reduced and Enum.Material.SmoothPlastic or Enum.Material.Neon
 pad.Color=color
 pad.Transparency=reduced and .42 or .18
 pad.Parent=model

 local core=Instance.new("Part")
 core.Name="CheckpointCore"
 core.Shape=Enum.PartType.Cylinder
 core.Size=Vector3.new(.12,diameter*.62,diameter*.62)
 core.CFrame=CFrame.new(ground+Vector3.new(0,.06,0))*CFrame.Angles(0,0,math.rad(90))
 core.Anchored=true
 core.CanCollide=false
 core.CanTouch=false
 core.CanQuery=false
 core.Material=Enum.Material.SmoothPlastic
 core.Color=Color3.fromRGB(20,30,42)
 core.Transparency=.18
 core.Parent=model

 local top=Instance.new("Part")
 top.Name="CheckpointTop"
 top.Size=Vector3.new(.15,.15,.15)
 top.Position=ground+Vector3.new(0,7,0)
 top.Transparency=1
 top.Anchored=true
 top.CanCollide=false
 top.CanTouch=false
 top.CanQuery=false
 top.Parent=model

 local a0=Instance.new("Attachment")
 a0.Parent=pad
 local a1=Instance.new("Attachment")
 a1.Parent=top
 local beam=Instance.new("Beam")
 beam.Name="CheckpointBeam"
 beam.Attachment0=a0
 beam.Attachment1=a1
 beam.Width0=.16
 beam.Width1=.04
 beam.FaceCamera=true
 beam.LightEmission=.8
 beam.Color=ColorSequence.new(color)
 beam.Transparency=NumberSequence.new({
  NumberSequenceKeypoint.new(0,reduced and .5 or .22),
  NumberSequenceKeypoint.new(1,.78),
 })
 beam.Parent=model

 local billboard=Instance.new("BillboardGui")
 billboard.Name="CheckpointLabel"
 billboard.Size=UDim2.fromOffset(190,54)
 billboard.AlwaysOnTop=true
 billboard.MaxDistance=180
 billboard.StudsOffset=Vector3.new(0,.7,0)
 billboard.Parent=top

 local prototypes=self.UI and self.UI.SafeRoot and self.UI.SafeRoot:FindFirstChild("WorldUIPrototypes")
 local template=prototypes and prototypes:FindFirstChild("ActivityCheckpointLabelTemplate",true)
 if not template or not template:IsA("TextLabel") then
  error("[ActivityController] Authored ActivityCheckpointLabelTemplate missing from SafeRoot/WorldUIPrototypes")
 end
 local label=template:Clone()
 label.Name="Label"
 label.Size=UDim2.fromScale(1,1)
 label.Position=UDim2.fromScale(0,0)
 label.Visible=true
 label.Text=string.format("%s  •  %d/%d\nSTEP INTO CHECKPOINT",displayName(o.Kind),o.Index or 1,o.Count or 1)
 label.Parent=billboard

 local light=Instance.new("PointLight")
 light.Color=color
 light.Range=math.max(9,radius*2.2)
 light.Brightness=reduced and .45 or 1
 light.Parent=pad

 if not reduced then
  TweenService:Create(
   pad,
   TweenInfo.new(.7,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),
   {Transparency=.38}
  ):Play()
 end

 return {
  Model=model,
  Part=pad,
  Core=core,
  Top=top,
  Label=label,
  NodePosition=o.Position,
  Index=o.Index or 1,
  Count=o.Count or 1,
  Kind=o.Kind,
  Expires=o.Expires,
  Radius=radius,
  VerticalTolerance=vertical,
  Sector=o.Sector,
  Tutorial=o.Tutorial==true,
  SentAt=-math.huge,
 }
end

function S:UpdateCheckpoint(item,o)
 item.NodePosition=o.Position
 item.Index=o.Index or item.Index or 1
 item.Count=o.Count or item.Count or 1
 item.Kind=o.Kind or item.Kind
 item.Expires=o.Expires
 item.Radius=tonumber(o.CheckpointRadius) or item.Radius
 item.VerticalTolerance=tonumber(o.VerticalTolerance) or item.VerticalTolerance
 item.Sector=o.Sector
 item.Tutorial=o.Tutorial==true
 local ground=self:GroundPosition(o.Position)
 item.Part.CFrame=CFrame.new(ground)*CFrame.Angles(0,0,math.rad(90))
 item.Core.CFrame=CFrame.new(ground+Vector3.new(0,.06,0))*CFrame.Angles(0,0,math.rad(90))
 item.Top.Position=ground+Vector3.new(0,7,0)
 item.Label.Text=string.format("%s  •  %d/%d\nSTEP INTO CHECKPOINT",displayName(item.Kind),item.Index,item.Count)
end

function S:Init(ui)
 self.UI=ui
 local folder=Instance.new("Folder")
 folder.Name="LocalBloomCheckpoints"
 folder.Parent=workspace
 self.Folder=folder

 self.CheckpointConnection=RunService.Heartbeat:Connect(function()
  local player=self.UI and self.UI.Player
  local character=player and player.Character
  local root=character and character:FindFirstChild("HumanoidRootPart")
  local humanoid=character and character:FindFirstChildOfClass("Humanoid")
  if not root or not humanoid or humanoid.Health<=0 then return end

  local now=os.clock()
  for id,item in pairs(self.Items) do
   if item.Part and item.Part.Parent and item.NodePosition then
    local delta=root.Position-item.NodePosition
    local horizontal=Vector2.new(delta.X,delta.Z).Magnitude
    local inside=horizontal<=item.Radius and math.abs(delta.Y)<=item.VerticalTolerance
    if inside and now-(item.SentAt or -math.huge)>=RETRY_SECONDS then
     item.SentAt=now
     self.UI:Send("Activity",id,item.Index,"Reach")
    end
   end
  end
 end)
end

function S:Update(list)
 local keep={}
 for _,o in ipairs(list) do
  keep[o.Id]=true
  local item=self.Items[o.Id]
  if item and item.Index~=o.Index then
   destroyItem(item)
   self.Items[o.Id]=nil
   item=nil
  end
  if not item then
   item=self:BuildCheckpoint(o)
   self.Items[o.Id]=item
  else
   self:UpdateCheckpoint(item,o)
  end
 end
 for id,item in pairs(self.Items) do
  if not keep[id] then
   destroyItem(item)
   self.Items[id]=nil
  end
 end
end

function S:BuildOtherCheckpoint(o)
 local color=colorFor(o.Kind)
 local ground=self:GroundPosition(o.Position)
 local part=Instance.new("Part")
 part.Name=tostring(o.Kind or "Activity").."_OtherCheckpoint"
 part.Shape=Enum.PartType.Cylinder
 part.Size=Vector3.new(.12,4.4,4.4)
 part.CFrame=CFrame.new(ground)*CFrame.Angles(0,0,math.rad(90))
 part.Anchored=true
 part.CanCollide=false
 part.CanTouch=false
 part.CanQuery=false
 part.Material=Enum.Material.Neon
 part.Color=color
 part.Transparency=.68
 part.Parent=self.OtherFolder
 return part
end

function S:Others(list)
 if not self.OtherFolder then
  self.OtherFolder=Instance.new("Folder")
  self.OtherFolder.Name="OtherBloomCheckpoints"
  self.OtherFolder.Parent=workspace
 end
 self.OtherItems=self.OtherItems or {}
 local keep={}
 if self.UI.State and not self.UI.State.Profile.Settings.HideOtherPlayersTokens then
  for _,o in ipairs(list) do
   if o.Owner~=self.UI.Player.UserId then
    keep[o.Id]=true
    local part=self.OtherItems[o.Id]
    if not part then
     part=self:BuildOtherCheckpoint(o)
     self.OtherItems[o.Id]=part
    else
     local ground=self:GroundPosition(o.Position)
     part.CFrame=CFrame.new(ground)*CFrame.Angles(0,0,math.rad(90))
    end
   end
  end
 end
 for id,part in pairs(self.OtherItems) do
  if not keep[id] then
   part:Destroy()
   self.OtherItems[id]=nil
  end
 end
end

function S:Target(mode)
 for _,item in pairs(self.Items) do
  if mode=="Tutorial" and item.Tutorial then return item.Part end
  if mode=="Sector" and item.Sector then return item.Part end
  if mode==nil then return item.Part end
 end
end

function S:TargetKind(kind)
 for _,item in pairs(self.Items) do
  if item.Kind==kind and item.Part and item.Part.Parent then
   return item.Part,item.Index or 1,item.Count or 1
  end
 end
 return nil,nil,nil
end

function S:RemoveItem(id)
 local item=self.Items[id]
 if not item then return false end
 destroyItem(item)
 self.Items[id]=nil
 return true
end

function S:Cleanup()
 self:Update({})
end

return S
