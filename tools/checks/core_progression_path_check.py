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
schema=read("src/ServerScriptService/Data/ProfileSchema.luau")
tutorial=read("src/ReplicatedStorage/Config/TutorialConfig.luau")
features=read("src/ReplicatedStorage/Config/FeatureUnlockConfig.luau")
bloom=read("src/ReplicatedStorage/Config/BloomConfig.luau")
rules=read("src/ReplicatedStorage/Shared/GardenRules.luau")
roll=read("src/ServerScriptService/Services/RollService.luau")
hive=read("src/ServerScriptService/Services/HiveService.luau")
tutorial_service=read("src/ServerScriptService/Services/TutorialService.luau")
meta=read("src/ServerScriptService/Services/MetaProgressionService.luau")
locations=read("src/ReplicatedStorage/Config/LocationsConfig.luau")
season=read("src/ReplicatedStorage/Config/SeasonConfig.luau")
season_plan=read("src/ReplicatedStorage/Shared/SeasonPlan.luau")
flowers=read("src/ReplicatedStorage/Config/FlowersConfig.luau")
bees=read("src/ReplicatedStorage/Config/BeesConfig.luau")
trials=read("src/ReplicatedStorage/Config/BuildTrialConfig.luau")

need(default,"SchemaVersion=6","game vision schema")
need(default,"JourneyNoTrialV1=true","fresh profiles use Trial-free Journey indices")
need(schema,"local journeyMigrate=not(n.Migrations and n.Migrations.JourneyNoTrialV1)","returning Journey migration marker")
need(schema,"elseif oldStep==15 then","old SeasonReady step remaps after Trial removal")
need(schema,"claimed.Journey_14=claimed.Journey_15==true or nil","completed SeasonReady claim remaps safely")
need(default,"OwnedSeedCopies={}","fresh profile starts with no Flower")
need(default,"BeeInventory={}","fresh profile starts with no Bee")
need(default,"UnlockedSlots=0","fresh profile starts with zero Garden slots")
need(default,"Slots={{},{},{},{},{},{},{}}","fresh profile carries seven empty slot records")

ids=re.findall(r'\{Id="([^"]+)"',tutorial)
expected=["GardenSlot","FirstFlowerRoll","Plant","FirstBeeRoll","EquipBee","FillBloom","BloomRoll","InventoryExplain","PollenSpark","HiveUpgrade","WorkshopPurchase","Synergy","Quests"]
if ids!=expected: raise AssertionError(f"tutorial path changed: {ids}")
need(tutorial,"Version=10","tutorial schema v10")
need(features,'Roll={Step=2}',"Roll unlocks for guaranteed Flower roll")
need(hive,'self.X:Emit(player,"FirstGardenSlot",1)',"Hive grants tutorial Garden slot")
need(roll,'if stepId=="FirstFlowerRoll" then',"Flower-only tutorial roll")
need(roll,'item.Kind=="FlowerSeed" and item.Id=="Daisy"',"tutorial prefers Daisy")
need(roll,'elseif stepId=="FirstBeeRoll" then',"Bee-only tutorial roll")
need(roll,'item.Kind=="Bee" and item.Id=="WorkerBee"',"tutorial prefers Worker Bee")
if 'self.X.InventoryService:EquipBee(player,item.Id,1)' in roll:
    raise AssertionError("tutorial Bee roll must not auto-equip before the Equip Bee step")
need(roll,'if T.Steps[p.Tutorial.Step] and automatic then return false,"TUTORIAL_SINGLE_ROLL" end',"tutorial rolls stay single-use")
if 'InventoryService:Grant(player,"Bee","WorkerBee")' in hive:
    raise AssertionError("old direct starter Bee grant returned")

need(bloom,"StartingSlots=0","capacity begins at zero")
need(bloom,"GardenSlotHiveMilestones={2,3,4,5,6,7}","Garden milestones configured")
need(bloom,"BeeSlotHiveMilestones={2,3,4,5,6,7,8}","Bee milestones configured")
need(rules,"FirstGardenSlot","first Garden slot comes from tutorial")
need(rules,"C.GardenSlotHiveMilestones","later Garden capacity comes from Hive")
if "WorkshopEffects" in rules:
    raise AssertionError("Workshop still changes Garden/Bee capacity")
garden_milestones=[int(x) for x in re.search(r'GardenSlotHiveMilestones=\{([^}]*)\}',bloom).group(1).split(",")]
if garden_milestones!=[2,3,4,5,6,7]:
    raise AssertionError(f"unexpected Garden milestones: {garden_milestones}")
if 1+sum(1 for x in garden_milestones if x<=7)!=7:
    raise AssertionError("all seven Garden slots are not available by Hive 7")

need(hive,"function S:QuestStatus(profile,nextLevel)","Hive quest validation")
for key in ("Discoveries","Synergies","BeeMasteryLevel","Activities","Trials"):
    need(bloom,key+"=","Hive quest table covers "+key)
need(hive,"if not questReady then","Hive upgrade blocks incomplete quest")
need(bloom,"function C.HiveUpgradeCost(nextLevel)","endless Hive Honey cost function")
need(bloom,"function C.HiveCoinCost(nextLevel)","endless Hive Coin cost function")
need(bloom,"function C.WorkshopPointsForHiveLevel(level)","endless Hive point function")
need(hive,"C.WorkshopPointsForHiveLevel(nextLevel)","Hive points continue after release milestones")
need(meta,'local POINT_MILESTONES={Synergy=1,Trait=1,SeasonReady=2}',"Journey point milestone table without Trial gate")
need(meta,'self.X.WorkshopService:Point(player,"JourneyMilestone_"..key,points)',"key Journey milestones award Workshop Points through one-time sources")

honey_per=number(bloom,"HoneyPerDelivery")
coins_per=number(bloom,"CoinsPerDelivery")
hive_costs=[float(x) for x in re.findall(r'[0-9.]+',re.search(r'HiveCosts=\{([^}]+)\}',bloom).group(1))]
hive2=hive_costs[1]
deliveries=int((hive2+honey_per-1)//honey_per)
coins=deliveries*coins_per
if deliveries!=10 or coins<30:
    raise AssertionError(f"early Hive pacing drift: {deliveries} deliveries / {coins} Coins")
need(tutorial_service,"p.Hive.Honey=need","tutorial cannot stall on Hive 2 Honey")
need(tutorial_service,"p.Currencies.Coins=coins","tutorial cannot stall on Hive 2 Coins")
need(tutorial_service,"p.WorkshopV5.Points=math.max(p.WorkshopV5.Points,node.Cost or 0)","tutorial guarantees first Workshop point")

need(locations,"Order={}","removed location list stays empty")
need(locations,"Sectors={}","removed location sectors stay empty")

flower_ids=re.findall(r'species\("([^"]+)"',flowers)
bee_block=bees.split("C.Bees={",1)[1].split("\nlocal Rarity=",1)[0]
bee_ids=re.findall(r'^ ([A-Za-z0-9_]+)=\{Id="',bee_block,re.M)
if int(number(season,"Flowers"))>len(flower_ids): raise AssertionError("Season Flower requirement exceeds shipped content")
if int(number(season,"Bees"))>len(bee_ids): raise AssertionError("Season Bee requirement exceeds shipped content")
need(trials,'MeadowCircuit={Id="MeadowCircuit"', "Meadow trial ships")
need(trials,'SwiftRoute={Id="SwiftRoute"', "Swift Route ships")
need(trials,'CrystalTriangle={Id="CrystalTriangle"', "Crystal trial ships")

need(season_plan,'local flower=profile.Season.Keepsakes.Flower or "Daisy"',"Season retains/seeds a Flower")
need(season_plan,"UnlockedSlots=1","Season reset remains plantable")
need(season_plan,'local bee=profile.Season.Keepsakes.Bee or "WorkerBee"',"Season retains/seeds a Bee")
need(season_plan,'after.Pollinators.EquippedBeeSlots={bee}',"Season reset remains pollination-ready")

print("core progression reachability: PASS")
print(f"Fresh path is deterministic through first Flower/Bee; Hive 2 needs {deliveries} deliveries and yields {int(coins)} Coins.")
print(f"Seven Garden slots are reached by Hive 7; release content ships {len(flower_ids)} Flowers / {len(bee_ids)} Bees.")
