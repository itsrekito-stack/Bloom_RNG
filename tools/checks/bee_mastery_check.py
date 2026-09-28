#!/usr/bin/env python3
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src: raise AssertionError(f"{label}: missing {text!r}")

bees=read("src/ReplicatedStorage/Config/BeesConfig.luau")
bloom=read("src/ReplicatedStorage/Config/BloomConfig.luau")
poll=read("src/ServerScriptService/Services/PollinatorService.luau")
activity=read("src/ServerScriptService/Services/GardenActivityService.luau")
inventory_service=read("src/ServerScriptService/Services/InventoryService.luau")
ui=read("src/ServerScriptService/Services/UIStateService.luau")
inventory_ui=read("src/StarterPlayer/StarterPlayerScripts/Controllers/InventoryV2Controller.luau")

block=bees.split("C.BeeMastery={",1)[1].split("\nC.Traits=",1)[0]
need(block,"Cap=10","Bee Mastery cap")
m=re.search(r"XPPerLevel=\{([^}]+)\}",block)
if not m: raise AssertionError("Bee Mastery XP ladder missing")
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

work=amount("WorkSpeed"); yield_bonus=amount("Yield"); cooldown=amount("AbilityCooldown")
if not 0.08<=work<=0.20: raise AssertionError(f"mastery work bonus out of guardrail: {work}")
if not 0.08<=yield_bonus<=0.20: raise AssertionError(f"mastery yield bonus out of guardrail: {yield_bonus}")
if not 0.05<=cooldown<=0.15: raise AssertionError(f"mastery cooldown bonus out of guardrail: {cooldown}")

m=re.search(r"\bBeeDuplicateXP=(\d+)",bloom)
if not m: raise AssertionError("BeeDuplicateXP missing")
duplicate_xp=int(m.group(1))
duplicates=sum(xp)/duplicate_xp
if not 15<=duplicates<=60: raise AssertionError(f"Bee duplicate pacing outside guardrail: {duplicates:.1f} duplicates to cap")

need(bees,"function C.GetMasteryState(totalXP:number?):any","shared species Mastery derivation")
need(poll,"function S:AddMastery(player,id,baseAmount)","single duplicate Mastery grant path")
need(poll,"*E.Value(p,\"BEES_3\",\"BeeXP\",1)","Workshop can modify duplicate Mastery gain")
need(poll,"*mastery.WorkSpeedMultiplier","Mastery affects work speed")
need(poll,"*mastery.AbilityCooldownMultiplier","Mastery affects ability cooldown")
need(poll,"*(mastery.YieldMultiplier or 1)","Mastery affects yield")
need(inventory_service,'pollinators.BeeInventory[id]=1',"first Bee unlock creates species ownership")
need(inventory_service,'pollinators.BeeObtained[id]=(pollinators.BeeObtained[id] or 0)+1',"Bee obtained count is tracked")
need(inventory_service,'self.X.PollinatorService:AddMastery(player,id,C.BeeDuplicateXP)',"duplicate Bee advances species Mastery")
if "self:AddMastery(player,bee.Id,1" in poll:
    raise AssertionError("routine pollination still advances Bee Mastery")
if "PollinatorService:AddMastery(player,bee" in activity:
    raise AssertionError("activities still advance Bee Mastery")

need(ui,"Obtained=profile.Pollinators.BeeObtained[id] or 1","authoritative Bee obtained count reaches UI")
need(ui,"Mastery=mastery","authoritative Bee Mastery reaches Inventory")
need(inventory_ui,'masteryLabel.Text="Bee Mastery"',"Bee detail shows Mastery")
need(inventory_ui,"item.Mastery.Progress","Bee detail shows Mastery progress")
need(inventory_ui,"item.Mastery.NextRewardText","Bee detail previews next Mastery reward")
need(inventory_ui,"traitEquipPreview(item,inventory)","Bee detail previews Trait delta")

print("bee mastery contract: PASS")
print(f"Bee Mastery is species-wide and duplicate-driven: ~{duplicates:.1f} base duplicates to cap.")
print(f"Max rewards: +{work*100:.0f}% work, +{yield_bonus*100:.0f}% yield, -{cooldown*100:.0f}% ability cooldown.")
