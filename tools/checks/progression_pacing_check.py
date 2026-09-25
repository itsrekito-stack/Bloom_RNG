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
effects=read("src/ReplicatedStorage/Config/WorkshopEffectsConfig.luau")
bees=read("src/ReplicatedStorage/Config/BeesConfig.luau")
hive_service=read("src/ServerScriptService/Services/HiveService.luau")

m=re.search(r'HiveCosts=\{([^}]*)\}',bloom)
if not m: raise AssertionError("HiveCosts missing")
costs=[float(x) for x in re.findall(r'[0-9.]+',m.group(1))]
delivery=num(bloom,"DeliverySeconds")
honey=num(bloom,"HoneyPerDelivery")

def cumulative_minutes(target_level,workers=1):
    total=sum(costs[1:target_level])
    deliveries=math.ceil(total/honey)
    return deliveries*delivery/60/max(1,workers)

hive2=cumulative_minutes(2)
hive4=cumulative_minutes(4)
hive6=cumulative_minutes(6)
hive8_one=cumulative_minutes(8)

if not 0.75<=hive2<=2.5:
    raise AssertionError(f"early Hive2 pacing drift: {hive2:.2f}m")
if not 7<=hive4<=20:
    raise AssertionError(f"midgame Hive4 one-bee anchor drift: {hive4:.2f}m")
if not 35<=hive6<=80:
    raise AssertionError(f"Twilight Hive6 one-bee anchor drift: {hive6:.2f}m")
if not 120<=hive8_one<=260:
    raise AssertionError(f"Season Hive8 one-bee upper anchor drift: {hive8_one:.2f}m")

# A fully developed release loadout can reach five equipped bees:
# 1 base + 1 at Hive2 + BEES_1 (+1) + BEES_5 (+2).
need(effects,'BEES_1={BeeSlots=1}',"first Workshop bee slot")
need(effects,'BEES_5={BeeSlots=2}',"late Workshop bee slots")
developed_workers=5
hive8_developed=hive8_one/developed_workers
if not 25<=hive8_developed<=60:
    raise AssertionError(f"developed Hive8 throughput floor drift: {hive8_developed:.2f}m")

# World milestones must remain ordered across the Hive ladder.
sector_hives={name:int(level) for name,level in re.findall(r'(SunnyOrchard|CrystalGreenhouse|TwilightGrove)=\{[^}]*Hive=(\d+)',locations)}
if sector_hives!={"SunnyOrchard":2,"CrystalGreenhouse":4,"TwilightGrove":6}:
    raise AssertionError(f"location pacing drift: {sector_hives}")
need(locations,'Requires="SunnyOrchard"',"Crystal follows Sunny")
need(locations,'Requires="CrystalGreenhouse"',"Twilight follows Crystal")
need(workshop,"local HIVE_BY_INDEX={1,2,3,4,5,5}","Workshop depth reaches Hive5 before Twilight/Season")

# First useful Workshop purchase is available when the first Hive milestone awards points.
need(hive_service,'self.X.WorkshopService:Point(player,"Hive_"..p.Season.Count.."_"..p.Hive.Level,2)',"Hive milestone Workshop points")
need(workshop,"Cost=1","early Workshop point affordability")

# Season remains a late milestone after all three locations, collection breadth and key trials.
need(season,"Hive=8","Season Hive gate")
need(season,"Flowers=8","Season flower breadth")
need(season,"Bees=5","Season bee breadth")
need(season,"Trials=3","Season trial breadth")
need(season,'TrialIds={"MeadowCircuit","SwiftRoute","CrystalTriangle"}',"Season key trials")

# Bee Mastery must be a long-running side progression, not a few-minute unlock.
block=bees.split("C.BeeMastery={",1)[1].split("\nC.Traits=",1)[0]
xp_match=re.search(r'XPPerLevel=\{([^}]*)\}',block)
if not xp_match: raise AssertionError("Bee Mastery XP ladder missing")
xp=[int(x) for x in re.findall(r'\d+',xp_match.group(1))]
mastery_minutes=sum(xp)*delivery/60
if not 45<=mastery_minutes<=150:
    raise AssertionError(f"Bee Mastery pacing drift: {mastery_minutes:.1f}m")

# Long-term Legacy should remain multi-Season.
season_reward=num(bloom,"SeasonReward")
legacy_nectar=sum(range(1,7))
legacy_seasons=math.ceil(legacy_nectar/season_reward)
if not 4<=legacy_seasons<=6:
    raise AssertionError(f"Legacy completion pacing drift: {legacy_seasons} Seasons")

# RNG protection keeps the active loop moving while preserving visible anticipation.
pity=num(bloom,"DiscoveryThreshold")
roll_cd=num(bloom,"RollCooldown")
pity_seconds=pity*roll_cd
if not 25<=pity_seconds<=60:
    raise AssertionError(f"pity pacing drift: {pity_seconds:.1f}s")

print("progression pacing contract: PASS")
print(f"Anchors: Hive2 {hive2:.2f}m, Hive4 {hive4:.1f}m, Hive6 {hive6:.1f}m, Hive8 one-bee {hive8_one:.1f}m / developed-5-bee {hive8_developed:.1f}m.")
print(f"Bee Mastery {mastery_minutes:.1f} base minutes; Legacy about {legacy_seasons} base Seasons; pity ceiling {pity_seconds:.1f}s.")
