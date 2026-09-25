#!/usr/bin/env python3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src:
        raise AssertionError(f"{label}: missing {text!r}")

bees=read("src/ReplicatedStorage/Config/BeesConfig.luau")
stats=read("src/ServerScriptService/Services/StatsService.luau")
poll=read("src/ServerScriptService/Services/PollinatorService.luau")
inventory=read("src/ServerScriptService/Services/InventoryService.luau")

if "PlayerXPMultiplier" in bees:
    raise AssertionError("bee config still promises disconnected Player XP")

for field,label in [
    ("Power=(traits.PollinatorPowerMultiplier or 1)*(passive.PollinatorPowerMultiplier or 1)","power"),
    ("FlowerGrowth=(traits.FlowerGrowthMultiplier or 1)*(passive.FlowerGrowthMultiplier or 1)","flower growth"),
    ("Coin=(traits.CoinMultiplier or 1)*(passive.CoinMultiplier or 1)","coin"),
    ("HiveHoney=(traits.HiveHoneyMultiplier or 1)*(passive.HiveHoneyMultiplier or 1)","hive honey"),
    ("ClonePower=(traits.ClonePowerMultiplier or 1)*(passive.ClonePowerMultiplier or 1)","clone power"),
    ("AbilityDuration=(traits.AbilityDurationMultiplier or 1)*(passive.AbilityDurationMultiplier or 1)","ability duration"),
    ("CriticalChance=traits.CriticalChance or 0","critical chance"),
    ("SplashChance=traits.SplashChance or 0","splash"),
    ("DualPollinationChance=traits.DualPollinationChance or 0","dual pollination"),
]:
    need(stats,field,f"runtime stat {label}")

need(poll,"local abilityWork=tonumber(ability.WorkMultiplier) or 1","ability work multiplier")
need(poll,"rewardMultiplier=(tonumber(ability.RewardMultiplier) or 1)","ability reward multiplier")
need(poll,"hiveMultiplier=tonumber(ability.HiveHoneyMultiplier) or 1","ability Hive Honey multiplier")
need(poll,"criticalChanceBonus=tonumber(ability.CriticalChanceBonus) or 0","ability critical chance")
need(poll,"*(stats.HiveHoney or 1)*(hiveMultiplier or 1)","Hive Honey trait/passive runtime")
need(poll,"*(stats.Coin or 1)*E.Value(profile","Coin trait/passive runtime")
need(poll,"*(stats.Power or 1)*(stats.FlowerGrowth or 1)","power and flower-growth runtime")
need(poll,"*(stats.AbilityDuration or 1)","Mirror duration runtime")
need(poll,"*(stats.ClonePower or 1)","Mirror clone runtime")
need(poll,"stats.SplashChance","Meadow splash runtime")
need(poll,"stats.DualPollinationChance","Meadow dual-pollination runtime")
need(poll,"ability.ExtraTargetCount","extra-target ability runtime")
need(poll,"ability.ExtraTargetPercent","extra-target power runtime")
need(poll,"ability.TickCount","periodic tick runtime")
need(poll,"ability.TickInterval","periodic tick cadence")
need(poll,"ability.TickWorkSeconds","periodic tick work")
need(poll,"ability.TickRewardMultiplier","periodic tick rewards")
need(poll,"ability.TickHiveMultiplier","periodic tick Hive reward")
need(poll,"ability.BurstTargets","burst target runtime")
need(poll,"ability.BurstWorkSeconds","burst work runtime")
need(poll,"ability.BurstRewardMultiplier","burst reward runtime")
need(poll,"ability.BurstHiveMultiplier","burst Hive runtime")
need(poll,"rng:NextNumber()<C.AbilityTokenChance","ability token chance uses BloomConfig")
need(poll,"while state.Elapsed>=C.DeliverySeconds and deliveryGuard<8 do","large-dt delivery catch-up is bounded")
need(poll,'if type(index)~="number" or index>capacity or equipped~=state.Id then states[index]=nil end',"unequipped runtime state pruning")

need(inventory,'if not self.X.U.Integer(slot,capacity) then return false,"INVALID_SLOT" end',"equipment slot authority")
need(inventory,'if (p.Pollinators.BeeInventory[id] or 0)<1 then return false,"NOT_OWNED" end',"bee ownership authority")
need(inventory,'if used>=(p.Pollinators.BeeInventory[id] or 0) then return false,"NOT_OWNED" end',"duplicate equipped-copy authority")

for field in [
    "WorkMultiplier","RewardMultiplier","HiveHoneyMultiplier","CriticalChanceBonus",
    "ExtraTargetCount","ExtraTargetPercent","TickCount","TickInterval",
    "TickWorkSeconds","TickRewardMultiplier","TickHiveMultiplier",
    "BurstTargets","BurstWorkSeconds","BurstRewardMultiplier","BurstHiveMultiplier",
]:
    if field in bees and field not in poll:
        raise AssertionError(f"configured bee mechanic lacks runtime hook: {field}")

print("bee runtime contract: PASS")
print("Traits, active abilities, special ticks/bursts and equipment state are connected to server runtime.")
