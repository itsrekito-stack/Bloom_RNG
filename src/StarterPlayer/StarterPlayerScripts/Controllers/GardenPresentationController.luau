local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")

local G=require(RS.Config.GardenSynergyConfig)

local FLOWER_DETAIL_DISTANCE=24
local FLOWER_REFRESH_SECONDS=.12

local S={Key="",FlowerAccumulator=0,FocusedFlowerInfo=nil}

local function flowerInfoPosition(info)
 local parent=info and info.Parent
 return parent and parent:IsA("BasePart") and parent.Position or nil
end

function S:Init(ui)
 self.UI=ui
 self.Folder=Instance.new("Folder")
 self.Folder.Name="LocalSynergyLines"
 self.Folder.Parent=workspace

 self.FlowerConnection=RunService.RenderStepped:Connect(function(dt)
  self.FlowerAccumulator+=dt
  if self.FlowerAccumulator<FLOWER_REFRESH_SECONDS then return end
  self.FlowerAccumulator=0
  self:RefreshFlowerFocus()
 end)
end

function S:RefreshFlowerFocus()
 local ui=self.UI
 local player=ui and ui.Player
 local character=player and player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local world=workspace:FindFirstChild("BloomWorld")
 local allowDetail=root~=nil and world~=nil and ui.Menu==nil and not ui:IsWorkshopExclusive()

 local nearest=nil
 local nearestDistance=FLOWER_DETAIL_DISTANCE
 if allowDetail then
  for _,descendant in ipairs(world:GetDescendants()) do
   if descendant:IsA("BillboardGui") and descendant.Name=="FlowerInfo" then
    local position=flowerInfoPosition(descendant)
    if position then
     local distance=(root.Position-position).Magnitude
     if distance<nearestDistance then
      nearestDistance=distance
      nearest=descendant
     end
    end
   end
  end
 end

 if self.FocusedFlowerInfo and self.FocusedFlowerInfo~=nearest and self.FocusedFlowerInfo.Parent then
  self.FocusedFlowerInfo.Enabled=false
 end

 if world then
  for _,descendant in ipairs(world:GetDescendants()) do
   if descendant:IsA("BillboardGui") and descendant.Name=="FlowerInfo" then
    descendant.Enabled=descendant==nearest
   end
  end
 end
 self.FocusedFlowerInfo=nearest
end

function S:Update()
 local state=self.UI.State
 if not state then return end

 local hivePosition=state.HivePosition
 local synergies=type(state.Synergies)=="table" and state.Synergies or {}
 if typeof(hivePosition)~="Vector3" then
  if self.Key~="" then
   self.Key=""
   self.Folder:ClearAllChildren()
  end
  return
 end

 local keys={}
 for id in pairs(synergies) do table.insert(keys,tostring(id)) end
 table.sort(keys)
 local revision=state.Profile and state.Profile.Garden and state.Profile.Garden.Revision or 0
 local key=table.concat(keys,",")..":"..tostring(revision)..":"..tostring(hivePosition)
 if key==self.Key then return end

 self.Key=key
 self.Folder:ClearAllChildren()

 local origin=hivePosition-Vector3.new(0,1,19)
 for _,relation in pairs(synergies) do
  local slots=type(relation)=="table" and relation.Slots or nil
  if type(slots)=="table" then
   for i=2,#slots do
    local previous=slots[i-1]
    local current=slots[i]
    local previousOffset=G.Position(previous)
    local currentOffset=G.Position(current)
    if typeof(previousOffset)=="Vector3" and typeof(currentOffset)=="Vector3" then
     local a=Instance.new("Part")
     a.Anchored=true
     a.CanCollide=false
     a.CanTouch=false
     a.CanQuery=false
     a.Transparency=1
     a.Size=Vector3.new(.1,.1,.1)
     a.Position=origin+previousOffset+Vector3.new(0,2,0)
     a.Parent=self.Folder

     local b=a:Clone()
     b.Position=origin+currentOffset+Vector3.new(0,2,0)
     b.Parent=self.Folder

     local aa=Instance.new("Attachment")
     aa.Parent=a
     local ab=Instance.new("Attachment")
     ab.Parent=b

     local beam=Instance.new("Beam")
     beam.Attachment0=aa
     beam.Attachment1=ab
     beam.Width0=.08
     beam.Width1=.08
     beam.FaceCamera=true
     beam.Color=ColorSequence.new(Color3.fromRGB(115,235,165))
     beam.Parent=a
    end
   end
  end
 end
end

return S
