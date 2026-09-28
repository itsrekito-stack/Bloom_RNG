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
  f.OwnedSeedCopies[id]=(f.OwnedSeedCopies[id] or 0)+1
  if not new
   and p.Settings.AutoDissolve
   and p.WorkshopV5.Nodes.ECONOMY_1
   and p.Settings.DissolveRarities[F.Species[id].Rarity]
   and not f.LockedFlowers[id]
   and not f.FavoriteFlowers[id]
  then
   self:Dissolve(player,id,1)
  end
  self.X:Emit(player,"SeedReward",1)
  return new
 end

 if kind=="Bee" and B.Exists(id) then
  local inv=p.Pollinators
  local new=not inv.DiscoveredBees[id]
  inv.DiscoveredBees[id]=true
  inv.BeeInventory[id]=(inv.BeeInventory[id] or 0)+1
  return new
 end

 return nil
end

function S:Dissolve(player,id,n)
 local p=self.X:Profile(player)
 if not p then return false,"PROFILE_LOADING" end
 if type(id)~="string" or not F.Exists(id) then return false,"INVALID_ITEM" end
 if type(n)~="number" or n%1~=0 or n<1 or n>10000 then return false,"INVALID_VALUE" end

 local f=p.FlowerCollection
 if f.LockedFlowers[id] then return false,"PROTECTED" end
 if f.FavoriteFlowers[id] then return false,"FAVORITE" end
 if self:Available(p,id)<n then return false,"NO_FREE_COPY" end
 if (f.OwnedSeedCopies[id] or 0)-n<1 then return false,"LAST_COPY" end

 f.OwnedSeedCopies[id]-=n
 p.Currencies.PetalDust+=n*C.DustPerCopy
  *(p.Season.ActiveCard=="AutumnFortune" and 1.5 or 1)
  *E.Value(p,"ECONOMY_3","DustYield",1)
 self.X.FlowerProgressionService:Add(player,id,n)
 return true
end

function S:DissolveBee(player,id,n)
 local p=self.X:Profile(player)
 if not p then return false,"PROFILE_LOADING" end
 if type(id)~="string" or not B.Exists(id) then return false,"INVALID_ITEM" end
 if type(n)~="number" or n%1~=0 or n<1 or n>10000 then return false,"INVALID_VALUE" end

 local inv=p.Pollinators
 if self:AvailableBee(p,id)<n then return false,"NO_FREE_COPY" end
 if (inv.BeeInventory[id] or 0)-n<1 then return false,"LAST_COPY" end

 inv.BeeInventory[id]-=n
 p.Currencies.PetalDust+=n*C.BeeDustPerCopy
  *(p.Season.ActiveCard=="AutumnFortune" and 1.5 or 1)
  *E.Value(p,"ECONOMY_3","DustYield",1)
 return true
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
 local _,traits=B.GetTraitBonuses(p.Pollinators.EquippedBeeSlots)
 if #traits>0 then self.X:Emit(player,"Trait",1) end
 return true
end

return S
