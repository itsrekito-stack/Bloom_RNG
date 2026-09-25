#!/usr/bin/env python3
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")

flowers=read("src/ReplicatedStorage/Config/FlowersConfig.luau")
bees=read("src/ReplicatedStorage/Config/BeesConfig.luau")
locations=read("src/ReplicatedStorage/Config/LocationsConfig.luau")
trials=read("src/ReplicatedStorage/Config/BuildTrialConfig.luau")
workshop=read("src/ReplicatedStorage/Config/WorkshopConfig.luau")
activities=read("src/ReplicatedStorage/Config/ActivityConfig.luau")
season=read("src/ReplicatedStorage/Config/SeasonConfig.luau")
meta=read("src/ServerScriptService/Services/MetaProgressionService.luau")

EXPECTED_FLOWERS={
 "Daisy","Tulip","Sunflower","Clover",
 "CrystalRose","FrostLily","PrismBloom","MoonOrchid",
 "Nightshade","VoidLotus","StarBloom","EmberDahlia",
}
EXPECTED_BEES={
 "WorkerBee","SprinterBee","NectarBee","ScholarBee","TwinBee","RoyalBee",
 "PrismBee","TwilightBee","BloomQueenBee","CrystalBee","MagmaBee","ShadowBee","StormBee",
}
EXPECTED_LOCATIONS={"SunnyOrchard","CrystalGreenhouse","TwilightGrove"}
EXPECTED_TRIALS={
 "MeadowCircuit","SwiftRoute","CrystalTriangle","NoCelestial",
 "SignatureBloom","TwilightPulse","MinimalGarden","MutationStudy",
}
EXPECTED_WORKSHOP_BRANCHES={"ROLL","GARDEN","BEES","ECONOMY","BLOOM","EXPLORATION","LEGACY"}
EXPECTED_ACTIVITIES={
 "PollenSpark","NectarBud","DewDrop","PollenTrail","CrossPollination","Overcharge",
 "BloomSurge","PollenWind","SolarBloom","CrystalResonance","ShadowBloom","FireflyRoute",
}
EXPECTED_SEASON_CARDS={"SpringResonance","SummerSwarm","AutumnFortune","CrystalSeason","TwilightSeason"}
EXPECTED_JOURNEY=[
 "StarterBee","PollenSpark","Delivery","Roll","Plant","Charge","BloomRoll","Hive2",
 "WorkshopVisit","WorkshopPurchase","Synergy","BeeSlots","Trait","SunnyVisit","SolarBloom",
 "Discover6","CrystalGate","Trial","CrystalVisit","SeasonReady",
]

actual_flowers=set(re.findall(r'^species\("([^"]+)"',flowers,re.M))
actual_bees=set(re.findall(r'^\s*([A-Za-z0-9_]+)=\{Id="[^"]+",DisplayName=',bees,re.M))
actual_locations=set(re.findall(r'^\s*([A-Za-z0-9_]+)=\{Name="[^"]+",Hive=',locations,re.M))
actual_trials=set(re.findall(r'^\s*([A-Za-z0-9_]+)=\{Id="[^"]+",Name="[^"]+",Sector=',trials,re.M))

branch_match=re.search(r'Branches=\{([^}]*)\}',workshop)
if not branch_match: raise AssertionError("Workshop branch list missing")
actual_branches=set(re.findall(r'"([^"]+)"',branch_match.group(1)))

actual_activities=set(re.findall(r'([A-Za-z0-9_]+)=\{Life=',activities))

cards_match=re.search(r'Cards=\{([^}]*)\}',season)
if not cards_match: raise AssertionError("Season card list missing")
actual_cards=set(re.findall(r'"([^"]+)"',cards_match.group(1)))

journey_match=re.search(r'local goals=\{([^}]*)\}',meta)
if not journey_match: raise AssertionError("Journey goal list missing")
actual_journey=re.findall(r'"([^"]+)"',journey_match.group(1))

for label,actual,expected in [
 ("flowers",actual_flowers,EXPECTED_FLOWERS),
 ("bees",actual_bees,EXPECTED_BEES),
 ("locations",actual_locations,EXPECTED_LOCATIONS),
 ("trials",actual_trials,EXPECTED_TRIALS),
 ("Workshop branches",actual_branches,EXPECTED_WORKSHOP_BRANCHES),
 ("activities",actual_activities,EXPECTED_ACTIVITIES),
 ("Season cards",actual_cards,EXPECTED_SEASON_CARDS),
]:
 if actual!=expected:
  raise AssertionError(f"release {label} changed: missing={sorted(expected-actual)} extra={sorted(actual-expected)}")

if actual_journey!=EXPECTED_JOURNEY:
 raise AssertionError(f"release Journey changed: expected={EXPECTED_JOURNEY} actual={actual_journey}")

# Release structure guardrails.
if len(actual_flowers)!=12: raise AssertionError("release must ship 12 flowers")
if len(actual_bees)!=13: raise AssertionError("release must ship 13 bees")
if len(actual_locations)!=3: raise AssertionError("release must ship 3 locations")
if len(actual_trials)!=8: raise AssertionError("release must ship 8 trials")
if len(actual_branches)!=7: raise AssertionError("release must ship 7 Workshop branches")
if len(actual_activities)!=12: raise AssertionError("release must ship 12 activity types")
if len(actual_cards)!=5: raise AssertionError("release must ship 5 Season cards")
if len(actual_journey)!=20: raise AssertionError("release must ship 20 Journey objectives")

# The three Season-critical trials must remain the stable base subset.
season_trials=re.search(r'TrialIds=\{([^}]*)\}',season)
if not season_trials: raise AssertionError("Season TrialIds missing")
season_trial_ids=re.findall(r'"([^"]+)"',season_trials.group(1))
if season_trial_ids!=["MeadowCircuit","SwiftRoute","CrystalTriangle"]:
 raise AssertionError(f"Season key trial set changed: {season_trial_ids}")

print("release content lock: PASS")
print("v1 content: 12 flowers, 13 bees, 3 locations, 8 trials, 7 Workshop branches, 12 activities, 5 Season cards, 20 Journey objectives.")
