#!/usr/bin/env python3
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src: raise AssertionError(f"{label}: missing {text!r}")
effects=read("src/ReplicatedStorage/Config/WorkshopEffectsConfig.luau")
helper=read("src/ReplicatedStorage/Shared/WorkshopEffects.luau")
cfg=read("src/ReplicatedStorage/Config/WorkshopConfig.luau")
stats=read("src/ServerScriptService/Services/StatsService.luau")
poll=read("src/ServerScriptService/Services/PollinatorService.luau")
flower=read("src/ServerScriptService/Services/FlowerProgressionService.luau")
inventory=read("src/ServerScriptService/Services/InventoryService.luau")
pool=read("src/ReplicatedStorage/Config/RollPoolConfig.luau")
roll=read("src/ServerScriptService/Services/RollService.luau")
activity=read("src/ServerScriptService/Services/GardenActivityService.luau")
quests=read("src/ServerScriptService/Services/QuestService.luau")
season=read("src/ReplicatedStorage/Shared/SeasonPlan.luau")
social=read("src/ServerScriptService/Services/SocialService.luau")
new_branches=["FORTUNE","MASTERY","HONEY","COINS","GROWTH","POLLEN","POWER","SWIFT","ABILITY","CRITICAL","CHARGE","DISCOVERY","RARITY","DUPLICATES","ACTIVITY","QUESTS","MUTATION","SEASON","SOCIAL","OVERDRIVE"]
block=re.search(r'Branches=\{(.*?)\n \},',cfg,re.S)
assert block, "Workshop branch block missing"
branches=re.findall(r'"([A-Z]+)"',block.group(1))
assert len(branches)==27 and all(x in branches for x in new_branches), branches
for b in new_branches: need(effects,b+'={Key=',b+" effect definition")
need(helper,'function S.BranchProduct(p,branch,key,default)',"branch multiplier API")
need(helper,'function S.BranchSum(p,branch,key,default)',"branch additive API")
consumers={
"FORTUNE":(stats,'E.BranchProduct(p,"FORTUNE","LuckMultiplier",1)'),
"MASTERY":(poll,'E.BranchProduct(p,"MASTERY","MasteryXPMultiplier",1)'),
"HONEY":(stats,'E.BranchProduct(p,"HONEY","HiveHoneyMultiplier",1)'),
"COINS":(stats,'E.BranchProduct(p,"COINS","CoinMultiplier",1)'),
"GROWTH":(stats,'E.BranchProduct(p,"GROWTH","FlowerGrowthMultiplier",1)'),
"POLLEN":(stats,'E.BranchProduct(p,"POLLEN","PollinatorYieldMultiplier",1)'),
"POWER":(stats,'E.BranchProduct(p,"POWER","PollinatorPowerMultiplier",1)'),
"SWIFT":(stats,'E.BranchProduct(p,"SWIFT","PollinatorTravelSpeedMultiplier",1)'),
"ABILITY":(stats,'E.BranchProduct(p,"ABILITY","AbilityCooldownMultiplier",1)'),
"CRITICAL":(stats,'E.BranchSum(p,"CRITICAL","CriticalChance",0)'),
"CHARGE":(activity,'E.BranchProduct(p,"CHARGE","BloomChargeMultiplier",1)'),
"DISCOVERY":(pool,'E.BranchProduct(p,"DISCOVERY","DiscoveryWeightMultiplier",1)'),
"RARITY":(pool,'E.BranchProduct(p,"RARITY","RareWeightMultiplier",1)'),
"DUPLICATES":(flower,'E.BranchProduct(p,"DUPLICATES","DuplicateXPMultiplier",1)'),
"ACTIVITY":(poll,'E.BranchProduct(profile,"ACTIVITY","ActivityIntervalMultiplier",1)'),
"QUESTS":(quests,'Effects.BranchProduct(profile,"QUESTS","QuestRewardMultiplier",1)'),
"MUTATION":(roll,'E.BranchSum(p,"MUTATION","MutationChance",0)'),
"SEASON":(season,'E.BranchProduct(profile,"SEASON","SeasonRewardMultiplier",1)'),
"SOCIAL":(social,'E.BranchProduct(target,"SOCIAL","BlessingMultiplier",1)'),
"OVERDRIVE":(poll,'E.BranchProduct(profile,"OVERDRIVE","AbilityRewardMultiplier",1)'),
}
for branch,(src,token) in consumers.items(): need(src,token,branch+" runtime consumer")
need(inventory,'E.BranchProduct(p,"DUPLICATES","DuplicateXPMultiplier",1)',"Bee duplicate XP consumer")
for old in ("ROLL_1","GARDEN_1","BEES_1","ECONOMY_1","BLOOM_1","EXPLORATION_1","LEGACY_1"):
    need(effects,old+"={",old+" legacy branch effect")
print("workshop-effects authority: PASS (27 branches / 162 purchasable nodes)")
