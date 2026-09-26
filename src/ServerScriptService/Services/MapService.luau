local RS=game:GetService("ReplicatedStorage")
local L=require(RS.Config.LocationsConfig)
local C=require(RS.Config.BloomConfig)

local S={Landmarks={},Gates={}}

local function asVerticalCylinder(part,material)
 part.Shape=Enum.PartType.Cylinder
 part.CFrame=CFrame.new(part.Position)*CFrame.Angles(0,0,math.rad(90))
 part.Material=material or Enum.Material.SmoothPlastic
end

function S:Init(x)
 self.X=x
end

function S:Sector(player)
 local char=player.Character
 local root=char and char:FindFirstChild("HumanoidRootPart")
 if not root then return "Center" end
 for id,s in pairs(L.Sectors) do
  if (root.Position-(self.X.Origin+s.Center)).Magnitude<55 then return id end
 end
 return "Center"
end

function S:Unlock(player,id)
 local p=self.X:Profile(player)
 local s=L.Sectors[id]
 local gate=s and self.Gates[id]
 if not p or not s or not gate then return false end
 if not self.X.U.Near(player,gate.Position,C.InteractionDistance) then return false end
 if s.Requires and not p.World.UnlockedSectors[s.Requires] then
  local required=L.Sectors[s.Requires]
  self.X:Send(player,"Message","Unlock "..(required and required.Name or s.Requires).." first")
  return false
 end
 if p.Hive.Level<s.Hive then
  self.X:Send(player,"Message","Reach Hive "..s.Hive.." to unlock "..s.Name)
  return false
 end
 if not p.World.UnlockedSectors[id] then
  p.World.UnlockedSectors[id]=true
  self.X:Send(player,"Ceremony",{Kind="Sector",Text=s.Name.." unlocked"})
 end
 return true
end

function S:Build()
 local centerFlower=self.X.FlowerService.Build(
  1,
  require(RS.Config.FlowersConfig).Species.StarBloom,
  self.X.Origin+Vector3.new(0,1,0)
 )
 centerFlower.Name="ServerBloom"
 centerFlower:ScaleTo(3)
 centerFlower.Parent=self.X.World

 for id,s in pairs(L.Sectors) do
  local center=self.X.Origin+s.Center
  local dir=s.Center.Unit

  local gatePos=center-dir*47
  local gate=self.X:Part(
   self.X.World,
   id.."Gate",
   gatePos+Vector3.new(0,1.5,0),
   Vector3.new(3,5,5),
   s.Color,
   false
  )
  asVerticalCylinder(gate,Enum.Material.SmoothPlastic)
  gate.CanQuery=true
  self.Gates[id]=gate
  self.X:Prompt(gate,s.Name.." • Hive "..s.Hive,function(player)
   return self:Unlock(player,id)
  end)

  for j=1,3 do
   local pos=center+Vector3.new((j-2)*22,1,(j%2)*15)
   local key=id.."_"..j
   local landmark=self.X:Part(
    self.X.World,
    key,
    pos+Vector3.new(0,.25,0),
    Vector3.new(2.5,3,3),
    s.Color:Lerp(Color3.new(1,1,1),.25),
    true
   )
   asVerticalCylinder(landmark,Enum.Material.SmoothPlastic)
   self.Landmarks[key]=pos
   self.X:Prompt(landmark,"Discover location / activity",function(player)
    local p=self.X:Profile(player)
    if not p or not p.World.UnlockedSectors[id] then return false end
    if not p.World.LandmarkDiscoveries[key] then
     p.World.LandmarkDiscoveries[key]=true
     p.Currencies.PetalDust=p.Currencies.PetalDust+3
     self.X.RollService:Charge(player,10)
     self.X:Emit(player,"Landmark",1)
     if Random.new():NextNumber()<.02 then
      p.Cosmetics=p.Cosmetics or {}
      p.Cosmetics.WildBloomExplorer=true
      self.X:Send(player,"Message","Wild Bloom Explorer title unlocked")
     end
    end
    self.X.GardenActivityService:Offer(player,s.Activity,pos,id)
    return true
   end)
  end

  local launch=self.X:Part(
   self.X.World,
   id.."Launch",
   center-dir*35+Vector3.new(0,.08,0),
   Vector3.new(.16,4.5,4.5),
   Color3.fromRGB(218,184,84),
   false
  )
  asVerticalCylinder(launch,Enum.Material.SmoothPlastic)
  self.X:Prompt(launch,"Launch to center",function(player)
   local p=self.X:Profile(player)
   if p and p.World.UnlockedSectors[id] and p.World.LandmarkDiscoveries[id.."_1"] and p.WorkshopV5.Nodes.EXPLORATION_6 then
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root then root.AssemblyLinearVelocity=-dir*75+Vector3.new(0,65,0) end
   end
  end)

  local shrine=self.X:Part(
   self.X.World,
   id.."Shrine",
   center+Vector3.new(0,1.25,30),
   Vector3.new(2.5,5,5),
   Color3.fromRGB(196,183,143),
   true
  )
  asVerticalCylinder(shrine,Enum.Material.SmoothPlastic)
  self.X:Prompt(shrine,"Garden Trials",function(player)
   local p=self.X:Profile(player)
   if p and p.World.UnlockedSectors[id] then self.X:Send(player,"Trials",id) end
  end)
 end

 local workshop=self.X:Part(
  self.X.World,
  "Workshop",
  self.X.Origin+Vector3.new(12,1.5,0),
  Vector3.new(3,6,6),
  Color3.fromRGB(84,151,193),
  true
 )
 asVerticalCylinder(workshop,Enum.Material.SmoothPlastic)
 self.X:Prompt(workshop,"Open Workshop",function(player)
  self.X:Emit(player,"WorkshopVisit",1)
  self.X:Send(player,"Open","Workshop")
 end)

 local tree=self.X:Part(
  self.X.World,
  "AncientTree",
  self.X.Origin+Vector3.new(-12,3,0),
  Vector3.new(6,3,3),
  Color3.fromRGB(110,82,60),
  true
 )
 asVerticalCylinder(tree,Enum.Material.Wood)
 self.X:Prompt(tree,"Season Turn",function(player)
  self.X.SeasonService:Preview(player)
 end)
end

function S:Tick(player)
 local p=self.X:Profile(player)
 local sector=self:Sector(player)
 if sector~="Center" and not p.World.UnlockedSectors[sector] then
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  if root then
   local s=L.Sectors[sector]
   root.CFrame=CFrame.new(self.X.Origin+s.Center-s.Center.Unit*62+Vector3.new(0,4,0))
  end
  return true
 end
 local pulse=self.X.SocialService.Pulse
 local temp=self.X.Temp[player]
 if p.Season.ActiveCard=="TwilightSeason" and sector=="TwilightGrove" and os.clock()>(temp.NextPersonalEclipse or 0) then
  temp.NextPersonalEclipse=os.clock()+90
  temp.PersonalEclipseUntil=os.clock()+45
  self.X.GardenActivityService:Offer(player,"FireflyRoute",self.X.Origin+L.Sectors[sector].Center,sector)
 end
 if pulse and pulse.Sector==sector and os.clock()>(temp.NextWild or 0) then
  temp.NextWild=os.clock()+25
  self.X.GardenActivityService:Offer(player,sector=="TwilightGrove" and "ShadowBloom" or L.Sectors[sector].Activity,self.X.Origin+L.Sectors[sector].Center,sector)
 end
 if sector=="SunnyOrchard" then self.X:EmitOnce(player,"SunnyVisit") end
 local changed=temp.Sector~=sector
 if changed then
  temp.Sector=sector
  self.X.GardenSynergyService:Recalculate(player)
 end
 return changed
end

return S
