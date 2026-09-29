local RS=game:GetService("ReplicatedStorage")
local B=require(RS.Config.BeesConfig)
local Assets=require(RS.Shared.AuthoredMeshTemplates)
local Tween=game:GetService("TweenService")

local S={Models={}}

local function fallbackBee(id,parent)
 local cfg=B.Get(id)
 local part=Instance.new("Part")
 part.Name=id
 part.Size=Vector3.new(1.4,.8,1)
 part.Anchored=true
 part.CanCollide=false
 part.CanTouch=false
 part.CanQuery=false
 part.Color=cfg and cfg.Color or Color3.fromRGB(255,195,60)
 part.Parent=parent
 return {Part=part,Root=part}
end

local function modelBee(id,template,parent)
 local cfg=B.Get(id)
 Assets.ApplyTextureFallback(template,"Bee",cfg and cfg.Color or nil)
 Assets.Configure(template,true,false)
 if not Assets.ScaleToMaxDimension(template,1.9) or not Assets.CenterAt(template,Vector3.zero) then
  template:Destroy()
  return fallbackBee(id,parent)
 end

 if template:IsA("BasePart") then
  template.Name=id
  template.Parent=parent
  return {Part=template,Root=template}
 end

 if not template:IsA("Model") then
  template:Destroy()
  return fallbackBee(id,parent)
 end

 local container=Instance.new("Model")
 container.Name=id
 container.Parent=parent
 local anchor=Instance.new("Part")
 anchor.Name="MotionRoot"
 anchor.Size=Vector3.new(.15,.15,.15)
 anchor.Transparency=1
 anchor.Anchored=true
 anchor.CanCollide=false
 anchor.CanTouch=false
 anchor.CanQuery=false
 anchor.Parent=container
 template.Name="Visual"
 template.Parent=container

 local welded=0
 for _,part in ipairs(template:GetDescendants()) do
  if part:IsA("BasePart") then
   part.Anchored=false
   part.Massless=true
   part.CanCollide=false
   part.CanTouch=false
   part.CanQuery=false
   local weld=Instance.new("WeldConstraint")
   weld.Part0=anchor
   weld.Part1=part
   weld.Parent=anchor
   welded+=1
  end
 end
 if welded==0 then
  container:Destroy()
  return fallbackBee(id,parent)
 end
 return {Part=anchor,Root=container}
end

local function createBee(id,parent)
 local template=Assets.Clone("Bee")
 if not template then return fallbackBee(id,parent) end
 return modelBee(id,template,parent)
end

function S:Init(ui)
 self.UI=ui
 local old=workspace:FindFirstChild("LocalBees")
 if old then old:Destroy() end
 local f=Instance.new("Folder")
 f.Name="LocalBees"
 f.Parent=workspace
 self.Folder=f
end

function S:Update(frames)
 local keep={}
 for _,v in ipairs(frames) do
  if v.Owner==self.UI.Player.UserId or self.UI.State and self.UI.State.Profile.Settings.ShowOtherPollinators then
   local key=v.Owner.."_"..v.Index
   keep[key]=true
   local item=self.Models[key]
   if not item then
    item=createBee(v.Id,self.Folder)
    item.Owner=v.Owner
    self.Models[key]=item
   end
   local phase=v.Phase
   local pos=phase<.25 and v.From:Lerp(v.To,phase*4) or phase<.7 and v.To or v.To:Lerp(v.From,(phase-.7)/.3)
   if item.Tween then item.Tween:Cancel() end
   item.Tween=Tween:Create(item.Part,TweenInfo.new(1,Enum.EasingStyle.Linear),{Position=pos+Vector3.new(0,4,0)})
   item.Tween:Play()
  end
 end
 for key,item in pairs(self.Models) do
  if not keep[key] then
   if item.Tween then item.Tween:Cancel() end
   if item.Root then item.Root:Destroy() elseif item.Part then item.Part:Destroy() end
   self.Models[key]=nil
  end
 end
end

function S:Target(ownerOnly)
 for _,item in pairs(self.Models) do
  if item.Part and item.Part.Parent and (not ownerOnly or item.Owner==self.UI.Player.UserId) then return item.Part end
 end
end

return S
