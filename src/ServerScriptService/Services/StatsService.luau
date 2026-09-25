local RS=game:GetService("ReplicatedStorage") local B=require(RS.Config.BeesConfig) local C=require(RS.Config.BloomConfig) local S={}
function S:Init(x) self.X=x end
local GardenRules=require(RS.Shared.GardenRules)
function S:BeeCapacity(p) return GardenRules.BeeCapacity(p) end
function S:FlowerCapacity(p) return GardenRules.FlowerCapacity(p) end
function S:Get(p) local traits=B.GetTraitBonuses(p.Pollinators.EquippedBeeSlots) local passive=B.GetPassiveBonuses(p.Pollinators.EquippedBeeSlots) return {Luck=(traits.LuckMultiplier or 1)*(passive.LuckMultiplier or 1),Yield=(traits.PollinatorYieldMultiplier or 1)*(passive.PollinatorYieldMultiplier or 1),Speed=(traits.PollinatorTravelSpeedMultiplier or 1)*(passive.PollinatorTravelSpeedMultiplier or 1),AbilityCooldown=traits.AbilityCooldownMultiplier or 1,BeeMasteryXP=(traits.BeeMasteryXPMultiplier or 1)*(passive.BeeMasteryXPMultiplier or 1)} end
return S

