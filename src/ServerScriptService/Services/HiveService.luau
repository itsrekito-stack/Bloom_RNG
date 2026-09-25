local RS=game:GetService("ReplicatedStorage")
local C=require(RS.Config.BloomConfig)
local Locations=require(RS.Config.LocationsConfig)
local Bees=require(RS.Config.BeesConfig)

local S={}

local function nextReadyLocation(profile)
 for _,id in ipairs(Locations.Order) do
  local cfg=Locations.Sectors[id]
  if not profile.World.UnlockedSectors[id]
   and profile.Hive.Level>=cfg.Hive
   and (not cfg.Requires or profile.World.UnlockedSectors[cfg.Requires])
  then
   return id,cfg
  end
 end
 return nil,nil
end

function S:Init(x)
 self.X=x
end

function S:Interact(player)
 local p=self.X:Profile(player)
 if not p then return false end

 if not p.StarterBeeGranted then
  p.StarterBeeGranted=true
  local isNew=self.X.InventoryService:Grant(player,"Bee","WorkerBee")
  p.Pollinators.EquippedBeeSlots[1]="WorkerBee"
  self.X.GardenSynergyService:Recalculate(player)
  self.X.GardenPlotService:RefreshHivePrompt(player)
  self.X:Emit(player,"StarterBee",1)
  local starter=Bees.Get("WorkerBee")
  self.X:Send(player,"Ceremony",{
   Kind="StarterBee",
   RewardKind="Bee",
   RewardId="WorkerBee",
   Text=(starter and starter.DisplayName or "Worker Bee").." joined your hive",
   Rarity=starter and starter.Rarity or "Common",
   IsNew=isNew==true,
  })
  return true
 end

 local nextLevel=p.Hive.Level+1
 local cost=C.HiveCosts[nextLevel]
 if not cost then
  self.X:Send(player,"Message","Hive is at max level")
  return false
 end
 if p.Hive.Honey<cost then
  self.X:Send(player,"Message",string.format("Hive %d needs %d Honey • %d / %d",nextLevel,cost,math.floor(p.Hive.Honey),cost))
  return false
 end

 p.Hive.Honey-=cost
 p.Hive.Level=nextLevel
 self.X.WorkshopService:Point(player,"Hive_"..p.Season.Count.."_"..p.Hive.Level,2)
 self.X.GardenPlotService:RefreshCapacity(player)
 self.X:Emit(player,"HiveUpgrade",1)
 self.X:Send(player,"Ceremony",{Kind="Hive",Text="Hive level "..p.Hive.Level})

 local _,location=nextReadyLocation(p)
 if location then
  self.X:Send(player,"Message",location.Name.." gate is ready to unlock")
 end
 return true
end

return S
