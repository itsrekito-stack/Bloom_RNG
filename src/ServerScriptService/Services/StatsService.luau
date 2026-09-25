local RS=game:GetService("ReplicatedStorage")
local B=require(RS.Config.BeesConfig)
local GardenRules=require(RS.Shared.GardenRules)

local S={}

function S:Init(x)
 self.X=x
end

function S:BeeCapacity(p)
 return GardenRules.BeeCapacity(p)
end

function S:FlowerCapacity(p)
 return GardenRules.FlowerCapacity(p)
end

function S:Get(p)
 local traits=B.GetTraitBonuses(p.Pollinators.EquippedBeeSlots)
 local passive=B.GetPassiveBonuses(p.Pollinators.EquippedBeeSlots)
 return {
  Luck=(traits.LuckMultiplier or 1)*(passive.LuckMultiplier or 1),
  Yield=(traits.PollinatorYieldMultiplier or 1)*(passive.PollinatorYieldMultiplier or 1),
  Speed=(traits.PollinatorTravelSpeedMultiplier or 1)*(passive.PollinatorTravelSpeedMultiplier or 1),
  Power=(traits.PollinatorPowerMultiplier or 1)*(passive.PollinatorPowerMultiplier or 1),
  FlowerGrowth=(traits.FlowerGrowthMultiplier or 1)*(passive.FlowerGrowthMultiplier or 1),
  Coin=(traits.CoinMultiplier or 1)*(passive.CoinMultiplier or 1),
  HiveHoney=(traits.HiveHoneyMultiplier or 1)*(passive.HiveHoneyMultiplier or 1),
  ClonePower=(traits.ClonePowerMultiplier or 1)*(passive.ClonePowerMultiplier or 1),
  AbilityCooldown=(traits.AbilityCooldownMultiplier or 1)*(passive.AbilityCooldownMultiplier or 1),
  AbilityDuration=(traits.AbilityDurationMultiplier or 1)*(passive.AbilityDurationMultiplier or 1),
  BeeMasteryXP=(traits.BeeMasteryXPMultiplier or 1)*(passive.BeeMasteryXPMultiplier or 1),
  CriticalChance=traits.CriticalChance or 0,
  CriticalMultiplier=(traits.CriticalMultiplier or 1)*(passive.CriticalMultiplier or 1),
  SplashChance=traits.SplashChance or 0,
  SplashPercent=traits.SplashPercent or 0,
  DualPollinationChance=traits.DualPollinationChance or 0,
  DualPollinationPercent=traits.DualPollinationPercent or 0,
 }
end

return S
