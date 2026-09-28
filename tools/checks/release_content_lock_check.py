#!/usr/bin/env python3
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[2]
def read(p): return (ROOT/p).read_text(encoding="utf-8")
def between(src,a,b):
    if a not in src or b not in src.split(a,1)[1]: raise AssertionError(f"missing section {a}")
    return src.split(a,1)[1].split(b,1)[0]
manifest=read("src/ReplicatedStorage/Config/ReleaseContentManifest.luau")
flowers=read("src/ReplicatedStorage/Config/FlowersConfig.luau")
bees=read("src/ReplicatedStorage/Config/BeesConfig.luau")
icons=read("src/ReplicatedStorage/Config/IconsConfig.luau")
rarity=read("src/ReplicatedStorage/Config/RarityConfig.luau")
workshop=read("src/ReplicatedStorage/Config/WorkshopConfig.luau")
effects=read("src/ReplicatedStorage/Config/WorkshopEffectsConfig.luau")
activities=read("src/ReplicatedStorage/Config/ActivityConfig.luau")
quests=read("src/ReplicatedStorage/Config/QuestConfig.luau")
synergies=read("src/ReplicatedStorage/Config/GardenSynergyConfig.luau")
season=read("src/ReplicatedStorage/Config/SeasonConfig.luau")

mf=between(manifest,"Flowers={","\n },\n Bees={")
mb=between(manifest,"Bees={","\n },\n Locations={")
expected_flowers={m.group(1):m.group(2) for m in re.finditer(r'(\w+)=\{Rarity="([^"]+)"\}',mf)}
expected_bees={m.group(1):(m.group(2),m.group(3),int(m.group(4))) for m in re.finditer(r'(\w+)=\{Rarity="([^"]+)",Ability="([^"]+)",SortOrder=(\d+)\}',mb)}
actual_flowers={m.group(1):m.group(2) for m in re.finditer(r'^species\("([^"]+)","[^"]+","([^"]+)"',flowers,re.M)}
actual_bees={}
for m in re.finditer(r'^\s*(\w+)=\{Id="([^"]+)",DisplayName="[^"]+",SortOrder=(\d+),DropWeight=[^,]+,Rarity="([^"]+)".*?Ability=\{Id="([^"]+)"',bees,re.M):
    key,id_,order,rarity_name,ability=m.groups()
    if key!=id_: raise AssertionError(f"bee key/id mismatch {key}/{id_}")
    actual_bees[id_]=(rarity_name,ability,int(order))
if actual_flowers!=expected_flowers: raise AssertionError("ReleaseContentManifest Flower set does not match FlowersConfig")
if actual_bees!=expected_bees: raise AssertionError("ReleaseContentManifest Bee set does not match BeesConfig")
if len(actual_flowers)!=27: raise AssertionError(f"release must ship 27 flowers, got {len(actual_flowers)}")
if len(actual_bees)!=28: raise AssertionError(f"release must ship 28 bees, got {len(actual_bees)}")
orders=sorted(v[2] for v in actual_bees.values())
if orders!=list(range(1,29)): raise AssertionError(f"Bee SortOrder must be contiguous 1..28: {orders}")

rarity_order=re.findall(r'"([A-Za-z]+)"',re.search(r'Order=\{([^}]+)\}',rarity).group(1))
for id_,r in actual_flowers.items():
    if r not in rarity_order: raise AssertionError(f"{id_} bad rarity {r}")
for id_,(r,_,_) in actual_bees.items():
    if r not in rarity_order: raise AssertionError(f"{id_} bad rarity {r}")

quest_order=re.findall(r'"(Q\d+_[A-Za-z0-9_]+)"',re.search(r'C\.Order=\{(.*?)\n\}',quests,re.S).group(1))
if len(quest_order)!=25 or 'QuestCount=25' not in manifest: raise AssertionError("release must ship exactly 25 quests")
synergy_count=len(re.findall(r'\{Id="[^"]+",Name="[^"]+",Strength=',synergies))
if synergy_count!=32 or 'GardenSynergyCount=32' not in manifest: raise AssertionError(f"release must ship 32 Garden Synergies, got {synergy_count}")
if "Trials={" in manifest or "SeasonKeyTrials" in manifest or "TrialIds" in season: raise AssertionError("Trials returned to release content")

branches=re.findall(r'"([^"]+)"',re.search(r'WorkshopBranches=\{([^}]*)\}',manifest).group(1))
if len(branches)!=7: raise AssertionError("release must ship 7 Workshop branches")
effect_ids=set(re.findall(r'([A-Z]+_[1-6])=\{',effects))
if len(effect_ids)!=42: raise AssertionError(f"expected 42 Workshop effects, got {len(effect_ids)}")
activity_ids=set(re.findall(r'([A-Za-z0-9_]+)=\{Life=',activities))
if len(activity_ids)!=12: raise AssertionError(f"expected 12 activity types, got {len(activity_ids)}")

icon_block=between(icons,"Bees={","},\n\n-- New uploaded UI set.")
icon_ids=set(re.findall(r'(\w+)=[0-9]+',icon_block))
if icon_ids!=set(actual_bees): raise AssertionError(f"Bee icon registry drift: missing={sorted(set(actual_bees)-icon_ids)}")
if 'return icon~=""and icon or thumb(C.Ids.System.Bee or 0)' not in icons: raise AssertionError("new Bee icon fallback missing")
if 'function C.GetFlowerIcon(id) local icon=C.Get("Flowers",id) return icon~="" and icon or C.Get("System","Flower") end' not in icons: raise AssertionError("Flower icon fallback missing")

print("release content lock: PASS")
print("Content: 27 Flowers, 28 Bees, 32 Garden Synergies, 25 Quests, 12 Activities, 7 Workshop branches, no Trials.")
