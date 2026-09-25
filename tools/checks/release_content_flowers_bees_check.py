#!/usr/bin/env python3
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def section(src,start,end):
    return src.split(start,1)[1].split(end,1)[0]
def need(src,text,label):
    if text not in src:
        raise AssertionError(f"{label}: missing {text!r}")

manifest=read("src/ReplicatedStorage/Config/ReleaseContentManifest.luau")
flowers=read("src/ReplicatedStorage/Config/FlowersConfig.luau")
bees=read("src/ReplicatedStorage/Config/BeesConfig.luau")
icons=read("src/ReplicatedStorage/Config/IconsConfig.luau")
rarity=read("src/ReplicatedStorage/Config/RarityConfig.luau")

mf=section(manifest,"Flowers={","\n },\n Bees={")
mb=section(manifest,"Bees={","\n },\n}")
expected_flowers={m.group(1):m.group(2) for m in re.finditer(r'^\s*(\w+)=\{Rarity="([^"]+)"\}',mf,re.M)}
expected_bees={
    m.group(1):(m.group(2),m.group(3),int(m.group(4)))
    for m in re.finditer(r'^\s*(\w+)=\{Rarity="([^"]+)",Ability="([^"]+)",SortOrder=(\d+)\}',mb,re.M)
}

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

if actual_flowers!=expected_flowers:
    raise AssertionError(f"shipping flower manifest drift: expected={expected_flowers} actual={actual_flowers}")
if actual_bees!=expected_bees:
    raise AssertionError(f"shipping bee manifest drift: expected={expected_bees} actual={actual_bees}")

if len(expected_flowers)!=12:
    raise AssertionError(f"release flower count changed: {len(expected_flowers)}")
if len(expected_bees)!=13:
    raise AssertionError(f"release bee count changed: {len(expected_bees)}")

valid_rarities=set(re.findall(r'"([A-Za-z]+)"',re.search(r'Order=\{([^}]+)\}',rarity).group(1)))
for id_,r in expected_flowers.items():
    if r not in valid_rarities:
        raise AssertionError(f"flower {id_} uses non-shipping rarity {r}")
for id_,(r,_,_) in expected_bees.items():
    if r not in valid_rarities:
        raise AssertionError(f"bee {id_} uses non-shipping rarity {r}")
if "Exotic" in bees:
    raise AssertionError("retired Exotic runtime rarity alias returned")

# Every shipping bee must have a concrete uploaded asset id.
bee_icon_block=section(icons,"Bees={","},\n\n-- New uploaded UI set.")
bee_icons={m.group(1):int(m.group(2)) for m in re.finditer(r'(\w+)=(\d+)',bee_icon_block)}
if set(bee_icons)!=set(expected_bees):
    raise AssertionError(f"bee icon set drift: missing={sorted(set(expected_bees)-set(bee_icons))} extra={sorted(set(bee_icons)-set(expected_bees))}")
for id_,asset_id in bee_icons.items():
    if asset_id<=0:
        raise AssertionError(f"shipping bee {id_} has no icon asset")

# Dedicated flower assets are optional for v1, but the UI must never return an empty icon.
need(manifest,'FlowerIconPolicy="DedicatedAssetOrSystemFlowerFallback"',"flower icon release policy")
need(icons,'function C.GetFlowerIcon(id) local icon=C.Get("Flowers",id) return icon~="" and icon or C.Get("System","Flower") end',"flower icon fallback")
need(icons,'Flower=117046422836136',"system flower fallback asset")

# Legacy fruit art remains available only for migration/history; it is not shipping content.
need(manifest,"LegacyFruitsShipping=false","legacy fruit exclusion")
need(icons,"C.Ids.LegacyFruits=C.Ids.Fruits","legacy fruit compatibility alias")

orders=[v[2] for v in expected_bees.values()]
if sorted(orders)!=list(range(1,len(expected_bees)+1)):
    raise AssertionError(f"bee sort order is not contiguous: {sorted(orders)}")

print("release content flowers/bees freeze: PASS")
print(f"Shipping content frozen: {len(expected_flowers)} flowers, {len(expected_bees)} bees.")
