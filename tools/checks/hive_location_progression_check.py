#!/usr/bin/env python3
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[2]
def read(p): return (ROOT/p).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src: raise AssertionError(f"{label}: missing {text!r}")
locations=read("src/ReplicatedStorage/Config/LocationsConfig.luau")
bloom=read("src/ReplicatedStorage/Config/BloomConfig.luau")
hive=read("src/ServerScriptService/Services/HiveService.luau")
workshop=read("src/ServerScriptService/Services/WorkshopService.luau")
garden=read("src/ServerScriptService/Services/GardenPlotService.luau")
map_service=read("src/ServerScriptService/Services/MapService.luau")
features=read("src/ReplicatedStorage/Config/FeatureUnlockConfig.luau")
roll_pool=read("src/ReplicatedStorage/Config/RollPoolConfig.luau")

need(locations,"Order={}","locations removed")
need(locations,"Sectors={}","location sectors removed")
need(roll_pool,"local unlocked=true","global roll pool")
costs=[int(float(x)) for x in re.findall(r'[0-9.]+',re.search(r'HiveCosts=\{([^}]+)\}',bloom).group(1))]
if len(costs)<8 or costs[1]<=0: raise AssertionError(f"Hive ladder invalid: {costs}")
need(hive,'local cost=C.HiveUpgradeCost(nextLevel)',"Hive Honey cost")
need(hive,'local coinCost=C.HiveCoinCost(nextLevel)',"Hive Coin cost")
need(hive,'p.Currencies.Coins-=coinCost',"Coin spend")
need(hive,'p.Hive.Honey-=cost',"Honey spend")
need(hive,'p.Hive.Level=nextLevel',"Hive level")
need(hive,'self.X.WorkshopService:AwardHiveLevel(player,nextLevel)',"Hive point award")
need(hive,'tostring(total).." total"',"Hive award feedback exposes resulting balance")
need(hive,'self.X.QuestService:ClaimedCount(profile)',"quest-gated Hive rule")
need(workshop,'function S:AwardHiveLevel(player,level)',"central Hive award")
need(workshop,'function S:ReconcileHivePoints(player)',"missing Hive point recovery")
need(workshop,'"HiveSeason_"..tostring(season).."_Level_"..tostring(level)',"season-scoped source key")
need(workshop,'not p.WorkshopV5.ClaimedSources[key] and not p.WorkshopV5.ClaimedSources[legacy]',"safe missing-source reconciliation")
need(hive,'self.X.GardenPlotService:RefreshCapacity(player)',"capacity refresh")
need(hive,'self.X:Emit(player,"HiveUpgrade",1)',"Hive event")
need(garden,'"Upgrade Hive • "..math.floor(cost).." Honey • "..math.floor(coins).." Coins"',"dual-resource prompt")
need(map_service,'return "Center"',"central map")
need(features,'Workshop={Event="HiveUpgrade"}',"Workshop unlock")
need(features,'Quests={Event="HiveUpgrade"}',"Quests unlock")
assert "Trials" not in features and "rule.Trials" not in hive, "Trial-based Hive progression returned"
print("hive / central-map progression contract: PASS")
