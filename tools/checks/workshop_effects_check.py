#!/usr/bin/env python3
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[2]

def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

def require(text, needle, label):
    if needle not in text:
        raise AssertionError(f"{label}: missing {needle!r}")

effects=read("src/ReplicatedStorage/Config/WorkshopEffectsConfig.luau")
helper=read("src/ReplicatedStorage/Shared/WorkshopEffects.luau")
workshop_cfg=read("src/ReplicatedStorage/Config/WorkshopConfig.luau")
bloom=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau")

branches=["ROLL","GARDEN","BEES","ECONOMY","BLOOM","EXPLORATION","LEGACY"]
expected={f"{branch}_{i}" for branch in branches for i in range(1,7)}
actual=set(re.findall(r"\b([A-Z]+_[1-6])=\{",effects))
if actual != expected:
    raise AssertionError(f"WorkshopEffectsConfig node coverage mismatch: missing={sorted(expected-actual)} extra={sorted(actual-expected)}")

require(effects,'BEES_2={Feature="GuaranteedAbilityToken"}',"BEES_2 matches current guaranteed-token runtime behavior")
require(helper,'function S.Value(p,id,key,default)',"explicit numeric effect API")
require(helper,'function S.Feature(p,id,feature)',"explicit feature effect API")
require(workshop_cfg,"runtime Workshop geometry is authored in StarterGui/BloomUI.model.json","geometry authority documented")

consumers={
 "src/ReplicatedStorage/Shared/GardenRules.luau":[
  'E.Value(p,"GARDEN_1","FlowerSlots",0)','E.Value(p,"GARDEN_4","FlowerSlots",0)',
  'E.Value(p,"BEES_1","BeeSlots",0)','E.Value(p,"BEES_5","BeeSlots",0)'],
 "src/ReplicatedStorage/Shared/SeasonPlan.luau":[
  'E.Value(profile,"LEGACY_6","SeasonNectar",0)','E.Value(profile,"LEGACY_2","MemoryMastery",0)'],
 "src/ReplicatedStorage/Config/RollPoolConfig.luau":[
  'E.Value(p,"BLOOM_3","NewWeight",1)','E.Value(p,"EXPLORATION_5","EclipseWeight",1)',
  'E.Value(p,"BLOOM_6","SignatureWeight",1)'],
 "src/ServerScriptService/Services/RollService.luau":[
  'E.Value(p,"ROLL_6","RollCooldown"','E.Value(p,"ROLL_2","Reserve",0)',
  'E.Value(p,"BLOOM_4","Reserve",0)','E.Value(p,"BLOOM_5","MutationChance",0)'],
 "src/ServerScriptService/Services/PollinatorService.luau":[
  'E.Feature(p,"BEES_2","GuaranteedAbilityToken")','E.Value(p,"BEES_3","BeeXP",1)',
  'E.Value(p,"BEES_4","TraitCooldown",1)','E.Value(p,"BEES_6","AbilityYield",1)',
  'E.Value(p,"GARDEN_6","SynergyXP",1)','E.Value(p,"ECONOMY_6","CoinYield",1)',
  'E.Value(p,"EXPLORATION_4","WildInterval",1)'],
 "src/ServerScriptService/Services/InventoryService.luau":['E.Value(p,"ECONOMY_3","DustYield",1)'],
 "src/ServerScriptService/Services/FlowerProgressionService.luau":['E.Value(p,"ECONOMY_5","StudyDiscount",0)'],
 "src/ServerScriptService/Services/UIStateService.luau":['Effects.Value(profile,"ECONOMY_5","StudyDiscount",0)'],
 "src/ServerScriptService/Services/GardenActivityService.luau":[
  'E.Value(p,"EXPLORATION_3","CrystalSeconds",0)','E.Value(p,"BLOOM_2","ManualCharge",1)',
  'E.Value(p,"EXPLORATION_2","RouteCharge",1)'],
 "src/ServerScriptService/Services/GardenSynergyService.luau":['E.Value(p,"GARDEN_2","Adjacency",0)'],
 "src/ServerScriptService/Services/WorkshopService.luau":['E.Value(p,"ECONOMY_4","MilestoneCoins",0)'],
}
for path, needles in consumers.items():
    source=read(path)
    for needle in needles:
        require(source,needle,f"{path} consumes WorkshopEffectsConfig")

require(bloom,'WorkshopEffects.Value(profile,"ROLL_3","RevealScale",1)',"ROLL_3 Fast Reveal runtime handler")
require(bloom,'WorkshopEffects.Feature(p,"GARDEN_3","RepeatPlant")',"GARDEN_3 Quick Replant runtime handler")
require(bloom,'GuaranteedAbilityToken="Rare bee abilities always offer an Overcharge token"',"BEES_2 feature description")

legacy_literals={
 "src/ServerScriptService/Services/RollService.luau":[
  "ROLL_6 and .8","ROLL_5 and 1.2","ROLL_1 and 1.4","BLOOM_5 and .1"],
 "src/ServerScriptService/Services/PollinatorService.luau":[
  "BEES_4 and .9","BEES_6 and 1.2","ECONOMY_6 and 1.15","BEES_3 and 2","GARDEN_6 and 2","EXPLORATION_4 and .8"],
 "src/ServerScriptService/Services/InventoryService.luau":["ECONOMY_3 and 1.2"],
 "src/ServerScriptService/Services/FlowerProgressionService.luau":["ECONOMY_5 and .8"],
 "src/ServerScriptService/Services/GardenActivityService.luau":["EXPLORATION_3 and 20","BLOOM_2 and 1.2","EXPLORATION_2 and 1.2"],
}
for path, needles in legacy_literals.items():
    source=read(path)
    for needle in needles:
        if needle in source:
            raise AssertionError(f"{path}: legacy hardcoded Workshop effect returned: {needle}")

print(f"workshop-effects authority: PASS ({len(expected)} node effect entries)")
print("Numeric V5 effects are config-driven; Fast Reveal and Quick Replant have runtime handlers.")
