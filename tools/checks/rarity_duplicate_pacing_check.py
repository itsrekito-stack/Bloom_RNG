#!/usr/bin/env python3
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src:
        raise AssertionError(f"{label}: missing {text!r}")

bloom=read("src/ReplicatedStorage/Config/BloomConfig.luau")
pool=read("src/ReplicatedStorage/Config/RollPoolConfig.luau")
rarity=read("src/ReplicatedStorage/Config/RarityConfig.luau")
flowers=read("src/ReplicatedStorage/Config/FlowersConfig.luau")
bees=read("src/ReplicatedStorage/Config/BeesConfig.luau")
season=read("src/ReplicatedStorage/Config/SeasonConfig.luau")
roll=read("src/ServerScriptService/Services/RollService.luau")
inventory=read("src/ServerScriptService/Services/InventoryService.luau")
ui=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau")

order=re.search(r'Order=\{([^}]*)\}',rarity)
if not order:
    raise AssertionError("rarity order missing")
rarities=re.findall(r'"([^"]+)"',order.group(1))
rank={name:i+1 for i,name in enumerate(rarities)}
if rarities!=["Common","Uncommon","Rare","Epic","Legendary","Mythic","Celestial"]:
    raise AssertionError(f"unexpected release rarity order: {rarities}")

m=re.search(r'DiscoveryPityMaxRarity="([^"]+)"',bloom)
if not m:
    raise AssertionError("DiscoveryPityMaxRarity missing")
pity_cap=m.group(1)
if pity_cap!="Epic":
    raise AssertionError(f"discovery pity must stop at Epic for release, got {pity_cap}")
cap_rank=rank[pity_cap]
if cap_rank>=rank["Legendary"]:
    raise AssertionError("discovery pity reaches endgame rarity")

need(pool,'local cap=R.Rank[C.DiscoveryPityMaxRarity] or R.Rank.Epic',"config-driven pity cap")
need(pool,'v.Undiscovered and (R.Rank[v.Rarity] or math.huge)<=cap',"pity filters only protected discovery tiers")
need(pool,'if #new>0 then pool=new end',"pity leaves natural pool intact when no protected discovery remains")
if 'if v.Undiscovered then table.insert(new,v)' in pool:
    raise AssertionError("uncapped all-rarity discovery pity returned")

# Parse release flower weights + sector availability.
weight_block=flowers.split("local DROP_WEIGHTS={",1)[1].split("}",1)[0]
flower_weights={k:int(v) for k,v in re.findall(r'([A-Za-z0-9_]+)=(\d+)',weight_block)}
flower_rows=[]
for row in re.finditer(r'species\("([^"]+)","[^"]+","([^"]+)","[^"]+",[^\n]+,\{([^}]*)\}',flowers):
    fid,rarity_name,sectors=row.groups()
    sector_names=set(re.findall(r'"([^"]+)"',sectors))
    flower_rows.append((fid,rarity_name,sector_names,flower_weights[fid]))

# Parse release bees. Exotic config rows are normalized to Mythic by BeesConfig.
bee_rows=[]
for row in re.finditer(r'([A-Za-z0-9_]+)=\{Id="[^"]+",DisplayName="[^"]+",SortOrder=\d+,DropWeight=(\d+),Rarity="([^"]+)"',bees):
    bid,weight,rarity_name=row.groups()
    if rarity_name=="Exotic":
        rarity_name="Mythic"
    bee_rows.append((bid,rarity_name,int(weight)))

if len(flower_rows)!=12:
    raise AssertionError(f"expected 12 release flowers, got {len(flower_rows)}")
if len(bee_rows)!=13:
    raise AssertionError(f"expected 13 release bees, got {len(bee_rows)}")

# Early roulette = all bees + Sunny/Starter flowers.
early=[]
for fid,r,sectors,w in flower_rows:
    if "StarterOrchard" in sectors:
        early.append((fid,r,w))
early.extend(bee_rows)
total=sum(w for _,_,w in early)
by_rarity={r:sum(w for _,rr,w in early if rr==r) for r in rarities}
share={r:(by_rarity[r]/total if total else 0) for r in rarities}

guardrails={
    "Common":(.55,.70),
    "Uncommon":(.28,.42),
    "Rare":(.012,.04),
    "Epic":(.003,.012),
    "Legendary":(.0005,.003),
    "Mythic":(.0001,.001),
    "Celestial":(.000005,.00005),
}
for r,(lo,hi) in guardrails.items():
    if not lo<=share[r]<=hi:
        raise AssertionError(f"early {r} natural share drift: {share[r]*100:.6f}%")

celestial_odds=1/share["Celestial"]
mythic_odds=1/share["Mythic"]
if not 50000<=celestial_odds<=150000:
    raise AssertionError(f"Celestial natural odds drift: 1/{celestial_odds:.0f}")
if not 2000<=mythic_odds<=6000:
    raise AssertionError(f"Mythic natural odds drift: 1/{mythic_odds:.0f}")

# Pity-protected tiers are sufficient for release progression without touching Legendary+.
protected_flowers=sum(
    1 for _,r,sectors,_ in flower_rows
    if rank[r]<=cap_rank and ("StarterOrchard" in sectors or "CrystalGreenhouse" in sectors)
)
protected_bees=sum(1 for _,r,_ in bee_rows if rank[r]<=cap_rank)
season_flowers=int(re.search(r'\bFlowers=(\d+)',season).group(1))
season_bees=int(re.search(r'\bBees=(\d+)',season).group(1))
if protected_flowers<season_flowers:
    raise AssertionError(f"pity-protected flowers cannot satisfy Season breadth: {protected_flowers} < {season_flowers}")
if protected_bees<season_bees:
    raise AssertionError(f"pity-protected bees cannot satisfy Season breadth: {protected_bees} < {season_bees}")

# Pity remains bounded and only resets when an actual discovery occurs.
need(roll,'math.min(C.DiscoveryThreshold,p.RollState.DiscoveryPity+1)',"bounded pity counter")
need(roll,'p.RollState.DiscoveryPity=new and 0 or',"pity resets only on discovery")

# Duplicates now advance species progression instead of creating disposable stock.
need(inventory,'f.ObtainedFlowers[id]=(f.ObtainedFlowers[id] or 0)+1',"Flower obtained count")
need(inventory,'self.X.FlowerProgressionService:AddDuplicate(player,id,1)',"duplicate Flower advances Level")
need(inventory,'pollinators.BeeObtained[id]=(pollinators.BeeObtained[id] or 0)+1',"Bee obtained count")
need(inventory,'self.X.PollinatorService:AddMastery(player,id,C.BeeDuplicateXP)',"duplicate Bee advances Mastery")
need(inventory,'f.OwnedSeedCopies[id]=1',"Flower species ownership does not stack copies")
need(inventory,'pollinators.BeeInventory[id]=1',"Bee species ownership does not stack copies")

# Player-facing copy must not promise a guaranteed endgame discovery.
need(ui,'"  •  PITY READY"',"truthful pity HUD copy")
if "NEW GUARANTEED" in ui:
    raise AssertionError("HUD still promises an uncapped guaranteed discovery")

threshold=int(re.search(r'\bDiscoveryThreshold=(\d+)',bloom).group(1))
cooldown=float(re.search(r'\bRollCooldown=([0-9.]+)',bloom).group(1))
pity_seconds=threshold*cooldown
if not 25<=pity_seconds<=60:
    raise AssertionError(f"pity timing drift: {pity_seconds:.1f}s")

print("rarity / duplicate pacing contract: PASS")
print(f"Early natural odds: Mythic ~1/{mythic_odds:.0f}, Celestial ~1/{celestial_odds:.0f}; pity caps at {pity_cap}.")
print(f"Pity-protected progression pool: {protected_flowers} flowers through Crystal, {protected_bees} bees; Season needs {season_flowers}/{season_bees}.")
