#!/usr/bin/env python3
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[2]

def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

def section(src,start,end):
    if start not in src or end not in src.split(start,1)[1]:
        raise AssertionError(f"section markers missing: {start!r} -> {end!r}")
    return src.split(start,1)[1].split(end,1)[0]

def need(src,text,label):
    if text not in src:
        raise AssertionError(f"{label}: missing {text!r}")

manifest=read("src/ReplicatedStorage/Config/ReleaseContentManifest.luau")
flowers=read("src/ReplicatedStorage/Config/FlowersConfig.luau")
bees=read("src/ReplicatedStorage/Config/BeesConfig.luau")
icons=read("src/ReplicatedStorage/Config/IconsConfig.luau")
rarity=read("src/ReplicatedStorage/Config/RarityConfig.luau")
locations=read("src/ReplicatedStorage/Config/LocationsConfig.luau")
trials=read("src/ReplicatedStorage/Config/BuildTrialConfig.luau")
workshop=read("src/ReplicatedStorage/Config/WorkshopConfig.luau")
workshop_effects=read("src/ReplicatedStorage/Config/WorkshopEffectsConfig.luau")
activities=read("src/ReplicatedStorage/Config/ActivityConfig.luau")
season=read("src/ReplicatedStorage/Config/SeasonConfig.luau")
meta=read("src/ServerScriptService/Services/MetaProgressionService.luau")

flower_manifest=section(manifest,"Flowers={","\n },\n Bees={")
bee_manifest=section(manifest,"Bees={","\n },\n Locations={")
location_manifest=section(manifest,"Locations={","\n },\n Activities={")
activity_match=re.search(r'Activities=\{([^}]*)\}',manifest)
if not activity_match:
    raise AssertionError("release activity manifest missing")
trial_manifest=section(manifest,"Trials={","\n },\n}")

EXPECTED_FLOWERS={
    m.group(1):m.group(2)
    for m in re.finditer(r'^\s*(\w+)=\{Rarity="([^"]+)"\},?\s*$',flower_manifest,re.M)
}
EXPECTED_BEES={
    m.group(1):(m.group(2),m.group(3),int(m.group(4)))
    for m in re.finditer(r'^\s*(\w+)=\{Rarity="([^"]+)",Ability="([^"]+)",SortOrder=(\d+)\},?\s*$',bee_manifest,re.M)
}
EXPECTED_LOCATIONS={}
for m in re.finditer(r'^\s*(\w+)=\{Hive=(\d+),Requires=(false|"[^"]+"),Activity="([^"]+)"\},?\s*$',location_manifest,re.M):
    req=m.group(3)
    EXPECTED_LOCATIONS[m.group(1)]=(int(m.group(2)),False if req=="false" else req.strip('"'),m.group(4))
EXPECTED_ACTIVITIES=set(re.findall(r'"([^"]+)"',activity_match.group(1)))
EXPECTED_TRIALS={}
for m in re.finditer(r'^\s*(\w+)=\{Sector="([^"]+)",Event="([^"]+)",Advanced=(true|false)\},?\s*$',trial_manifest,re.M):
    EXPECTED_TRIALS[m.group(1)]=(m.group(2),m.group(3),m.group(4)=="true")

workshop_branch_manifest=re.search(r'WorkshopBranches=\{([^}]*)\}',manifest)
if not workshop_branch_manifest:
    raise AssertionError("release Workshop branch manifest missing")
EXPECTED_WORKSHOP_BRANCH_LIST=re.findall(r'"([^"]+)"',workshop_branch_manifest.group(1))
EXPECTED_WORKSHOP_BRANCHES=set(EXPECTED_WORKSHOP_BRANCH_LIST)
workshop_count_manifest=re.search(r'WorkshopNodesPerBranch=(\d+)',manifest)
if not workshop_count_manifest:
    raise AssertionError("release Workshop node count manifest missing")
EXPECTED_WORKSHOP_NODES_PER_BRANCH=int(workshop_count_manifest.group(1))
EXPECTED_WORKSHOP_NODE_IDS={
    f"{branch}_{index}"
    for branch in EXPECTED_WORKSHOP_BRANCH_LIST
    for index in range(1,EXPECTED_WORKSHOP_NODES_PER_BRANCH+1)
}
EXPECTED_SEASON_CARDS={"SpringResonance","SummerSwarm","AutumnFortune","CrystalSeason","TwilightSeason"}
EXPECTED_JOURNEY=[
    "StarterBee","PollenSpark","Delivery","Roll","Plant","Charge","BloomRoll","Hive2",
    "WorkshopVisit","WorkshopPurchase","Synergy","BeeSlots","Trait","SunnyVisit","SolarBloom",
    "Discover6","CrystalGate","Trial","CrystalVisit","SeasonReady",
]

actual_flowers={}
for m in re.finditer(r'^species\("([^"]+)","[^"]+","([^"]+)"',flowers,re.M):
    actual_flowers[m.group(1)]=m.group(2)

actual_bees={}
for line in bees.splitlines():
    m=re.match(r'^\s*(\w+)=\{Id="([^"]+)",DisplayName="[^"]+",SortOrder=(\d+),DropWeight=[^,]+,Rarity="([^"]+)".*Ability=\{Id="([^"]+)"',line)
    if m:
        key,id_,order,rarity_name,ability=m.groups()
        if key!=id_:
            raise AssertionError(f"bee table key/id mismatch: {key} != {id_}")
        actual_bees[id_]=(rarity_name,ability,int(order))

actual_locations={}
for line in locations.splitlines():
    m=re.match(r'^\s*(\w+)=\{Name="[^"]+",Hive=(\d+),(?:Requires="([^"]+)",)?Center=.*Activity="([^"]+)"\},?\s*$',line)
    if m:
        actual_locations[m.group(1)]=(int(m.group(2)),m.group(3) or False,m.group(4))

actual_trials={}
for line in trials.splitlines():
    m=re.match(r'^\s*(\w+)=\{Id="[^"]+",Name="[^"]+",Sector="([^"]+)",Event="([^"]+)",Target=[^,]+,Seconds=[^,}]+(,Advanced=true)?\},?\s*$',line)
    if m:
        actual_trials[m.group(1)]=(m.group(2),m.group(3),m.group(4) is not None)

branch_match=re.search(r'Branches=\{([^}]*)\}',workshop)
if not branch_match:
    raise AssertionError("Workshop branch list missing")
actual_branch_list=re.findall(r'"([^"]+)"',branch_match.group(1))
actual_branches=set(actual_branch_list)
actual_workshop_effect_ids=set(re.findall(r'([A-Z]+_[1-6])=\{',workshop_effects))

actual_activities=set(re.findall(r'([A-Za-z0-9_]+)=\{Life=',activities))

cards_match=re.search(r'Cards=\{([^}]*)\}',season)
if not cards_match:
    raise AssertionError("Season card list missing")
actual_cards=set(re.findall(r'"([^"]+)"',cards_match.group(1)))

journey_match=re.search(r'local goals=\{([^}]*)\}',meta)
if not journey_match:
    raise AssertionError("Journey goal list missing")
actual_journey=re.findall(r'"([^"]+)"',journey_match.group(1))

if actual_flowers!=EXPECTED_FLOWERS:
    raise AssertionError(f"release flowers changed: expected={EXPECTED_FLOWERS} actual={actual_flowers}")
if actual_bees!=EXPECTED_BEES:
    raise AssertionError(f"release bees changed: expected={EXPECTED_BEES} actual={actual_bees}")
if actual_locations!=EXPECTED_LOCATIONS:
    raise AssertionError(f"release location metadata changed: expected={EXPECTED_LOCATIONS} actual={actual_locations}")
if actual_trials!=EXPECTED_TRIALS:
    raise AssertionError(f"release trial metadata changed: expected={EXPECTED_TRIALS} actual={actual_trials}")
if actual_activities!=EXPECTED_ACTIVITIES:
    raise AssertionError(f"release activities changed: missing={sorted(EXPECTED_ACTIVITIES-actual_activities)} extra={sorted(actual_activities-EXPECTED_ACTIVITIES)}")

if actual_branch_list!=EXPECTED_WORKSHOP_BRANCH_LIST:
    raise AssertionError(f"release Workshop branch order changed: expected={EXPECTED_WORKSHOP_BRANCH_LIST} actual={actual_branch_list}")
if actual_workshop_effect_ids!=EXPECTED_WORKSHOP_NODE_IDS:
    raise AssertionError(f"release Workshop node/effect set changed: missing={sorted(EXPECTED_WORKSHOP_NODE_IDS-actual_workshop_effect_ids)} extra={sorted(actual_workshop_effect_ids-EXPECTED_WORKSHOP_NODE_IDS)}")

if actual_cards!=EXPECTED_SEASON_CARDS:
    raise AssertionError(f"release Season cards changed: missing={sorted(EXPECTED_SEASON_CARDS-actual_cards)} extra={sorted(actual_cards-EXPECTED_SEASON_CARDS)}")

if actual_journey!=EXPECTED_JOURNEY:
    raise AssertionError(f"release Journey changed: expected={EXPECTED_JOURNEY} actual={actual_journey}")

if len(actual_flowers)!=12:
    raise AssertionError("release must ship 12 flowers")
if len(actual_bees)!=13:
    raise AssertionError("release must ship 13 bees")
if len(actual_locations)!=3:
    raise AssertionError("release must ship 3 locations")
if len(actual_trials)!=8:
    raise AssertionError("release must ship 8 trials")
if len(actual_branches)!=7:
    raise AssertionError("release must ship 7 Workshop branches")
if EXPECTED_WORKSHOP_NODES_PER_BRANCH!=6 or len(actual_workshop_effect_ids)!=42:
    raise AssertionError("release must ship exactly 6 Workshop nodes per branch / 42 effect-backed nodes")
if len(actual_activities)!=12:
    raise AssertionError("release must ship 12 activity types")
if len(actual_cards)!=5:
    raise AssertionError("release must ship 5 Season cards")
if len(actual_journey)!=20:
    raise AssertionError("release must ship 20 Journey objectives")

valid_rarities=set(re.findall(r'"([A-Za-z]+)"',re.search(r'Order=\{([^}]+)\}',rarity).group(1)))
for id_,rarity_name in actual_flowers.items():
    if rarity_name not in valid_rarities:
        raise AssertionError(f"flower {id_} uses non-shipping rarity {rarity_name}")
for id_,(rarity_name,_,_) in actual_bees.items():
    if rarity_name not in valid_rarities:
        raise AssertionError(f"bee {id_} uses non-shipping rarity {rarity_name}")
if "Exotic" in bees:
    raise AssertionError("retired Exotic runtime rarity alias returned")

bee_icon_block=section(icons,"Bees={","},\n\n-- New uploaded UI set.")
bee_icons={m.group(1):int(m.group(2)) for m in re.finditer(r'(\w+)=(\d+)',bee_icon_block)}
if set(bee_icons)!=set(EXPECTED_BEES):
    raise AssertionError(f"bee icon set drift: missing={sorted(set(EXPECTED_BEES)-set(bee_icons))} extra={sorted(set(bee_icons)-set(EXPECTED_BEES))}")
for id_,asset_id in bee_icons.items():
    if asset_id<=0:
        raise AssertionError(f"shipping bee {id_} has no icon asset")

need(manifest,'FlowerIconPolicy="DedicatedAssetOrSystemFlowerFallback"',"flower icon release policy")
need(icons,'function C.GetFlowerIcon(id) local icon=C.Get("Flowers",id) return icon~="" and icon or C.Get("System","Flower") end',"flower icon fallback")
need(icons,'Flower=117046422836136',"system flower fallback asset")
need(manifest,"LegacyFruitsShipping=false","legacy fruit exclusion")
need(icons,"C.Ids.LegacyFruits=C.Ids.Fruits","legacy fruit compatibility alias")

orders=[v[2] for v in actual_bees.values()]
if sorted(orders)!=list(range(1,len(actual_bees)+1)):
    raise AssertionError(f"bee sort order is not contiguous: {sorted(orders)}")

season_trials=re.search(r'TrialIds=\{([^}]*)\}',season)
if not season_trials:
    raise AssertionError("Season TrialIds missing")
season_trial_ids=re.findall(r'"([^"]+)"',season_trials.group(1))
if season_trial_ids!=["MeadowCircuit","SwiftRoute","CrystalTriangle"]:
    raise AssertionError(f"Season key trial set changed: {season_trial_ids}")

print("release content lock: PASS")
print("v1 content: 12 flowers, 13 bees, 3 locations, 8 trials, 7 Workshop branches, 12 activities, 5 Season cards, 20 Journey objectives.")
print("Flower/bee metadata, world/trial roles and all 42 Workshop node IDs are frozen by ReleaseContentManifest.")
