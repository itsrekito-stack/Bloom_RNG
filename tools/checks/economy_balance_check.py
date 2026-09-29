#!/usr/bin/env python3
from pathlib import Path
import math,re
ROOT=Path(__file__).resolve().parents[2]
def read(p): return (ROOT/p).read_text(encoding="utf-8")
def num(src,key):
    m=re.search(rf'\b{re.escape(key)}=([0-9.]+)',src)
    if not m: raise AssertionError(f"missing {key}")
    return float(m.group(1))
def need(src,text,label):
    if text not in src: raise AssertionError(f"{label}: missing {text!r}")
bloom=read("src/ReplicatedStorage/Config/BloomConfig.luau")
workshop=read("src/ReplicatedStorage/Config/WorkshopConfig.luau")
flowers=read("src/ReplicatedStorage/Config/FlowersConfig.luau")
stats=read("src/ServerScriptService/Services/StatsService.luau")
tutorial=read("src/ServerScriptService/Services/TutorialService.luau")
poll=read("src/ServerScriptService/Services/PollinatorService.luau")
hive=read("src/ServerScriptService/Services/HiveService.luau")
inventory=read("src/ServerScriptService/Services/InventoryService.luau")
social=read("src/ServerScriptService/Services/SocialService.luau")
workshop_service=read("src/ServerScriptService/Services/WorkshopService.luau")
quest_service=read("src/ServerScriptService/Services/QuestService.luau")
quest_cfg=read("src/ReplicatedStorage/Config/QuestConfig.luau")
season_plan=read("src/ReplicatedStorage/Shared/SeasonPlan.luau")
season_service=read("src/ServerScriptService/Services/SeasonService.luau")

costs=[float(x) for x in re.findall(r'[0-9.]+',re.search(r'HiveCosts=\{([^}]*)\}',bloom).group(1))]
delivery_seconds=num(bloom,"DeliverySeconds");honey_per=num(bloom,"HoneyPerDelivery");coins_per=num(bloom,"CoinsPerDelivery")
first=math.ceil(costs[1]/honey_per);first_seconds=first*delivery_seconds
if not 45<=first_seconds<=150: raise AssertionError(f"Hive2 pacing {first_seconds}")
total_deliveries=math.ceil(sum(costs[1:])/honey_per);one_bee_minutes=total_deliveries*delivery_seconds/60
if not 120<=one_bee_minutes<=260: raise AssertionError(f"Hive8 pacing {one_bee_minutes}")
coin_costs=[float(x) for x in re.findall(r'[0-9.]+',re.search(r'HiveCoinCosts=\{([^}]*)\}',bloom).group(1))]
if coin_costs[1]!=first*coins_per: raise AssertionError("Hive2 Coin gate not aligned to first loop")
need(hive,"p.Currencies.Coins-=coinCost","Hive Coin sink")
need(workshop,'local COINS_BY_INDEX={100,250,700,1800,4500,10000}',"Workshop Coin curve")
need(inventory,'self.X.FlowerProgressionService:AddDuplicate(player,id,1)',"Flower duplicate progression")
need(inventory,'self.X.PollinatorService:AddMastery(player,id,C.BeeDuplicateXP)',"Bee duplicate progression")
need(poll,"profile.Hive.Honey+=honey","Honey source")
need(hive,"p.Hive.Honey-=cost","Honey sink")
need(poll,"profile.Currencies.Coins+=coins","Coin source")
need(workshop_service,"p.Currencies.Coins-=(n.Coins or 0)","Coin Workshop sink")
need(flowers,"function C.GetLevelBuff(id,level)","Flower specialty passives")
need(flowers,"function C.GetLuckMultiplier(id,level)","universal Flower Luck")
need(stats,"local buffs=F.GetLevelBuffs and F.GetLevelBuffs(id,mastery and mastery.Level or 1) or {}","Flower stats")
need(social,"p.Currencies.PetalDust=p.Currencies.PetalDust+2+math.min(8,math.floor(n/10))","Petal Dust source")
need(workshop_service,"p.Currencies.PetalDust-=(n.Dust or 0)","Petal Dust sink")
need(season_plan,'after.Currencies.AncientNectar=after.Currencies.AncientNectar+C.SeasonReward',"Nectar source")
need(workshop_service,"p.Currencies.AncientNectar-=(n.Nectar or 0)","Nectar Workshop sink")
need(season_service,"p.Currencies.AncientNectar-=cost","repeat Nectar sink")
need(hive,'self.X.WorkshopService:AwardHiveLevel(player,nextLevel)',"Hive Workshop Points source")
need(workshop_service,'function S:ReconcileHivePoints(player)',"Hive point recovery")
need(quest_service,'self.X.WorkshopService:Point(player,"Quest_"..id,points)',"Quest Workshop Points source")
for q in ("Q05_FirstBloom","Q10_WorkshopPath","Q14_BloomRoutine","Q18_BeeScholar","Q24_HiveTen","Q25_BloomKeeper"):
    need(quest_cfg,q,"quest point milestone "+q)
need(workshop_service,"w.Points-=(n.Cost or 0)","Workshop Point sink")

bloom_minutes=(num(bloom,"BloomMax")/num(bloom,"Delivery"))*delivery_seconds/60
pity_seconds=num(bloom,"DiscoveryThreshold")*num(bloom,"RollCooldown")
if not 4<=bloom_minutes<=10 or not 25<=pity_seconds<=60: raise AssertionError("Bloom/pity cadence drift")
print("economy balance contract: PASS")
print(f"Hive2 {first_seconds:.0f}s; Hive8 one-Bee {one_bee_minutes:.1f}m; Bloom {bloom_minutes:.2f}m; pity {pity_seconds:.1f}s.")
