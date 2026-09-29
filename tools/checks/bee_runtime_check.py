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
client=read("src/StarterPlayer/StarterPlayerScripts/Controllers/PollinatorController.luau")

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
need(poll,'local function chooseNextSlot(slots,current,state,states)',"per-Bee target brain")
need(poll,'brain=Random.new(rng:NextInteger(1,2147483646))',"independent Bee RNG stream")
need(poll,'if other~=state and table.find(slots,other.Slot) then occupied[other.Slot]=true end',"Bee avoids already-targeted Flowers when possible")
need(poll,'state.Slot=chooseNextSlot(slots,state.Slot,state,states) or state.Slot',"new Flower chosen after every delivery")
need(poll,'state.Slot=chooseNextSlot(slots,nil,state,states) or slots[1]',"independent initial Flower choice")
if 'if temp.Hotspot and (temp.HotspotUntil or 0)>os.clock() then' in poll:
    raise AssertionError("BloomSurge hotspot must not force every Bee onto the same Flower")

need(inventory,'if not self.X.U.Integer(slot,capacity) then return false,"INVALID_SLOT" end',"unequip slot authority")
need(inventory,'if (p.Pollinators.BeeInventory[id] or 0)<1 then return false,"NOT_OWNED" end',"bee ownership authority")
need(inventory,'if v==id then return false,"ALREADY_EQUIPPED" end',"one equipped slot per Bee species")
need(inventory,'local function chooseEquipSlot(p,id,capacity)',"server selects replacement slot when full")
need(inventory,'if rank<newRank',"replacement only removes a lower-rarity Bee")
need(inventory,'return false,"NO_LOWER_RARITY_BEE"',"equal-or-higher rarity loadout is protected")

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


# Client presentation: orientation follows the route, movement is continuous, and
# equipped Bees are visually separated without changing server-authoritative targets.
need(client,'local BEE_FORWARD_FIX=CFrame.Angles(0,math.rad(90),0)',"authored Bee forward-axis correction")
need(client,'RunService.RenderStepped:Connect',"per-frame Bee flight animation")
need(client,'CFrame.lookAt(position,position+direction,Vector3.yAxis)',"Bee faces travel direction")
need(client,'estimatedPhase(frame,packet.ReceivedAt,now)',"network phase is interpolated locally")
need(client,'spreadOffset(index,1.75)',"Hive departure spacing")
need(client,'math.sin(now*BOB_SPEED+seed)*BOB_AMOUNT',"flight bob animation")
need(client,'animateWings(item,now)',"optional authored wing animation")
need(client,'string.find(lower,"wing",1,true)',"wing discovery")
if 'TweenService' in client or 'Tween:Create' in client:
    raise AssertionError("Bee flight must not return to one-second position tweens")
