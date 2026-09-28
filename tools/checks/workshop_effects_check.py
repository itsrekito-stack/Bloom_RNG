#!/usr/bin/env python3
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src: raise AssertionError(f"{label}: missing {text!r}")

effects=read("src/ReplicatedStorage/Config/WorkshopEffectsConfig.luau")
helper=read("src/ReplicatedStorage/Shared/WorkshopEffects.luau")
workshop_cfg=read("src/ReplicatedStorage/Config/WorkshopConfig.luau")
bloom=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau")
stats=read("src/ServerScriptService/Services/StatsService.luau")
poll=read("src/ServerScriptService/Services/PollinatorService.luau")
season=read("src/ServerScriptService/Services/SeasonService.luau")
activity=read("src/ServerScriptService/Services/GardenActivityService.luau")
roll=read("src/ServerScriptService/Services/RollService.luau")
pool=read("src/ReplicatedStorage/Config/RollPoolConfig.luau")
plan=read("src/ReplicatedStorage/Shared/SeasonPlan.luau")
workshop_service=read("src/ServerScriptService/Services/WorkshopService.luau")
ui_state=read("src/ServerScriptService/Services/UIStateService.luau")
rules=read("src/ReplicatedStorage/Shared/GardenRules.luau")

branches=["ROLL","GARDEN","BEES","ECONOMY","BLOOM","EXPLORATION","LEGACY"]
expected={f"{branch}_{i}" for branch in branches for i in range(1,7)}
actual=set(re.findall(r"\b([A-Z]+_[1-6])=\{",effects))
if actual!=expected:
    raise AssertionError(f"WorkshopEffectsConfig coverage mismatch: missing={sorted(expected-actual)} extra={sorted(actual-expected)}")

need(helper,'function S.Value(p,id,key,default)',"numeric effect API")
need(helper,'function S.Feature(p,id,feature)',"feature effect API")
need(workshop_cfg,"runtime Workshop geometry is authored in StarterGui/BloomUI.model.json","authored Workshop geometry")
need(workshop_cfg,'GARDEN={"Healthy Soil","Garden Fortune","Quick Replant","Deep Roots","Pattern Lens","Living Garden"}',"Garden branch names match live effects")
need(workshop_cfg,'BEES={"Stronger Wings","Ability Tokens","Mastery Practice","Trait Depth","Rich Nectar","Swarm Protocol"}',"Bee branch names match live effects")
need(workshop_cfg,'ECONOMY={"Coin Sense","Honey Storage","Nectar Refining","Milestone Chest","Prosperity I","Prosperity II"}',"Economy branch names match live effects")

# Capacity is Hive progression now, never a Workshop effect.
if "FlowerSlots" in effects or "BeeSlots" in effects:
    raise AssertionError("retired Workshop slot-capacity effects returned")
if "WorkshopEffects" in rules or "GARDEN_1" in rules or "BEES_1" in rules:
    raise AssertionError("GardenRules still depends on Workshop capacity nodes")

for needle,label in [
 ('E.Value(p,"GARDEN_1","FlowerGrowthMultiplier",1)',"GARDEN_1"),
 ('E.Value(p,"GARDEN_2","LuckMultiplier",1)',"GARDEN_2"),
 ('E.Value(p,"GARDEN_4","FlowerGrowthMultiplier",1)',"GARDEN_4"),
 ('E.Value(p,"GARDEN_6","PollinatorYieldMultiplier",1)',"GARDEN_6"),
 ('E.Value(p,"BEES_1","PollinatorPowerMultiplier",1)',"BEES_1"),
 ('E.Value(p,"BEES_5","PollinatorYieldMultiplier",1)',"BEES_5"),
 ('E.Value(p,"ECONOMY_1","CoinYield",1)',"ECONOMY_1"),
 ('E.Value(p,"ECONOMY_2","HiveHoneyMultiplier",1)',"ECONOMY_2"),
 ('E.Value(p,"ECONOMY_5","CoinYield",1)',"ECONOMY_5"),
]:
    need(stats,needle,label+" stat consumer")

need(ui_state,'Effects.Feature(profile,"GARDEN_5","PatternHints")',"GARDEN_5 pattern-hint consumer")
need(bloom,'WorkshopEffects.Feature(p,"GARDEN_3","RepeatPlant")',"GARDEN_3 Quick Replant consumer")
need(poll,'E.Feature(profile,"BEES_2","GuaranteedAbilityToken")',"BEES_2 ability-token consumer")
need(poll,'E.Value(p,"BEES_3","BeeXP",1)',"BEES_3 duplicate Mastery consumer")
need(poll,'E.Value(profile,"BEES_4","TraitCooldown",1)',"BEES_4 trait cooldown consumer")
need(poll,'E.Value(profile,"BEES_6","AbilityYield",1)',"BEES_6 ability yield consumer")
need(season,'E.Value(p,"ECONOMY_3","DustYield",1)',"ECONOMY_3 Nectar refining consumer")
need(workshop_service,'E.Value(p,"ECONOMY_4","MilestoneCoins",0)',"ECONOMY_4 milestone chest consumer")
need(poll,'E.Value(profile,"ECONOMY_6","CoinYield",1)',"ECONOMY_6 prosperity consumer")

for needle,label in [
 ('E.Value(p,"BLOOM_3","NewWeight",1)',"BLOOM_3"),
 ('E.Value(p,"EXPLORATION_5","EclipseWeight",1)',"EXPLORATION_5"),
 ('E.Value(p,"BLOOM_6","SignatureWeight",1)',"BLOOM_6"),
]:
    need(pool,needle,label+" RollPool consumer")
for needle,label in [
 ('E.Value(p,"ROLL_6","RollCooldown"',"ROLL cooldown"),
 ('E.Value(p,"ROLL_2","Reserve",0)',"ROLL reserve"),
 ('E.Value(p,"BLOOM_4","Reserve",0)',"Bloom reserve"),
 ('E.Value(p,"BLOOM_5","MutationChance",0)',"Bloom mutation"),
]:
    need(roll,needle,label+" consumer")
for needle,label in [
 ('E.Value(p,"EXPLORATION_3","CrystalSeconds",0)',"EXPLORATION_3"),
 ('E.Value(p,"BLOOM_2","ManualCharge",1)',"BLOOM_2"),
 ('E.Value(p,"EXPLORATION_2","RouteCharge",1)',"EXPLORATION_2"),
]:
    need(activity,needle,label+" activity consumer")
need(plan,'E.Value(profile,"LEGACY_6","SeasonNectar",0)',"LEGACY_6 consumer")
need(plan,'E.Value(profile,"LEGACY_2","MemoryMastery",0)',"LEGACY_2 consumer")
need(bloom,'WorkshopEffects.Value(profile,"ROLL_3","RevealScale",1)',"ROLL_3 reveal consumer")

for retired in ("AutoDissolve","DissolveFilters","StudyDiscount"):
    if retired in effects:
        raise AssertionError(f"retired Workshop effect returned: {retired}")

print(f"workshop-effects authority: PASS ({len(expected)} node effect entries)")
print("Capacity belongs to Hive; ordinary Workshop nodes now modify live stats and major nodes retain explicit mechanics/QoL handlers.")
