local RS=game:GetService("ReplicatedStorage") local G=require(RS.Config.GardenSynergyConfig) local S={Key=""}
function S:Init(ui) self.UI=ui self.Folder=Instance.new("Folder") self.Folder.Name="LocalSynergyLines" self.Folder.Parent=workspace end
function S:Update()
 local state=self.UI.State if not state then return end local keys={} for id in pairs(state.Synergies) do table.insert(keys,id) end table.sort(keys) local key=table.concat(keys,",")..":"..state.Profile.Garden.Revision if key==self.Key then return end self.Key=key self.Folder:ClearAllChildren()
 local origin=state.HivePosition-Vector3.new(0,1,19)
 for _,r in pairs(state.Synergies) do for i=2,#r.Slots do local previous=r.Slots[i-1] local current=r.Slots[i] local a=Instance.new("Part") a.Anchored=true a.CanCollide=false a.CanTouch=false a.Transparency=1 a.Size=Vector3.new(.1,.1,.1) a.Position=origin+G.Position(previous)+Vector3.new(0,2,0) a.Parent=self.Folder local b=a:Clone() b.Position=origin+G.Position(current)+Vector3.new(0,2,0) b.Parent=self.Folder local aa=Instance.new("Attachment") aa.Parent=a local ab=Instance.new("Attachment") ab.Parent=b local beam=Instance.new("Beam") beam.Attachment0=aa beam.Attachment1=ab beam.Width0=.08 beam.Width1=.08 beam.FaceCamera=true beam.Color=ColorSequence.new(Color3.fromRGB(115,235,165)) beam.Parent=a end end
end return S
