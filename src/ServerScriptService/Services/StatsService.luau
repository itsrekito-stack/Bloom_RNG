local RS=game:GetService("ReplicatedStorage")
local B=require(RS.Config.BeesConfig)
local F=require(RS.Config.FlowersConfig)
local G=require(RS.Config.GardenSynergyConfig)
local GardenRules=require(RS.Shared.GardenRules)
local E=require(RS.Shared.WorkshopEffects)

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
 local synergy=G.Get(p.Garden and p.Garden.ActiveSynergy or "")
 local effect=synergy and synergy.Effect or {}
 local flower={}
 for _,key in ipairs({"LuckMultiplier","PollinatorYieldMultiplier","PollinatorTravelSpeedMultiplier","PollinatorPowerMultiplier","FlowerGrowthMultiplier","CoinMultiplier","HiveHoneyMultiplier","AbilityCooldownMultiplier"}) do flower[key]=1 end
 for _,slot in ipairs((p.Garden and p.Garden.Slots) or {}) do
  local id=slot.SpeciesId
  if type(id)=="string" then
   local mastery=p.FlowerCollection and p.FlowerCollection.FlowerMastery and p.FlowerCollection.FlowerMastery[id]
   local buff=F.GetLevelBuff and F.GetLevelBuff(id,mastery and mastery.Level or 1) or nil
   if buff and flower[buff.Stat] then flower[buff.Stat]*=buff.Multiplier end
  end
 end
 local masteryLuck=1
 for _,beeId in pairs(p.Pollinators.EquippedBeeSlots or {}) do
  if type(beeId)=="string" then
   local state=B.GetMasteryState and B.GetMasteryState(p.Pollinators.BeeMastery[beeId]) or nil
   local masteryMultiplier=tonumber(state and state.LuckMultiplier) or 1
   masteryLuck=masteryLuck*masteryMultiplier
  end
 end
 return {
  Luck=(traits.LuckMultiplier or 1)*(passive.LuckMultiplier or 1)*(effect.LuckMultiplier or 1)*(flower.LuckMultiplier or 1)*masteryLuck*E.Value(p,"GARDEN_2","LuckMultiplier",1),
  Yield=(traits.PollinatorYieldMultiplier or 1)*(passive.PollinatorYieldMultiplier or 1)*(effect.PollinatorYieldMultiplier or 1)*(flower.PollinatorYieldMultiplier or 1)*E.Value(p,"GARDEN_6","PollinatorYieldMultiplier",1)*E.Value(p,"BEES_5","PollinatorYieldMultiplier",1),
  Speed=(traits.PollinatorTravelSpeedMultiplier or 1)*(passive.PollinatorTravelSpeedMultiplier or 1)*(effect.PollinatorTravelSpeedMultiplier or 1)*(flower.PollinatorTravelSpeedMultiplier or 1),
  Power=(traits.PollinatorPowerMultiplier or 1)*(passive.PollinatorPowerMultiplier or 1)*(effect.PollinatorPowerMultiplier or 1)*(flower.PollinatorPowerMultiplier or 1)*E.Value(p,"BEES_1","PollinatorPowerMultiplier",1),
  FlowerGrowth=(traits.FlowerGrowthMultiplier or 1)*(passive.FlowerGrowthMultiplier or 1)*(effect.FlowerGrowthMultiplier or 1)*(flower.FlowerGrowthMultiplier or 1)*E.Value(p,"GARDEN_1","FlowerGrowthMultiplier",1)*E.Value(p,"GARDEN_4","FlowerGrowthMultiplier",1),
  Coin=(traits.CoinMultiplier or 1)*(passive.CoinMultiplier or 1)*(effect.CoinMultiplier or 1)*(flower.CoinMultiplier or 1)*E.Value(p,"ECONOMY_1","CoinYield",1)*E.Value(p,"ECONOMY_5","CoinYield",1),
  HiveHoney=(traits.HiveHoneyMultiplier or 1)*(passive.HiveHoneyMultiplier or 1)*(effect.HiveHoneyMultiplier or 1)*(flower.HiveHoneyMultiplier or 1)*E.Value(p,"ECONOMY_2","HiveHoneyMultiplier",1),
  ClonePower=(traits.ClonePowerMultiplier or 1)*(passive.ClonePowerMultiplier or 1),
  AbilityCooldown=(traits.AbilityCooldownMultiplier or 1)*(passive.AbilityCooldownMultiplier or 1)*(effect.AbilityCooldownMultiplier or 1)*(flower.AbilityCooldownMultiplier or 1),
  AbilityDuration=(traits.AbilityDurationMultiplier or 1)*(passive.AbilityDurationMultiplier or 1),
  BeeMasteryXP=1,
  CriticalChance=traits.CriticalChance or 0,
  CriticalMultiplier=(traits.CriticalMultiplier or 1)*(passive.CriticalMultiplier or 1),
  SplashChance=traits.SplashChance or 0,
  SplashPercent=traits.SplashPercent or 0,
  DualPollinationChance=traits.DualPollinationChance or 0,
  DualPollinationPercent=traits.DualPollinationPercent or 0,
 }
end

return S
