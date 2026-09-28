#!/usr/bin/env python3
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src: raise AssertionError(f"{label}: missing {text!r}")

locations=read("src/ReplicatedStorage/Config/LocationsConfig.luau")
bloom=read("src/ReplicatedStorage/Config/BloomConfig.luau")
hive=read("src/ServerScriptService/Services/HiveService.luau")
garden=read("src/ServerScriptService/Services/GardenPlotService.luau")
map_service=read("src/ServerScriptService/Services/MapService.luau")
features=read("src/ReplicatedStorage/Config/FeatureUnlockConfig.luau")
roll_pool=read("src/ReplicatedStorage/Config/RollPoolConfig.luau")
config_validation=read("src/ServerScriptService/Tests/ConfigValidation.luau")

need(locations,"Order={}","all location entries removed")
need(locations,"Sectors={}","all location sectors removed")
for stale in ("SunnyOrchard","CrystalGreenhouse","TwilightGrove"):
    if stale in locations or stale in map_service or stale in hive:
        raise AssertionError(f"removed location still referenced: {stale}")
assert "LocationsConfig" not in config_validation and "AllowedBiomes" not in config_validation, "ConfigValidation still validates removed biomes"
assert "AllowedBiomes" not in roll_pool and "UnlockedSectors" not in roll_pool, "RollPool still gates rewards by removed locations"
need(roll_pool,"local unlocked=true","global roll pool after location removal")

costs_match=re.search(r'HiveCosts=\{([^}]+)\}',bloom)
if not costs_match: raise AssertionError("HiveCosts missing")
costs=[int(float(x)) for x in re.findall(r'[0-9.]+',costs_match.group(1))]
if len(costs)<8 or costs[1]<=0: raise AssertionError(f"Hive ladder invalid: {costs}")

need(hive,'local cost=C.HiveUpgradeCost(nextLevel)',"endless Hive Honey cost")
need(hive,'local coinCost=C.HiveCoinCost(nextLevel)',"endless Hive Coin cost")
need(hive,'p.Currencies.Coins-=coinCost',"Hive consumes Coins as a second progression resource")
need(hive,'function S:UpgradeFromMenu(player)',"Hive menu upgrade route")
need(hive,'p.Hive.Honey-=cost',"server spend")
need(hive,'p.Hive.Level=nextLevel',"server Hive upgrade")
need(hive,'C.WorkshopPointsForHiveLevel(nextLevel)',"endless Hive point schedule")
need(hive,'self.X.WorkshopService:Point(player,"Hive_"',"Hive awards Workshop points")
if "Hive MAX" in hive: raise AssertionError("HiveService still exposes a hard max")
need(hive,'self.X.GardenPlotService:RefreshCapacity(player)',"Hive updates capacity")
need(hive,'self.X:Emit(player,"FirstGardenSlot",1)',"first slot")
need(hive,'self.X:Emit(player,"HiveUpgrade",1)',"Hive progression event")
assert 'gate is ready to unlock' not in hive and 'LocationsConfig' not in hive

need(garden,'return "Unlock Garden Slot 1"',"fresh Hive prompt")
need(garden,'"Upgrade Hive • "..math.floor(cost).." Honey"',"upgrade cost prompt")
need(map_service,'return "Center"',"single central map sector")
assert '"Workshop"' not in map_service, "physical Workshop returned"
need(features,'Workshop={Event="HiveUpgrade"}',"Workshop menu unlock")
need(features,'Trials={Event="HiveUpgrade"}',"Trials menu unlock")

print("hive / central-map progression contract: PASS")
