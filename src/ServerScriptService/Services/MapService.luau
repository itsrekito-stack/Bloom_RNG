local RS=game:GetService("ReplicatedStorage") local L=require(RS.Config.LocationsConfig) local C=require(RS.Config.BloomConfig) local S={Landmarks={},Gates={}}
function S:Init(x) self.X=x end
function S:Sector(player) local char=player.Character local root=char and char:FindFirstChild("HumanoidRootPart") if not root then return "Center" end for id,s in pairs(L.Sectors) do if (root.Position-(self.X.Origin+s.Center)).Magnitude<55 then return id end end return "Center" end
function S:Unlock(player,id)
 local p=self.X:Profile(player) local s=L.Sectors[id] if not p or not s or not self.X.U.Near(player,self.Gates[id].Position,C.InteractionDistance) or p.Hive.Level<s.Hive then return false end
 if not p.World.UnlockedSectors[id] then p.World.UnlockedSectors[id]=true self.X:Send(player,"Ceremony",{Kind="Sector",Text=s.Name.." unlocked"}) end return true
end
function S:Build()
 local centerFlower=self.X.FlowerService.Build(1,require(RS.Config.FlowersConfig).Species.StarBloom,self.X.Origin+Vector3.new(0,1,0)) centerFlower.Name="ServerBloom" centerFlower:ScaleTo(3) centerFlower.Parent=self.X.World
 for id,s in pairs(L.Sectors) do local center=self.X.Origin+s.Center
  self.X:Part(self.X.World,id,center-Vector3.new(0,1,0),Vector3.new(95,2,95),s.Color,true)
  local dir=s.Center.Unit local gatePos=center-dir*47 local gate=self.X:Part(self.X.World,id.."Gate",gatePos+Vector3.new(0,3,0),Vector3.new(12,6,2),s.Color,false) self.Gates[id]=gate
  self.X:Prompt(gate,s.Name.." • Hive "..s.Hive,function(player) self:Unlock(player,id) end)
  for j=1,3 do local pos=center+Vector3.new((j-2)*22,1,(j%2)*15) local key=id.."_"..j
   local landmark=self.X:Part(self.X.World,key,pos,Vector3.new(3,7,3),s.Color:Lerp(Color3.new(1,1,1),.3),true) self.Landmarks[key]=pos
   self.X:Prompt(landmark,"Discover location / activity",function(player)
    local p=self.X:Profile(player) if not p or not p.World.UnlockedSectors[id] then return end
    if not p.World.LandmarkDiscoveries[key] then p.World.LandmarkDiscoveries[key]=true p.Currencies.PetalDust=p.Currencies.PetalDust+3 self.X.RollService:Charge(player,10) self.X:Emit(player,"Landmark",1)
     if Random.new():NextNumber()<.02 then p.Cosmetics=p.Cosmetics or {} p.Cosmetics.WildBloomExplorer=true self.X:Send(player,"Message","Wild Bloom Explorer title unlocked") end end
    self.X.GardenActivityService:Offer(player,s.Activity,pos,id)
   end)
  end
  local launch=self.X:Part(self.X.World,id.."Launch",center-dir*35,Vector3.new(5,.5,5),Color3.fromRGB(240,210,100),true)
  self.X:Prompt(launch,"Launch to center",function(player) local p=self.X:Profile(player) if p and p.World.UnlockedSectors[id] and p.World.LandmarkDiscoveries[id.."_1"] and p.WorkshopV5.Nodes.EXPLORATION_6 then local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart") if root then root.AssemblyLinearVelocity=-dir*75+Vector3.new(0,65,0) end end end)
  local shrine=self.X:Part(self.X.World,id.."Shrine",center+Vector3.new(0,2,30),Vector3.new(6,4,6),Color3.fromRGB(230,210,150),true)
  self.X:Prompt(shrine,"Garden Trials",function(player) local p=self.X:Profile(player) if p and p.World.UnlockedSectors[id] then self.X:Send(player,"Trials",id) end end)
 end
 local workshop=self.X:Part(self.X.World,"Workshop",self.X.Origin+Vector3.new(12,2,0),Vector3.new(7,4,7),Color3.fromRGB(90,160,210),true)
 self.X:Prompt(workshop,"Open Workshop",function(player) self.X:Emit(player,"WorkshopVisit",1) self.X:Send(player,"Open","Workshop") end)
 local tree=self.X:Part(self.X.World,"AncientTree",self.X.Origin+Vector3.new(-12,5,0),Vector3.new(6,10,6),Color3.fromRGB(140,100,170),true)
 self.X:Prompt(tree,"Season Turn",function(player) self.X.SeasonService:Preview(player) end)
end
function S:Tick(player)
 local p=self.X:Profile(player) local sector=self:Sector(player) if sector~="Center" and not p.World.UnlockedSectors[sector] then
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart") if root then local s=L.Sectors[sector] root.CFrame=CFrame.new(self.X.Origin+s.Center-s.Center.Unit*62+Vector3.new(0,4,0)) end return
 end
 local pulse=self.X.SocialService.Pulse local temp=self.X.Temp[player]
 if p.Season.ActiveCard=="TwilightSeason" and sector=="TwilightGrove" and os.clock()>(temp.NextPersonalEclipse or 0) then temp.NextPersonalEclipse=os.clock()+90 temp.PersonalEclipseUntil=os.clock()+45 self.X.GardenActivityService:Offer(player,"FireflyRoute",self.X.Origin+L.Sectors[sector].Center,sector) end
 if pulse and pulse.Sector==sector and os.clock()>(temp.NextWild or 0) then temp.NextWild=os.clock()+25 self.X.GardenActivityService:Offer(player,sector=="TwilightGrove" and "ShadowBloom" or L.Sectors[sector].Activity,self.X.Origin+L.Sectors[sector].Center,sector) end
 if sector=="SunnyOrchard" then self.X:EmitOnce(player,"SunnyVisit") end
 local temp=self.X.Temp[player] local changed=temp.Sector~=sector
 if changed then temp.Sector=sector self.X.GardenSynergyService:Recalculate(player) end
 return changed
end
return S
