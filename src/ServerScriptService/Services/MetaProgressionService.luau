local S={}
local goals={"TutorialBeeRoll","PollenSpark","Delivery","Roll","Plant","Charge","BloomRoll","Hive2","WorkshopVisit","WorkshopPurchase","Synergy","BeeSlots","Trait","SunnyVisit","SolarBloom","Discover6","CrystalGate","Trial","CrystalVisit","SeasonReady"}
local POINT_MILESTONES={WorkshopVisit=1,Synergy=1,Trait=1,Trial=2,SeasonReady=2}
function S:Init(x) self.X=x end
function S:Tick(player)
 local p=self.X:Profile(player) if not p then return false end
 local q=p.Quests local beforeStep=q.JourneyStep local beforeCoins=p.Currencies.Coins local beforePoints=p.WorkshopV5.Points
 local key=goals[q.JourneyStep] if not key then return false end local events=p.Tutorial.Events local yes=(events[key] or 0)>0
 if key=="Charge" then yes=p.RollState.SpecialRollReady or (events.BloomRoll or 0)>0 elseif key=="Hive2" then yes=p.Hive.Level>=2 elseif key=="BeeSlots" then yes=self.X.StatsService:BeeCapacity(p)>=2 elseif key=="Discover6" then yes=self.X.U.Count(p.FlowerCollection.DiscoveredFlowers)>=6 elseif key=="CrystalGate" then yes=p.World.UnlockedSectors.CrystalGreenhouse elseif key=="CrystalVisit" then yes=self.X.MapService:Sector(player)=="CrystalGreenhouse" elseif key=="SeasonReady" then yes=self.X.SeasonService:Eligible(p) end
 if yes then
  local id="Journey_"..q.JourneyStep
  if not q.Claimed[id] then
   q.Claimed[id]=true
   p.Currencies.Coins=p.Currencies.Coins+10
   local points=POINT_MILESTONES[key] or 0
   if points>0 then self.X.WorkshopService:Point(player,"JourneyMilestone_"..key,points) end
  end
  q.JourneyStep=q.JourneyStep+1
 end
 return q.JourneyStep~=beforeStep or p.Currencies.Coins~=beforeCoins or p.WorkshopV5.Points~=beforePoints
end
S.Goals=goals return S
