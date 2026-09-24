local RS=game:GetService("ReplicatedStorage") local F=require(RS.Config.FlowersConfig) local B=require(RS.Config.BeesConfig) local C=require(RS.Config.BloomConfig)
local S={}
function S:Init(x) self.X=x end
function S:Available(p,id) local n=p.FlowerCollection.OwnedSeedCopies[id] or 0 for _,s in ipairs(p.Garden.Slots) do if s.SpeciesId==id then n=n-1 end end return math.max(0,n) end
function S:Grant(player,kind,id)
 local p=self.X:Profile(player) if not p then return end
 if kind=="FlowerSeed" and F.Exists(id) then local f=p.FlowerCollection local new=not f.DiscoveredFlowers[id] f.DiscoveredFlowers[id]=true f.OwnedSeedCopies[id]=(f.OwnedSeedCopies[id] or 0)+1
  if not new and p.Settings.AutoDissolve and p.WorkshopV5.Nodes.ECONOMY_1 and p.Settings.DissolveRarities[F.Species[id].Rarity] and not f.LockedFlowers[id] and not f.FavoriteFlowers[id] then self:Dissolve(player,id,1) end
  self.X:Emit(player,"SeedReward",1) return new
 elseif kind=="Bee" and B.Exists(id) then local b=p.Pollinators local new=not b.DiscoveredBees[id] b.DiscoveredBees[id]=true b.BeeInventory[id]=(b.BeeInventory[id] or 0)+1 return new end
end
function S:Dissolve(player,id,n)
 local p=self.X:Profile(player) if not p or not F.Exists(id) or type(n)~="number" or n%1~=0 or n<1 or n>10000 then return false end
 local f=p.FlowerCollection if f.LockedFlowers[id] or f.FavoriteFlowers[id] or self:Available(p,id)<n or (f.OwnedSeedCopies[id] or 0)-n<1 then return false end
 f.OwnedSeedCopies[id]=f.OwnedSeedCopies[id]-n p.Currencies.PetalDust=p.Currencies.PetalDust+n*C.DustPerCopy*(p.Season.ActiveCard=="AutumnFortune" and 1.5 or 1)*(p.WorkshopV5.Nodes.ECONOMY_3 and 1.2 or 1)
 self.X.FlowerProgressionService:Add(player,id,n) return true
end
function S:EquipBee(player,id,slot)
 local p=self.X:Profile(player) if not p or not B.Exists(id) or not self.X.U.Integer(slot,self.X.StatsService:BeeCapacity(p)) then return false end
 local count=0 for i,v in pairs(p.Pollinators.EquippedBeeSlots) do if i~=slot and v==id then count=count+1 end end
 if count>=(p.Pollinators.BeeInventory[id] or 0) then return false end p.Pollinators.EquippedBeeSlots[slot]=id
 self.X.GardenSynergyService:Recalculate(player) local _,traits=B.GetTraitBonuses(p.Pollinators.EquippedBeeSlots) if #traits>0 then self.X:Emit(player,"Trait",1) end return true
end
return S
