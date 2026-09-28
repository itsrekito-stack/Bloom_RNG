local RS=game:GetService("ReplicatedStorage")
local F=require(RS.Config.FlowersConfig)
local B=require(RS.Config.BeesConfig)
local C=require(RS.Config.BloomConfig)
local E=require(RS.Shared.WorkshopEffects)

local S={}

function S:Init(x)
 self.X=x
end

function S:Available(p,id)
 local n=p.FlowerCollection.OwnedSeedCopies[id] or 0
 for _,slot in ipairs(p.Garden.Slots) do
  if slot.SpeciesId==id then n-=1 end
 end
 return math.max(0,n)
end

function S:AvailableBee(p,id)
 local n=p.Pollinators.BeeInventory[id] or 0
 for _,beeId in pairs(p.Pollinators.EquippedBeeSlots) do
  if beeId==id then n-=1 end
 end
 return math.max(0,n)
end

function S:Grant(player,kind,id)
 local p=self.X:Profile(player)
 if not p then return nil end

 if kind=="FlowerSeed" and F.Exists(id) then
  local f=p.FlowerCollection
  local new=not f.DiscoveredFlowers[id]
  f.DiscoveredFlowers[id]=true
  f.ObtainedFlowers[id]=(f.ObtainedFlowers[id] or 0)+1
  if new then
   f.OwnedSeedCopies[id]=1
   f.FlowerMastery[id]=f.FlowerMastery[id] or {Level=1,XP=0}
  else
   self.X.FlowerProgressionService:AddDuplicate(player,id,1)
  end
  self.X:Emit(player,"SeedReward",1)
  return new
 end

 if kind=="Bee" and B.Exists(id) then
  local pollinators=p.Pollinators
  local new=not pollinators.DiscoveredBees[id]
  pollinators.DiscoveredBees[id]=true
  pollinators.BeeObtained[id]=(pollinators.BeeObtained[id] or 0)+1
  if new then
   pollinators.BeeInventory[id]=1
   pollinators.BeeMastery[id]=pollinators.BeeMastery[id] or 0
  else
   self.X.PollinatorService:AddMastery(player,id,C.BeeDuplicateXP)
  end
  return new
 end

 return nil
end

function S:Dissolve()
 return false,"ACTION_UNAVAILABLE"
end

function S:DissolveBee()
 return false,"ACTION_UNAVAILABLE"
end

function S:EquipBee(player,id,slot)
 local p=self.X:Profile(player)
 if not p then return false,"PROFILE_LOADING" end
 local capacity=self.X.StatsService:BeeCapacity(p)
 if not self.X.U.Integer(slot,capacity) then return false,"INVALID_SLOT" end

 if id=="" or id==nil then
  p.Pollinators.EquippedBeeSlots[slot]=nil
  self.X.GardenSynergyService:Recalculate(player)
  return true
 end

 if type(id)~="string" or not B.Exists(id) then return false,"INVALID_ITEM" end
 if (p.Pollinators.BeeInventory[id] or 0)<1 then return false,"NOT_OWNED" end

 for i,v in pairs(p.Pollinators.EquippedBeeSlots) do
  if i~=slot and v==id then return false,"ALREADY_EQUIPPED" end
 end

 p.Pollinators.EquippedBeeSlots[slot]=id
 self.X.GardenSynergyService:Recalculate(player)
 self.X:Emit(player,"EquipBee",1)
 local _,traits=B.GetTraitBonuses(p.Pollinators.EquippedBeeSlots)
 if #traits>0 then self.X:Emit(player,"Trait",1) end
 return true
end

return S
