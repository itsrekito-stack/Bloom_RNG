#!/usr/bin/env python3
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src: raise AssertionError(f"{label}: missing {text!r}")

flowers=read("src/ReplicatedStorage/Config/FlowersConfig.luau")
stats=read("src/ServerScriptService/Services/StatsService.luau")
boosts=read("src/ServerScriptService/Services/BoostService.luau")
garden=read("src/StarterPlayer/StarterPlayerScripts/Controllers/GardenEditorController.luau")
index=read("src/StarterPlayer/StarterPlayerScripts/Controllers/IndexController.luau")

species=set(re.findall(r'^species\("([A-Za-z0-9_]+)"',flowers,re.M))
if len(species)<12:
    raise AssertionError(f"expected at least 12 Flower species, got {len(species)}")

block_match=re.search(r'local LEVEL_BUFFS=\{(.*?)\n\}',flowers,re.S)
if not block_match:
    raise AssertionError("LEVEL_BUFFS table missing")
rows={}
for m in re.finditer(r'^\s*([A-Za-z0-9_]+)=\{([^\n]+)\},?$',block_match.group(1),re.M):
    flower_id,body=m.groups()
    stat=re.search(r'Stat="([^"]+)"',body)
    label=re.search(r'Label="([^"]+)"',body)
    base=re.search(r'Base=([0-9.]+)',body)
    per=re.search(r'PerLevel=([0-9.]+)',body)
    cap=re.search(r'Cap=([0-9.]+)',body)
    if not all((stat,label,base,per,cap)):
        raise AssertionError(f"malformed level buff row: {flower_id}")
    rows[flower_id]={
        "stat":stat.group(1),"label":label.group(1),
        "base":float(base.group(1)),"per":float(per.group(1)),"cap":float(cap.group(1)),
        "inverse":"Inverse=true" in body,
    }

if set(rows)!=species:
    raise AssertionError(f"every Flower must have exactly one Level passive: missing={sorted(species-set(rows))} extra={sorted(set(rows)-species)}")

allowed={
    "LuckMultiplier","PollinatorYieldMultiplier","PollinatorTravelSpeedMultiplier",
    "PollinatorPowerMultiplier","FlowerGrowthMultiplier","CoinMultiplier",
    "HiveHoneyMultiplier","AbilityCooldownMultiplier",
}
for flower_id,row in rows.items():
    if row["stat"] not in allowed:
        raise AssertionError(f"{flower_id}: unsupported passive stat {row['stat']}")
    if row["base"]<=0 or row["per"]<=0 or row["cap"]<=row["base"]:
        raise AssertionError(f"{flower_id}: passive must grow from a positive base toward a higher cap")
    if row["cap"]>.50:
        raise AssertionError(f"{flower_id}: passive cap is too large for one planted slot: {row['cap']}")
    l1=min(row["cap"],row["base"])
    l25=min(row["cap"],row["base"]+24*row["per"])
    l100=min(row["cap"],row["base"]+99*row["per"])
    if not (l1<l25<=l100<=row["cap"]+1e-9):
        raise AssertionError(f"{flower_id}: passive does not scale monotonically with Flower Level")
    if row["inverse"] and row["stat"]!="AbilityCooldownMultiplier":
        raise AssertionError(f"{flower_id}: inverse scaling is only valid for cooldown")

need(flowers,"function C.GetLevelBuff(id,level)","level buff API")
need(flowers,"local lv=math.clamp(math.floor(tonumber(level) or 1),1,Bloom.MasteryCap)","Flower Level clamp")
need(flowers,"(lv-1)*(tonumber(cfg.PerLevel) or 0)","per-Level growth")
need(flowers,"function C.FormatLevelBuff(id,level)","player-facing passive formatter")

need(stats,"for _,slot in ipairs((p.Garden and p.Garden.Slots) or {}) do","only planted Garden Flowers contribute")
need(stats,"local mastery=p.FlowerCollection and p.FlowerCollection.FlowerMastery and p.FlowerCollection.FlowerMastery[id]","species Level is authoritative source")
need(stats,"local buff=F.GetLevelBuff and F.GetLevelBuff(id,mastery and mastery.Level or 1) or nil","authoritative Flower passive lookup")
for field in [
    "flower.LuckMultiplier","flower.PollinatorYieldMultiplier","flower.PollinatorTravelSpeedMultiplier",
    "flower.PollinatorPowerMultiplier","flower.FlowerGrowthMultiplier","flower.CoinMultiplier",
    "flower.HiveHoneyMultiplier","flower.AbilityCooldownMultiplier",
]:
    need(stats,field,f"{field} enters live StatsService")

need(boosts,'source(buckets,stat,"Flowers",flower.DisplayName.." • Lv."..tostring(level)',"Active Boosts shows planted Flower source and Level")
need(garden,'Flowers.FormatLevelBuff(id,mastery.Level)',"Garden shows selected Flower passive")
need(index,'Flowers.FormatLevelBuff(item.Id,level)',"Index shows current Flower passive")
need(index,'Flowers.FormatLevelBuff(item.Id,level+1)',"Index previews next Flower Level passive")

luck_flowers={flower_id for flower_id,row in rows.items() if row["stat"]=="LuckMultiplier"}
if not {"Clover","PrismBloom","MoonOrchid","StarBloom"}<=luck_flowers:
    raise AssertionError(f"Luck progression Flower line incomplete: {sorted(luck_flowers)}")

print("flower level buffs v2 contract: PASS")
print(f"{len(rows)} planted Flower passives scale monotonically with Flower Level and feed authoritative stats/UI.")
