local S={}
local goals={"StarterBee","PollenSpark","Delivery","Roll","Plant","Charge","BloomRoll","Hive2","WorkshopVisit","WorkshopPurchase","Synergy","BeeSlots","Trait","SunnyVisit","SolarBloom","Discover6","CrystalGate","Trial","CrystalVisit","SeasonReady"}
function S:Init(x) self.X=x end
function S:Tick(player)
 local p=self.X:Profile(player) local q=p.Quests local key=goals[q.JourneyStep] if not key then return end local events=p.Tutorial.Events local yes=(events[key] or 0)>0
 if key=="Charge" then yes=p.RollState.SpecialRollReady or (events.BloomRoll or 0)>0 elseif key=="Hive2" then yes=p.Hive.Level>=2 elseif key=="BeeSlots" then yes=self.X.StatsService:BeeCapacity(p)>=2 elseif key=="Discover6" then yes=self.X.U.Count(p.FlowerCollection.DiscoveredFlowers)>=6 elseif key=="CrystalGate" then yes=p.World.UnlockedSectors.CrystalGreenhouse elseif key=="CrystalVisit" then yes=self.X.MapService:Sector(player)=="CrystalGreenhouse" elseif key=="SeasonReady" then yes=self.X.SeasonService:Eligible(p) end
 if yes then local id="Journey_"..q.JourneyStep if not q.Claimed[id] then q.Claimed[id]=true p.Currencies.Coins=p.Currencies.Coins+10 end q.JourneyStep=q.JourneyStep+1 end
 local discovered=self.X.U.Count(p.FlowerCollection.DiscoveredFlowers)+self.X.U.Count(p.Pollinators.DiscoveredBees)
 for _,threshold in ipairs({4,8,12,18,24}) do if discovered>=threshold then self.X.WorkshopService:Point(player,"Collection_"..threshold,2) end end
end
S.Goals=goals return S
