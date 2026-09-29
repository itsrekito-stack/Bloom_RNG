local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")

local B=require(RS.Config.BeesConfig)
local Bloom=require(RS.Config.BloomConfig)
local Assets=require(RS.Shared.AuthoredMeshTemplates)

local S={Models={},Frames={}}

local BEE_FORWARD_FIX=CFrame.Angles(0,math.rad(90),0)
local FLIGHT_HEIGHT=2.85
local TRAVEL_ARC=.72
local BOB_AMOUNT=.14
local BOB_SPEED=7.5
local HOVER_RADIUS=.20
local TURN_RESPONSE=14
local GOLDEN_ANGLE=2.399963229728653

local function phaseSeed(owner,index)
 local a=tonumber(owner) or 0
 local b=tonumber(index) or 0
 return ((a%997)*.013+(b%37)*1.73)%100
end

local function spreadOffset(index,radius)
 local n=math.max(1,math.floor(tonumber(index) or 1))
 local angle=(n-1)*GOLDEN_ANGLE
 local ring=radius*(.88+((n-1)%3)*.10)
 return Vector3.new(math.cos(angle)*ring,((n-1)%2)*.16,math.sin(angle)*ring)
end

local function destroyItem(item)
 if item and item.Root then item.Root:Destroy()
 elseif item and item.Part then item.Part:Destroy() end
end

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
 return {
  Id=id,
  Part=part,
  Root=part,
  Wings={},
  Seed=0,
  Initialized=false,
  LastDirection=Vector3.new(0,0,-1),
 }
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
  return {
   Id=id,
   Part=template,
   Root=template,
   Wings={},
   Seed=0,
   Initialized=false,
   LastDirection=Vector3.new(0,0,-1),
  }
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

 local wings={}
 local welded=0
 for _,part in ipairs(template:GetDescendants()) do
  if part:IsA("BasePart") then
   local relative=anchor.CFrame:ToObjectSpace(part.CFrame)
   local lower=string.lower(part.Name)
   local side=relative.Position.Z>=0 and 1 or -1
   part.Anchored=false
   part.Massless=true
   part.CanCollide=false
   part.CanTouch=false
   part.CanQuery=false

   local weld=Instance.new("Weld")
   weld.Name="VisualWeld"
   weld.Part0=anchor
   weld.Part1=part
   weld.C0=relative
   weld.C1=CFrame.identity
   weld.Parent=anchor
   if string.find(lower,"wing",1,true) then
    table.insert(wings,{Weld=weld,Base=relative,Side=side})
   end
   welded+=1
  end
 end

 if welded==0 then
  container:Destroy()
  return fallbackBee(id,parent)
 end

 return {
  Id=id,
  Part=anchor,
  Root=container,
  Wings=wings,
  Seed=0,
  Initialized=false,
  LastDirection=Vector3.new(0,0,-1),
 }
end

local function createBee(id,parent)
 local template=Assets.Clone("Bee")
 if not template then return fallbackBee(id,parent) end
 return modelBee(id,template,parent)
end

local function eased(t)
 t=math.clamp(t,0,1)
 return t*t*(3-2*t)
end

local function estimatedPhase(frame,receivedAt,now)
 local duration=math.max(.1,tonumber(Bloom.DeliverySeconds) or 1)
 return math.clamp((tonumber(frame.Phase) or 0)+(now-receivedAt)/duration,0,1)
end

local function routePose(frame,index,seed,phase,now,lastDirection)
 local from=frame.From+spreadOffset(index,1.75)+Vector3.new(0,FLIGHT_HEIGHT,0)
 local to=frame.To+spreadOffset(index,.34)+Vector3.new(0,FLIGHT_HEIGHT,0)
 local position
 local direction

 if phase<.25 then
  local t=eased(phase/.25)
  position=from:Lerp(to,t)+Vector3.new(0,math.sin(t*math.pi)*TRAVEL_ARC,0)
  direction=to-from
 elseif phase<.70 then
  local orbit=(now*1.9+seed)
  local hover=Vector3.new(math.cos(orbit)*HOVER_RADIUS,0,math.sin(orbit)*HOVER_RADIUS)
  position=to+hover
  direction=Vector3.new(-math.sin(orbit),0,math.cos(orbit))
 else
  local t=eased((phase-.70)/.30)
  position=to:Lerp(from,t)+Vector3.new(0,math.sin(t*math.pi)*TRAVEL_ARC,0)
  direction=from-to
 end

 position+=Vector3.new(0,math.sin(now*BOB_SPEED+seed)*BOB_AMOUNT,0)
 if direction.Magnitude<.001 then direction=lastDirection end
 direction=Vector3.new(direction.X,math.clamp(direction.Y,-.35,.35),direction.Z)
 if direction.Magnitude<.001 then direction=Vector3.new(0,0,-1) end
 return position,direction.Unit
end

local function animateWings(item,now)
 if not item.Wings or #item.Wings==0 then return end
 local flap=math.sin(now*30+item.Seed)*math.rad(23)
 for _,wing in ipairs(item.Wings) do
  if wing.Weld and wing.Weld.Parent then
   wing.Weld.C0=wing.Base*CFrame.Angles(flap*wing.Side,0,0)
  end
 end
end

function S:Init(ui)
 self.UI=ui
 if self.StepConnection then self.StepConnection:Disconnect() end
 for _,item in pairs(self.Models) do destroyItem(item) end
 self.Models={}
 self.Frames={}

 local old=workspace:FindFirstChild("LocalBees")
 if old then old:Destroy() end
 local folder=Instance.new("Folder")
 folder.Name="LocalBees"
 folder.Parent=workspace
 self.Folder=folder

 self.StepConnection=RunService.RenderStepped:Connect(function(dt)
  self:Step(dt)
 end)
end

function S:Update(frames)
 local now=os.clock()
 local nextFrames={}
 local showOthers=self.UI.State and self.UI.State.Profile.Settings.ShowOtherPollinators
 for _,frame in ipairs(frames) do
  if frame.Owner==self.UI.Player.UserId or showOthers then
   local key=tostring(frame.Owner).."_"..tostring(frame.Index)
   local item=self.Models[key]
   if item and item.Id~=frame.Id then
    destroyItem(item)
    self.Models[key]=nil
    item=nil
   end
   if not item then
    item=createBee(frame.Id,self.Folder)
    item.Owner=frame.Owner
    item.Seed=phaseSeed(frame.Owner,frame.Index)
    self.Models[key]=item
   end
   nextFrames[key]={Data=frame,ReceivedAt=now}
  end
 end
 self.Frames=nextFrames

 for key,item in pairs(self.Models) do
  if not nextFrames[key] then
   destroyItem(item)
   self.Models[key]=nil
  end
 end
end

function S:Step(dt)
 local now=os.clock()
 local alpha=1-math.exp(-TURN_RESPONSE*math.max(0,dt))
 for key,packet in pairs(self.Frames) do
  local item=self.Models[key]
  local frame=packet and packet.Data
  if item and frame and item.Part and item.Part.Parent then
   local phase=estimatedPhase(frame,packet.ReceivedAt,now)
   local position,direction=routePose(frame,frame.Index,item.Seed,phase,now,item.LastDirection)
   item.LastDirection=direction

   local bank=math.sin(now*4.2+item.Seed)*math.rad(4)
   local pitch=math.sin(now*2.6+item.Seed*.7)*math.rad(2)
   local target=CFrame.lookAt(position,position+direction,Vector3.yAxis)
    *BEE_FORWARD_FIX
    *CFrame.Angles(pitch,0,bank)

   if not item.Initialized then
    item.Part.CFrame=target
    item.Initialized=true
   else
    item.Part.CFrame=item.Part.CFrame:Lerp(target,alpha)
   end
   animateWings(item,now)
  end
 end
end

function S:Target(ownerOnly)
 for _,item in pairs(self.Models) do
  if item.Part and item.Part.Parent and (not ownerOnly or item.Owner==self.UI.Player.UserId) then
   return item.Part
  end
 end
end

return S
