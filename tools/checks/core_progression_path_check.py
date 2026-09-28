#!/usr/bin/env python3
from pathlib import Path
import re, math
ROOT=Path(__file__).resolve().parents[2]
def read(p): return (ROOT/p).read_text(encoding="utf-8")
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
rules=read("src/ReplicatedStorage/Shared/GardenRules.luau")
roll=read("src/ServerScriptService/Services/RollService.luau")
hive=read("src/ServerScriptService/Services/HiveService.luau")
workshop=read("src/ServerScriptService/Services/WorkshopService.luau")
tutorial_service=read("src/ServerScriptService/Services/TutorialService.luau")
quests=read("src/ReplicatedStorage/Config/QuestConfig.luau")
quest_service=read("src/ServerScriptService/Services/QuestService.luau")
season=read("src/ReplicatedStorage/Config/SeasonConfig.luau")
season_plan=read("src/ReplicatedStorage/Shared/SeasonPlan.luau")
flowers=read("src/ReplicatedStorage/Config/FlowersConfig.luau")
bees=read("src/ReplicatedStorage/Config/BeesConfig.luau")

need(default,"SchemaVersion=7","schema v7")
need(default,"OwnedSeedCopies={}","no starter Flower before tutorial")
need(default,"BeeInventory={}","no starter Bee before tutorial")
need(default,"UnlockedSlots=0","zero initial Garden slots")
ids=re.findall(r'\{Id="([^"]+)"',tutorial)
expected=["GardenSlot","FirstFlowerRoll","Plant","FirstBeeRoll","EquipBee","FillBloom","BloomRoll","InventoryExplain","PollenSpark","HiveUpgrade","WorkshopPurchase","Synergy","Quests"]
if ids!=expected: raise AssertionError(f"tutorial path changed: {ids}")
need(tutorial,"Version=11","tutorial v11")
need(features,'Quests={Event="HiveUpgrade"}',"Quests unlock")
need(features,'Workshop={Event="HiveUpgrade"}',"Workshop unlock")
need(roll,'item.Kind=="FlowerSeed" and item.Id=="Daisy"',"guaranteed tutorial Flower")
need(roll,'item.Kind=="Bee" and item.Id=="WorkerBee"',"guaranteed tutorial Bee")
need(roll,'T.Steps[p.Tutorial.Step] and automatic',"single tutorial rolls")

need(bloom,"GardenSlotHiveMilestones={2,3,4,5,6,7}","Garden milestones")
need(bloom,"BeeSlotHiveMilestones={2,3,4,5,6,7,8}","Bee milestones")
need(rules,"C.GardenSlotHiveMilestones","Garden capacity")
need(hive,"function S:QuestStatus(profile,nextLevel)","Hive quest rules")
for key in ("Discoveries","Synergies","BeeMasteryLevel","Activities","Quests"):
    need(bloom,key+"=","Hive rule "+key)
need(hive,'self.X.WorkshopService:AwardHiveLevel(player,nextLevel)',"Hive Workshop point award")
need(workshop,'function S:ReconcileHivePoints(player)',"Hive point recovery")

order=re.findall(r'"(Q\d+_[A-Za-z0-9_]+)"',re.search(r'C\.Order=\{(.*?)\n\}',quests,re.S).group(1))
if len(order)!=25: raise AssertionError(f"expected 25 quests, got {len(order)}")
need(quest_service,'function S:Claim(player,id)',"quest claims")
need(season,'Quests=15',"Season quest gate")

honey=number(bloom,"HoneyPerDelivery");coins_per=number(bloom,"CoinsPerDelivery")
costs=[float(x) for x in re.findall(r'[0-9.]+',re.search(r'HiveCosts=\{([^}]+)\}',bloom).group(1))]
deliveries=math.ceil(costs[1]/honey);coins=deliveries*coins_per
if deliveries!=10 or coins<30: raise AssertionError(f"early Hive pacing drift {deliveries}/{coins}")
need(tutorial_service,"p.Hive.Honey=need","tutorial Hive Honey assist")
need(tutorial_service,"p.Currencies.Coins=coins","tutorial Hive Coin assist")
need(tutorial_service,"p.WorkshopV5.Points=math.max(p.WorkshopV5.Points,node.Cost or 0)","tutorial Workshop assist")

flower_ids=re.findall(r'species\("([^"]+)"',flowers)
bee_ids=re.findall(r'^ ([A-Za-z0-9_]+)=\{Id="',bees.split("C.Bees={",1)[1].split("\nlocal Rarity=",1)[0],re.M)
if len(flower_ids)!=27 or len(bee_ids)!=28: raise AssertionError(f"content breadth drift {len(flower_ids)}/{len(bee_ids)}")
if int(number(season,"Flowers"))>len(flower_ids) or int(number(season,"Bees"))>len(bee_ids): raise AssertionError("Season breadth exceeds content")
need(season_plan,'local flower=profile.Season.Keepsakes.Flower or "Daisy"',"Season Flower")
need(season_plan,'local bee=profile.Season.Keepsakes.Bee or "WorkerBee"',"Season Bee")
for retired in ("src/ServerScriptService/Services/MetaProgressionService.luau","src/ServerScriptService/Services/BuildTrialService.luau","src/ReplicatedStorage/Config/BuildTrialConfig.luau"):
    if (ROOT/retired).exists(): raise AssertionError(f"retired file returned: {retired}")

print("core progression reachability: PASS")
print(f"Tutorial -> 25 Quests; Hive2 requires {deliveries} deliveries; content ships {len(flower_ids)} Flowers / {len(bee_ids)} Bees.")
