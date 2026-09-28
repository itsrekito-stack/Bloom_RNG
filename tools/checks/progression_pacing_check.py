#!/usr/bin/env python3
from pathlib import Path
import math,re

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def num(src,key):
    m=re.search(rf'\b{re.escape(key)}=([0-9.]+)',src)
    if not m: raise AssertionError(f"missing numeric config {key}")
    return float(m.group(1))
def need(src,text,label):
    if text not in src: raise AssertionError(f"{label}: missing {text!r}")

bloom=read("src/ReplicatedStorage/Config/BloomConfig.luau")
locations=read("src/ReplicatedStorage/Config/LocationsConfig.luau")
season=read("src/ReplicatedStorage/Config/SeasonConfig.luau")
workshop=read("src/ReplicatedStorage/Config/WorkshopConfig.luau")
bees=read("src/ReplicatedStorage/Config/BeesConfig.luau")
hive=read("src/ServerScriptService/Services/HiveService.luau")
rules=read("src/ReplicatedStorage/Shared/GardenRules.luau")

costs=[float(x) for x in re.findall(r'[0-9.]+',re.search(r'HiveCosts=\{([^}]*)\}',bloom).group(1))]
delivery=num(bloom,"DeliverySeconds"); honey=num(bloom,"HoneyPerDelivery")

def cumulative_minutes(target_level,workers=1):
    total=sum(costs[1:target_level])
    deliveries=math.ceil(total/honey)
    return deliveries*delivery/60/max(1,workers)

hive2=cumulative_minutes(2)
hive4=cumulative_minutes(4)
hive6=cumulative_minutes(6)
hive8_one=cumulative_minutes(8)
if not 0.75<=hive2<=2.5: raise AssertionError(f"early Hive2 pacing drift: {hive2:.2f}m")
if not 7<=hive4<=20: raise AssertionError(f"Hive4 one-Bee anchor drift: {hive4:.2f}m")
if not 35<=hive6<=80: raise AssertionError(f"Hive6 one-Bee anchor drift: {hive6:.2f}m")
if not 120<=hive8_one<=260: raise AssertionError(f"Hive8 one-Bee upper anchor drift: {hive8_one:.2f}m")

need(bloom,"GardenSlotHiveMilestones={2,3,4,5,6,7}","Garden capacity milestone table")
need(bloom,"BeeSlotHiveMilestones={2,3,4,5,6,7,8}","Bee capacity milestone table")
need(rules,"C.GardenSlotHiveMilestones","Garden slots use Hive milestones")
need(rules,"C.BeeSlotHiveMilestones","Bee slots use Hive milestones")
if "WorkshopEffects" in rules:
    raise AssertionError("Workshop still changes slot capacity")
garden=[int(x) for x in re.search(r'GardenSlotHiveMilestones=\{([^}]*)\}',bloom).group(1).split(",")]
bee=[int(x) for x in re.search(r'BeeSlotHiveMilestones=\{([^}]*)\}',bloom).group(1).split(",")]
if 1+sum(x<=7 for x in garden)!=7: raise AssertionError("seven Garden slots not reached by Hive 7")
if 1+sum(x<=8 for x in bee)!=8: raise AssertionError("eight Bee slots not reached by Hive 8")

# A practical five-Bee build provides a lower bound on developed throughput without assuming all slots are filled.
developed_workers=5
hive8_developed=hive8_one/developed_workers
if not 25<=hive8_developed<=60:
    raise AssertionError(f"developed Hive8 throughput drift: {hive8_developed:.2f}m")

need(locations,"Order={}","removed location list stays empty")
need(locations,"Sectors={}","removed location sectors stay empty")
need(workshop,"local HIVE_BY_INDEX={1,2,3,4,5,5}","Workshop depth reaches Hive5")
need(hive,"C.WorkshopPointsForHiveLevel(nextLevel)","Workshop points continue after Hive 8")
growth=num(bloom,"EndlessHiveCostGrowth")
round_to=num(bloom,"EndlessHiveCostRound")
endless_points=num(bloom,"EndlessHivePointsPerLevel")
if not 1.2<=growth<=1.5: raise AssertionError(f"endless Hive growth drift: {growth}")
if round_to<1: raise AssertionError("endless Hive rounding invalid")
if endless_points<1: raise AssertionError("Hive 9+ must keep awarding Workshop Points")
hive9=round(costs[-1]*growth/round_to)*round_to
if hive9<=costs[-1]: raise AssertionError("Hive 9 cost must exceed Hive 8")

need(season,"Hive=8","Season Hive gate");need(season,"Flowers=8","Season Flower breadth");need(season,"Bees=5","Season Bee breadth");need(season,"Trials=3","Season trial breadth")

bee_block=bees.split("C.Bees={",1)[1].split("\nlocal Rarity=",1)[0]
bee_entries=re.findall(r'^ ([A-Za-z0-9_]+)=\{.*?Passive=\{([^}]*)\}',bee_block,re.M)
bee_luck=[]
for bee_id,passive in bee_entries:
    m=re.search(r'LuckMultiplier=([0-9.]+)',passive)
    if not m: raise AssertionError(f"{bee_id} does not contribute Roll Luck")
    bee_luck.append(float(m.group(1)))
if not bee_luck or min(bee_luck)<1.02 or max(bee_luck)>1.30:
    raise AssertionError(f"Bee Luck curve out of bounds: {bee_luck}")
block=bees.split("C.BeeMastery={",1)[1].split("\nC.Traits=",1)[0]
xp=[int(x) for x in re.findall(r'\d+',re.search(r'XPPerLevel=\{([^}]*)\}',block).group(1))]
duplicate_xp=num(bloom,"BeeDuplicateXP")
mastery_duplicates=sum(xp)/duplicate_xp
if not 15<=mastery_duplicates<=60:
    raise AssertionError(f"Bee Mastery duplicate pacing drift: {mastery_duplicates:.1f}")

season_reward=num(bloom,"SeasonReward")
legacy_seasons=math.ceil(sum(range(1,7))/season_reward)
if not 4<=legacy_seasons<=6: raise AssertionError(f"Legacy pacing drift: {legacy_seasons} Seasons")

pity_seconds=num(bloom,"DiscoveryThreshold")*num(bloom,"RollCooldown")
if not 25<=pity_seconds<=60: raise AssertionError(f"pity pacing drift: {pity_seconds:.1f}s")

print("progression pacing contract: PASS")
print(f"Anchors: Hive2 {hive2:.2f}m, Hive4 {hive4:.1f}m, Hive6 {hive6:.1f}m, Hive8 one-Bee {hive8_one:.1f}m / practical-5-Bee {hive8_developed:.1f}m.")
print(f"Bee Mastery ~{mastery_duplicates:.1f} base duplicates to cap; Legacy ~{legacy_seasons} base Seasons; pity ceiling {pity_seconds:.1f}s.")
