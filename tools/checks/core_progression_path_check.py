#!/usr/bin/env python3
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src: raise AssertionError(f"{label}: missing {text!r}")
def number(src,key):
    m=re.search(rf"\b{re.escape(key)}=([0-9.]+)",src)
    if not m: raise AssertionError(f"missing numeric config {key}")
    return float(m.group(1))

default=read("src/ServerScriptService/Data/DefaultProfile.luau")
tutorial=read("src/ReplicatedStorage/Config/TutorialConfig.luau")
features=read("src/ReplicatedStorage/Config/FeatureUnlockConfig.luau")
bloom=read("src/ReplicatedStorage/Config/BloomConfig.luau")
locations=read("src/ReplicatedStorage/Config/LocationsConfig.luau")
trials=read("src/ReplicatedStorage/Config/BuildTrialConfig.luau")
season=read("src/ReplicatedStorage/Config/SeasonConfig.luau")
flowers=read("src/ReplicatedStorage/Config/FlowersConfig.luau")
bees=read("src/ReplicatedStorage/Config/BeesConfig.luau")
hive=read("src/ServerScriptService/Services/HiveService.luau")
pollinator=read("src/ServerScriptService/Services/PollinatorService.luau")
garden_rules=read("src/ReplicatedStorage/Shared/GardenRules.luau")
garden_activity=read("src/ServerScriptService/Services/GardenActivityService.luau")
build_trial=read("src/ServerScriptService/Services/BuildTrialService.luau")
map_service=read("src/ServerScriptService/Services/MapService.luau")
season_plan=read("src/ReplicatedStorage/Shared/SeasonPlan.luau")
roll_pool=read("src/ReplicatedStorage/Config/RollPoolConfig.luau")
workshop=read("src/ReplicatedStorage/Config/WorkshopConfig.luau")

# A fresh profile must be able to begin pollination before Roll is unlocked.
need(default,'OwnedSeedCopies={Daisy=1}',"fresh profile owns starter flower")
need(default,'Slots={{SpeciesId="Daisy",Level=1,XP=0,Mutation="",TotalPollination=0}',"fresh profile has planted Daisy")
need(hive,'self.X.InventoryService:Grant(player,"Bee","WorkerBee")',"Hive grants starter Worker Bee")
need(hive,'p.Pollinators.EquippedBeeSlots[1]="WorkerBee"',"starter Worker Bee is equipped")

events=re.findall(r'Event="([^"]+)"',tutorial)
required_prefix=["Wake","StarterBee","Work","PollenSpark","Delivery","Roll"]
if events[:len(required_prefix)] != required_prefix:
    raise AssertionError(f"tutorial opening path changed: {events[:len(required_prefix)]}")
need(features,'Roll={Step=6}',"Roll unlock follows reachable opening tutorial")
need(pollinator,'self.X:EmitOnce(player,"Work")',"starter pollination advances Work")
need(pollinator,'if not p.Tutorial.Events.PollenSpark then self.X.GardenActivityService:Offer(player,"PollenSpark"', "first delivery creates Pollen Spark route")
need(pollinator,'self.X:Emit(player,"Delivery",1)',"delivery advances tutorial")

# First Workshop purchase must be economically reachable from the Hive 2 path.
need(hive,'self.X.WorkshopService:Point(player,"Hive_"..p.Season.Count.."_"..p.Hive.Level,2)',"Hive upgrade awards Workshop points")
honey_per=number(bloom,"HoneyPerDelivery")
coins_per=number(bloom,"CoinsPerDelivery")
m=re.search(r'HiveCosts=\{([^}]+)\}',bloom)
if not m: raise AssertionError("HiveCosts missing")
hive_costs=[float(x) for x in re.findall(r'[0-9.]+',m.group(1))]
if len(hive_costs)<2: raise AssertionError("HiveCosts must contain Hive 2 cost")
hive2_cost=hive_costs[1]
deliveries=(hive2_cost+honey_per-1)//honey_per
coins_before_hive2=deliveries*coins_per
if coins_before_hive2 < 30:
    raise AssertionError(f"Hive 2 path only yields {coins_before_hive2} Coins before a 30-Coin first Workshop node")
need(workshop,'Cost=1,Coins=i*30',"first Workshop branch node cost contract")

# Sector thresholds must be reachable before the Season gate.
sector_hives={name:int(level) for name,level in re.findall(r'(SunnyOrchard|CrystalGreenhouse|TwilightGrove)=\{[^}]*Hive=(\d+)',locations)}
if sector_hives != {"SunnyOrchard":2,"CrystalGreenhouse":4,"TwilightGrove":6}:
    raise AssertionError(f"unexpected sector Hive thresholds: {sector_hives}")
season_hive=int(number(season,"Hive"))
if max(sector_hives.values()) > season_hive:
    raise AssertionError("a required sector unlocks after the Season Hive requirement")
need(roll_pool,'p.World.UnlockedSectors[sector] or sector=="SunnyOrchard"',"Sunny flower pool is available for early progression")

# CrystalTriangle requires slot 6 at Hive 4; base capacity must reach it.
need(garden_rules,'3+math.max(0,p.Hive.Level-1)',"base flower capacity grows with Hive level")
need(trials,'CrystalTriangle={Id="CrystalTriangle",Name="Crystal Triangle",Sector="CrystalGreenhouse"', "CrystalTriangle sector")
need(read("src/ReplicatedStorage/Config/GardenSynergyConfig.luau"),'Slots={1,2,6}',"CrystalTriangle pattern slots")
if 3+(sector_hives["CrystalGreenhouse"]-1) < 6:
    raise AssertionError("Crystal Greenhouse unlock does not provide enough base flower slots for CrystalTriangle")

# All key Season trials need deterministic event sources.
need(trials,'MeadowCircuit={Id="MeadowCircuit",Name="Meadow Circuit",Sector="SunnyOrchard",Event="Delivery"', "MeadowCircuit uses automatic delivery")
need(trials,'SwiftRoute={Id="SwiftRoute",Name="Swift Route",Sector="SunnyOrchard",Event="PollenTrail"', "SwiftRoute event")
need(trials,'CrystalTriangle={Id="CrystalTriangle",Name="Crystal Triangle",Sector="CrystalGreenhouse",Event="CrystalResonance"', "CrystalTriangle event")
need(map_service,'self.X.GardenActivityService:Offer(player,s.Activity,pos,id)',"sector landmarks create configured world activity")
need(locations,'CrystalGreenhouse={Name="Crystal Greenhouse",Hive=4', "Crystal sector config")
need(locations,'Activity="CrystalResonance"', "Crystal sector supplies CrystalResonance")
need(build_trial,'if id=="SwiftRoute" then', "SwiftRoute has trial-specific route")
need(build_trial,'self.X.GardenActivityService:Offer(player,"PollenTrail",pos,cfg.Sector,nil,true)', "SwiftRoute immediately creates PollenTrail")
need(garden_activity,'if count>=A.MaxVisible and not priority then return false end', "priority trial route bypasses ordinary activity cap")
if 'elseif kind=="NectarBud" then\n  local nearest=nil local distance=math.huge' in garden_activity:
    raise AssertionError("dead duplicate NectarBud Collect branch returned")

# Season requirements must not exceed shipped content.
flower_ids=re.findall(r'species\("([^"]+)"',flowers)
bee_block=bees.split("C.Bees={",1)[1].split("\nlocal Rarity=",1)[0]
bee_ids=re.findall(r'^ ([A-Za-z0-9_]+)=\{Id="',bee_block,re.M)
required_flowers=int(number(season,"Flowers"))
required_bees=int(number(season,"Bees"))
required_trials=int(number(season,"Trials"))
if required_flowers > len(flower_ids):
    raise AssertionError(f"Season requires {required_flowers} flowers but only {len(flower_ids)} ship")
if required_bees > len(bee_ids):
    raise AssertionError(f"Season requires {required_bees} bees but only {len(bee_ids)} ship")
key_trials=re.search(r'TrialIds=\{([^}]+)\}',season)
if not key_trials or len(re.findall(r'"[^"]+"',key_trials.group(1))) < required_trials:
    raise AssertionError("Season key trial list cannot satisfy Season.Trials")

# Season Turn must return to a playable starter state.
need(season_plan,'local flower=profile.Season.Keepsakes.Flower or "Daisy"', "Season Turn retains/seeds a flower")
need(season_plan,'after.Garden.Slots[1]={SpeciesId=flower,Level=1', "Season Turn replants slot 1")
need(season_plan,'local bee=profile.Season.Keepsakes.Bee or "WorkerBee"', "Season Turn retains/seeds a bee")
need(season_plan,'after.Pollinators.EquippedBeeSlots={bee}', "Season Turn equips retained bee")
need(season_plan,'after.StarterBeeGranted=true',"Season Turn stays pollination-ready")

print("core progression reachability: PASS")
print(f"Fresh profile -> Hive 2 needs {int(deliveries)} deliveries and yields {int(coins_before_hive2)} Coins before first Workshop node.")
print(f"Content gate: {len(flower_ids)} flowers / {len(bee_ids)} bees ship vs Season requirement {required_flowers} / {required_bees}.")
print("Key path covered through sectors, key trials and playable post-Season reset.")
