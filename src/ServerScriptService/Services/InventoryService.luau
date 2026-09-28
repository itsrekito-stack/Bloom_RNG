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
  local new=not (pollinators.DiscoveredBees[id]==true)
  local owned=(tonumber(pollinators.BeeInventory[id]) or 0)>0
  pollinators.DiscoveredBees[id]=true
  pollinators.BeeObtained[id]=(pollinators.BeeObtained[id] or 0)+1
  pollinators.BeeInventory[id]=1
  pollinators.BeeMastery[id]=pollinators.BeeMastery[id] or 0
  if owned then
   self.X.PollinatorService:AddMastery(player,id,C.BeeDuplicateXP)
  end
  self.X:MarkStateDirty(player)
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

local function beeRank(id)
 local bee=type(id)=="string" and B.Get(id) or nil
 return bee and (B.RarityRank[bee.Rarity] or 0) or 0
end

local function chooseEquipSlot(p,id,capacity)
 local slots=p.Pollinators.EquippedBeeSlots
 for i=1,capacity do
  local equipped=slots[i]
  if equipped==nil or equipped=="" then return i end
 end
 local newRank=beeRank(id)
 local bestSlot=nil
 local bestRank=math.huge
 for i=1,capacity do
  local equipped=slots[i]
  local rank=beeRank(equipped)
  if rank<newRank and (rank<bestRank or (rank==bestRank and (bestSlot==nil or i<bestSlot))) then
   bestSlot=i
   bestRank=rank
  end
 end
 return bestSlot
end

function S:EquipBee(player,id,slot)
 local p=self.X:Profile(player)
 if not p then return false,"PROFILE_LOADING" end
 local capacity=self.X.StatsService:BeeCapacity(p)

 if id=="" or id==nil then
  if not self.X.U.Integer(slot,capacity) then return false,"INVALID_SLOT" end
  p.Pollinators.EquippedBeeSlots[slot]=nil
  self.X.GardenSynergyService:Recalculate(player)
  return true
 end

 if type(id)~="string" or not B.Exists(id) then return false,"INVALID_ITEM" end
 if (p.Pollinators.BeeInventory[id] or 0)<1 then return false,"NOT_OWNED" end
 for _,v in pairs(p.Pollinators.EquippedBeeSlots) do
  if v==id then return false,"ALREADY_EQUIPPED" end
 end

 local chosenSlot=slot
 if chosenSlot~=nil and not self.X.U.Integer(chosenSlot,capacity) then return false,"INVALID_SLOT" end
 if chosenSlot==nil then chosenSlot=chooseEquipSlot(p,id,capacity) end
 if not chosenSlot then return false,"NO_LOWER_RARITY_BEE" end

 local previousId=p.Pollinators.EquippedBeeSlots[chosenSlot]
 if previousId and previousId~="" and beeRank(previousId)>=beeRank(id) then
  return false,"NO_LOWER_RARITY_BEE"
 end

 p.Pollinators.EquippedBeeSlots[chosenSlot]=id
 self.X.GardenSynergyService:Recalculate(player)
 self.X:Emit(player,"EquipBee",1)
 local _,traits=B.GetTraitBonuses(p.Pollinators.EquippedBeeSlots)
 if #traits>0 then self.X:Emit(player,"Trait",1) end
 if previousId and previousId~="" then
  local newBee=B.Get(id)
  local oldBee=B.Get(previousId)
  self.X:Send(player,"Message",(newBee and newBee.DisplayName or id).." replaced "..(oldBee and oldBee.DisplayName or previousId))
 end
 return true
end

return S
