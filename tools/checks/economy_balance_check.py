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
workshop=read("src/ReplicatedStorage/Config/WorkshopConfig.luau")
poll=read("src/ServerScriptService/Services/PollinatorService.luau")
hive=read("src/ServerScriptService/Services/HiveService.luau")
inventory=read("src/ServerScriptService/Services/InventoryService.luau")
map_service=read("src/ServerScriptService/Services/MapService.luau")
social=read("src/ServerScriptService/Services/SocialService.luau")
workshop_service=read("src/ServerScriptService/Services/WorkshopService.luau")
season_plan=read("src/ReplicatedStorage/Shared/SeasonPlan.luau")
season_service=read("src/ServerScriptService/Services/SeasonService.luau")
trial=read("src/ServerScriptService/Services/BuildTrialService.luau")
meta=read("src/ServerScriptService/Services/MetaProgressionService.luau")

m=re.search(r'HiveCosts=\{([^}]*)\}',bloom)
if not m: raise AssertionError("HiveCosts missing")
hive_costs=[float(x) for x in re.findall(r'[0-9.]+',m.group(1))]
if len(hive_costs)!=8 or hive_costs[0]!=0:
    raise AssertionError(f"unexpected Hive cost ladder: {hive_costs}")
if any(hive_costs[i]>=hive_costs[i+1] for i in range(1,len(hive_costs)-1)):
    raise AssertionError(f"Hive upgrade costs must rise: {hive_costs}")

delivery_seconds=num(bloom,"DeliverySeconds")
honey_per=num(bloom,"HoneyPerDelivery")
coins_per=num(bloom,"CoinsPerDelivery")
bloom_max=num(bloom,"BloomMax")
delivery_charge=num(bloom,"Delivery")
roll_cd=num(bloom,"RollCooldown")
pity=num(bloom,"DiscoveryThreshold")
season_reward=num(bloom,"SeasonReward")

# Baseline timings intentionally ignore traits/abilities/extra bees; they are upper-bound pacing anchors.
first_deliveries=math.ceil(hive_costs[1]/honey_per)
first_hive_seconds=first_deliveries*delivery_seconds
if not 45<=first_hive_seconds<=150:
    raise AssertionError(f"Hive 2 baseline pacing outside guardrail: {first_hive_seconds:.0f}s")

total_honey=sum(hive_costs[1:])
total_deliveries=math.ceil(total_honey/honey_per)
one_bee_minutes=total_deliveries*delivery_seconds/60
if not 120<=one_bee_minutes<=260:
    raise AssertionError(f"Hive 8 one-bee upper-bound pacing outside guardrail: {one_bee_minutes:.1f}m")

coins_before_hive2=first_deliveries*coins_per
first_workshop_coin_cost=30
if not first_workshop_coin_cost<=coins_before_hive2<=first_workshop_coin_cost*4:
    raise AssertionError(f"first Workshop affordability drift: {coins_before_hive2} Coins before Hive 2")

nonlegacy_workshop_coins=sum(i*30 for i in range(1,7))*6
baseline_coins_to_hive8=total_deliveries*coins_per
ratio=baseline_coins_to_hive8/nonlegacy_workshop_coins
if not 1.4<=ratio<=3.5:
    raise AssertionError(f"Coin source/sink ratio outside guardrail: {ratio:.2f}x")

# Duplicate rolls now feed species Level/Mastery directly; Petal Dust is a world/seasonal resource.
need(inventory,'self.X.FlowerProgressionService:AddDuplicate(player,id,1)',"Flower duplicate progression")
need(inventory,'self.X.PollinatorService:AddMastery(player,id,C.BeeDuplicateXP)',"Bee duplicate progression")

legacy_nectar=sum(range(1,7))
base_seasons_for_legacy=math.ceil(legacy_nectar/season_reward)
if not 4<=base_seasons_for_legacy<=6:
    raise AssertionError(f"Legacy Nectar pacing outside guardrail: {base_seasons_for_legacy} Seasons")

bloom_delivery_minutes=(bloom_max/delivery_charge)*delivery_seconds/60
if not 4<=bloom_delivery_minutes<=10:
    raise AssertionError(f"delivery-only Bloom cadence outside guardrail: {bloom_delivery_minutes:.2f}m")

pity_seconds=pity*roll_cd
if not 25<=pity_seconds<=60:
    raise AssertionError(f"base pity cadence outside guardrail: {pity_seconds:.1f}s")

# Static Hive milestones + three key trials + the remaining non-Trial Journey milestones fund early Workshop choices.
hive_points=2+1+1+2
trial_points=3*2
journey_points=1+1+2
minimum_first_season_points=hive_points+trial_points+journey_points
if not 16<=minimum_first_season_points<36:
    raise AssertionError(f"first-Season Workshop point pacing drift: {minimum_first_season_points}")

# Every release currency has both a live source and a live sink/reset.
need(poll,"profile.Hive.Honey+=honey","Honey source")
need(hive,"p.Hive.Honey-=cost","Honey sink")
need(poll,"profile.Currencies.Coins+=coins","Coin source")
need(workshop_service,"p.Currencies.Coins-=(n.Coins or 0)","Coin Workshop sink")
need(season_plan,"after.Currencies.Coins=0","Coin Season sink")
if "PetalDust" in map_service:
    raise AssertionError("removed world landmarks must not remain a Petal Dust source")
need(social,"p.Currencies.PetalDust=p.Currencies.PetalDust+2+math.min(8,math.floor(n/10))","Petal Dust Server Bloom source")
need(workshop_service,"p.Currencies.PetalDust-=(n.Dust or 0)","Petal Dust Workshop sink")
need(season_plan,'after.Currencies.AncientNectar=after.Currencies.AncientNectar+C.SeasonReward',"Ancient Nectar source")
need(workshop_service,"p.Currencies.AncientNectar-=(n.Nectar or 0)","Ancient Nectar Legacy sink")
need(season_service,"p.Currencies.AncientNectar-=cost","Ancient Nectar post-Legacy repeatable sink")
need(season_service,"p.Currencies.PetalDust+=Bloom.NectarDistillDust","Ancient Nectar distill destination")
need(hive,'C.WorkshopPointsForHiveLevel(nextLevel)',"Hive Workshop Points continue after release milestones")
need(hive,'self.X.WorkshopService:Point(player,"Hive_"',"Workshop Point Hive source")
need(trial,'self.X.WorkshopService:Point(player,"Trial_"',"Workshop Point trial source")
need(meta,'local POINT_MILESTONES={Synergy=1,Trait=1,SeasonReady=2}',"Trial-free Journey Workshop Point table")
need(meta,'self.X.WorkshopService:Point(player,"JourneyMilestone_"..key,points)',"Journey Workshop Point source")
need(workshop_service,"w.Points-=(n.Cost or 0)","Workshop Point sink")

print("economy balance contract: PASS")
print(f"Hive2 baseline {first_hive_seconds:.0f}s; Hive8 one-bee upper bound {one_bee_minutes:.1f}m; Coin coverage {ratio:.2f}x seasonal Workshop; Legacy ~{base_seasons_for_legacy} base Seasons.")
print(f"Bloom delivery-only {bloom_delivery_minutes:.2f}m; base pity {pity_seconds:.1f}s; minimum first-Season Workshop Points {minimum_first_season_points}.")
