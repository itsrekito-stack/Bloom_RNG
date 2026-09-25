#!/usr/bin/env python3
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src: raise AssertionError(f"{label}: missing {text!r}")

bees=read("src/ReplicatedStorage/Config/BeesConfig.luau")
stats=read("src/ServerScriptService/Services/StatsService.luau")
poll=read("src/ServerScriptService/Services/PollinatorService.luau")
ui=read("src/ServerScriptService/Services/UIStateService.luau")
inventory=read("src/StarterPlayer/StarterPlayerScripts/Controllers/InventoryV2Controller.luau")
bloom=read("src/ReplicatedStorage/Config/BloomConfig.luau")

block=bees.split("C.BeeMastery={",1)[1].split("\nC.Traits=",1)[0]
need(block,"Cap=10","mastery cap")
m=re.search(r"XPPerLevel=\{([^}]+)\}",block)
if not m: raise AssertionError("mastery XP ladder missing")
xp=[int(x) for x in re.findall(r"\d+",m.group(1))]
if len(xp)!=9 or any(x<=0 for x in xp): raise AssertionError(f"unexpected mastery XP ladder: {xp}")
rewards={int(level):body for level,body in re.findall(r"\[(\d+)\]=\{([^}]*)\}",block)}
if set(rewards)!=set(range(2,11)): raise AssertionError(f"mastery reward levels incomplete: {sorted(rewards)}")
def amount(key):
    total=0.0
    for body in rewards.values():
        m=re.search(rf"\b{key}=([0-9.]+)",body)
        if m: total+=float(m.group(1))
    return total
work=amount("WorkSpeed")
yield_bonus=amount("Yield")
cooldown=amount("AbilityCooldown")
if not 0.08<=work<=0.20: raise AssertionError(f"mastery work bonus out of guardrail: {work}")
if not 0.08<=yield_bonus<=0.20: raise AssertionError(f"mastery yield bonus out of guardrail: {yield_bonus}")
if not 0.05<=cooldown<=0.15: raise AssertionError(f"mastery cooldown bonus out of guardrail: {cooldown}")
delivery=float(re.search(r"DeliverySeconds=([0-9.]+)",bloom).group(1))
base_minutes=sum(xp)*delivery/60
if not 45<=base_minutes<=150: raise AssertionError(f"mastery pacing outside intended range: {base_minutes:.1f} minutes")

need(bees,"function C.GetMasteryState(totalXP:number?):any","shared mastery derivation")
need(bees,"NextRewardText=","server/shared reward copy")
need(stats,"BeeMasteryXP=(traits.BeeMasteryXPMultiplier or 1)*(passive.BeeMasteryXPMultiplier or 1)","Arcane mastery XP reaches runtime stats")
need(poll,"local mastery=B.GetMasteryState(profile.Pollinators.BeeMastery[id])","server derives equipped bee mastery")
need(poll,"*mastery.WorkSpeedMultiplier","mastery affects work speed")
need(poll,"*mastery.AbilityCooldownMultiplier*","mastery affects ability cooldown")
need(poll,"*(mastery.YieldMultiplier or 1)","mastery affects delivery yield")
need(poll,"function S:AddMastery(player,id,baseAmount,abilityMultiplier)","central Bee Mastery grant path")
need(poll,"*(stats.BeeMasteryXP or 1)","trait Bee Mastery XP multiplier")
need(poll,"*(tonumber(abilityMultiplier) or 1)","supplied ability Bee Mastery XP multiplier")
need(poll,'self:AddMastery(player,bee.Id,1,active and (ability.BeeMasteryXPMultiplier or 1) or 1)',"delivery supplies active ability mastery XP multiplier")
need(poll,'Mastery Lv. "..after.Level',"level-up player feedback")
need(ui,"Mastery=mastery","authoritative mastery included in inventory payload")
need(inventory,"Mastery=entry.Mastery or Bees.GetMasteryState(0)","Inventory V2 consumes mastery payload")
need(inventory,'masteryLabel.Text="Bee Mastery"',"Inventory V2 mastery label")
need(inventory,"item.Mastery.Progress","Inventory V2 mastery progress bar")
need(inventory,"item.Mastery.NextRewardText","Inventory V2 next reward copy")

print("bee mastery contract: PASS")
print(f"Bee Mastery: 10 levels, {sum(xp)} base XP, about {base_minutes:.1f} base minutes to cap.")
print(f"Max rewards: +{work*100:.0f}% work, +{yield_bonus*100:.0f}% yield, -{cooldown*100:.0f}% ability cooldown.")
