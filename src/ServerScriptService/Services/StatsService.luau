local RS=game:GetService("ReplicatedStorage") local B=require(RS.Config.BeesConfig) local C=require(RS.Config.BloomConfig) local S={}
function S:Init(x) self.X=x end
function S:BeeCapacity(p) return math.min(C.MaxBeeSlots,1+(p.Hive.Level>=2 and 1 or 0)+(p.WorkshopV5.Nodes.BEES_1 and 1 or 0)+(p.WorkshopV5.Nodes.BEES_5 and 2 or 0)) end
function S:FlowerCapacity(p) return math.min(C.MaxFlowerSlots,3+math.max(0,p.Hive.Level-1)+(p.WorkshopV5.Nodes.GARDEN_1 and 1 or 0)+(p.WorkshopV5.Nodes.GARDEN_4 and 3 or 0)) end
function S:Get(p) local traits=B.GetTraitBonuses(p.Pollinators.EquippedBeeSlots) local passive=B.GetPassiveBonuses(p.Pollinators.EquippedBeeSlots) return {Luck=(traits.LuckMultiplier or 1)*(passive.LuckMultiplier or 1),Yield=(traits.PollinatorYieldMultiplier or 1)*(passive.PollinatorYieldMultiplier or 1),Speed=(traits.PollinatorTravelSpeedMultiplier or 1)*(passive.PollinatorTravelSpeedMultiplier or 1),AbilityCooldown=traits.AbilityCooldownMultiplier or 1} end
return S
