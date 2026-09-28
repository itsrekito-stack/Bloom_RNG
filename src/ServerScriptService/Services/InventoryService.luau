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

function S:UnequipAllBees(player)
 local p=self.X:Profile(player)
 if not p then return false,"PROFILE_LOADING" end
 local changed=false
 for slot in pairs(p.Pollinators.EquippedBeeSlots) do
  if type(slot)=="number" then
   p.Pollinators.EquippedBeeSlots[slot]=nil
   changed=true
  end
 end
 if changed then
  self.X.GardenSynergyService:Recalculate(player)
  self.X.PollinatorService:Remove(player)
 end
 return true
end

function S:EquipTraitSynergy(player,traitId)
 local p=self.X:Profile(player)
 if not p then return false,"PROFILE_LOADING" end
 local trait=B.GetTrait(traitId)
 if not trait then return false,"INVALID_ITEM" end
 local capacity=self.X.StatsService:BeeCapacity(p)
 if capacity<1 then return false,"SYNERGY_UNAVAILABLE" end

 local candidates={}
 for _,beeId in ipairs(B.GetTraitBees(traitId)) do
  if (tonumber(p.Pollinators.BeeInventory[beeId]) or 0)>0 then candidates[#candidates+1]=beeId end
 end
 table.sort(candidates,function(a,b)
  local ra,rb=beeRank(a),beeRank(b)
  if ra==rb then return (B.Get(a).SortOrder or 999)>(B.Get(b).SortOrder or 999) end
  return ra>rb
 end)

 local target=0
 for _,bp in ipairs(trait.Breakpoints or {}) do
  local need=math.floor(tonumber(bp.Count) or 0)
  if need<=#candidates and need<=capacity then target=math.max(target,need) end
 end
 if target<1 then return false,"SYNERGY_UNAVAILABLE" end

 local slots,chosen={},{}
 for i=1,target do slots[#slots+1]=candidates[i] chosen[candidates[i]]=true end
 local fillers={}
 for beeId,count in pairs(p.Pollinators.BeeInventory or {}) do
  if (tonumber(count) or 0)>0 and not chosen[beeId] and B.Exists(beeId) then fillers[#fillers+1]=beeId end
 end
 table.sort(fillers,function(a,b)
  local ra,rb=beeRank(a),beeRank(b)
  if ra==rb then return (B.Get(a).SortOrder or 999)>(B.Get(b).SortOrder or 999) end
  return ra>rb
 end)
 for _,beeId in ipairs(fillers) do if #slots>=capacity then break end slots[#slots+1]=beeId end

 table.clear(p.Pollinators.EquippedBeeSlots)
 for i,beeId in ipairs(slots) do p.Pollinators.EquippedBeeSlots[i]=beeId end
 self.X.PollinatorService:Remove(player)
 self.X.GardenSynergyService:Recalculate(player)
 self.X:Emit(player,"EquipBee",1)
 self.X:Emit(player,"Trait",1)
 local state
 for _,entry in ipairs(B.GetTraitState(p.Pollinators.EquippedBeeSlots)) do if entry.Id==traitId then state=entry break end end
 if not state or state.Tier<1 then return false,"SYNERGY_UNAVAILABLE" end
 self.X:Send(player,"Message",tostring(trait.Name).." synergy equipped • Tier "..tostring(state.Tier))
 return true
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
