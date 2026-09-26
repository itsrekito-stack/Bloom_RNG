local RS=game:GetService("ReplicatedStorage")
local G=require(RS.Config.GardenSynergyConfig)

local S={Key=""}

function S:Init(ui)
 self.UI=ui
 self.Folder=Instance.new("Folder")
 self.Folder.Name="LocalSynergyLines"
 self.Folder.Parent=workspace
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
